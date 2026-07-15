import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/repositories/category_repository.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftCategoryRepository(db);
  });

  tearDown(() async => db.close());

  test('creates a custom category with parent (hierarchy)', () async {
    final parentId = await repo.create(
        name: 'Trasporti', icon: '⛽', colorHex: '#7C5CBF', kind: CategoryKind.expense);
    final childId = await repo.create(
        name: 'Carburante', icon: '⛽', colorHex: '#7C5CBF',
        kind: CategoryKind.expense, parentId: parentId);

    final all = await repo.getAll();
    final child = all.singleWhere((c) => c.id == childId);
    expect(child.parentId, parentId);
  });

  test('seedDefaults populates defaults only once (idempotent)', () async {
    await repo.seedDefaults();
    final first = await repo.getAll();
    expect(first, isNotEmpty);

    await repo.seedDefaults();
    final second = await repo.getAll();
    expect(second.length, first.length);
  });

  test('soft-deleted categories are hidden from getAll', () async {
    final id = await repo.create(
        name: 'Svago', icon: '🎬', colorHex: '#FF6F61', kind: CategoryKind.expense);
    await repo.softDelete(id);
    expect(await repo.getAll(), isEmpty);
  });
}
