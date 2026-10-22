import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/core/validation.dart';

void main() {
  group('normalizeDisplayName (stesse regole di set_display_name)', () {
    test('toglie gli spazi ai bordi', () {
      expect(normalizeDisplayName('  Anna Rossi  '), 'Anna Rossi');
    });

    test('rifiuta un nome vuoto o fatto solo di spazi', () {
      expect(normalizeDisplayName(''), isNull);
      expect(normalizeDisplayName('    '), isNull);
    });

    test('accetta 40 caratteri, rifiuta il 41°', () {
      expect(normalizeDisplayName('x' * 40), 'x' * 40);
      expect(normalizeDisplayName('x' * 41), isNull);
    });

    test('conta i caratteri come Postgres, non le unità UTF-16', () {
      // Ogni emoji vale 2 unità UTF-16 ma 1 carattere per char_length.
      expect(normalizeDisplayName('😀' * 40), '😀' * 40);
      expect(normalizeDisplayName('😀' * 41), isNull);
    });

    test('rifiuta caratteri di controllo', () {
      expect(normalizeDisplayName('Anna\nRossi'), isNull);
      expect(normalizeDisplayName('Anna\tRossi'), isNull);
      expect(normalizeDisplayName('Anna\u0000'), isNull);
    });

    test('accetta accenti e alfabeti non latini', () {
      expect(normalizeDisplayName('Àñnä 李'), 'Àñnä 李');
      expect(normalizeDisplayName('محمد'), 'محمد');
    });
  });
}
