// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'nIpay';

  @override
  String get homeTab => 'Start';

  @override
  String get transactionsTab => 'Transaktionen';

  @override
  String get statsTab => 'Statistiken';

  @override
  String get settingsTab => 'Mehr';

  @override
  String get totalBalance => 'Gesamtsaldo';

  @override
  String get thisMonth => 'diesen Monat';

  @override
  String get wallets => 'Konten';

  @override
  String get newWallet => 'Neues Konto';

  @override
  String get walletName => 'Name';

  @override
  String get currency => 'Währung';

  @override
  String get walletNameDuplicate =>
      'Ein Konto mit diesem Namen existiert bereits';

  @override
  String get walletNameRequired => 'Bitte gib einen Kontonamen ein';

  @override
  String get initialBalance => 'Anfangssaldo';

  @override
  String get recentTransactions => 'Letzte Transaktionen';

  @override
  String get noTransactions =>
      'Noch keine Transaktionen. Tippe auf +, um die erste hinzuzufügen.';

  @override
  String get noWallets => 'Erstelle dein erstes Konto, um loszulegen.';

  @override
  String get newTransaction => 'Neue Transaktion';

  @override
  String get expense => 'Ausgabe';

  @override
  String get income => 'Einnahme';

  @override
  String get transfer => 'Überweisung';

  @override
  String get amount => 'Betrag';

  @override
  String get invalidAmount => 'Ungültiger Betrag';

  @override
  String get exchangeRateError =>
      'Wechselkurs nicht verfügbar: Verbindung prüfen und erneut versuchen';

  @override
  String convertedPreview(String amount) {
    return '≈ $amount zum aktuellen Kurs';
  }

  @override
  String get description => 'Beschreibung';

  @override
  String get category => 'Kategorie';

  @override
  String get wallet => 'Konto';

  @override
  String get fromWallet => 'Von';

  @override
  String get toWallet => 'Nach';

  @override
  String get date => 'Datum';

  @override
  String get save => 'Speichern';

  @override
  String get apply => 'Anwenden';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get delete => 'Löschen';

  @override
  String get deleteWalletTitle => 'Konto löschen?';

  @override
  String deleteWalletBody(String name) {
    return 'Gib zur Bestätigung „$name\" in das Feld unten ein. Dies kann nicht rückgängig gemacht werden.';
  }

  @override
  String get allWallets => 'Alle Konten';

  @override
  String get allCategories => 'Alle Kategorien';

  @override
  String get searchTransactions => 'Transaktionen suchen…';

  @override
  String get receipt => 'Beleg';

  @override
  String get fromCamera => 'Kamera';

  @override
  String get fromGallery => 'Galerie';

  @override
  String get attachments => 'Anhänge';

  @override
  String get transactionDetail => 'Transaktion';

  @override
  String get deleteTransaction => 'Transaktion löschen';

  @override
  String get addCard => 'Karte hinzufügen';

  @override
  String get cardCategoryDonut => 'Ausgaben nach Kategorie';

  @override
  String get cardTrend => '6-Monats-Trend';

  @override
  String get cardCashflow => 'Cashflow';

  @override
  String get cardBudget => 'Budget';

  @override
  String get netLabel => 'Netto';

  @override
  String get noStatsData => 'Keine Daten für diesen Zeitraum.';

  @override
  String get emptyDashboard =>
      'Stelle dein Dashboard zusammen: Füge deine erste Karte hinzu.';

  @override
  String get customization => 'Anpassung';

  @override
  String get budgets => 'Budget';

  @override
  String get newBudget => 'Neues Budget';

  @override
  String get monthlyLimit => 'Monatliches Limit';

  @override
  String get recurring => 'Wiederkehrend';

  @override
  String get newRecurring => 'Neue wiederkehrende Transaktion';

  @override
  String get frequency => 'Häufigkeit';

  @override
  String get freqDaily => 'Täglich';

  @override
  String get freqWeekly => 'Wöchentlich';

  @override
  String get freqMonthly => 'Monatlich';

  @override
  String get freqYearly => 'Jährlich';

  @override
  String get startDate => 'Startdatum';

  @override
  String get nextRun => 'Nächste';

  @override
  String get paused => 'Pausiert';

  @override
  String budgetNear(String category, int percent) {
    return 'Budget $category bei $percent%';
  }

  @override
  String budgetExceeded(String category) {
    return 'Budget $category überschritten!';
  }

  @override
  String get manageCategories => 'Kategorien';

  @override
  String get manageTags => 'Tags';

  @override
  String get manageCustomFields => 'Benutzerdefinierte Felder';

  @override
  String get newCategory => 'Neue Kategorie';

  @override
  String get editCategory => 'Kategorie bearbeiten';

  @override
  String get icon => 'Symbol (Emoji)';

  @override
  String get color => 'Farbe';

  @override
  String get kindBoth => 'Beide';

  @override
  String get newTag => 'Neuer Tag';

  @override
  String get tagNameRequired => 'Gib einen Tag-Namen ein';

  @override
  String get tagNameDuplicate => 'Ein Tag mit diesem Namen existiert bereits';

  @override
  String get costCenterNameRequired =>
      'Gib einen Namen für die Kostenstelle ein';

  @override
  String get tagName => 'Tag-Name';

  @override
  String get newField => 'Neues Feld';

  @override
  String get fieldName => 'Feldname';

  @override
  String get fieldType => 'Typ';

  @override
  String get typeText => 'Text';

  @override
  String get typeNumber => 'Zahl';

  @override
  String get typeChoice => 'Auswahl';

  @override
  String get typeDate => 'Datum';

  @override
  String get choiceOptions => 'Optionen (durch Komma getrennt)';

  @override
  String get tags => 'Tags';

  @override
  String get customFields => 'Benutzerdefinierte Felder';

  @override
  String get allTags => 'Alle Tags';

  @override
  String get noItems => 'Hier ist noch nichts.';

  @override
  String get expenseReport => 'Spesenabrechnung';

  @override
  String get expenseReportFlag => 'Spesenabrechnung';

  @override
  String get costCenter => 'Kostenstelle';

  @override
  String get manageCostCenters => 'Kostenstellen';

  @override
  String get newCostCenter => 'Neue Kostenstelle';

  @override
  String get reimbursable => 'Erstattungsfähig';

  @override
  String get eInvoice => 'E-Rechnung';

  @override
  String get pendingReimbursement => 'Zu erstatten';

  @override
  String get exportPdf => 'PDF exportieren';

  @override
  String get createReport => 'Spesenabrechnung erstellen';

  @override
  String get reportName => 'Name der Abrechnung';

  @override
  String get statusDraft => 'Entwurf';

  @override
  String get statusSent => 'Gesendet';

  @override
  String get statusReimbursed => 'Erstattet';

  @override
  String get markSent => 'Als gesendet markieren';

  @override
  String get markReimbursed => 'Als erstattet markieren';

  @override
  String get reportArchive => 'Archiv';

  @override
  String get flaggedExpenses => 'Markierte Ausgaben';

  @override
  String get expenseReportOnlyField => 'Nur für Spesenabrechnungen';

  @override
  String get edit => 'Bearbeiten';

  @override
  String get editTransaction => 'Transaktion bearbeiten';

  @override
  String get fromDate => 'Von';

  @override
  String get toDate => 'Bis';

  @override
  String get none => 'Keine';

  @override
  String get language => 'Sprache';

  @override
  String get settingsTheme => 'Design';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Hell';

  @override
  String get themeDark => 'Dunkel';

  @override
  String get account => 'Account';

  @override
  String get accountLocalModeDescription =>
      'Du bist nicht angemeldet: Deine Daten bleiben nur auf diesem Gerät. Melde dich an, um sie zwischen Geräten zu synchronisieren.';

  @override
  String get signIn => 'Anmelden';

  @override
  String get signUp => 'Registrieren';

  @override
  String get signOut => 'Abmelden';

  @override
  String get email => 'E-Mail';

  @override
  String get password => 'Passwort';

  @override
  String get confirmSignOut =>
      'Vom Account abmelden? Deine Daten bleiben auf diesem Gerät, lassen sich aber nur wieder öffnen, wenn du dich mit diesem Account anmeldest.';

  @override
  String get noAccountYet => 'Noch keinen Account? Registrieren';

  @override
  String get alreadyHaveAccount => 'Schon einen Account? Anmelden';

  @override
  String get forgotPassword => 'Passwort vergessen?';

  @override
  String get resetPasswordSent =>
      'E-Mail zum Zurücksetzen des Passworts gesendet — sieh in deinem Posteingang nach.';

  @override
  String signedInAs(String email) {
    return 'Angemeldet als $email';
  }

  @override
  String get invalidEmail => 'Gib eine gültige E-Mail-Adresse ein';

  @override
  String get passwordTooShort =>
      'Das Passwort muss mindestens 8 Zeichen lang sein';

  @override
  String get changePassword => 'Passwort ändern';

  @override
  String get newPassword => 'Neues Passwort';

  @override
  String get confirmPassword => 'Passwort bestätigen';

  @override
  String get passwordsDontMatch => 'Die Passwörter stimmen nicht überein';

  @override
  String get passwordChanged =>
      'Passwort geändert. Andere Geräte wurden abgemeldet.';

  @override
  String get syncNow => 'Jetzt synchronisieren';

  @override
  String get syncComplete => 'Synchronisierung abgeschlossen';

  @override
  String get syncFailed =>
      'Synchronisierung fehlgeschlagen. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get deleteAccount => 'Account löschen';

  @override
  String get deleteAccountConfirmBody =>
      'Dein Account und seine Cloud-Daten werden in 30 Tagen endgültig gelöscht. Bis dahin kannst du das auf diesem Bildschirm abbrechen. Die Daten auf diesem Gerät werden nicht gelöscht.';

  @override
  String get deleteAccountRequested =>
      'Löschung des Accounts beantragt. Du hast 30 Tage Zeit, sie abzubrechen.';

  @override
  String deletionPending(String date) {
    return 'Der Account wird am $date gelöscht.';
  }

  @override
  String get cancelDeletion => 'Löschung abbrechen';

  @override
  String get deletionCanceled => 'Löschung des Accounts abgebrochen.';

  @override
  String get signOutRemoveLocalData => 'Daten von diesem Gerät entfernen';

  @override
  String get signOutRemoveLocalDataHint =>
      'Deine Daten werden zuerst mit deinem Konto synchronisiert und dann von diesem Gerät entfernt. Belegfotos werden noch nicht synchronisiert und gehen verloren.';

  @override
  String get signOutSyncFailed =>
      'Synchronisierung vor dem Entfernen fehlgeschlagen. Es wurde nichts entfernt und du bist noch angemeldet: Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get localDataRemoved => 'Daten von diesem Gerät entfernt';

  @override
  String get foreignLocalDataBody =>
      'Auf diesem Gerät befinden sich Daten eines anderen Kontos, daher ist die Synchronisierung pausiert. Entferne diese Daten, um dieses Konto zu synchronisieren, oder melde dich ab.';

  @override
  String get removeLocalDataAndSync => 'Daten entfernen und synchronisieren';

  @override
  String get removeForeignLocalDataConfirmBody =>
      'Alle Konten, Transaktionen und Belegfotos auf diesem Gerät werden gelöscht. Was das andere Konto bereits synchronisiert hat, bleibt dort sicher erhalten. Fortfahren?';

  @override
  String get syncBlockedForeignData =>
      'Synchronisierung pausiert: Auf diesem Gerät befinden sich Daten eines anderen Kontos.';

  @override
  String get currentPassword => 'Aktuelles Passwort';

  @override
  String get wrongCurrentPassword => 'Das aktuelle Passwort ist nicht korrekt.';

  @override
  String get confirmWithPassword => 'Gib zur Bestätigung dein Passwort ein.';

  @override
  String get passwordTooWeak =>
      'Verwende mindestens 12 Zeichen mit Buchstaben und Zahlen.';

  @override
  String get signOutEverywhere => 'Von allen Geräten abmelden';

  @override
  String get signOutEverywhereConfirmBody =>
      'Alle Sitzungen dieses Accounts werden beendet, auch diese. Nutze das, wenn ein Gerät verloren gegangen ist oder gestohlen wurde. Die Daten auf diesem Gerät bleiben hier.';

  @override
  String get signedOutEverywhere => 'Von allen Geräten abgemeldet.';

  @override
  String get authErrorInvalidCredentials =>
      'E-Mail oder Passwort ungültig, oder die E-Mail wurde noch nicht bestätigt.';

  @override
  String get authErrorWeakPassword =>
      'Dieses Passwort wird nicht akzeptiert: Wähle ein längeres, weniger verbreitetes.';

  @override
  String get authErrorSamePassword =>
      'Das neue Passwort muss sich vom aktuellen unterscheiden.';

  @override
  String get authErrorRateLimited =>
      'Zu viele Versuche. Warte ein paar Minuten und versuche es erneut.';

  @override
  String get authErrorReauthRequired =>
      'Gib aus Sicherheitsgründen dein Passwort erneut ein und versuche es noch einmal.';

  @override
  String get authErrorNetwork =>
      'Der Server ist nicht erreichbar. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get authErrorGeneric =>
      'Etwas ist schiefgelaufen. Bitte versuche es erneut.';

  @override
  String get resetPasswordTitle => 'Neues Passwort festlegen';

  @override
  String get passwordResetDone =>
      'Passwort aktualisiert. Andere Geräte wurden abgemeldet.';

  @override
  String get resetPasswordCooldown =>
      'Warte eine Minute, bevor du eine weitere E-Mail anforderst.';

  @override
  String lastSyncAt(String date) {
    return 'Letzte Synchronisierung: $date';
  }

  @override
  String get lastSyncNever => 'Noch nicht synchronisiert';

  @override
  String get syncLastFailed =>
      'Die letzte Synchronisierung ist fehlgeschlagen: Sie wird automatisch wiederholt.';

  @override
  String syncIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count Elemente konnten nicht synchronisiert werden und werden erneut versucht.',
      one:
          '1 Element konnte nicht synchronisiert werden und wird erneut versucht.',
    );
    return '$_temp0';
  }

  @override
  String get lockedDataTitle => 'Daten gesperrt';

  @override
  String lockedDataBody(String email) {
    return 'Dieses Gerät enthält die Daten von $email. Melde dich mit diesem Account an, um sie zu sehen, oder entferne sie von diesem Gerät.';
  }

  @override
  String get lockedDataBodyUnknownOwner =>
      'Dieses Gerät enthält die Daten eines nicht angemeldeten Accounts. Melde dich mit diesem Account an, um sie zu sehen, oder entferne sie von diesem Gerät.';

  @override
  String get lockedDataOtherAccountBody =>
      'Dieses Gerät enthält die Daten eines anderen Accounts. Um diesen Account hier zu nutzen, entferne diese Daten vom Gerät (öffne Account) oder melde dich ab.';

  @override
  String get startupError =>
      'Deine Daten konnten nicht geöffnet werden. Starte die App neu; wenn das wieder passiert, wende dich an den Support.';

  @override
  String get attachmentUnsupported =>
      'Dieses Bildformat wird nicht unterstützt: Verwende ein JPEG-, PNG- oder WebP-Foto.';

  @override
  String get pause => 'Pausieren';

  @override
  String get resume => 'Fortsetzen';

  @override
  String deleteItemTitle(String name) {
    return '„$name“ löschen?';
  }

  @override
  String get deleteItemBody => 'Dies kann nicht rückgängig gemacht werden.';

  @override
  String get showPassword => 'Passwort anzeigen';

  @override
  String get hidePassword => 'Passwort ausblenden';

  @override
  String get fieldRequired => 'Erforderlich';

  @override
  String get noWalletForTransaction =>
      'Lege zuerst ein Konto an, um Transaktionen hinzuzufügen.';

  @override
  String get categoryGroceries => 'Lebensmittel';

  @override
  String get categoryRestaurants => 'Restaurants';

  @override
  String get categoryTransport => 'Verkehr';

  @override
  String get categoryHousing => 'Wohnen';

  @override
  String get categoryLeisure => 'Freizeit';

  @override
  String get categoryHealth => 'Gesundheit';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categorySalary => 'Gehalt';

  @override
  String get categoryGifts => 'Geschenke';

  @override
  String get categoryOther => 'Sonstiges';

  @override
  String get profileSection => 'Profil';

  @override
  String get displayName => 'Anzeigename';

  @override
  String get displayNameNotSet => 'Nicht festgelegt';

  @override
  String get displayNameHelp =>
      'Deine Freunde sehen diesen Namen. Deine E-Mail bleibt privat.';

  @override
  String get displayNameDialogTitle => 'Wie heißt du?';

  @override
  String get displayNameInvalid => 'Verwende 1 bis 40 Zeichen.';

  @override
  String get displayNameSaved => 'Name gespeichert';

  @override
  String get friendCode => 'Dein Freundescode';

  @override
  String get friendCodeHelp =>
      'Teile ihn, um Freundschaftsanfragen zu erhalten.';

  @override
  String get copyFriendCode => 'Code kopieren';

  @override
  String get friendCodeCopied => 'Code kopiert';

  @override
  String get regenerateFriendCode => 'Neuen Code erzeugen';

  @override
  String get regenerateFriendCodeBody =>
      'Dein aktueller Code funktioniert dann nicht mehr: Wer ihn hat, kann dir keine Anfragen mehr senden. Deine bisherigen Freunde bleiben.';

  @override
  String get friendCodeRegenerated => 'Neuer Freundescode bereit';

  @override
  String get profileLoadFailed =>
      'Dein Profil konnte nicht geladen werden. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get retry => 'Erneut versuchen';

  @override
  String get friendsTab => 'Freunde';

  @override
  String get friendsSignInPrompt =>
      'Melde dich an, um Freunde hinzuzufügen, zu chatten und Ausgaben zu teilen.';

  @override
  String get myQrCode => 'Mein QR-Code';

  @override
  String get addFriend => 'Freund hinzufügen';

  @override
  String get friendRequests => 'Anfragen';

  @override
  String get friendsSection => 'Deine Freunde';

  @override
  String get noFriendsYet =>
      'Noch keine Freunde. Lass einen Freund deinen QR-Code scannen oder scanne seinen.';

  @override
  String get incomingRequestSubtitle => 'Möchte mit dir befreundet sein';

  @override
  String get acceptRequest => 'Annehmen';

  @override
  String get declineRequest => 'Ablehnen';

  @override
  String get outgoingPending => 'Wartet auf Antwort';

  @override
  String get outgoingDeclined => 'Anfrage nicht angenommen';

  @override
  String get cancelRequest => 'Anfrage zurückziehen';

  @override
  String get removeFriend => 'Freund entfernen';

  @override
  String removeFriendBody(String name) {
    return '$name ist dann nicht mehr dein Freund. Ihr könnt euch später wieder hinzufügen.';
  }

  @override
  String get blockUser => 'Blockieren';

  @override
  String blockUserBody(String name) {
    return '$name kann dir dann keine Anfragen mehr senden und dich nicht mehr über deinen Code finden, und eure Freundschaft endet. Er oder sie wird nicht benachrichtigt.';
  }

  @override
  String get blockedSection => 'Blockiert';

  @override
  String get unblockUser => 'Freigeben';

  @override
  String get unnamedUser => 'Nutzer ohne Namen';

  @override
  String get myQrAddName => 'Namen hinzufügen';

  @override
  String get myQrHelp =>
      'Lass einen Freund diesen Code scannen: Seine Freundschaftsanfrage kommt dann bei dir an.';

  @override
  String get shareFriendCode => 'Teilen';

  @override
  String shareFriendCodeText(String link, String code) {
    return 'Füge mich bei nIpay hinzu: $link (Code $code)';
  }

  @override
  String get scanQrHint =>
      'Richte die Kamera auf den nIpay-QR-Code eines Freundes.';

  @override
  String get cameraUnavailable =>
      'Kamera nicht verfügbar. Erlaube den Zugriff in den Einstellungen oder gib den Code von Hand ein.';

  @override
  String get enterCodeManually => 'Oder gib den Code ein';

  @override
  String get findFriend => 'Suchen';

  @override
  String get invalidFriendCode => 'Das ist kein gültiger Freundescode.';

  @override
  String get notANipayQr => 'Dieser QR-Code ist kein nIpay-Freundescode.';

  @override
  String get friendCodeNoMatch => 'Niemand mit diesem Code gefunden.';

  @override
  String sendFriendRequestTitle(String name) {
    return 'Freundschaftsanfrage an $name senden?';
  }

  @override
  String get sendRequest => 'Anfrage senden';

  @override
  String friendRequestSent(String name) {
    return 'Anfrage an $name gesendet';
  }

  @override
  String nowFriends(String name) {
    return 'Du und $name seid jetzt Freunde';
  }

  @override
  String get friendsErrorNotAvailable => 'Diese Person ist nicht verfügbar.';

  @override
  String get friendsErrorCooldown =>
      'Diese Person hat deine Anfrage kürzlich abgelehnt. Versuche es in ein paar Tagen erneut.';

  @override
  String get friendsErrorTooManyPending =>
      'Du hast zu viele offene Anfragen. Ziehe einige zurück oder warte auf Antworten.';

  @override
  String get friendsErrorNotFound => 'Diese Anfrage ist nicht mehr verfügbar.';

  @override
  String get friendsLoadFailed =>
      'Deine Freunde konnten nicht geladen werden. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String friendRequestsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Freundschaftsanfragen',
      one: '1 Freundschaftsanfrage',
    );
    return '$_temp0';
  }

  @override
  String get chatSection => 'Chats';

  @override
  String get newGroup => 'Neue Gruppe';

  @override
  String get noChatsYet =>
      'Noch keine Chats. Tippe auf einen Freund, um einen zu beginnen.';

  @override
  String get chatsLoadFailed =>
      'Deine Chats konnten nicht geladen werden. Prüfe deine Verbindung und versuche es erneut.';

  @override
  String get messageHint => 'Nachricht';

  @override
  String get sendMessage => 'Senden';

  @override
  String get messageDeleted => 'Nachricht gelöscht';

  @override
  String get deletedUser => 'Gelöschter Nutzer';

  @override
  String get chatReadOnly => 'Du kannst in diesem Chat nicht mehr schreiben.';

  @override
  String get chatOffline =>
      'Du bist offline. Du kannst wieder schreiben, sobald du online bist.';

  @override
  String get loadEarlierMessages => 'Ältere Nachrichten laden';

  @override
  String get chatEmpty => 'Noch keine Nachrichten. Sag Hallo!';

  @override
  String chatYouPrefix(String text) {
    return 'Du: $text';
  }

  @override
  String get deleteMessage => 'Nachricht löschen';

  @override
  String get deleteMessageBody =>
      'Alle im Chat sehen dann „Nachricht gelöscht“.';

  @override
  String get reportAction => 'Melden';

  @override
  String get reportMessageTitle => 'Nachricht melden';

  @override
  String reportUserTitle(String name) {
    return '$name melden';
  }

  @override
  String get reportReasonLabel => 'Grund';

  @override
  String get reportChooseReason => 'Wähle einen Grund aus.';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonOffensive => 'Beleidigende Inhalte';

  @override
  String get reportReasonHarassment => 'Belästigung';

  @override
  String get reportReasonOther => 'Sonstiges';

  @override
  String get reportDetails => 'Details (optional)';

  @override
  String get reportAlsoBlock => 'Diese Person auch blockieren';

  @override
  String get reportSend => 'Meldung senden';

  @override
  String get reportSent => 'Meldung gesendet. Danke.';

  @override
  String get groupName => 'Gruppenname';

  @override
  String get chooseFriends => 'Freunde auswählen';

  @override
  String get createGroup => 'Gruppe erstellen';

  @override
  String get groupNeedsMembers => 'Wähle mindestens einen Freund aus.';

  @override
  String get groupNameInvalid => 'Verwende 1 bis 60 Zeichen.';

  @override
  String groupMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Mitglieder',
      one: '1 Mitglied',
    );
    return '$_temp0';
  }

  @override
  String get groupInfo => 'Gruppeninfo';

  @override
  String get groupAdmin => 'Admin';

  @override
  String get addMembers => 'Mitglieder hinzufügen';

  @override
  String get removeFromGroup => 'Aus der Gruppe entfernen';

  @override
  String removeFromGroupBody(String name) {
    return '$name sieht diese Gruppe dann nicht mehr.';
  }

  @override
  String get leaveGroup => 'Gruppe verlassen';

  @override
  String get leaveGroupBody =>
      'Du siehst die Nachrichten dieser Gruppe dann nicht mehr.';

  @override
  String get youLabel => 'Du';

  @override
  String get noFriendsToAdd => 'Alle deine Freunde sind schon in der Gruppe.';

  @override
  String get messageFriend => 'Nachricht schreiben';

  @override
  String get chatErrorInvalidMessage =>
      'Eine Nachricht hat 1 bis 2000 Zeichen.';

  @override
  String get chatErrorTooManyMembers =>
      'Eine Gruppe kann höchstens 50 Mitglieder haben.';

  @override
  String get chatErrorNotFound => 'Dieser Chat ist nicht mehr verfügbar.';

  @override
  String get chatErrorInvalidReport =>
      'Prüfe die Details: höchstens 500 Zeichen.';

  @override
  String unreadMessagesBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ungelesene Nachrichten',
      one: '1 ungelesene Nachricht',
    );
    return '$_temp0';
  }

  @override
  String get friendOut => 'An Freunde';

  @override
  String get friendIn => 'Von Freunden';

  @override
  String get shareWithFriends => 'Mit Freunden teilen';

  @override
  String get shareAddFriends => 'Freunde hinzufügen';

  @override
  String get shareWhoPaid => 'Wer hat bezahlt?';

  @override
  String get sharePaidByMe => 'Ich';

  @override
  String get shareSplitEqually => 'Zu gleichen Teilen';

  @override
  String get shareSplitCustom => 'Eigene Beträge';

  @override
  String shareRemaining(String amount) {
    return 'Noch $amount zu verteilen';
  }

  @override
  String shareExcess(String amount) {
    return '$amount zu viel';
  }

  @override
  String shareOwesYou(String name, String amount) {
    return '$name schuldet dir $amount';
  }

  @override
  String shareYouOwe(String name, String amount) {
    return 'Du schuldest $name $amount';
  }

  @override
  String shareYourShare(String amount) {
    return 'Dein Anteil: $amount';
  }

  @override
  String get shareNeedsConnection =>
      'Zum Teilen brauchst du eine Verbindung. Du kannst sie trotzdem als normale Ausgabe speichern.';

  @override
  String get shareSplitMismatch =>
      'Die Beträge müssen den Gesamtbetrag ergeben.';

  @override
  String get shareTooSmall =>
      'Der Betrag ist zu klein, um ihn auf alle aufzuteilen.';

  @override
  String get shareLinkedNote => 'Geteilte Ausgabe: Verwalte sie unter Freunde.';

  @override
  String get shareErrorInvalid =>
      'Prüfe die geteilte Ausgabe: Beträge, Währung und Freunde.';

  @override
  String get splitSection => 'Geteilte Ausgaben';

  @override
  String get splitTodo => 'Zu erledigen';

  @override
  String get splitBalances => 'Salden';

  @override
  String get splitRecent => 'Neueste';

  @override
  String balanceOwesYou(String amount) {
    return 'Schuldet dir $amount';
  }

  @override
  String balanceYouOwe(String amount) {
    return 'Du schuldest $amount';
  }

  @override
  String get settleAction => 'Begleichen';

  @override
  String settleTitle(String name) {
    return '$name zurückzahlen';
  }

  @override
  String settleAmountMax(String amount) {
    return 'Höchstens $amount: so viel schuldest du.';
  }

  @override
  String settleRecorded(String name) {
    return 'Erfasst. Es zählt, sobald $name bestätigt.';
  }

  @override
  String settleIncoming(String name, String amount) {
    return '$name sagt, dir $amount gegeben zu haben';
  }

  @override
  String get settleReceived => 'Erhalten';

  @override
  String get settleNotReceived => 'Nicht erhalten';

  @override
  String settleWaiting(String name, String amount) {
    return 'Warte darauf, dass $name $amount bestätigt';
  }

  @override
  String settleDeclined(String name, String amount) {
    return '$name hat $amount nicht bestätigt';
  }

  @override
  String registerShareItem(String description, String amount) {
    return 'Dein Anteil an „$description“: $amount';
  }

  @override
  String registerSettlementOut(String name, String amount) {
    return 'Rückzahlung an $name bestätigt: $amount';
  }

  @override
  String registerSettlementIn(String name, String amount) {
    return 'Rückzahlung von $name: $amount';
  }

  @override
  String get registerAction => 'Erfassen';

  @override
  String get registerTitle => 'In einem Konto erfassen';

  @override
  String registerConverted(String amount) {
    return 'In diesem Konto: $amount';
  }

  @override
  String get registerDone => 'Im Konto erfasst.';

  @override
  String get sharedExpenseFallbackTitle => 'Geteilte Ausgabe';

  @override
  String sharedExpensePaidBy(String name, String amount) {
    return 'Bezahlt von $name · dein Anteil $amount';
  }

  @override
  String sharedExpensePaidByYou(String amount) {
    return 'Von dir bezahlt · dein Anteil $amount';
  }

  @override
  String get splitLocked =>
      'Jemand hat seinen Anteil schon erfasst: Sie kann nicht mehr geändert werden.';

  @override
  String get splitNotFound => 'Das gibt es nicht mehr.';

  @override
  String get settleTooMuch => 'Das ist mehr, als du schuldest.';

  @override
  String get editSharedExpense => 'Geteilte Ausgabe bearbeiten';

  @override
  String get deleteSharedExpenseBody =>
      'Sie verschwindet für alle, zusammen mit deinen Buchungen im Konto.';

  @override
  String splitTodoBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count geteilte Ausgaben zu erledigen',
      one: '1 geteilte Ausgabe zu erledigen',
    );
    return '$_temp0';
  }
}
