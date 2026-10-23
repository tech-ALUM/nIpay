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

/// Ora ("14:05", "2:05 PM") nella lingua dell'app, in ora locale.
String formatTime(BuildContext context, DateTime date) =>
    DateFormat.jm(_locale(context)).format(date.toLocal());

/// Momento di un messaggio nella lista chat: l'ora se è di oggi,
/// altrimenti la data.
String formatChatMoment(BuildContext context, DateTime date, {DateTime? now}) {
  final local = date.toLocal();
  final today = now ?? DateTime.now();
  final sameDay =
      local.year == today.year &&
      local.month == today.month &&
      local.day == today.day;
  return sameDay ? formatTime(context, local) : formatDate(context, local);
}

String _locale(BuildContext context) =>
    Localizations.localeOf(context).toString();
