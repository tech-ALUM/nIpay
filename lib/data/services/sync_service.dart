import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';
import '../db/tables.dart';
import 'sync_lock.dart';

/// Il server ha rifiutato una o più righe (vincolo violato, RLS): non è un
/// problema di rete, riprovare la stessa riga darebbe lo stesso esito.
class SyncRowRejectedException implements Exception {
  const SyncRowRejectedException(this.code);

  final String? code;

  @override
  String toString() => 'SyncRowRejectedException($code)';
}

/// Astrazione sopra l'accesso di rete a Postgres — stesso motivo di
/// `AuthService`: isolare la sync engine dal client Supabase concreto,
/// così la logica di watermark/ordinamento/mapping è testabile con un
/// finto "server" in memoria, senza toccare la rete.
abstract interface class SyncRemote {
  /// Upsert per chiave primaria. Lancia [SyncRowRejectedException] se il
  /// server rifiuta i dati (vincoli, RLS); qualunque altra eccezione è un
  /// problema di trasporto. No-op se [rows] è vuota.
  Future<void> upsert(String table, List<Map<String, dynamic>> rows);

  /// Una pagina di righe ordinate per (`updated_at`, [keyColumns]...).
  /// Senza [afterKey]: righe con `updated_at >= from`. Con [afterKey]:
  /// righe strettamente successive alla posizione (`from`, [afterKey]) —
  /// paginazione keyset, stabile anche se nel frattempo arrivano scritture.
  Future<List<Map<String, dynamic>>> fetchPage(
    String table, {
    required List<String> keyColumns,
    required DateTime from,
    List<String>? afterKey,
    required int limit,
  });
}

class SupabaseSyncRemote implements SyncRemote {
  /// Il client è letto solo al primo uso (non alla costruzione): il motore
  /// si può creare anche senza `Supabase.initialize()`, es. nei widget test
  /// che leggono solo lo stato locale.
  SupabaseSyncRemote(SupabaseClient Function() client) : _clientOf = client;

  final SupabaseClient Function() _clientOf;
  SupabaseClient get _client => _clientOf();

  /// Codici SQLSTATE che dipendono dai dati della riga: classe 22 (dato
  /// non valido), 23 (vincolo violato), 42501 (RLS).
  static bool _isRowRejection(String? code) =>
      code != null &&
      (code.startsWith('22') || code.startsWith('23') || code == '42501');

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    try {
      await _client.from(table).upsert(rows);
    } on PostgrestException catch (e) {
      if (_isRowRejection(e.code)) throw SyncRowRejectedException(e.code);
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPage(
    String table, {
    required List<String> keyColumns,
    required DateTime from,
    List<String>? afterKey,
    required int limit,
  }) {
    final ts = from.toUtc().toIso8601String();
    final query = _client.from(table).select();
    final filtered = afterKey == null
        ? query.gte('updated_at', ts)
        : query.or(keysetFilter(ts, keyColumns, afterKey));
    var ordered = filtered.order('updated_at', ascending: true);
    for (final column in keyColumns) {
      ordered = ordered.order(column, ascending: true);
    }
    return ordered.limit(limit);
  }

  static final _safeValue = RegExp(r'^[A-Za-z0-9:.+_-]{1,64}$');

  /// Filtro PostgREST `or=(...)` per "(updated_at, k1, k2...) > (ts, a1,
  /// a2...)". I valori finiscono tra virgolette nella sintassi del filtro:
  /// accettati solo caratteri sicuri (UUID, timestamp ISO).
  static String keysetFilter(
    String ts,
    List<String> keyColumns,
    List<String> afterKey,
  ) {
    for (final v in [ts, ...afterKey]) {
      if (!_safeValue.hasMatch(v)) {
        throw FormatException('valore non ammesso nel cursore di sync: $v');
      }
    }
    final parts = ['updated_at.gt."$ts"'];
    for (var i = 0; i < keyColumns.length; i++) {
      parts.add(
        'and(${['updated_at.eq."$ts"', for (var j = 0; j < i; j++) '${keyColumns[j]}.eq."${afterKey[j]}"', '${keyColumns[i]}.gt."${afterKey[i]}"'].join(',')})',
      );
    }
    return parts.join(',');
  }
}

/// Stato dell'ultima sync, per la UI (SECURITY_AUDIT NIP-04: niente più
/// sync bloccate da giorni senza che nessuno se ne accorga).
class SyncStatus {
  const SyncStatus({
    required this.lastSuccessAt,
    required this.lastError,
    required this.pendingIssues,
  });

  final DateTime? lastSuccessAt;

  /// Codice dell'ultimo errore (`failed`), null se l'ultima sync è andata
  /// a buon fine. Mai un messaggio del server.
  final String? lastError;

  /// Righe che il server ha rifiutato o che sono arrivate malformate:
  /// restano in coda e vengono ritentate a ogni sync.
  final int pendingIssues;
}

/// Account a cui appartengono i dati locali (riga di `SyncStates`).
class LocalDataOwner {
  const LocalDataOwner({required this.userId, this.email});

  final String userId;
  final String? email;
}

/// Motore di sync (M-ACC6): push/pull incrementale tra il Drift locale e
/// Postgres (schema in `supabase/migrations/`).
///
/// Nota di scope: gli **allegati** (foto scontrini) sono esclusi da questa
/// prima versione — sincronizzarli richiede anche l'upload/download del
/// file binario su Supabase Storage (M-ACC3), non solo la riga di
/// metadata; è un lavoro a sé, rimandato a un passo successivo.
abstract interface class SyncService {
  /// Sincronizza subito. No-op silenzioso se non c'è un utente loggato
  /// (modalità solo-locale) — mai un errore per questo caso, è normale.
  ///
  /// Lancia [LocalDataOwnedByAnotherUserException] se i dati locali
  /// appartengono a un altro account: in quel caso non viene inviato né
  /// scaricato nulla.
  Future<void> syncNow();

