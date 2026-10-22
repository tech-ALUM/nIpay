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
}
