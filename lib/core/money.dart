/// Formattazione e parsing degli importi. Convenzione di progetto:
/// gli importi viaggiano SEMPRE in centesimi (int), mai in double.
library;

import 'package:flutter/services.dart';

import 'currencies.dart';

/// U+2212 (minus sign tipografico), come nei mockup Bold Ink.
const _minus = '−';

/// Solo cifre ed eventuale separatore decimale (virgola o punto) seguito
/// da al massimo due cifre: blocca lettere e simboli fin dalla digitazione,
/// non solo in fase di parsing.
final moneyInputFormatters = <TextInputFormatter>[
  FilteringTextInputFormatter.allow(RegExp(r'[0-9,.]')),
  TextInputFormatter.withFunction((oldValue, newValue) {
    if (RegExp(r'^\d*[,.]?\d{0,2}$').hasMatch(newValue.text)) return newValue;
    return oldValue;
  }),
];

/// [currency] è un codice ISO 4217 (es. "USD"). Di default mostra il codice
/// (tranne EUR → "€"), per evitare l'ambiguità del simbolo "$" condiviso da
/// USD/CAD/AUD/ecc.; con [symbolOnly] mostra invece solo il simbolo — pensato
/// per le card di portafoglio/transazione, dove lo spazio è poco e il
/// contesto (un solo portafoglio alla volta) rende il simbolo inequivocabile.
String formatCents(
  int cents, {
  String currency = 'EUR',
  bool signed = false,
  bool symbolOnly = false,
}) {
  final negative = cents < 0;
  final abs = cents.abs();
  final euros = abs ~/ 100;
  final dec = (abs % 100).toString().padLeft(2, '0');

  final digits = euros.toString();
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buf.write('.');
    buf.write(digits[i]);
  }

  final sign = negative ? _minus : (signed ? '+' : '');
  final symbol = symbolOnly
      ? currencySymbol(currency)
      : (currency == 'EUR' ? '€' : currency);
  //  : spazio unificatore prima della valuta, come la formattazione intl it_IT.
  return "$sign$buf,$dec\u00A0$symbol";
}

/// Converte input utente in centesimi. Null se invalido.
///
/// L'ultimo separatore (`,` o `.`) trovato è il decimale solo se seguito da
/// al massimo 2 cifre (es. "42,50", "12.00" con tastiera in inglese);
/// altrimenti è un separatore delle migliaia (es. "1.850" → 1850,00 €).
int? parseCents(String input) {
  final cleaned = input.trim();
  if (cleaned.isEmpty) return null;

  final lastSep = cleaned.lastIndexOf(RegExp(r'[.,]'));
  final String normalized;
  if (lastSep == -1) {
    normalized = cleaned;
  } else if (cleaned.length - lastSep - 1 <= 2) {
    normalized =
        '${cleaned.substring(0, lastSep).replaceAll(RegExp(r'[.,]'), '')}'
        '.${cleaned.substring(lastSep + 1)}';
  } else {
    normalized = cleaned.replaceAll(RegExp(r'[.,]'), '');
  }

  final value = double.tryParse(normalized);
  if (value == null) return null;
  return (value * 100).round();
}
