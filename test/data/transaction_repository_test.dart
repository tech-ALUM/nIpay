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
        name: 'Conto', colorHex: '#0E7C86', initialBalanceCents: 100000);
    contanti = await wallets.create(
        name: 'Contanti', colorHex: '#FF6F61', initialBalanceCents: 5000);
  });

  tearDown(() async => db.close());

  test('balance = initial + income − expense', () async {
    await repo.createIncome(
        walletId: conto, amountCents: 185000, date: DateTime(2026, 7, 1));
    await repo.createExpense(
        walletId: conto, amountCents: 4250, date: DateTime(2026, 7, 15));

    expect(await repo.balanceOf(conto), 100000 + 185000 - 4250);
  });

  test('transfer moves money between wallets', () async {
    await repo.createTransfer(
        fromWalletId: conto,
        toWalletId: contanti,
        amountCents: 10000,
        date: DateTime(2026, 6, 30));

    expect(await repo.balanceOf(conto), 100000 - 10000);
    expect(await repo.balanceOf(contanti), 5000 + 10000);
  });

  test('period totals exclude transfers', () async {
    await repo.createIncome(
        walletId: conto, amountCents: 185000, date: DateTime(2026, 7, 1));
    await repo.createExpense(
        walletId: conto, amountCents: 4250, date: DateTime(2026, 7, 15));
    await repo.createTransfer(
        fromWalletId: conto,
        toWalletId: contanti,
        amountCents: 10000,
        date: DateTime(2026, 7, 2));
    // fuori periodo
    await repo.createExpense(
        walletId: conto, amountCents: 9999, date: DateTime(2026, 6, 20));

    final t = await repo.totalsForPeriod(
        from: DateTime(2026, 7, 1), to: DateTime(2026, 8, 1));
    expect(t.incomeCents, 185000);
    expect(t.expenseCents, 4250);
  });

  test('soft-deleted transactions do not affect balance', () async {
    final id = await repo.createExpense(
        walletId: conto, amountCents: 4250, date: DateTime(2026, 7, 15));
    await repo.softDelete(id);

    expect(await repo.balanceOf(conto), 100000);
  });
}
