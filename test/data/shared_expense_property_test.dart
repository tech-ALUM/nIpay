import 'dart:math';

import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/core/split_accounting.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/repositories/transaction_repository.dart';
import 'package:nipay/data/repositories/wallet_repository.dart';

import '../support/property.dart';

/// Proprietà del modello contabile delle spese divise (M-SOC4): ogni
/// partecipante ha il suo portafoglio (come su dispositivi diversi) e
/// registra quote e rimborsi con [movementsForShare]. Per qualunque
/// sequenza casuale di spese (chi paga, quote uguali o personalizzate) e
/// rimborsi devono valere:
/// 1. il saldo di ogni portafoglio = soldi davvero usciti/entrati;
/// 2. le spese di ognuno (statistiche, budget) = solo le sue quote;
/// 3. i movimenti "con amici" di tutti si annullano;
/// 4. per ognuno corrispondono al saldo verso gli altri calcolato come fa
///    il server (friend_balances): quanto gli devono meno quanto deve.
void main() {
  forAll(
    'shared expenses and settlements keep every wallet balance real and the '
    'friend balances zero-sum',
    (random) => random,
    (Random random) async {
      final db = AppDatabase(NativeDatabase.memory());
      final wallets = DriftWalletRepository(db);
      final txs = DriftTransactionRepository(db);
      final people = randomInt(random, 2, 5);
      final walletOf = <String>[];
      final cash = <int>[]; // soldi del portafoglio, modello indipendente
      final shareSum = List.filled(people, 0);
      // owes[i][j]: quanto i deve a j (modello del server).
      final owes = List.generate(people, (_) => List.filled(people, 0));
      for (var i = 0; i < people; i++) {
        final initial = randomInt(random, 0, 200000);
        walletOf.add(
          await wallets.create(
            name: 'P$i',
            colorHex: '#0E7C86',
            initialBalanceCents: initial,
          ),
        );
        cash.add(initial);
      }
      final date = DateTime(2026, 10, 15);

      final ops = randomInt(random, 1, 15);
      for (var op = 0; op < ops; op++) {
        final settle = op > 0 && random.nextInt(4) == 0;
        if (settle) {
          final from = random.nextInt(people);
          final to = (from + 1 + random.nextInt(people - 1)) % people;
          final amount = randomInt(random, 1, 20000);
          await txs.createFriendMovement(
            walletId: walletOf[from],
            amountCents: amount,
            date: date,
            outgoing: true,
          );
          await txs.createFriendMovement(
            walletId: walletOf[to],
            amountCents: amount,
            date: date,
            outgoing: false,
          );
          cash[from] -= amount;
          cash[to] += amount;
          owes[from][to] -= amount;
          continue;
        }

        // Spesa divisa tra un sottoinsieme (almeno due persone).
        final members = [for (var i = 0; i < people; i++) i]..shuffle(random);
        final group = members.take(randomInt(random, 2, people)).toList();
        final total = randomInt(random, group.length, 100000);
        final List<int> shares;
        if (random.nextBool()) {
          shares = splitEqually(total, group.length);
        } else {
          // Personalizzate: ognuno almeno 1 centesimo, il resto a caso.
          final rest = List.filled(group.length, 1);
          for (var c = 0; c < total - group.length; c++) {
            rest[random.nextInt(group.length)]++;
          }
          shares = rest;
        }
        final payer = group[random.nextInt(group.length)];
        cash[payer] -= total;
        for (var k = 0; k < group.length; k++) {
          final p = group[k];
          final m = movementsForShare(
            iPaid: p == payer,
            totalCents: total,
            myShareCents: shares[k],
          );
          await txs.createExpense(
            walletId: walletOf[p],
            amountCents: m.expenseCents,
            date: date,
          );
          if (m.friendOutCents > 0) {
            await txs.createFriendMovement(
              walletId: walletOf[p],
              amountCents: m.friendOutCents,
              date: date,
              outgoing: true,
            );
          }
          if (m.friendInCents > 0) {
            await txs.createFriendMovement(
              walletId: walletOf[p],
              amountCents: m.friendInCents,
              date: date,
              outgoing: false,
            );
          }
          shareSum[p] += shares[k];
          if (p != payer) owes[p][payer] += shares[k];
        }
      }

      var friendTotal = 0;
      for (var i = 0; i < people; i++) {
        // 1. Saldo reale.
        expect(await txs.balanceOf(walletOf[i]), cash[i], reason: 'saldo P$i');
        // 2. Solo le quote come spese.
        final totals = await txs.totalsForPeriod(
          from: DateTime(2026, 10),
          to: DateTime(2026, 11),
          walletId: walletOf[i],
        );
        expect(totals.expenseCents, shareSum[i], reason: 'spese P$i');
        expect(totals.incomeCents, 0, reason: 'entrate P$i');
        // 3–4. Movimenti con amici.
        final rows =
            await (db.select(db.transactions)..where(
                  (t) =>
                      t.walletId.equals(walletOf[i]) &
                      t.type.isIn([
                        TransactionType.friendOut.name,
                        TransactionType.friendIn.name,
                      ]),
                ))
                .get();
        final friendNet = rows.fold(
          0,
          (sum, t) =>
              sum +
              (t.type == TransactionType.friendIn
                  ? t.amountCents
                  : -t.amountCents),
        );
        friendTotal += friendNet;
        var serverBalance = 0; // quanto gli altri devono a i
        for (var j = 0; j < people; j++) {
          if (j == i) continue;
          serverBalance += owes[j][i] - owes[i][j];
        }
        expect(friendNet, -serverBalance, reason: 'con amici P$i');
      }
      expect(friendTotal, 0, reason: 'i movimenti con amici si annullano');

      await db.close();
    },
    trials: 60,
  );
}
