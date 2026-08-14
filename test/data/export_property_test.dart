import 'dart:math';

import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/export/json_codec.dart';
import 'package:nipay/data/repositories/transaction_repository.dart';
import 'package:nipay/data/repositories/wallet_repository.dart';

import '../support/property.dart';

/// Pool di caratteri "scomodi" per i nomi generati: unicode multibyte,
/// emoji, apostrofi, spazi multipli — casi che una libreria JSON o un
/// encoding sbagliato potrebbero corrompere silenziosamente.
const _namePool = [
  'Conto', 'Viaggio 🏖️', "Casa dell'amico", 'Café ☕',
  '现金', 'Épargne', 'Wüste Reise', '  spazi  ', 'Ω budget', 'a',
];

String _randomName(Random random) =>
    _namePool[random.nextInt(_namePool.length)];

/// Popola un DB con N portafogli e M transazioni casuali per ciascuno,
/// tutte le combinazioni segno/importo generate a caso.
Future<AppDatabase> _seedRandom(Random random) async {
  final db = AppDatabase(NativeDatabase.memory());
  final wallets = DriftWalletRepository(db);
  final txs = DriftTransactionRepository(db);

  final walletCount = 1 + random.nextInt(4);
  for (var w = 0; w < walletCount; w++) {
    final walletId = await wallets.create(
      name: '${_randomName(random)} $w',
      colorHex: '#0E7C86',
      initialBalanceCents: randomInt(random, -100000, 500000),
    );
    final txCount = random.nextInt(8);
    for (var t = 0; t < txCount; t++) {
      final amount = randomInt(random, 1, 999999);
      final date = DateTime(2026, 1 + random.nextInt(12), 1 + random.nextInt(28));
      if (random.nextBool()) {
        await txs.createExpense(
          walletId: walletId,
          amountCents: amount,
          date: date,
          description: _randomName(random),
        );
      } else {
        await txs.createIncome(
          walletId: walletId,
          amountCents: amount,
          date: date,
          description: _randomName(random),
        );
      }
    }
  }
  return db;
}

void main() {
  driftRuntimeOptions.defaultSerializer = const ValueSerializer.defaults(
    serializeDateTimeValuesAsString: true,
  );
  // Il test crea intenzionalmente molti AppDatabase in loop (uno per trial):
  // il warning di drift sulla "creazione multipla" è un falso positivo qui.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;

  // Proprietà: per QUALUNQUE combinazione di portafogli/transazioni generata
  // a caso (nomi con caratteri unicode, importi ai limiti), un
  // export→import globale deve ricostruire lo stesso numero di righe e,
  // soprattutto, lo stesso saldo per portafoglio (ricalcolato da zero sul DB
  // di destinazione, non copiato) — l'unica cosa che conta davvero per
  // l'utente in un restore.
  forAll(
    'JSON export/import round-trip preserves wallet balances and counts',
    (random) => random,
    (random) async {
      final source = await _seedRandom(random);
      final sourceTxRepo = DriftTransactionRepository(source);
      final sourceWallets = await source.select(source.wallets).get();
      final sourceBalances = {
        for (final w in sourceWallets) w.id: await sourceTxRepo.balanceOf(w.id),
      };
      final sourceTxCount = (await source.select(source.transactions).get())
          .length;

      final json = await exportToJson(source);
      final target = AppDatabase(NativeDatabase.memory());
      await importFromJson(target, json);

      final targetWallets = await target.select(target.wallets).get();
      final targetTxCount = (await target.select(target.transactions).get())
          .length;
      final targetTxRepo = DriftTransactionRepository(target);

      if (targetWallets.length != sourceWallets.length) {
        throw StateError(
          'wallet count: atteso ${sourceWallets.length}, '
          'ottenuto ${targetWallets.length}',
        );
      }
      if (targetTxCount != sourceTxCount) {
        throw StateError(
          'transaction count: atteso $sourceTxCount, ottenuto $targetTxCount',
        );
      }
      for (final w in targetWallets) {
        final expected = sourceBalances[w.id];
        final actual = await targetTxRepo.balanceOf(w.id);
        if (actual != expected) {
          await source.close();
          await target.close();
          throw StateError(
            'saldo portafoglio ${w.id} ("${w.name}"): '
            'atteso $expected, ottenuto $actual',
          );
        }
      }

      await source.close();
      await target.close();
    },
    trials: 30,
  );
}
