// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Hindi (`hi`).
class AppLocalizationsHi extends AppLocalizations {
  AppLocalizationsHi([String locale = 'hi']) : super(locale);

  @override
  String get appTitle => 'nIpay';

  @override
  String get homeTab => 'होम';

  @override
  String get transactionsTab => 'लेन-देन';

  @override
  String get statsTab => 'आंकड़े';

  @override
  String get settingsTab => 'अधिक';

  @override
  String get totalBalance => 'कुल शेष राशि';

  @override
  String get thisMonth => 'इस महीने';

  @override
  String get wallets => 'वॉलेट';

  @override
  String get newWallet => 'नया वॉलेट';

  @override
  String get walletName => 'नाम';

  @override
  String get currency => 'मुद्रा';

  @override
  String get walletNameDuplicate => 'इस नाम का वॉलेट पहले से मौजूद है';

  @override
  String get walletNameRequired => 'वॉलेट का नाम दर्ज करें';

  @override
  String get initialBalance => 'प्रारंभिक शेष राशि';

  @override
  String get recentTransactions => 'हाल के लेन-देन';

  @override
  String get noTransactions =>
      'अभी तक कोई लेन-देन नहीं। पहला जोड़ने के लिए + टैप करें।';

  @override
  String get noWallets => 'शुरू करने के लिए अपना पहला वॉलेट बनाएं।';

  @override
  String get newTransaction => 'नया लेन-देन';

  @override
  String get expense => 'खर्च';

  @override
  String get income => 'आय';

  @override
  String get transfer => 'स्थानांतरण';

  @override
  String get amount => 'राशि';

  @override
  String get invalidAmount => 'अमान्य राशि';

  @override
  String get exchangeRateError =>
      'विनिमय दर प्राप्त नहीं हो सकी: कनेक्शन जाँचें और फिर से प्रयास करें';

  @override
  String convertedPreview(String amount) {
    return '≈ $amount मौजूदा दर पर';
  }

  @override
  String get description => 'विवरण';

  @override
  String get category => 'श्रेणी';

  @override
  String get wallet => 'वॉलेट';

  @override
  String get fromWallet => 'से';

  @override
  String get toWallet => 'तक';

  @override
  String get date => 'तारीख';

  @override
  String get save => 'सहेजें';

  @override
  String get apply => 'लागू करें';

  @override
  String get cancel => 'रद्द करें';

  @override
  String get delete => 'हटाएं';

  @override
  String get deleteWalletTitle => 'वॉलेट हटाएं?';

  @override
  String deleteWalletBody(String name) {
    return 'पुष्टि करने के लिए, नीचे दिए गए बॉक्स में \"$name\" टाइप करें। यह पूर्ववत नहीं किया जा सकता।';
  }

  @override
  String get allWallets => 'सभी वॉलेट';

  @override
  String get allCategories => 'सभी श्रेणियां';

  @override
  String get searchTransactions => 'लेन-देन खोजें…';

  @override
  String get receipt => 'रसीद';

  @override
  String get fromCamera => 'कैमरा';

  @override
  String get fromGallery => 'गैलरी';

  @override
  String get attachments => 'अटैचमेंट';

  @override
  String get transactionDetail => 'लेन-देन';

  @override
  String get deleteTransaction => 'लेन-देन हटाएं';

  @override
  String get addCard => 'कार्ड जोड़ें';

  @override
  String get cardCategoryDonut => 'श्रेणी अनुसार खर्च';

  @override
  String get cardTrend => '6 महीने का रुझान';

  @override
  String get cardCashflow => 'नकदी प्रवाह';

  @override
  String get cardBudget => 'बजट';

  @override
  String get netLabel => 'शुद्ध';

  @override
  String get noStatsData => 'इस अवधि के लिए कोई डेटा नहीं है।';

  @override
  String get emptyDashboard => 'अपना डैशबोर्ड बनाएं: अपना पहला कार्ड जोड़ें।';

  @override
  String get customization => 'अनुकूलन';

  @override
  String get budgets => 'बजट';

  @override
  String get newBudget => 'नया बजट';

  @override
  String get monthlyLimit => 'मासिक सीमा';

  @override
  String get recurring => 'आवर्ती';

  @override
  String get newRecurring => 'नया आवर्ती लेन-देन';

  @override
  String get frequency => 'आवृत्ति';

  @override
  String get freqDaily => 'दैनिक';

  @override
  String get freqWeekly => 'साप्ताहिक';

  @override
  String get freqMonthly => 'मासिक';

  @override
  String get freqYearly => 'वार्षिक';

  @override
  String get startDate => 'प्रारंभ तिथि';

  @override
  String get nextRun => 'अगला';

  @override
  String get paused => 'रोका गया';

  @override
  String budgetNear(String category, int percent) {
    return '$category बजट $percent% पर';
  }

  @override
  String budgetExceeded(String category) {
    return '$category बजट पार हो गया!';
  }

  @override
  String get manageCategories => 'श्रेणियां';

  @override
  String get manageTags => 'टैग';

  @override
  String get manageCustomFields => 'कस्टम फ़ील्ड';

