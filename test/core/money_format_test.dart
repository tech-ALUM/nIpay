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

  test('parses dot as decimal separator (english keyboard)', () {
    expect(parseCents('12.00'), 1200);
    expect(parseCents('12.5'), 1250);
    expect(parseCents('42.50'), 4250);
  });

  test('formats non-EUR currencies with the ISO code, not a symbol', () {
    expect(formatCents(4250, currency: 'USD'), '42,50 USD');
    expect(formatCents(-4250, currency: 'GBP'), '−42,50 GBP');
    // Default resta EUR, comportamento identico a prima.
    expect(formatCents(4250), '42,50 €');
  });
}
