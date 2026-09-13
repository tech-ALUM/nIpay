import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/app_database.dart';
import '../db/tables.dart';

/// Astrazione sopra l'accesso di rete a Postgres — stesso motivo di
/// `AuthService`: isolare la sync engine dal client Supabase concreto,
/// così la logica di watermark/ordinamento/mapping è testabile con un
/// finto "server" in memoria, senza toccare la rete.
abstract interface class SyncRemote {
  /// Upsert per `id` (o chiave primaria composta, per le tabelle di
  /// join). No-op se [rows] è vuota.
  Future<void> upsert(String table, List<Map<String, dynamic>> rows);

  /// Righe con `[column] > since`, ordinamento non garantito.
  Future<List<Map<String, dynamic>>> selectChangedSince(
    String table,
    DateTime since, {
    String column = 'updated_at',
  });
}

class SupabaseSyncRemote implements SyncRemote {
  SupabaseSyncRemote(this._client);

  final SupabaseClient _client;

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    if (rows.isEmpty) return;
    await _client.from(table).upsert(rows);
  }

  @override
  Future<List<Map<String, dynamic>>> selectChangedSince(
    String table,
    DateTime since, {
    String column = 'updated_at',
  }) {
    return _client
        .from(table)
        .select()
        .gt(column, since.toUtc().toIso8601String());
  }
}

/// Motore di sync (M-ACC6): push/pull incrementale tra il Drift locale e
/// Postgres (schema in `supabase/migrations/`), guidato da due watermark
/// per utente (`SyncStates`, uno per push nel dominio dell'orologio
/// locale, uno per pull nel dominio dell'orologio server — vedi commento
/// su `SyncStates` in `tables.dart` per il perché della separazione).
///
/// Nota di scope: gli **allegati** (foto scontrini) sono esclusi da questa
/// prima versione — sincronizzarli richiede anche l'upload/download del
/// file binario su Supabase Storage (M-ACC3), non solo la riga di
/// metadata; è un lavoro a sé, rimandato a un passo successivo.
abstract interface class SyncService {
  /// Sincronizza subito. No-op silenzioso se non c'è un utente loggato
  /// (modalità solo-locale) — mai un errore per questo caso, è normale.
  Future<void> syncNow();
}

/// Ordine di sync: genitori prima dei figli, sia per il push (rispetta le
/// foreign key su Postgres) sia per il pull (rispetta le foreign key
/// locali, dato che lo schema Drift usa `.references()` anch'esso).
class SupabaseSyncService implements SyncService {
  SupabaseSyncService(
    this._remote,
    this._db, {
    required String? Function() currentUserId,
  }) : _currentUserId = currentUserId;

  final SyncRemote _remote;
  final AppDatabase _db;
  final String? Function() _currentUserId;

  static final DateTime _epoch = DateTime.utc(1970);

  @override
  Future<void> syncNow() async {
    final userId = _currentUserId();
    if (userId == null) return;

    final state = await (_db.select(
      _db.syncStates,
    )..where((t) => t.userId.equals(userId))).getSingleOrNull();
    final pushSince = state?.lastPushedAt ?? _epoch;
    final pullSince = state?.lastPulledAt ?? _epoch;

    // Il watermark di push si cattura PRIMA di interrogare le righe
    // cambiate: se si scrivesse "adesso" dopo il push, una riga scritta
    // dall'utente nel mezzo della sync (stesso device) rischierebbe di
    // avere un updatedAt < watermark e non essere mai più pushata.
    final pushCutoff = DateTime.now();

    final pulledWatermarks = <DateTime?>[
      await _syncWallets(userId, pushSince, pullSince),
      await _syncCategories(pushSince, pullSince),
      await _syncTags(pushSince, pullSince),
      await _syncCustomFieldDefs(pushSince, pullSince),
      await _syncCostCenters(pushSince, pullSince),
      await _syncBudgets(pushSince, pullSince),
      await _syncRecurringRules(pushSince, pullSince),
      await _syncDashboardCards(pushSince, pullSince),
      await _syncTransactions(pushSince, pullSince),
      await _syncExpenseReports(pushSince, pullSince),
      await _syncTransactionTags(pushSince, pullSince),
      await _syncCustomFieldValues(pushSince, pullSince),
      await _syncExpenseReportEntries(pushSince, pullSince),
    ];
    final maxPulled = pulledWatermarks.nonNulls
        .followedBy([pullSince])
        .reduce((a, b) => a.isAfter(b) ? a : b);

    await _db
        .into(_db.syncStates)
        .insertOnConflictUpdate(
          SyncStatesCompanion.insert(
            userId: userId,
            lastPushedAt: pushCutoff,
            lastPulledAt: maxPulled,
          ),
        );
  }

