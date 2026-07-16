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
  String get statsSoon => 'Configurable dashboard coming soon (M6)';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';
}
