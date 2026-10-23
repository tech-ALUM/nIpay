import 'dart:io';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/repositories/transaction_repository.dart';

/// Migrazione del DB locale v7 → v8 (spese divise, M-SOC4) a partire dallo
/// schema v7 ESATTO (codice al commit fd57cb0, `fixtures/schema_v7.sql`,
/// trigger di sync compresi).
AppDatabase _openV7() => AppDatabase(
  NativeDatabase.memory(
    setup: (raw) {
      if (raw.userVersion != 0) return;
      // Un solo execute: i corpi dei trigger contengono ";".
      raw.execute(File('test/data/fixtures/schema_v7.sql').readAsStringSync());
      const at = '2026-10-01T10:00:00.000Z';
      raw.execute(
        "INSERT INTO wallets (id, created_at, updated_at, name, color_hex, "
        "initial_balance_cents) VALUES ('w1', '$at', '$at', 'Casa', "
        "'#000000', 10000)",
      );
      raw.execute(
        "INSERT INTO transactions (id, created_at, updated_at, type, "
        "amount_cents, date, wallet_id) VALUES ('tx1', '$at', '$at', "
        "'expense', 2500, '$at', 'w1')",
      );
      raw.userVersion = 7;
    },
  ),
);

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  test('v7 → v8 keeps the data; old rows have no shared expense', () async {
    final db = _openV7();
    addTearDown(db.close);

    final tx = await (db.select(
      db.transactions,
    )..where((t) => t.id.equals('tx1'))).getSingle();
    expect(tx.type, TransactionType.expense);
    expect(tx.amountCents, 2500);
    expect(tx.sharedExpenseId, isNull);
    expect(await DriftTransactionRepository(db).balanceOf('w1'), 7500);
  });

  test(
    'after v8 friend movements are saved, linked and queued for sync',
    () async {
      final db = _openV7();
      addTearDown(db.close);
      final repo = DriftTransactionRepository(db);

      final out = await repo.createFriendMovement(
        walletId: 'w1',
        amountCents: 4000,
        date: DateTime.utc(2026, 10, 23),
        outgoing: true,
        sharedExpenseId: 'se-1',
      );
      final saved = await (db.select(
        db.transactions,
      )..where((t) => t.id.equals(out))).getSingle();
      expect(saved.type, TransactionType.friendOut);
      expect(saved.sharedExpenseId, 'se-1');

      final queued = await db
          .customSelect(
            "SELECT COUNT(*) AS n FROM sync_outbox "
            "WHERE sync_table = 'transactions' AND row_key = ?",
            variables: [Variable.withString(out)],
          )
          .getSingle();
      expect(queued.read<int>('n'), 1);
    },
  );
}
