import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

export '../db/tables.dart' show CategoryKind;

abstract interface class CategoryRepository {
  Future<String> create({
    required String name,
    required String icon,
    required String colorHex,
    required CategoryKind kind,
    String? parentId,
  });
  Future<List<Category>> getAll();
  Stream<List<Category>> watchAll();
  Future<void> softDelete(String id);

  /// Popola le categorie di default alla prima apertura. Idempotente.
  Future<void> seedDefaults();
}

class DriftCategoryRepository implements CategoryRepository {
  DriftCategoryRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  static const _defaults = <(String, String, CategoryKind)>[
    ('Spesa', '🛒', CategoryKind.expense),
    ('Ristoranti', '🍽️', CategoryKind.expense),
    ('Trasporti', '⛽', CategoryKind.expense),
    ('Casa', '🏠', CategoryKind.expense),
    ('Svago', '🎬', CategoryKind.expense),
    ('Salute', '💊', CategoryKind.expense),
    ('Shopping', '👕', CategoryKind.expense),
    ('Stipendio', '💼', CategoryKind.income),
    ('Regali', '🎁', CategoryKind.both),
    ('Altro', '📦', CategoryKind.both),
  ];

  @override
  Future<String> create({
    required String name,
    required String icon,
    required String colorHex,
    required CategoryKind kind,
    String? parentId,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db
        .into(_db.categories)
        .insert(
          CategoriesCompanion.insert(
            id: id,
            name: name,
            icon: icon,
            colorHex: colorHex,
            kind: kind,
            parentId: Value(parentId),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Future<List<Category>> getAll() =>
      (_db.select(_db.categories)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .get();

  @override
  Stream<List<Category>> watchAll() =>
      (_db.select(_db.categories)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
          .watch();

  @override
  Future<void> softDelete(String id) =>
      (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
        CategoriesCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<void> seedDefaults() async {
    final existing = await (_db.select(
      _db.categories,
    )..where((t) => t.isDefault.equals(true))).get();
    if (existing.isNotEmpty) return;

    final now = DateTime.now();
    await _db.batch((b) {
      for (final (i, (name, icon, kind)) in _defaults.indexed) {
        b.insert(
          _db.categories,
          CategoriesCompanion.insert(
            id: _uuid.v4(),
            name: name,
            icon: icon,
            colorHex: kind == CategoryKind.income ? '#0E7C86' : '#FF6F61',
            kind: kind,
            sortOrder: Value(i),
            isDefault: const Value(true),
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
    });
  }
}
