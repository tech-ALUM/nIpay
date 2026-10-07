// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'nIpay';

  @override
  String get homeTab => 'Accueil';

  @override
  String get transactionsTab => 'Transactions';

  @override
  String get statsTab => 'Statistiques';

  @override
  String get settingsTab => 'Plus';

  @override
  String get totalBalance => 'Solde total';

  @override
  String get thisMonth => 'ce mois-ci';

  @override
  String get wallets => 'Portefeuilles';

  @override
  String get newWallet => 'Nouveau portefeuille';

  @override
  String get walletName => 'Nom';

  @override
  String get currency => 'Devise';

  @override
  String get walletNameDuplicate => 'Un portefeuille porte déjà ce nom';

  @override
  String get walletNameRequired => 'Saisis un nom de portefeuille';

  @override
  String get initialBalance => 'Solde initial';

  @override
  String get recentTransactions => 'Transactions récentes';

  @override
  String get noTransactions =>
      'Aucune transaction pour l\'instant. Appuyez sur + pour ajouter la première.';

  @override
  String get noWallets => 'Créez votre premier portefeuille pour commencer.';

  @override
  String get newTransaction => 'Nouvelle transaction';

  @override
  String get expense => 'Dépense';

  @override
  String get income => 'Revenu';

  @override
  String get transfer => 'Virement';

  @override
  String get amount => 'Montant';

  @override
  String get invalidAmount => 'Montant invalide';

  @override
  String get exchangeRateError =>
      'Impossible d\'obtenir le taux de change : vérifiez votre connexion et réessayez';

  @override
  String convertedPreview(String amount) {
    return '≈ $amount au taux actuel';
  }

  @override
  String get description => 'Description';

  @override
  String get category => 'Catégorie';

  @override
  String get wallet => 'Portefeuille';

  @override
  String get fromWallet => 'De';

  @override
  String get toWallet => 'Vers';

  @override
  String get date => 'Date';

  @override
  String get save => 'Enregistrer';

  @override
  String get apply => 'Appliquer';

  @override
  String get cancel => 'Annuler';

  @override
  String get delete => 'Supprimer';

  @override
  String get deleteWalletTitle => 'Supprimer le portefeuille ?';

  @override
  String deleteWalletBody(String name) {
    return 'Pour confirmer, tapez « $name » dans le champ ci-dessous. Cette action est irréversible.';
  }

  @override
  String get allWallets => 'Tous les portefeuilles';

  @override
  String get allCategories => 'Toutes les catégories';

  @override
  String get searchTransactions => 'Rechercher des transactions…';

  @override
  String get receipt => 'Reçu';

  @override
  String get fromCamera => 'Appareil photo';

  @override
  String get fromGallery => 'Galerie';

  @override
  String get attachments => 'Pièces jointes';

  @override
  String get transactionDetail => 'Transaction';

  @override
  String get deleteTransaction => 'Supprimer la transaction';

  @override
  String get addCard => 'Ajouter une carte';

  @override
  String get cardCategoryDonut => 'Dépenses par catégorie';

  @override
  String get cardTrend => 'Tendance sur 6 mois';

  @override
  String get cardCashflow => 'Flux de trésorerie';

  @override
  String get cardBudget => 'Budget';

  @override
  String get netLabel => 'Net';

  @override
  String get noStatsData => 'Aucune donnée pour cette période.';

  @override
  String get emptyDashboard =>
      'Composez votre tableau de bord : ajoutez votre première carte.';

  @override
  String get customization => 'Personnalisation';

  @override
  String get budgets => 'Budget';

  @override
  String get newBudget => 'Nouveau budget';

  @override
  String get monthlyLimit => 'Plafond mensuel';

  @override
  String get recurring => 'Récurrentes';

  @override
  String get newRecurring => 'Nouvelle transaction récurrente';

  @override
  String get frequency => 'Fréquence';

  @override
  String get freqDaily => 'Quotidienne';

  @override
  String get freqWeekly => 'Hebdomadaire';

  @override
  String get freqMonthly => 'Mensuelle';

  @override
  String get freqYearly => 'Annuelle';

  @override
  String get startDate => 'Date de début';

  @override
  String get nextRun => 'Prochaine';

  @override
  String get paused => 'En pause';

  @override
  String budgetNear(String category, int percent) {
    return 'Budget $category à $percent %';
  }

  @override
  String budgetExceeded(String category) {
    return 'Budget $category dépassé !';
  }

  @override
  String get manageCategories => 'Catégories';

  @override
  String get manageTags => 'Tags';

  @override
  String get manageCustomFields => 'Champs personnalisés';

  @override
  String get newCategory => 'Nouvelle catégorie';

  @override
  String get editCategory => 'Modifier la catégorie';

  @override
  String get icon => 'Icône (emoji)';

  @override
  String get color => 'Couleur';

  @override
  String get kindBoth => 'Les deux';

  @override
  String get newTag => 'Nouveau tag';

  @override
  String get tagNameRequired => 'Saisissez un nom de tag';

  @override
  String get tagNameDuplicate => 'Un tag porte déjà ce nom';

  @override
  String get costCenterNameRequired => 'Saisissez un nom de centre de coût';

  @override
  String get tagName => 'Nom du tag';

  @override
  String get newField => 'Nouveau champ';

  @override
  String get fieldName => 'Nom du champ';

  @override
  String get fieldType => 'Type';

  @override
  String get typeText => 'Texte';

  @override
  String get typeNumber => 'Nombre';

  @override
  String get typeChoice => 'Choix';

  @override
  String get typeDate => 'Date';

  @override
  String get choiceOptions => 'Options (séparées par des virgules)';

  @override
  String get tags => 'Tags';

  @override
  String get customFields => 'Champs personnalisés';

  @override
  String get allTags => 'Tous les tags';

  @override
  String get noItems => 'Rien ici pour l\'instant.';

  @override
  String get expenseReport => 'Note de frais';

  @override
  String get expenseReportFlag => 'Note de frais';

  @override
  String get costCenter => 'Centre de coût';

  @override
  String get manageCostCenters => 'Centres de coût';

  @override
  String get newCostCenter => 'Nouveau centre de coût';

  @override
  String get reimbursable => 'Remboursable';

  @override
  String get eInvoice => 'Facture électronique';

  @override
  String get pendingReimbursement => 'À rembourser';

  @override
  String get exportPdf => 'Exporter en PDF';

  @override
  String get createReport => 'Créer une note de frais';

  @override
  String get reportName => 'Nom de la note';

  @override
  String get statusDraft => 'Brouillon';

  @override
  String get statusSent => 'Envoyée';

  @override
  String get statusReimbursed => 'Remboursée';

  @override
  String get markSent => 'Marquer comme envoyée';

  @override
  String get markReimbursed => 'Marquer comme remboursée';

  @override
  String get reportArchive => 'Archives';

  @override
  String get flaggedExpenses => 'Dépenses marquées';

  @override
  String get expenseReportOnlyField => 'Uniquement pour les notes de frais';

  @override
  String get edit => 'Modifier';

  @override
  String get editTransaction => 'Modifier la transaction';

  @override
  String get fromDate => 'Du';

  @override
  String get toDate => 'Au';

  @override
  String get none => 'Aucun';

  @override
  String get language => 'Langue';

  @override
  String get settingsTheme => 'Thème';

  @override
  String get themeSystem => 'Système';

  @override
  String get themeLight => 'Clair';

  @override
  String get themeDark => 'Sombre';

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
  String get signOutRemoveLocalData => 'Supprimer les données de cet appareil';

  @override
  String get signOutRemoveLocalDataHint =>
      'Vos données sont d\'abord synchronisées avec votre compte, puis supprimées de cet appareil. Les photos des reçus ne sont pas encore synchronisées et seront perdues.';

  @override
  String get signOutSyncFailed =>
      'La synchronisation avant la suppression a échoué. Rien n\'a été supprimé et vous êtes toujours connecté : vérifiez votre connexion et réessayez.';

  @override
  String get localDataRemoved => 'Données supprimées de cet appareil';

  @override
  String get foreignLocalDataBody =>
      'Cet appareil contient les données d\'un autre compte : la synchronisation est suspendue pour les garder séparées. Supprimez ces données pour synchroniser ce compte, ou déconnectez-vous.';

  @override
  String get removeLocalDataAndSync => 'Supprimer les données et synchroniser';

  @override
  String get removeForeignLocalDataConfirmBody =>
      'Tous les portefeuilles, transactions et photos de reçus de cet appareil seront supprimés. Ce que l\'autre compte a déjà synchronisé reste en sécurité dans ce compte. Continuer ?';

  @override
  String get syncBlockedForeignData =>
      'Synchronisation suspendue : cet appareil contient les données d\'un autre compte.';

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
