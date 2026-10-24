// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'nIpay';

  @override
  String get homeTab => 'الرئيسية';

  @override
  String get transactionsTab => 'المعاملات';

  @override
  String get statsTab => 'الإحصائيات';

  @override
  String get settingsTab => 'المزيد';

  @override
  String get totalBalance => 'الرصيد الإجمالي';

  @override
  String get thisMonth => 'هذا الشهر';

  @override
  String get wallets => 'المحافظ';

  @override
  String get newWallet => 'محفظة جديدة';

  @override
  String get walletName => 'الاسم';

  @override
  String get currency => 'العملة';

  @override
  String get walletNameDuplicate => 'توجد محفظة بهذا الاسم بالفعل';

  @override
  String get walletNameRequired => 'الرجاء إدخال اسم للمحفظة';

  @override
  String get initialBalance => 'الرصيد الابتدائي';

  @override
  String get recentTransactions => 'أحدث المعاملات';

  @override
  String get noTransactions => 'لا توجد معاملات بعد. اضغط على + لإضافة الأولى.';

  @override
  String get noWallets => 'أنشئ محفظتك الأولى للبدء.';

  @override
  String get newTransaction => 'معاملة جديدة';

  @override
  String get expense => 'مصروف';

  @override
  String get income => 'دخل';

  @override
  String get transfer => 'تحويل';

  @override
  String get amount => 'المبلغ';

  @override
  String get invalidAmount => 'مبلغ غير صالح';

  @override
  String get exchangeRateError =>
      'تعذر الحصول على سعر الصرف: تحقق من الاتصال وحاول مرة أخرى';

  @override
  String convertedPreview(String amount) {
    return '≈ $amount بالسعر الحالي';
  }

  @override
  String get description => 'الوصف';

  @override
  String get category => 'الفئة';

  @override
  String get wallet => 'المحفظة';

  @override
  String get fromWallet => 'من';

  @override
  String get toWallet => 'إلى';

  @override
  String get date => 'التاريخ';

  @override
  String get save => 'حفظ';

  @override
  String get apply => 'تطبيق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get delete => 'حذف';

  @override
  String get deleteWalletTitle => 'حذف المحفظة؟';

  @override
  String deleteWalletBody(String name) {
    return 'للتأكيد، اكتب \"$name\" في الحقل أدناه. لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get allWallets => 'جميع المحافظ';

  @override
  String get allCategories => 'جميع الفئات';

  @override
  String get searchTransactions => 'البحث في المعاملات…';

  @override
  String get receipt => 'إيصال';

  @override
  String get fromCamera => 'الكاميرا';

  @override
  String get fromGallery => 'المعرض';

  @override
  String get attachments => 'المرفقات';

  @override
  String get transactionDetail => 'المعاملة';

  @override
  String get deleteTransaction => 'حذف المعاملة';

  @override
  String get addCard => 'إضافة بطاقة';

  @override
  String get cardCategoryDonut => 'المصروفات حسب الفئة';

  @override
  String get cardTrend => 'اتجاه 6 أشهر';

  @override
  String get cardCashflow => 'التدفق النقدي';

  @override
  String get cardBudget => 'الميزانية';

  @override
  String get netLabel => 'الصافي';

  @override
  String get noStatsData => 'لا توجد بيانات لهذه الفترة.';

  @override
  String get emptyDashboard => 'صمّم لوحتك: أضف بطاقتك الأولى.';

  @override
  String get customization => 'التخصيص';

  @override
  String get budgets => 'الميزانية';

  @override
  String get newBudget => 'ميزانية جديدة';

  @override
  String get monthlyLimit => 'الحد الشهري';

  @override
  String get recurring => 'المتكررة';

  @override
  String get newRecurring => 'معاملة متكررة جديدة';

  @override
  String get frequency => 'التكرار';

  @override
  String get freqDaily => 'يومي';

  @override
  String get freqWeekly => 'أسبوعي';

  @override
  String get freqMonthly => 'شهري';

  @override
  String get freqYearly => 'سنوي';

  @override
  String get startDate => 'تاريخ البدء';

  @override
  String get nextRun => 'التالي';

  @override
  String get paused => 'متوقف مؤقتًا';

  @override
  String budgetNear(String category, int percent) {
    return 'ميزانية $category عند $percent%';
  }

  @override
  String budgetExceeded(String category) {
    return 'تم تجاوز ميزانية $category!';
  }

  @override
  String get manageCategories => 'الفئات';

  @override
  String get manageTags => 'الوسوم';

  @override
  String get manageCustomFields => 'الحقول المخصصة';

  @override
  String get newCategory => 'فئة جديدة';

  @override
  String get editCategory => 'تعديل الفئة';

  @override
  String get icon => 'أيقونة (رمز تعبيري)';

  @override
  String get color => 'اللون';

  @override
  String get kindBoth => 'كلاهما';

  @override
  String get newTag => 'وسم جديد';

  @override
  String get tagNameRequired => 'أدخل اسم الوسم';

  @override
  String get tagNameDuplicate => 'يوجد وسم بهذا الاسم بالفعل';

  @override
  String get costCenterNameRequired => 'أدخل اسم مركز التكلفة';

  @override
  String get tagName => 'اسم الوسم';

  @override
  String get newField => 'حقل جديد';

  @override
  String get fieldName => 'اسم الحقل';

  @override
  String get fieldType => 'النوع';

  @override
  String get typeText => 'نص';

  @override
  String get typeNumber => 'رقم';

  @override
  String get typeChoice => 'اختيار';

  @override
  String get typeDate => 'تاريخ';

  @override
  String get choiceOptions => 'الخيارات (مفصولة بفواصل)';

  @override
  String get tags => 'الوسوم';

  @override
  String get customFields => 'الحقول المخصصة';

  @override
  String get allTags => 'جميع الوسوم';

  @override
  String get noItems => 'لا شيء هنا بعد.';

  @override
  String get expenseReport => 'تقرير المصروفات';

  @override
  String get expenseReportFlag => 'تقرير المصروفات';

  @override
  String get costCenter => 'مركز التكلفة';

  @override
  String get manageCostCenters => 'مراكز التكلفة';

  @override
  String get newCostCenter => 'مركز تكلفة جديد';

  @override
  String get reimbursable => 'قابل للاسترداد';

  @override
  String get eInvoice => 'فاتورة إلكترونية';

  @override
  String get pendingReimbursement => 'بانتظار الاسترداد';

  @override
  String get exportPdf => 'تصدير PDF';

  @override
  String get createReport => 'إنشاء تقرير مصروفات';

  @override
  String get reportName => 'اسم التقرير';

  @override
  String get statusDraft => 'مسودة';

  @override
  String get statusSent => 'مُرسل';

  @override
  String get statusReimbursed => 'مسترد';

  @override
  String get markSent => 'وضع علامة كمُرسل';

  @override
  String get markReimbursed => 'وضع علامة كمسترد';

  @override
  String get reportArchive => 'الأرشيف';

  @override
  String get flaggedExpenses => 'المصروفات المُعلَّمة';

  @override
  String get expenseReportOnlyField => 'فقط لتقارير المصروفات';

  @override
  String get edit => 'تعديل';

  @override
  String get editTransaction => 'تعديل المعاملة';

  @override
  String get fromDate => 'من';

  @override
  String get toDate => 'إلى';

  @override
  String get none => 'لا شيء';

  @override
  String get language => 'اللغة';

  @override
  String get settingsTheme => 'المظهر';

  @override
  String get themeSystem => 'النظام';

  @override
  String get themeLight => 'فاتح';

  @override
  String get themeDark => 'داكن';

  @override
  String get account => 'الحساب';

  @override
  String get accountLocalModeDescription =>
      'أنت غير مسجّل الدخول: تبقى بياناتك على هذا الجهاز فقط. سجّل الدخول لمزامنتها بين أجهزتك.';

  @override
  String get signIn => 'تسجيل الدخول';

  @override
  String get signUp => 'إنشاء حساب';

  @override
  String get signOut => 'تسجيل الخروج';

  @override
  String get email => 'البريد الإلكتروني';

  @override
  String get password => 'كلمة المرور';

  @override
  String get confirmSignOut =>
      'هل تريد تسجيل الخروج من حسابك؟ تبقى بياناتك على هذا الجهاز، لكن لا يمكن فتحها مجددًا إلا بتسجيل الدخول بهذا الحساب.';

  @override
  String get noAccountYet => 'ليس لديك حساب؟ أنشئ حسابًا';

  @override
  String get alreadyHaveAccount => 'لديك حساب بالفعل؟ سجّل الدخول';

  @override
  String get forgotPassword => 'نسيت كلمة المرور؟';

  @override
  String get resetPasswordSent =>
      'تم إرسال رسالة إعادة تعيين كلمة المرور — تحقّق من بريدك.';

  @override
  String signedInAs(String email) {
    return 'تم تسجيل الدخول باسم $email';
  }

  @override
  String get invalidEmail => 'أدخل عنوان بريد إلكتروني صالحًا';

  @override
  String get passwordTooShort =>
      'يجب أن تتكوّن كلمة المرور من 8 أحرف على الأقل';

  @override
  String get changePassword => 'تغيير كلمة المرور';

  @override
  String get newPassword => 'كلمة المرور الجديدة';

  @override
  String get confirmPassword => 'تأكيد كلمة المرور';

  @override
  String get passwordsDontMatch => 'كلمتا المرور غير متطابقتين';

  @override
  String get passwordChanged =>
      'تم تغيير كلمة المرور. تم تسجيل الخروج من الأجهزة الأخرى.';

  @override
  String get syncNow => 'مزامنة الآن';

  @override
  String get syncComplete => 'اكتملت المزامنة';

  @override
  String get syncFailed => 'فشلت المزامنة. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get deleteAccount => 'حذف الحساب';

  @override
  String get deleteAccountConfirmBody =>
      'سيتم حذف حسابك وبياناته السحابية نهائيًا بعد 30 يومًا. ويمكنك الإلغاء من هذه الشاشة حتى ذلك الحين. لا تُحذف البيانات الموجودة على هذا الجهاز.';

  @override
  String get deleteAccountRequested =>
      'تم طلب حذف الحساب. لديك 30 يومًا للإلغاء.';

  @override
  String deletionPending(String date) {
    return 'الحساب مجدول للحذف في $date.';
  }

  @override
  String get cancelDeletion => 'إلغاء الحذف';

  @override
  String get deletionCanceled => 'تم إلغاء حذف الحساب.';

  @override
  String get signOutRemoveLocalData => 'إزالة البيانات من هذا الجهاز';

  @override
  String get signOutRemoveLocalDataHint =>
      'تتم مزامنة بياناتك مع حسابك أولًا، ثم تُزال من هذا الجهاز. صور الإيصالات لا تتم مزامنتها بعد وستُفقد.';

  @override
  String get signOutSyncFailed =>
      'تعذّرت المزامنة قبل إزالة البيانات. لم تتم إزالة أي شيء وما زلت مسجّل الدخول: تحقّق من الاتصال وحاول مرة أخرى.';

  @override
  String get localDataRemoved => 'تمت إزالة البيانات من هذا الجهاز';

  @override
  String get foreignLocalDataBody =>
      'يحتوي هذا الجهاز على بيانات حساب آخر، لذا أُوقفت المزامنة مؤقتًا لإبقائها منفصلة. أزل تلك البيانات لبدء مزامنة هذا الحساب، أو سجّل الخروج.';

  @override
  String get removeLocalDataAndSync => 'إزالة البيانات والمزامنة';

  @override
  String get removeForeignLocalDataConfirmBody =>
      'سيتم حذف جميع المحافظ والمعاملات وصور الإيصالات على هذا الجهاز. ما قام الحساب الآخر بمزامنته يبقى آمنًا في ذلك الحساب. هل تريد المتابعة؟';

  @override
  String get syncBlockedForeignData =>
      'المزامنة متوقفة مؤقتًا: يحتوي هذا الجهاز على بيانات حساب آخر.';

  @override
  String get currentPassword => 'كلمة المرور الحالية';

  @override
  String get wrongCurrentPassword => 'كلمة المرور الحالية غير صحيحة.';

  @override
  String get confirmWithPassword => 'أدخل كلمة المرور للتأكيد.';

  @override
  String get passwordTooWeak =>
      'استخدم 12 حرفًا على الأقل، تتضمّن أحرفًا وأرقامًا.';

  @override
  String get signOutEverywhere => 'تسجيل الخروج من جميع الأجهزة';

  @override
  String get signOutEverywhereConfirmBody =>
      'سيتم إغلاق جميع جلسات هذا الحساب، بما فيها هذه الجلسة. استخدم ذلك إذا فقدت جهازًا أو سُرق منك. تبقى البيانات الموجودة على هذا الجهاز هنا.';

  @override
  String get signedOutEverywhere => 'تم تسجيل الخروج من جميع الأجهزة.';

  @override
  String get authErrorInvalidCredentials =>
      'البريد الإلكتروني أو كلمة المرور غير صحيحين، أو لم يتم تأكيد البريد الإلكتروني بعد.';

  @override
  String get authErrorWeakPassword =>
      'لا تُقبل كلمة المرور هذه: اختر كلمة أطول وأقل شيوعًا.';

  @override
  String get authErrorSamePassword =>
      'يجب أن تختلف كلمة المرور الجديدة عن الحالية.';

  @override
  String get authErrorRateLimited =>
      'محاولات كثيرة جدًا. انتظر بضع دقائق ثم حاول مرة أخرى.';

  @override
  String get authErrorReauthRequired =>
      'لدواعٍ أمنية، أدخل كلمة المرور مرة أخرى وأعد المحاولة.';

  @override
  String get authErrorNetwork =>
      'تعذّر الوصول إلى الخادم. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get authErrorGeneric => 'حدث خطأ ما. حاول مرة أخرى.';

  @override
  String get resetPasswordTitle => 'تعيين كلمة مرور جديدة';

  @override
  String get passwordResetDone =>
      'تم تحديث كلمة المرور. تم تسجيل الخروج من الأجهزة الأخرى.';

  @override
  String get resetPasswordCooldown => 'انتظر دقيقة قبل طلب رسالة أخرى.';

  @override
  String lastSyncAt(String date) {
    return 'آخر مزامنة: $date';
  }

  @override
  String get lastSyncNever => 'لم تتم المزامنة بعد';

  @override
  String get syncLastFailed => 'فشلت آخر مزامنة: ستتم إعادة المحاولة تلقائيًا.';

  @override
  String syncIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تعذّرت مزامنة $count من العناصر وستتم إعادة المحاولة.',
      one: 'تعذّرت مزامنة عنصر واحد وستتم إعادة المحاولة.',
    );
    return '$_temp0';
  }

  @override
  String get lockedDataTitle => 'البيانات مقفلة';

  @override
  String lockedDataBody(String email) {
    return 'يحتوي هذا الجهاز على بيانات $email. سجّل الدخول بذلك الحساب لعرضها، أو احذفها من هذا الجهاز.';
  }

  @override
  String get lockedDataBodyUnknownOwner =>
      'يحتوي هذا الجهاز على بيانات حساب غير مسجّل الدخول. سجّل الدخول بذلك الحساب لعرضها، أو احذفها من هذا الجهاز.';

  @override
  String get lockedDataOtherAccountBody =>
      'يحتوي هذا الجهاز على بيانات حساب آخر. لاستخدام هذا الحساب هنا، احذف تلك البيانات من الجهاز (افتح الحساب)، أو سجّل الخروج.';

  @override
  String get startupError =>
      'تعذّر فتح بياناتك. أعد تشغيل التطبيق؛ وإذا تكرّر ذلك، فتواصل مع الدعم.';

  @override
  String get attachmentUnsupported =>
      'صيغة الصورة هذه غير مدعومة: استخدم صورة بصيغة JPEG أو PNG أو WebP.';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get resume => 'استئناف';

  @override
  String deleteItemTitle(String name) {
    return 'حذف \"$name\"؟';
  }

  @override
  String get deleteItemBody => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get showPassword => 'إظهار كلمة المرور';

  @override
  String get hidePassword => 'إخفاء كلمة المرور';

  @override
  String get fieldRequired => 'مطلوب';

  @override
  String get noWalletForTransaction => 'أنشئ محفظة أولاً لإضافة المعاملات.';

  @override
  String get categoryGroceries => 'بقالة';

  @override
  String get categoryRestaurants => 'مطاعم';

  @override
  String get categoryTransport => 'مواصلات';

  @override
  String get categoryHousing => 'السكن';

  @override
  String get categoryLeisure => 'ترفيه';

  @override
  String get categoryHealth => 'الصحة';

  @override
  String get categoryShopping => 'تسوق';

  @override
  String get categorySalary => 'الراتب';

  @override
  String get categoryGifts => 'هدايا';

  @override
  String get categoryOther => 'أخرى';

  @override
  String get profileSection => 'الملف الشخصي';

  @override
  String get displayName => 'الاسم المعروض';

  @override
  String get displayNameNotSet => 'غير محدد';

  @override
  String get displayNameHelp =>
      'يرى أصدقاؤك هذا الاسم. ويبقى بريدك الإلكتروني خاصًا.';

  @override
  String get displayNameDialogTitle => 'ما اسمك؟';

  @override
  String get displayNameInvalid => 'استخدم من 1 إلى 40 حرفًا.';

  @override
  String get displayNameSaved => 'تم حفظ الاسم';

  @override
  String get friendCode => 'رمز الصداقة الخاص بك';

  @override
  String get friendCodeHelp => 'شاركه لتلقي طلبات الصداقة.';

  @override
  String get copyFriendCode => 'نسخ الرمز';

  @override
  String get friendCodeCopied => 'تم نسخ الرمز';

  @override
  String get regenerateFriendCode => 'إنشاء رمز جديد';

  @override
  String get regenerateFriendCodeBody =>
      'سيتوقف رمزك الحالي عن العمل: لن يتمكن من لديه من إرسال طلبات إليك بعد الآن. ويبقى أصدقاؤك الحاليون.';

  @override
  String get friendCodeRegenerated => 'رمز الصداقة الجديد جاهز';

  @override
  String get profileLoadFailed =>
      'تعذّر تحميل ملفك الشخصي. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get friendsTab => 'الأصدقاء';

  @override
  String get friendsSignInPrompt =>
      'سجّل الدخول لإضافة أصدقاء والدردشة وتقسيم المصاريف.';

  @override
  String get myQrCode => 'رمز QR الخاص بي';

  @override
  String get addFriend => 'إضافة صديق';

  @override
  String get friendRequests => 'الطلبات';

  @override
  String get friendsSection => 'أصدقاؤك';

  @override
  String get noFriendsYet =>
      'لا يوجد أصدقاء بعد. دع صديقًا يمسح رمز QR الخاص بك، أو امسح رمزه.';

  @override
  String get incomingRequestSubtitle => 'يريد أن يكون صديقك';

  @override
  String get acceptRequest => 'قبول';

  @override
  String get declineRequest => 'رفض';

  @override
  String get outgoingPending => 'بانتظار الرد';

  @override
  String get outgoingDeclined => 'لم يُقبل الطلب';

  @override
  String get cancelRequest => 'إلغاء الطلب';

  @override
  String get removeFriend => 'إزالة الصديق';

  @override
  String removeFriendBody(String name) {
    return 'لن يكون $name بين أصدقائك بعد الآن. يمكنكما إضافة بعضكما مجددًا لاحقًا.';
  }

  @override
  String get blockUser => 'حظر';

  @override
  String blockUserBody(String name) {
    return 'لن يتمكن $name من إرسال طلبات إليك أو العثور عليك برمزك، وستنتهي صداقتكما. ولن يتلقى أي إشعار.';
  }

  @override
  String get blockedSection => 'المحظورون';

  @override
  String get unblockUser => 'إلغاء الحظر';

  @override
  String get unnamedUser => 'مستخدم بلا اسم';

  @override
  String get myQrAddName => 'أضف اسمك';

  @override
  String get myQrHelp => 'اطلب من صديق مسح هذا الرمز: سيصلك طلب صداقته.';

  @override
  String get shareFriendCode => 'مشاركة';

  @override
  String shareFriendCodeText(String link, String code) {
    return 'أضفني على nIpay: $link (الرمز $code)';
  }

  @override
  String get scanQrHint => 'وجّه الكاميرا نحو رمز QR الخاص بصديقك في nIpay.';

  @override
  String get cameraUnavailable =>
      'الكاميرا غير متاحة. اسمح بالوصول من الإعدادات، أو أدخل الرمز يدويًا.';

  @override
  String get enterCodeManually => 'أو أدخل الرمز';

  @override
  String get findFriend => 'بحث';

  @override
  String get invalidFriendCode => 'هذا ليس رمز صداقة صالحًا.';

  @override
  String get notANipayQr => 'رمز QR هذا ليس رمز صداقة في nIpay.';

  @override
  String get friendCodeNoMatch => 'لم يُعثر على أحد بهذا الرمز.';

  @override
  String sendFriendRequestTitle(String name) {
    return 'هل تريد إرسال طلب صداقة إلى $name؟';
  }

  @override
  String get sendRequest => 'إرسال الطلب';

  @override
  String friendRequestSent(String name) {
    return 'تم إرسال الطلب إلى $name';
  }

  @override
  String nowFriends(String name) {
    return 'أنت و$name صديقان الآن';
  }

  @override
  String get friendsErrorNotAvailable => 'هذا الشخص غير متاح.';

  @override
  String get friendsErrorCooldown =>
      'رفض هذا الشخص طلبك مؤخرًا. حاول مرة أخرى بعد بضعة أيام.';

  @override
  String get friendsErrorTooManyPending =>
      'لديك طلبات كثيرة بانتظار الرد. ألغِ بعضها أو انتظر الردود.';

  @override
  String get friendsErrorNotFound => 'هذا الطلب لم يعد متاحًا.';

  @override
  String get friendsLoadFailed =>
      'تعذّر تحميل أصدقائك. تحقّق من اتصالك وحاول مرة أخرى.';

  @override
  String friendRequestsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count من طلبات الصداقة',
      one: 'طلب صداقة واحد',
    );
    return '$_temp0';
  }

  @override
  String get chatSection => 'المحادثات';

  @override
  String get newGroup => 'مجموعة جديدة';

  @override
  String get noChatsYet => 'لا توجد محادثات بعد. اضغط على صديق لبدء محادثة.';

  @override
  String get chatsLoadFailed =>
      'تعذّر تحميل محادثاتك. تحقّق من اتصالك وحاول مجددًا.';

  @override
  String get messageHint => 'رسالة';

  @override
  String get sendMessage => 'إرسال';

  @override
  String get messageDeleted => 'تم حذف الرسالة';

  @override
  String get deletedUser => 'مستخدم محذوف';

  @override
  String get chatReadOnly => 'لم يعد بإمكانك الكتابة في هذه المحادثة.';

  @override
  String get chatOffline =>
      'أنت غير متصل. يمكنك الكتابة مجددًا عند عودة الاتصال.';

  @override
  String get loadEarlierMessages => 'تحميل الرسائل الأقدم';

  @override
  String get chatEmpty => 'لا توجد رسائل بعد. قل مرحبًا!';

  @override
  String chatYouPrefix(String text) {
    return 'أنت: $text';
  }

  @override
  String get deleteMessage => 'حذف الرسالة';

  @override
  String get deleteMessageBody => 'سيرى الجميع في المحادثة «تم حذف الرسالة».';

  @override
  String get reportAction => 'إبلاغ';

  @override
  String get reportMessageTitle => 'الإبلاغ عن الرسالة';

  @override
  String reportUserTitle(String name) {
    return 'الإبلاغ عن $name';
  }

  @override
  String get reportReasonLabel => 'السبب';

  @override
  String get reportChooseReason => 'اختر سببًا.';

  @override
  String get reportReasonSpam => 'رسائل مزعجة';

  @override
  String get reportReasonOffensive => 'محتوى مسيء';

  @override
  String get reportReasonHarassment => 'تحرّش';

  @override
  String get reportReasonOther => 'أخرى';

  @override
  String get reportDetails => 'التفاصيل (اختياري)';

  @override
  String get reportAlsoBlock => 'حظر هذا الشخص أيضًا';

  @override
  String get reportSend => 'إرسال البلاغ';

  @override
  String get reportSent => 'تم إرسال البلاغ. شكرًا لك.';

  @override
  String get groupName => 'اسم المجموعة';

  @override
  String get chooseFriends => 'اختر أصدقاء';

  @override
  String get createGroup => 'إنشاء المجموعة';

  @override
  String get groupNeedsMembers => 'اختر صديقًا واحدًا على الأقل.';

  @override
  String get groupNameInvalid => 'استخدم من 1 إلى 60 حرفًا.';

  @override
  String groupMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count من الأعضاء',
      one: 'عضو واحد',
    );
    return '$_temp0';
  }

  @override
  String get groupInfo => 'معلومات المجموعة';

  @override
  String get groupAdmin => 'مشرف';

  @override
  String get addMembers => 'إضافة أعضاء';

  @override
  String get removeFromGroup => 'إزالة من المجموعة';

  @override
  String removeFromGroupBody(String name) {
    return 'لن يرى $name هذه المجموعة بعد الآن.';
  }

  @override
  String get leaveGroup => 'مغادرة المجموعة';

  @override
  String get leaveGroupBody => 'لن ترى رسائل هذه المجموعة بعد الآن.';

  @override
  String get youLabel => 'أنت';

  @override
  String get noFriendsToAdd => 'جميع أصدقائك موجودون في المجموعة بالفعل.';

  @override
  String get messageFriend => 'مراسلة';

  @override
  String get chatErrorInvalidMessage =>
      'يمكن أن تحتوي الرسالة على 1 إلى 2000 حرف.';

  @override
  String get chatErrorTooManyMembers =>
      'يمكن أن تضم المجموعة 50 عضوًا كحد أقصى.';

  @override
  String get chatErrorNotFound => 'لم تعد هذه المحادثة متاحة.';

  @override
  String get chatErrorInvalidReport => 'تحقّق من التفاصيل: 500 حرف كحد أقصى.';

  @override
  String unreadMessagesBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count من الرسائل غير المقروءة',
      one: 'رسالة واحدة غير مقروءة',
    );
    return '$_temp0';
  }

  @override
  String get friendOut => 'إلى الأصدقاء';

  @override
  String get friendIn => 'من الأصدقاء';

  @override
  String get shareWithFriends => 'المشاركة مع الأصدقاء';

  @override
  String get shareAddFriends => 'إضافة أصدقاء';

  @override
  String get shareWhoPaid => 'من دفع؟';

  @override
  String get sharePaidByMe => 'أنا';

  @override
  String get shareSplitEqually => 'بالتساوي';

  @override
  String get shareSplitCustom => 'مبالغ مخصصة';

  @override
  String shareRemaining(String amount) {
    return 'متبقٍ $amount للتوزيع';
  }

  @override
  String shareExcess(String amount) {
    return '$amount زيادة';
  }

  @override
  String shareOwesYou(String name, String amount) {
    return '$name مدين لك بـ $amount';
  }

  @override
  String shareYouOwe(String name, String amount) {
    return 'أنت مدين لـ $name بـ $amount';
  }

  @override
  String shareYourShare(String amount) {
    return 'حصتك: $amount';
  }

  @override
  String get shareNeedsConnection =>
      'تحتاج المشاركة إلى اتصال. لا يزال بإمكانك حفظها كمصروف عادي.';

  @override
  String get shareSplitMismatch => 'يجب أن يساوي مجموع المبالغ الإجمالي.';

  @override
  String get shareTooSmall => 'المبلغ صغير جدًا لتقسيمه على الجميع.';

  @override
  String get shareLinkedNote => 'مصروف مشترك: تتم إدارته من الأصدقاء.';

  @override
  String get shareErrorInvalid =>
      'تحقّق من المصروف المشترك: المبالغ والعملة والأصدقاء.';

  @override
  String get splitSection => 'المصروفات المشتركة';

  @override
  String get splitTodo => 'مطلوب منك';

  @override
  String get splitBalances => 'الأرصدة';

  @override
  String get splitRecent => 'الأحدث';

  @override
  String balanceOwesYou(String amount) {
    return 'مدين لك بـ $amount';
  }

  @override
  String balanceYouOwe(String amount) {
    return 'أنت مدين بـ $amount';
  }

  @override
  String get settleAction => 'تسوية';

  @override
  String settleTitle(String name) {
    return 'السداد لـ $name';
  }

  @override
  String settleAmountMax(String amount) {
    return 'بحد أقصى $amount: هذا ما أنت مدين به.';
  }

  @override
  String settleRecorded(String name) {
    return 'تم التسجيل. يُحتسب عندما يؤكده $name.';
  }

  @override
  String settleIncoming(String name, String amount) {
    return 'يقول $name إنه دفع لك $amount';
  }

  @override
  String get settleReceived => 'تم الاستلام';

  @override
  String get settleNotReceived => 'لم يتم الاستلام';

  @override
  String settleWaiting(String name, String amount) {
    return 'بانتظار أن يؤكد $name مبلغ $amount';
  }

  @override
  String settleDeclined(String name, String amount) {
    return 'لم يؤكد $name مبلغ $amount';
  }

  @override
  String registerShareItem(String description, String amount) {
    return 'حصتك من «$description»: $amount';
  }

  @override
  String registerSettlementOut(String name, String amount) {
    return 'تم تأكيد السداد لـ $name: $amount';
  }

  @override
  String registerSettlementIn(String name, String amount) {
    return 'سداد من $name: $amount';
  }

  @override
  String get registerAction => 'تسجيل';

  @override
  String get registerTitle => 'التسجيل في محفظة';

  @override
  String registerConverted(String amount) {
    return 'في هذه المحفظة: $amount';
  }

  @override
  String get registerDone => 'تم التسجيل في المحفظة.';

  @override
  String get sharedExpenseFallbackTitle => 'مصروف مشترك';

  @override
  String sharedExpensePaidBy(String name, String amount) {
    return 'دفعها $name · حصتك $amount';
  }

  @override
  String sharedExpensePaidByYou(String amount) {
    return 'دفعتها أنت · حصتك $amount';
  }

  @override
  String get splitLocked =>
      'سجّل أحدهم حصته بالفعل، لذا لم يعد بالإمكان تعديله.';

  @override
  String get splitNotFound => 'لم يعد هذا موجودًا.';

  @override
  String get settleTooMuch => 'هذا أكثر مما أنت مدين به.';

  @override
  String get editSharedExpense => 'تعديل المصروف المشترك';

  @override
  String get deleteSharedExpenseBody => 'يختفي للجميع، مع حركاتك في المحفظة.';

  @override
  String splitTodoBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count من المصروفات المشتركة بانتظارك',
      one: 'مصروف مشترك واحد بانتظارك',
    );
    return '$_temp0';
  }

  @override
  String get accountPendingDeletionError =>
      'جارٍ حذف حسابك: يمكنك فقط القراءة وتسوية ديونك.';
}