  @override
  String get newCategory => 'नई श्रेणी';

  @override
  String get editCategory => 'श्रेणी संपादित करें';

  @override
  String get icon => 'आइकन (इमोजी)';

  @override
  String get color => 'रंग';

  @override
  String get kindBoth => 'दोनों';

  @override
  String get newTag => 'नया टैग';

  @override
  String get tagNameRequired => 'एक टैग नाम दर्ज करें';

  @override
  String get tagNameDuplicate => 'इस नाम का टैग पहले से मौजूद है';

  @override
  String get costCenterNameRequired => 'लागत केंद्र का नाम दर्ज करें';

  @override
  String get tagName => 'टैग नाम';

  @override
  String get newField => 'नया फ़ील्ड';

  @override
  String get fieldName => 'फ़ील्ड नाम';

  @override
  String get fieldType => 'प्रकार';

  @override
  String get typeText => 'टेक्स्ट';

  @override
  String get typeNumber => 'संख्या';

  @override
  String get typeChoice => 'विकल्प';

  @override
  String get typeDate => 'तारीख';

  @override
  String get choiceOptions => 'विकल्प (अल्पविराम से अलग)';

  @override
  String get tags => 'टैग';

  @override
  String get customFields => 'कस्टम फ़ील्ड';

  @override
  String get allTags => 'सभी टैग';

  @override
  String get noItems => 'अभी यहां कुछ नहीं है।';

  @override
  String get expenseReport => 'व्यय रिपोर्ट';

  @override
  String get expenseReportFlag => 'व्यय रिपोर्ट';

  @override
  String get costCenter => 'लागत केंद्र';

  @override
  String get manageCostCenters => 'लागत केंद्र';

  @override
  String get newCostCenter => 'नया लागत केंद्र';

  @override
  String get reimbursable => 'प्रतिपूर्ति योग्य';

  @override
  String get eInvoice => 'ई-इनवॉइस';

  @override
  String get pendingReimbursement => 'प्रतिपूर्ति के लिए लंबित';

  @override
  String get exportPdf => 'PDF निर्यात करें';

  @override
  String get createReport => 'व्यय रिपोर्ट बनाएं';

  @override
  String get reportName => 'रिपोर्ट नाम';

  @override
  String get statusDraft => 'ड्राफ्ट';

  @override
  String get statusSent => 'भेजा गया';

  @override
  String get statusReimbursed => 'प्रतिपूर्ति की गई';

  @override
  String get markSent => 'भेजा गया के रूप में चिह्नित करें';

  @override
  String get markReimbursed => 'प्रतिपूर्ति के रूप में चिह्नित करें';

  @override
  String get reportArchive => 'संग्रह';

  @override
  String get flaggedExpenses => 'चिह्नित खर्च';

  @override
  String get expenseReportOnlyField => 'केवल व्यय रिपोर्ट के लिए';

  @override
  String get edit => 'संपादित करें';

  @override
  String get editTransaction => 'लेन-देन संपादित करें';

  @override
  String get fromDate => 'से';

  @override
  String get toDate => 'तक';

  @override
  String get none => 'कोई नहीं';

  @override
  String get language => 'भाषा';

  @override
  String get settingsTheme => 'थीम';

  @override
  String get themeSystem => 'सिस्टम';

  @override
  String get themeLight => 'लाइट';

  @override
  String get themeDark => 'डार्क';

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
  String get signOutRemoveLocalData => 'इस डिवाइस से डेटा हटाएँ';

  @override
  String get signOutRemoveLocalDataHint =>
      'आपका डेटा पहले आपके खाते में सिंक होगा, फिर इस डिवाइस से हटाया जाएगा। रसीदों की फ़ोटो अभी सिंक नहीं होतीं और खो जाएँगी।';

  @override
  String get signOutSyncFailed =>
      'डेटा हटाने से पहले सिंक नहीं हो सका। कुछ भी नहीं हटाया गया और आप अभी भी साइन इन हैं: अपना कनेक्शन जाँचें और फिर से कोशिश करें।';

  @override
  String get localDataRemoved => 'इस डिवाइस से डेटा हटा दिया गया';

  @override
  String get foreignLocalDataBody =>
      'इस डिवाइस पर किसी दूसरे खाते का डेटा है, इसलिए उसे अलग रखने के लिए सिंक रोक दिया गया है। इस खाते को सिंक करने के लिए वह डेटा हटाएँ, या साइन आउट करें।';

  @override
  String get removeLocalDataAndSync => 'डेटा हटाएँ और सिंक करें';

  @override
  String get removeForeignLocalDataConfirmBody =>
      'इस डिवाइस के सभी वॉलेट, लेन-देन और रसीदों की फ़ोटो मिटा दी जाएँगी। दूसरे खाते ने जो पहले ही सिंक किया है, वह उसी खाते में सुरक्षित रहेगा। जारी रखें?';

  @override
  String get syncBlockedForeignData =>
      'सिंक रुका हुआ है: इस डिवाइस पर किसी दूसरे खाते का डेटा है।';

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
