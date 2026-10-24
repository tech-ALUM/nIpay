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

  @override
  String get friendsTab => '好友';

  @override
  String get friendsSignInPrompt => '登录后即可添加好友、聊天和分摊费用。';

  @override
  String get myQrCode => '我的二维码';

  @override
  String get addFriend => '添加好友';

  @override
  String get friendRequests => '好友请求';

  @override
  String get friendsSection => '你的好友';

  @override
  String get noFriendsYet => '还没有好友。让好友扫描你的二维码，或者扫描对方的。';

  @override
  String get incomingRequestSubtitle => '想加你为好友';

  @override
  String get acceptRequest => '接受';

  @override
  String get declineRequest => '拒绝';

  @override
  String get outgoingPending => '等待对方回复';

  @override
  String get outgoingDeclined => '请求未被接受';

  @override
  String get cancelRequest => '取消请求';

  @override
  String get removeFriend => '删除好友';

  @override
  String removeFriendBody(String name) {
    return '$name 将不再是你的好友。之后你们可以再次互相添加。';
  }

  @override
  String get blockUser => '屏蔽';

  @override
  String blockUserBody(String name) {
    return '$name 将无法再向你发送请求，也无法通过你的好友码找到你，你们的好友关系也会结束。对方不会收到任何通知。';
  }

  @override
  String get blockedSection => '已屏蔽';

  @override
  String get unblockUser => '解除屏蔽';

  @override
  String get unnamedUser => '未命名用户';

  @override
  String get myQrAddName => '添加你的名字';

  @override
  String get myQrHelp => '让好友扫描这个二维码，你就会收到对方的好友请求。';

  @override
  String get shareFriendCode => '分享';

  @override
  String shareFriendCodeText(String link, String code) {
    return '在 nIpay 上加我为好友：$link（好友码 $code）';
  }

  @override
  String get scanQrHint => '将相机对准好友的 nIpay 二维码。';

  @override
  String get cameraUnavailable => '相机不可用。请在“设置”中允许访问，或手动输入好友码。';

  @override
  String get enterCodeManually => '或输入好友码';

  @override
  String get findFriend => '查找';

  @override
  String get invalidFriendCode => '这不是有效的好友码。';

  @override
  String get notANipayQr => '这个二维码不是 nIpay 好友码。';

  @override
  String get friendCodeNoMatch => '没有找到使用此好友码的用户。';

  @override
  String sendFriendRequestTitle(String name) {
    return '要向 $name 发送好友请求吗？';
  }

  @override
  String get sendRequest => '发送请求';

  @override
  String friendRequestSent(String name) {
    return '已向 $name 发送请求';
  }

  @override
  String nowFriends(String name) {
    return '你和 $name 已成为好友';
  }

  @override
  String get friendsErrorNotAvailable => '此用户不可用。';

  @override
  String get friendsErrorCooldown => '对方最近拒绝了你的请求。请过几天再试。';

  @override
  String get friendsErrorTooManyPending => '你有太多待处理的请求。请取消一些或等待对方回复。';

  @override
  String get friendsErrorNotFound => '此请求已失效。';

  @override
  String get friendsLoadFailed => '无法加载好友列表。请检查网络连接后重试。';

  @override
  String friendRequestsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 个好友请求',
      one: '1 个好友请求',
    );
    return '$_temp0';
  }

  @override
  String get chatSection => '聊天';

  @override
  String get newGroup => '新建群组';

  @override
  String get noChatsYet => '还没有聊天。点按一位好友即可开始。';

  @override
  String get chatsLoadFailed => '无法加载你的聊天。请检查网络连接后重试。';

  @override
  String get messageHint => '消息';

  @override
  String get sendMessage => '发送';

  @override
  String get messageDeleted => '消息已删除';

  @override
  String get deletedUser => '已注销用户';

  @override
  String get chatReadOnly => '你已无法在此聊天中发送消息。';

  @override
  String get chatOffline => '你已离线。恢复联网后即可继续发送消息。';

  @override
  String get loadEarlierMessages => '加载更早的消息';

  @override
  String get chatEmpty => '还没有消息。打个招呼吧！';

  @override
  String chatYouPrefix(String text) {
    return '你：$text';
  }

  @override
  String get deleteMessage => '删除消息';

  @override
  String get deleteMessageBody => '聊天中的所有人都会看到“消息已删除”。';

  @override
  String get reportAction => '举报';

  @override
  String get reportMessageTitle => '举报消息';

  @override
  String reportUserTitle(String name) {
    return '举报 $name';
  }

  @override
  String get reportReasonLabel => '原因';

  @override
  String get reportChooseReason => '请选择原因。';

  @override
  String get reportReasonSpam => '垃圾信息';

  @override
  String get reportReasonOffensive => '冒犯性内容';

  @override
  String get reportReasonHarassment => '骚扰';

  @override
  String get reportReasonOther => '其他';

  @override
  String get reportDetails => '详细说明（可选）';

  @override
  String get reportAlsoBlock => '同时屏蔽此用户';

  @override
  String get reportSend => '提交举报';

  @override
  String get reportSent => '举报已提交，谢谢。';

  @override
  String get groupName => '群组名称';

  @override
  String get chooseFriends => '选择好友';

  @override
  String get createGroup => '创建群组';

  @override
  String get groupNeedsMembers => '请至少选择一位好友。';

  @override
  String get groupNameInvalid => '请使用 1 到 60 个字符。';

  @override
  String groupMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 名成员',
      one: '1 名成员',
    );
    return '$_temp0';
  }

  @override
  String get groupInfo => '群组信息';

  @override
  String get groupAdmin => '管理员';

  @override
  String get addMembers => '添加成员';

  @override
  String get removeFromGroup => '移出群组';

  @override
  String removeFromGroupBody(String name) {
    return '$name 将无法再看到此群组。';
  }

  @override
  String get leaveGroup => '退出群组';

  @override
  String get leaveGroupBody => '你将无法再看到此群组的消息。';

  @override
  String get youLabel => '你';

  @override
  String get noFriendsToAdd => '你的所有好友都已在群组中。';

  @override
  String get messageFriend => '发消息';

  @override
  String get chatErrorInvalidMessage => '一条消息可包含 1 到 2000 个字符。';

  @override
  String get chatErrorTooManyMembers => '一个群组最多可有 50 名成员。';

  @override
  String get chatErrorNotFound => '此聊天已不可用。';

  @override
  String get chatErrorInvalidReport => '请检查详细说明：最多 500 个字符。';

  @override
  String unreadMessagesBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 条未读消息',
      one: '1 条未读消息',
    );
    return '$_temp0';
  }

  @override
  String get friendOut => '给好友';

  @override
  String get friendIn => '来自好友';

  @override
  String get shareWithFriends => '与好友分摊';

  @override
  String get shareAddFriends => '添加好友';

  @override
  String get shareWhoPaid => '谁付的钱？';

  @override
  String get sharePaidByMe => '我';

  @override
  String get shareSplitEqually => '平均分摊';

  @override
  String get shareSplitCustom => '自定义金额';

  @override
  String shareRemaining(String amount) {
    return '还差 $amount';
  }

  @override
  String shareExcess(String amount) {
    return '多了 $amount';
  }

  @override
  String shareOwesYou(String name, String amount) {
    return '$name 欠你 $amount';
  }

  @override
  String shareYouOwe(String name, String amount) {
    return '你欠 $name $amount';
  }

  @override
  String shareYourShare(String amount) {
    return '你的份额：$amount';
  }

  @override
  String get shareNeedsConnection => '分摊需要联网。你仍可将其保存为普通支出。';

  @override
  String get shareSplitMismatch => '各项金额之和必须等于总额。';

  @override
  String get shareTooSmall => '金额太小，无法在所有人之间分摊。';

  @override
  String get shareLinkedNote => '分摊支出：请在“好友”中管理。';

  @override
  String get shareErrorInvalid => '请检查分摊支出：金额、币种和好友。';

  @override
  String get splitSection => '分摊支出';

  @override
  String get splitTodo => '待处理';

  @override
  String get splitBalances => '余额';

  @override
  String get splitRecent => '最近';

  @override
  String balanceOwesYou(String amount) {
    return '欠你 $amount';
  }

  @override
  String balanceYouOwe(String amount) {
    return '你欠 $amount';
  }

  @override
  String get settleAction => '还款';

  @override
  String settleTitle(String name) {
    return '还钱给 $name';
  }

  @override
  String settleAmountMax(String amount) {
    return '最多 $amount：这是你欠的金额。';
  }

  @override
  String settleRecorded(String name) {
    return '已记录。$name 确认后生效。';
  }

  @override
  String settleIncoming(String name, String amount) {
    return '$name 说已给你 $amount';
  }

  @override
  String get settleReceived => '已收到';

  @override
  String get settleNotReceived => '未收到';

  @override
  String settleWaiting(String name, String amount) {
    return '等待 $name 确认 $amount';
  }

  @override
  String settleDeclined(String name, String amount) {
    return '$name 未确认 $amount';
  }

  @override
  String registerShareItem(String description, String amount) {
    return '“$description”中你的份额：$amount';
  }

  @override
  String registerSettlementOut(String name, String amount) {
    return '已确认还给 $name：$amount';
  }

  @override
  String registerSettlementIn(String name, String amount) {
    return '来自 $name 的还款：$amount';
  }

  @override
  String get registerAction => '记账';

  @override
  String get registerTitle => '记入钱包';

  @override
  String registerConverted(String amount) {
    return '在此钱包中：$amount';
  }

  @override
  String get registerDone => '已记入钱包。';

  @override
  String get sharedExpenseFallbackTitle => '分摊支出';

  @override
  String sharedExpensePaidBy(String name, String amount) {
    return '$name 付款 · 你的份额 $amount';
  }

  @override
  String sharedExpensePaidByYou(String amount) {
    return '你付款 · 你的份额 $amount';
  }

  @override
  String get splitLocked => '已有人记入了自己的份额，因此无法再修改。';

  @override
  String get splitNotFound => '此项已不存在。';

  @override
  String get settleTooMuch => '超出了你欠的金额。';

  @override
  String get editSharedExpense => '编辑分摊支出';

  @override
  String get deleteSharedExpenseBody => '它将对所有人消失，你钱包里的相关记录也会一并删除。';

  @override
  String splitTodoBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 项分摊待处理',
      one: '1 项分摊待处理',
    );
    return '$_temp0';
  }

  @override
  String get accountPendingDeletionError => '你的账户正在注销：你只能查看内容并结清欠款。';
}
