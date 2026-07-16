import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/repositories/attachment_repository.dart';

import '../data/db/app_database.dart';
import '../data/repositories/budget_repository.dart';
import '../data/repositories/category_repository.dart';
import '../data/repositories/dashboard_repository.dart';
import '../data/repositories/custom_field_repository.dart';
import '../data/repositories/recurring_repository.dart';
import '../data/repositories/tag_repository.dart';
import '../data/repositories/transaction_repository.dart';
import '../data/repositories/wallet_repository.dart';

/// Executor del DB: nei test viene sostituito con NativeDatabase.memory().
final databaseExecutorProvider = Provider<QueryExecutor>(
  (ref) => driftDatabase(name: 'nipay'),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase(ref.watch(databaseExecutorProvider));
  ref.onDispose(db.close);
  return db;
});

final walletRepositoryProvider = Provider<WalletRepository>(
  (ref) => DriftWalletRepository(ref.watch(databaseProvider)),
);
final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => DriftCategoryRepository(ref.watch(databaseProvider)),
);
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => DriftTransactionRepository(ref.watch(databaseProvider)),
);
final recurringRepositoryProvider = Provider<RecurringRepository>(
  (ref) => DriftRecurringRepository(ref.watch(databaseProvider)),
);
final tagRepositoryProvider = Provider<TagRepository>(
  (ref) => DriftTagRepository(ref.watch(databaseProvider)),
);
final customFieldRepositoryProvider = Provider<CustomFieldRepository>(
  (ref) => DriftCustomFieldRepository(ref.watch(databaseProvider)),
);
final budgetRepositoryProvider = Provider<BudgetRepository>(
  (ref) => DriftBudgetRepository(ref.watch(databaseProvider)),
);
final dashboardRepositoryProvider = Provider<DashboardRepository>(
  (ref) => DriftDashboardRepository(ref.watch(databaseProvider)),
);
final attachmentRepositoryProvider = Provider<AttachmentRepository>(
  (ref) => DriftAttachmentRepository(ref.watch(databaseProvider)),
);

/// Directory documenti dell'app (base per i path relativi degli allegati).
final appDirProvider = FutureProvider<Directory>(
  (ref) => getApplicationDocumentsDirectory(),
);

/// Allegati di una transazione.
final attachmentsOfProvider = FutureProvider.family((ref, String txId) {
  ref.watch(recentTransactionsProvider);
  return ref.watch(attachmentRepositoryProvider).listOf(txId);
});

/// Bootstrap alla prima apertura: seed categorie + catch-up ricorrenze.
final bootstrapProvider = FutureProvider<void>((ref) async {
  await ref.read(categoryRepositoryProvider).seedDefaults();
  await ref.read(recurringRepositoryProvider).generateDue(now: DateTime.now());
});

final walletsProvider = StreamProvider(
  (ref) => ref.watch(walletRepositoryProvider).watchAll(),
);

final categoriesProvider = StreamProvider(
  (ref) => ref.watch(categoryRepositoryProvider).watchAll(),
);

final recentTransactionsProvider = StreamProvider(
  (ref) => ref.watch(transactionRepositoryProvider).watchRecent(limit: 50),
);

/// Saldo di un portafoglio, ricalcolato a ogni variazione delle transazioni.
final walletBalanceProvider = FutureProvider.family<int, String>((
  ref,
  walletId,
) {
  ref.watch(recentTransactionsProvider); // invalida al cambiare dei movimenti
  return ref.watch(transactionRepositoryProvider).balanceOf(walletId);
});

/// Saldo totale su tutti i portafogli vivi.
final totalBalanceProvider = FutureProvider<int>((ref) async {
  final wallets = await ref.watch(walletsProvider.future);
  var total = 0;
  for (final w in wallets) {
    total += await ref.watch(walletBalanceProvider(w.id).future);
  }
  return total;
});

/// Totali del mese corrente (entrate/uscite, trasferimenti esclusi).
final monthTotalsProvider = FutureProvider<PeriodTotals>((ref) {
  ref.watch(recentTransactionsProvider);
  final now = DateTime.now();
  return ref
      .watch(transactionRepositoryProvider)
      .totalsForPeriod(
        from: DateTime(now.year, now.month),
        to: DateTime(now.year, now.month + 1),
      );
});

