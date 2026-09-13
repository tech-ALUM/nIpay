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
      'Sign out of your account? Your data stays on this device and keeps working offline.';

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
      'Your account will be permanently deleted in 30 days. You can cancel any time before then by signing back in. This does not affect the data on this device, which keeps working offline.';

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
}
