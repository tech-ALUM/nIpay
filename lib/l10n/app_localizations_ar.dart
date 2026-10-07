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
