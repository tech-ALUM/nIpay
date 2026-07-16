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
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

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
  String get backup => 'Backup';

  @override
  String get exportJson => 'Export JSON backup';

  @override
  String get exportExcel => 'Export Excel';

  @override
  String get importJson => 'Import JSON backup';

  @override
  String get importExcel => 'Import Excel';

  @override
  String get importConfirmTitle => 'Replace all data?';

  @override
  String get importConfirmBody =>
      'Importing replaces every wallet, transaction and setting with the file contents. This cannot be undone.';

  @override
  String get importDone => 'Import completed';

  @override
  String get importFailed => 'Import failed: invalid file';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';
}
