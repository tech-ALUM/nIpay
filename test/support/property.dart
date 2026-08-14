/// Piccolo harness di property-based testing, senza dipendenze esterne.
///
/// Le librerie sul mercato (glados: non supporta Dart 3; kiri_check: confligge
/// con l'`analyzer` richiesto da drift_dev; le alternative compatibili hanno
/// pochissima adozione) non erano una scelta solida per questo progetto — da
/// qui l'harness minimale: genera N input casuali (seed fisso e riportato per
/// riprodurre un fallimento) e verifica che la proprietà valga su tutti.
library;

import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

void forAll<T>(
  String description,
  T Function(Random random) generate,
  FutureOr<void> Function(T value) check, {
  int trials = 200,
  int seed = 42,
}) {
  test(description, () async {
    final random = Random(seed);
    for (var i = 0; i < trials; i++) {
      final value = generate(random);
      try {
        await check(value);
      } catch (e) {
        fail(
          'Proprietà fallita al trial $i/$trials (seed: $seed)\n'
          'Input: $value\n'
          'Errore: $e',
        );
      }
    }
  });
}

/// Intero casuale in [min, max] (inclusi).
int randomInt(Random random, int min, int max) =>
    min + random.nextInt(max - min + 1);

/// Stringa numerica "sporca" in stile utente: cifre con un separatore
/// decimale (`,` o `.`) casuale, eventuale segno meno, eventuali spazi
/// attorno — lo stesso genere di input che ha già causato un bug reale
/// in [parseCents] (12.00 interpretato come migliaia invece che decimali).
String randomMoneyInput(Random random, {int maxIntDigits = 6}) {
  final intDigits = 1 + random.nextInt(maxIntDigits);
  final intPart = List.generate(
    intDigits,
    (i) => i == 0 ? (1 + random.nextInt(9)) : random.nextInt(10),
  ).join();
  final decPart = randomInt(random, 0, 99).toString().padLeft(2, '0');
  final sep = random.nextBool() ? ',' : '.';
  final negative = random.nextBool();
  return '${negative ? '-' : ''}$intPart$sep$decPart';
}
