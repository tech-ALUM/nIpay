import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/tables.dart';
import 'transaction_repository.dart';

export '../db/tables.dart' show RecurrenceFrequency, TransactionType;

abstract interface class RecurringRepository {
  Future<String> create({
    required String walletId,
    String? categoryId,
    required TransactionType type,
    required int amountCents,
    String description,
    required RecurrenceFrequency frequency,
    required DateTime startAt,
    DateTime? endAt,
  });
  Future<List<RecurringRule>> getAll();

  /// Genera tutte le occorrenze scadute fino a [now] (catch-up) e avanza
  /// [RecurringRule.nextRunAt]. Ritorna quante transazioni ha creato.
  Future<int> generateDue({required DateTime now});
  Future<void> pause(String id);
  Future<void> softDelete(String id);
}

class DriftRecurringRepository implements RecurringRepository {
  DriftRecurringRepository(this._db)
    : _transactions = DriftTransactionRepository(_db);

  final AppDatabase _db;
  final TransactionRepository _transactions;
  final Uuid _uuid = const Uuid();

  @override
  Future<String> create({
    required String walletId,
    String? categoryId,
    required TransactionType type,
    required int amountCents,
    String description = '',
    required RecurrenceFrequency frequency,
    required DateTime startAt,
    DateTime? endAt,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    await _db
        .into(_db.recurringRules)
        .insert(
          RecurringRulesCompanion.insert(
            id: id,
            walletId: walletId,
            categoryId: Value(categoryId),
            type: type,
            amountCents: amountCents,
            description: Value(description),
            frequency: frequency,
            startAt: startAt,
            nextRunAt: startAt,
            endAt: Value(endAt),
            createdAt: now,
            updatedAt: now,
          ),
        );
    return id;
  }

  @override
  Future<List<RecurringRule>> getAll() => (_db.select(
    _db.recurringRules,
  )..where((t) => t.deletedAt.isNull())).get();

  DateTime _advance(DateTime d, RecurrenceFrequency f) => switch (f) {
    RecurrenceFrequency.daily => d.add(const Duration(days: 1)),
    RecurrenceFrequency.weekly => d.add(const Duration(days: 7)),
    // Il giorno viene riportato dal costruttore: 31 gen + 1 mese → 2/3 mar.
    // Per il tracking personale è accettabile; rivedere se servirà "fine mese".
    RecurrenceFrequency.monthly => DateTime(d.year, d.month + 1, d.day),
    RecurrenceFrequency.yearly => DateTime(d.year + 1, d.month, d.day),
  };

  @override
  Future<int> generateDue({required DateTime now}) async {
    final due =
        await (_db.select(_db.recurringRules)..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.pausedAt.isNull() &
                  t.nextRunAt.isSmallerOrEqualValue(now),
            ))
            .get();

    var created = 0;
    for (final rule in due) {
      var next = rule.nextRunAt;
      while (!next.isAfter(now) &&
          (rule.endAt == null || !next.isAfter(rule.endAt!))) {
        switch (rule.type) {
          case TransactionType.expense:
            await _transactions.createExpense(
              walletId: rule.walletId,
              amountCents: rule.amountCents,
              date: next,
              categoryId: rule.categoryId,
              description: rule.description,
            );
          case TransactionType.income:
            await _transactions.createIncome(
              walletId: rule.walletId,
              amountCents: rule.amountCents,
              date: next,
              categoryId: rule.categoryId,
              description: rule.description,
            );
          case TransactionType.transfer:
            throw UnsupportedError(
              'Trasferimenti ricorrenti non supportati (serve walletTo)',
            );
        }
        created++;
        next = _advance(next, rule.frequency);
      }
      await (_db.update(
        _db.recurringRules,
      )..where((t) => t.id.equals(rule.id))).write(
        RecurringRulesCompanion(
          nextRunAt: Value(next),
          updatedAt: Value(DateTime.now()),
        ),
      );
    }
    return created;
  }

  @override
  Future<void> pause(String id) =>
      (_db.update(_db.recurringRules)..where((t) => t.id.equals(id))).write(
        RecurringRulesCompanion(
          pausedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

  @override
  Future<void> softDelete(String id) =>
      (_db.update(_db.recurringRules)..where((t) => t.id.equals(id))).write(
        RecurringRulesCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
