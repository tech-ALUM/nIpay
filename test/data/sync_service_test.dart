import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/db/tables.dart';
import 'package:nipay/data/repositories/budget_repository.dart';
import 'package:nipay/data/repositories/expense_report_repository.dart';
import 'package:nipay/data/repositories/tag_repository.dart';
import 'package:nipay/data/services/local_data_service.dart';
import 'package:nipay/data/services/sync_lock.dart';
import 'package:nipay/data/services/sync_service.dart';

import '../support/property.dart';

/// Finto "server" in memoria che replica la semantica di Postgres dopo le
/// migration di supabase/migrations/20261005* (trigger `sync_stamp`):
///   * `updated_at` assegnato dal server a ogni scrittura accettata, con
///     un orologio proprio (spostabile con [clockOffset]);
///   * `modified_at` del client limitato a "adesso" del server, scrittura
///     scartata se non più recente della versione presente (LWW);
///   * `created_at` limitato a "adesso" e immutabile;
///   * batch atomico: se una riga viene rifiutata, nessuna viene scritta;
///   * un solo budget vivo per (wallet_id, category_id);
///   * paginazione keyset su (updated_at, chiave), con troncamento
///     opzionale a [maxRows] come PostgREST.
class FakeSyncRemote implements SyncRemote {
  FakeSyncRemote({this.clockOffset = Duration.zero});

  final Map<String, Map<String, Map<String, dynamic>>> tables = {};
  Duration clockOffset;
  DateTime _last = DateTime.utc(2000);

  /// Se valorizzato, l'upsert su questa tabella fallisce (rete caduta).
  String? failOnUpsertTo;

  /// Righe che il server rifiuta (vincolo violato, RLS).
  bool Function(String table, Map<String, dynamic> row)? rejectRow;

  /// Chiamato prima di ogni pagina di pull (scritture concorrenti, pause).
  Future<void> Function(String table)? onFetch;

  /// Chiamato dopo ogni upsert accettato (modifiche locali durante l'invio).
  Future<void> Function(String table)? afterUpsert;

  /// Limite di righe per risposta imposto dal server (max_rows).
  int? maxRows;

  int upsertedRows = 0;

  static const _keys = {
    'transaction_tags': ['transaction_id', 'tag_id'],
    'custom_field_values': ['transaction_id', 'field_id'],
    'expense_report_entries': ['transaction_id'],
  };

  static List<String> keysOf(String table) => _keys[table] ?? const ['id'];

  String _keyOf(String table, Map<String, dynamic> row) =>
      keysOf(table).map((c) => row[c]).join('|');

  DateTime serverNow() {
    var t = DateTime.now().toUtc().add(clockOffset);
    if (!t.isAfter(_last)) t = _last.add(const Duration(microseconds: 1));
    return _last = t;
  }

  static DateTime _min(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
  static String _iso(DateTime d) => d.toUtc().toIso8601String();

  List<Map<String, dynamic>> rowsOf(String table) =>
      (tables[table] ?? const {}).values.toList();

  Map<String, dynamic>? row(String table, String key) => tables[table]?[key];

  /// Modifica fatta "da un altro device" direttamente sul server.
  void serverUpdate(String table, String key, Map<String, dynamic> changes) {
    final existing = tables[table]![key]!;
    final ts = serverNow();
    tables[table]![key] = {
      ...existing,
      ...changes,
      'modified_at': _iso(ts),
      'updated_at': _iso(ts),
    };
  }

  void _checkBudgets(List<Map<String, dynamic>> rows) {
    final live = <String, String>{
      for (final b in rowsOf('budgets'))
        if (b['deleted_at'] == null)
          '${b['wallet_id']}|${b['category_id']}': b['id'] as String,
    };
    for (final b in rows) {
      final slot = '${b['wallet_id']}|${b['category_id']}';
      if (b['deleted_at'] != null) {
        if (live[slot] == b['id']) live.remove(slot);
        continue;
      }
      final holder = live[slot];
      if (holder != null && holder != b['id']) {
        throw const SyncRowRejectedException('23505');
      }
      live[slot] = b['id'] as String;
    }
  }

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    if (table == failOnUpsertTo) throw Exception('rete non disponibile');
    if (rows.isEmpty) return;
    if (rows.any((r) => rejectRow?.call(table, r) ?? false)) {
      throw const SyncRowRejectedException('23514');
    }
    if (table == 'budgets') _checkBudgets(rows);

    final store = tables.putIfAbsent(table, () => {});
    for (final row in rows) {
      final key = _keyOf(table, row);
      final ts = serverNow();
      final incoming = row['modified_at'] == null
          ? null
          : DateTime.parse(row['modified_at'] as String);
      final existing = store[key];
      if (existing == null) {
        final created = row['created_at'] == null
            ? ts
            : DateTime.parse(row['created_at'] as String);
        store[key] = {
          ...row,
          'created_at': _iso(_min(created, ts)),
          'modified_at': _iso(_min(incoming ?? ts, ts)),
          'updated_at': _iso(ts),
        };
      } else {
        final old = DateTime.parse(existing['modified_at'] as String);
        DateTime modified;
        if (incoming == null || incoming.isAtSameMomentAs(old)) {
          modified = ts;
        } else {
          modified = _min(incoming, ts);
          if (!modified.isAfter(old)) continue; // LWW: si tiene il server
        }
        store[key] = {
          ...existing,
          ...row,
          'created_at': existing['created_at'],
          'modified_at': _iso(modified),
          'updated_at': _iso(ts),
        };
      }
      upsertedRows++;
    }
    await afterUpsert?.call(table);
  }

