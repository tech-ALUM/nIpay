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
  String get account => 'Compte';

  @override
  String get accountLocalModeDescription =>
      'Vous n\'êtes pas connecté : vos données restent uniquement sur cet appareil. Connectez-vous pour les synchroniser entre vos appareils.';

  @override
  String get signIn => 'Se connecter';

  @override
  String get signUp => 'S\'inscrire';

  @override
  String get signOut => 'Se déconnecter';

  @override
  String get email => 'E-mail';

  @override
  String get password => 'Mot de passe';

  @override
  String get confirmSignOut =>
      'Se déconnecter de votre compte ? Vos données restent sur cet appareil, mais elles ne pourront être rouvertes qu\'en vous reconnectant avec ce compte.';

  @override
  String get noAccountYet => 'Pas encore de compte ? Inscrivez-vous';

  @override
  String get alreadyHaveAccount => 'Déjà un compte ? Connectez-vous';

  @override
  String get forgotPassword => 'Mot de passe oublié ?';

  @override
  String get resetPasswordSent =>
      'E-mail de réinitialisation du mot de passe envoyé — consultez votre boîte de réception.';

  @override
  String signedInAs(String email) {
    return 'Connecté en tant que $email';
  }

  @override
  String get invalidEmail => 'Saisissez une adresse e-mail valide';

  @override
  String get passwordTooShort =>
      'Le mot de passe doit comporter au moins 8 caractères';

  @override
  String get changePassword => 'Changer le mot de passe';

  @override
  String get newPassword => 'Nouveau mot de passe';

  @override
  String get confirmPassword => 'Confirmer le mot de passe';

  @override
  String get passwordsDontMatch => 'Les mots de passe ne correspondent pas';

  @override
  String get passwordChanged =>
      'Mot de passe modifié. Les autres appareils ont été déconnectés.';

  @override
  String get syncNow => 'Synchroniser maintenant';

  @override
  String get syncComplete => 'Synchronisation terminée';

  @override
  String get syncFailed =>
      'Échec de la synchronisation. Vérifiez votre connexion et réessayez.';

  @override
  String get deleteAccount => 'Supprimer le compte';

  @override
  String get deleteAccountConfirmBody =>
      'Votre compte et ses données dans le cloud seront définitivement supprimés dans 30 jours. D\'ici là, vous pouvez annuler depuis cet écran. Les données de cet appareil ne sont pas supprimées.';

  @override
  String get deleteAccountRequested =>
      'Suppression du compte demandée. Vous avez 30 jours pour annuler.';

  @override
  String deletionPending(String date) {
    return 'Suppression du compte prévue le $date.';
  }

  @override
  String get cancelDeletion => 'Annuler la suppression';

  @override
  String get deletionCanceled => 'Suppression du compte annulée.';

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
  String get currentPassword => 'Mot de passe actuel';

  @override
  String get wrongCurrentPassword => 'Le mot de passe actuel est incorrect.';

  @override
  String get confirmWithPassword =>
      'Saisissez votre mot de passe pour confirmer.';

  @override
  String get passwordTooWeak =>
      'Utilisez au moins 12 caractères, avec des lettres et des chiffres.';

  @override
  String get signOutEverywhere => 'Se déconnecter de tous les appareils';

  @override
  String get signOutEverywhereConfirmBody =>
      'Toutes les sessions de ce compte seront fermées, y compris celle-ci. Utilisez cette option si un appareil a été perdu ou volé. Les données de cet appareil restent ici.';

  @override
  String get signedOutEverywhere => 'Déconnecté de tous les appareils.';

  @override
  String get authErrorInvalidCredentials =>
      'E-mail ou mot de passe invalide, ou e-mail pas encore confirmé.';

  @override
  String get authErrorWeakPassword =>
      'Ce mot de passe n\'est pas accepté : choisissez-en un plus long et moins courant.';

  @override
  String get authErrorSamePassword =>
      'Le nouveau mot de passe doit être différent de l\'actuel.';

  @override
  String get authErrorRateLimited =>
      'Trop de tentatives. Patientez quelques minutes et réessayez.';

  @override
  String get authErrorReauthRequired =>
      'Par sécurité, saisissez à nouveau votre mot de passe et réessayez.';

  @override
  String get authErrorNetwork =>
      'Impossible de joindre le serveur. Vérifiez votre connexion et réessayez.';

  @override
  String get authErrorGeneric =>
      'Une erreur s\'est produite. Veuillez réessayer.';

  @override
  String get resetPasswordTitle => 'Définir un nouveau mot de passe';

  @override
  String get passwordResetDone =>
      'Mot de passe mis à jour. Les autres appareils ont été déconnectés.';

  @override
  String get resetPasswordCooldown =>
      'Patientez une minute avant de demander un autre e-mail.';

  @override
  String lastSyncAt(String date) {
    return 'Dernière synchronisation : $date';
  }

  @override
  String get lastSyncNever => 'Pas encore synchronisé';

  @override
  String get syncLastFailed =>
      'La dernière synchronisation a échoué : elle sera relancée automatiquement.';

  @override
  String syncIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count éléments n\'ont pas pu être synchronisés et seront réessayés.',
      one: '1 élément n\'a pas pu être synchronisé et sera réessayé.',
    );
    return '$_temp0';
  }

  @override
  String get lockedDataTitle => 'Données verrouillées';

  @override
  String lockedDataBody(String email) {
    return 'Cet appareil contient les données de $email. Connectez-vous avec ce compte pour les voir, ou supprimez-les de cet appareil.';
  }

  @override
  String get lockedDataBodyUnknownOwner =>
      'Cet appareil contient les données d\'un compte qui n\'est pas connecté. Connectez-vous avec ce compte pour les voir, ou supprimez-les de cet appareil.';

  @override
  String get lockedDataOtherAccountBody =>
      'Cet appareil contient les données d\'un autre compte. Pour utiliser ce compte ici, supprimez ces données de l\'appareil (ouvrez Compte) ou déconnectez-vous.';

  @override
  String get startupError =>
      'Impossible d\'ouvrir vos données. Redémarrez l\'application ; si le problème persiste, contactez l\'assistance.';

  @override
  String get attachmentUnsupported =>
      'Ce format d\'image n\'est pas pris en charge : utilisez une photo JPEG, PNG ou WebP.';

  @override
  String get pause => 'Mettre en pause';

  @override
  String get resume => 'Reprendre';

  @override
  String deleteItemTitle(String name) {
    return 'Supprimer « $name » ?';
  }

  @override
  String get deleteItemBody => 'Cette action est irréversible.';

  @override
  String get showPassword => 'Afficher le mot de passe';

  @override
  String get hidePassword => 'Masquer le mot de passe';

  @override
  String get fieldRequired => 'Obligatoire';

  @override
  String get noWalletForTransaction =>
      'Créez d\'abord un portefeuille pour ajouter des transactions.';

  @override
  String get categoryGroceries => 'Courses';

  @override
  String get categoryRestaurants => 'Restaurants';

  @override
  String get categoryTransport => 'Transports';

  @override
  String get categoryHousing => 'Logement';

  @override
  String get categoryLeisure => 'Loisirs';

  @override
  String get categoryHealth => 'Santé';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categorySalary => 'Salaire';

  @override
  String get categoryGifts => 'Cadeaux';

  @override
  String get categoryOther => 'Autre';
}