  /// True se l'utente loggato è diverso da quello a cui appartengono i
  /// dati locali (sync bloccato finché i dati non vengono rimossi).
  Future<bool> hasLocalDataOfAnotherUser();

  /// Account a cui sono legati i dati di questo device, o null se i dati
  /// non sono mai stati sincronizzati (modalità solo-locale).
  Future<LocalDataOwner?> localDataOwner();

  /// Stato dell'ultima sync dell'utente loggato, o null se non c'è.
  Future<SyncStatus?> status();

  /// Esegue [action] in esclusiva rispetto alla sync (e a `wipe()`): usato
  /// dal logout per non avere una sync in background a metà strada.
  Future<T> exclusive<T>(Future<T> Function() action);
}

/// I dati locali sono legati a un altro account (login A → logout →
/// login B sullo stesso device). Il sync si rifiuta di partire: senza
/// questo blocco i portafogli di A verrebbero caricati con
/// `owner_user_id` = B (dati di A finiti nell'account di B).
class LocalDataOwnedByAnotherUserException implements Exception {
  const LocalDataOwnedByAnotherUserException();

  @override
  String toString() =>
      'LocalDataOwnedByAnotherUserException: i dati locali appartengono a '
      'un altro account';
}

/// L'utente è cambiato (logout/login) mentre la sync era in corso: ci si
/// ferma senza scrivere altro (SECURITY_AUDIT NIP-14).
class SyncAbortedException implements Exception {
  const SyncAbortedException();

  @override
  String toString() => 'SyncAbortedException: utente cambiato durante la sync';
}

/// Riga del server non conforme a quanto il client sa gestire.
class _InvalidRow implements Exception {
  const _InvalidRow(this.field);

  final String field;
}

/// Lettura difensiva di una riga del server: ogni campo viene controllato
/// (tipo, dominio, lunghezza) prima di toccare il DB locale. Una riga
/// malformata finisce in quarantena invece di bloccare la sync di tutti i
/// device (SECURITY_AUDIT NIP-04).
class _Row {
  _Row(this._data);

  final Map<String, dynamic> _data;

  static final _key = RegExp(r'^[A-Za-z0-9-]{1,64}$');
  static final _color = RegExp(r'^#[0-9A-Fa-f]{6}$');
  static final _currency = RegExp(r'^[A-Z]{3}$');

  Object? operator [](String field) => _data[field];

  String key(String field) {
    final v = _data[field];
    if (v is String && _key.hasMatch(v)) return v;
    throw _InvalidRow(field);
  }

  String? optKey(String field) => _data[field] == null ? null : key(field);

  String text(String field, {int max = 200}) {
    final v = _data[field];
    if (v is String && v.length <= max) return v;
    throw _InvalidRow(field);
  }

  String? optText(String field, {int max = 200}) =>
      _data[field] == null ? null : text(field, max: max);

  int integer(String field, {int? min}) {
    final v = _data[field];
    if (v is int && (min == null || v >= min)) return v;
    throw _InvalidRow(field);
  }

  int? optInteger(String field, {int? min}) =>
      _data[field] == null ? null : integer(field, min: min);

  bool boolean(String field) {
    final v = _data[field];
    if (v is bool) return v;
    throw _InvalidRow(field);
  }

  DateTime date(String field) {
    final v = _data[field];
    final parsed = v is String ? DateTime.tryParse(v) : null;
    if (parsed != null) return parsed;
    throw _InvalidRow(field);
  }

  DateTime? optDate(String field) => _data[field] == null ? null : date(field);

  T enumByName<T extends Enum>(List<T> values, String field) {
    final v = _data[field];
    final parsed = v is String ? values.asNameMap()[v] : null;
    if (parsed != null) return parsed;
    throw _InvalidRow(field);
  }

  String color(String field) {
    final v = _data[field];
    if (v is String && _color.hasMatch(v)) return v;
    throw _InvalidRow(field);
  }

  String currency(String field) {
    final v = _data[field];
    if (v is String && _currency.hasMatch(v)) return v;
    throw _InvalidRow(field);
  }

  String? optCurrency(String field) =>
      _data[field] == null ? null : currency(field);

  List<String>? optStringList(
    String field, {
    int maxItems = 200,
    int maxLen = 200,
  }) {
    final v = _data[field];
    if (v == null) return null;
    if (v is List &&
        v.length <= maxItems &&
        v.every((e) => e is String && e.length <= maxLen)) {
      return v.cast<String>();
    }
    throw _InvalidRow(field);
  }

  Map<String, dynamic> jsonObject(String field, {int maxBytes = 16384}) {
    final v = _data[field];
    if (v is Map<String, dynamic> && jsonEncode(v).length <= maxBytes) return v;
    throw _InvalidRow(field);
  }
}

/// Come sincronizzare una tabella: chiave, serializzazione verso il server
/// e lettura (validata) dal server.
class _TableSync<T extends Table, D> {
  const _TableSync({
    required this.name,
    required this.table,
    this.keyColumns = const ['id'],
    required this.keyOfLocal,
    required this.loadByKeys,
    required this.modifiedAtOf,
    required this.toRemote,
    required this.fromRemote,
    this.beforeApply,
  });

