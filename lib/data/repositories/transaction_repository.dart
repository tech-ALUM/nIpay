import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

export '../db/tables.dart' show TransactionType;

typedef PeriodTotals = ({int expenseCents, int incomeCents});
typedef CategoryTotal = ({String? categoryId, int totalCents});
typedef MonthTotals = ({
  int year,
  int month,
  int incomeCents,
  int expenseCents,
});

abstract interface class TransactionRepository {
  /// [sharedExpenseId]: la propria quota di una spesa divisa (M-SOC4).
  Future<String> createExpense({
    required String walletId,
    required int amountCents,
    required DateTime date,
    String? categoryId,
    String description,
    String? entryCurrency,
    int? entryAmountCents,
    String? sharedExpenseId,
  });
  Future<String> createIncome({
    required String walletId,
    required int amountCents,
    required DateTime date,
    String? categoryId,
    String description,
    String? entryCurrency,
    int? entryAmountCents,
  });
  Future<String> createTransfer({
    required String fromWalletId,
    required String toWalletId,
    required int amountCents,
    required DateTime date,
    String description,
    String? entryCurrency,
    int? entryAmountCents,

    /// Solo se il portafoglio di destinazione ha valuta diversa: importo
    /// accreditato nella SUA valuta.
    int? amountCentsTo,
  });

  /// Movimento "con amici" (M-SOC4): [outgoing] = soldi usciti per altri
  /// ([TransactionType.friendOut]), altrimenti messi da altri per te
  /// ([TransactionType.friendIn]). Cambia il saldo, non spese né entrate.
  Future<String> createFriendMovement({
    required String walletId,
    required int amountCents,
    required DateTime date,
    required bool outgoing,
    String description,
    String? entryCurrency,
    int? entryAmountCents,
    String? sharedExpenseId,
  });

  /// Saldo del portafoglio: iniziale + entrate − spese ± trasferimenti ±
  /// movimenti con amici.
  Future<int> balanceOf(String walletId);

  /// Totali spese/entrate nel periodo [from, to). Trasferimenti e movimenti
  /// con amici sono esclusi.
  /// Con [walletId] limita al singolo portafoglio.
  Future<PeriodTotals> totalsForPeriod({
    required DateTime from,
    required DateTime to,
    String? walletId,
  });

  /// Totale spese per categoria in [from, to), ordinato per totale decrescente.
  Future<List<CategoryTotal>> expensesByCategory({
    required DateTime from,
    required DateTime to,
    String? walletId,
  });

  /// Entrate/uscite per ciascuno degli ultimi [months] mesi fino a [until]
  /// incluso, dal più vecchio al più recente.
  Future<List<MonthTotals>> monthlySeries({
    required int months,
    required DateTime until,
    String? walletId,
  });

  /// Con [walletId] include anche i trasferimenti in arrivo (walletToId).
  Stream<List<Transaction>> watchRecent({int limit, String? walletId});

  /// Modifica retroattiva: aggiorna solo i campi passati.
  /// [entryAmountCents]: l'importo come digitato nella valuta originale,
  /// solo se la transazione ne ha una (es. una quota di spesa divisa in
  /// un'altra valuta).
  Future<void> updateTransaction(
    String id, {
    int? amountCents,
    DateTime? date,
    String? categoryId,
    String? description,
    int? entryAmountCents,
  });
  Future<void> softDelete(String id);

