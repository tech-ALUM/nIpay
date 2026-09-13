import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/db/tables.dart';
import 'package:nipay/data/services/sync_service.dart';

import '../support/property.dart';

/// Finto "server" in memoria: nessuna rete, nessuna dipendenza da
/// Supabase.initialize() nei test. L'`updated_at` viene assegnato da un
/// orologio finto che avanza ad ogni upsert — replica il trigger Postgres
/// di M-ACC1 (mai fidarsi del timestamp mandato dal client) in modo
/// deterministico, senza i tempi morti di DateTime.now() reale.
class FakeSyncRemote implements SyncRemote {
  final Map<String, Map<String, Map<String, dynamic>>> _tables = {};
  int _clock = 0;

  static const _primaryKeys = {
    'transaction_tags': ['transaction_id', 'tag_id'],
    'custom_field_values': ['transaction_id', 'field_id'],
    'expense_report_entries': ['transaction_id'],
  };

  List<String> _pkColumns(String table) => _primaryKeys[table] ?? ['id'];

  String _keyOf(String table, Map<String, dynamic> row) =>
      _pkColumns(table).map((c) => row[c]).join('|');

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    final store = _tables.putIfAbsent(table, () => {});
    for (final row in rows) {
      _clock++;
      final stamped = {
        ...row,
        'updated_at': DateTime.utc(
          2020,
        ).add(Duration(microseconds: _clock)).toIso8601String(),
      };
      store[_keyOf(table, stamped)] = stamped;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> selectChangedSince(
    String table,
    DateTime since, {
    String column = 'updated_at',
  }) async {
    final store = _tables[table] ?? {};
    return store.values
        .where((row) => DateTime.parse(row[column] as String).isAfter(since))
        .map((row) => Map<String, dynamic>.from(row))
        .toList();
  }
}

const _userId = 'user-1';

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

  SupabaseSyncService serviceFor(AppDatabase db) =>
      SupabaseSyncService(remote, db, currentUserId: () => _userId);

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

    final pushed = await remote.selectChangedSince(
      'wallets',
      DateTime.utc(2000),
    );
    expect(pushed, hasLength(1));
    expect(pushed.single['name'], 'Conto');
    expect(pushed.single['owner_user_id'], _userId);
  });

  test('a wallet pushed from device A appears on device B after sync', () async {
    await _insertWallet(
      deviceA,
      id: 'w1',
      name: 'Conto condiviso',
      updatedAt: DateTime.utc(2024),
    );
    await serviceFor(deviceA).syncNow();

    // Device B parte vuoto: la sua stessa prima sync deve tirare giù
    // tutto ciò che esiste già sul server per questo utente (M-ACC6,
    // "nessun wallet perso nella transizione locale→account" — qui è il
    // caso simmetrico: nessun wallet perso quando un SECONDO device fa
    // il login sullo stesso account).
    await serviceFor(deviceB).syncNow();

    final wallets = await deviceB.select(deviceB.wallets).get();
    expect(wallets, hasLength(1));
    expect(wallets.single.id, 'w1');
    expect(wallets.single.name, 'Conto condiviso');
  });

  test(
    'categories sync after their wallet, respecting the foreign key',
    () async {
      await _insertWallet(
        deviceA,
        id: 'w1',
        name: 'Conto',
        updatedAt: DateTime.utc(2024),
      );
      await deviceA
          .into(deviceA.categories)
          .insert(
            CategoriesCompanion.insert(
              id: 'c1',
              createdAt: DateTime.utc(2024),
              updatedAt: DateTime.utc(2024),
              walletId: const Value('w1'),
              name: 'Spesa',
              icon: 'cart',
              colorHex: '#111111',
              kind: CategoryKind.expense,
            ),
          );

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

      await (deviceA.update(deviceA.wallets)..where((t) => t.id.equals('w1')))
          .write(
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

  forAll<List<int>>(
    'last-write-wins: whichever device syncs last always converges to the '
    'same final name on both devices, regardless of write order',
    (random) => List.generate(4 + random.nextInt(4), (_) => random.nextInt(2)),
    (writers) async {
      final db = <int, AppDatabase>{
        0: AppDatabase(NativeDatabase.memory()),
        1: AppDatabase(NativeDatabase.memory()),
      };
      final fakeRemote = FakeSyncRemote();
      final service = {
        0: SupabaseSyncService(fakeRemote, db[0]!, currentUserId: () => _userId),
        1: SupabaseSyncService(fakeRemote, db[1]!, currentUserId: () => _userId),
      };

      await _insertWallet(
        db[0]!,
        id: 'w1',
        name: 'v0',
        updatedAt: DateTime.utc(2024),
      );
      await service[0]!.syncNow();
      await service[1]!.syncNow();

      String? lastWrittenBy;
      var counter = 0;
      for (final writer in writers) {
        counter++;
        await (db[writer]!.update(
          db[writer]!.wallets,
        )..where((t) => t.id.equals('w1'))).write(
          WalletsCompanion(
            name: Value('v$counter'),
            // DateTime.now() (non un timestamp fisso arbitrario): il
            // watermark di push del servizio (`pushCutoff`) è anch'esso
            // preso da DateTime.now() dopo la prima sync, quindi la
            // riga locale deve stare nello stesso dominio di orologio
            // reale, altrimenti risulterebbe "già vecchia" e non
            // verrebbe mai pushata — esattamente il bug scoperto dal
            // primo giro di questo test.
            updatedAt: Value(DateTime.now().add(Duration(seconds: counter))),
          ),
        );
        await service[writer]!.syncNow();
        lastWrittenBy = 'v$counter';
      }
      // Un ultimo giro di sync per entrambi, a fare da "tutti online alla
      // fine": qualunque sia stata la sequenza, entrambi devono convergere
      // sull'ultimo valore effettivamente pushato.
      await service[0]!.syncNow();
      await service[1]!.syncNow();

      final nameOnA = (await (db[0]!.select(
        db[0]!.wallets,
      )..where((t) => t.id.equals('w1'))).getSingle()).name;
      final nameOnB = (await (db[1]!.select(
        db[1]!.wallets,
      )..where((t) => t.id.equals('w1'))).getSingle()).name;

      expect(nameOnA, nameOnB, reason: 'i due device devono convergere');
      expect(nameOnA, lastWrittenBy);

      await db[0]!.close();
      await db[1]!.close();
    },
    trials: 30,
  );
}
