import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

typedef BudgetProgress = ({int spentCents, int limitCents});

abstract interface class BudgetRepository {
  /// Crea o aggiorna il tetto mensile della categoria.
  Future<void> setMonthlyLimit({
    required String walletId,
    required String categoryId,
    required int limitCents,
  });
  Future<List<Budget>> getAll(String walletId);

  /// Speso nel mese (solo spese vive della categoria) vs tetto.
  Future<BudgetProgress> progressFor({
    required String categoryId,
    required DateTime month,
  });
  Future<void> softDelete(String id);
}

class DriftBudgetRepository implements BudgetRepository {
  DriftBudgetRepository(this._db);

  final AppDatabase _db;
  final Uuid _uuid = const Uuid();

  @override
  Future<void> setMonthlyLimit({
    required String walletId,
    required String categoryId,
    required int limitCents,
  }) async {
    final now = DateTime.now();
    final existing = await (_db.select(
      _db.budgets,
    )..where((t) => t.categoryId.equals(categoryId))).getSingleOrNull();
    if (existing == null) {
      await _db
          .into(_db.budgets)
          .insert(
            BudgetsCompanion.insert(
              id: _uuid.v4(),
              walletId: Value(walletId),
              categoryId: categoryId,
              limitCents: limitCents,
              createdAt: now,
              updatedAt: now,
            ),
          );
    } else {
      await (_db.update(
        _db.budgets,
      )..where((t) => t.id.equals(existing.id))).write(
        BudgetsCompanion(
          limitCents: Value(limitCents),
          deletedAt: const Value(null),
          updatedAt: Value(now),
        ),
      );
    }
  }

  @override
  Future<List<Budget>> getAll(String walletId) => (_db.select(
    _db.budgets,
  )..where((t) => t.deletedAt.isNull() & t.walletId.equals(walletId))).get();

  @override
  Future<BudgetProgress> progressFor({
    required String categoryId,
    required DateTime month,
  }) async {
    final budget = await (_db.select(
      _db.budgets,
    )..where((t) => t.categoryId.equals(categoryId))).getSingle();

    final from = DateTime(month.year, month.month);
    final to = DateTime(month.year, month.month + 1);
    final spentExp = _db.transactions.amountCents.sum();
    final row =
        await (_db.selectOnly(_db.transactions)
              ..addColumns([spentExp])
              ..where(
                _db.transactions.deletedAt.isNull() &
                    _db.transactions.categoryId.equals(categoryId) &
                    _db.transactions.type.equalsValue(TransactionType.expense) &
                    _db.transactions.date.isBiggerOrEqualValue(from) &
                    _db.transactions.date.isSmallerThanValue(to),
              ))
            .getSingle();

    return (spentCents: row.read(spentExp) ?? 0, limitCents: budget.limitCents);
  }

  @override
  Future<void> softDelete(String id) =>
      (_db.update(_db.budgets)..where((t) => t.id.equals(id))).write(
        BudgetsCompanion(
          deletedAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );
}
