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
