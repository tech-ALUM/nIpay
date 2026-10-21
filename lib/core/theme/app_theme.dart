import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Tema "Ink Aurora" (2026-10-21), evoluzione di "Bold Ink"
/// (design/directions/a-bold-ink*.html): stessi colori del brand ALUM —
/// coral #FF6F61, teal #0E7C86, ink #15181D — con gradienti, bagliori e
/// ombre a strati per dare profondità. Titoli in Bricolage Grotesque, testo
/// in Plus Jakarta Sans, importi in Space Grotesk.
///
/// Regole d'uso (design/README.md): coral è l'accento primario, deliberato e
/// non ovunque (FAB, CTA, spese); teal il secondario (entrate, selezioni,
/// focus). Le varianti "deep"/"light" esistono solo per garantire il
/// contrasto WCAG AA del testo (≥ 4.5:1) sul rispettivo sfondo.
abstract final class NipayColors {
  // Brand.
  static const coral = Color(0xFFFF6F61);
  static const teal = Color(0xFF0E7C86);
  static const ink = Color(0xFF15181D);

  // Ink Aurora: code dei gradienti del brand e fondali del mesh saldo.
  static const magenta = Color(0xFFFF3D7F); // coda del CTA: ink sopra 5.3:1
  static const cyan = Color(0xFF22C3D6);
  static const auroraIndigo = Color(0xFF241C52);
  static const auroraInk = Color(0xFF0E1024);
  static const auroraTeal = Color(0xFF0A2630);

  // Varianti tonali per testo/icone: coral e teal puri non reggono il
  // contrasto del testo piccolo su tutti gli sfondi.
  static const coralDeep = Color(0xFFC23B2B); // su chiaro: 4.95:1 su bgLight
  static const coralLight = Color(0xFFFF8A7E); // su scuro: 7.2:1 su surfDark
  static const tealLight = Color(0xFF3FC5CF); // su scuro: 8:1 su surfDark

  // Stato budget (barre e avvisi): giallo ≥ 80%, rosso ≥ 100%.
  static const warn = Color(0xFFE0A800);
  static const over = Color(0xFFD64545);

  // Superfici dark: sfondo più profondo delle card, così le card "salgono".
  static const bgDark = Color(0xFF0B0E14);
  static const surfDark = Color(0xFF181C26);
  static const surf2Dark = Color(0xFF222834);
  static const fieldDark = Color(0xFF151A21);
  static const lineDark = Color(0xFF2A313D);
  static const outlineDark = Color(0xFF6B7385); // bordi input: 3.5:1
  static const textDark = Color(0xFFF2F4F8);
  static const mutedDark = Color(0xFF8B93A1); // 5.3:1 su surfDark

  // Superfici light.
  static const bgLight = Color(0xFFF6F7F9);
  static const surfLight = Color(0xFFFFFFFF);
  static const surf2Light = Color(0xFFEDEFF2);
  static const lineLight = Color(0xFFE2E7EC);
  static const outlineLight = Color(0xFF7F8792); // bordi input: ≥ 3.4:1
  static const textLight = Color(0xFF171B21);
  static const mutedLight = Color(0xFF5C6470); // 5.6:1 su bgLight
}

/// Colori dipendenti dal brightness, comodi nei widget:
/// `context.nipay.expense`, `.income`, `.muted`, `.line`, `.surface2`, …
class NipayPalette extends ThemeExtension<NipayPalette> {
  const NipayPalette({
    required this.expense,
    required this.income,
    required this.transfer,
    required this.muted,
    required this.line,
    required this.surface2,
    required this.warning,
    required this.warningStrong,
    required this.danger,
    required this.hero,
    required this.onHero,
    required this.onHeroMuted,
    required this.heroGradient,
    required this.ctaGradient,
    required this.glowPrimary,
    required this.glowSecondary,
    required this.cardShadow,
    required this.raisedShadow,
  });

  /// Testo/icone delle spese (coral leggibile sullo sfondo del tema).
  final Color expense;

  /// Testo/icone delle entrate (teal leggibile sullo sfondo del tema).
  final Color income;

  /// Trasferimenti: neutri, senza segno.
  final Color transfer;

  /// Testo secondario (AA su sfondo e superfici).
  final Color muted;

  /// Divisori e bordi decorativi.
  final Color line;

  /// Superficie secondaria: tracce delle barre, KPI, placeholder.
  final Color surface2;

