import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'nIpay'**
  String get appTitle;

  /// No description provided for @homeTab.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeTab;

  /// No description provided for @transactionsTab.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactionsTab;

  /// No description provided for @statsTab.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTab;

  /// No description provided for @settingsTab.
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get settingsTab;

  /// No description provided for @totalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get totalBalance;

  /// No description provided for @thisMonth.
  ///
  /// In en, this message translates to:
  /// **'this month'**
  String get thisMonth;

  /// No description provided for @wallets.
  ///
  /// In en, this message translates to:
  /// **'Wallets'**
  String get wallets;

  /// No description provided for @newWallet.
  ///
  /// In en, this message translates to:
  /// **'New wallet'**
  String get newWallet;

  /// No description provided for @walletName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get walletName;

  /// No description provided for @initialBalance.
  ///
  /// In en, this message translates to:
  /// **'Initial balance'**
  String get initialBalance;

  /// No description provided for @recentTransactions.
  ///
  /// In en, this message translates to:
  /// **'Recent transactions'**
  String get recentTransactions;

  /// No description provided for @noTransactions.
  ///
  /// In en, this message translates to:
  /// **'No transactions yet. Tap + to add the first one.'**
  String get noTransactions;

  /// No description provided for @noWallets.
  ///
  /// In en, this message translates to:
  /// **'Create your first wallet to get started.'**
  String get noWallets;

  /// No description provided for @newTransaction.
  ///
  /// In en, this message translates to:
  /// **'New transaction'**
  String get newTransaction;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @invalidAmount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalidAmount;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @wallet.
  ///
  /// In en, this message translates to:
  /// **'Wallet'**
  String get wallet;

  /// No description provided for @fromWallet.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromWallet;

  /// No description provided for @toWallet.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toWallet;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @allWallets.
  ///
  /// In en, this message translates to:
  /// **'All wallets'**
  String get allWallets;

  /// No description provided for @allCategories.
  ///
  /// In en, this message translates to:
  /// **'All categories'**
  String get allCategories;

  /// No description provided for @searchTransactions.
  ///
  /// In en, this message translates to:
  /// **'Search transactions…'**
  String get searchTransactions;

  /// No description provided for @receipt.
  ///
  /// In en, this message translates to:
  /// **'Receipt'**
  String get receipt;

  /// No description provided for @fromCamera.
  ///
  /// In en, this message translates to:
  /// **'Camera'**
  String get fromCamera;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'Gallery'**
  String get fromGallery;

  /// No description provided for @attachments.
  ///
  /// In en, this message translates to:
  /// **'Attachments'**
  String get attachments;

  /// No description provided for @transactionDetail.
  ///
  /// In en, this message translates to:
  /// **'Transaction'**
  String get transactionDetail;

  /// No description provided for @deleteTransaction.
  ///
  /// In en, this message translates to:
  /// **'Delete transaction'**
  String get deleteTransaction;

  /// No description provided for @addCard.
  ///
  /// In en, this message translates to:
  /// **'Add card'**
  String get addCard;

  /// No description provided for @cardCategoryDonut.
  ///
  /// In en, this message translates to:
  /// **'Expenses by category'**
  String get cardCategoryDonut;

  /// No description provided for @cardTrend.
  ///
  /// In en, this message translates to:
  /// **'6-month trend'**
  String get cardTrend;

  /// No description provided for @cardCashflow.
  ///
  /// In en, this message translates to:
  /// **'Cash flow'**
  String get cardCashflow;

  /// No description provided for @cardBudget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get cardBudget;

  /// No description provided for @netLabel.
  ///
  /// In en, this message translates to:
  /// **'Net'**
  String get netLabel;

  /// No description provided for @noStatsData.
  ///
  /// In en, this message translates to:
  /// **'No data for this period.'**
  String get noStatsData;

  /// No description provided for @emptyDashboard.
  ///
  /// In en, this message translates to:
  /// **'Compose your dashboard: add your first card.'**
  String get emptyDashboard;

  /// No description provided for @customization.
  ///
  /// In en, this message translates to:
  /// **'Customization'**
  String get customization;

  /// No description provided for @budgets.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budgets;

  /// No description provided for @newBudget.
  ///
  /// In en, this message translates to:
  /// **'New budget'**
  String get newBudget;

  /// No description provided for @monthlyLimit.
  ///
  /// In en, this message translates to:
  /// **'Monthly limit'**
  String get monthlyLimit;

  /// No description provided for @recurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring'**
  String get recurring;

  /// No description provided for @newRecurring.
  ///
  /// In en, this message translates to:
  /// **'New recurring transaction'**
  String get newRecurring;

  /// No description provided for @frequency.
  ///
  /// In en, this message translates to:
  /// **'Frequency'**
  String get frequency;

  /// No description provided for @freqDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get freqDaily;

  /// No description provided for @freqWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get freqWeekly;

  /// No description provided for @freqMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get freqMonthly;

  /// No description provided for @freqYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get freqYearly;

  /// No description provided for @startDate.
  ///
  /// In en, this message translates to:
  /// **'Start date'**
  String get startDate;

  /// No description provided for @nextRun.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextRun;

  /// No description provided for @paused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get paused;

  /// No description provided for @budgetNear.
  ///
  /// In en, this message translates to:
  /// **'Budget {category} at {percent}%'**
  String budgetNear(String category, int percent);

  /// No description provided for @budgetExceeded.
  ///
  /// In en, this message translates to:
  /// **'Budget {category} exceeded!'**
  String budgetExceeded(String category);

  /// No description provided for @manageCategories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get manageCategories;

  /// No description provided for @manageTags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get manageTags;

  /// No description provided for @manageCustomFields.
  ///
  /// In en, this message translates to:
  /// **'Custom fields'**
  String get manageCustomFields;

  /// No description provided for @newCategory.
  ///
  /// In en, this message translates to:
  /// **'New category'**
  String get newCategory;

  /// No description provided for @editCategory.
  ///
  /// In en, this message translates to:
  /// **'Edit category'**
  String get editCategory;

  /// No description provided for @icon.
  ///
  /// In en, this message translates to:
  /// **'Icon (emoji)'**
  String get icon;

  /// No description provided for @color.
  ///
  /// In en, this message translates to:
  /// **'Color'**
  String get color;

  /// No description provided for @kindBoth.
  ///
  /// In en, this message translates to:
  /// **'Both'**
  String get kindBoth;

  /// No description provided for @newTag.
  ///
  /// In en, this message translates to:
  /// **'New tag'**
  String get newTag;

  /// No description provided for @tagName.
  ///
  /// In en, this message translates to:
  /// **'Tag name'**
  String get tagName;

  /// No description provided for @newField.
  ///
  /// In en, this message translates to:
  /// **'New field'**
  String get newField;

  /// No description provided for @fieldName.
  ///
  /// In en, this message translates to:
  /// **'Field name'**
  String get fieldName;

  /// No description provided for @fieldType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get fieldType;

  /// No description provided for @typeText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get typeText;

  /// No description provided for @typeNumber.
  ///
  /// In en, this message translates to:
  /// **'Number'**
  String get typeNumber;

  /// No description provided for @typeChoice.
  ///
  /// In en, this message translates to:
  /// **'Choice'**
  String get typeChoice;

  /// No description provided for @typeDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get typeDate;

  /// No description provided for @choiceOptions.
  ///
  /// In en, this message translates to:
  /// **'Options (comma separated)'**
  String get choiceOptions;

  /// No description provided for @tags.
  ///
  /// In en, this message translates to:
  /// **'Tags'**
  String get tags;

  /// No description provided for @customFields.
  ///
  /// In en, this message translates to:
  /// **'Custom fields'**
  String get customFields;

  /// No description provided for @allTags.
  ///
  /// In en, this message translates to:
  /// **'All tags'**
  String get allTags;

  /// No description provided for @noItems.
  ///
  /// In en, this message translates to:
  /// **'Nothing here yet.'**
  String get noItems;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @exportJson.
  ///
  /// In en, this message translates to:
  /// **'Export JSON backup'**
  String get exportJson;

  /// No description provided for @exportExcel.
  ///
  /// In en, this message translates to:
  /// **'Export Excel'**
  String get exportExcel;

  /// No description provided for @importJson.
  ///
  /// In en, this message translates to:
  /// **'Import JSON backup'**
  String get importJson;

  /// No description provided for @importExcel.
  ///
  /// In en, this message translates to:
  /// **'Import Excel'**
  String get importExcel;

  /// No description provided for @exportWalletJson.
  ///
  /// In en, this message translates to:
  /// **'Export active wallet (JSON)'**
  String get exportWalletJson;

  /// No description provided for @exportWalletExcel.
  ///
  /// In en, this message translates to:
  /// **'Export active wallet (Excel)'**
  String get exportWalletExcel;

  /// No description provided for @importWallet.
  ///
  /// In en, this message translates to:
  /// **'Import wallet (adds a new space)'**
  String get importWallet;

  /// No description provided for @walletImported.
  ///
  /// In en, this message translates to:
  /// **'Wallet imported'**
  String get walletImported;

  /// No description provided for @importConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Replace all data?'**
  String get importConfirmTitle;

  /// No description provided for @importConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Importing replaces every wallet, transaction and setting with the file contents. This cannot be undone.'**
  String get importConfirmBody;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Import completed'**
  String get importDone;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Import failed: invalid file'**
  String get importFailed;

  /// No description provided for @expenseReport.
  ///
  /// In en, this message translates to:
  /// **'Expense report'**
  String get expenseReport;

  /// No description provided for @expenseReportFlag.
  ///
  /// In en, this message translates to:
  /// **'Expense report'**
  String get expenseReportFlag;

  /// No description provided for @costCenter.
  ///
  /// In en, this message translates to:
  /// **'Cost center'**
  String get costCenter;

  /// No description provided for @manageCostCenters.
  ///
  /// In en, this message translates to:
  /// **'Cost centers'**
  String get manageCostCenters;

  /// No description provided for @newCostCenter.
  ///
  /// In en, this message translates to:
  /// **'New cost center'**
  String get newCostCenter;

  /// No description provided for @reimbursable.
  ///
  /// In en, this message translates to:
  /// **'Reimbursable'**
  String get reimbursable;

  /// No description provided for @eInvoice.
  ///
  /// In en, this message translates to:
  /// **'E-invoice'**
  String get eInvoice;

  /// No description provided for @pendingReimbursement.
  ///
  /// In en, this message translates to:
  /// **'To be reimbursed'**
  String get pendingReimbursement;

  /// No description provided for @exportPdf.
  ///
  /// In en, this message translates to:
  /// **'Export PDF'**
  String get exportPdf;

  /// No description provided for @createReport.
  ///
  /// In en, this message translates to:
  /// **'Create expense report'**
  String get createReport;

  /// No description provided for @reportName.
  ///
  /// In en, this message translates to:
  /// **'Report name'**
  String get reportName;

  /// No description provided for @statusDraft.
  ///
  /// In en, this message translates to:
  /// **'Draft'**
  String get statusDraft;

  /// No description provided for @statusSent.
  ///
  /// In en, this message translates to:
  /// **'Sent'**
  String get statusSent;

  /// No description provided for @statusReimbursed.
  ///
  /// In en, this message translates to:
  /// **'Reimbursed'**
  String get statusReimbursed;

  /// No description provided for @markSent.
  ///
  /// In en, this message translates to:
  /// **'Mark as sent'**
  String get markSent;

  /// No description provided for @markReimbursed.
  ///
  /// In en, this message translates to:
  /// **'Mark as reimbursed'**
  String get markReimbursed;

  /// No description provided for @reportArchive.
  ///
  /// In en, this message translates to:
  /// **'Archive'**
  String get reportArchive;

  /// No description provided for @flaggedExpenses.
  ///
  /// In en, this message translates to:
  /// **'Flagged expenses'**
  String get flaggedExpenses;

  /// No description provided for @expenseReportOnlyField.
  ///
  /// In en, this message translates to:
  /// **'Only for expense reports'**
  String get expenseReportOnlyField;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @editTransaction.
  ///
  /// In en, this message translates to:
  /// **'Edit transaction'**
  String get editTransaction;

  /// No description provided for @fromDate.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get fromDate;

  /// No description provided for @toDate.
  ///
  /// In en, this message translates to:
  /// **'To'**
  String get toDate;

  /// No description provided for @none.
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get none;

  /// No description provided for @settingsTheme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get settingsTheme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
