// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'nIpay';

  @override
  String get homeTab => 'Home';

  @override
  String get transactionsTab => 'Transactions';

  @override
  String get statsTab => 'Stats';

  @override
  String get settingsTab => 'More';

  @override
  String get totalBalance => 'Total balance';

  @override
  String get thisMonth => 'this month';

  @override
  String get wallets => 'Wallets';

  @override
  String get newWallet => 'New wallet';

  @override
  String get walletName => 'Name';

  @override
  String get currency => 'Currency';

  @override
  String get walletNameDuplicate => 'A wallet with this name already exists';

  @override
  String get walletNameRequired => 'Enter a wallet name';

  @override
  String get initialBalance => 'Initial balance';

  @override
  String get recentTransactions => 'Recent transactions';

  @override
  String get noTransactions =>
      'No transactions yet. Tap + to add the first one.';

  @override
  String get noWallets => 'Create your first wallet to get started.';

  @override
  String get newTransaction => 'New transaction';

  @override
  String get expense => 'Expense';

  @override
  String get income => 'Income';

  @override
  String get transfer => 'Transfer';

  @override
  String get amount => 'Amount';

  @override
  String get invalidAmount => 'Invalid amount';

  @override
  String get exchangeRateError =>
      'Couldn\'t get the exchange rate: check your connection and try again';

  @override
  String convertedPreview(String amount) {
    return '≈ $amount at the current rate';
  }

  @override
  String get description => 'Description';

  @override
  String get category => 'Category';

  @override
  String get wallet => 'Wallet';

  @override
  String get fromWallet => 'From';

  @override
  String get toWallet => 'To';

  @override
  String get date => 'Date';

  @override
  String get save => 'Save';

  @override
  String get apply => 'Apply';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get deleteWalletTitle => 'Delete wallet?';

  @override
  String deleteWalletBody(String name) {
    return 'To confirm, type \"$name\" in the field below. This cannot be undone.';
  }

  @override
  String get allWallets => 'All wallets';

  @override
  String get allCategories => 'All categories';

  @override
  String get searchTransactions => 'Search transactions…';

  @override
  String get receipt => 'Receipt';

  @override
  String get fromCamera => 'Camera';

  @override
  String get fromGallery => 'Gallery';

  @override
  String get attachments => 'Attachments';

  @override
  String get transactionDetail => 'Transaction';

  @override
  String get deleteTransaction => 'Delete transaction';

  @override
  String get addCard => 'Add card';

  @override
  String get cardCategoryDonut => 'Expenses by category';

  @override
  String get cardTrend => '6-month trend';

  @override
  String get cardCashflow => 'Cash flow';

  @override
  String get cardBudget => 'Budget';

  @override
  String get netLabel => 'Net';

  @override
  String get noStatsData => 'No data for this period.';

  @override
  String get emptyDashboard => 'Compose your dashboard: add your first card.';

  @override
  String get customization => 'Customization';

  @override
  String get budgets => 'Budget';

  @override
  String get newBudget => 'New budget';

  @override
  String get monthlyLimit => 'Monthly limit';

  @override
  String get recurring => 'Recurring';

  @override
  String get newRecurring => 'New recurring transaction';

  @override
  String get frequency => 'Frequency';

  @override
  String get freqDaily => 'Daily';

  @override
  String get freqWeekly => 'Weekly';

  @override
  String get freqMonthly => 'Monthly';

  @override
  String get freqYearly => 'Yearly';

  @override
  String get startDate => 'Start date';

  @override
  String get nextRun => 'Next';

  @override
  String get paused => 'Paused';

  @override
  String budgetNear(String category, int percent) {
    return 'Budget $category at $percent%';
  }

  @override
  String budgetExceeded(String category) {
    return 'Budget $category exceeded!';
  }

  @override
  String get manageCategories => 'Categories';

  @override
  String get manageTags => 'Tags';

  @override
  String get manageCustomFields => 'Custom fields';

  @override
  String get newCategory => 'New category';

  @override
  String get editCategory => 'Edit category';

  @override
  String get icon => 'Icon (emoji)';

  @override
  String get color => 'Color';

  @override
  String get kindBoth => 'Both';

  @override
  String get newTag => 'New tag';

  @override
  String get tagNameRequired => 'Enter a tag name';

  @override
  String get tagNameDuplicate => 'A tag with this name already exists';

  @override
  String get costCenterNameRequired => 'Enter a cost center name';

  @override
  String get tagName => 'Tag name';

  @override
  String get newField => 'New field';

  @override
  String get fieldName => 'Field name';

  @override
  String get fieldType => 'Type';

  @override
  String get typeText => 'Text';

  @override
  String get typeNumber => 'Number';

  @override
  String get typeChoice => 'Choice';

  @override
  String get typeDate => 'Date';

  @override
  String get choiceOptions => 'Options (comma separated)';

  @override
  String get tags => 'Tags';

  @override
  String get customFields => 'Custom fields';

  @override
  String get allTags => 'All tags';

  @override
  String get noItems => 'Nothing here yet.';

  @override
  String get expenseReport => 'Expense report';

  @override
  String get expenseReportFlag => 'Expense report';

  @override
  String get costCenter => 'Cost center';

  @override
  String get manageCostCenters => 'Cost centers';

  @override
  String get newCostCenter => 'New cost center';

  @override
  String get reimbursable => 'Reimbursable';

  @override
  String get eInvoice => 'E-invoice';

  @override
  String get pendingReimbursement => 'To be reimbursed';

  @override
  String get exportPdf => 'Export PDF';

  @override
  String get createReport => 'Create expense report';

  @override
  String get reportName => 'Report name';

  @override
  String get statusDraft => 'Draft';

  @override
  String get statusSent => 'Sent';

  @override
  String get statusReimbursed => 'Reimbursed';

  @override
  String get markSent => 'Mark as sent';

  @override
  String get markReimbursed => 'Mark as reimbursed';

  @override
  String get reportArchive => 'Archive';

  @override
  String get flaggedExpenses => 'Flagged expenses';

  @override
  String get expenseReportOnlyField => 'Only for expense reports';

  @override
  String get edit => 'Edit';

  @override
  String get editTransaction => 'Edit transaction';

  @override
  String get fromDate => 'From';

  @override
  String get toDate => 'To';

  @override
  String get none => 'None';

  @override
  String get language => 'Language';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

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
  String get signOutRemoveLocalData => 'Remove data from this device';

  @override
  String get signOutRemoveLocalDataHint =>
      'Your data is synced to your account first, then removed from this device. Receipt photos are not synced yet and will be lost.';

  @override
  String get signOutSyncFailed =>
      'Couldn\'t sync before removing your data. Nothing was removed and you are still signed in: check your connection and try again.';

  @override
  String get localDataRemoved => 'Data removed from this device';

  @override
  String get foreignLocalDataBody =>
      'This device holds data from another account, so sync is paused to keep it separate. Remove that data to start syncing this account, or sign out.';

  @override
  String get removeLocalDataAndSync => 'Remove data and sync';

  @override
  String get removeForeignLocalDataConfirmBody =>
      'All wallets, transactions and receipt photos on this device will be deleted. Whatever the other account already synced stays safe in that account. Continue?';

  @override
  String get syncBlockedForeignData =>
      'Sync paused: this device holds data from another account.';

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

  @override
  String get pause => 'Pause';

  @override
  String get resume => 'Resume';

  @override
  String deleteItemTitle(String name) {
    return 'Delete “$name”?';
  }

  @override
  String get deleteItemBody => 'This can\'t be undone.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get fieldRequired => 'Required';

  @override
  String get noWalletForTransaction =>
      'Create a wallet first to add transactions.';

  @override
  String get categoryGroceries => 'Groceries';

  @override
  String get categoryRestaurants => 'Restaurants';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryHousing => 'Housing';

  @override
  String get categoryLeisure => 'Leisure';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categorySalary => 'Salary';

  @override
  String get categoryGifts => 'Gifts';

  @override
  String get categoryOther => 'Other';

  @override
  String get profileSection => 'Profile';

  @override
  String get displayName => 'Display name';

  @override
  String get displayNameNotSet => 'Not set';

  @override
  String get displayNameHelp =>
      'Your friends see this name. Your email stays private.';

  @override
  String get displayNameDialogTitle => 'What\'s your name?';

  @override
  String get displayNameInvalid => 'Use 1 to 40 characters.';

  @override
  String get displayNameSaved => 'Name saved';

  @override
  String get friendCode => 'Your friend code';

  @override
  String get friendCodeHelp => 'Share it to receive friend requests.';

  @override
  String get copyFriendCode => 'Copy code';

  @override
  String get friendCodeCopied => 'Code copied';

  @override
  String get regenerateFriendCode => 'Generate new code';

  @override
  String get regenerateFriendCodeBody =>
      'Your current code stops working: anyone who has it can no longer send you requests. The friends you already have stay.';

  @override
  String get friendCodeRegenerated => 'New friend code ready';

  @override
  String get profileLoadFailed =>
      'Couldn\'t load your profile. Check your connection and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get friendsTab => 'Friends';

  @override
  String get friendsSignInPrompt =>
      'Sign in to add friends, chat and split expenses.';

  @override
  String get myQrCode => 'My QR code';

  @override
  String get addFriend => 'Add friend';

  @override
  String get friendRequests => 'Requests';

  @override
  String get friendsSection => 'Your friends';

  @override
  String get noFriendsYet =>
      'No friends yet. Let a friend scan your QR code, or scan theirs.';

  @override
  String get incomingRequestSubtitle => 'Wants to be your friend';

  @override
  String get acceptRequest => 'Accept';

  @override
  String get declineRequest => 'Decline';

  @override
  String get outgoingPending => 'Waiting for a reply';

  @override
  String get outgoingDeclined => 'Request not accepted';

  @override
  String get cancelRequest => 'Cancel request';

  @override
  String get removeFriend => 'Remove friend';

  @override
  String removeFriendBody(String name) {
    return '$name will no longer be among your friends. You can add each other again later.';
  }

  @override
  String get blockUser => 'Block';

  @override
  String blockUserBody(String name) {
    return '$name won\'t be able to send you requests or find you with your code, and your friendship ends. They won\'t be notified.';
  }

  @override
  String get blockedSection => 'Blocked';

  @override
  String get unblockUser => 'Unblock';

  @override
  String get unnamedUser => 'Unnamed user';

  @override
  String get myQrAddName => 'Add your name';

  @override
  String get myQrHelp =>
      'Ask a friend to scan this code: their friend request will reach you.';

  @override
  String get shareFriendCode => 'Share';

  @override
  String shareFriendCodeText(String link, String code) {
    return 'Add me on nIpay: $link (code $code)';
  }

  @override
  String get scanQrHint => 'Point the camera at a friend\'s nIpay QR code.';

  @override
  String get cameraUnavailable =>
      'Camera not available. Allow access in Settings, or enter the code by hand.';

  @override
  String get enterCodeManually => 'Or enter the code';

  @override
  String get findFriend => 'Find';

  @override
  String get invalidFriendCode => 'This isn\'t a valid friend code.';

  @override
  String get notANipayQr => 'This QR code isn\'t an nIpay friend code.';

  @override
  String get friendCodeNoMatch => 'No one found with this code.';

  @override
  String sendFriendRequestTitle(String name) {
    return 'Send a friend request to $name?';
  }

  @override
  String get sendRequest => 'Send request';

  @override
  String friendRequestSent(String name) {
    return 'Request sent to $name';
  }

  @override
  String nowFriends(String name) {
    return 'You and $name are now friends';
  }

  @override
  String get friendsErrorNotAvailable => 'This person isn\'t available.';

  @override
  String get friendsErrorCooldown =>
      'This person declined your request recently. Try again in a few days.';

  @override
  String get friendsErrorTooManyPending =>
      'You have too many requests waiting. Cancel some or wait for replies.';

  @override
  String get friendsErrorNotFound => 'This request is no longer available.';

  @override
  String get friendsLoadFailed =>
      'Couldn\'t load your friends. Check your connection and try again.';

  @override
  String friendRequestsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count friend requests',
      one: '1 friend request',
    );
    return '$_temp0';
  }

  @override
  String get chatSection => 'Chats';

  @override
  String get newGroup => 'New group';

  @override
  String get noChatsYet => 'No chats yet. Tap a friend to start one.';

  @override
  String get chatsLoadFailed =>
      'Couldn\'t load your chats. Check your connection and try again.';

  @override
  String get messageHint => 'Message';

  @override
  String get sendMessage => 'Send';

  @override
  String get messageDeleted => 'Message deleted';

  @override
  String get deletedUser => 'Deleted user';

  @override
  String get chatReadOnly => 'You can no longer write in this chat.';

  @override
  String get chatOffline =>
      'You\'re offline. You can write again when you\'re back online.';

  @override
  String get loadEarlierMessages => 'Load earlier messages';

  @override
  String get chatEmpty => 'No messages yet. Say hi!';

  @override
  String chatYouPrefix(String text) {
    return 'You: $text';
  }

  @override
  String get deleteMessage => 'Delete message';

  @override
  String get deleteMessageBody =>
      'Everyone in the chat will see “Message deleted”.';

  @override
  String get reportAction => 'Report';

  @override
  String get reportMessageTitle => 'Report message';

  @override
  String reportUserTitle(String name) {
    return 'Report $name';
  }

  @override
  String get reportReasonLabel => 'Reason';

  @override
  String get reportChooseReason => 'Choose a reason.';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonOffensive => 'Offensive content';

  @override
  String get reportReasonHarassment => 'Harassment';

  @override
  String get reportReasonOther => 'Other';

  @override
  String get reportDetails => 'Details (optional)';

  @override
  String get reportAlsoBlock => 'Also block this person';

  @override
  String get reportSend => 'Send report';

  @override
  String get reportSent => 'Report sent. Thank you.';

  @override
  String get groupName => 'Group name';

  @override
  String get chooseFriends => 'Choose friends';

  @override
  String get createGroup => 'Create group';

  @override
  String get groupNeedsMembers => 'Choose at least one friend.';

  @override
  String get groupNameInvalid => 'Use 1 to 60 characters.';

  @override
  String groupMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count members',
      one: '1 member',
    );
    return '$_temp0';
  }

  @override
  String get groupInfo => 'Group info';

  @override
  String get groupAdmin => 'Admin';

  @override
  String get addMembers => 'Add members';

  @override
  String get removeFromGroup => 'Remove from group';

  @override
  String removeFromGroupBody(String name) {
    return '$name will no longer see this group.';
  }

  @override
  String get leaveGroup => 'Leave group';

  @override
  String get leaveGroupBody => 'You\'ll no longer see this group\'s messages.';

  @override
  String get youLabel => 'You';

  @override
  String get noFriendsToAdd => 'All your friends are already in the group.';

  @override
  String get messageFriend => 'Message';

  @override
  String get chatErrorInvalidMessage =>
      'A message can have 1 to 2000 characters.';

  @override
  String get chatErrorTooManyMembers => 'A group can have up to 50 members.';

  @override
  String get chatErrorNotFound => 'This chat is no longer available.';

  @override
  String get chatErrorInvalidReport =>
      'Check the details: up to 500 characters.';

  @override
  String unreadMessagesBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count unread messages',
      one: '1 unread message',
    );
    return '$_temp0';
  }
}