  /// Budget ≥ 80% (grafici e sfondi con testo ink).
  final Color warning;

  /// Variante di [warning] per icone e testo sullo sfondo del tema (≥ 3:1).
  final Color warningStrong;

  /// Budget superato (grafici).
  final Color danger;

  /// Banda "ink" del saldo in home: scura in entrambi i temi.
  final Color hero;
  final Color onHero;
  final Color onHeroMuted;

  /// Mesh della banda saldo (indigo → ink → teal profondo): scuro in
  /// entrambi i temi, il testo sopra resta [onHero].
  final Gradient heroGradient;

  /// CTA e FAB: coral → magenta, testo/icone ink sopra (≥ 5.3:1).
  final Gradient ctaGradient;

  /// Bagliori decorativi dietro le intestazioni (coral e teal).
  final Color glowPrimary;
  final Color glowSecondary;

  /// Ombra a riposo delle card in rilievo e quella sollevata (hover).
  final List<BoxShadow> cardShadow;
  final List<BoxShadow> raisedShadow;

  static const _ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [NipayColors.coral, NipayColors.magenta],
  );

  static const dark = NipayPalette(
    expense: NipayColors.coralLight,
    income: NipayColors.tealLight,
    transfer: NipayColors.mutedDark,
    muted: NipayColors.mutedDark,
    line: NipayColors.lineDark,
    surface2: NipayColors.surf2Dark,
    warning: NipayColors.warn,
    warningStrong: Color(0xFFFFC94D),
    danger: NipayColors.over,
    hero: NipayColors.surf2Dark,
    onHero: NipayColors.textDark,
    onHeroMuted: Color(0xFFB9C0CB),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        NipayColors.auroraIndigo,
        NipayColors.auroraInk,
        NipayColors.auroraTeal,
      ],
      stops: [0, .55, 1],
    ),
    ctaGradient: _ctaGradient,
    glowPrimary: Color(0x47FF6F61),
    glowSecondary: Color(0x383FC5CF),
    cardShadow: [
      BoxShadow(color: Color(0x59000000), blurRadius: 18, offset: Offset(0, 8)),
    ],
    raisedShadow: [
      BoxShadow(
        color: Color(0x80000000),
        blurRadius: 28,
        offset: Offset(0, 14),
      ),
    ],
  );

  static const light = NipayPalette(
    expense: NipayColors.coralDeep,
    income: NipayColors.teal,
    transfer: NipayColors.mutedLight,
    muted: NipayColors.mutedLight,
    line: NipayColors.lineLight,
    surface2: NipayColors.surf2Light,
    warning: NipayColors.warn,
    warningStrong: Color(0xFF7A5B00),
    danger: NipayColors.over,
    hero: NipayColors.ink,
    onHero: NipayColors.textDark,
    onHeroMuted: Color(0xFFB9C0CB),
    heroGradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2B2160), NipayColors.ink, Color(0xFF0C2E38)],
      stops: [0, .55, 1],
    ),
    ctaGradient: _ctaGradient,
    glowPrimary: Color(0x29FF6F61),
    glowSecondary: Color(0x240E7C86),
    cardShadow: [
      BoxShadow(color: Color(0x141B2240), blurRadius: 16, offset: Offset(0, 6)),
      BoxShadow(color: Color(0x0D1B2240), blurRadius: 2, offset: Offset(0, 1)),
    ],
    raisedShadow: [
      BoxShadow(
        color: Color(0x241B2240),
        blurRadius: 28,
        offset: Offset(0, 14),
      ),
      BoxShadow(color: Color(0x0D1B2240), blurRadius: 2, offset: Offset(0, 1)),
    ],
  );

  @override
  NipayPalette copyWith({
    Color? expense,
    Color? income,
    Color? transfer,
    Color? muted,
    Color? line,
    Color? surface2,
    Color? warning,
    Color? warningStrong,
    Color? danger,
    Color? hero,
    Color? onHero,
    Color? onHeroMuted,
    Gradient? heroGradient,
    Gradient? ctaGradient,
    Color? glowPrimary,
    Color? glowSecondary,
    List<BoxShadow>? cardShadow,
    List<BoxShadow>? raisedShadow,
  }) => NipayPalette(
    expense: expense ?? this.expense,
    income: income ?? this.income,
    transfer: transfer ?? this.transfer,
    muted: muted ?? this.muted,
    line: line ?? this.line,
    surface2: surface2 ?? this.surface2,
    warning: warning ?? this.warning,
    warningStrong: warningStrong ?? this.warningStrong,
    danger: danger ?? this.danger,
    hero: hero ?? this.hero,
    onHero: onHero ?? this.onHero,
    onHeroMuted: onHeroMuted ?? this.onHeroMuted,
    heroGradient: heroGradient ?? this.heroGradient,
    ctaGradient: ctaGradient ?? this.ctaGradient,
    glowPrimary: glowPrimary ?? this.glowPrimary,
    glowSecondary: glowSecondary ?? this.glowSecondary,
    cardShadow: cardShadow ?? this.cardShadow,
    raisedShadow: raisedShadow ?? this.raisedShadow,
  );

  /// Interpolazione vera: il cambio chiaro/scuro anima anche questi colori.
  @override
  NipayPalette lerp(NipayPalette? other, double t) {
    if (other == null) return this;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return NipayPalette(
      expense: mix(expense, other.expense),
      income: mix(income, other.income),
      transfer: mix(transfer, other.transfer),
      muted: mix(muted, other.muted),
      line: mix(line, other.line),
      surface2: mix(surface2, other.surface2),
      warning: mix(warning, other.warning),
      warningStrong: mix(warningStrong, other.warningStrong),
      danger: mix(danger, other.danger),
      hero: mix(hero, other.hero),
      onHero: mix(onHero, other.onHero),
      onHeroMuted: mix(onHeroMuted, other.onHeroMuted),
      heroGradient: Gradient.lerp(heroGradient, other.heroGradient, t)!,
      ctaGradient: Gradient.lerp(ctaGradient, other.ctaGradient, t)!,
      glowPrimary: mix(glowPrimary, other.glowPrimary),
      glowSecondary: mix(glowSecondary, other.glowSecondary),
      cardShadow: BoxShadow.lerpList(cardShadow, other.cardShadow, t)!,
      raisedShadow: BoxShadow.lerpList(raisedShadow, other.raisedShadow, t)!,
    );
  }
}

