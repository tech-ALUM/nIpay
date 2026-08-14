import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/repositories/budget_repository.dart';
import 'package:nipay/data/repositories/category_repository.dart';
import 'package:nipay/data/repositories/recurring_repository.dart';
import 'package:nipay/data/repositories/transaction_repository.dart';
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
    expect(wallets.first.currency, 'EUR');
  });

  test('create with explicit currency persists it', () async {
    final id = await repo.create(
      name: 'Conto USA',
      colorHex: '#0E7C86',
      currency: 'USD',
    );

    final wallets = await repo.getAll();
    expect(wallets.singleWhere((w) => w.id == id).currency, 'USD');
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

  test('getAll returns wallets ordered by position', () async {
    final a = await repo.create(name: 'A', colorHex: '#0E7C86');
    final b = await repo.create(name: 'B', colorHex: '#FF6F61');
    final c = await repo.create(name: 'C', colorHex: '#7C5CBF');
    expect((await repo.getAll()).map((w) => w.id), [a, b, c]);
  });

  test('move reorders wallets, compacting positions', () async {
    final a = await repo.create(name: 'A', colorHex: '#0E7C86');
    final b = await repo.create(name: 'B', colorHex: '#FF6F61');
    final c = await repo.create(name: 'C', colorHex: '#7C5CBF');

    // Sposta A (indice 0) alla fine.
    await repo.move(a, 2);
    expect((await repo.getAll()).map((w) => w.id), [b, c, a]);
  });

  test('move clamps out-of-range indexes instead of crashing', () async {
    final a = await repo.create(name: 'A', colorHex: '#0E7C86');
    final b = await repo.create(name: 'B', colorHex: '#FF6F61');
    final c = await repo.create(name: 'C', colorHex: '#7C5CBF');

    // Indice negativo: clampato a 0 (inizio).
    await repo.move(c, -5);
    expect((await repo.getAll()).map((w) => w.id), [c, a, b]);

    // Indice ben oltre la lunghezza: clampato alla fine.
    await repo.move(c, 999);
    expect((await repo.getAll()).map((w) => w.id), [a, b, c]);
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

  group('changeCurrency', () {
    test('is a no-op when the new currency is the same', () async {
      final a = await repo.create(
        name: 'A',
        colorHex: '#0E7C86',
        initialBalanceCents: 100000,
        currency: 'EUR',
      );
      await repo.changeCurrency(a, 'EUR', 1.0);
      final wallet = (await repo.getAll()).single;
      expect(wallet.currency, 'EUR');
      expect(wallet.initialBalanceCents, 100000);
    });

    test('rescales only the initial balance, nothing else', () async {
      final txs = DriftTransactionRepository(db);
      final cats = DriftCategoryRepository(db);
      final budgets = DriftBudgetRepository(db);
      final recurring = DriftRecurringRepository(db);

      final a = await repo.create(
        name: 'A',
        colorHex: '#0E7C86',
        initialBalanceCents: 100000, // 1000,00
        currency: 'EUR',
      );
      final b = await repo.create(name: 'B', colorHex: '#FF6F61');

      final cat = await cats.create(
        walletId: a,
        name: 'Spesa',
        icon: '🛒',
        colorHex: '#FF6F61',
        kind: CategoryKind.expense,
      );

      await txs.createExpense(
        walletId: a,
        amountCents: 5000,
        date: DateTime(2026, 1, 1),
      );
      await txs.createTransfer(
        fromWalletId: a,
        toWalletId: b,
        amountCents: 1000,
        date: DateTime(2026, 1, 3),
      );
      await budgets.setMonthlyLimit(
        walletId: a,
        categoryId: cat,
        limitCents: 40000,
      );
      await recurring.create(
        walletId: a,
        type: TransactionType.expense,
        amountCents: 3000,
        description: 'Affitto',
        frequency: RecurrenceFrequency.monthly,
        startAt: DateTime(2026, 2, 1),
      );

      await repo.changeCurrency(a, 'USD', 1.1);

      final wallets = {for (final w in await repo.getAll()) w.id: w};
      // Solo il saldo iniziale del portafoglio cambia.
      expect(wallets[a]!.currency, 'USD');
      expect(wallets[a]!.initialBalanceCents, 110000);
      expect(wallets[b]!.currency, 'EUR');

      // Transazioni, budget e regole ricorrenti restano intatti.
      final rows = await db.select(db.transactions).get();
      final expense = rows.singleWhere(
        (t) => t.type == TransactionType.expense,
      );
      expect(expense.amountCents, 5000);
      final transfer = rows.singleWhere(
        (t) => t.type == TransactionType.transfer,
      );
      expect(transfer.amountCents, 1000);
      expect(transfer.amountCentsTo, isNull);

      final budgetRow = (await db.select(db.budgets).get()).single;
      expect(budgetRow.limitCents, 40000);

      final ruleRow = (await db.select(db.recurringRules).get()).single;
      expect(ruleRow.amountCents, 3000);
    });
  });
}