  /// Nome della tabella, uguale in Drift (SQL) e in Postgres.
  final String name;
  final TableInfo<T, D> table;
  final List<String> keyColumns;
  final String Function(D row) keyOfLocal;
  final Future<List<D>> Function(List<String> keys) loadByKeys;

  /// Momento dell'ultima modifica locale (`updatedAt`): è il `modified_at`
  /// del last-write-wins.
  final DateTime Function(D row) modifiedAtOf;
  final Map<String, dynamic> Function(D row, String userId) toRemote;
  final Insertable<D> Function(_Row row) fromRemote;

  /// Hook prima di applicare una riga scaricata (es. deduplica budget).
  final Future<void> Function(_Row row)? beforeApply;

  String keyOfRemote(_Row row) =>
      keyColumns.map(row.key).join(SupabaseSyncService.keySeparator);

  // Le chiamate passano da qui perché dentro la classe `this` ha i tipi
  // esatti <T, D>: dalla lista eterogenea delle tabelle (tipata con i
  // supertipi) un accesso diretto ai campi funzione fallirebbe a runtime.
  Future<int> push(SupabaseSyncService sync, String userId) =>
      sync._push<T, D>(this, userId);

  Future<(int, DateTime?)> pull(SupabaseSyncService sync, String userId) =>
      sync._pull<T, D>(this, userId);
}

/// Ordine di sync: genitori prima dei figli, sia per il push (rispetta le
/// foreign key su Postgres) sia per il pull.
///
/// Modello (SECURITY_AUDIT NIP-01..04, NIP-14):
///   * **push**: si inviano le righe in [SyncOutbox] (riempita da trigger
///     SQLite a ogni scrittura locale), con `modified_at` = `updatedAt`
///     locale. Il server applica il last-write-wins (trigger `sync_stamp`)
///     e assegna `updated_at`. Una voce esce dalla coda solo se il server
///     ha risposto e nessuno l'ha modificata nel frattempo. Le righe
///     rifiutate (vincoli, RLS) restano in coda e non bloccano le altre;
///   * **pull**: un watermark per tabella ([SyncCursors]) nel dominio
///     dell'orologio del server, paginazione keyset ordinata su
///     (`updated_at`, chiave) e una finestra di sovrapposizione che
///     recupera i commit arrivati fuori ordine. Le righe sono applicate in
///     modo idempotente e con last-write-wins anche in locale: una modifica
///     locale più recente non ancora inviata non viene sovrascritta;
///   * tutto dentro un [SyncLock] condiviso con `wipe()` e il logout, e la
///     sync si ferma se l'utente cambia a metà.
class SupabaseSyncService implements SyncService {
  SupabaseSyncService(
    this._remote,
    this._db, {
    required String? Function() currentUserId,
    String? Function()? currentUserEmail,
    SyncLock? lock,
    this.pageSize = 500,
    this.pushBatchSize = 200,
    this.pullOverlap = const Duration(minutes: 2),
  }) : _currentUserId = currentUserId,
       _currentUserEmail = currentUserEmail ?? _noEmail,
       _lock = lock ?? SyncLock();

  final SyncRemote _remote;
  final AppDatabase _db;
  final String? Function() _currentUserId;
  final String? Function() _currentUserEmail;
  final SyncLock _lock;
  final int pageSize;
  final int pushBatchSize;

  /// Quanto si "torna indietro" rispetto al watermark a ogni pull: copre le
  /// transazioni Postgres che committano dopo che righe più recenti sono
  /// già state lette (il timeout delle query di PostgREST è di pochi
  /// secondi, la finestra è ampiamente sufficiente).
  final Duration pullOverlap;

  static String? _noEmail() => null;
  static const keySeparator = '|';
  static final DateTime _epoch = DateTime.utc(1970);

  late final List<_TableSync<Table, Object?>> _tables = [
    _wallets(),
    _categories(),
    _tags(),
    _customFieldDefs(),
    _costCenters(),
    _budgets(),
    _recurringRules(),
    _dashboardCards(),
    _transactions(),
    _expenseReports(),
    _transactionTags(),
    _customFieldValues(),
    _expenseReportEntries(),
  ];

  @override
  Future<T> exclusive<T>(Future<T> Function() action) => _lock.run(action);

  @override
  Future<void> syncNow() => _lock.run(_syncLocked);

