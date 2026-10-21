import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Date nella lingua attiva dell'app (non quella del sistema): "7 ott 2026",
/// "Oct 7, 2026". I dati di formattazione li carica già il delegate di
/// GlobalMaterialLocalizations per tutte le lingue supportate.
String formatDate(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(_locale(context)).format(date);

/// Mese abbreviato ("ott", "Oct") per gli assi dei grafici.
String formatMonthShort(BuildContext context, DateTime date) =>
    DateFormat.MMM(_locale(context)).format(date);

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toString();
