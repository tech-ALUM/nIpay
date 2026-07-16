import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';

abstract interface class CostCenterRepository {
  Future<String> create(String name, {required String walletId});
  Future<List<CostCenter>> getAll(String walletId);
  Future<void> softDelete(String id);
}

class DriftCostCenterRepository implements CostCenterRepository {
  DriftCostCenterRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Future<String> create(String name, {required String walletId}) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db
        .into(_db.costCenters)
        .insert(
          CostCentersCompanion.insert(
            id: id,
            walletId: Value(walletId),
            name: name,
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Future<List<CostCenter>> getAll(String walletId) =>
      (_db.select(_db.costCenters)
            ..where((t) => t.deletedAt.isNull() & t.walletId.equals(walletId))
            ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  @override
  Future<void> softDelete(String id) =>
      (_db.update(_db.costCenters)..where((t) => t.id.equals(id))).write(
        CostCentersCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
