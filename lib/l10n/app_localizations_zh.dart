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
  String get account => '账户';

  @override
  String get accountLocalModeDescription =>
      '你尚未登录：你的数据只保存在这台设备上。登录后即可在多台设备间同步。';

  @override
  String get signIn => '登录';

  @override
  String get signUp => '注册';

  @override
  String get signOut => '退出登录';

  @override
  String get email => '电子邮箱';

  @override
  String get password => '密码';

  @override
  String get confirmSignOut => '要退出你的账户吗？数据会保留在这台设备上，但只能用这个账户重新登录后才能再次打开。';

  @override
  String get noAccountYet => '还没有账户？注册';

  @override
  String get alreadyHaveAccount => '已有账户？登录';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get resetPasswordSent => '重置密码的邮件已发送，请查收邮箱。';

  @override
  String signedInAs(String email) {
    return '已登录：$email';
  }

  @override
  String get invalidEmail => '请输入有效的电子邮箱地址';

  @override
  String get passwordTooShort => '密码至少需要 8 个字符';

  @override
  String get changePassword => '修改密码';

  @override
  String get newPassword => '新密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get passwordsDontMatch => '两次输入的密码不一致';

  @override
  String get passwordChanged => '密码已修改。其他设备已退出登录。';

  @override
  String get syncNow => '立即同步';

  @override
  String get syncComplete => '同步完成';

  @override
  String get syncFailed => '同步失败。请检查网络连接后重试。';

  @override
  String get deleteAccount => '删除账户';

  @override
  String get deleteAccountConfirmBody =>
      '你的账户及其云端数据将在 30 天后永久删除。在此之前，你可以在此页面取消。这台设备上的数据不会被删除。';

  @override
  String get deleteAccountRequested => '已申请删除账户。你有 30 天时间可以取消。';

  @override
  String deletionPending(String date) {
    return '账户将于 $date 删除。';
  }

  @override
  String get cancelDeletion => '取消删除';

  @override
  String get deletionCanceled => '已取消删除账户。';

  @override
  String get signOutRemoveLocalData => '从此设备移除数据';

  @override
  String get signOutRemoveLocalDataHint =>
      '数据会先同步到你的账户，然后从此设备移除。收据照片尚不支持同步，将会丢失。';

  @override
  String get signOutSyncFailed => '移除前同步失败。没有删除任何数据，你仍处于登录状态：请检查网络连接后重试。';

  @override
  String get localDataRemoved => '已从此设备移除数据';

  @override
  String get foreignLocalDataBody =>
      '此设备上有另一个账户的数据，为保持隔离，同步已暂停。移除这些数据以开始同步此账户，或退出登录。';

  @override
  String get removeLocalDataAndSync => '移除数据并同步';

  @override
  String get removeForeignLocalDataConfirmBody =>
      '此设备上的所有钱包、交易和收据照片都将被删除。另一个账户已同步的数据仍安全保存在该账户中。是否继续？';

  @override
  String get syncBlockedForeignData => '同步已暂停：此设备上有另一个账户的数据。';

  @override
  String get currentPassword => '当前密码';

  @override
  String get wrongCurrentPassword => '当前密码不正确。';

  @override
  String get confirmWithPassword => '请输入密码以确认。';

  @override
  String get passwordTooWeak => '请至少使用 12 个字符，并包含字母和数字。';

  @override
  String get signOutEverywhere => '在所有设备上退出登录';

  @override
  String get signOutEverywhereConfirmBody =>
      '这个账户的所有会话都将被关闭，包括当前会话。如果设备丢失或被盗，请使用此功能。这台设备上的数据会保留。';

  @override
  String get signedOutEverywhere => '已在所有设备上退出登录。';

  @override
  String get authErrorInvalidCredentials => '电子邮箱或密码无效，或者邮箱尚未验证。';

  @override
  String get authErrorWeakPassword => '此密码不被接受：请选择更长、更不常见的密码。';

  @override
  String get authErrorSamePassword => '新密码必须与当前密码不同。';

  @override
  String get authErrorRateLimited => '尝试次数过多。请等待几分钟后重试。';

  @override
  String get authErrorReauthRequired => '为了安全，请重新输入密码后重试。';

  @override
  String get authErrorNetwork => '无法连接服务器。请检查网络连接后重试。';

  @override
  String get authErrorGeneric => '出了点问题，请重试。';

  @override
  String get resetPasswordTitle => '设置新密码';

  @override
  String get passwordResetDone => '密码已更新。其他设备已退出登录。';

  @override
  String get resetPasswordCooldown => '请等待一分钟后再请求新的邮件。';

  @override
  String lastSyncAt(String date) {
    return '上次同步：$date';
  }

  @override
  String get lastSyncNever => '尚未同步';

  @override
  String get syncLastFailed => '上次同步失败：将自动重试。';

  @override
  String syncIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '有 $count 项未能同步，将自动重试。',
      one: '有 1 项未能同步，将自动重试。',
    );
    return '$_temp0';
  }

  @override
  String get lockedDataTitle => '数据已锁定';

  @override
  String lockedDataBody(String email) {
    return '这台设备上保存着 $email 的数据。请用该账户登录查看，或将其从这台设备上移除。';
  }

  @override
  String get lockedDataBodyUnknownOwner =>
      '这台设备上保存着一个未登录账户的数据。请用该账户登录查看，或将其从这台设备上移除。';

  @override
  String get lockedDataOtherAccountBody =>
      '这台设备上保存着另一个账户的数据。要在这里使用当前账户，请从设备上移除这些数据（打开“账户”），或者退出登录。';

  @override
  String get startupError => '无法打开你的数据。请重启应用；如果问题持续出现，请联系支持团队。';

  @override
  String get attachmentUnsupported => '不支持此图片格式：请使用 JPEG、PNG 或 WebP 照片。';

  @override
  String get pause => '暂停';

  @override
  String get resume => '恢复';

  @override
  String deleteItemTitle(String name) {
    return '删除“$name”？';
  }

  @override
  String get deleteItemBody => '此操作无法撤销。';

  @override
  String get showPassword => '显示密码';

  @override
  String get hidePassword => '隐藏密码';

  @override
  String get fieldRequired => '必填';

  @override
  String get noWalletForTransaction => '请先创建一个钱包再添加交易。';

  @override
  String get categoryGroceries => '日用杂货';

  @override
  String get categoryRestaurants => '餐厅';

  @override
  String get categoryTransport => '交通';

  @override
  String get categoryHousing => '住房';

  @override
  String get categoryLeisure => '休闲娱乐';

  @override
  String get categoryHealth => '医疗健康';

  @override
  String get categoryShopping => '购物';

  @override
  String get categorySalary => '工资';

  @override
  String get categoryGifts => '礼物';

  @override
  String get categoryOther => '其他';

  @override
  String get profileSection => '个人资料';

  @override
  String get displayName => '显示名称';

  @override
  String get displayNameNotSet => '未设置';

  @override
  String get displayNameHelp => '好友会看到这个名称。你的电子邮箱不会公开。';

  @override
  String get displayNameDialogTitle => '你叫什么名字？';

  @override
  String get displayNameInvalid => '请使用 1 到 40 个字符。';

  @override
  String get displayNameSaved => '名称已保存';

  @override
  String get friendCode => '你的好友码';

  @override
  String get friendCodeHelp => '分享它即可收到好友请求。';

  @override
  String get copyFriendCode => '复制好友码';

  @override
  String get friendCodeCopied => '已复制好友码';

  @override
  String get regenerateFriendCode => '生成新好友码';

  @override
  String get regenerateFriendCodeBody => '当前好友码将失效：持有它的人将无法再向你发送请求。已有的好友不受影响。';

  @override
  String get friendCodeRegenerated => '新好友码已生成';

  @override
  String get profileLoadFailed => '无法加载你的个人资料。请检查网络连接后重试。';

  @override
  String get retry => '重试';
}