/// Tag e definizioni campi custom (si aggiornano al cambiare delle transazioni
/// perché tag/valori possono nascere dal sheet di inserimento).
final tagsProvider = FutureProvider((ref) {
  ref.watch(recentTransactionsProvider);
  return ref.watch(tagRepositoryProvider).getAll();
});

final customFieldDefsProvider = FutureProvider(
  (ref) => ref.watch(customFieldRepositoryProvider).getDefinitions(),
);

/// Id transazioni con un certo tag (per il filtro della lista).
final txIdsWithTagProvider = FutureProvider.family<Set<String>, String>((
  ref,
  tagId,
) {
  ref.watch(recentTransactionsProvider);
  return ref.watch(tagRepositoryProvider).transactionIdsWithTag(tagId);
});

/// Id transazioni i cui valori custom contengono la query di ricerca.
final txIdsMatchingFieldProvider = FutureProvider.family<Set<String>, String>((
  ref,
  query,
) {
  ref.watch(recentTransactionsProvider);
  return ref.watch(customFieldRepositoryProvider).transactionIdsMatching(query);
});

/// Budget attivi (invalidato dai manager dopo le modifiche).
final budgetsProvider = FutureProvider(
  (ref) => ref.watch(budgetRepositoryProvider).getAll(),
);

/// Avanzamento budget del mese corrente per categoria.
final budgetProgressProvider = FutureProvider.family<BudgetProgress, String>((
  ref,
  categoryId,
) {
  ref.watch(recentTransactionsProvider);
  return ref
      .watch(budgetRepositoryProvider)
      .progressFor(categoryId: categoryId, month: DateTime.now());
});

/// Regole ricorrenti (invalidato dal manager dopo le modifiche).
final recurringRulesProvider = FutureProvider(
  (ref) => ref.watch(recurringRepositoryProvider).getAll(),
);

/// Card della dashboard statistiche (reattivo: riordino/aggiunte via stream).
final dashboardCardsProvider = StreamProvider(
  (ref) => ref.watch(dashboardRepositoryProvider).watchCards(),
);

/// Mese selezionato nella tab Statistiche.
final statsMonthProvider = StateProvider<DateTime>(
  (ref) => DateTime(DateTime.now().year, DateTime.now().month),
);

/// Spese per categoria del mese (chiave: primo giorno del mese).
final expensesByCategoryProvider =
    FutureProvider.family<List<CategoryTotal>, DateTime>((ref, month) {
      ref.watch(recentTransactionsProvider);
      return ref
          .watch(transactionRepositoryProvider)
          .expensesByCategory(
            from: DateTime(month.year, month.month),
            to: DateTime(month.year, month.month + 1),
          );
    });

/// Serie mensile entrate/uscite degli ultimi 6 mesi fino al mese scelto.
final monthlySeriesProvider =
    FutureProvider.family<List<MonthTotals>, DateTime>((ref, month) {
      ref.watch(recentTransactionsProvider);
      return ref
          .watch(transactionRepositoryProvider)
          .monthlySeries(months: 6, until: month);
    });

/// Totali del mese scelto nelle statistiche.
final statsTotalsProvider = FutureProvider.family<PeriodTotals, DateTime>((
  ref,
  month,
) {
  ref.watch(recentTransactionsProvider);
  return ref
      .watch(transactionRepositoryProvider)
      .totalsForPeriod(
        from: DateTime(month.year, month.month),
        to: DateTime(month.year, month.month + 1),
      );
});

/// Iniettato in main() (e nei test) dopo SharedPreferences.getInstance().
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('override in main()'),
);

/// Preferenza tema persistita: Sistema / Chiaro / Scuro.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(
  ThemeModeNotifier.new,
);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  static const _key = 'themeMode';

  @override
  ThemeMode build() {
    final saved = ref.watch(sharedPreferencesProvider).getString(_key);
    return ThemeMode.values.asNameMap()[saved] ?? ThemeMode.system;
  }

  void set(ThemeMode mode) {
    state = mode;
    ref.read(sharedPreferencesProvider).setString(_key, mode.name);
  }
}
