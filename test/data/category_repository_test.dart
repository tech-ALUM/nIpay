import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/repositories/category_repository.dart';

import 'package:nipay/data/repositories/wallet_repository.dart';

void main() {
  late AppDatabase db;
  late CategoryRepository repo;
  late String w;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftCategoryRepository(db);
    w = await DriftWalletRepository(
      db,
    ).create(name: 'Conto', colorHex: '#0E7C86');
  });

  tearDown(() async => db.close());

  test('creates a custom category with parent (hierarchy)', () async {
    final parentId = await repo.create(
      walletId: w,
      name: 'Trasporti',
      icon: '⛽',
      colorHex: '#7C5CBF',
      kind: CategoryKind.expense,
    );
    final childId = await repo.create(
      walletId: w,
      name: 'Carburante',
      icon: '⛽',
      colorHex: '#7C5CBF',
      kind: CategoryKind.expense,
      parentId: parentId,
    );

    final all = await repo.getAll(w);
    final child = all.singleWhere((c) => c.id == childId);
    expect(child.parentId, parentId);
  });

  test('seedDefaults populates defaults only once (idempotent)', () async {
    await repo.seedDefaults(w);
    final first = await repo.getAll(w);
    expect(first, isNotEmpty);

    await repo.seedDefaults(w);
    final second = await repo.getAll(w);
    expect(second.length, first.length);
  });

  test('update changes name, icon and color', () async {
    final id = await repo.create(
      walletId: w,
      name: 'Sport',
      icon: '⚽',
      colorHex: '#2E9E6B',
      kind: CategoryKind.expense,
    );
    await repo.update(id, name: 'Palestra', icon: '🏋️', colorHex: '#7C5CBF');

    final cat = (await repo.getAll(w)).single;
    expect(cat.name, 'Palestra');
    expect(cat.icon, '🏋️');
    expect(cat.colorHex, '#7C5CBF');
  });

  test('reorder rewrites sortOrder following the given id order', () async {
    final a = await repo.create(
      walletId: w,
      name: 'A',
      icon: 'a',
      colorHex: '#111111',
      kind: CategoryKind.expense,
    );
    final b = await repo.create(
      walletId: w,
      name: 'B',
      icon: 'b',
      colorHex: '#222222',
      kind: CategoryKind.expense,
    );
    final c = await repo.create(
      walletId: w,
      name: 'C',
      icon: 'c',
      colorHex: '#333333',
      kind: CategoryKind.expense,
    );

    await repo.reorder([c, a, b]);

    final names = (await repo.getAll(w)).map((x) => x.name).toList();
    expect(names, ['C', 'A', 'B']);
  });

  test('categories are scoped per wallet', () async {
    final w2 = await DriftWalletRepository(
      db,
    ).create(name: 'Altro', colorHex: '#7C5CBF');
    await repo.create(
      walletId: w,
      name: 'SoloW1',
      icon: 'a',
      colorHex: '#111111',
      kind: CategoryKind.expense,
    );
    await repo.seedDefaults(w2);

    expect((await repo.getAll(w)).map((c) => c.name), ['SoloW1']);
    expect((await repo.getAll(w2)).any((c) => c.name == 'SoloW1'), isFalse);
    expect(await repo.getAll(w2), isNotEmpty); // seed di w2
  });

  test('soft-deleted categories are hidden from getAll', () async {
    final id = await repo.create(
      walletId: w,
      name: 'Svago',
      icon: '🎬',
      colorHex: '#FF6F61',
      kind: CategoryKind.expense,
    );
    await repo.softDelete(id);
    expect(await repo.getAll(w), isEmpty);
  });
}
