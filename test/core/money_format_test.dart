import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/core/money.dart';

void main() {
  test('formats cents as euro (it locale, comma decimals)', () {
    expect(formatCents(0), '0,00 €');
    expect(formatCents(4250), '42,50 €');
    expect(formatCents(284730), '2.847,30 €');
  });

  test('formats negative and signed amounts', () {
    expect(formatCents(-4250), '−42,50 €');
    expect(formatCents(185000, signed: true), '+1.850,00 €');
  });

  test('parses user input into cents', () {
    expect(parseCents('42,50'), 4250);
    expect(parseCents('1.850'), 185000);
    expect(parseCents('1850,5'), 185050);
    expect(parseCents('abc'), isNull);
  });
}
