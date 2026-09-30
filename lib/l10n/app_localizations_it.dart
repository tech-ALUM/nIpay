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
  String get currency => 'Valuta';

  @override
  String get walletNameDuplicate => 'Esiste già un portafoglio con questo nome';

  @override
  String get walletNameRequired => 'Inserisci un nome per il portafoglio';

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
  String get exchangeRateError =>
      'Impossibile ottenere il tasso di cambio: controlla la connessione e riprova';

  @override
  String convertedPreview(String amount) {
    return '≈ $amount al tasso attuale';
  }

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
  String get apply => 'Applica';

  @override
  String get cancel => 'Annulla';

  @override
  String get delete => 'Elimina';

  @override
  String get deleteWalletTitle => 'Eliminare il portafoglio?';

  @override
  String deleteWalletBody(String name) {
    return 'Per confermare, scrivi \"$name\" nel campo qui sotto. L\'operazione non è reversibile.';
  }

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
  String get tagNameRequired => 'Inserisci un nome per il tag';

  @override
  String get tagNameDuplicate => 'Esiste già un tag con questo nome';

  @override
  String get costCenterNameRequired =>
      'Inserisci un nome per il centro di costo';

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
  String get language => 'Lingua';

  @override
  String get settingsTheme => 'Tema';

  @override
  String get themeSystem => 'Sistema';

  @override
  String get themeLight => 'Chiaro';

  @override
  String get themeDark => 'Scuro';

  @override
  String get account => 'Account';

  @override
  String get accountLocalModeDescription =>
      'Non hai fatto accesso: i tuoi dati restano solo su questo dispositivo. Accedi per sincronizzarli tra più dispositivi.';

  @override
  String get signIn => 'Accedi';

  @override
  String get signUp => 'Registrati';

  @override
  String get signOut => 'Esci';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmSignOut =>
      'Uscire dall\'account? I dati restano su questo dispositivo e continuano a funzionare offline.';

  @override
  String get noAccountYet => 'Non hai un account? Registrati';

  @override
  String get alreadyHaveAccount => 'Hai già un account? Accedi';

  @override
  String get forgotPassword => 'Password dimenticata?';

  @override
  String get resetPasswordSent =>
      'Email per il reset della password inviata — controlla la posta.';

  @override
  String signedInAs(String email) {
    return 'Accesso effettuato come $email';
  }

  @override
  String get invalidEmail => 'Inserisci un indirizzo email valido';

  @override
  String get passwordTooShort => 'La password deve avere almeno 8 caratteri';

  @override
  String get changePassword => 'Cambia password';

  @override
  String get newPassword => 'Nuova password';

  @override
  String get confirmPassword => 'Conferma password';

  @override
  String get passwordsDontMatch => 'Le password non coincidono';

  @override
  String get passwordChanged =>
      'Password cambiata. Gli altri dispositivi sono stati disconnessi.';

  @override
  String get syncNow => 'Sincronizza ora';

  @override
  String get syncComplete => 'Sincronizzazione completata';

  @override
  String get syncFailed =>
      'Sincronizzazione fallita. Controlla la connessione e riprova.';

  @override
  String get deleteAccount => 'Elimina account';

  @override
  String get deleteAccountConfirmBody =>
      'Il tuo account verrà eliminato definitivamente tra 30 giorni. Puoi annullare in qualsiasi momento prima di allora effettuando di nuovo l\'accesso. I dati su questo dispositivo non vengono toccati e continuano a funzionare offline.';

  @override
  String get deleteAccountRequested =>
      'Cancellazione account richiesta. Hai 30 giorni per annullare.';

  @override
  String deletionPending(String date) {
    return 'Account programmato per la cancellazione il $date.';
  }

  @override
  String get cancelDeletion => 'Annulla cancellazione';

  @override
  String get deletionCanceled => 'Cancellazione account annullata.';

  @override
  String get signOutRemoveLocalData => 'Rimuovi i dati da questo dispositivo';

  @override
  String get signOutRemoveLocalDataHint =>
      'I dati vengono prima sincronizzati sul tuo account, poi rimossi da questo dispositivo. Le foto degli scontrini non sono ancora sincronizzate e andranno perse.';

  @override
  String get signOutSyncFailed =>
      'Sincronizzazione non riuscita prima della rimozione. Non è stato rimosso nulla e sei ancora connesso: controlla la connessione e riprova.';

  @override
  String get localDataRemoved => 'Dati rimossi da questo dispositivo';

  @override
  String get foreignLocalDataBody =>
      'Questo dispositivo contiene i dati di un altro account: la sincronizzazione è sospesa per tenerli separati. Rimuovi quei dati per sincronizzare questo account, oppure esci.';

  @override
  String get removeLocalDataAndSync => 'Rimuovi i dati e sincronizza';

  @override
  String get removeForeignLocalDataConfirmBody =>
      'Tutti i portafogli, le transazioni e le foto degli scontrini su questo dispositivo verranno eliminati. Quanto l\'altro account ha già sincronizzato resta al sicuro nel suo account. Continuare?';

  @override
  String get syncBlockedForeignData =>
      'Sincronizzazione sospesa: questo dispositivo contiene i dati di un altro account.';
}
