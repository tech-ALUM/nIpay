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
}
