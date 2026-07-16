import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/repositories/transaction_repository.dart';
import 'package:nipay/data/repositories/wallet_repository.dart';

void main() {
  late AppDatabase db;
  late TransactionRepository repo;
  late String conto;
  late String contanti;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftTransactionRepository(db);
    final wallets = DriftWalletRepository(db);
    conto = await wallets.create(
      name: 'Conto',
      colorHex: '#0E7C86',
      initialBalanceCents: 100000,
    );
    contanti = await wallets.create(
      name: 'Contanti',
      colorHex: '#FF6F61',
      initialBalanceCents: 5000,
    );
  });

  tearDown(() async => db.close());

  test('balance = initial + income − expense', () async {
    await repo.createIncome(
      walletId: conto,
      amountCents: 185000,
      date: DateTime(2026, 7, 1),
    );
    await repo.createExpense(
      walletId: conto,
      amountCents: 4250,
      date: DateTime(2026, 7, 15),
    );

    expect(await repo.balanceOf(conto), 100000 + 185000 - 4250);
  });

  test('transfer moves money between wallets', () async {
    await repo.createTransfer(
      fromWalletId: conto,
      toWalletId: contanti,
      amountCents: 10000,
      date: DateTime(2026, 6, 30),
    );

    expect(await repo.balanceOf(conto), 100000 - 10000);
    expect(await repo.balanceOf(contanti), 5000 + 10000);
  });

  test('period totals exclude transfers', () async {
    await repo.createIncome(
      walletId: conto,
      amountCents: 185000,
      date: DateTime(2026, 7, 1),
    );
    await repo.createExpense(
      walletId: conto,
      amountCents: 4250,
      date: DateTime(2026, 7, 15),
    );
    await repo.createTransfer(
      fromWalletId: conto,
      toWalletId: contanti,
      amountCents: 10000,
      date: DateTime(2026, 7, 2),
    );
    // fuori periodo
    await repo.createExpense(
      walletId: conto,
      amountCents: 9999,
      date: DateTime(2026, 6, 20),
    );

    final t = await repo.totalsForPeriod(
      from: DateTime(2026, 7, 1),
      to: DateTime(2026, 8, 1),
    );
    expect(t.incomeCents, 185000);
    expect(t.expenseCents, 4250);
  });

  test('expensesByCategory aggregates expense totals in the period', () async {
    await repo.createExpense(
      walletId: conto,
      amountCents: 100,
      date: DateTime(2026, 7, 2),
      categoryId: 'cat-a',
    );
    await repo.createExpense(
      walletId: conto,
      amountCents: 250,
      date: DateTime(2026, 7, 9),
      categoryId: 'cat-a',
    );
    await repo.createExpense(
      walletId: conto,
      amountCents: 40,
      date: DateTime(2026, 7, 9),
      categoryId: 'cat-b',
    );
    // fuori periodo e non-spesa: escluse
    await repo.createExpense(
      walletId: conto,
      amountCents: 999,
      date: DateTime(2026, 6, 9),
      categoryId: 'cat-a',
    );
    await repo.createIncome(
      walletId: conto,
      amountCents: 999,
      date: DateTime(2026, 7, 9),
      categoryId: 'cat-a',
    );

    final rows = await repo.expensesByCategory(
      from: DateTime(2026, 7, 1),
      to: DateTime(2026, 8, 1),
    );
    expect(rows, hasLength(2));
    expect(rows.first.categoryId, 'cat-a'); // ordinati per totale desc
    expect(rows.first.totalCents, 350);
    expect(rows.last.totalCents, 40);
  });

  test(
    'monthlySeries returns income/expense per month, oldest first',
    () async {
      await repo.createIncome(
        walletId: conto,
        amountCents: 1000,
        date: DateTime(2026, 6, 1),
      );
      await repo.createExpense(
        walletId: conto,
        amountCents: 400,
        date: DateTime(2026, 6, 15),
      );
      await repo.createExpense(
        walletId: conto,
        amountCents: 700,
        date: DateTime(2026, 7, 10),
      );

      final series = await repo.monthlySeries(
        months: 3,
        until: DateTime(2026, 7, 15),
      );
      expect(series, hasLength(3));
      expect((series[0].year, series[0].month), (2026, 5));
      expect(series[0].expenseCents, 0);
      expect((series[1].year, series[1].month), (2026, 6));
      expect(series[1].incomeCents, 1000);
      expect(series[1].expenseCents, 400);
      expect(series[2].expenseCents, 700);
    },
  );

  test(
    'updateTransaction edits amount, date, category and description',
    () async {
      final id = await repo.createExpense(
        walletId: conto,
        amountCents: 1000,
        date: DateTime(2026, 7, 10),
        description: 'Prima',
      );

      await repo.updateTransaction(
        id,
        amountCents: 2500,
        date: DateTime(2026, 7, 12),
        categoryId: 'cat-x',
        description: 'Dopo',
      );

      final tx = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(tx.amountCents, 2500);
      expect(tx.date, DateTime(2026, 7, 12));
      expect(tx.categoryId, 'cat-x');
      expect(tx.description, 'Dopo');
      expect(await repo.balanceOf(conto), 100000 - 2500);
    },
  );

  test('soft-deleted transactions do not affect balance', () async {
    final id = await repo.createExpense(
      walletId: conto,
      amountCents: 4250,
      date: DateTime(2026, 7, 15),
    );
    await repo.softDelete(id);

    expect(await repo.balanceOf(conto), 100000);
  });
}
