/// Formattazione e parsing degli importi. Convenzione di progetto:
/// gli importi viaggiano SEMPRE in centesimi (int), mai in double.
library;

/// U+2212 (minus sign tipografico), come nei mockup Bold Ink.
const _minus = '−';

String formatCents(int cents, {bool signed = false}) {
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
  //  : spazio unificatore prima di €, come la formattazione intl it_IT.
  return "$sign$buf,$dec\u00A0€";
}

/// Converte input utente ("42,50", "1.850") in centesimi. Null se invalido.
int? parseCents(String input) {
  final cleaned = input.trim().replaceAll('.', '').replaceAll(',', '.');
  if (cleaned.isEmpty) return null;
  final value = double.tryParse(cleaned);
  if (value == null) return null;
  return (value * 100).round();
}
