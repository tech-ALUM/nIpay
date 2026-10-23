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
}
