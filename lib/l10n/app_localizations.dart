import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';
import 'app_localizations_hi.dart';
import 'app_localizations_it.dart';
import 'app_localizations_zh.dart';

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
    Locale('ar'),
    Locale('de'),
    Locale('en'),
    Locale('es'),
    Locale('fr'),
    Locale('hi'),
    Locale('it'),
    Locale('zh'),
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

  /// No description provided for @currency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get currency;

  /// No description provided for @walletNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A wallet with this name already exists'**
  String get walletNameDuplicate;

  /// No description provided for @walletNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a wallet name'**
  String get walletNameRequired;

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

  /// No description provided for @exchangeRateError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t get the exchange rate: check your connection and try again'**
  String get exchangeRateError;

  /// No description provided for @convertedPreview.
  ///
  /// In en, this message translates to:
  /// **'≈ {amount} at the current rate'**
  String convertedPreview(String amount);

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

  /// No description provided for @apply.
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

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

  /// No description provided for @deleteWalletTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete wallet?'**
  String get deleteWalletTitle;

  /// No description provided for @deleteWalletBody.
  ///
  /// In en, this message translates to:
  /// **'To confirm, type \"{name}\" in the field below. This cannot be undone.'**
  String deleteWalletBody(String name);

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

  /// No description provided for @tagNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a tag name'**
  String get tagNameRequired;

  /// No description provided for @tagNameDuplicate.
  ///
  /// In en, this message translates to:
  /// **'A tag with this name already exists'**
  String get tagNameDuplicate;

  /// No description provided for @costCenterNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a cost center name'**
  String get costCenterNameRequired;

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

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

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

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @accountLocalModeDescription.
  ///
  /// In en, this message translates to:
  /// **'You\'re not signed in: your data stays on this device only. Sign in to sync it across devices.'**
  String get accountLocalModeDescription;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @signUp.
  ///
  /// In en, this message translates to:
  /// **'Sign up'**
  String get signUp;

  /// No description provided for @signOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out of your account? Your data stays on this device, but it can only be opened again by signing in with this account.'**
  String get confirmSignOut;

  /// No description provided for @noAccountYet.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Sign up'**
  String get noAccountYet;

  /// No description provided for @alreadyHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// No description provided for @forgotPassword.
  ///
  /// In en, this message translates to:
  /// **'Forgot password?'**
  String get forgotPassword;

  /// No description provided for @resetPasswordSent.
  ///
  /// In en, this message translates to:
  /// **'Password reset email sent — check your inbox.'**
  String get resetPasswordSent;

  /// No description provided for @signedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {email}'**
  String signedInAs(String email);

  /// No description provided for @invalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address'**
  String get invalidEmail;

  /// No description provided for @passwordTooShort.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordTooShort;

  /// No description provided for @changePassword.
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePassword;

  /// No description provided for @newPassword.
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPassword;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @passwordsDontMatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords don\'t match'**
  String get passwordsDontMatch;

  /// No description provided for @passwordChanged.
  ///
  /// In en, this message translates to:
  /// **'Password changed. Other devices have been signed out.'**
  String get passwordChanged;

  /// No description provided for @syncNow.
  ///
  /// In en, this message translates to:
  /// **'Sync now'**
  String get syncNow;

  /// No description provided for @syncComplete.
  ///
  /// In en, this message translates to:
  /// **'Sync complete'**
  String get syncComplete;

  /// No description provided for @syncFailed.
  ///
  /// In en, this message translates to:
  /// **'Sync failed. Check your connection and try again.'**
  String get syncFailed;

  /// No description provided for @deleteAccount.
  ///
  /// In en, this message translates to:
  /// **'Delete account'**
  String get deleteAccount;

  /// No description provided for @deleteAccountConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Your account and its cloud data will be permanently deleted in 30 days. Until then you can cancel from this screen. The data on this device is not deleted.'**
  String get deleteAccountConfirmBody;

  /// No description provided for @deleteAccountRequested.
  ///
  /// In en, this message translates to:
  /// **'Account deletion requested. You have 30 days to cancel.'**
  String get deleteAccountRequested;

  /// No description provided for @deletionPending.
  ///
  /// In en, this message translates to:
  /// **'Account scheduled for deletion on {date}.'**
  String deletionPending(String date);

  /// No description provided for @cancelDeletion.
  ///
  /// In en, this message translates to:
  /// **'Cancel deletion'**
  String get cancelDeletion;

  /// No description provided for @deletionCanceled.
  ///
  /// In en, this message translates to:
  /// **'Account deletion canceled.'**
  String get deletionCanceled;

  /// No description provided for @signOutRemoveLocalData.
  ///
  /// In en, this message translates to:
  /// **'Remove data from this device'**
  String get signOutRemoveLocalData;

  /// No description provided for @signOutRemoveLocalDataHint.
  ///
  /// In en, this message translates to:
  /// **'Your data is synced to your account first, then removed from this device. Receipt photos are not synced yet and will be lost.'**
  String get signOutRemoveLocalDataHint;

  /// No description provided for @signOutSyncFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t sync before removing your data. Nothing was removed and you are still signed in: check your connection and try again.'**
  String get signOutSyncFailed;

  /// No description provided for @localDataRemoved.
  ///
  /// In en, this message translates to:
  /// **'Data removed from this device'**
  String get localDataRemoved;

  /// No description provided for @foreignLocalDataBody.
  ///
  /// In en, this message translates to:
  /// **'This device holds data from another account, so sync is paused to keep it separate. Remove that data to start syncing this account, or sign out.'**
  String get foreignLocalDataBody;

  /// No description provided for @removeLocalDataAndSync.
  ///
  /// In en, this message translates to:
  /// **'Remove data and sync'**
  String get removeLocalDataAndSync;

  /// No description provided for @removeForeignLocalDataConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'All wallets, transactions and receipt photos on this device will be deleted. Whatever the other account already synced stays safe in that account. Continue?'**
  String get removeForeignLocalDataConfirmBody;

  /// No description provided for @syncBlockedForeignData.
  ///
  /// In en, this message translates to:
  /// **'Sync paused: this device holds data from another account.'**
  String get syncBlockedForeignData;

  /// No description provided for @currentPassword.
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPassword;

  /// No description provided for @wrongCurrentPassword.
  ///
  /// In en, this message translates to:
  /// **'The current password is not correct.'**
  String get wrongCurrentPassword;

  /// No description provided for @confirmWithPassword.
  ///
  /// In en, this message translates to:
  /// **'Enter your password to confirm.'**
  String get confirmWithPassword;

  /// No description provided for @passwordTooWeak.
  ///
  /// In en, this message translates to:
  /// **'Use at least 12 characters, with letters and numbers.'**
  String get passwordTooWeak;

  /// No description provided for @signOutEverywhere.
  ///
  /// In en, this message translates to:
  /// **'Sign out of all devices'**
  String get signOutEverywhere;

  /// No description provided for @signOutEverywhereConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Every session of this account will be closed, including this one. Use it if a device was lost or stolen. Data on this device stays here.'**
  String get signOutEverywhereConfirmBody;

  /// No description provided for @signedOutEverywhere.
  ///
  /// In en, this message translates to:
  /// **'Signed out of all devices.'**
  String get signedOutEverywhere;

  /// No description provided for @authErrorInvalidCredentials.
  ///
  /// In en, this message translates to:
  /// **'Invalid email or password, or email not confirmed yet.'**
  String get authErrorInvalidCredentials;

  /// No description provided for @authErrorWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'This password isn\'t accepted: choose a longer, less common one.'**
  String get authErrorWeakPassword;

  /// No description provided for @authErrorSamePassword.
  ///
  /// In en, this message translates to:
  /// **'The new password must be different from the current one.'**
  String get authErrorSamePassword;

  /// No description provided for @authErrorRateLimited.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a few minutes and try again.'**
  String get authErrorRateLimited;

  /// No description provided for @authErrorReauthRequired.
  ///
  /// In en, this message translates to:
  /// **'For security, enter your password again and retry.'**
  String get authErrorReauthRequired;

  /// No description provided for @authErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the server. Check your connection and try again.'**
  String get authErrorNetwork;

  /// No description provided for @authErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get authErrorGeneric;

  /// No description provided for @resetPasswordTitle.
  ///
  /// In en, this message translates to:
  /// **'Set a new password'**
  String get resetPasswordTitle;

  /// No description provided for @passwordResetDone.
  ///
  /// In en, this message translates to:
  /// **'Password updated. Other devices have been signed out.'**
  String get passwordResetDone;

  /// No description provided for @resetPasswordCooldown.
  ///
  /// In en, this message translates to:
  /// **'Wait a minute before requesting another email.'**
  String get resetPasswordCooldown;

  /// No description provided for @lastSyncAt.
  ///
  /// In en, this message translates to:
  /// **'Last sync: {date}'**
  String lastSyncAt(String date);

  /// No description provided for @lastSyncNever.
  ///
  /// In en, this message translates to:
  /// **'Not synced yet'**
  String get lastSyncNever;

  /// No description provided for @syncLastFailed.
  ///
  /// In en, this message translates to:
  /// **'The last sync failed: it will be retried automatically.'**
  String get syncLastFailed;

  /// No description provided for @syncIssues.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item couldn\'t be synced and will be retried.} other{{count} items couldn\'t be synced and will be retried.}}'**
  String syncIssues(int count);

  /// No description provided for @lockedDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Data locked'**
  String get lockedDataTitle;

  /// No description provided for @lockedDataBody.
  ///
  /// In en, this message translates to:
  /// **'This device holds the data of {email}. Sign in with that account to see it, or remove it from this device.'**
  String lockedDataBody(String email);

  /// No description provided for @lockedDataBodyUnknownOwner.
  ///
  /// In en, this message translates to:
  /// **'This device holds the data of an account that is not signed in. Sign in with that account to see it, or remove it from this device.'**
  String get lockedDataBodyUnknownOwner;

  /// No description provided for @lockedDataOtherAccountBody.
  ///
  /// In en, this message translates to:
  /// **'This device holds the data of a different account. To use this account here, remove that data from the device (open Account), or sign out.'**
  String get lockedDataOtherAccountBody;

  /// No description provided for @startupError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open your data. Restart the app; if it keeps happening, contact support.'**
  String get startupError;

  /// No description provided for @attachmentUnsupported.
  ///
  /// In en, this message translates to:
  /// **'This image format isn\'t supported: use a JPEG, PNG or WebP photo.'**
  String get attachmentUnsupported;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @deleteItemTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete “{name}”?'**
  String deleteItemTitle(String name);

  /// No description provided for @deleteItemBody.
  ///
  /// In en, this message translates to:
  /// **'This can\'t be undone.'**
  String get deleteItemBody;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @fieldRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get fieldRequired;

  /// No description provided for @noWalletForTransaction.
  ///
  /// In en, this message translates to:
  /// **'Create a wallet first to add transactions.'**
  String get noWalletForTransaction;

  /// No description provided for @categoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryGroceries;

  /// No description provided for @categoryRestaurants.
  ///
  /// In en, this message translates to:
  /// **'Restaurants'**
  String get categoryRestaurants;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get categoryHousing;

  /// No description provided for @categoryLeisure.
  ///
  /// In en, this message translates to:
  /// **'Leisure'**
  String get categoryLeisure;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get categorySalary;

  /// No description provided for @categoryGifts.
  ///
  /// In en, this message translates to:
  /// **'Gifts'**
  String get categoryGifts;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @profileSection.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileSection;

  /// No description provided for @displayName.
  ///
  /// In en, this message translates to:
  /// **'Display name'**
  String get displayName;

  /// No description provided for @displayNameNotSet.
  ///
  /// In en, this message translates to:
  /// **'Not set'**
  String get displayNameNotSet;

  /// No description provided for @displayNameHelp.
  ///
  /// In en, this message translates to:
  /// **'Your friends see this name. Your email stays private.'**
  String get displayNameHelp;

  /// No description provided for @displayNameDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your name?'**
  String get displayNameDialogTitle;

  /// No description provided for @displayNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 1 to 40 characters.'**
  String get displayNameInvalid;

  /// No description provided for @displayNameSaved.
  ///
  /// In en, this message translates to:
  /// **'Name saved'**
  String get displayNameSaved;

  /// No description provided for @friendCode.
  ///
  /// In en, this message translates to:
  /// **'Your friend code'**
  String get friendCode;

  /// No description provided for @friendCodeHelp.
  ///
  /// In en, this message translates to:
  /// **'Share it to receive friend requests.'**
  String get friendCodeHelp;

  /// No description provided for @copyFriendCode.
  ///
  /// In en, this message translates to:
  /// **'Copy code'**
  String get copyFriendCode;

  /// No description provided for @friendCodeCopied.
  ///
  /// In en, this message translates to:
  /// **'Code copied'**
  String get friendCodeCopied;

  /// No description provided for @regenerateFriendCode.
  ///
  /// In en, this message translates to:
  /// **'Generate new code'**
  String get regenerateFriendCode;

  /// No description provided for @regenerateFriendCodeBody.
  ///
  /// In en, this message translates to:
  /// **'Your current code stops working: anyone who has it can no longer send you requests. The friends you already have stay.'**
  String get regenerateFriendCodeBody;

  /// No description provided for @friendCodeRegenerated.
  ///
  /// In en, this message translates to:
  /// **'New friend code ready'**
  String get friendCodeRegenerated;

  /// No description provided for @profileLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your profile. Check your connection and try again.'**
  String get profileLoadFailed;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @friendsTab.
  ///
  /// In en, this message translates to:
  /// **'Friends'**
  String get friendsTab;

  /// No description provided for @friendsSignInPrompt.
  ///
  /// In en, this message translates to:
  /// **'Sign in to add friends, chat and split expenses.'**
  String get friendsSignInPrompt;

  /// No description provided for @myQrCode.
  ///
  /// In en, this message translates to:
  /// **'My QR code'**
  String get myQrCode;

  /// No description provided for @addFriend.
  ///
  /// In en, this message translates to:
  /// **'Add friend'**
  String get addFriend;

  /// No description provided for @friendRequests.
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get friendRequests;

  /// No description provided for @friendsSection.
  ///
  /// In en, this message translates to:
  /// **'Your friends'**
  String get friendsSection;

  /// No description provided for @noFriendsYet.
  ///
  /// In en, this message translates to:
  /// **'No friends yet. Let a friend scan your QR code, or scan theirs.'**
  String get noFriendsYet;

  /// No description provided for @incomingRequestSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Wants to be your friend'**
  String get incomingRequestSubtitle;

  /// No description provided for @acceptRequest.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get acceptRequest;

  /// No description provided for @declineRequest.
  ///
  /// In en, this message translates to:
  /// **'Decline'**
  String get declineRequest;

  /// No description provided for @outgoingPending.
  ///
  /// In en, this message translates to:
  /// **'Waiting for a reply'**
  String get outgoingPending;

  /// No description provided for @outgoingDeclined.
  ///
  /// In en, this message translates to:
  /// **'Request not accepted'**
  String get outgoingDeclined;

  /// No description provided for @cancelRequest.
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelRequest;

  /// No description provided for @removeFriend.
  ///
  /// In en, this message translates to:
  /// **'Remove friend'**
  String get removeFriend;

  /// No description provided for @removeFriendBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will no longer be among your friends. You can add each other again later.'**
  String removeFriendBody(String name);

  /// No description provided for @blockUser.
  ///
  /// In en, this message translates to:
  /// **'Block'**
  String get blockUser;

  /// No description provided for @blockUserBody.
  ///
  /// In en, this message translates to:
  /// **'{name} won\'t be able to send you requests or find you with your code, and your friendship ends. They won\'t be notified.'**
  String blockUserBody(String name);

  /// No description provided for @blockedSection.
  ///
  /// In en, this message translates to:
  /// **'Blocked'**
  String get blockedSection;

  /// No description provided for @unblockUser.
  ///
  /// In en, this message translates to:
  /// **'Unblock'**
  String get unblockUser;

  /// No description provided for @unnamedUser.
  ///
  /// In en, this message translates to:
  /// **'Unnamed user'**
  String get unnamedUser;

  /// No description provided for @myQrAddName.
  ///
  /// In en, this message translates to:
  /// **'Add your name'**
  String get myQrAddName;

  /// No description provided for @myQrHelp.
  ///
  /// In en, this message translates to:
  /// **'Ask a friend to scan this code: their friend request will reach you.'**
  String get myQrHelp;

  /// No description provided for @shareFriendCode.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get shareFriendCode;

  /// No description provided for @shareFriendCodeText.
  ///
  /// In en, this message translates to:
  /// **'Add me on nIpay: {link} (code {code})'**
  String shareFriendCodeText(String link, String code);

  /// No description provided for @scanQrHint.
  ///
  /// In en, this message translates to:
  /// **'Point the camera at a friend\'s nIpay QR code.'**
  String get scanQrHint;

  /// No description provided for @cameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera not available. Allow access in Settings, or enter the code by hand.'**
  String get cameraUnavailable;

  /// No description provided for @enterCodeManually.
  ///
  /// In en, this message translates to:
  /// **'Or enter the code'**
  String get enterCodeManually;

  /// No description provided for @findFriend.
  ///
  /// In en, this message translates to:
  /// **'Find'**
  String get findFriend;

  /// No description provided for @invalidFriendCode.
  ///
  /// In en, this message translates to:
  /// **'This isn\'t a valid friend code.'**
  String get invalidFriendCode;

  /// No description provided for @notANipayQr.
  ///
  /// In en, this message translates to:
  /// **'This QR code isn\'t an nIpay friend code.'**
  String get notANipayQr;

  /// No description provided for @friendCodeNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No one found with this code.'**
  String get friendCodeNoMatch;

  /// No description provided for @sendFriendRequestTitle.
  ///
  /// In en, this message translates to:
  /// **'Send a friend request to {name}?'**
  String sendFriendRequestTitle(String name);

  /// No description provided for @sendRequest.
  ///
  /// In en, this message translates to:
  /// **'Send request'**
  String get sendRequest;

  /// No description provided for @friendRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent to {name}'**
  String friendRequestSent(String name);

  /// No description provided for @nowFriends.
  ///
  /// In en, this message translates to:
  /// **'You and {name} are now friends'**
  String nowFriends(String name);

  /// No description provided for @friendsErrorNotAvailable.
  ///
  /// In en, this message translates to:
  /// **'This person isn\'t available.'**
  String get friendsErrorNotAvailable;

  /// No description provided for @friendsErrorCooldown.
  ///
  /// In en, this message translates to:
  /// **'This person declined your request recently. Try again in a few days.'**
  String get friendsErrorCooldown;

  /// No description provided for @friendsErrorTooManyPending.
  ///
  /// In en, this message translates to:
  /// **'You have too many requests waiting. Cancel some or wait for replies.'**
  String get friendsErrorTooManyPending;

  /// No description provided for @friendsErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This request is no longer available.'**
  String get friendsErrorNotFound;

  /// No description provided for @friendsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your friends. Check your connection and try again.'**
  String get friendsLoadFailed;

  /// No description provided for @friendRequestsBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 friend request} other{{count} friend requests}}'**
  String friendRequestsBadge(int count);

  /// No description provided for @chatSection.
  ///
  /// In en, this message translates to:
  /// **'Chats'**
  String get chatSection;

  /// No description provided for @newGroup.
  ///
  /// In en, this message translates to:
  /// **'New group'**
  String get newGroup;

  /// No description provided for @noChatsYet.
  ///
  /// In en, this message translates to:
  /// **'No chats yet. Tap a friend to start one.'**
  String get noChatsYet;

  /// No description provided for @chatsLoadFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your chats. Check your connection and try again.'**
  String get chatsLoadFailed;

  /// No description provided for @messageHint.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageHint;

  /// No description provided for @sendMessage.
  ///
  /// In en, this message translates to:
  /// **'Send'**
  String get sendMessage;

  /// No description provided for @messageDeleted.
  ///
  /// In en, this message translates to:
  /// **'Message deleted'**
  String get messageDeleted;

  /// No description provided for @deletedUser.
  ///
  /// In en, this message translates to:
  /// **'Deleted user'**
  String get deletedUser;

  /// No description provided for @chatReadOnly.
  ///
  /// In en, this message translates to:
  /// **'You can no longer write in this chat.'**
  String get chatReadOnly;

  /// No description provided for @chatOffline.
  ///
  /// In en, this message translates to:
  /// **'You\'re offline. You can write again when you\'re back online.'**
  String get chatOffline;

  /// No description provided for @loadEarlierMessages.
  ///
  /// In en, this message translates to:
  /// **'Load earlier messages'**
  String get loadEarlierMessages;

  /// No description provided for @chatEmpty.
  ///
  /// In en, this message translates to:
  /// **'No messages yet. Say hi!'**
  String get chatEmpty;

  /// No description provided for @chatYouPrefix.
  ///
  /// In en, this message translates to:
  /// **'You: {text}'**
  String chatYouPrefix(String text);

  /// No description provided for @deleteMessage.
  ///
  /// In en, this message translates to:
  /// **'Delete message'**
  String get deleteMessage;

  /// No description provided for @deleteMessageBody.
  ///
  /// In en, this message translates to:
  /// **'Everyone in the chat will see “Message deleted”.'**
  String get deleteMessageBody;

  /// No description provided for @reportAction.
  ///
  /// In en, this message translates to:
  /// **'Report'**
  String get reportAction;

  /// No description provided for @reportMessageTitle.
  ///
  /// In en, this message translates to:
  /// **'Report message'**
  String get reportMessageTitle;

  /// No description provided for @reportUserTitle.
  ///
  /// In en, this message translates to:
  /// **'Report {name}'**
  String reportUserTitle(String name);

  /// No description provided for @reportReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get reportReasonLabel;

  /// No description provided for @reportChooseReason.
  ///
  /// In en, this message translates to:
  /// **'Choose a reason.'**
  String get reportChooseReason;

  /// No description provided for @reportReasonSpam.
  ///
  /// In en, this message translates to:
  /// **'Spam'**
  String get reportReasonSpam;

  /// No description provided for @reportReasonOffensive.
  ///
  /// In en, this message translates to:
  /// **'Offensive content'**
  String get reportReasonOffensive;

  /// No description provided for @reportReasonHarassment.
  ///
  /// In en, this message translates to:
  /// **'Harassment'**
  String get reportReasonHarassment;

  /// No description provided for @reportReasonOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get reportReasonOther;

  /// No description provided for @reportDetails.
  ///
  /// In en, this message translates to:
  /// **'Details (optional)'**
  String get reportDetails;

  /// No description provided for @reportAlsoBlock.
  ///
  /// In en, this message translates to:
  /// **'Also block this person'**
  String get reportAlsoBlock;

  /// No description provided for @reportSend.
  ///
  /// In en, this message translates to:
  /// **'Send report'**
  String get reportSend;

  /// No description provided for @reportSent.
  ///
  /// In en, this message translates to:
  /// **'Report sent. Thank you.'**
  String get reportSent;

  /// No description provided for @groupName.
  ///
  /// In en, this message translates to:
  /// **'Group name'**
  String get groupName;

  /// No description provided for @chooseFriends.
  ///
  /// In en, this message translates to:
  /// **'Choose friends'**
  String get chooseFriends;

  /// No description provided for @createGroup.
  ///
  /// In en, this message translates to:
  /// **'Create group'**
  String get createGroup;

  /// No description provided for @groupNeedsMembers.
  ///
  /// In en, this message translates to:
  /// **'Choose at least one friend.'**
  String get groupNeedsMembers;

  /// No description provided for @groupNameInvalid.
  ///
  /// In en, this message translates to:
  /// **'Use 1 to 60 characters.'**
  String get groupNameInvalid;

  /// No description provided for @groupMembersCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 member} other{{count} members}}'**
  String groupMembersCount(int count);

  /// No description provided for @groupInfo.
  ///
  /// In en, this message translates to:
  /// **'Group info'**
  String get groupInfo;

  /// No description provided for @groupAdmin.
  ///
  /// In en, this message translates to:
  /// **'Admin'**
  String get groupAdmin;

  /// No description provided for @addMembers.
  ///
  /// In en, this message translates to:
  /// **'Add members'**
  String get addMembers;

  /// No description provided for @removeFromGroup.
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get removeFromGroup;

  /// No description provided for @removeFromGroupBody.
  ///
  /// In en, this message translates to:
  /// **'{name} will no longer see this group.'**
  String removeFromGroupBody(String name);

  /// No description provided for @leaveGroup.
  ///
  /// In en, this message translates to:
  /// **'Leave group'**
  String get leaveGroup;

  /// No description provided for @leaveGroupBody.
  ///
  /// In en, this message translates to:
  /// **'You\'ll no longer see this group\'s messages.'**
  String get leaveGroupBody;

  /// No description provided for @youLabel.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get youLabel;

  /// No description provided for @noFriendsToAdd.
  ///
  /// In en, this message translates to:
  /// **'All your friends are already in the group.'**
  String get noFriendsToAdd;

  /// No description provided for @messageFriend.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get messageFriend;

  /// No description provided for @chatErrorInvalidMessage.
  ///
  /// In en, this message translates to:
  /// **'A message can have 1 to 2000 characters.'**
  String get chatErrorInvalidMessage;

  /// No description provided for @chatErrorTooManyMembers.
  ///
  /// In en, this message translates to:
  /// **'A group can have up to 50 members.'**
  String get chatErrorTooManyMembers;

  /// No description provided for @chatErrorNotFound.
  ///
  /// In en, this message translates to:
  /// **'This chat is no longer available.'**
  String get chatErrorNotFound;

  /// No description provided for @chatErrorInvalidReport.
  ///
  /// In en, this message translates to:
  /// **'Check the details: up to 500 characters.'**
  String get chatErrorInvalidReport;

  /// No description provided for @unreadMessagesBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 unread message} other{{count} unread messages}}'**
  String unreadMessagesBadge(int count);

  /// No description provided for @friendOut.
  ///
  /// In en, this message translates to:
  /// **'To friends'**
  String get friendOut;

  /// No description provided for @friendIn.
  ///
  /// In en, this message translates to:
  /// **'From friends'**
  String get friendIn;

  /// No description provided for @shareWithFriends.
  ///
  /// In en, this message translates to:
  /// **'Share with friends'**
  String get shareWithFriends;

  /// No description provided for @shareAddFriends.
  ///
  /// In en, this message translates to:
  /// **'Add friends'**
  String get shareAddFriends;

  /// No description provided for @shareWhoPaid.
  ///
  /// In en, this message translates to:
  /// **'Who paid?'**
  String get shareWhoPaid;

  /// No description provided for @sharePaidByMe.
  ///
  /// In en, this message translates to:
  /// **'Me'**
  String get sharePaidByMe;

  /// No description provided for @shareSplitEqually.
  ///
  /// In en, this message translates to:
  /// **'Equally'**
  String get shareSplitEqually;

  /// No description provided for @shareSplitCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom amounts'**
  String get shareSplitCustom;

  /// No description provided for @shareRemaining.
  ///
  /// In en, this message translates to:
  /// **'{amount} left to assign'**
  String shareRemaining(String amount);

  /// No description provided for @shareExcess.
  ///
  /// In en, this message translates to:
  /// **'{amount} too much'**
  String shareExcess(String amount);

  /// No description provided for @shareOwesYou.
  ///
  /// In en, this message translates to:
  /// **'{name} owes you {amount}'**
  String shareOwesYou(String name, String amount);

  /// No description provided for @shareYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe {name} {amount}'**
  String shareYouOwe(String name, String amount);

  /// No description provided for @shareYourShare.
  ///
  /// In en, this message translates to:
  /// **'Your share: {amount}'**
  String shareYourShare(String amount);

  /// No description provided for @shareNeedsConnection.
  ///
  /// In en, this message translates to:
  /// **'Sharing needs a connection. You can still save it as a normal expense.'**
  String get shareNeedsConnection;

  /// No description provided for @shareSplitMismatch.
  ///
  /// In en, this message translates to:
  /// **'The amounts must add up to the total.'**
  String get shareSplitMismatch;

  /// No description provided for @shareTooSmall.
  ///
  /// In en, this message translates to:
  /// **'The amount is too small to split between everyone.'**
  String get shareTooSmall;

  /// No description provided for @shareLinkedNote.
  ///
  /// In en, this message translates to:
  /// **'Shared expense: manage it in Friends.'**
  String get shareLinkedNote;

  /// No description provided for @shareErrorInvalid.
  ///
  /// In en, this message translates to:
  /// **'Check the shared expense: amounts, currency and friends.'**
  String get shareErrorInvalid;

  /// No description provided for @splitSection.
  ///
  /// In en, this message translates to:
  /// **'Shared expenses'**
  String get splitSection;

  /// No description provided for @splitTodo.
  ///
  /// In en, this message translates to:
  /// **'To do'**
  String get splitTodo;

  /// No description provided for @splitBalances.
  ///
  /// In en, this message translates to:
  /// **'Balances'**
  String get splitBalances;

  /// No description provided for @splitRecent.
  ///
  /// In en, this message translates to:
  /// **'Recent'**
  String get splitRecent;

  /// No description provided for @balanceOwesYou.
  ///
  /// In en, this message translates to:
  /// **'Owes you {amount}'**
  String balanceOwesYou(String amount);

  /// No description provided for @balanceYouOwe.
  ///
  /// In en, this message translates to:
  /// **'You owe {amount}'**
  String balanceYouOwe(String amount);

  /// No description provided for @settleAction.
  ///
  /// In en, this message translates to:
  /// **'Settle'**
  String get settleAction;

  /// No description provided for @settleTitle.
  ///
  /// In en, this message translates to:
  /// **'Pay back {name}'**
  String settleTitle(String name);

  /// No description provided for @settleAmountMax.
  ///
  /// In en, this message translates to:
  /// **'At most {amount}: that is what you owe.'**
  String settleAmountMax(String amount);

  /// No description provided for @settleRecorded.
  ///
  /// In en, this message translates to:
  /// **'Recorded. It counts once {name} confirms.'**
  String settleRecorded(String name);

  /// No description provided for @settleIncoming.
  ///
  /// In en, this message translates to:
  /// **'{name} says they paid you {amount}'**
  String settleIncoming(String name, String amount);

  /// No description provided for @settleReceived.
  ///
  /// In en, this message translates to:
  /// **'Received'**
  String get settleReceived;

  /// No description provided for @settleNotReceived.
  ///
  /// In en, this message translates to:
  /// **'Not received'**
  String get settleNotReceived;

  /// No description provided for @settleWaiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting for {name} to confirm {amount}'**
  String settleWaiting(String name, String amount);

  /// No description provided for @settleDeclined.
  ///
  /// In en, this message translates to:
  /// **'{name} didn\'t confirm {amount}'**
  String settleDeclined(String name, String amount);

  /// No description provided for @registerShareItem.
  ///
  /// In en, this message translates to:
  /// **'Your share of “{description}”: {amount}'**
  String registerShareItem(String description, String amount);

  /// No description provided for @registerSettlementOut.
  ///
  /// In en, this message translates to:
  /// **'Pay-back to {name} confirmed: {amount}'**
  String registerSettlementOut(String name, String amount);

  /// No description provided for @registerSettlementIn.
  ///
  /// In en, this message translates to:
  /// **'Pay-back from {name}: {amount}'**
  String registerSettlementIn(String name, String amount);

  /// No description provided for @registerAction.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get registerAction;

  /// No description provided for @registerTitle.
  ///
  /// In en, this message translates to:
  /// **'Add to a wallet'**
  String get registerTitle;

  /// No description provided for @registerConverted.
  ///
  /// In en, this message translates to:
  /// **'In this wallet: {amount}'**
  String registerConverted(String amount);

  /// No description provided for @registerDone.
  ///
  /// In en, this message translates to:
  /// **'Added to your wallet.'**
  String get registerDone;

  /// No description provided for @sharedExpenseFallbackTitle.
  ///
  /// In en, this message translates to:
  /// **'Shared expense'**
  String get sharedExpenseFallbackTitle;

  /// No description provided for @sharedExpensePaidBy.
  ///
  /// In en, this message translates to:
  /// **'Paid by {name} · your share {amount}'**
  String sharedExpensePaidBy(String name, String amount);

  /// No description provided for @sharedExpensePaidByYou.
  ///
  /// In en, this message translates to:
  /// **'Paid by you · your share {amount}'**
  String sharedExpensePaidByYou(String amount);

  /// No description provided for @splitLocked.
  ///
  /// In en, this message translates to:
  /// **'Someone has already registered their share, so it can no longer be changed.'**
  String get splitLocked;

  /// No description provided for @splitNotFound.
  ///
  /// In en, this message translates to:
  /// **'This no longer exists.'**
  String get splitNotFound;

  /// No description provided for @settleTooMuch.
  ///
  /// In en, this message translates to:
  /// **'That\'s more than you owe.'**
  String get settleTooMuch;

  /// No description provided for @editSharedExpense.
  ///
  /// In en, this message translates to:
  /// **'Edit shared expense'**
  String get editSharedExpense;

  /// No description provided for @deleteSharedExpenseBody.
  ///
  /// In en, this message translates to:
  /// **'It disappears for everyone, together with your movements in the wallet.'**
  String get deleteSharedExpenseBody;

  /// No description provided for @splitTodoBadge.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 shared expense to handle} other{{count} shared expenses to handle}}'**
  String splitTodoBadge(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>[
    'ar',
    'de',
    'en',
    'es',
    'fr',
    'hi',
    'it',
    'zh',
  ].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
    case 'hi':
      return AppLocalizationsHi();
    case 'it':
      return AppLocalizationsIt();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
