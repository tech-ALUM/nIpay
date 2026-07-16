import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

export '../db/tables.dart' show CustomFieldType;

abstract interface class CustomFieldRepository {
  Future<String> define({
    required String name,
    required CustomFieldType type,
    List<String>? options,
  });
  Future<List<CustomFieldDef>> getDefinitions();
  Future<void> setValue({
    required String transactionId,
    required String fieldId,
    required String value,
  });
  Future<List<CustomFieldValue>> valuesOf(String transactionId);

  /// Id delle transazioni con almeno un valore custom che contiene [query]
  /// (case-insensitive). Usato dalla ricerca della lista.
  Future<Set<String>> transactionIdsMatching(String query);
  Future<void> softDeleteDefinition(String id);
}

class DriftCustomFieldRepository implements CustomFieldRepository {
  DriftCustomFieldRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Future<String> define({
    required String name,
    required CustomFieldType type,
    List<String>? options,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db
        .into(_db.customFieldDefs)
        .insert(
          CustomFieldDefsCompanion.insert(
            id: id,
            name: name,
            type: type,
            options: Value(options),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Future<List<CustomFieldDef>> getDefinitions() =>
      (_db.select(_db.customFieldDefs)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  @override
  Future<void> setValue({
    required String transactionId,
    required String fieldId,
    required String value,
  }) => _db
      .into(_db.customFieldValues)
      .insertOnConflictUpdate(
        CustomFieldValuesCompanion.insert(
          transactionId: transactionId,
          fieldId: fieldId,
          value: value,
          updatedAt: DateTime.now(),
        ),
      );

  @override
  Future<List<CustomFieldValue>> valuesOf(String transactionId) => (_db.select(
    _db.customFieldValues,
  )..where((t) => t.transactionId.equals(transactionId))).get();

  @override
  Future<Set<String>> transactionIdsMatching(String query) async {
    final rows = await (_db.select(
      _db.customFieldValues,
    )..where((t) => t.value.lower().like('%${query.toLowerCase()}%'))).get();
    return rows.map((r) => r.transactionId).toSet();
  }

  @override
  Future<void> softDeleteDefinition(String id) =>
      (_db.update(_db.customFieldDefs)..where((t) => t.id.equals(id))).write(
        CustomFieldDefsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