extension NipayThemeX on BuildContext {
  /// Palette del tema nIpay; fuori dal tema dell'app (es. widget montati da
  /// soli nei test) ripiega sulla variante chiara/scura corrispondente.
  NipayPalette get nipay {
    final theme = Theme.of(this);
    return theme.extension<NipayPalette>() ??
        (theme.brightness == Brightness.dark
            ? NipayPalette.dark
            : NipayPalette.light);
  }
}

/// Stile per gli importi: SEMPRE Space Grotesk (cifre tabulari, non
/// monospace), il font numerico del brand ALUM.
TextStyle moneyStyle({
  double size = 14,
  FontWeight weight = FontWeight.w700,
  Color? color,
}) => GoogleFonts.spaceGrotesk(
  fontSize: size,
  fontWeight: weight,
  color: color,
  letterSpacing: size >= 28 ? -1 : 0,
  fontFeatures: const [FontFeature.tabularFigures()],
);

/// Stile per i bottoni distruttivi (elimina, rimuovi dati): rosso errore con
/// testo `onError`, non l'ink del CTA standard (che sul rosso non si legge).
/// Lo stile del widget si fonde con quello del tema, quindi il gradiente
/// coral del CTA va spento esplicitamente.
ButtonStyle destructiveButtonStyle(BuildContext context) {
  final scheme = Theme.of(context).colorScheme;
  return FilledButton.styleFrom(
    backgroundColor: scheme.error,
    foregroundColor: scheme.onError,
    shadowColor: scheme.error.withValues(alpha: .45),
    backgroundBuilder: (context, states, child) => child!,
  );
}

/// Colore da stringa `#RRGGBB` (come salvata su DB); coral se non valida.
Color colorFromHex(String hex) {
  final v = int.tryParse(hex.replaceFirst('#', ''), radix: 16) ?? 0xFF6F61;
  return Color(0xFF000000 | v);
}

/// Primo piano leggibile (ink o bianco) su un colore scelto dall'utente,
/// es. la card di un portafoglio: vince quello col contrasto più alto.
Color foregroundOn(Color background) {
  double contrast(Color a, Color b) {
    final la = a.computeLuminance(), lb = b.computeLuminance();
    return la > lb ? (la + .05) / (lb + .05) : (lb + .05) / (la + .05);
  }

  const light = NipayColors.textDark;
  return contrast(light, background) >= contrast(NipayColors.ink, background)
      ? light
      : NipayColors.ink;
}

