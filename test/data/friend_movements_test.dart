import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/db/tables.dart';
import 'package:nipay/data/repositories/budget_repository.dart';
import 'package:nipay/data/repositories/category_repository.dart';
import 'package:nipay/data/repositories/transaction_repository.dart';
import 'package:nipay/data/repositories/wallet_repository.dart';

/// Movimenti "con amici" (M-SOC4): cambiano il saldo ma non contano in
/// spese, entrate, categorie, serie mensili e budget.
void main() {
  late AppDatabase db;
  late DriftTransactionRepository txs;
  late String wallet;
  late String food;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    txs = DriftTransactionRepository(db);
    wallet = await DriftWalletRepository(
      db,
    ).create(name: 'Conto', colorHex: '#0E7C86', initialBalanceCents: 10000);
    food = await DriftCategoryRepository(db).create(
      walletId: wallet,
      name: 'Ristoranti',
      icon: '🍝',
      colorHex: '#FF6F61',
      kind: CategoryKind.expense,
    );
    // La cena del piano vista da A: quota 20 €, anticipo 40 €; poi B
    // rimborsa 20 €.
    await txs.createExpense(
      walletId: wallet,
      amountCents: 2000,
      date: DateTime(2026, 10, 10),
      categoryId: food,
      sharedExpenseId: 'se-cena',
    );
    await txs.createFriendMovement(
      walletId: wallet,
      amountCents: 4000,
      date: DateTime(2026, 10, 10),
      outgoing: true,
      sharedExpenseId: 'se-cena',
    );
    await txs.createFriendMovement(
      walletId: wallet,
      amountCents: 2000,
      date: DateTime(2026, 10, 12),
      outgoing: false,
    );
  });

  tearDown(() => db.close());

  test('the balance follows the real money: 100 − 20 − 40 + 20', () async {
    expect(await txs.balanceOf(wallet), 6000);
  });

  test('totals, categories and monthly series count only the share', () async {
    final totals = await txs.totalsForPeriod(
      from: DateTime(2026, 10),
      to: DateTime(2026, 11),
      walletId: wallet,
    );
    expect(totals, (expenseCents: 2000, incomeCents: 0));

    final byCategory = await txs.expensesByCategory(
      from: DateTime(2026, 10),
      to: DateTime(2026, 11),
      walletId: wallet,
    );
    expect(byCategory, [(categoryId: food, totalCents: 2000)]);

    final series = await txs.monthlySeries(
      months: 1,
      until: DateTime(2026, 10, 31),
      walletId: wallet,
    );
    expect(series.single.expenseCents, 2000);
    expect(series.single.incomeCents, 0);
  });

  test('the budget counts only the share', () async {
    final budgets = DriftBudgetRepository(db);
    await budgets.setMonthlyLimit(
      walletId: wallet,
      categoryId: food,
      limitCents: 5000,
    );
    expect(
      await budgets.progressFor(categoryId: food, month: DateTime(2026, 10)),
      (spentCents: 2000, limitCents: 5000),
    );
  });

  test('changing the wallet currency converts friend movements too', () async {
    await DriftWalletRepository(db).changeCurrency(wallet, 'USD', 2.0);
    final rows = await db.select(db.transactions).get();
    expect(
      rows.where((t) => t.type == TransactionType.friendOut).single.amountCents,
      8000,
    );
    // Stesso valore, nuova valuta.
    expect(await txs.balanceOf(wallet), 12000);
  });
}
