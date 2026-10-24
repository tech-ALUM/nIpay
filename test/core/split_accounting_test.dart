import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/core/split_accounting.dart';

import '../support/property.dart';

void main() {
  test('the dinner of the plan: A pays 60 € for A, B, C', () {
    expect(
      movementsForShare(iPaid: true, totalCents: 6000, myShareCents: 2000),
      (expenseCents: 2000, friendOutCents: 4000, friendInCents: 0),
    );
    expect(
      movementsForShare(iPaid: false, totalCents: 6000, myShareCents: 2000),
      (expenseCents: 2000, friendOutCents: 0, friendInCents: 2000),
    );
  });

  test('equal split hands the leftover cents to the first people', () {
    expect(splitEqually(1000, 3), [334, 333, 333]);
    expect(splitEqually(6000, 3), [2000, 2000, 2000]);
    expect(splitEqually(1, 2), [1, 0]);
  });

  forAll(
    'equal split always adds up to the total and differs by at most a cent',
    (random) => (randomInt(random, 0, 10000000), randomInt(random, 1, 50)),
    (input) {
      final (total, people) = input;
      final shares = splitEqually(total, people);
      expect(shares, hasLength(people));
      expect(shares.fold(0, (a, b) => a + b), total);
      expect(
        shares.reduce((a, b) => a > b ? a : b) -
            shares.reduce((a, b) => a < b ? a : b),
        lessThanOrEqualTo(1),
      );
      expect(shares.every((s) => s >= 0), isTrue);
    },
  );

  test('a split typed in another currency keeps the wallet total exact', () {
    // 60 USD → 30,01 € nel portafoglio: la quota di 20 USD diventa 10,00 €,
    // l'anticipo il resto (20,01 €), non 2 × 10,00 €.
    final paid = convertShareMovements(
      movementsForShare(iPaid: true, totalCents: 6000, myShareCents: 2000),
      entryTotalCents: 6000,
      walletTotalCents: 3001,
    );
    expect(paid, (expenseCents: 1000, friendOutCents: 2001, friendInCents: 0));
    expect(paid.expenseCents + paid.friendOutCents, 3001);

    final owed = convertShareMovements(
      movementsForShare(iPaid: false, totalCents: 6000, myShareCents: 2000),
      entryTotalCents: 6000,
      walletTotalCents: 3001,
    );
    expect(owed, (expenseCents: 1000, friendOutCents: 0, friendInCents: 1000));
  });

  test('custom shares must be positive and add up to the total', () {
    expect(
      resolveShares(
        totalCents: 1000,
        participants: ['me', 'bea'],
        custom: {'me': 600, 'bea': 400},
      ).shares,
      [600, 400],
    );
    expect(
      resolveShares(
        totalCents: 1000,
        participants: ['me', 'bea'],
        custom: {'me': 600, 'bea': 300},
      ).error,
      SplitError.mismatch,
    );
    expect(
      resolveShares(
        totalCents: 1000,
        participants: ['me', 'bea'],
        custom: {'me': 1000},
      ).error,
      SplitError.mismatch,
    );
    expect(
      resolveShares(totalCents: 1, participants: ['me', 'bea']).error,
      SplitError.tooSmall,
    );
  });
}