const _radiusS = 12.0;
const _radiusM = 14.0;
const _radiusL = 20.0;
const _radiusXL = 28.0;

ThemeData _base(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final bg = dark ? NipayColors.bgDark : NipayColors.bgLight;
  final surf = dark ? NipayColors.surfDark : NipayColors.surfLight;
  final text = dark ? NipayColors.textDark : NipayColors.textLight;
  final muted = dark ? NipayColors.mutedDark : NipayColors.mutedLight;
  final line = dark ? NipayColors.lineDark : NipayColors.lineLight;
  final outline = dark ? NipayColors.outlineDark : NipayColors.outlineLight;
  final palette = dark ? NipayPalette.dark : NipayPalette.light;

  // Teal = selezioni e focus (primary dei componenti Material); coral resta
  // l'accento dei CTA (FilledButton, FAB) e delle spese, via component theme.
  final tealOnTheme = dark ? NipayColors.tealLight : NipayColors.teal;
  final tealTint = dark ? const Color(0xFF123E44) : const Color(0xFFD4EEF0);
  final onTealTint = dark ? const Color(0xFFBFF3F7) : const Color(0xFF053C41);
  final coralTint = dark ? const Color(0xFF4A2420) : const Color(0xFFFFE3DF);
  final onCoralTint = dark ? const Color(0xFFFFDAD5) : const Color(0xFF5C1A12);

  final scheme =
      ColorScheme.fromSeed(
        seedColor: NipayColors.teal,
        brightness: brightness,
      ).copyWith(
        primary: tealOnTheme,
        onPrimary: dark ? NipayColors.ink : Colors.white,
        primaryContainer: tealTint,
        onPrimaryContainer: onTealTint,
        secondary: tealOnTheme,
        onSecondary: dark ? NipayColors.ink : Colors.white,
        secondaryContainer: tealTint,
        onSecondaryContainer: onTealTint,
        tertiary: dark ? NipayColors.coralLight : NipayColors.coralDeep,
        onTertiary: dark ? NipayColors.ink : Colors.white,
        tertiaryContainer: coralTint,
        onTertiaryContainer: onCoralTint,
        error: dark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
        onError: dark ? const Color(0xFF690005) : Colors.white,
        errorContainer: dark
            ? const Color(0xFF5C1714)
            : const Color(0xFFFCE4E2),
        onErrorContainer: dark
            ? const Color(0xFFFFDAD6)
            : const Color(0xFF410E0B),
        surface: surf,
        onSurface: text,
        onSurfaceVariant: muted,
        surfaceContainerLowest: dark
            ? const Color(0xFF0C0F13)
            : NipayColors.surfLight,
        surfaceContainerLow: dark ? const Color(0xFF151A21) : bg,
        surfaceContainer: dark ? surf : const Color(0xFFF1F3F6),
        surfaceContainerHigh: dark
            ? NipayColors.surf2Dark
            : NipayColors.surf2Light,
        surfaceContainerHighest: dark ? line : const Color(0xFFE6E9EE),
        outline: outline,
        outlineVariant: line,
        inverseSurface: dark ? NipayColors.textDark : NipayColors.ink,
        onInverseSurface: dark ? NipayColors.ink : NipayColors.textDark,
        inversePrimary: dark ? NipayColors.teal : NipayColors.tealLight,
        surfaceTint: Colors.transparent,
        shadow: Colors.black,
        scrim: Colors.black,
      );

  final base = GoogleFonts.plusJakartaSansTextTheme(
    ThemeData(brightness: brightness).textTheme,
  ).apply(bodyColor: text, displayColor: text);
  // Titoli grandi e compatti: la spaziatura negativa cresce con la misura.
  TextStyle display(double size, FontWeight weight) =>
      GoogleFonts.bricolageGrotesque(
        fontSize: size,
        fontWeight: weight,
        color: text,
        letterSpacing: -size * .025,
        height: 1.1,
      );
  TextStyle inter(double size, FontWeight weight, [Color? color]) =>
      GoogleFonts.plusJakartaSans(
        fontSize: size,
        fontWeight: weight,
        color: color ?? text,
      );

  // Scala unica: titoli in Bricolage Grotesque, testo in Plus Jakarta Sans.
  // Niente testo sotto i 12 px per i contenuti (11 solo per micro-etichette).
  final textTheme = base.copyWith(
    displaySmall: display(40, FontWeight.w800),
    headlineMedium: display(31, FontWeight.w800),
    headlineSmall: display(27, FontWeight.w800),
    titleLarge: display(21, FontWeight.w700),
    titleMedium: display(17.5, FontWeight.w700),
    titleSmall: inter(14, FontWeight.w600),
    bodyLarge: inter(16, FontWeight.w400),
    bodyMedium: inter(14, FontWeight.w400),
    bodySmall: inter(12.5, FontWeight.w400, muted),
    labelLarge: inter(15, FontWeight.w600),
    labelMedium: inter(13, FontWeight.w600),
    labelSmall: inter(11.5, FontWeight.w600, muted),
  );

  RoundedRectangleBorder rounded(double r) =>
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(r));
  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(_radiusM),
        borderSide: BorderSide(color: color, width: width),
      );

  // Anello di focus ben visibile per la navigazione da tastiera.
  BorderSide? focusRing(Set<WidgetState> states) =>
      states.contains(WidgetState.focused)
      ? BorderSide(color: text, width: 2)
      : null;

  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
    canvasColor: surf,
    textTheme: textTheme,
    extensions: [palette],
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      color: surf,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_radiusL),
        side: BorderSide(color: line),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: DividerThemeData(color: line, space: 1, thickness: 1),
    listTileTheme: ListTileThemeData(
      iconColor: muted,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      minVerticalPadding: 10,
      titleTextStyle: inter(15, FontWeight.w500),
      subtitleTextStyle: inter(13, FontWeight.w400, muted),
      leadingAndTrailingTextStyle: textTheme.labelMedium,
      shape: rounded(_radiusM),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: NipayColors.coral,
      foregroundColor: NipayColors.ink,
      focusColor: NipayColors.ink.withValues(alpha: .16),
      hoverColor: NipayColors.ink.withValues(alpha: .08),
      splashColor: NipayColors.ink.withValues(alpha: .16),
      elevation: 4,
      focusElevation: 8,
      hoverElevation: 8,
      highlightElevation: 2,
      shape: rounded(18),
      extendedTextStyle: inter(15, FontWeight.w700, NipayColors.ink),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? text.withValues(alpha: .12)
              : NipayColors.coral,
        ),
        // Gradiente dipinto con Ink sul Material del bottone: ripple e
        // overlay di hover/focus restano visibili sopra il colore.
        backgroundBuilder: (context, states, child) =>
            states.contains(WidgetState.disabled)
            ? child!
            : Ink(
                decoration: BoxDecoration(
                  gradient: palette.ctaGradient,
                  borderRadius: BorderRadius.circular(_radiusM),
                ),
                child: child,
              ),
        // Ombra colorata che si alza al passaggio e si abbassa al tocco.
        elevation: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? 0
              : s.contains(WidgetState.pressed)
              ? 1
              : s.contains(WidgetState.hovered) ||
                    s.contains(WidgetState.focused)
              ? 8
              : 3,
        ),
        shadowColor: WidgetStatePropertyAll(
          NipayColors.coral.withValues(alpha: dark ? .55 : .45),
        ),
        animationDuration: const Duration(milliseconds: 160),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? text.withValues(alpha: .38)
              : NipayColors.ink,
        ),
        overlayColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.pressed)
              ? NipayColors.ink.withValues(alpha: .14)
              : s.contains(WidgetState.hovered) ||
                    s.contains(WidgetState.focused)
              ? NipayColors.ink.withValues(alpha: .08)
              : null,
        ),
        side: WidgetStateProperty.resolveWith(focusRing),
        minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        ),
        shape: WidgetStatePropertyAll(rounded(_radiusM)),
        textStyle: WidgetStatePropertyAll(inter(15, FontWeight.w700)),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.disabled)
              ? text.withValues(alpha: .38)
              : text,
        ),
        side: WidgetStateProperty.resolveWith(
          (s) =>
              focusRing(s) ??
              BorderSide(
                color: s.contains(WidgetState.disabled)
                    ? text.withValues(alpha: .12)
                    : outline,
              ),
        ),
        minimumSize: const WidgetStatePropertyAll(Size(64, 48)),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        shape: WidgetStatePropertyAll(rounded(_radiusM)),
        textStyle: WidgetStatePropertyAll(inter(15, FontWeight.w600)),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: ButtonStyle(
        side: WidgetStateProperty.resolveWith(focusRing),
        minimumSize: const WidgetStatePropertyAll(Size(48, 44)),
        shape: WidgetStatePropertyAll(rounded(_radiusS)),
        textStyle: WidgetStatePropertyAll(inter(14.5, FontWeight.w600)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: ButtonStyle(side: WidgetStateProperty.resolveWith(focusRing)),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        side: WidgetStatePropertyAll(BorderSide(color: outline)),
        shape: WidgetStatePropertyAll(rounded(_radiusS)),
        minimumSize: const WidgetStatePropertyAll(Size(0, 44)),
        textStyle: WidgetStatePropertyAll(inter(14, FontWeight.w600)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: rounded(10),
      side: WidgetStateBorderSide.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? BorderSide(color: tealOnTheme)
            : BorderSide(color: outline),
      ),
      labelStyle: inter(13.5, FontWeight.w500),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      showCheckmark: true,
      checkmarkColor: onTealTint,
      selectedColor: tealTint,
      backgroundColor: surf,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? NipayColors.fieldDark : NipayColors.surfLight,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: inputBorder(outline),
      enabledBorder: inputBorder(outline),
      focusedBorder: inputBorder(tealOnTheme, 2),
      errorBorder: inputBorder(scheme.error),
      focusedErrorBorder: inputBorder(scheme.error, 2),
      disabledBorder: inputBorder(text.withValues(alpha: .12)),
      labelStyle: inter(15, FontWeight.w400, muted),
      floatingLabelStyle: WidgetStateTextStyle.resolveWith(
        (s) => inter(
          15,
          FontWeight.w500,
          s.contains(WidgetState.error)
              ? scheme.error
              : s.contains(WidgetState.focused)
              ? tealOnTheme
              : muted,
        ),
      ),
      hintStyle: inter(15, FontWeight.w400, muted),
      helperStyle: inter(12.5, FontWeight.w400, muted),
      errorStyle: inter(12.5, FontWeight.w500, scheme.error),
      helperMaxLines: 3,
      errorMaxLines: 3,
      prefixIconColor: muted,
      suffixIconColor: muted,
    ),
    switchTheme: SwitchThemeData(
      // Stato leggibile anche senza colore: spunta quando attivo.
      thumbIcon: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? const Icon(Icons.check, size: 16)
            : null,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: surf,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      height: 72,
      indicatorColor: coralTint,
      indicatorShape: rounded(16),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected)
            ? inter(12.5, FontWeight.w700)
            : inter(12.5, FontWeight.w500, muted),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (s) => IconThemeData(
          size: 24,
          color: s.contains(WidgetState.selected) ? onCoralTint : muted,
        ),
      ),
    ),
    navigationRailTheme: NavigationRailThemeData(
      backgroundColor: surf,
      elevation: 0,
      indicatorColor: coralTint,
      indicatorShape: rounded(16),
      labelType: NavigationRailLabelType.all,
      minWidth: 88,
      selectedIconTheme: IconThemeData(size: 24, color: onCoralTint),
      unselectedIconTheme: IconThemeData(size: 24, color: muted),
      selectedLabelTextStyle: inter(12.5, FontWeight.w700),
      unselectedLabelTextStyle: inter(12.5, FontWeight.w500, muted),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surf,
      modalBackgroundColor: surf,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: outline,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_radiusXL)),
      ),
      // Su tablet il foglio non si allarga a tutto schermo.
      constraints: const BoxConstraints(maxWidth: 640),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surf,
      surfaceTintColor: Colors.transparent,
      shape: rounded(24),
      titleTextStyle: textTheme.titleLarge,
      contentTextStyle: inter(14.5, FontWeight.w400),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: surf,
      surfaceTintColor: Colors.transparent,
      shape: rounded(24),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: surf,
      surfaceTintColor: Colors.transparent,
      shape: rounded(_radiusM),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: inter(14, FontWeight.w500, scheme.onInverseSurface),
      actionTextColor: dark ? NipayColors.teal : NipayColors.tealLight,
      shape: rounded(_radiusM),
      elevation: 3,
    ),
    tooltipTheme: TooltipThemeData(
      waitDuration: const Duration(milliseconds: 400),
      decoration: BoxDecoration(
        color: scheme.inverseSurface,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: inter(12.5, FontWeight.w500, scheme.onInverseSurface),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: tealOnTheme,
      linearTrackColor: palette.surface2,
    ),
  );
}

ThemeData nipayDarkTheme() => _base(Brightness.dark);
ThemeData nipayLightTheme() => _base(Brightness.light);
