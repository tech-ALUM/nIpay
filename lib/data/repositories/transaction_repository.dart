import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

export '../db/tables.dart' show TransactionType;

typedef PeriodTotals = ({int expenseCents, int incomeCents});

abstract interface class TransactionRepository {
  Future<String> createExpense({
    required String walletId,
    required int amountCents,
    required DateTime date,
    String? categoryId,
    String description,
  });
  Future<String> createIncome({
    required String walletId,
    required int amountCents,
    required DateTime date,
    String? categoryId,
    String description,
  });
  Future<String> createTransfer({
    required String fromWalletId,
    required String toWalletId,
    required int amountCents,
    required DateTime date,
    String description,
  });

  /// Saldo del portafoglio: iniziale + entrate − spese ± trasferimenti.
  Future<int> balanceOf(String walletId);

  /// Totali spese/entrate nel periodo [from, to). I trasferimenti sono esclusi.
  Future<PeriodTotals> totalsForPeriod({
    required DateTime from,
    required DateTime to,
  });

  Stream<List<Transaction>> watchRecent({int limit});
  Future<void> softDelete(String id);
}

class DriftTransactionRepository implements TransactionRepository {
  DriftTransactionRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  Future<String> _insert({
    required TransactionType type,
    required String walletId,
    String? walletToId,
    required int amountCents,
    required DateTime date,
    String? categoryId,
    String description = '',
  }) async {
    assert(amountCents > 0, 'amountCents deve essere positivo');
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db
        .into(_db.transactions)
        .insert(
          TransactionsCompanion.insert(
            id: id,
            type: type,
            amountCents: amountCents,
            date: date,
            walletId: walletId,
            walletToId: Value(walletToId),
            categoryId: Value(categoryId),
            description: Value(description),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Future<String> createExpense({
    required String walletId,
    required int amountCents,
    required DateTime date,
    String? categoryId,
    String description = '',
  }) => _insert(
    type: TransactionType.expense,
    walletId: walletId,
    amountCents: amountCents,
    date: date,
    categoryId: categoryId,
    description: description,
  );

  @override
  Future<String> createIncome({
    required String walletId,
    required int amountCents,
    required DateTime date,
    String? categoryId,
    String description = '',
  }) => _insert(
    type: TransactionType.income,
    walletId: walletId,
    amountCents: amountCents,
    date: date,
    categoryId: categoryId,
    description: description,
  );

  @override
  Future<String> createTransfer({
    required String fromWalletId,
    required String toWalletId,
    required int amountCents,
    required DateTime date,
    String description = '',
  }) => _insert(
    type: TransactionType.transfer,
    walletId: fromWalletId,
    walletToId: toWalletId,
    amountCents: amountCents,
    date: date,
    description: description,
  );

  @override
  Future<int> balanceOf(String walletId) async {
    final wallet = await (_db.select(
      _db.wallets,
    )..where((t) => t.id.equals(walletId))).getSingle();

    final rows =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.deletedAt.isNull() &
                  (t.walletId.equals(walletId) | t.walletToId.equals(walletId)),
            ))
            .get();

    var balance = wallet.initialBalanceCents;
    for (final tx in rows) {
      switch (tx.type) {
        case TransactionType.income:
          balance += tx.amountCents;
        case TransactionType.expense:
          balance -= tx.amountCents;
        case TransactionType.transfer:
          if (tx.walletId == walletId) balance -= tx.amountCents;
          if (tx.walletToId == walletId) balance += tx.amountCents;
      }
    }
    return balance;
  }

  @override
  Future<PeriodTotals> totalsForPeriod({
    required DateTime from,
    required DateTime to,
  }) async {
    final rows =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.type.equalsValue(TransactionType.transfer).not() &
                  t.date.isBiggerOrEqualValue(from) &
                  t.date.isSmallerThanValue(to),
            ))
            .get();

    var expense = 0, income = 0;
    for (final tx in rows) {
      if (tx.type == TransactionType.expense) expense += tx.amountCents;
      if (tx.type == TransactionType.income) income += tx.amountCents;
    }
    return (expenseCents: expense, incomeCents: income);
  }

  @override
  Stream<List<Transaction>> watchRecent({int limit = 20}) =>
      (_db.select(_db.transactions)
            ..where((t) => t.deletedAt.isNull())
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(limit))
          .watch();

  @override
  Future<void> softDelete(String id) =>
      (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
