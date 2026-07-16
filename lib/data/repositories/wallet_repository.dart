import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

/// Contratto usato dalla UI: nessun riferimento a Drift fuori da qui.
abstract interface class WalletRepository {
  Future<String> create({
    required String name,
    required String colorHex,
    int initialBalanceCents,
  });
  Future<List<Wallet>> getAll();
  Stream<List<Wallet>> watchAll();
  Future<void> rename(String id, String name);
  Future<void> softDelete(String id);
}

class DriftWalletRepository implements WalletRepository {
  DriftWalletRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  Expression<bool> _alive($WalletsTable t) => t.deletedAt.isNull();

  @override
  Future<String> create({
    required String name,
    required String colorHex,
    int initialBalanceCents = 0,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db
        .into(_db.wallets)
        .insert(
          WalletsCompanion.insert(
            id: id,
            name: name,
            colorHex: colorHex,
            initialBalanceCents: Value(initialBalanceCents),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Future<List<Wallet>> getAll() =>
      (_db.select(_db.wallets)..where(_alive)).get();

  @override
  Stream<List<Wallet>> watchAll() =>
      (_db.select(_db.wallets)..where(_alive)).watch();

  @override
  Future<void> rename(String id, String name) =>
      (_db.update(_db.wallets)..where((t) => t.id.equals(id))).write(
        WalletsCompanion(name: Value(name), updatedAt: Value(DateTime.now())),
      );

  @override
  Future<void> softDelete(String id) =>
      (_db.update(_db.wallets)..where((t) => t.id.equals(id))).write(
        WalletsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
