import '../../data/services/chat_service.dart';
import '../../l10n/app_localizations.dart';
import '../friends/friends_ui.dart';

/// Testo per l'utente di un errore della chat (mai il messaggio del server).
String chatErrorText(AppLocalizations l10n, ChatErrorCode code) =>
    switch (code) {
      ChatErrorCode.notAvailable => l10n.friendsErrorNotAvailable,
      ChatErrorCode.notFound => l10n.chatErrorNotFound,
      ChatErrorCode.readOnly => l10n.chatReadOnly,
      ChatErrorCode.invalidMessage => l10n.chatErrorInvalidMessage,
      ChatErrorCode.invalidTitle => l10n.groupNameInvalid,
      ChatErrorCode.noMembers => l10n.groupNeedsMembers,
      ChatErrorCode.tooManyMembers => l10n.chatErrorTooManyMembers,
      ChatErrorCode.invalidReport => l10n.chatErrorInvalidReport,
      ChatErrorCode.rateLimited => l10n.authErrorRateLimited,
      ChatErrorCode.network => l10n.authErrorNetwork,
      ChatErrorCode.unknown => l10n.authErrorGeneric,
    };

/// Titolo di una conversazione: il gruppo, o l'altra persona (che può aver
/// cancellato l'account).
String conversationTitle(AppLocalizations l10n, Conversation c) {
  if (c.isGroup) return c.title ?? '';
  if (c.peerId == null) return l10n.deletedUser;
  return personName(l10n, c.peerDisplayName);
}

/// Nome del mittente di un messaggio: "Tu", "Utente eliminato" o il nome.
String senderName(AppLocalizations l10n, ChatMessage m, String? myId) {
  if (m.senderId == null) return l10n.deletedUser;
  if (m.senderId == myId) return l10n.youLabel;
  return personName(l10n, m.senderDisplayName);
}

/// Anteprima dell'ultimo messaggio nella lista; "Tu: …" per i miei.
String? messagePreview(AppLocalizations l10n, ChatMessage? m, String? myId) {
  if (m == null) return null;
  final text = m.deleted ? l10n.messageDeleted : (m.body ?? '');
  final oneLine = text.replaceAll(RegExp(r'\s+'), ' ');
  return m.senderId != null && m.senderId == myId
      ? l10n.chatYouPrefix(oneLine)
      : oneLine;
}

String reportReasonLabel(AppLocalizations l10n, ReportReason reason) =>
    switch (reason) {
      ReportReason.spam => l10n.reportReasonSpam,
      ReportReason.offensive => l10n.reportReasonOffensive,
      ReportReason.harassment => l10n.reportReasonHarassment,
      ReportReason.other => l10n.reportReasonOther,
    };
