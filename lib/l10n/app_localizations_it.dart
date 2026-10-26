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
      'Uscire dall\'account? I dati restano su questo dispositivo, ma si potranno riaprire solo accedendo di nuovo con questo account.';

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
      'Il tuo account e i suoi dati sul cloud verranno eliminati definitivamente tra 30 giorni. Fino ad allora puoi annullare da questa schermata. I dati su questo dispositivo non vengono eliminati.';

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

  @override
  String get currentPassword => 'Password attuale';

  @override
  String get wrongCurrentPassword => 'La password attuale non è corretta.';

  @override
  String get confirmWithPassword => 'Inserisci la password per confermare.';

  @override
  String get passwordTooWeak =>
      'Usa almeno 12 caratteri, con lettere e numeri.';

  @override
  String get signOutEverywhere => 'Esci da tutti i dispositivi';

  @override
  String get signOutEverywhereConfirmBody =>
      'Verranno chiuse tutte le sessioni di questo account, compresa questa. Usalo se hai perso un dispositivo o te l\'hanno rubato. I dati su questo dispositivo restano qui.';

  @override
  String get signedOutEverywhere => 'Disconnesso da tutti i dispositivi.';

  @override
  String get authErrorInvalidCredentials =>
      'Email o password non validi, oppure email non ancora confermata.';

  @override
  String get authErrorWeakPassword =>
      'Questa password non è accettata: scegline una più lunga e meno comune.';

  @override
  String get authErrorSamePassword =>
      'La nuova password deve essere diversa da quella attuale.';

  @override
  String get authErrorRateLimited =>
      'Troppi tentativi. Attendi qualche minuto e riprova.';

  @override
  String get authErrorReauthRequired =>
      'Per sicurezza, inserisci di nuovo la password e riprova.';

  @override
  String get authErrorNetwork =>
      'Server non raggiungibile. Controlla la connessione e riprova.';

  @override
  String get authErrorGeneric => 'Qualcosa è andato storto. Riprova.';

  @override
  String get resetPasswordTitle => 'Imposta una nuova password';

  @override
  String get passwordResetDone =>
      'Password aggiornata. Gli altri dispositivi sono stati disconnessi.';

  @override
  String get resetPasswordCooldown =>
      'Attendi un minuto prima di richiedere un\'altra email.';

  @override
  String lastSyncAt(String date) {
    return 'Ultima sincronizzazione: $date';
  }

  @override
  String get lastSyncNever => 'Non ancora sincronizzato';

  @override
  String get syncLastFailed =>
      'L\'ultima sincronizzazione non è riuscita: verrà ritentata automaticamente.';

  @override
  String syncIssues(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          '$count elementi non sono stati sincronizzati e verranno ritentati.',
      one: '1 elemento non è stato sincronizzato e verrà ritentato.',
    );
    return '$_temp0';
  }

  @override
  String get lockedDataTitle => 'Dati bloccati';

  @override
  String lockedDataBody(String email) {
    return 'Questo dispositivo contiene i dati di $email. Accedi con quell\'account per vederli, oppure rimuovili dal dispositivo.';
  }

  @override
  String get lockedDataBodyUnknownOwner =>
      'Questo dispositivo contiene i dati di un account non connesso. Accedi con quell\'account per vederli, oppure rimuovili dal dispositivo.';

  @override
  String get lockedDataOtherAccountBody =>
      'Questo dispositivo contiene i dati di un altro account. Per usare questo account qui, rimuovi quei dati dal dispositivo (apri Account), oppure esci.';

  @override
  String get startupError =>
      'Impossibile aprire i tuoi dati. Riavvia l\'app; se il problema continua, contatta l\'assistenza.';

  @override
  String get attachmentUnsupported =>
      'Formato immagine non supportato: usa una foto JPEG, PNG o WebP.';

  @override
  String get pause => 'Metti in pausa';

  @override
  String get resume => 'Riprendi';

  @override
  String deleteItemTitle(String name) {
    return 'Eliminare “$name”?';
  }

  @override
  String get deleteItemBody => 'L\'operazione non è reversibile.';

  @override
  String get showPassword => 'Mostra password';

  @override
  String get hidePassword => 'Nascondi password';

  @override
  String get fieldRequired => 'Obbligatorio';

  @override
  String get noWalletForTransaction =>
      'Crea prima un portafoglio per aggiungere transazioni.';

  @override
  String get categoryGroceries => 'Spesa';

  @override
  String get categoryRestaurants => 'Ristoranti';

  @override
  String get categoryTransport => 'Trasporti';

  @override
  String get categoryHousing => 'Casa';

  @override
  String get categoryLeisure => 'Svago';

  @override
  String get categoryHealth => 'Salute';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categorySalary => 'Stipendio';

  @override
  String get categoryGifts => 'Regali';

  @override
  String get categoryOther => 'Altro';

  @override
  String get profileSection => 'Profilo';

  @override
  String get displayName => 'Nome visualizzato';

  @override
  String get displayNameNotSet => 'Non impostato';

  @override
  String get displayNameHelp =>
      'I tuoi amici vedono questo nome. La tua email resta privata.';

  @override
  String get displayNameDialogTitle => 'Come ti chiami?';

  @override
  String get displayNameInvalid => 'Usa da 1 a 40 caratteri.';

  @override
  String get displayNameSaved => 'Nome salvato';

  @override
  String get friendCode => 'Il tuo codice amico';

  @override
  String get friendCodeHelp =>
      'Condividilo per ricevere richieste di amicizia.';

  @override
  String get copyFriendCode => 'Copia codice';

  @override
  String get friendCodeCopied => 'Codice copiato';

  @override
  String get regenerateFriendCode => 'Genera nuovo codice';

  @override
  String get regenerateFriendCodeBody =>
      'Il codice attuale smette di funzionare: chi ce l\'ha non potrà più inviarti richieste. Gli amici che hai già restano.';

  @override
  String get friendCodeRegenerated => 'Nuovo codice amico pronto';

  @override
  String get profileLoadFailed =>
      'Impossibile caricare il profilo. Controlla la connessione e riprova.';

  @override
  String get retry => 'Riprova';

  @override
  String get friendsTab => 'Amici';

  @override
  String get friendsSignInPrompt =>
      'Accedi per aggiungere amici, chattare e dividere le spese.';

  @override
  String get myQrCode => 'Il mio QR';

  @override
  String get addFriend => 'Aggiungi amico';

  @override
  String get friendRequests => 'Richieste';

  @override
  String get friendsSection => 'I tuoi amici';

  @override
  String get noFriendsYet =>
      'Ancora nessun amico. Fai scansionare il tuo QR a un amico, oppure scansiona il suo.';

  @override
  String get incomingRequestSubtitle => 'Vuole essere tuo amico';

  @override
  String get acceptRequest => 'Accetta';

  @override
  String get declineRequest => 'Rifiuta';

  @override
  String get outgoingPending => 'In attesa di risposta';

  @override
  String get outgoingDeclined => 'Richiesta non accettata';

  @override
  String get cancelRequest => 'Annulla richiesta';

  @override
  String get removeFriend => 'Rimuovi amico';

  @override
  String removeFriendBody(String name) {
    return '$name non sarà più tra i tuoi amici. Potrete aggiungervi di nuovo in seguito.';
  }

  @override
  String get blockUser => 'Blocca';

  @override
  String blockUserBody(String name) {
    return '$name non potrà più inviarti richieste né trovarti col tuo codice, e la vostra amicizia finisce. Non riceverà nessun avviso.';
  }

  @override
  String get blockedSection => 'Bloccati';

  @override
  String get unblockUser => 'Sblocca';

  @override
  String get unnamedUser => 'Utente senza nome';

  @override
  String get myQrAddName => 'Aggiungi il tuo nome';

  @override
  String get myQrHelp =>
      'Fai inquadrare questo codice a un amico: ti arriverà la sua richiesta di amicizia.';

  @override
  String get shareFriendCode => 'Condividi';

  @override
  String shareFriendCodeText(String link, String code) {
    return 'Aggiungimi su nIpay: $link (codice $code)';
  }

  @override
  String get scanQrHint => 'Inquadra il QR nIpay di un amico.';

  @override
  String get cameraUnavailable =>
      'Fotocamera non disponibile. Consenti l\'accesso nelle Impostazioni, oppure inserisci il codice a mano.';

  @override
  String get enterCodeManually => 'Oppure inserisci il codice';

  @override
  String get findFriend => 'Cerca';

  @override
  String get invalidFriendCode => 'Questo non è un codice amico valido.';

  @override
  String get notANipayQr => 'Questo QR non è un codice amico nIpay.';

  @override
  String get friendCodeNoMatch => 'Nessuno trovato con questo codice.';

  @override
  String sendFriendRequestTitle(String name) {
    return 'Inviare una richiesta di amicizia a $name?';
  }

  @override
  String get sendRequest => 'Invia richiesta';

  @override
  String friendRequestSent(String name) {
    return 'Richiesta inviata a $name';
  }

  @override
  String nowFriends(String name) {
    return 'Ora tu e $name siete amici';
  }

  @override
  String get friendsErrorNotAvailable => 'Questa persona non è disponibile.';

  @override
  String get friendsErrorCooldown =>
      'Questa persona ha rifiutato la tua richiesta di recente. Riprova tra qualche giorno.';

  @override
  String get friendsErrorTooManyPending =>
      'Hai troppe richieste in attesa. Annullane qualcuna o aspetta le risposte.';

  @override
  String get friendsErrorNotFound => 'Questa richiesta non è più disponibile.';

  @override
  String get friendsLoadFailed =>
      'Impossibile caricare gli amici. Controlla la connessione e riprova.';

  @override
  String friendRequestsBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count richieste di amicizia',
      one: '1 richiesta di amicizia',
    );
    return '$_temp0';
  }

  @override
  String get chatSection => 'Chat';

  @override
  String get newGroup => 'Nuovo gruppo';

  @override
  String get noChatsYet => 'Nessuna chat. Tocca un amico per iniziarne una.';

  @override
  String get chatsLoadFailed =>
      'Impossibile caricare le chat. Controlla la connessione e riprova.';

  @override
  String get messageHint => 'Messaggio';

  @override
  String get sendMessage => 'Invia';

  @override
  String get messageDeleted => 'Messaggio eliminato';

  @override
  String get deletedUser => 'Utente eliminato';

  @override
  String get chatReadOnly => 'Non puoi più scrivere in questa chat.';

  @override
  String get chatOffline => 'Sei offline: potrai scrivere quando torni online.';

  @override
  String get loadEarlierMessages => 'Carica messaggi precedenti';

  @override
  String get chatEmpty => 'Ancora nessun messaggio. Saluta!';

  @override
  String chatYouPrefix(String text) {
    return 'Tu: $text';
  }

  @override
  String get deleteMessage => 'Elimina messaggio';

  @override
  String get deleteMessageBody =>
      'Tutti nella chat vedranno “Messaggio eliminato”.';

  @override
  String get reportAction => 'Segnala';

  @override
  String get reportMessageTitle => 'Segnala messaggio';

  @override
  String reportUserTitle(String name) {
    return 'Segnala $name';
  }

  @override
  String get reportReasonLabel => 'Motivo';

  @override
  String get reportChooseReason => 'Scegli un motivo.';

  @override
  String get reportReasonSpam => 'Spam';

  @override
  String get reportReasonOffensive => 'Contenuto offensivo';

  @override
  String get reportReasonHarassment => 'Molestie';

  @override
  String get reportReasonOther => 'Altro';

  @override
  String get reportDetails => 'Dettagli (facoltativi)';

  @override
  String get reportAlsoBlock => 'Blocca anche questa persona';

  @override
  String get reportSend => 'Invia segnalazione';

  @override
  String get reportSent => 'Segnalazione inviata. Grazie.';

  @override
  String get groupName => 'Nome del gruppo';

  @override
  String get chooseFriends => 'Scegli gli amici';

  @override
  String get createGroup => 'Crea gruppo';

  @override
  String get groupNeedsMembers => 'Scegli almeno un amico.';

  @override
  String get groupNameInvalid => 'Usa da 1 a 60 caratteri.';

  @override
  String groupMembersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count membri',
      one: '1 membro',
    );
    return '$_temp0';
  }

  @override
  String get groupInfo => 'Info gruppo';

  @override
  String get groupAdmin => 'Admin';

  @override
  String get addMembers => 'Aggiungi membri';

  @override
  String get removeFromGroup => 'Rimuovi dal gruppo';

  @override
  String removeFromGroupBody(String name) {
    return '$name non vedrà più questo gruppo.';
  }

  @override
  String get leaveGroup => 'Esci dal gruppo';

  @override
  String get leaveGroupBody => 'Non vedrai più i messaggi di questo gruppo.';

  @override
  String get youLabel => 'Tu';

  @override
  String get noFriendsToAdd => 'Tutti i tuoi amici sono già nel gruppo.';

  @override
  String get messageFriend => 'Scrivi';

  @override
  String get chatErrorInvalidMessage =>
      'Un messaggio va da 1 a 2000 caratteri.';

  @override
  String get chatErrorTooManyMembers =>
      'Un gruppo può avere al massimo 50 membri.';

  @override
  String get chatErrorNotFound => 'Questa chat non è più disponibile.';

  @override
  String get chatErrorInvalidReport =>
      'Controlla i dettagli: al massimo 500 caratteri.';

  @override
  String unreadMessagesBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count messaggi non letti',
      one: '1 messaggio non letto',
    );
    return '$_temp0';
  }

  @override
  String get friendOut => 'Verso amici';

  @override
  String get friendIn => 'Da amici';

  @override
  String get shareWithFriends => 'Condividi con amici';

  @override
  String get shareAddFriends => 'Aggiungi amici';

  @override
  String get shareWhoPaid => 'Chi ha pagato?';

  @override
  String get sharePaidByMe => 'Io';

  @override
  String get shareSplitEqually => 'In parti uguali';

  @override
  String get shareSplitCustom => 'Importi diversi';

  @override
  String shareRemaining(String amount) {
    return 'Mancano $amount';
  }

  @override
  String shareExcess(String amount) {
    return '$amount in più';
  }

  @override
  String shareOwesYou(String name, String amount) {
    return '$name ti deve $amount';
  }

  @override
  String shareYouOwe(String name, String amount) {
    return 'Devi $amount a $name';
  }

  @override
  String shareYourShare(String amount) {
    return 'La tua quota: $amount';
  }

  @override
  String get shareNeedsConnection =>
      'Serve la connessione per condividere: puoi comunque salvarla come spesa normale.';

  @override
  String get shareSplitMismatch => 'Gli importi devono tornare col totale.';

  @override
  String get shareTooSmall =>
      'L\'importo è troppo piccolo da dividere fra tutti.';

  @override
  String get shareLinkedNote => 'Spesa divisa: si gestisce in Amici.';

  @override
  String get shareErrorInvalid =>
      'Controlla la spesa divisa: importi, valuta e amici.';

  @override
  String get splitSection => 'Spese divise';

  @override
  String get splitTodo => 'Da fare';

  @override
  String get splitBalances => 'Saldi';

  @override
  String get splitRecent => 'Recenti';

  @override
  String balanceOwesYou(String amount) {
    return 'Ti deve $amount';
  }

  @override
  String balanceYouOwe(String amount) {
    return 'Devi $amount';
  }

  @override
  String get settleAction => 'Salda';

  @override
  String settleTitle(String name) {
    return 'Rimborsa $name';
  }

  @override
  String settleAmountMax(String amount) {
    return 'Al massimo $amount: è quanto devi.';
  }

  @override
  String settleRecorded(String name) {
    return 'Registrato: conta quando $name lo conferma.';
  }

  @override
  String settleIncoming(String name, String amount) {
    return '$name dice di averti dato $amount';
  }

  @override
  String get settleReceived => 'Ricevuto';

  @override
  String get settleNotReceived => 'Non ricevuto';

  @override
  String settleWaiting(String name, String amount) {
    return 'In attesa che $name confermi $amount';
  }

  @override
  String settleDeclined(String name, String amount) {
    return '$name non ha confermato $amount';
  }

  @override
  String registerShareItem(String description, String amount) {
    return 'La tua quota di “$description”: $amount';
  }

  @override
  String registerSettlementOut(String name, String amount) {
    return 'Rimborso a $name confermato: $amount';
  }

  @override
  String registerSettlementIn(String name, String amount) {
    return 'Rimborso da $name: $amount';
  }

  @override
  String get registerAction => 'Registra';

  @override
  String get registerTitle => 'Registra in un portafoglio';

  @override
  String registerConverted(String amount) {
    return 'In questo portafoglio: $amount';
  }

  @override
  String get registerDone => 'Registrato nel portafoglio.';

  @override
  String get sharedExpenseFallbackTitle => 'Spesa divisa';

  @override
  String sharedExpensePaidBy(String name, String amount) {
    return 'Pagata da $name · la tua quota $amount';
  }

  @override
  String sharedExpensePaidByYou(String amount) {
    return 'Pagata da te · la tua quota $amount';
  }

  @override
  String get splitLocked =>
      'Qualcuno ha già registrato la sua quota: non si può più modificare.';

  @override
  String get splitNotFound => 'Non esiste più.';

  @override
  String get settleTooMuch => 'È più di quanto devi.';

  @override
  String get editSharedExpense => 'Modifica spesa divisa';

  @override
  String get deleteSharedExpenseBody =>
      'Sparisce per tutti, insieme ai tuoi movimenti nel portafoglio.';

  @override
  String splitTodoBadge(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count spese divise da gestire',
      one: '1 spesa divisa da gestire',
    );
    return '$_temp0';
  }

  @override
  String get accountPendingDeletionError =>
      'Il tuo account è in cancellazione: puoi solo leggere e saldare i debiti.';

  @override
  String get privacyPolicy => 'Informativa sulla privacy';

  @override
  String get termsOfUse => 'Termini d\'uso';

  @override
  String get signUpLegalConsent =>
      'Ho almeno 16 anni, accetto i Termini d\'uso e ho letto l\'Informativa sulla privacy.';

  @override
  String get signUpLegalConsentRequired =>
      'Per creare un account devi confermare questa casella.';

  @override
  String get legalLinkError =>
      'Impossibile aprire la pagina. Riprova più tardi.';
}
