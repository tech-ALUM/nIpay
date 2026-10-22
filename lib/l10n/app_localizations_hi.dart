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
  String get account => 'खाता';

  @override
  String get accountLocalModeDescription =>
      'आपने साइन इन नहीं किया है: आपका डेटा केवल इसी डिवाइस पर रहता है। इसे सभी डिवाइस पर सिंक करने के लिए साइन इन करें।';

  @override
  String get signIn => 'साइन इन करें';

  @override
  String get signUp => 'साइन अप करें';

  @override
  String get signOut => 'साइन आउट करें';

  @override
  String get email => 'ईमेल';

  @override
  String get password => 'पासवर्ड';

  @override
  String get confirmSignOut =>
      'क्या आप अपने खाते से साइन आउट करना चाहते हैं? आपका डेटा इसी डिवाइस पर रहेगा, लेकिन इसे फिर से केवल इसी खाते से साइन इन करके खोला जा सकेगा।';

  @override
  String get noAccountYet => 'खाता नहीं है? साइन अप करें';

  @override
  String get alreadyHaveAccount => 'पहले से खाता है? साइन इन करें';

  @override
  String get forgotPassword => 'पासवर्ड भूल गए?';

  @override
  String get resetPasswordSent =>
      'पासवर्ड रीसेट ईमेल भेज दिया गया है — अपना इनबॉक्स देखें।';

  @override
  String signedInAs(String email) {
    return '$email के रूप में साइन इन किया गया';
  }

  @override
  String get invalidEmail => 'एक मान्य ईमेल पता दर्ज करें';

  @override
  String get passwordTooShort => 'पासवर्ड में कम से कम 8 अक्षर होने चाहिए';

  @override
  String get changePassword => 'पासवर्ड बदलें';

  @override
  String get newPassword => 'नया पासवर्ड';

  @override
  String get confirmPassword => 'पासवर्ड की पुष्टि करें';

  @override
  String get passwordsDontMatch => 'पासवर्ड मेल नहीं खाते';

  @override
  String get passwordChanged =>
      'पासवर्ड बदल दिया गया। अन्य डिवाइस से साइन आउट कर दिया गया है।';

  @override
  String get syncNow => 'अभी सिंक करें';

  @override
  String get syncComplete => 'सिंक पूरा हुआ';

  @override
  String get syncFailed =>
      'सिंक विफल रहा। अपना कनेक्शन जांचें और फिर से कोशिश करें।';

  @override
  String get deleteAccount => 'खाता हटाएं';

  @override
  String get deleteAccountConfirmBody =>
      'आपका खाता और उसका क्लाउड डेटा 30 दिनों में स्थायी रूप से हटा दिया जाएगा। तब तक आप इसी स्क्रीन से रद्द कर सकते हैं। इस डिवाइस का डेटा नहीं हटाया जाता।';

  @override
  String get deleteAccountRequested =>
      'खाता हटाने का अनुरोध किया गया। रद्द करने के लिए आपके पास 30 दिन हैं।';

  @override
  String deletionPending(String date) {
    return 'खाता $date को हटाया जाना निर्धारित है।';
  }

  @override
  String get cancelDeletion => 'हटाना रद्द करें';

  @override
  String get deletionCanceled => 'खाता हटाना रद्द कर दिया गया।';

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
  String get currentPassword => 'वर्तमान पासवर्ड';

  @override
  String get wrongCurrentPassword => 'वर्तमान पासवर्ड सही नहीं है।';

  @override
  String get confirmWithPassword =>
      'पुष्टि करने के लिए अपना पासवर्ड दर्ज करें।';

  @override
  String get passwordTooWeak =>
      'कम से कम 12 अक्षरों का उपयोग करें, जिनमें अक्षर और अंक दोनों हों।';

  @override
  String get signOutEverywhere => 'सभी डिवाइस से साइन आउट करें';

  @override
  String get signOutEverywhereConfirmBody =>
      'इस खाते के सभी सत्र बंद कर दिए जाएंगे, इसमें यह सत्र भी शामिल है। अगर कोई डिवाइस खो गया है या चोरी हो गया है, तो इसका उपयोग करें। इस डिवाइस का डेटा यहीं रहेगा।';

  @override
  String get signedOutEverywhere => 'सभी डिवाइस से साइन आउट कर दिया गया।';

  @override
  String get authErrorInvalidCredentials =>
      'ईमेल या पासवर्ड अमान्य है, या ईमेल की अभी पुष्टि नहीं हुई है।';

  @override
  String get authErrorWeakPassword =>
      'यह पासवर्ड स्वीकार नहीं किया गया: कोई लंबा और कम आम पासवर्ड चुनें।';

  @override
  String get authErrorSamePassword =>
      'नया पासवर्ड वर्तमान पासवर्ड से अलग होना चाहिए।';

  @override
  String get authErrorRateLimited =>
      'बहुत अधिक प्रयास। कुछ मिनट रुकें और फिर से कोशिश करें।';

  @override
  String get authErrorReauthRequired =>
      'सुरक्षा के लिए, अपना पासवर्ड फिर से दर्ज करें और दोबारा कोशिश करें।';

  @override
  String get authErrorNetwork =>
      'सर्वर तक नहीं पहुंचा जा सका। अपना कनेक्शन जांचें और फिर से कोशिश करें।';

  @override
  String get authErrorGeneric => 'कुछ गलत हो गया। कृपया फिर से कोशिश करें।';

  @override
  String get resetPasswordTitle => 'नया पासवर्ड सेट करें';

  @override
  String get passwordResetDone =>
      'पासवर्ड अपडेट हो गया। अन्य डिवाइस से साइन आउट कर दिया गया है।';

  @override
  String get resetPasswordCooldown =>
      'दूसरा ईमेल मांगने से पहले एक मिनट रुकें।';

  @override
  String lastSyncAt(String date) {
    return 'पिछला सिंक: $date';
  }

  @override
  String get lastSyncNever => 'अभी तक सिंक नहीं हुआ';

  @override
  String get syncLastFailed =>
      'पिछला सिंक विफल रहा: इसे अपने आप फिर से आज़माया जाएगा।';

  @override
  String syncIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count आइटम सिंक नहीं हो सके और उन्हें फिर से आज़माया जाएगा।',
      one: '1 आइटम सिंक नहीं हो सका और उसे फिर से आज़माया जाएगा।',
    );
    return '$_temp0';
  }

  @override
  String get lockedDataTitle => 'डेटा लॉक है';

  @override
  String lockedDataBody(String email) {
    return 'इस डिवाइस में $email का डेटा है। इसे देखने के लिए उस खाते से साइन इन करें, या इसे इस डिवाइस से हटा दें।';
  }

  @override
  String get lockedDataBodyUnknownOwner =>
      'इस डिवाइस में ऐसे खाते का डेटा है जिससे साइन इन नहीं किया गया है। इसे देखने के लिए उस खाते से साइन इन करें, या इसे इस डिवाइस से हटा दें।';

  @override
  String get lockedDataOtherAccountBody =>
      'इस डिवाइस में किसी दूसरे खाते का डेटा है। इस खाते का यहां उपयोग करने के लिए, उस डेटा को डिवाइस से हटाएं (खाता खोलें), या साइन आउट करें।';

  @override
  String get startupError =>
      'आपका डेटा नहीं खोला जा सका। ऐप को फिर से शुरू करें; अगर यह बार-बार हो, तो सहायता से संपर्क करें।';

  @override
  String get attachmentUnsupported =>
      'यह इमेज फ़ॉर्मेट समर्थित नहीं है: JPEG, PNG या WebP फ़ोटो का उपयोग करें।';

  @override
  String get pause => 'रोकें';

  @override
  String get resume => 'फिर से शुरू करें';

  @override
  String deleteItemTitle(String name) {
    return '\"$name\" हटाएं?';
  }

  @override
  String get deleteItemBody => 'यह पूर्ववत नहीं किया जा सकता।';

  @override
  String get showPassword => 'पासवर्ड दिखाएं';

  @override
  String get hidePassword => 'पासवर्ड छिपाएं';

  @override
  String get fieldRequired => 'आवश्यक';

  @override
  String get noWalletForTransaction =>
      'लेन-देन जोड़ने के लिए पहले एक वॉलेट बनाएं।';

  @override
  String get categoryGroceries => 'किराना';

  @override
  String get categoryRestaurants => 'रेस्टोरेंट';

  @override
  String get categoryTransport => 'परिवहन';

  @override
  String get categoryHousing => 'आवास';

  @override
  String get categoryLeisure => 'मनोरंजन';

  @override
  String get categoryHealth => 'स्वास्थ्य';

  @override
  String get categoryShopping => 'खरीदारी';

  @override
  String get categorySalary => 'वेतन';

  @override
  String get categoryGifts => 'उपहार';

  @override
  String get categoryOther => 'अन्य';
}
