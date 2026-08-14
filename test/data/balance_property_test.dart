import 'package:drift/native.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/repositories/transaction_repository.dart';
import 'package:nipay/data/repositories/wallet_repository.dart';

import '../support/property.dart';

/// Proprietà: qualunque sequenza casuale di spese/entrate/trasferimenti
/// (anche cross-valuta) deve produrre, per OGNI portafoglio coinvolto, un
/// saldo identico a quello calcolato da un modello indipendente e banale
/// (somma in Dart puro), non solo alla query SQL di `balanceOf` — se la
/// query e il modello divergono su un caso generato a caso, è un bug reale.
void main() {
  forAll(
    'balanceOf matches an independent plain-Dart model after a random sequence of operations',
    (random) => random,
    (random) async {
      final db = AppDatabase(NativeDatabase.memory());
      final wallets = DriftWalletRepository(db);
      final txs = DriftTransactionRepository(db);

      final walletCount = 2 + random.nextInt(2); // 2 o 3 portafogli
      final walletIds = <String>[];
      final model = <String, int>{};
      for (var i = 0; i < walletCount; i++) {
        final initial = randomInt(random, -50000, 500000);
        final id = await wallets.create(
          name: 'W$i',
          colorHex: '#0E7C86',
          initialBalanceCents: initial,
        );
        walletIds.add(id);
        model[id] = initial;
      }

      final opCount = 1 + random.nextInt(20);
      for (var i = 0; i < opCount; i++) {
        final walletId = walletIds[random.nextInt(walletIds.length)];
        final amount = randomInt(random, 1, 100000);
        final date = DateTime(2026, 1 + random.nextInt(12), 1 + random.nextInt(28));

        switch (random.nextInt(3)) {
          case 0: // expense
            await txs.createExpense(
              walletId: walletId,
              amountCents: amount,
              date: date,
            );
            model[walletId] = model[walletId]! - amount;
          case 1: // income
            await txs.createIncome(
              walletId: walletId,
              amountCents: amount,
              date: date,
            );
            model[walletId] = model[walletId]! + amount;
          default: // transfer, eventualmente cross-valuta
            final toId = walletIds[random.nextInt(walletIds.length)];
            if (toId == walletId) continue;
            final crediting = random.nextBool()
                ? amount // stessa valuta: nessuna conversione
                : randomInt(random, 1, 100000); // valuta diversa: importo diverso
            await txs.createTransfer(
              fromWalletId: walletId,
              toWalletId: toId,
              amountCents: amount,
              date: date,
              amountCentsTo: crediting == amount ? null : crediting,
            );
            model[walletId] = model[walletId]! - amount;
            model[toId] = model[toId]! + crediting;
        }
      }

      for (final id in walletIds) {
        final actual = await txs.balanceOf(id);
        final expected = model[id];
        if (actual != expected) {
          await db.close();
          throw StateError(
            'balanceOf($id) = $actual, modello atteso $expected',
          );
        }
      }
      await db.close();
    },
    trials: 50,
  );
}