  Future<void> _syncLocked() async {
    final userId = _currentUserId();
    if (userId == null) return;

    if (await _isOwnedByAnotherUser(userId)) {
      throw const LocalDataOwnedByAnotherUserException();
    }
    // Il device viene "rivendicato" PRIMA di inviare qualunque riga: se
    // questa prima sync si interrompe a metà (rete), la riga di stato
    // esiste già e un login successivo di un altro utente resta bloccato
    // comunque. I dati creati in modalità solo-locale, mai sincronizzati,
    // vanno al primo account che fa login (first-sync da locale, voluto).
    await _db
        .into(_db.syncStates)
        .insert(
          SyncStatesCompanion.insert(
            userId: userId,
            lastPushedAt: _epoch,
            lastPulledAt: _epoch,
            userEmail: Value(_currentUserEmail()),
          ),
          mode: InsertMode.insertOrIgnore,
        );

    final startedAt = DateTime.now();
    try {
      var issues = 0;
      for (final table in _tables) {
        issues += await table.push(this, userId);
      }
      DateTime? maxPulled;
      for (final table in _tables) {
        final (tableIssues, tableMax) = await table.pull(this, userId);
        issues += tableIssues;
        if (tableMax != null &&
            (maxPulled == null || tableMax.isAfter(maxPulled))) {
          maxPulled = tableMax;
        }
      }
      _ensureSameUser(userId);
      await (_db.update(
        _db.syncStates,
      )..where((t) => t.userId.equals(userId))).write(
        SyncStatesCompanion(
          lastPushedAt: Value(startedAt),
          lastPulledAt: maxPulled == null
              ? const Value.absent()
              : Value(maxPulled),
          lastSuccessAt: Value(DateTime.now()),
          lastError: const Value(null),
          pendingIssues: Value(issues),
          userEmail: _currentUserEmail() == null
              ? const Value.absent()
              : Value(_currentUserEmail()),
        ),
      );
    } on SyncAbortedException {
      rethrow;
    } catch (_) {
      // Rete assente, server irraggiungibile, risposta inutilizzabile: lo
      // stato resta visibile in Account finché una sync non riesce.
      if (_currentUserId() == userId) {
        await (_db.update(_db.syncStates)
              ..where((t) => t.userId.equals(userId)))
            .write(const SyncStatesCompanion(lastError: Value('failed')));
      }
      rethrow;
    }
  }

  @override
  Future<bool> hasLocalDataOfAnotherUser() async {
    final userId = _currentUserId();
    if (userId == null) return false;
    return _isOwnedByAnotherUser(userId);
  }

  @override
  Future<LocalDataOwner?> localDataOwner() async {
    final row = await (_db.select(_db.syncStates)..limit(1)).getSingleOrNull();
    return row == null
        ? null
        : LocalDataOwner(userId: row.userId, email: row.userEmail);
  }