  DateTime? _maxUpdatedAt(
    List<Map<String, dynamic>> rows,
    DateTime? current,
  ) {
    var max = current;
    for (final row in rows) {
      final updatedAt = DateTime.parse(row['updated_at'] as String);
      if (max == null || updatedAt.isAfter(max)) max = updatedAt;
    }
    return max;
  }

  // ---------------------------------------------------------------------
  // wallets — unica tabella che richiede owner_user_id in push (non è
  // una colonna del Drift locale, vedi M-ACC1: resta solo lato Postgres).
  // ---------------------------------------------------------------------
  Future<DateTime?> _syncWallets(
    String userId,
    DateTime pushSince,
    DateTime pullSince,
  ) async {
    final changed = await (_db.select(
      _db.wallets,
    )..where((t) => t.updatedAt.isBiggerThanValue(pushSince))).get();
    await _remote.upsert(
      'wallets',
      changed
          .map(
            (w) => {
              'id': w.id,
              'created_at': w.createdAt.toIso8601String(),
              'deleted_at': w.deletedAt?.toIso8601String(),
              'owner_user_id': userId,
              'name': w.name,
              'color_hex': w.colorHex,
              'icon': w.icon,
              'initial_balance_cents': w.initialBalanceCents,
              'archived_at': w.archivedAt?.toIso8601String(),
              'position': w.position,
              'currency': w.currency,
            },
          )
          .toList(),
    );

    final remote = await _remote.selectChangedSince('wallets', pullSince);
    for (final row in remote) {
      await _db
          .into(_db.wallets)
          .insertOnConflictUpdate(
            WalletsCompanion.insert(
              id: row['id'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
              deletedAt: Value(_parseNullableDate(row['deleted_at'])),
              name: row['name'] as String,
              colorHex: row['color_hex'] as String,
              icon: Value(row['icon'] as String),
              initialBalanceCents: Value(row['initial_balance_cents'] as int),
              archivedAt: Value(_parseNullableDate(row['archived_at'])),
              position: Value(row['position'] as int),
              currency: Value(row['currency'] as String),
            ),
          );
    }
    return _maxUpdatedAt(remote, null);
  }

  Future<DateTime?> _syncCategories(DateTime pushSince, DateTime pullSince) async {
    final changed = await (_db.select(
      _db.categories,
    )..where((t) => t.updatedAt.isBiggerThanValue(pushSince))).get();
    await _remote.upsert(
      'categories',
      changed
          .map(
            (c) => {
              'id': c.id,
              'created_at': c.createdAt.toIso8601String(),
              'deleted_at': c.deletedAt?.toIso8601String(),
              'wallet_id': c.walletId,
              'name': c.name,
              'icon': c.icon,
              'color_hex': c.colorHex,
              'kind': c.kind.name,
              'parent_id': c.parentId,
              'sort_order': c.sortOrder,
              'is_default': c.isDefault,
            },
          )
          .toList(),
    );

    final remote = await _remote.selectChangedSince('categories', pullSince);
    for (final row in remote) {
      await _db
          .into(_db.categories)
          .insertOnConflictUpdate(
            CategoriesCompanion.insert(
              id: row['id'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
              deletedAt: Value(_parseNullableDate(row['deleted_at'])),
              walletId: Value(row['wallet_id'] as String?),
              name: row['name'] as String,
              icon: row['icon'] as String,
              colorHex: row['color_hex'] as String,
              kind: CategoryKind.values.byName(row['kind'] as String),
              parentId: Value(row['parent_id'] as String?),
              sortOrder: Value(row['sort_order'] as int),
              isDefault: Value(row['is_default'] as bool),
            ),
          );
    }
    return _maxUpdatedAt(remote, null);
  }

  Future<DateTime?> _syncTags(DateTime pushSince, DateTime pullSince) async {
    final changed = await (_db.select(
      _db.tags,
    )..where((t) => t.updatedAt.isBiggerThanValue(pushSince))).get();
    await _remote.upsert(
      'tags',
      changed
          .map(
            (t) => {
              'id': t.id,
              'created_at': t.createdAt.toIso8601String(),
              'deleted_at': t.deletedAt?.toIso8601String(),
              'wallet_id': t.walletId,
              'name': t.name,
            },
          )
          .toList(),
    );

    final remote = await _remote.selectChangedSince('tags', pullSince);
    for (final row in remote) {
      await _db
          .into(_db.tags)
          .insertOnConflictUpdate(
            TagsCompanion.insert(
              id: row['id'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
              deletedAt: Value(_parseNullableDate(row['deleted_at'])),
              walletId: Value(row['wallet_id'] as String?),
              name: row['name'] as String,
            ),
          );
    }
    return _maxUpdatedAt(remote, null);
  }

  Future<DateTime?> _syncCustomFieldDefs(
    DateTime pushSince,
    DateTime pullSince,
  ) async {
    final changed = await (_db.select(
      _db.customFieldDefs,
    )..where((t) => t.updatedAt.isBiggerThanValue(pushSince))).get();
    await _remote.upsert(
      'custom_field_defs',
      changed
          .map(
            (f) => {
              'id': f.id,
              'created_at': f.createdAt.toIso8601String(),
              'deleted_at': f.deletedAt?.toIso8601String(),
              'wallet_id': f.walletId,
              'name': f.name,
              'type': f.type.name,
              'expense_report_only': f.expenseReportOnly,
              'options': f.options,
              'sort_order': f.sortOrder,
            },
          )
          .toList(),
    );

    final remote = await _remote.selectChangedSince('custom_field_defs', pullSince);
    for (final row in remote) {
      await _db
          .into(_db.customFieldDefs)
          .insertOnConflictUpdate(
            CustomFieldDefsCompanion.insert(
              id: row['id'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
              deletedAt: Value(_parseNullableDate(row['deleted_at'])),
              walletId: Value(row['wallet_id'] as String?),
              name: row['name'] as String,
              type: CustomFieldType.values.byName(row['type'] as String),
              expenseReportOnly: Value(row['expense_report_only'] as bool),
              options: Value(
                (row['options'] as List?)?.cast<String>(),
              ),
              sortOrder: Value(row['sort_order'] as int),
            ),
          );
    }
    return _maxUpdatedAt(remote, null);
  }

  Future<DateTime?> _syncCostCenters(
    DateTime pushSince,
    DateTime pullSince,
  ) async {
    final changed = await (_db.select(
      _db.costCenters,
    )..where((t) => t.updatedAt.isBiggerThanValue(pushSince))).get();
    await _remote.upsert(
      'cost_centers',
      changed
          .map(
            (c) => {
              'id': c.id,
              'created_at': c.createdAt.toIso8601String(),
              'deleted_at': c.deletedAt?.toIso8601String(),
              'wallet_id': c.walletId,
              'name': c.name,
            },
          )
          .toList(),
    );

    final remote = await _remote.selectChangedSince('cost_centers', pullSince);
    for (final row in remote) {
      await _db
          .into(_db.costCenters)
          .insertOnConflictUpdate(
            CostCentersCompanion.insert(
              id: row['id'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
              deletedAt: Value(_parseNullableDate(row['deleted_at'])),
              walletId: Value(row['wallet_id'] as String?),
              name: row['name'] as String,
            ),
          );
    }
    return _maxUpdatedAt(remote, null);
  }

  Future<DateTime?> _syncBudgets(DateTime pushSince, DateTime pullSince) async {
    final changed = await (_db.select(
      _db.budgets,
    )..where((t) => t.updatedAt.isBiggerThanValue(pushSince))).get();
    await _remote.upsert(
      'budgets',
      changed
          .map(
            (b) => {
              'id': b.id,
              'created_at': b.createdAt.toIso8601String(),
              'deleted_at': b.deletedAt?.toIso8601String(),
              'wallet_id': b.walletId,
              'category_id': b.categoryId,
              'limit_cents': b.limitCents,
            },
          )
          .toList(),
    );

    final remote = await _remote.selectChangedSince('budgets', pullSince);
    for (final row in remote) {
      await _db
          .into(_db.budgets)
          .insertOnConflictUpdate(
            BudgetsCompanion.insert(
              id: row['id'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
              deletedAt: Value(_parseNullableDate(row['deleted_at'])),
              walletId: Value(row['wallet_id'] as String?),
              categoryId: row['category_id'] as String,
              limitCents: row['limit_cents'] as int,
            ),
          );
    }
    return _maxUpdatedAt(remote, null);
  }

  Future<DateTime?> _syncRecurringRules(
    DateTime pushSince,
    DateTime pullSince,
  ) async {
    final changed = await (_db.select(
      _db.recurringRules,
    )..where((t) => t.updatedAt.isBiggerThanValue(pushSince))).get();
    await _remote.upsert(
      'recurring_rules',
      changed
          .map(
            (r) => {
              'id': r.id,
              'created_at': r.createdAt.toIso8601String(),
              'deleted_at': r.deletedAt?.toIso8601String(),
              'wallet_id': r.walletId,
              'category_id': r.categoryId,
              'type': r.type.name,
              'amount_cents': r.amountCents,
              'description': r.description,
              'frequency': r.frequency.name,
              'start_at': r.startAt.toIso8601String(),
              'next_run_at': r.nextRunAt.toIso8601String(),
              'end_at': r.endAt?.toIso8601String(),
              'paused_at': r.pausedAt?.toIso8601String(),
            },
          )
          .toList(),
    );

    final remote = await _remote.selectChangedSince('recurring_rules', pullSince);
    for (final row in remote) {
      await _db
          .into(_db.recurringRules)
          .insertOnConflictUpdate(
            RecurringRulesCompanion.insert(
              id: row['id'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
              deletedAt: Value(_parseNullableDate(row['deleted_at'])),
              walletId: row['wallet_id'] as String,
              categoryId: Value(row['category_id'] as String?),
              type: TransactionType.values.byName(row['type'] as String),
              amountCents: row['amount_cents'] as int,
              description: Value(row['description'] as String),
              frequency: RecurrenceFrequency.values.byName(
                row['frequency'] as String,
              ),
              startAt: DateTime.parse(row['start_at'] as String),
              nextRunAt: DateTime.parse(row['next_run_at'] as String),
              endAt: Value(_parseNullableDate(row['end_at'])),
              pausedAt: Value(_parseNullableDate(row['paused_at'])),
            ),
          );
    }
    return _maxUpdatedAt(remote, null);
  }

  Future<DateTime?> _syncDashboardCards(
    DateTime pushSince,
    DateTime pullSince,
  ) async {
    final changed = await (_db.select(
      _db.dashboardCards,
    )..where((t) => t.updatedAt.isBiggerThanValue(pushSince))).get();
    await _remote.upsert(
      'dashboard_cards',
      changed
          .map(
            (d) => {
              'id': d.id,
              'created_at': d.createdAt.toIso8601String(),
              'deleted_at': d.deletedAt?.toIso8601String(),
              'wallet_id': d.walletId,
              'type': d.type,
              'position': d.position,
              'config_json': jsonDecode(d.configJson),
            },
          )
          .toList(),
    );

    final remote = await _remote.selectChangedSince('dashboard_cards', pullSince);
    for (final row in remote) {
      await _db
          .into(_db.dashboardCards)
          .insertOnConflictUpdate(
            DashboardCardsCompanion.insert(
              id: row['id'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
              deletedAt: Value(_parseNullableDate(row['deleted_at'])),
              walletId: Value(row['wallet_id'] as String?),
              type: row['type'] as String,
              position: row['position'] as int,
              configJson: Value(jsonEncode(row['config_json'])),
            ),
          );
    }
    return _maxUpdatedAt(remote, null);
  }

  Future<DateTime?> _syncTransactions(
    DateTime pushSince,
    DateTime pullSince,
  ) async {
    final changed = await (_db.select(
      _db.transactions,
    )..where((t) => t.updatedAt.isBiggerThanValue(pushSince))).get();
    await _remote.upsert(
      'transactions',
      changed
          .map(
            (t) => {
              'id': t.id,
              'created_at': t.createdAt.toIso8601String(),
              'deleted_at': t.deletedAt?.toIso8601String(),
              'wallet_id': t.walletId,
              'type': t.type.name,
              'amount_cents': t.amountCents,
              'date': t.date.toIso8601String(),
              'wallet_to_id': t.walletToId,
              'category_id': t.categoryId,
              'description': t.description,
              'note': t.note,
              'entry_currency': t.entryCurrency,
              'entry_amount_cents': t.entryAmountCents,
              'amount_cents_to': t.amountCentsTo,
            },
          )
          .toList(),
    );

    final remote = await _remote.selectChangedSince('transactions', pullSince);
    for (final row in remote) {
      await _db
          .into(_db.transactions)
          .insertOnConflictUpdate(
            TransactionsCompanion.insert(
              id: row['id'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
              deletedAt: Value(_parseNullableDate(row['deleted_at'])),
              type: TransactionType.values.byName(row['type'] as String),
              amountCents: row['amount_cents'] as int,
              date: DateTime.parse(row['date'] as String),
              walletId: row['wallet_id'] as String,
              walletToId: Value(row['wallet_to_id'] as String?),
              categoryId: Value(row['category_id'] as String?),
              description: Value(row['description'] as String),
              note: Value(row['note'] as String?),
              entryCurrency: Value(row['entry_currency'] as String?),
              entryAmountCents: Value(row['entry_amount_cents'] as int?),
              amountCentsTo: Value(row['amount_cents_to'] as int?),
            ),
          );
    }
    return _maxUpdatedAt(remote, null);
  }

  Future<DateTime?> _syncExpenseReports(
    DateTime pushSince,
    DateTime pullSince,
  ) async {
    final changed = await (_db.select(
      _db.expenseReports,
    )..where((t) => t.updatedAt.isBiggerThanValue(pushSince))).get();
    await _remote.upsert(
      'expense_reports',
      changed
          .map(
            (r) => {
              'id': r.id,
              'created_at': r.createdAt.toIso8601String(),
              'deleted_at': r.deletedAt?.toIso8601String(),
              'wallet_id': r.walletId,
              'name': r.name,
              'date_from': r.dateFrom.toIso8601String(),
              'date_to': r.dateTo.toIso8601String(),
              'status': r.status.name,
              'reimburse_tx_id': r.reimburseTxId,
            },
          )
          .toList(),
    );

    final remote = await _remote.selectChangedSince('expense_reports', pullSince);
    for (final row in remote) {
      await _db
          .into(_db.expenseReports)
          .insertOnConflictUpdate(
            ExpenseReportsCompanion.insert(
              id: row['id'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              updatedAt: DateTime.parse(row['updated_at'] as String),
              deletedAt: Value(_parseNullableDate(row['deleted_at'])),
              walletId: Value(row['wallet_id'] as String?),
              name: row['name'] as String,
              dateFrom: DateTime.parse(row['date_from'] as String),
              dateTo: DateTime.parse(row['date_to'] as String),
              status: ExpenseReportStatus.values.byName(
                row['status'] as String,
              ),
              reimburseTxId: Value(row['reimburse_tx_id'] as String?),
            ),
          );
    }
    return _maxUpdatedAt(remote, null);
  }

  Future<DateTime?> _syncTransactionTags(
    DateTime pushSince,
    DateTime pullSince,
  ) async {
    // Nessuna colonna updatedAt propria (tabella di join, mai modificata
    // dopo la creazione — solo creata/cancellata): si usa createdAt come
    // watermark per il push.
    final changed = await (_db.select(
      _db.transactionTags,
    )..where((t) => t.createdAt.isBiggerThanValue(pushSince))).get();
    await _remote.upsert(
      'transaction_tags',
      changed
          .map(
            (t) => {
              'transaction_id': t.transactionId,
              'tag_id': t.tagId,
              'created_at': t.createdAt.toIso8601String(),
            },
          )
          .toList(),
    );

    final remote = await _remote.selectChangedSince(
      'transaction_tags',
      pullSince,
      column: 'created_at',
    );
    for (final row in remote) {
      await _db
          .into(_db.transactionTags)
          .insertOnConflictUpdate(
            TransactionTagsCompanion.insert(
              transactionId: row['transaction_id'] as String,
              tagId: row['tag_id'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
            ),
          );
    }
    DateTime? max;
    for (final row in remote) {
      final createdAt = DateTime.parse(row['created_at'] as String);
      if (max == null || createdAt.isAfter(max)) max = createdAt;
    }
    return max;
  }

  Future<DateTime?> _syncCustomFieldValues(
    DateTime pushSince,
    DateTime pullSince,
  ) async {
    final changed = await (_db.select(
      _db.customFieldValues,
    )..where((t) => t.updatedAt.isBiggerThanValue(pushSince))).get();
    await _remote.upsert(
      'custom_field_values',
      changed
          .map(
            (v) => {
              'transaction_id': v.transactionId,
              'field_id': v.fieldId,
              'value': v.value,
              'updated_at': v.updatedAt.toIso8601String(),
            },
          )
          .toList(),
    );

    final remote = await _remote.selectChangedSince('custom_field_values', pullSince);
    for (final row in remote) {
      await _db
          .into(_db.customFieldValues)
          .insertOnConflictUpdate(
            CustomFieldValuesCompanion.insert(
              transactionId: row['transaction_id'] as String,
              fieldId: row['field_id'] as String,
              value: row['value'] as String,
              updatedAt: DateTime.parse(row['updated_at'] as String),
            ),
          );
    }
    return _maxUpdatedAt(remote, null);
  }

  Future<DateTime?> _syncExpenseReportEntries(
    DateTime pushSince,
    DateTime pullSince,
  ) async {
    final changed = await (_db.select(
      _db.expenseReportEntries,
    )..where((t) => t.updatedAt.isBiggerThanValue(pushSince))).get();
    await _remote.upsert(
      'expense_report_entries',
      changed
          .map(
            (e) => {
              'transaction_id': e.transactionId,
              'cost_center_id': e.costCenterId,
              'reimbursable': e.reimbursable,
              'e_invoice': e.eInvoice,
              'report_id': e.reportId,
              'updated_at': e.updatedAt.toIso8601String(),
            },
          )
          .toList(),
    );

    final remote = await _remote.selectChangedSince('expense_report_entries', pullSince);
    for (final row in remote) {
      await _db
          .into(_db.expenseReportEntries)
          .insertOnConflictUpdate(
            ExpenseReportEntriesCompanion.insert(
              transactionId: row['transaction_id'] as String,
              costCenterId: Value(row['cost_center_id'] as String?),
              reimbursable: Value(row['reimbursable'] as bool),
              eInvoice: Value(row['e_invoice'] as bool),
              reportId: Value(row['report_id'] as String?),
              updatedAt: DateTime.parse(row['updated_at'] as String),
            ),
          );
    }
    return _maxUpdatedAt(remote, null);
  }

  DateTime? _parseNullableDate(Object? value) =>
      value == null ? null : DateTime.parse(value as String);
}
