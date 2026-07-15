import 'package:drift/drift.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
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
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  @override
  int get schemaVersion => 1;
}
