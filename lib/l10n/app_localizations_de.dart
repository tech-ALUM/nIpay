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
      'You\'re not signed in: your data stays on this device only. Sign in to sync it across devices.';

  @override
  String get signIn => 'Sign in';

  @override
  String get signUp => 'Sign up';

  @override
  String get signOut => 'Sign out';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmSignOut =>
      'Sign out of your account? Your data stays on this device, but it can only be opened again by signing in with this account.';

  @override
  String get noAccountYet => 'Don\'t have an account? Sign up';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get resetPasswordSent =>
      'Password reset email sent — check your inbox.';

  @override
  String signedInAs(String email) {
    return 'Signed in as $email';
  }

  @override
  String get invalidEmail => 'Enter a valid email address';

  @override
  String get passwordTooShort => 'Password must be at least 8 characters';

  @override
  String get changePassword => 'Change password';

  @override
  String get newPassword => 'New password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get passwordsDontMatch => 'Passwords don\'t match';

  @override
  String get passwordChanged =>
      'Password changed. Other devices have been signed out.';

  @override
  String get syncNow => 'Sync now';

  @override
  String get syncComplete => 'Sync complete';

  @override
  String get syncFailed => 'Sync failed. Check your connection and try again.';

  @override
  String get deleteAccount => 'Delete account';

  @override
  String get deleteAccountConfirmBody =>
      'Your account and its cloud data will be permanently deleted in 30 days. Until then you can cancel from this screen. The data on this device is not deleted.';

  @override
  String get deleteAccountRequested =>
      'Account deletion requested. You have 30 days to cancel.';

  @override
  String deletionPending(String date) {
    return 'Account scheduled for deletion on $date.';
  }

  @override
  String get cancelDeletion => 'Cancel deletion';

  @override
  String get deletionCanceled => 'Account deletion canceled.';

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
  String get currentPassword => 'Current password';

  @override
  String get wrongCurrentPassword => 'The current password is not correct.';

  @override
  String get confirmWithPassword => 'Enter your password to confirm.';

  @override
  String get passwordTooWeak =>
      'Use at least 12 characters, with letters and numbers.';

  @override
  String get signOutEverywhere => 'Sign out of all devices';

  @override
  String get signOutEverywhereConfirmBody =>
      'Every session of this account will be closed, including this one. Use it if a device was lost or stolen. Data on this device stays here.';

  @override
  String get signedOutEverywhere => 'Signed out of all devices.';

  @override
  String get authErrorInvalidCredentials =>
      'Invalid email or password, or email not confirmed yet.';

  @override
  String get authErrorWeakPassword =>
      'This password isn\'t accepted: choose a longer, less common one.';

  @override
  String get authErrorSamePassword =>
      'The new password must be different from the current one.';

  @override
  String get authErrorRateLimited =>
      'Too many attempts. Wait a few minutes and try again.';

  @override
  String get authErrorReauthRequired =>
      'For security, enter your password again and retry.';

  @override
  String get authErrorNetwork =>
      'Can\'t reach the server. Check your connection and try again.';

  @override
  String get authErrorGeneric => 'Something went wrong. Please try again.';

  @override
  String get resetPasswordTitle => 'Set a new password';

  @override
  String get passwordResetDone =>
      'Password updated. Other devices have been signed out.';

  @override
  String get resetPasswordCooldown =>
      'Wait a minute before requesting another email.';

  @override
  String lastSyncAt(String date) {
    return 'Last sync: $date';
  }

  @override
  String get lastSyncNever => 'Not synced yet';

  @override
  String get syncLastFailed =>
      'The last sync failed: it will be retried automatically.';

  @override
  String syncIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items couldn\'t be synced and will be retried.',
      one: '1 item couldn\'t be synced and will be retried.',
    );
    return '$_temp0';
  }

  @override
  String get lockedDataTitle => 'Data locked';

  @override
  String lockedDataBody(String email) {
    return 'This device holds the data of $email. Sign in with that account to see it, or remove it from this device.';
  }

  @override
  String get lockedDataBodyUnknownOwner =>
      'This device holds the data of an account that is not signed in. Sign in with that account to see it, or remove it from this device.';

  @override
  String get lockedDataOtherAccountBody =>
      'This device holds the data of a different account. To use this account here, remove that data from the device (open Account), or sign out.';

  @override
  String get startupError =>
      'Couldn\'t open your data. Restart the app; if it keeps happening, contact support.';

  @override
  String get attachmentUnsupported =>
      'This image format isn\'t supported: use a JPEG, PNG or WebP photo.';
}