  int _compare(String table, Map<String, dynamic> a, Map<String, dynamic> b) {
    final byTime = DateTime.parse(
      a['updated_at'] as String,
    ).compareTo(DateTime.parse(b['updated_at'] as String));
    if (byTime != 0) return byTime;
    for (final k in keysOf(table)) {
      final c = (a[k] as String).compareTo(b[k] as String);
      if (c != 0) return c;
    }
    return 0;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPage(
    String table, {
    required List<String> keyColumns,
    required DateTime from,
    List<String>? afterKey,
    required int limit,
  }) async {
    await onFetch?.call(table);
    final sorted = rowsOf(table).toList()
      ..sort((a, b) => _compare(table, a, b));
    final cursor = {
      'updated_at': _iso(from),
      for (final (i, k) in keyColumns.indexed) k: afterKey?[i],
    };
    return sorted
        .where((r) {
          if (afterKey == null) {
            return !DateTime.parse(r['updated_at'] as String).isBefore(from);
          }
          return _compare(table, r, cursor) > 0;
        })
        .take(maxRows == null || maxRows! > limit ? limit : maxRows!)
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }
}

const _userId = 'user-1';
const _otherUserId = 'user-2';

Future<void> _insertWallet(
  AppDatabase db, {
  required String id,
  required String name,
  required DateTime updatedAt,
}) {
  return db
      .into(db.wallets)
      .insertOnConflictUpdate(
        WalletsCompanion.insert(
          id: id,
          createdAt: updatedAt,
          updatedAt: updatedAt,
          name: name,
          colorHex: '#000000',
        ),
      );
}

Future<void> _insertCategory(
  AppDatabase db,
  String id, {
  String wallet = 'w1',
}) => db
    .into(db.categories)
    .insert(
      CategoriesCompanion.insert(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        walletId: Value(wallet),
        name: 'Spesa',
        icon: 'cart',
        colorHex: '#111111',
        kind: CategoryKind.expense,
      ),
    );

Future<void> _insertTransaction(
  AppDatabase db,
  String id, {
  int amount = 1000,
  String wallet = 'w1',
}) => db
    .into(db.transactions)
    .insert(
      TransactionsCompanion.insert(
        id: id,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        type: TransactionType.expense,
        amountCents: amount,
        date: DateTime.now(),
        walletId: wallet,
      ),
    );

Future<void> _setAmount(AppDatabase db, String id, int amount, DateTime at) =>
    (db.update(db.transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(amountCents: Value(amount), updatedAt: Value(at)),
    );

Future<int> _amountOf(AppDatabase db, String id) async => (await (db.select(
  db.transactions,
)..where((t) => t.id.equals(id))).getSingle()).amountCents;

void main() {
  // Questi test aprono deliberatamente più AppDatabase in-memory nello
  // stesso processo per simulare più dispositivi: il warning di Drift su
  // "istanze multiple" non si applica (non condividono un QueryExecutor).
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  late AppDatabase deviceA;
  late AppDatabase deviceB;
  late FakeSyncRemote remote;

  setUp(() {
    deviceA = AppDatabase(NativeDatabase.memory());
    deviceB = AppDatabase(NativeDatabase.memory());
    remote = FakeSyncRemote();
  });

  tearDown(() async {
    await deviceA.close();
    await deviceB.close();
  });

  SupabaseSyncService serviceFor(AppDatabase db, {int pageSize = 500}) =>
      SupabaseSyncService(
        remote,
        db,
        currentUserId: () => _userId,
        pageSize: pageSize,
      );

  Future<int> outboxSize(AppDatabase db) async =>
      (await db.select(db.syncOutbox).get()).length;

  test('syncNow is a silent no-op when nobody is logged in', () async {
    final service = SupabaseSyncService(
      remote,
      deviceA,
      currentUserId: () => null,
    );
    await service.syncNow(); // non deve lanciare
  });

  test('a locally created wallet is pushed with the owner user id', () async {
    await _insertWallet(
      deviceA,
      id: 'w1',
      name: 'Conto',
      updatedAt: DateTime.utc(2024),
    );

    await serviceFor(deviceA).syncNow();

    final pushed = remote.rowsOf('wallets');
    expect(pushed, hasLength(1));
    expect(pushed.single['name'], 'Conto');
    expect(pushed.single['owner_user_id'], _userId);
    expect(
      pushed.single.containsKey('updated_at'),
      isTrue,
      reason: 'updated_at lo assegna il server',
    );
    expect(await outboxSize(deviceA), 0, reason: 'confermato dal server');
  });

  test(
    'the client never sends updated_at: it is the server watermark',
    () async {
      final sent = <Map<String, dynamic>>[];
      final spy = _SpyRemote(remote, sent);
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      await _insertTransaction(deviceA, 'tx1');
      await deviceA
          .into(deviceA.tags)
          .insert(
            TagsCompanion.insert(
              id: 'tag1',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              walletId: const Value('w1'),
              name: 'lavoro',
            ),
          );
      await DriftTagRepository(deviceA).tagTransaction('tx1', 'tag1');

      await SupabaseSyncService(
        spy,
        deviceA,
        currentUserId: () => _userId,
      ).syncNow();

      expect(sent, isNotEmpty);
      expect(sent.where((r) => r.containsKey('updated_at')), isEmpty);
      expect(sent.every((r) => r.containsKey('modified_at')), isTrue);
    },
  );

  test(
    'a wallet pushed from device A appears on device B after sync',
    () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto condiviso',
        updatedAt: DateTime.utc(2024),
      );
      await serviceFor(deviceA).syncNow();

      // Device B parte vuoto: la sua stessa prima sync deve tirare giù
      // tutto ciò che esiste già sul server per questo utente.
      await serviceFor(deviceB).syncNow();

      final wallets = await deviceB.select(deviceB.wallets).get();
      expect(wallets, hasLength(1));
      expect(wallets.single.id, 'w1');
      expect(wallets.single.name, 'Conto condiviso');
      expect(
        await outboxSize(deviceB),
        0,
        reason: 'le righe scaricate non vengono reinviate (niente "eco")',
      );
    },
  );

