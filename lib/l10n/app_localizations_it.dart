// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get appTitle => 'nIpay';

  @override
  String get homeTab => 'Home';

  @override
  String get transactionsTab => 'Transazioni';

  @override
  String get statsTab => 'Statistiche';

  @override
  String get settingsTab => 'Altro';

  @override
  String get totalBalance => 'Saldo totale';

  @override
  String get thisMonth => 'questo mese';

  @override
  String get wallets => 'Portafogli';

  @override
  String get newWallet => 'Nuovo portafoglio';

  @override
  String get walletName => 'Nome';

  @override
  String get initialBalance => 'Saldo iniziale';

  @override
  String get recentTransactions => 'Ultime transazioni';

  @override
  String get noTransactions =>
      'Nessuna transazione. Tocca + per aggiungere la prima.';

  @override
  String get noWallets => 'Crea il tuo primo portafoglio per iniziare.';

  @override
  String get newTransaction => 'Nuova transazione';

  @override
  String get expense => 'Spesa';

  @override
  String get income => 'Entrata';

  @override
  String get transfer => 'Trasferimento';

  @override
  String get amount => 'Importo';

  @override
  String get invalidAmount => 'Importo non valido';

  @override
  String get description => 'Descrizione';

  @override
  String get category => 'Categoria';

  @override
  String get wallet => 'Portafoglio';

  @override
  String get fromWallet => 'Da';

  @override
  String get toWallet => 'A';

  @override
  String get date => 'Data';

  @override
  String get save => 'Salva';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get allWallets => 'Tutti i portafogli';

  @override
  String get allCategories => 'Tutte le categorie';

  @override
  String get searchTransactions => 'Cerca transazioni…';

  @override
  String get statsSoon => 'Dashboard componibile in arrivo (M6)';

  @override
  String get customization => 'Personalizzazione';

  @override
  String get budgets => 'Budget';

  @override
  String get newBudget => 'Nuovo budget';

  @override
  String get monthlyLimit => 'Tetto mensile';

  @override
  String get recurring => 'Ricorrenze';

  @override
  String get newRecurring => 'Nuova transazione ricorrente';

  @override
  String get frequency => 'Frequenza';

  @override
  String get freqDaily => 'Giornaliera';

  @override
  String get freqWeekly => 'Settimanale';

  @override
  String get freqMonthly => 'Mensile';

  @override
  String get freqYearly => 'Annuale';

  @override
  String get startDate => 'Data di inizio';

  @override
  String get nextRun => 'Prossima';

  @override
  String get paused => 'In pausa';

  @override
  String budgetNear(String category, int percent) {
    return 'Budget $category all\'$percent%';
  }

  @override
  String budgetExceeded(String category) {
    return 'Budget $category superato!';
  }

  @override
  String get manageCategories => 'Categorie';

  @override
  String get manageTags => 'Tag';

  @override
  String get manageCustomFields => 'Campi custom';

  @override
  String get newCategory => 'Nuova categoria';

  @override
  String get editCategory => 'Modifica categoria';

  @override
  String get icon => 'Icona (emoji)';

  @override
  String get color => 'Colore';

  @override
  String get kindBoth => 'Entrambi';

  @override
  String get newTag => 'Nuovo tag';

  @override
  String get tagName => 'Nome tag';

  @override
  String get newField => 'Nuovo campo';

  @override
  String get fieldName => 'Nome campo';

  @override
  String get fieldType => 'Tipo';

  @override
  String get typeText => 'Testo';

  @override
  String get typeNumber => 'Numero';

  @override
  String get typeChoice => 'Scelta';

  @override
  String get typeDate => 'Data';

  @override
  String get choiceOptions => 'Opzioni (separate da virgola)';

  @override
  String get tags => 'Tag';

  @override
  String get customFields => 'Campi custom';

  @override
  String get allTags => 'Tutti i tag';

  @override
  String get noItems => 'Ancora niente qui.';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';
}
