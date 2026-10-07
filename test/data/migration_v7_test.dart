import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';

/// Migrazione del DB locale v6 → v7 (sync robusta, SECURITY_AUDIT NIP-01..04,
/// NIP-15) a partire dallo schema v6 ESATTO (dump del codice al commit
/// dc9594a, `fixtures/schema_v6.sql`).
AppDatabase _openV6(void Function(void Function(String sql) exec) seed) =>
    AppDatabase(
      NativeDatabase.memory(
        setup: (raw) {
          if (raw.userVersion != 0) return;
          final schema = File(
            'test/data/fixtures/schema_v6.sql',
          ).readAsStringSync();
          for (final statement in schema.split(';\n')) {
            if (statement.trim().isNotEmpty) raw.execute(statement);
          }
          seed(raw.execute);
          raw.userVersion = 6;
        },
      ),
    );

const _old = '2026-01-01T10:00:00.000Z';
const _lastPush = '2026-06-01T10:00:00.000Z';
const _recent = '2026-09-01T10:00:00.000Z';

void _seed(void Function(String sql) exec, {bool synced = true}) {
  exec(
    "INSERT INTO wallets (id, created_at, updated_at, name, color_hex) VALUES "
    "('w-old', '$_old', '$_old', 'Vecchio', '#000000'), "
    "('w-new', '$_old', '$_recent', 'Nuovo', '#000000')",
  );
  exec(
    "INSERT INTO categories (id, created_at, updated_at, wallet_id, name, icon, color_hex, kind) "
    "VALUES ('c1', '$_old', '$_old', 'w-old', 'Spesa', 'x', '#000000', 'expense')",
  );
  exec(
    "INSERT INTO transactions (id, created_at, updated_at, type, amount_cents, date, wallet_id) "
    "VALUES ('tx1', '$_old', '$_old', 'expense', 100, '$_old', 'w-old')",
  );
  exec(
    "INSERT INTO tags (id, created_at, updated_at, wallet_id, name) "
    "VALUES ('t1', '$_old', '$_old', 'w-old', 'lavoro')",
  );
  exec(
    "INSERT INTO transaction_tags (transaction_id, tag_id, created_at) "
    "VALUES ('tx1', 't1', '$_recent')",
  );
  exec(
    "INSERT INTO budgets (id, created_at, updated_at, deleted_at, wallet_id, category_id, limit_cents) "
    "VALUES ('b1', '$_old', '$_old', NULL, 'w-old', 'c1', 500)",
  );
  exec(
    "INSERT INTO expense_report_entries (transaction_id, reimbursable, e_invoice, updated_at) "
    "VALUES ('tx1', 1, 0, '$_old')",
  );
  if (synced) {
    exec(
      "INSERT INTO sync_states (user_id, last_pushed_at, last_pulled_at) "
      "VALUES ('user-1', '$_lastPush', '$_lastPush')",
    );
  }
}

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('v6 → v7 keeps the data and queues only the rows changed after the '
      'last push', () async {
    final db = _openV6(_seed);
    addTearDown(db.close);

    expect(await db.select(db.wallets).get(), hasLength(2));
    final queued = {
      for (final o in await db.select(db.syncOutbox).get())
        '${o.syncTable}:${o.rowKey}',
    };
    expect(queued, {'wallets:w-new', 'transaction_tags:tx1|t1'});

    final link = await db.select(db.transactionTags).getSingle();
    expect(link.updatedAt, DateTime.parse(_recent), reason: '= createdAt');
    expect(link.deletedAt, isNull);
    expect(
      (await db.select(db.expenseReportEntries).getSingle()).deletedAt,
      isNull,
    );

    final state = await db.select(db.syncStates).getSingle();
    expect(state.userId, 'user-1');
    expect(state.pendingIssues, 0);
    expect(
      await db.select(db.syncCursors).get(),
      isEmpty,
      reason:
          'watermark per tabella da zero: un pull completo ripara '
          'eventuali righe perse dal vecchio motore',
    );
  });

  test('v6 → v7 on a never-synced device queues everything for the first '
      'login', () async {
    final db = _openV6((exec) => _seed(exec, synced: false));
    addTearDown(db.close);

    final queued = await db.select(db.syncOutbox).get();
    // 2 wallet, 1 categoria, 1 transazione, 1 tag, 1 link, 1 budget, 1 voce
    expect(queued, hasLength(8));
  });

  test('after v7 every write is queued by the triggers', () async {
    final db = _openV6(_seed);
    addTearDown(db.close);
    await db.delete(db.syncOutbox).go();

    await (db.update(db.transactions)..where((t) => t.id.equals('tx1'))).write(
      TransactionsCompanion(
        amountCents: const Value(200),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await db
        .into(db.costCenters)
        .insert(
          CostCentersCompanion.insert(
            id: 'cc1',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            walletId: const Value('w-old'),
            name: 'Cliente',
          ),
        );
    final queued = {
      for (final o in await db.select(db.syncOutbox).get())
        '${o.syncTable}:${o.rowKey}',
    };
    expect(queued, {'transactions:tx1', 'cost_centers:cc1'});
  });

  test('after v7 a category can have a new live budget once the old one is '
      'soft-deleted (no more global UNIQUE)', () async {
    final db = _openV6(_seed);
    addTearDown(db.close);

    Future<void> insertBudget(String id) => db
        .into(db.budgets)
        .insert(
          BudgetsCompanion.insert(
            id: id,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            walletId: const Value('w-old'),
            categoryId: 'c1',
            limitCents: 1,
          ),
        );

    await expectLater(
      insertBudget('b2'),
      throwsA(isA<SqliteException>()),
      reason: 'un solo budget vivo per categoria',
    );
    await (db.update(db.budgets)..where((t) => t.id.equals('b1'))).write(
      BudgetsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    await insertBudget('b2');
    expect(await db.select(db.budgets).get(), hasLength(2));
  });
}
