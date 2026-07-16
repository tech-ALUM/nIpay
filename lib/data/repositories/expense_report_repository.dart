import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

export '../db/tables.dart' show ExpenseReportStatus;

/// Spesa flaggata "nota spese": transazione + dati dedicati.
typedef FlaggedExpense = ({Transaction transaction, ExpenseReportEntry entry});

abstract interface class ExpenseReportRepository {
  /// Flagga la spesa come nota spese (o aggiorna i campi se già flaggata).
  /// La semantica è di sovrascrittura completa dei campi.
  Future<void> setExpenseData({
    required String transactionId,
    String? costCenterId,
    bool reimbursable,
    bool eInvoice,
  });

  /// Toglie il flag nota spese dalla spesa.
  Future<void> clearExpenseData(String transactionId);
  Future<ExpenseReportEntry?> dataOf(String transactionId);

  /// Spese flaggate del portafoglio nel periodo [from, to), per data.
  Future<List<FlaggedExpense>> flaggedInRange({
    required String walletId,
    required DateTime from,
    required DateTime to,
  });

  /// Crea la nota spese (bozza) e aggancia le spese flaggate del periodo
  /// non ancora assegnate a un'altra nota.
  Future<String> createReport({
    required String walletId,
    required String name,
    required DateTime from,
    required DateTime to,
  });

  Future<List<ExpenseReport>> getReports(String walletId);
  Future<void> setStatus(String reportId, ExpenseReportStatus status);

  /// Collega l'entrata di rimborso e marca la nota come rimborsata.
  Future<void> linkReimbursement(String reportId, String transactionId);

  /// Totale spese rimborsabili non ancora dentro una nota rimborsata.
  Future<int> pendingReimbursementCents(String walletId);
  Future<void> softDeleteReport(String id);
}

class DriftExpenseReportRepository implements ExpenseReportRepository {
  DriftExpenseReportRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Future<void> setExpenseData({
    required String transactionId,
    String? costCenterId,
    bool reimbursable = true,
    bool eInvoice = false,
  }) async {
    final existing = await dataOf(transactionId);
    await _db
        .into(_db.expenseReportEntries)
        .insertOnConflictUpdate(
          ExpenseReportEntriesCompanion.insert(
            transactionId: transactionId,
            costCenterId: Value(costCenterId),
            reimbursable: Value(reimbursable),
            eInvoice: Value(eInvoice),
            reportId: Value(existing?.reportId),
            updatedAt: DateTime.now(),
          ),
        );
  }

  @override
  Future<void> clearExpenseData(String transactionId) => (_db.delete(
    _db.expenseReportEntries,
  )..where((t) => t.transactionId.equals(transactionId))).go();

  @override
  Future<ExpenseReportEntry?> dataOf(String transactionId) => (_db.select(
    _db.expenseReportEntries,
  )..where((t) => t.transactionId.equals(transactionId))).getSingleOrNull();

  JoinedSelectStatement<HasResultSet, dynamic> _flaggedQuery(
    String walletId,
    DateTime from,
    DateTime to,
  ) =>
      _db.select(_db.expenseReportEntries).join([
        innerJoin(
          _db.transactions,
          _db.transactions.id.equalsExp(_db.expenseReportEntries.transactionId),
        ),
      ])..where(
        _db.transactions.deletedAt.isNull() &
            _db.transactions.walletId.equals(walletId) &
            _db.transactions.type.equalsValue(TransactionType.expense) &
            _db.transactions.date.isBiggerOrEqualValue(from) &
            _db.transactions.date.isSmallerThanValue(to),
      );

  @override
  Future<List<FlaggedExpense>> flaggedInRange({
    required String walletId,
    required DateTime from,
    required DateTime to,
  }) async {
    final query = _flaggedQuery(walletId, from, to)
      ..orderBy([OrderingTerm.asc(_db.transactions.date)]);
    final rows = await query.get();
    return [
      for (final r in rows)
        (
          transaction: r.readTable(_db.transactions),
          entry: r.readTable(_db.expenseReportEntries),
        ),
    ];
  }

  @override
  Future<String> createReport({
    required String walletId,
    required String name,
    required DateTime from,
    required DateTime to,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db.transaction(() async {
      await _db
          .into(_db.expenseReports)
          .insert(
            ExpenseReportsCompanion.insert(
              id: id,
              walletId: Value(walletId),
              name: name,
              dateFrom: from,
              dateTo: to,
              status: ExpenseReportStatus.draft,
              createdAt: now,
              updatedAt: now,
            ),
          );
      final flagged = await flaggedInRange(
        walletId: walletId,
        from: from,
        to: to,
      );
      final free = [
        for (final f in flagged)
          if (f.entry.reportId == null) f.transaction.id,
      ];
      if (free.isNotEmpty) {
        await (_db.update(
          _db.expenseReportEntries,
        )..where((t) => t.transactionId.isIn(free))).write(
          ExpenseReportEntriesCompanion(
            reportId: Value(id),
            updatedAt: Value(now),
          ),
        );
      }
    });
    return id;
  }

  @override
  Future<List<ExpenseReport>> getReports(String walletId) =>
      (_db.select(_db.expenseReports)
            ..where((t) => t.deletedAt.isNull() & t.walletId.equals(walletId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  @override
  Future<void> setStatus(String reportId, ExpenseReportStatus status) =>
      (_db.update(
        _db.expenseReports,
      )..where((t) => t.id.equals(reportId))).write(
        ExpenseReportsCompanion(
          status: Value(status),
          updatedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<void> linkReimbursement(String reportId, String transactionId) =>
      (_db.update(
        _db.expenseReports,
      )..where((t) => t.id.equals(reportId))).write(
        ExpenseReportsCompanion(
          reimburseTxId: Value(transactionId),
          status: const Value(ExpenseReportStatus.reimbursed),
          updatedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<int> pendingReimbursementCents(String walletId) async {
    final rows =
        await (_db.select(_db.expenseReportEntries).join([
              innerJoin(
                _db.transactions,
                _db.transactions.id.equalsExp(
                  _db.expenseReportEntries.transactionId,
                ),
              ),
              leftOuterJoin(
                _db.expenseReports,
                _db.expenseReports.id.equalsExp(
                  _db.expenseReportEntries.reportId,
                ),
              ),
            ])..where(
              _db.transactions.deletedAt.isNull() &
                  _db.transactions.walletId.equals(walletId) &
                  _db.transactions.type.equalsValue(TransactionType.expense) &
                  _db.expenseReportEntries.reimbursable.equals(true),
            ))
            .get();

    var total = 0;
    for (final r in rows) {
      final report = r.readTableOrNull(_db.expenseReports);
      if (report == null || report.status != ExpenseReportStatus.reimbursed) {
        total += r.readTable(_db.transactions).amountCents;
      }
    }
    return total;
  }

  @override
  Future<void> softDeleteReport(String id) =>
      (_db.update(_db.expenseReports)..where((t) => t.id.equals(id))).write(
        ExpenseReportsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