  @override
  Future<SyncStatus?> status() async {
    final userId = _currentUserId();
    if (userId == null) return null;
    final row = await (_db.select(
      _db.syncStates,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
    if (row == null) return null;
    return SyncStatus(
      lastSuccessAt: row.lastSuccessAt,
      lastError: row.lastError,
      pendingIssues: row.pendingIssues,
    );
  }

  /// Le righe di `SyncStates` sono il marchio di proprietà dei dati locali:
  /// ne esiste una per ogni utente che ha sincronizzato su questo device,
  /// e vengono rimosse solo insieme ai dati (`LocalDataService.wipe`).
  Future<bool> _isOwnedByAnotherUser(String userId) async {
    final other =
        await (_db.select(_db.syncStates)
              ..where((t) => t.userId.equals(userId).not())
              ..limit(1))
            .getSingleOrNull();
    return other != null;
  }

  /// Le richieste HTTP usano il token CORRENTE del client: se nel frattempo
  /// è entrato un altro utente, niente deve più essere scritto.
  void _ensureSameUser(String userId) {
    if (_currentUserId() != userId) throw const SyncAbortedException();
  }

  // -------------------------------------------------------------------
  // Push
  // -------------------------------------------------------------------

  /// Invia le righe in coda per [spec]. Ritorna quante sono state
  /// rifiutate dal server (restano in coda).
  Future<int> _push<T extends Table, D>(
    _TableSync<T, D> spec,
    String userId,
  ) async {
    var rejected = 0;
    var afterSeq = 0;
    while (true) {
      _ensureSameUser(userId);
      final entries =
          await (_db.select(_db.syncOutbox)
                ..where(
                  (o) =>
                      o.syncTable.equals(spec.name) &
                      o.seq.isBiggerThanValue(afterSeq),
                )
                ..orderBy([(o) => OrderingTerm.asc(o.seq)])
                ..limit(pushBatchSize))
              .get();
      if (entries.isEmpty) return rejected;
      afterSeq = entries.last.seq;

      final rows = {
        for (final row in await spec.loadByKeys([
          for (final e in entries) e.rowKey,
        ]))
          spec.keyOfLocal(row): row,
      };
      final pending = <(int, Map<String, dynamic>)>[];
      final gone = <int>[];
      for (final entry in entries) {
        final row = rows[entry.rowKey];
        if (row == null) {
          gone.add(entry.seq); // riga non più esistente in locale
        } else {
          pending.add((entry.seq, spec.toRemote(row, userId)));
        }
      }
      await _ack(gone);
      if (pending.isEmpty) continue;

      try {
        await _remote.upsert(spec.name, [for (final p in pending) p.$2]);
        await _ack([for (final p in pending) p.$1]);
      } on SyncRowRejectedException {
        // Il batch contiene almeno una riga che il server rifiuta: si
        // riprova riga per riga, così le altre passano comunque.
        for (final (seq, payload) in pending) {
          _ensureSameUser(userId);
          try {
            await _remote.upsert(spec.name, [payload]);
            await _ack([seq]);
          } on SyncRowRejectedException {
            rejected++;
          }
        }
      }
    }
  }

  /// Conferma le voci della coda inviate. Una riga modificata durante
  /// l'invio ha nel frattempo un seq nuovo, quindi resta in coda.
  Future<void> _ack(List<int> seqs) async {
    if (seqs.isEmpty) return;
    await (_db.delete(_db.syncOutbox)..where((o) => o.seq.isIn(seqs))).go();
  }

  // -------------------------------------------------------------------
  // Pull
  // -------------------------------------------------------------------

  /// Scarica le righe cambiate di [spec] dal suo watermark. Ritorna le
  /// righe scartate perché malformate e il nuovo watermark.
  Future<(int, DateTime?)> _pull<T extends Table, D>(
    _TableSync<T, D> spec,
    String userId,
  ) async {
    final cursor =
        await (_db.select(_db.syncCursors)..where(
              (c) => c.userId.equals(userId) & c.syncTable.equals(spec.name),
            ))
            .getSingleOrNull();
    var from = cursor == null
        ? _epoch
        : cursor.lastUpdatedAt.subtract(pullOverlap);
    List<String>? afterKey;
    DateTime? maxSeen = cursor?.lastUpdatedAt;
    var invalid = 0;

    while (true) {
      _ensureSameUser(userId);
      final page = await _remote.fetchPage(
        spec.name,
        keyColumns: spec.keyColumns,
        from: from,
        afterKey: afterKey,
        limit: pageSize,
      );
      // Ci si ferma solo su una pagina vuota: se il server tronca le
      // risposte (max_rows più basso di pageSize) non si perde nulla.
      if (page.isEmpty) return (invalid, maxSeen);

      // updated_at e chiave dell'ultima riga sono il cursore: assegnati
      // dal server (NOT NULL), se mancano la risposta è inutilizzabile.
      final last = _Row(page.last);
      final lastUpdatedAt = last.date('updated_at').toUtc();
      final lastKey = spec.keyColumns.map(last.key).toList();

      await _db.transaction(() async {
        _ensureSameUser(userId);
        for (final raw in page) {
          if (!await _apply(spec, _Row(raw))) invalid++;
        }
        if (maxSeen == null || lastUpdatedAt.isAfter(maxSeen!)) {
          maxSeen = lastUpdatedAt;
        }
        await _db
            .into(_db.syncCursors)
            .insertOnConflictUpdate(
              SyncCursorsCompanion.insert(
                userId: userId,
                syncTable: spec.name,
                lastUpdatedAt: maxSeen!,
              ),
            );
      });

      from = lastUpdatedAt;
      afterKey = lastKey;
    }
  }

  /// Applica una riga del server. False se è malformata (quarantena).
  Future<bool> _apply<T extends Table, D>(
    _TableSync<T, D> spec,
    _Row row,
  ) async {
    final String key;
    final DateTime remoteModifiedAt;
    final Insertable<D> companion;
    try {
      key = spec.keyOfRemote(row);
      remoteModifiedAt = row.date('modified_at');
      companion = spec.fromRemote(row);
    } on _InvalidRow {
      return false;
    }

    final queued =
        await (_db.select(_db.syncOutbox)..where(
              (o) => o.syncTable.equals(spec.name) & o.rowKey.equals(key),
            ))
            .getSingleOrNull();
    if (queued != null) {
      // Modifica locale non ancora confermata dal server: vince la più
      // recente (stessa regola del trigger sul server).
      final local = await spec.loadByKeys([key]);
      if (local.isNotEmpty &&
          spec.modifiedAtOf(local.single).isAfter(remoteModifiedAt)) {
        return true;
      }
    }

    await spec.beforeApply?.call(row);
    await _db.into(spec.table).insertOnConflictUpdate(companion);
    // Il trigger ha appena rimesso la riga in coda: è la versione del
    // server, non va reinviata (era l'"eco" che sovrascriveva modifiche
    // più recenti di altri device).
    await (_db.delete(
      _db.syncOutbox,
    )..where((o) => o.syncTable.equals(spec.name) & o.rowKey.equals(key))).go();
    return true;
  }

  // -------------------------------------------------------------------
  // Tabelle
  // -------------------------------------------------------------------

  static String _ts(DateTime d) => d.toUtc().toIso8601String();
  static String? _optTs(DateTime? d) => d?.toIso8601String();

  Future<List<D>> Function(List<String>) _byId<T extends Table, D>(
    TableInfo<T, D> table,
    Expression<String> Function(T t) idColumn,
  ) =>
      (keys) => (_db.select(table)..where((t) => idColumn(t).isIn(keys))).get();

  /// Righe di una tabella con chiave (transaction_id, x): filtro grezzo su
  /// transaction_id, poi esatto in Dart.
  Future<List<D>> Function(List<String>) _byPair<T extends Table, D>(
    TableInfo<T, D> table,
    Expression<String> Function(T t) first,
    String Function(D row) keyOf,
  ) => (keys) async {
    final wanted = keys.toSet();
    final firsts = {for (final k in keys) k.split(keySeparator).first};
    final rows = await (_db.select(
      table,
    )..where((t) => first(t).isIn(firsts))).get();
    return [
      for (final r in rows)
        if (wanted.contains(keyOf(r))) r,
    ];
  };

  _TableSync<$WalletsTable, Wallet> _wallets() => _TableSync(
    name: 'wallets',
    table: _db.wallets,
    keyOfLocal: (w) => w.id,
    loadByKeys: _byId(_db.wallets, (t) => t.id),
    modifiedAtOf: (w) => w.updatedAt,
    // Unica tabella che richiede owner_user_id (non è una colonna del
    // Drift locale, vedi M-ACC1: resta solo lato Postgres).
    toRemote: (w, userId) => {
      'id': w.id,
      'created_at': _ts(w.createdAt),
      'modified_at': _ts(w.updatedAt),
      'deleted_at': _optTs(w.deletedAt),
      'owner_user_id': userId,
      'name': w.name,
      'color_hex': w.colorHex,
      'icon': w.icon,
      'initial_balance_cents': w.initialBalanceCents,
      'archived_at': _optTs(w.archivedAt),
      'position': w.position,
      'currency': w.currency,
    },
    fromRemote: (r) => WalletsCompanion.insert(
      id: r.key('id'),
      createdAt: r.date('created_at'),
      updatedAt: r.date('modified_at'),
      deletedAt: Value(r.optDate('deleted_at')),
      name: r.text('name'),
      colorHex: r.color('color_hex'),
      icon: Value(r.text('icon', max: 64)),
      initialBalanceCents: Value(r.integer('initial_balance_cents')),
      archivedAt: Value(r.optDate('archived_at')),
      position: Value(r.integer('position')),
      currency: Value(r.currency('currency')),
    ),
  );

  _TableSync<$CategoriesTable, Category> _categories() => _TableSync(
    name: 'categories',
    table: _db.categories,
    keyOfLocal: (c) => c.id,
    loadByKeys: _byId(_db.categories, (t) => t.id),
    modifiedAtOf: (c) => c.updatedAt,
    toRemote: (c, _) => {
      'id': c.id,
      'created_at': _ts(c.createdAt),
      'modified_at': _ts(c.updatedAt),
      'deleted_at': _optTs(c.deletedAt),
      'wallet_id': c.walletId,
      'name': c.name,
      'icon': c.icon,
      'color_hex': c.colorHex,
      'kind': c.kind.name,
      'parent_id': c.parentId,
      'sort_order': c.sortOrder,
      'is_default': c.isDefault,
    },
    fromRemote: (r) => CategoriesCompanion.insert(
      id: r.key('id'),
      createdAt: r.date('created_at'),
      updatedAt: r.date('modified_at'),
      deletedAt: Value(r.optDate('deleted_at')),
      walletId: Value(r.key('wallet_id')),
      name: r.text('name'),
      icon: r.text('icon', max: 64),
      colorHex: r.color('color_hex'),
      kind: r.enumByName(CategoryKind.values, 'kind'),
      parentId: Value(r.optKey('parent_id')),
      sortOrder: Value(r.integer('sort_order')),
      isDefault: Value(r.boolean('is_default')),
    ),
  );

  _TableSync<$TagsTable, Tag> _tags() => _TableSync(
    name: 'tags',
    table: _db.tags,
    keyOfLocal: (t) => t.id,
    loadByKeys: _byId(_db.tags, (t) => t.id),
    modifiedAtOf: (t) => t.updatedAt,
    toRemote: (t, _) => {
      'id': t.id,
      'created_at': _ts(t.createdAt),
      'modified_at': _ts(t.updatedAt),
      'deleted_at': _optTs(t.deletedAt),
      'wallet_id': t.walletId,
      'name': t.name,
    },
    fromRemote: (r) => TagsCompanion.insert(
      id: r.key('id'),
      createdAt: r.date('created_at'),
      updatedAt: r.date('modified_at'),
      deletedAt: Value(r.optDate('deleted_at')),
      walletId: Value(r.key('wallet_id')),
      name: r.text('name'),
    ),
  );

  _TableSync<$CustomFieldDefsTable, CustomFieldDef> _customFieldDefs() =>
      _TableSync(
        name: 'custom_field_defs',
        table: _db.customFieldDefs,
        keyOfLocal: (f) => f.id,
        loadByKeys: _byId(_db.customFieldDefs, (t) => t.id),
        modifiedAtOf: (f) => f.updatedAt,
        toRemote: (f, _) => {
          'id': f.id,
          'created_at': _ts(f.createdAt),
          'modified_at': _ts(f.updatedAt),
          'deleted_at': _optTs(f.deletedAt),
          'wallet_id': f.walletId,
          'name': f.name,
          'type': f.type.name,
          'expense_report_only': f.expenseReportOnly,
          'options': f.options,
          'sort_order': f.sortOrder,
        },
        fromRemote: (r) => CustomFieldDefsCompanion.insert(
          id: r.key('id'),
          createdAt: r.date('created_at'),
          updatedAt: r.date('modified_at'),
          deletedAt: Value(r.optDate('deleted_at')),
          walletId: Value(r.key('wallet_id')),
          name: r.text('name'),
          type: r.enumByName(CustomFieldType.values, 'type'),
          expenseReportOnly: Value(r.boolean('expense_report_only')),
          options: Value(r.optStringList('options')),
          sortOrder: Value(r.integer('sort_order')),
        ),
      );

  _TableSync<$CostCentersTable, CostCenter> _costCenters() => _TableSync(
    name: 'cost_centers',
    table: _db.costCenters,
    keyOfLocal: (c) => c.id,
    loadByKeys: _byId(_db.costCenters, (t) => t.id),
    modifiedAtOf: (c) => c.updatedAt,
    toRemote: (c, _) => {
      'id': c.id,
      'created_at': _ts(c.createdAt),
      'modified_at': _ts(c.updatedAt),
      'deleted_at': _optTs(c.deletedAt),
      'wallet_id': c.walletId,
      'name': c.name,
    },
    fromRemote: (r) => CostCentersCompanion.insert(
      id: r.key('id'),
      createdAt: r.date('created_at'),
      updatedAt: r.date('modified_at'),
      deletedAt: Value(r.optDate('deleted_at')),
      walletId: Value(r.key('wallet_id')),
      name: r.text('name'),
    ),
  );

  _TableSync<$BudgetsTable, Budget> _budgets() => _TableSync(
    name: 'budgets',
    table: _db.budgets,
    keyOfLocal: (b) => b.id,
    loadByKeys: _byId(_db.budgets, (t) => t.id),
    modifiedAtOf: (b) => b.updatedAt,
    toRemote: (b, _) => {
      'id': b.id,
      'created_at': _ts(b.createdAt),
      'modified_at': _ts(b.updatedAt),
      'deleted_at': _optTs(b.deletedAt),
      'wallet_id': b.walletId,
      'category_id': b.categoryId,
      'limit_cents': b.limitCents,
    },
    fromRemote: (r) => BudgetsCompanion.insert(
      id: r.key('id'),
      createdAt: r.date('created_at'),
      updatedAt: r.date('modified_at'),
      deletedAt: Value(r.optDate('deleted_at')),
      walletId: Value(r.key('wallet_id')),
      categoryId: r.key('category_id'),
      limitCents: r.integer('limit_cents', min: 0),
    ),
    // Un budget vivo per categoria: se il server ne ha uno con un altro id
    // (due device offline sulla stessa categoria), quello locale lascia il
    // posto e il suo soft-delete si propaga alla sync successiva.
    beforeApply: (r) async {
      if (r['deleted_at'] != null) return;
      await (_db.update(_db.budgets)..where(
            (t) =>
                t.categoryId.equals(r.key('category_id')) &
                t.id.equals(r.key('id')).not() &
                t.deletedAt.isNull(),
          ))
          .write(
            BudgetsCompanion(
              deletedAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );
    },
  );

  _TableSync<$RecurringRulesTable, RecurringRule> _recurringRules() =>
      _TableSync(
        name: 'recurring_rules',
        table: _db.recurringRules,
        keyOfLocal: (r) => r.id,
        loadByKeys: _byId(_db.recurringRules, (t) => t.id),
        modifiedAtOf: (r) => r.updatedAt,
        toRemote: (r, _) => {
          'id': r.id,
          'created_at': _ts(r.createdAt),
          'modified_at': _ts(r.updatedAt),
          'deleted_at': _optTs(r.deletedAt),
          'wallet_id': r.walletId,
          'category_id': r.categoryId,
          'type': r.type.name,
          'amount_cents': r.amountCents,
          'description': r.description,
          'frequency': r.frequency.name,
          'start_at': r.startAt.toIso8601String(),
          'next_run_at': r.nextRunAt.toIso8601String(),
          'end_at': _optTs(r.endAt),
          'paused_at': _optTs(r.pausedAt),
        },
        fromRemote: (r) => RecurringRulesCompanion.insert(
          id: r.key('id'),
          createdAt: r.date('created_at'),
          updatedAt: r.date('modified_at'),
          deletedAt: Value(r.optDate('deleted_at')),
          walletId: r.key('wallet_id'),
          categoryId: Value(r.optKey('category_id')),
          type: r.enumByName(TransactionType.values, 'type'),
          amountCents: r.integer('amount_cents', min: 0),
          description: Value(r.text('description', max: 1000)),
          frequency: r.enumByName(RecurrenceFrequency.values, 'frequency'),
          startAt: r.date('start_at'),
          nextRunAt: r.date('next_run_at'),
          endAt: Value(r.optDate('end_at')),
          pausedAt: Value(r.optDate('paused_at')),
        ),
      );

  _TableSync<$DashboardCardsTable, DashboardCard> _dashboardCards() =>
      _TableSync(
        name: 'dashboard_cards',
        table: _db.dashboardCards,
        keyOfLocal: (d) => d.id,
        loadByKeys: _byId(_db.dashboardCards, (t) => t.id),
        modifiedAtOf: (d) => d.updatedAt,
        toRemote: (d, _) => {
          'id': d.id,
          'created_at': _ts(d.createdAt),
          'modified_at': _ts(d.updatedAt),
          'deleted_at': _optTs(d.deletedAt),
          'wallet_id': d.walletId,
          'type': d.type,
          'position': d.position,
          'config_json': jsonDecode(d.configJson),
        },
        fromRemote: (r) => DashboardCardsCompanion.insert(
          id: r.key('id'),
          createdAt: r.date('created_at'),
          updatedAt: r.date('modified_at'),
          deletedAt: Value(r.optDate('deleted_at')),
          walletId: Value(r.key('wallet_id')),
          type: r.text('type', max: 64),
          position: r.integer('position'),
          configJson: Value(jsonEncode(r.jsonObject('config_json'))),
        ),
      );

  _TableSync<$TransactionsTable, Transaction> _transactions() => _TableSync(
    name: 'transactions',
    table: _db.transactions,
    keyOfLocal: (t) => t.id,
    loadByKeys: _byId(_db.transactions, (t) => t.id),
    modifiedAtOf: (t) => t.updatedAt,
    toRemote: (t, _) => {
      'id': t.id,
      'created_at': _ts(t.createdAt),
      'modified_at': _ts(t.updatedAt),
      'deleted_at': _optTs(t.deletedAt),
      'wallet_id': t.walletId,
      'type': t.type.name,
      'amount_cents': t.amountCents,
      'date': t.date.toIso8601String(),
      'wallet_to_id': t.walletToId,
      'category_id': t.categoryId,
      'description': t.description,
      'note': t.note,
      'entry_currency': t.entryCurrency,
      'entry_amount_cents': t.entryAmountCents,
      'amount_cents_to': t.amountCentsTo,
    },
    fromRemote: (r) => TransactionsCompanion.insert(
      id: r.key('id'),
      createdAt: r.date('created_at'),
      updatedAt: r.date('modified_at'),
      deletedAt: Value(r.optDate('deleted_at')),
      type: r.enumByName(TransactionType.values, 'type'),
      amountCents: r.integer('amount_cents', min: 0),
      date: r.date('date'),
      walletId: r.key('wallet_id'),
      walletToId: Value(r.optKey('wallet_to_id')),
      categoryId: Value(r.optKey('category_id')),
      description: Value(r.text('description', max: 1000)),
      note: Value(r.optText('note', max: 10000)),
      entryCurrency: Value(r.optCurrency('entry_currency')),
      entryAmountCents: Value(r.optInteger('entry_amount_cents', min: 0)),
      amountCentsTo: Value(r.optInteger('amount_cents_to', min: 0)),
    ),
  );

  _TableSync<$ExpenseReportsTable, ExpenseReport> _expenseReports() =>
      _TableSync(
        name: 'expense_reports',
        table: _db.expenseReports,
        keyOfLocal: (r) => r.id,
        loadByKeys: _byId(_db.expenseReports, (t) => t.id),
        modifiedAtOf: (r) => r.updatedAt,
        toRemote: (r, _) => {
          'id': r.id,
          'created_at': _ts(r.createdAt),
          'modified_at': _ts(r.updatedAt),
          'deleted_at': _optTs(r.deletedAt),
          'wallet_id': r.walletId,
          'name': r.name,
          'date_from': r.dateFrom.toIso8601String(),
          'date_to': r.dateTo.toIso8601String(),
          'status': r.status.name,
          'reimburse_tx_id': r.reimburseTxId,
        },
        fromRemote: (r) => ExpenseReportsCompanion.insert(
          id: r.key('id'),
          createdAt: r.date('created_at'),
          updatedAt: r.date('modified_at'),
          deletedAt: Value(r.optDate('deleted_at')),
          walletId: Value(r.key('wallet_id')),
          name: r.text('name'),
          dateFrom: r.date('date_from'),
          dateTo: r.date('date_to'),
          status: r.enumByName(ExpenseReportStatus.values, 'status'),
          reimburseTxId: Value(r.optKey('reimburse_tx_id')),
        ),
      );

  _TableSync<$TransactionTagsTable, TransactionTag> _transactionTags() =>
      _TableSync(
        name: 'transaction_tags',
        table: _db.transactionTags,
        keyColumns: const ['transaction_id', 'tag_id'],
        keyOfLocal: (t) => '${t.transactionId}$keySeparator${t.tagId}',
        loadByKeys: _byPair(
          _db.transactionTags,
          (t) => t.transactionId,
          (t) => '${t.transactionId}$keySeparator${t.tagId}',
        ),
        modifiedAtOf: (t) => t.updatedAt,
        toRemote: (t, _) => {
          'transaction_id': t.transactionId,
          'tag_id': t.tagId,
          'created_at': _ts(t.createdAt),
          'modified_at': _ts(t.updatedAt),
          'deleted_at': _optTs(t.deletedAt),
        },
        fromRemote: (r) => TransactionTagsCompanion.insert(
          transactionId: r.key('transaction_id'),
          tagId: r.key('tag_id'),
          createdAt: r.date('created_at'),
          updatedAt: Value(r.date('modified_at')),
          deletedAt: Value(r.optDate('deleted_at')),
        ),
      );

  _TableSync<$CustomFieldValuesTable, CustomFieldValue> _customFieldValues() =>
      _TableSync(
        name: 'custom_field_values',
        table: _db.customFieldValues,
        keyColumns: const ['transaction_id', 'field_id'],
        keyOfLocal: (v) => '${v.transactionId}$keySeparator${v.fieldId}',
        loadByKeys: _byPair(
          _db.customFieldValues,
          (t) => t.transactionId,
          (v) => '${v.transactionId}$keySeparator${v.fieldId}',
        ),
        modifiedAtOf: (v) => v.updatedAt,
        toRemote: (v, _) => {
          'transaction_id': v.transactionId,
          'field_id': v.fieldId,
          'value': v.value,
          'modified_at': _ts(v.updatedAt),
        },
        fromRemote: (r) => CustomFieldValuesCompanion.insert(
          transactionId: r.key('transaction_id'),
          fieldId: r.key('field_id'),
          value: r.text('value', max: 2000),
          updatedAt: r.date('modified_at'),
        ),
      );

  _TableSync<$ExpenseReportEntriesTable, ExpenseReportEntry>
  _expenseReportEntries() => _TableSync(
    name: 'expense_report_entries',
    table: _db.expenseReportEntries,
    keyColumns: const ['transaction_id'],
    keyOfLocal: (e) => e.transactionId,
    loadByKeys: _byId(_db.expenseReportEntries, (t) => t.transactionId),
    modifiedAtOf: (e) => e.updatedAt,
    toRemote: (e, _) => {
      'transaction_id': e.transactionId,
      'cost_center_id': e.costCenterId,
      'reimbursable': e.reimbursable,
      'e_invoice': e.eInvoice,
      'report_id': e.reportId,
      'modified_at': _ts(e.updatedAt),
      'deleted_at': _optTs(e.deletedAt),
    },
    fromRemote: (r) => ExpenseReportEntriesCompanion.insert(
      transactionId: r.key('transaction_id'),
      costCenterId: Value(r.optKey('cost_center_id')),
      reimbursable: Value(r.boolean('reimbursable')),
      eInvoice: Value(r.boolean('e_invoice')),
      reportId: Value(r.optKey('report_id')),
      updatedAt: r.date('modified_at'),
      deletedAt: Value(r.optDate('deleted_at')),
    ),
  );
}
