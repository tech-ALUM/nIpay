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
  String get receipt => 'Scontrino';

  @override
  String get fromCamera => 'Fotocamera';

  @override
  String get fromGallery => 'Galleria';

  @override
  String get attachments => 'Allegati';

  @override
  String get transactionDetail => 'Transazione';

  @override
  String get deleteTransaction => 'Elimina transazione';

  @override
  String get addCard => 'Aggiungi card';

  @override
  String get cardCategoryDonut => 'Spese per categoria';

  @override
  String get cardTrend => 'Trend 6 mesi';

  @override
  String get cardCashflow => 'Cash flow';

  @override
  String get cardBudget => 'Budget';

  @override
  String get netLabel => 'Netto';

  @override
  String get noStatsData => 'Nessun dato nel periodo.';

  @override
  String get emptyDashboard =>
      'Componi la tua dashboard: aggiungi la prima card.';

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
  String get backup => 'Backup';

  @override
  String get exportJson => 'Esporta backup JSON';

  @override
  String get exportExcel => 'Esporta Excel';

  @override
  String get importJson => 'Importa backup JSON';

  @override
  String get importExcel => 'Importa Excel';

  @override
  String get exportWalletJson => 'Esporta portafoglio attivo (JSON)';

  @override
  String get exportWalletExcel => 'Esporta portafoglio attivo (Excel)';

  @override
  String get importWallet => 'Importa portafoglio (aggiunge uno spazio)';

  @override
  String get walletImported => 'Portafoglio importato';

  @override
  String get importConfirmTitle => 'Sostituire tutti i dati?';

  @override
  String get importConfirmBody =>
      'L\'import sostituisce ogni portafoglio, transazione e impostazione con il contenuto del file. Operazione irreversibile.';

  @override
  String get importDone => 'Importazione completata';

  @override
  String get importFailed => 'Import fallito: file non valido';

  @override
  String get expenseReport => 'Nota spese';

  @override
  String get expenseReportFlag => 'Nota spese';

  @override
  String get costCenter => 'Centro di costo';

  @override
  String get manageCostCenters => 'Centri di costo';

  @override
  String get newCostCenter => 'Nuovo centro di costo';

  @override
  String get reimbursable => 'Rimborsabile';

  @override
  String get eInvoice => 'Fattura elettronica';

  @override
  String get pendingReimbursement => 'Da rimborsare';

  @override
  String get exportPdf => 'Esporta PDF';

  @override
  String get createReport => 'Crea nota spese';

  @override
  String get reportName => 'Nome nota spese';

  @override
  String get statusDraft => 'Bozza';

  @override
  String get statusSent => 'Inviata';

  @override
  String get statusReimbursed => 'Rimborsata';

  @override
  String get markSent => 'Segna inviata';

  @override
  String get markReimbursed => 'Segna rimborsata';

  @override
  String get reportArchive => 'Archivio';

  @override
  String get flaggedExpenses => 'Spese flaggate';

  @override
  String get expenseReportOnlyField => 'Solo per nota spese';

  @override
  String get edit => 'Modifica';

  @override
  String get editTransaction => 'Modifica transazione';

  @override
  String get fromDate => 'Dal';

  @override
  String get toDate => 'Al';

  @override
  String get none => 'Nessuno';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';
}
