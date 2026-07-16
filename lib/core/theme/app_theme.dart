import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema "Bold Ink" — dal design system nIpay (design/directions/a-bold-ink*.html).
/// Brand ALUM: coral #FF6F61, teal #0E7C86, ink; importi in JetBrains Mono.
abstract final class NipayColors {
  static const coral = Color(0xFFFF6F61);
  static const coralLight = Color(0xFFFF8A7E);
  static const coralDark = Color(0xFFE8503F);

  // Semantici: spesa=coral, entrata=teal, trasferimento=neutro.
  static const expenseDark = coralLight;
  static const expenseLight = coralDark;
  static const incomeDark = Color(0xFF3FC5CF);
  static const incomeLight = Color(0xFF0E7C86);
  static const warn = Color(0xFFE0A800);
  static const over = Color(0xFFD64545);

  // Superfici dark.
  static const bgDark = Color(0xFF101318);
  static const surfDark = Color(0xFF1A1F27);
  static const surf2Dark = Color(0xFF222834);
  static const lineDark = Color(0xFF2A313D);
  static const textDark = Color(0xFFF2F4F8);
  static const mutedDark = Color(0xFF8B93A1);

  // Superfici light.
  static const bgLight = Color(0xFFF6F7F9);
  static const surfLight = Color(0xFFFFFFFF);
  static const surf2Light = Color(0xFFEDEFF2);
  static const lineLight = Color(0xFFE8EAEE);
  static const textLight = Color(0xFF171B21);
  static const mutedLight = Color(0xFF79818F);
}

/// Colori dipendenti dal brightness, comodi nei widget:
/// `context.nipay.expense`, `.income`, `.muted`, `.line`, `.surface2`.
class NipayPalette extends ThemeExtension<NipayPalette> {
  const NipayPalette({
    required this.expense,
    required this.income,
    required this.transfer,
    required this.muted,
    required this.line,
    required this.surface2,
  });

  final Color expense;
  final Color income;
  final Color transfer;
  final Color muted;
  final Color line;
  final Color surface2;

  static const dark = NipayPalette(
    expense: NipayColors.expenseDark,
    income: NipayColors.incomeDark,
    transfer: NipayColors.mutedDark,
    muted: NipayColors.mutedDark,
    line: NipayColors.lineDark,
    surface2: NipayColors.surf2Dark,
  );

  static const light = NipayPalette(
    expense: NipayColors.expenseLight,
    income: NipayColors.incomeLight,
    transfer: NipayColors.mutedLight,
    muted: NipayColors.mutedLight,
    line: NipayColors.lineLight,
    surface2: NipayColors.surf2Light,
  );

  @override
  NipayPalette copyWith({
    Color? expense,
    Color? income,
    Color? transfer,
    Color? muted,
    Color? line,
    Color? surface2,
  }) => NipayPalette(
    expense: expense ?? this.expense,
    income: income ?? this.income,
    transfer: transfer ?? this.transfer,
    muted: muted ?? this.muted,
    line: line ?? this.line,
    surface2: surface2 ?? this.surface2,
  );

  @override
  NipayPalette lerp(NipayPalette? other, double t) => other ?? this;
}

extension NipayThemeX on BuildContext {
  NipayPalette get nipay => Theme.of(this).extension<NipayPalette>()!;
}

/// Stile per gli importi: SEMPRE JetBrains Mono.
TextStyle moneyStyle({
  double size = 14,
  FontWeight weight = FontWeight.w700,
  Color? color,
}) =>
    GoogleFonts.jetBrainsMono(fontSize: size, fontWeight: weight, color: color);

ThemeData _base(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final bg = dark ? NipayColors.bgDark : NipayColors.bgLight;
  final surf = dark ? NipayColors.surfDark : NipayColors.surfLight;
  final text = dark ? NipayColors.textDark : NipayColors.textLight;
  final muted = dark ? NipayColors.mutedDark : NipayColors.mutedLight;
  final line = dark ? NipayColors.lineDark : NipayColors.lineLight;

  final scheme = ColorScheme.fromSeed(
    seedColor: NipayColors.coral,
    brightness: brightness,
    primary: NipayColors.coral,
    surface: surf,
    onSurface: text,
    outlineVariant: line,
  );

  final textTheme = GoogleFonts.interTextTheme(
    ThemeData(brightness: brightness).textTheme,
  ).apply(bodyColor: text, displayColor: text);

  final grotesk = GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700);

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    textTheme: textTheme.copyWith(
      // Titoli in Space Grotesk, come da design system.
      headlineMedium: grotesk.copyWith(fontSize: 28, color: text),
      titleLarge: grotesk.copyWith(fontSize: 20, color: text),
      titleMedium: grotesk.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: text,
      ),
      bodySmall: textTheme.bodySmall?.copyWith(color: muted),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: text,
      elevation: 0,
      titleTextStyle: grotesk.copyWith(fontSize: 20, color: text),
    ),
    cardTheme: CardThemeData(
      color: surf,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: line),
      ),
      margin: EdgeInsets.zero,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: NipayColors.coral,
      foregroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surf,
      indicatorColor: NipayColors.coral.withValues(alpha: .15),
      labelTextStyle: WidgetStatePropertyAll(
        GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600),
      ),
    ),
    dividerTheme: DividerThemeData(color: line, space: 1, thickness: 1),
    extensions: [dark ? NipayPalette.dark : NipayPalette.light],
  );
}

ThemeData nipayDarkTheme() => _base(Brightness.dark);
ThemeData nipayLightTheme() => _base(Brightness.light);
