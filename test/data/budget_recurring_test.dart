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
  late String wallet;
  late String catSpesa;
  late TransactionRepository txs;

  setUp(() async {
    db = AppDatabase(NativeDatabase.memory());
    wallet = await DriftWalletRepository(db)
        .create(name: 'Conto', colorHex: '#0E7C86');
    catSpesa = await DriftCategoryRepository(db).create(
        name: 'Spesa', icon: '🛒', colorHex: '#FF6F61',
        kind: CategoryKind.expense);
    txs = DriftTransactionRepository(db);
  });

  tearDown(() async => db.close());

  group('budget', () {
    test('progress = spent in month vs monthly limit', () async {
      final budgets = DriftBudgetRepository(db);
      await budgets.setMonthlyLimit(categoryId: catSpesa, limitCents: 40000);

      await txs.createExpense(
          walletId: wallet, amountCents: 20000, date: DateTime(2026, 7, 3),
          categoryId: catSpesa);
      await txs.createExpense(
          walletId: wallet, amountCents: 11200, date: DateTime(2026, 7, 10),
          categoryId: catSpesa);
      // altro mese: non conta
      await txs.createExpense(
          walletId: wallet, amountCents: 9999, date: DateTime(2026, 6, 10),
          categoryId: catSpesa);

      final p = await budgets.progressFor(
          categoryId: catSpesa, month: DateTime(2026, 7));
      expect(p.limitCents, 40000);
      expect(p.spentCents, 31200);
    });
  });

  group('ricorrenze', () {
    test('generateDue crea le occorrenze mancanti (catch-up) e avanza nextRunAt',
        () async {
      final recurring = DriftRecurringRepository(db);
      await recurring.create(
        walletId: wallet,
        categoryId: catSpesa,
        type: TransactionType.expense,
        amountCents: 65000,
        description: 'Affitto',
        frequency: RecurrenceFrequency.monthly,
        startAt: DateTime(2026, 5, 1),
      );

      final created = await recurring.generateDue(now: DateTime(2026, 7, 15));
      expect(created, 3); // mag, giu, lug

      final rules = await recurring.getAll();
      expect(rules.single.nextRunAt, DateTime(2026, 8, 1));

      // idempotente: seconda chiamata nello stesso momento non crea nulla
      expect(await recurring.generateDue(now: DateTime(2026, 7, 15)), 0);

      final totals = await txs.totalsForPeriod(
          from: DateTime(2026, 5, 1), to: DateTime(2026, 8, 1));
      expect(totals.expenseCents, 65000 * 3);
    });
  });
}
