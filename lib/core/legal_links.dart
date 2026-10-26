import 'dart:ui' show Locale;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Informativa e Termini (M-ACC0, M-SOC0). PROVVISORI: puntano alle bozze
/// in mds/legal/ sul repo pubblico finché non sono pubblicate le pagine
/// definitive; allora si cambia solo [_base].
const _base = 'https://github.com/tech-ALUM/nIpay/blob/beta-sergio/mds/legal';

/// Italiano per l'app in italiano, inglese per tutte le altre lingue.
String _suffix(Locale locale) => locale.languageCode == 'it' ? 'it' : 'en';

Uri privacyPolicyUri(Locale locale) =>
    Uri.parse('$_base/privacy-policy.${_suffix(locale)}.md');

Uri termsUri(Locale locale) => Uri.parse('$_base/terms.${_suffix(locale)}.md');

/// Apre un indirizzo nel browser; false se non ci riesce. Sostituibile nei
/// test.
final openExternalUrlProvider = Provider<Future<bool> Function(Uri)>(
  (ref) => (uri) async {
    try {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      return false;
    }
  },
);
