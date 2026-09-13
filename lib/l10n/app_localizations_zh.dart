// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'nIpay';

  @override
  String get homeTab => '首页';

  @override
  String get transactionsTab => '交易';

  @override
  String get statsTab => '统计';

  @override
  String get settingsTab => '更多';

  @override
  String get totalBalance => '总余额';

  @override
  String get thisMonth => '本月';

  @override
  String get wallets => '钱包';

  @override
  String get newWallet => '新建钱包';

  @override
  String get walletName => '名称';

  @override
  String get currency => '货币';

  @override
  String get walletNameDuplicate => '已存在同名钱包';

  @override
  String get walletNameRequired => '请输入钱包名称';

  @override
  String get initialBalance => '初始余额';

  @override
  String get recentTransactions => '最近交易';

  @override
  String get noTransactions => '还没有交易。点击 + 添加第一笔。';

  @override
  String get noWallets => '创建你的第一个钱包开始使用。';

  @override
  String get newTransaction => '新建交易';

  @override
  String get expense => '支出';

  @override
  String get income => '收入';

  @override
  String get transfer => '转账';

  @override
  String get amount => '金额';

  @override
  String get invalidAmount => '金额无效';

  @override
  String get exchangeRateError => '无法获取汇率：请检查网络连接后重试';

  @override
  String convertedPreview(String amount) {
    return '≈ $amount（按当前汇率）';
  }

  @override
  String get description => '描述';

  @override
  String get category => '分类';

  @override
  String get wallet => '钱包';

  @override
  String get fromWallet => '从';

  @override
  String get toWallet => '到';

  @override
  String get date => '日期';

  @override
  String get save => '保存';

  @override
  String get apply => '应用';

  @override
  String get cancel => '取消';

  @override
  String get delete => '删除';

  @override
  String get deleteWalletTitle => '删除钱包？';

  @override
  String deleteWalletBody(String name) {
    return '请在下方输入 \"$name\" 以确认。此操作无法撤销。';
  }

  @override
  String get allWallets => '所有钱包';

  @override
  String get allCategories => '所有分类';

  @override
  String get searchTransactions => '搜索交易…';

  @override
  String get receipt => '收据';

  @override
  String get fromCamera => '相机';

  @override
  String get fromGallery => '相册';

  @override
  String get attachments => '附件';

  @override
  String get transactionDetail => '交易';

  @override
  String get deleteTransaction => '删除交易';

  @override
  String get addCard => '添加卡片';

  @override
  String get cardCategoryDonut => '按分类的支出';

  @override
  String get cardTrend => '6个月趋势';

  @override
  String get cardCashflow => '现金流';

  @override
  String get cardBudget => '预算';

  @override
  String get netLabel => '净额';

  @override
  String get noStatsData => '该时间段没有数据。';

  @override
  String get emptyDashboard => '自定义你的仪表盘：添加第一张卡片。';

  @override
  String get customization => '自定义';

  @override
  String get budgets => '预算';

  @override
  String get newBudget => '新建预算';

  @override
  String get monthlyLimit => '每月限额';

  @override
  String get recurring => '周期性';

  @override
  String get newRecurring => '新建周期性交易';

  @override
  String get frequency => '频率';

  @override
  String get freqDaily => '每天';

  @override
  String get freqWeekly => '每周';

  @override
  String get freqMonthly => '每月';

  @override
  String get freqYearly => '每年';

  @override
  String get startDate => '开始日期';

  @override
  String get nextRun => '下一次';

  @override
  String get paused => '已暂停';

  @override
  String budgetNear(String category, int percent) {
    return '$category 预算已达 $percent%';
  }

  @override
  String budgetExceeded(String category) {
    return '$category 预算已超支！';
  }

  @override
  String get manageCategories => '分类';

  @override
  String get manageTags => '标签';

  @override
  String get manageCustomFields => '自定义字段';

  @override
  String get newCategory => '新建分类';

  @override
  String get editCategory => '编辑分类';

  @override
  String get icon => '图标（表情符号）';

  @override
  String get color => '颜色';

  @override
  String get kindBoth => '两者皆可';

  @override
  String get newTag => '新建标签';

  @override
  String get tagNameRequired => '请输入标签名称';

  @override
  String get tagNameDuplicate => '已存在同名标签';

  @override
  String get costCenterNameRequired => '请输入成本中心名称';

  @override
  String get tagName => '标签名称';

  @override
  String get newField => '新建字段';

  @override
  String get fieldName => '字段名称';

  @override
  String get fieldType => '类型';

  @override
  String get typeText => '文本';

  @override
  String get typeNumber => '数字';

  @override
  String get typeChoice => '选项';

  @override
  String get typeDate => '日期';

  @override
  String get choiceOptions => '选项（逗号分隔）';

  @override
  String get tags => '标签';

  @override
  String get customFields => '自定义字段';

  @override
  String get allTags => '所有标签';

  @override
  String get noItems => '这里还没有内容。';

  @override
  String get expenseReport => '报销单';

  @override
  String get expenseReportFlag => '报销单';

  @override
  String get costCenter => '成本中心';

  @override
  String get manageCostCenters => '成本中心';

  @override
  String get newCostCenter => '新建成本中心';

  @override
  String get reimbursable => '可报销';

  @override
  String get eInvoice => '电子发票';

  @override
  String get pendingReimbursement => '待报销';

  @override
  String get exportPdf => '导出 PDF';

  @override
  String get createReport => '创建报销单';

  @override
  String get reportName => '报销单名称';

  @override
  String get statusDraft => '草稿';

  @override
  String get statusSent => '已提交';

  @override
  String get statusReimbursed => '已报销';

  @override
  String get markSent => '标记为已提交';

  @override
  String get markReimbursed => '标记为已报销';

  @override
  String get reportArchive => '存档';

  @override
  String get flaggedExpenses => '已标记的支出';

  @override
  String get expenseReportOnlyField => '仅用于报销单';

  @override
  String get edit => '编辑';

  @override
  String get editTransaction => '编辑交易';

  @override
  String get fromDate => '从';

  @override
  String get toDate => '到';

  @override
  String get none => '无';

  @override
  String get language => '语言';

  @override
  String get settingsTheme => '主题';

  @override
  String get themeSystem => '系统';

  @override
  String get themeLight => '浅色';

  @override
  String get themeDark => '深色';

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
