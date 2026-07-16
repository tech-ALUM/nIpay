import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/export/excel_codec.dart';
import 'package:nipay/data/export/json_codec.dart';
import 'package:nipay/data/repositories/budget_repository.dart';
import 'package:nipay/data/repositories/category_repository.dart';
import 'package:nipay/data/repositories/custom_field_repository.dart';
import 'package:nipay/data/repositories/dashboard_repository.dart';
import 'package:nipay/data/repositories/recurring_repository.dart';
import 'package:nipay/data/repositories/tag_repository.dart';
import 'package:nipay/data/repositories/transaction_repository.dart';
import 'package:nipay/data/repositories/wallet_repository.dart';

/// Popola un DB con un campione di tutte le entità.
Future<void> seed(AppDatabase db) async {
  final wallet = await DriftWalletRepository(
    db,
  ).create(name: 'Conto', colorHex: '#0E7C86', initialBalanceCents: 100000);
  final cat = await DriftCategoryRepository(db).create(
    walletId: wallet,
    name: 'Spesa',
    icon: '🛒',
    colorHex: '#FF6F61',
    kind: CategoryKind.expense,
  );
  final txs = DriftTransactionRepository(db);
  final tx = await txs.createExpense(
    walletId: wallet,
    amountCents: 4250,
    date: DateTime(2026, 7, 15),
    categoryId: cat,
    description: 'Esselunga',
  );
  await txs.createIncome(
    walletId: wallet,
    amountCents: 185000,
    date: DateTime(2026, 7, 1),
  );
  final tags = DriftTagRepository(db);
  final tag = await tags.create('casa', walletId: wallet);
  await tags.tagTransaction(tx, tag);
  final fields = DriftCustomFieldRepository(db);
  final field = await fields.define(
    walletId: wallet,
    name: 'Metodo',
    type: CustomFieldType.choice,
    options: ['Carta'],
  );
  await fields.setValue(transactionId: tx, fieldId: field, value: 'Carta');
  await DriftBudgetRepository(
    db,
  ).setMonthlyLimit(walletId: wallet, categoryId: cat, limitCents: 40000);
  await DriftRecurringRepository(db).create(
    walletId: wallet,
    type: TransactionType.expense,
    amountCents: 65000,
    description: 'Affitto',
    frequency: RecurrenceFrequency.monthly,
    startAt: DateTime(2026, 8, 1),
  );
  await DriftDashboardRepository(
    db,
  ).addCard(walletId: wallet, type: 'cashflow', configJson: '{"x":1}');
}

void main() {
  test('JSON export → import into empty DB restores everything', () async {
    final source = AppDatabase(NativeDatabase.memory());
    await seed(source);

    final json = await exportToJson(source);
    expect(json['schemaVersion'], 2);

    final target = AppDatabase(NativeDatabase.memory());
    await importFromJson(target, json);

    expect(await target.select(target.wallets).get(), hasLength(1));
    expect(await target.select(target.categories).get(), hasLength(1));
    expect(await target.select(target.transactions).get(), hasLength(2));
    expect(await target.select(target.tags).get(), hasLength(1));
    expect(await target.select(target.transactionTags).get(), hasLength(1));
    expect(await target.select(target.customFieldDefs).get(), hasLength(1));
    expect(await target.select(target.customFieldValues).get(), hasLength(1));
    expect(await target.select(target.budgets).get(), hasLength(1));
    expect(await target.select(target.recurringRules).get(), hasLength(1));
    expect(await target.select(target.dashboardCards).get(), hasLength(1));

    // Round-trip fedele: saldo ricalcolato identico.
    final wallet = (await target.select(target.wallets).get()).single;
    expect(
      await DriftTransactionRepository(target).balanceOf(wallet.id),
      100000 + 185000 - 4250,
    );
    final def = (await target.select(target.customFieldDefs).get()).single;
    expect(def.options, ['Carta']);

    await source.close();
    await target.close();
  });

  test('import wipes pre-existing data before restoring', () async {
    final source = AppDatabase(NativeDatabase.memory());
    await seed(source);
    final json = await exportToJson(source);

    final target = AppDatabase(NativeDatabase.memory());
    await DriftWalletRepository(
      target,
    ).create(name: 'Vecchio', colorHex: '#000000');
    await importFromJson(target, json);

    final wallets = await target.select(target.wallets).get();
    expect(wallets.map((w) => w.name), ['Conto']);

    await source.close();
    await target.close();
  });

  test('wallet export → additive import with fresh ids', () async {
    final db = AppDatabase(NativeDatabase.memory());
    await seed(db);
    final walletId = (await db.select(db.wallets).get()).single.id;

    final json = await exportWalletToJson(db, walletId);
    expect(json['kind'], 'wallet');

    // Import nello STESSO db: aggiunge un secondo spazio, senza collisioni.
    final newWalletId = await importWalletFromJson(db, json);
    expect(newWalletId, isNot(walletId));
    expect(await db.select(db.wallets).get(), hasLength(2));
    expect(await db.select(db.categories).get(), hasLength(2));
    expect(await db.select(db.transactions).get(), hasLength(4));

    // Lo spazio importato è coerente: saldo identico all'originale.
    final txRepo = DriftTransactionRepository(db);
    expect(
      await txRepo.balanceOf(newWalletId),
      await txRepo.balanceOf(walletId),
    );

    // Reimportare ANCORA lo stesso file funziona (id sempre freschi).
    await importWalletFromJson(db, json);
    expect(await db.select(db.wallets).get(), hasLength(3));

    await db.close();
  });

  test(
    'Excel export → import restores wallets/categories/transactions/budgets',
    () async {
      final source = AppDatabase(NativeDatabase.memory());
      await seed(source);

      final bytes = await exportToExcel(source);
      expect(bytes, isNotEmpty);

      final target = AppDatabase(NativeDatabase.memory());
      await importFromExcel(target, bytes);

      expect(await target.select(target.wallets).get(), hasLength(1));
      expect(await target.select(target.categories).get(), hasLength(1));
      final txs = await target.select(target.transactions).get();
      expect(txs, hasLength(2));
      expect(txs.map((t) => t.amountCents).toSet(), {4250, 185000});
      expect(await target.select(target.budgets).get(), hasLength(1));

      await source.close();
      await target.close();
    },
  );
}