  /// I miei movimenti (vivi) collegati a una spesa divisa: la quota e il
  /// movimento "con amici".
  Future<List<Transaction>> linkedTo(String sharedExpenseId);
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
    String? entryCurrency,
    int? entryAmountCents,
    int? amountCentsTo,
    String? sharedExpenseId,
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
            entryCurrency: Value(entryCurrency),
            entryAmountCents: Value(entryAmountCents),
            amountCentsTo: Value(amountCentsTo),
            sharedExpenseId: Value(sharedExpenseId),
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
    String? entryCurrency,
    int? entryAmountCents,
    String? sharedExpenseId,
  }) => _insert(
    type: TransactionType.expense,
    walletId: walletId,
    amountCents: amountCents,
    date: date,
    categoryId: categoryId,
    description: description,
    entryCurrency: entryCurrency,
    entryAmountCents: entryAmountCents,
    sharedExpenseId: sharedExpenseId,
  );

  @override
  Future<String> createIncome({
    required String walletId,
    required int amountCents,
    required DateTime date,
    String? categoryId,
    String description = '',
    String? entryCurrency,
    int? entryAmountCents,
  }) => _insert(
    type: TransactionType.income,
    walletId: walletId,
    amountCents: amountCents,
    date: date,
    categoryId: categoryId,
    description: description,
    entryCurrency: entryCurrency,
    entryAmountCents: entryAmountCents,
  );

  @override
  Future<String> createTransfer({
    required String fromWalletId,
    required String toWalletId,
    required int amountCents,
    required DateTime date,
    String description = '',
    String? entryCurrency,
    int? entryAmountCents,
    int? amountCentsTo,
  }) => _insert(
    type: TransactionType.transfer,
    walletId: fromWalletId,
    walletToId: toWalletId,
    amountCents: amountCents,
    date: date,
    description: description,
    entryCurrency: entryCurrency,
    entryAmountCents: entryAmountCents,
    amountCentsTo: amountCentsTo,
  );

  @override
  Future<String> createFriendMovement({
    required String walletId,
    required int amountCents,
    required DateTime date,
    required bool outgoing,
    String description = '',
    String? entryCurrency,
    int? entryAmountCents,
    String? sharedExpenseId,
  }) => _insert(
    type: outgoing ? TransactionType.friendOut : TransactionType.friendIn,
    walletId: walletId,
    amountCents: amountCents,
    date: date,
    description: description,
    entryCurrency: entryCurrency,
    entryAmountCents: entryAmountCents,
    sharedExpenseId: sharedExpenseId,
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
          // Cross-valuta: il credito usa l'importo convertito nella valuta
          // del portafoglio di destinazione, se presente.
          if (tx.walletToId == walletId) {
            balance += tx.amountCentsTo ?? tx.amountCents;
          }
        case TransactionType.friendIn:
          balance += tx.amountCents;
        case TransactionType.friendOut:
          balance -= tx.amountCents;
      }
    }
    return balance;
  }

  @override
  Future<PeriodTotals> totalsForPeriod({
    required DateTime from,
    required DateTime to,
    String? walletId,
  }) async {
    final rows =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.type.equalsValue(TransactionType.transfer).not() &
                  t.date.isBiggerOrEqualValue(from) &
                  t.date.isSmallerThanValue(to) &
                  (walletId == null
                      ? const Constant(true)
                      : t.walletId.equals(walletId)),
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
  Future<List<CategoryTotal>> expensesByCategory({
    required DateTime from,
    required DateTime to,
    String? walletId,
  }) async {
    final sum = _db.transactions.amountCents.sum();
    final rows =
        await (_db.selectOnly(_db.transactions)
              ..addColumns([_db.transactions.categoryId, sum])
              ..where(
                _db.transactions.deletedAt.isNull() &
                    _db.transactions.type.equalsValue(TransactionType.expense) &
                    _db.transactions.date.isBiggerOrEqualValue(from) &
                    _db.transactions.date.isSmallerThanValue(to) &
                    (walletId == null
                        ? const Constant(true)
                        : _db.transactions.walletId.equals(walletId)),
              )
              ..groupBy([_db.transactions.categoryId])
              ..orderBy([OrderingTerm.desc(sum)]))
            .get();
    return [
      for (final r in rows)
        (
          categoryId: r.read(_db.transactions.categoryId),
          totalCents: r.read(sum) ?? 0,
        ),
    ];
  }

  @override
  Future<List<MonthTotals>> monthlySeries({
    required int months,
    required DateTime until,
    String? walletId,
  }) async {
    final from = DateTime(until.year, until.month - months + 1);
    final to = DateTime(until.year, until.month + 1);
    final rows =
        await (_db.select(_db.transactions)..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.type.equalsValue(TransactionType.transfer).not() &
                  t.date.isBiggerOrEqualValue(from) &
                  t.date.isSmallerThanValue(to) &
                  (walletId == null
                      ? const Constant(true)
                      : t.walletId.equals(walletId)),
            ))
            .get();

    return [
      for (var i = months - 1; i >= 0; i--)
        () {
          final m = DateTime(until.year, until.month - i);
          var income = 0, expense = 0;
          for (final tx in rows.where(
            (t) => t.date.year == m.year && t.date.month == m.month,
          )) {
            if (tx.type == TransactionType.income) income += tx.amountCents;
            if (tx.type == TransactionType.expense) expense += tx.amountCents;
          }
          return (
            year: m.year,
            month: m.month,
            incomeCents: income,
            expenseCents: expense,
          );
        }(),
    ];
  }

  @override
  Stream<List<Transaction>> watchRecent({int limit = 20, String? walletId}) =>
      (_db.select(_db.transactions)
            ..where(
              (t) =>
                  t.deletedAt.isNull() &
                  (walletId == null
                      ? const Constant(true)
                      : (t.walletId.equals(walletId) |
                            t.walletToId.equals(walletId))),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.date)])
            ..limit(limit))
          .watch();

  @override
  Future<void> updateTransaction(
    String id, {
    int? amountCents,
    DateTime? date,
    String? categoryId,
    String? description,
    int? entryAmountCents,
  }) => (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
    TransactionsCompanion(
      amountCents: amountCents == null
          ? const Value.absent()
          : Value(amountCents),
      entryAmountCents: entryAmountCents == null
          ? const Value.absent()
          : Value(entryAmountCents),
      date: date == null ? const Value.absent() : Value(date),
      categoryId: categoryId == null ? const Value.absent() : Value(categoryId),
      description: description == null
          ? const Value.absent()
          : Value(description),
      updatedAt: Value(DateTime.now()),
    ),
  );

  @override
  Future<void> softDelete(String id) =>
      (_db.update(_db.transactions)..where((t) => t.id.equals(id))).write(
        TransactionsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<List<Transaction>> linkedTo(String sharedExpenseId) =>
      (_db.select(_db.transactions)..where(
            (t) =>
                t.deletedAt.isNull() &
                t.sharedExpenseId.equals(sharedExpenseId),
          ))
          .get();
}
