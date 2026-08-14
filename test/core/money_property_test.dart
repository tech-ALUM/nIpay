import 'package:nipay/core/money.dart';

import '../support/property.dart';

const _typographicMinus = '−';
const _nbsp = ' ';

void main() {
  // Round-trip: un input "pulito" (segno + parte intera + separatore + 2
  // cifre decimali, senza raggruppamento delle migliaia) deve sempre
  // riprodurre esattamente i centesimi che rappresenta. È l'invariante che
  // ha già tradito il codice una volta (bug 12.00 → 1200,00€): qui lo
  // verifichiamo su centinaia di input generati invece che su 3 casi fissi.
  forAll('parseCents recovers exact cents from clean user input', (random) {
    final negative = random.nextBool();
    final intDigits = 1 + random.nextInt(6);
    final intPart = List.generate(
      intDigits,
      (i) => i == 0 ? (1 + random.nextInt(9)) : random.nextInt(10),
    ).join();
    final decValue = randomInt(random, 0, 99);
    final sep = random.nextBool() ? ',' : '.';
    return (
      input: '${negative ? '-' : ''}$intPart$sep${decValue.toString().padLeft(2, '0')}',
      expectedCents: (negative ? -1 : 1) * (int.parse(intPart) * 100 + decValue),
    );
  }, (v) {
    final result = parseCents(v.input);
    if (result != v.expectedCents) {
      throw StateError(
        'parseCents(${v.input}) = $result, atteso ${v.expectedCents}',
      );
    }
  });

  forAll('parseCents rejects non-numeric garbage', (random) {
    final letters = 'abcdefghijklmnopqrstuvwxyz';
    final len = 1 + random.nextInt(10);
    return List.generate(len, (_) => letters[random.nextInt(letters.length)])
        .join();
  }, (garbage) {
    if (parseCents(garbage) != null) {
      throw StateError('parseCents("$garbage") atteso null, ottenuto valore');
    }
  });

  forAll('parseCents rejects blank input', (random) {
    return ' ' * random.nextInt(5);
  }, (blank) {
    if (parseCents(blank) != null) {
      throw StateError('parseCents("$blank") atteso null, ottenuto valore');
    }
  });

  // formatCents: proprietà strutturali che devono valere per qualunque
  // importo e valuta, non solo per gli esempi fissi già coperti altrove.
  forAll('formatCents always has exactly 2 decimal digits after the comma', (
    random,
  ) {
    return randomInt(random, -50000000, 50000000);
  }, (cents) {
    final out = formatCents(cents);
    final commaIndex = out.indexOf(',');
    if (commaIndex == -1) {
      throw StateError('formatCents($cents) = "$out" senza virgola decimale');
    }
    final decPart = out.substring(commaIndex + 1, commaIndex + 3);
    if (!RegExp(r'^\d{2}$').hasMatch(decPart)) {
      throw StateError(
        'formatCents($cents) = "$out" non ha 2 cifre decimali esatte',
      );
    }
  });

  forAll('formatCents sign matches cents sign', (random) {
    return randomInt(random, -50000000, 50000000);
  }, (cents) {
    final out = formatCents(cents);
    final startsWithMinus = out.startsWith(_typographicMinus);
    if (cents < 0 && !startsWithMinus) {
      throw StateError('formatCents($cents) = "$out" atteso segno negativo');
    }
    if (cents >= 0 && startsWithMinus) {
      throw StateError(
        'formatCents($cents) = "$out" non atteso segno negativo',
      );
    }
  });

  forAll('formatCents shows ISO code for non-EUR, symbol for EUR', (
    random,
  ) {
    final currencies = ['EUR', 'USD', 'GBP', 'CHF', 'CNY'];
    return (
      cents: randomInt(random, -1000000, 1000000),
      currency: currencies[random.nextInt(currencies.length)],
    );
  }, (v) {
    final out = formatCents(v.cents, currency: v.currency);
    final expectedSuffix = v.currency == 'EUR' ? '€' : v.currency;
    if (!out.endsWith('$_nbsp$expectedSuffix')) {
      throw StateError(
        'formatCents(${v.cents}, currency: ${v.currency}) = "$out" '
        'atteso suffisso "$_nbsp$expectedSuffix"',
      );
    }
  });
}
