import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/repositories/wallet_repository.dart';

void main() {
  late AppDatabase db;
  late WalletRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftWalletRepository(db);
  });

  tearDown(() async => db.close());

  test('creates a wallet and reads it back', () async {
    final id = await repo.create(
      name: 'Conto',
      colorHex: '#0E7C86',
      initialBalanceCents: 100000,
    );

    final wallets = await repo.getAll();
    expect(wallets, hasLength(1));
    expect(wallets.first.id, id);
    expect(wallets.first.name, 'Conto');
    expect(wallets.first.initialBalanceCents, 100000);
    expect(wallets.first.deletedAt, isNull);
  });

  test('updates a wallet and bumps updatedAt', () async {
    final id = await repo.create(
      name: 'Conto',
      colorHex: '#0E7C86',
      initialBalanceCents: 0,
    );
    final before = (await repo.getAll()).first.updatedAt;

    await Future<void>.delayed(const Duration(milliseconds: 10));
    await repo.rename(id, 'Conto principale');

    final after = (await repo.getAll()).first;
    expect(after.name, 'Conto principale');
    expect(after.updatedAt.isAfter(before), isTrue);
  });

  test('soft delete hides the wallet but keeps the row', () async {
    final id = await repo.create(
      name: 'Contanti',
      colorHex: '#FF6F61',
      initialBalanceCents: 5000,
    );
    await repo.softDelete(id);

    expect(await repo.getAll(), isEmpty);
    final raw = await db.select(db.wallets).get();
    expect(raw, hasLength(1));
    expect(raw.first.deletedAt, isNotNull);
  });

  test('watchAll emits reactively on insert', () async {
    final stream = repo.watchAll();
    final first = await stream.first;
    expect(first, isEmpty);

    await repo.create(
      name: 'Risparmi',
      colorHex: '#7C5CBF',
      initialBalanceCents: 0,
    );
    final second = await stream.firstWhere((l) => l.isNotEmpty);
    expect(second.single.name, 'Risparmi');
  });
}
