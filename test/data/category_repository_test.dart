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
      name: 'Trasporti',
      icon: '⛽',
      colorHex: '#7C5CBF',
      kind: CategoryKind.expense,
    );
    final childId = await repo.create(
      name: 'Carburante',
      icon: '⛽',
      colorHex: '#7C5CBF',
      kind: CategoryKind.expense,
      parentId: parentId,
    );

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

  test('update changes name, icon and color', () async {
    final id = await repo.create(
      name: 'Sport',
      icon: '⚽',
      colorHex: '#2E9E6B',
      kind: CategoryKind.expense,
    );
    await repo.update(id, name: 'Palestra', icon: '🏋️', colorHex: '#7C5CBF');

    final cat = (await repo.getAll()).single;
    expect(cat.name, 'Palestra');
    expect(cat.icon, '🏋️');
    expect(cat.colorHex, '#7C5CBF');
  });

  test('reorder rewrites sortOrder following the given id order', () async {
    final a = await repo.create(
      name: 'A',
      icon: 'a',
      colorHex: '#111111',
      kind: CategoryKind.expense,
    );
    final b = await repo.create(
      name: 'B',
      icon: 'b',
      colorHex: '#222222',
      kind: CategoryKind.expense,
    );
    final c = await repo.create(
      name: 'C',
      icon: 'c',
      colorHex: '#333333',
      kind: CategoryKind.expense,
    );

    await repo.reorder([c, a, b]);

    final names = (await repo.getAll()).map((x) => x.name).toList();
    expect(names, ['C', 'A', 'B']);
  });

  test('soft-deleted categories are hidden from getAll', () async {
    final id = await repo.create(
      name: 'Svago',
      icon: '🎬',
      colorHex: '#FF6F61',
      kind: CategoryKind.expense,
    );
    await repo.softDelete(id);
    expect(await repo.getAll(), isEmpty);
  });
}