  test(
    'categories sync after their wallet, respecting the foreign key',
    () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.utc(2024),
      );
      await _insertCategory(deviceA, 'c1');

      await serviceFor(deviceA).syncNow();
      await serviceFor(deviceB).syncNow();

      final categories = await deviceB.select(deviceB.categories).get();
      expect(categories, hasLength(1));
      expect(categories.single.walletId, 'w1');
    },
  );

  test(
    'a soft-deleted wallet propagates deletedAt to the other device',
    () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.utc(2024),
      );
      await serviceFor(deviceA).syncNow();
      await serviceFor(deviceB).syncNow();

      await (deviceA.update(
        deviceA.wallets,
      )..where((t) => t.id.equals('w1'))).write(
        WalletsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await serviceFor(deviceA).syncNow();
      await serviceFor(deviceB).syncNow();

      final wallet = await (deviceB.select(
        deviceB.wallets,
      )..where((t) => t.id.equals('w1'))).getSingle();
      expect(wallet.deletedAt, isNotNull);
    },
  );

  // ===================================================================
  // Regressioni delle PoC di SECURITY_AUDIT.md (Appendice A), invertite.
  // ===================================================================
  group('SECURITY_AUDIT PoC (regressione)', () {
    test('PoC 1 / NIP-02: a device with the clock ahead (or a forged '
        'created_at) no longer poisons the other devices', () async {
      final skewed = DateTime.now().add(const Duration(days: 1));
      await _insertWallet(deviceA, id: 'w1', name: 'Conto', updatedAt: skewed);
      await _insertTransaction(deviceA, 'tx1');
      await deviceA
          .into(deviceA.tags)
          .insert(
            TagsCompanion.insert(
              id: 'tag1',
              createdAt: skewed,
              updatedAt: skewed,
              walletId: const Value('w1'),
              name: 'lavoro',
            ),
          );
      await deviceA
          .into(deviceA.transactionTags)
          .insert(
            TransactionTagsCompanion.insert(
              transactionId: 'tx1',
              tagId: 'tag1',
              createdAt: skewed,
              updatedAt: Value(skewed),
            ),
          );
      await serviceFor(deviceA).syncNow();
      await serviceFor(deviceB).syncNow();

      // Il server non ha accettato timestamp futuri.
      final tag = remote.rowsOf('transaction_tags').single;
      expect(
        DateTime.parse(tag['created_at'] as String).isAfter(remote.serverNow()),
        isFalse,
      );

      // A cambia poi l'importo: B lo riceve.
      await _setAmount(
        deviceA,
        'tx1',
        99900,
        DateTime.now().add(const Duration(days: 2)),
      );
      await serviceFor(deviceA).syncNow();
      await serviceFor(deviceB).syncNow();
      expect(await _amountOf(deviceB, 'tx1'), 99900);

      // Il modified_at "nel futuro" di A è stato limitato all'ora del
      // server: una modifica successiva di B vince, invece di perdere per
      // due giorni contro una data falsa.
      await _setAmount(deviceB, 'tx1', 500, DateTime.now());
      await serviceFor(deviceB).syncNow();
      await serviceFor(deviceA).syncNow();
      expect(await _amountOf(deviceA, 'tx1'), 500);
      expect(remote.row('transactions', 'tx1')!['amount_cents'], 500);
    });

    test('PoC 2 / NIP-01: a change made to an already-pulled table during '
        'the sync is not lost', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      await _insertTransaction(deviceA, 'tx1');
      await serviceFor(deviceA).syncNow();
      await serviceFor(deviceB).syncNow();

      var injected = false;
      remote.onFetch = (table) async {
        if (table == 'categories' && !injected) {
          injected = true;
          remote.serverUpdate('wallets', 'w1', {'name': 'Conto RINOMINATO'});
          remote.serverUpdate('transactions', 'tx1', {
            'description': 'modificata',
          });
        }
      };
      await serviceFor(deviceB).syncNow();
      remote.onFetch = null;
      await serviceFor(deviceB).syncNow();

      final wB = await deviceB.select(deviceB.wallets).getSingle();
      expect(wB.name, 'Conto RINOMINATO');
      final txB = await deviceB.select(deviceB.transactions).getSingle();
      expect(txB.description, 'modificata');
    });

    test('PoC 3 / NIP-03: an older offline edit no longer overwrites a '
        'newer edit from another device', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      await _insertTransaction(deviceA, 'tx1');
      await serviceFor(deviceA).syncNow();
      await serviceFor(deviceB).syncNow();

      // 10:00 A (offline) corregge l'importo a 1500.
      await _setAmount(deviceA, 'tx1', 1500, DateTime.now());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      // 10:05 B corregge l'importo a 2000 e sincronizza subito.
      await _setAmount(deviceB, 'tx1', 2000, DateTime.now());
      await serviceFor(deviceB).syncNow();
      // 10:30 A torna online: vince la modifica più recente (2000).
      await serviceFor(deviceA).syncNow();
      await serviceFor(deviceB).syncNow();

      expect(remote.row('transactions', 'tx1')!['amount_cents'], 2000);
      expect(await _amountOf(deviceA, 'tx1'), 2000);
      expect(await _amountOf(deviceB, 'tx1'), 2000);
    });

    test('NIP-03: a soft-delete is not undone by a stale push', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      await _insertTransaction(deviceA, 'tx1');
      await serviceFor(deviceA).syncNow();
      await serviceFor(deviceB).syncNow();

      // A modifica offline (prima), B cancella (dopo) e sincronizza.
      await _setAmount(deviceA, 'tx1', 1234, DateTime.now());
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await (deviceB.update(
        deviceB.transactions,
      )..where((t) => t.id.equals('tx1'))).write(
        TransactionsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
      await serviceFor(deviceB).syncNow();
      await serviceFor(deviceA).syncNow();

      expect(remote.row('transactions', 'tx1')!['deleted_at'], isNotNull);
      final txA = await deviceA.select(deviceA.transactions).getSingle();
      expect(txA.deletedAt, isNotNull, reason: 'la cancellazione arriva su A');
    });

    Future<void> renameWallet(AppDatabase db, String name) =>
        (db.update(db.wallets)..where((t) => t.id.equals('w1'))).write(
          WalletsCompanion(name: Value(name), updatedAt: Value(DateTime.now())),
        );

    test('NIP-03: an edit made while the push is in flight is not lost '
        '(its new queue entry is sent too)', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      var edited = false;
      remote.afterUpsert = (table) async {
        if (table == 'wallets' && !edited) {
          edited = true;
          await renameWallet(deviceA, 'Modificato durante l\'invio');
        }
      };
      await serviceFor(deviceA).syncNow();
      expect(
        remote.row('wallets', 'w1')!['name'],
        'Modificato durante l\'invio',
      );
      expect(await outboxSize(deviceA), 0);
    });

    test('NIP-03: an edit made during the pull is neither overwritten nor '
        'lost: it stays queued for the next sync', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      await serviceFor(deviceA).syncNow();
      remote.serverUpdate('wallets', 'w1', {'name': 'Dal server'});

      var edited = false;
      remote.onFetch = (table) async {
        // Prima del pull dei wallet: la versione del server è più vecchia
        // della modifica locale, che quindi non va sovrascritta.
        if (table == 'wallets' && !edited) {
          edited = true;
          await Future<void>.delayed(const Duration(milliseconds: 2));
          await renameWallet(deviceA, 'Modificato durante il pull');
        }
      };
      await serviceFor(deviceA).syncNow();
      remote.onFetch = null;
      final local = await deviceA.select(deviceA.wallets).getSingle();
      expect(local.name, 'Modificato durante il pull');
      expect(await outboxSize(deviceA), 1);

      await serviceFor(deviceA).syncNow();
      expect(
        remote.row('wallets', 'w1')!['name'],
        'Modificato durante il pull',
      );
      expect(await outboxSize(deviceA), 0);
    });
  });

  group('NIP-01: pull paginato', () {
    test('a new device receives every row even when the server truncates '
        'responses (max_rows) and pages are small', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      for (var i = 0; i < 37; i++) {
        await _insertTransaction(deviceA, 'tx${i.toString().padLeft(2, '0')}');
      }
      await serviceFor(deviceA).syncNow();
      expect(remote.rowsOf('transactions'), hasLength(37));

      remote.maxRows = 4; // il server ne restituisce meno di pageSize
      await serviceFor(deviceB, pageSize: 10).syncNow();

      expect(await deviceB.select(deviceB.transactions).get(), hasLength(37));
    });

    test('a row committed late with an older updated_at is still pulled '
        '(overlap window)', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      await _insertTransaction(deviceA, 'tx1');
      await serviceFor(deviceA).syncNow();
      await serviceFor(deviceB).syncNow();

      // Riga scritta "prima" del watermark di B ma visibile solo ora
      // (transazione Postgres che committa in ritardo).
      final w = remote.row('transactions', 'tx1')!;
      final late = DateTime.parse(
        w['updated_at'] as String,
      ).subtract(const Duration(seconds: 30));
      remote.tables['transactions']!['tx2'] = {
        ...w,
        'id': 'tx2',
        'updated_at': late.toIso8601String(),
        'modified_at': late.toIso8601String(),
      };
      await serviceFor(deviceB).syncNow();

      expect(await deviceB.select(deviceB.transactions).get(), hasLength(2));
    });
  });

  group('NIP-04: righe avvelenate isolate', () {
    test('a malformed row from the server is quarantined: the rest syncs, '
        'the watermark advances and the issue is reported', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      await deviceA
          .into(deviceA.customFieldDefs)
          .insert(
            CustomFieldDefsCompanion.insert(
              id: 'f1',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              walletId: const Value('w1'),
              name: 'Progetto',
              type: CustomFieldType.choice,
              options: const Value(['a', 'b']),
            ),
          );
      await _insertTransaction(deviceA, 'tx1');
      await serviceFor(deviceA).syncNow();
      // Riga manomessa direttamente sul server.
      remote.serverUpdate('custom_field_defs', 'f1', {
        'options': {'non': 'una lista'},
      });

      final b = serviceFor(deviceB);
      await b.syncNow(); // non lancia
      expect(await deviceB.select(deviceB.transactions).get(), hasLength(1));
      expect(await deviceB.select(deviceB.customFieldDefs).get(), isEmpty);
      expect((await b.status())!.pendingIssues, 1);

      // Le sync successive non riscaricano la riga e vanno a buon fine.
      await _setAmount(deviceA, 'tx1', 4200, DateTime.now());
      await serviceFor(deviceA).syncNow();
      await b.syncNow();
      expect(await _amountOf(deviceB, 'tx1'), 4200);
      expect((await b.status())!.lastError, isNull);
    });

    test('a row rejected by the server stays queued without blocking the '
        'other rows or tables', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      await _insertTransaction(deviceA, 'tx-ok');
      await _insertTransaction(deviceA, 'tx-bad');
      await deviceA
          .into(deviceA.costCenters)
          .insert(
            CostCentersCompanion.insert(
              id: 'cc1',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
              walletId: const Value('w1'),
              name: 'Cliente',
            ),
          );
      remote.rejectRow = (table, row) => row['id'] == 'tx-bad';

      final a = serviceFor(deviceA);
      await a.syncNow();

      expect(remote.row('transactions', 'tx-ok'), isNotNull);
      expect(remote.row('transactions', 'tx-bad'), isNull);
      expect(remote.row('cost_centers', 'cc1'), isNotNull);
      expect((await a.status())!.pendingIssues, 1);
      expect(await outboxSize(deviceA), 1, reason: 'riprovata alla prossima');

      remote.rejectRow = null;
      await a.syncNow();
      expect(remote.row('transactions', 'tx-bad'), isNotNull);
      expect((await a.status())!.pendingIssues, 0);
    });

    test('a failed sync is recorded in the status (no more silent '
        'background failures)', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      remote.failOnUpsertTo = 'wallets';
      final a = serviceFor(deviceA);
      await expectLater(a.syncNow(), throwsException);
      expect((await a.status())!.lastError, 'failed');
      expect((await a.status())!.lastSuccessAt, isNull);

      remote.failOnUpsertTo = null;
      await a.syncNow();
      expect((await a.status())!.lastError, isNull);
      expect((await a.status())!.lastSuccessAt, isNotNull);
    });

    test('two devices setting the budget of the same category offline '
        'converge on one budget (deterministic id)', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      await _insertCategory(deviceA, 'c1');
      await serviceFor(deviceA).syncNow();
      await serviceFor(deviceB).syncNow();

      await DriftBudgetRepository(
        deviceA,
      ).setMonthlyLimit(walletId: 'w1', categoryId: 'c1', limitCents: 100);
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await DriftBudgetRepository(
        deviceB,
      ).setMonthlyLimit(walletId: 'w1', categoryId: 'c1', limitCents: 200);
      await serviceFor(deviceA).syncNow();
      await serviceFor(deviceB).syncNow();
      await serviceFor(deviceA).syncNow();

      expect(remote.rowsOf('budgets'), hasLength(1));
      expect(remote.rowsOf('budgets').single['limit_cents'], 200);
      for (final db in [deviceA, deviceB]) {
        final live = await (db.select(
          db.budgets,
        )..where((t) => t.deletedAt.isNull())).get();
        expect(live.single.limitCents, 200);
      }
    });

    test('a legacy duplicate budget (random id) is resolved instead of '
        'blocking the sync', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      await _insertCategory(deviceA, 'c1');
      await serviceFor(deviceA).syncNow();
      await serviceFor(deviceB).syncNow();

      for (final (db, id, limit) in [
        (deviceA, 'budget-a', 100),
        (deviceB, 'budget-b', 200),
      ]) {
        await db
            .into(db.budgets)
            .insert(
              BudgetsCompanion.insert(
                id: id,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
                walletId: const Value('w1'),
                categoryId: 'c1',
                limitCents: limit,
              ),
            );
      }
      await serviceFor(deviceA).syncNow();
      final b = serviceFor(deviceB);
      await b.syncNow(); // budget-b rifiutato (unico), budget-a scaricato
      await b.syncNow();
      await serviceFor(deviceA).syncNow();

      for (final db in [deviceA, deviceB]) {
        final live = await (db.select(
          db.budgets,
        )..where((t) => t.deletedAt.isNull())).get();
        expect(live.single.id, 'budget-a');
      }
      expect((await b.status())!.pendingIssues, 0);
      expect(await outboxSize(deviceB), 0);
    });
  });

  group('NIP-15: rimozioni propagate', () {
    test(
      'removing a tag from a transaction reaches the other devices',
      () async {
        await _insertWallet(
          deviceA,
          id: 'w1',
          name: 'Conto',
          updatedAt: DateTime.now(),
        );
        await _insertTransaction(deviceA, 'tx1');
        final tagsA = DriftTagRepository(deviceA);
        final tagId = await tagsA.create('lavoro', walletId: 'w1');
        await tagsA.tagTransaction('tx1', tagId);
        await serviceFor(deviceA).syncNow();
        await serviceFor(deviceB).syncNow();
        expect(await DriftTagRepository(deviceB).tagsOf('tx1'), hasLength(1));

        await tagsA.untagTransaction('tx1', tagId);
        await serviceFor(deviceA).syncNow();
        await serviceFor(deviceB).syncNow();
        expect(await DriftTagRepository(deviceB).tagsOf('tx1'), isEmpty);

        // E si può rimettere.
        await tagsA.tagTransaction('tx1', tagId);
        await serviceFor(deviceA).syncNow();
        await serviceFor(deviceB).syncNow();
        expect(await DriftTagRepository(deviceB).tagsOf('tx1'), hasLength(1));
      },
    );

    test('removing an expense from the expense report reaches the other '
        'devices', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      await _insertTransaction(deviceA, 'tx1');
      final reportsA = DriftExpenseReportRepository(deviceA);
      await reportsA.setExpenseData(transactionId: 'tx1');
      await serviceFor(deviceA).syncNow();
      await serviceFor(deviceB).syncNow();
      final reportsB = DriftExpenseReportRepository(deviceB);
      expect(await reportsB.pendingReimbursementCents('w1'), 1000);

      await reportsA.clearExpenseData('tx1');
      await serviceFor(deviceA).syncNow();
      await serviceFor(deviceB).syncNow();
      expect(await reportsB.dataOf('tx1'), isNull);
      expect(await reportsB.pendingReimbursementCents('w1'), 0);
    });
  });

  group('NIP-14: concorrenza e cambio utente', () {
    test('a user switch during the sync stops it before writing data of '
        'the new user', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      await _insertTransaction(deviceA, 'tx1');
      await serviceFor(deviceA).syncNow();

      var current = _userId;
      remote.onFetch = (table) async {
        if (table == 'categories') current = _otherUserId;
      };
      final b = SupabaseSyncService(
        remote,
        deviceB,
        currentUserId: () => current,
      );
      await expectLater(b.syncNow(), throwsA(isA<SyncAbortedException>()));
      expect(await deviceB.select(deviceB.transactions).get(), isEmpty);
    });

    test('wipe waits for a running sync: nothing comes back after the '
        'removal', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      await _insertTransaction(deviceA, 'tx1');
      await serviceFor(deviceA).syncNow();

      final lock = SyncLock();
      final gate = Completer<void>();
      remote.onFetch = (table) async {
        if (table == 'transactions') await gate.future;
      };
      final b = SupabaseSyncService(
        remote,
        deviceB,
        currentUserId: () => _userId,
        lock: lock,
      );
      final appDir = await Directory.systemTemp.createTemp('nipay_sync_');
      addTearDown(() => appDir.delete(recursive: true));
      final wipe = DeviceLocalDataService(
        deviceB,
        () async => appDir,
        lock: lock,
      );

      final syncing = b.syncNow();
      await Future<void>.delayed(const Duration(milliseconds: 10));
      final wiping = wipe.wipe();
      gate.complete();
      await syncing;
      await wiping;

      expect(await deviceB.select(deviceB.transactions).get(), isEmpty);
      expect(await deviceB.select(deviceB.syncStates).get(), isEmpty);
      expect(await deviceB.select(deviceB.syncCursors).get(), isEmpty);
    });

    test('concurrent syncNow calls are serialized', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.now(),
      );
      var running = 0;
      var maxRunning = 0;
      remote.onFetch = (table) async {
        if (table == 'wallets') {
          running++;
          maxRunning = running > maxRunning ? running : maxRunning;
          await Future<void>.delayed(const Duration(milliseconds: 5));
          running--;
        }
      };
      final a = serviceFor(deviceA);
      await Future.wait([a.syncNow(), a.syncNow(), a.syncNow()]);
      expect(maxRunning, 1);
    });
  });

  group('cambio utente sullo stesso device', () {
    Set<Object?> remoteWalletOwners() =>
        remote.rowsOf('wallets').map((row) => row['owner_user_id']).toSet();

    test('another user signing in is blocked and nothing is pushed under '
        'their id, not even data created after the logout', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto di A',
        updatedAt: DateTime.utc(2024),
      );
      await serviceFor(deviceA).syncNow();
      // Dopo il logout di A i dati restano; ne nascono anche di nuovi.
      await _insertWallet(
        deviceA,
        id: 'w2',
        name: 'Creato dopo il logout',
        updatedAt: DateTime.now(),
      );

      final asOther = SupabaseSyncService(
        remote,
        deviceA,
        currentUserId: () => _otherUserId,
      );
      expect(await asOther.hasLocalDataOfAnotherUser(), isTrue);
      await expectLater(
        asOther.syncNow(),
        throwsA(isA<LocalDataOwnedByAnotherUserException>()),
      );

      expect(remoteWalletOwners(), {_userId});
      expect(remote.row('wallets', 'w2'), isNull);
      // Il proprietario dei dati invece continua a sincronizzare.
      expect(await serviceFor(deviceA).hasLocalDataOfAnotherUser(), isFalse);
      expect((await asOther.localDataOwner())!.userId, _userId);
    });

    test('a first sync interrupted midway already claims the device', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto di A',
        updatedAt: DateTime.utc(2024),
      );
      await _insertCategory(deviceA, 'c1');
      remote.failOnUpsertTo = 'categories';
      await expectLater(serviceFor(deviceA).syncNow(), throwsException);
      remote.failOnUpsertTo = null;

      final asOther = SupabaseSyncService(
        remote,
        deviceA,
        currentUserId: () => _otherUserId,
      );
      await expectLater(
        asOther.syncNow(),
        throwsA(isA<LocalDataOwnedByAnotherUserException>()),
      );
      expect(remoteWalletOwners(), {_userId});
    });

    test('after wiping local data the new user syncs normally', () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto di A',
        updatedAt: DateTime.utc(2024),
      );
      await serviceFor(deviceA).syncNow();

      final appDir = await Directory.systemTemp.createTemp('nipay_sync_');
      addTearDown(() => appDir.delete(recursive: true));
      await DeviceLocalDataService(deviceA, () async => appDir).wipe();

      final asOther = SupabaseSyncService(
        remote,
        deviceA,
        currentUserId: () => _otherUserId,
      );
      expect(await asOther.hasLocalDataOfAnotherUser(), isFalse);
      expect(await asOther.localDataOwner(), isNull);
      await asOther.syncNow();
      // Il FakeSyncRemote non applica la RLS: qui si verifica solo che
      // nulla di A sia stato ricaricato con l'id di B.
      expect(remoteWalletOwners(), {_userId});
    });

    test('nobody signed in is never reported as another user', () async {
      await serviceFor(deviceA).syncNow();
      final signedOut = SupabaseSyncService(
        remote,
        deviceA,
        currentUserId: () => null,
      );
      expect(await signedOut.hasLocalDataOfAnotherUser(), isFalse);
    });
  });

  test('keyset filter escapes values and rejects unsafe ones', () {
    expect(
      SupabaseSyncRemote.keysetFilter(
        '2026-10-05T10:00:00.123456Z',
        ['transaction_id', 'tag_id'],
        ['a-1', 'b-2'],
      ),
      'updated_at.gt."2026-10-05T10:00:00.123456Z",'
      'and(updated_at.eq."2026-10-05T10:00:00.123456Z",transaction_id.gt."a-1"),'
      'and(updated_at.eq."2026-10-05T10:00:00.123456Z",transaction_id.eq."a-1",tag_id.gt."b-2")',
    );
    expect(
      () => SupabaseSyncRemote.keysetFilter('x', ['id'], ['a",id.neq."b']),
      throwsFormatException,
    );
  });

  forAll<List<int>>(
    'last-write-wins: whichever order the devices sync in, both converge '
    'on the most recent edit',
    (random) => List.generate(4 + random.nextInt(4), (_) => random.nextInt(2)),
    (writers) async {
      final db = <int, AppDatabase>{
        0: AppDatabase(NativeDatabase.memory()),
        1: AppDatabase(NativeDatabase.memory()),
      };
      final fakeRemote = FakeSyncRemote();
      final service = {
        0: SupabaseSyncService(
          fakeRemote,
          db[0]!,
          currentUserId: () => _userId,
        ),
        1: SupabaseSyncService(
          fakeRemote,
          db[1]!,
          currentUserId: () => _userId,
        ),
      };

      await _insertWallet(
        db[0]!,
        id: 'w1',
        name: 'v0',
        updatedAt: DateTime.now(),
      );
      await service[0]!.syncNow();
      await service[1]!.syncNow();

      String? lastWritten;
      var counter = 0;
      for (final writer in writers) {
        counter++;
        await Future<void>.delayed(const Duration(milliseconds: 1));
        await (db[writer]!.update(
          db[writer]!.wallets,
        )..where((t) => t.id.equals('w1'))).write(
          WalletsCompanion(
            name: Value('v$counter'),
            updatedAt: Value(DateTime.now()),
          ),
        );
        await service[writer]!.syncNow();
        lastWritten = 'v$counter';
      }
      // Un ultimo giro di sync per entrambi ("tutti online alla fine").
      await service[0]!.syncNow();
      await service[1]!.syncNow();

      final nameOnA = (await (db[0]!.select(
        db[0]!.wallets,
      )..where((t) => t.id.equals('w1'))).getSingle()).name;
      final nameOnB = (await (db[1]!.select(
        db[1]!.wallets,
      )..where((t) => t.id.equals('w1'))).getSingle()).name;

      expect(nameOnA, nameOnB, reason: 'i due device devono convergere');
      expect(nameOnA, lastWritten);

      await db[0]!.close();
      await db[1]!.close();
    },
    trials: 30,
  );
}

/// Registra ciò che il client invia, inoltrando al server finto.
class _SpyRemote implements SyncRemote {
  _SpyRemote(this._inner, this._sent);

  final SyncRemote _inner;
  final List<Map<String, dynamic>> _sent;

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) {
    _sent.addAll(rows);
    return _inner.upsert(table, rows);
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPage(
    String table, {
    required List<String> keyColumns,
    required DateTime from,
    List<String>? afterKey,
    required int limit,
  }) => _inner.fetchPage(
    table,
    keyColumns: keyColumns,
    from: from,
    afterKey: afterKey,
    limit: limit,
  );
}
