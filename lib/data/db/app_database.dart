import 'package:drift/drift.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    Wallets,
    Categories,
    Transactions,
    Tags,
    TransactionTags,
    CustomFieldDefs,
    CustomFieldValues,
    Budgets,
    RecurringRules,
    Attachments,
    DashboardCards,
    CostCenters,
    ExpenseReports,
    ExpenseReportEntries,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 5) {
        // v5: multi-valuta. Default 'EUR' per i portafogli esistenti; le
        // nuove colonne su transactions restano NULL (= nessuna conversione,
        // comportamento identico a prima).
        await m.addColumn(wallets, wallets.currency);
        await m.addColumn(transactions, transactions.entryCurrency);
        await m.addColumn(transactions, transactions.entryAmountCents);
        await m.addColumn(transactions, transactions.amountCentsTo);
      }
      if (from < 4) {
        // v4: ordine portafogli (drag-to-reorder in home). Backfill in
        // base a createdAt, così l'ordine esistente non cambia.
        await m.addColumn(wallets, wallets.position);
        await customStatement('''
          UPDATE wallets SET position = (
            SELECT COUNT(*) FROM wallets w2 WHERE w2.created_at < wallets.created_at
          )
        ''');
      }
      if (from < 3) {
        // v3: nota spese.
        await m.createTable(costCenters);
        await m.createTable(expenseReports);
        await m.createTable(expenseReportEntries);
        await m.addColumn(customFieldDefs, customFieldDefs.expenseReportOnly);
      }
      if (from < 2) {
        // v2: taxonomy per-portafoglio. Le righe esistenti (globali)
        // vengono assegnate al portafoglio più vecchio.
        await m.addColumn(categories, categories.walletId);
        await m.addColumn(tags, tags.walletId);
        await m.addColumn(customFieldDefs, customFieldDefs.walletId);
        await m.addColumn(budgets, budgets.walletId);
        await m.addColumn(dashboardCards, dashboardCards.walletId);
        const backfill = "(SELECT id FROM wallets ORDER BY created_at LIMIT 1)";
        for (final table in [
          'categories',
          'tags',
          'custom_field_defs',
          'budgets',
          'dashboard_cards',
        ]) {
          await customStatement(
            'UPDATE $table SET wallet_id = $backfill WHERE wallet_id IS NULL',
          );
        }
      }
    },
  );
}
