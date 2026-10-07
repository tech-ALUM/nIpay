# nIpay — Checklist di test pre-commit

Da passare prima di ogni **commit importante**: modifica allo schema Drift o
Postgres, tocchi a sync/auth/RLS, nuova feature, release (APK/IPA per il team).

**Come usarla**
- Copia la sezione "Registro esecuzione" in fondo nella descrizione del
  commit/PR e spunta lì, non in questo file.
- **Livello rapido** (commit di feature normale): sezione 1 + le sezioni
  della/e feature toccate + sezione 14 (sicurezza, parte "sempre").
- **Livello completo** (schema, sync/auth, release): tutto.
- 🤖 = già coperto da test automatici (file indicato). Se la sezione 1 è
  verde, a mano basta un controllo visivo rapido.
- ⚠️ = punto debole noto (vedi sezione 16): controllalo a mano con
  attenzione finché non c'è un test.

Dispositivi: Android su **Waydroid con APK debug**, iOS su iPhone via
Sideloader (IPA non firmata). Per sync/account servono **2 dispositivi** (o
Waydroid + iPhone) e **2 account di test** (A e B), mai account reali.

---

## 1. Controlli automatici (sempre)

- [ ] `flutter pub get && flutter gen-l10n` senza errori.
- [ ] `flutter analyze` → *No issues found*.
- [ ] `flutter test` → tutti verdi (inclusi i property test `forAll`).
- [ ] Se lo schema Drift è cambiato: `dart run build_runner build --delete-conflicting-outputs`
      eseguito, `schemaVersion` incrementato, migration scritta in
      `app_database.dart`, valutato il bump di `kExportSchemaVersion`.
- [ ] Se `supabase/` è cambiata: workflow **Supabase RLS** verde su GitHub
      (`supabase/tests/`, gira da solo al push), poi migration applicata al
      progetto reale (`supabase db push`) e `./scripts/test_rls.sh` →
      *0 falliti* (vedi sezione 14).
- [ ] `git status`: nessun file sensibile in staging (`android/key.properties`,
      `*.jks`, `.env*`, `supabase/.temp/`, `*.ipa`, `build/`).
- [ ] CI GitHub Actions verde dopo il push (Android + workflow iOS se toccato
      `ios/**`).

## 2. Installazione, avvio e migrazione dati

- [ ] **Installazione pulita**: l'app parte, home vuota con invito a creare un
      portafoglio, nessun crash. 🤖 `app_test.dart`
- [ ] **Aggiornamento sopra la build precedente** (senza disinstallare): i dati
      esistenti ci sono tutti (portafogli, transazioni, allegati, note spese).
      *Obbligatorio se è cambiato `schemaVersion`.*
- [ ] Riavvio app (kill + riapertura): portafoglio attivo, tema e lingua
      restano quelli scelti.
- [ ] Nessuna schermata rossa di errore / spinner infinito al bootstrap
      (seed categorie + recupero ricorrenze).

## 3. Portafogli (spazi separati)

- [ ] Crea un portafoglio con nome, colore, icona, saldo iniziale e valuta:
      il saldo in home è corretto. 🤖 `wallet_repository_test.dart`, `app_test.dart`
- [ ] Nome vuoto → messaggio d'errore, nessun crash. Nome duplicato → errore. 🤖
- [ ] Modifica portafoglio: le modifiche si vedono subito in home.
- [ ] Riordino dei portafogli: l'ordine resta dopo il riavvio. 🤖
- [ ] **Cambio valuta** del portafoglio: viene riscalato solo il saldo
      iniziale, nient'altro. 🤖 `wallet_repository_test.dart`
- [ ] Elimina portafoglio: conferma richiesta, sparisce dalla lista, il
      totale in home si aggiorna.
- [ ] Toccare la wallet card cambia il **portafoglio attivo**: transazioni,
      categorie, tag, budget, dashboard cambiano di conseguenza. 🤖 `app_test.dart`
- [ ] Un nuovo portafoglio riceve le **categorie di default**. 🤖 `category_repository_test.dart`

## 4. Transazioni

- [ ] Aggiungi **spesa**: saldo e lista "recenti" aggiornati. 🤖 `app_test.dart`
- [ ] Aggiungi **entrata**: saldo aumenta.
- [ ] **Trasferimento** tra due portafogli: sottrae da uno e aggiunge
      all'altro, niente categoria, escluso dai totali entrate/uscite. 🤖 `transaction_repository_test.dart`
- [ ] Trasferimento tra portafogli con **valute diverse**: anteprima importo
      convertito visibile; con tasso non disponibile compare un errore
      chiaro, non un crash. 🤖 `exchange_rate_service_test.dart`
- [ ] Importi: `12,50` e `12.50` accettati; testo non numerico / vuoto /
      negativo rifiutato con messaggio. 🤖 `money_property_test.dart`
- [ ] Importi grandi (es. 999.999,99) e piccoli (0,01) visualizzati
      correttamente, 2 decimali, segno giusto. 🤖 `money_format_test.dart`
- [ ] Modifica transazione (importo, categoria, data, descrizione): saldo
      ricalcolato.
- [ ] Elimina transazione: sparisce e **non** conta più nel saldo. 🤖
- [ ] Dettaglio transazione: mostra tutti i campi, tag, campi custom,
      allegati, dati nota spese.
- [ ] Ricerca testuale e filtri (categoria, tag, periodo) nella lista
      transazioni. 🤖 parziale `app_test.dart`

## 5. Categorie, tag, campi custom, centri di costo

- [ ] Categorie: crea (anche sottocategoria), modifica nome/icona/colore,
      riordina, elimina. Categorie visibili solo nel loro portafoglio. 🤖 `category_repository_test.dart`
- [ ] Tag: crea dal manager e **inline** dalla transazione; nome vuoto o
      duplicato → errore. Filtro per tag funziona. 🤖 `app_test.dart`, `tag_customfield_test.dart`
- [ ] Campi custom di tutti i tipi: **testo, numero, scelta, data**;
      valore salvato e mostrato nel dettaglio; "solo nota spese" compare
      solo per le spese flaggate. 🤖 parziale
- [ ] Centri di costo: crea, rinomina, elimina; selezionabili nella nota spese.

## 6. Ricorrenze

- [ ] Crea una ricorrenza per ciascuna frequenza (giornaliera, settimanale,
      mensile, annuale).
- [ ] **Recupero arretrati**: con una ricorrenza nel passato, riaprendo l'app
      vengono generate le occorrenze mancanti, **una sola volta** (riavviare
      di nuovo non le duplica). 🤖 `budget_recurring_test.dart`
- [ ] Pausa → non genera; riprendi → riparte. 🤖
- [ ] Elimina ricorrenza: le transazioni già generate restano.

## 7. Budget

- [ ] Crea budget mensile su una categoria: barra di avanzamento in home. 🤖 `app_test.dart`
- [ ] All'80% compare l'avviso "quasi esaurito", al 100% "superato". 🤖
- [ ] Il mese nuovo riparte da zero; i trasferimenti non contano.

## 8. Statistiche / dashboard

- [ ] Aggiungi ciascuna card: **torta categorie, trend, cashflow, budget**. 🤖 parziale
- [ ] Riordina e rimuovi card: la configurazione resta dopo il riavvio e
      vale per singolo portafoglio. 🤖 `attachment_dashboard_test.dart`
- [ ] Portafoglio senza dati → stato vuoto, nessun grafico rotto o crash.
- [ ] I numeri delle card coincidono con la somma delle transazioni del
      periodo (controllo a campione su 3–4 transazioni).

## 9. Allegati (scontrini)

- [ ] Aggiungi foto **da fotocamera** (iOS: popup permesso camera corretto).
- [ ] Aggiungi foto **dalla galleria** (iOS: popup permesso foto).
- [ ] Negare il permesso → messaggio, nessun crash.
- [ ] Il visualizzatore apre l'immagine; eliminare l'allegato lo rimuove. 🤖 parziale
- [ ] L'allegato resta dopo il riavvio dell'app.

## 10. Nota spese

- [ ] Flagga una spesa come nota spese (centro di costo, rimborsabile,
      fattura elettronica); togli il flag → dati rimossi. 🤖 `expense_report_test.dart`
- [ ] Card "Da rimborsare" in home con il totale corretto. 🤖 `app_test.dart`
- [ ] Crea una nota per un intervallo di date: include **solo** le spese
      flaggate del periodo. 🤖
- [ ] **Export PDF** con giustificativi: si apre/condivide, contiene tabella,
      totale e le foto degli scontrini leggibili. 🤖 (solo generazione)
- [ ] Ciclo di stato bozza → inviata → rimborsata; collegando la
      transazione di rimborso il "da rimborsare" si azzera.
- [ ] Archivio note: elimina una nota, le spese restano.

## 11. Impostazioni, tema, lingue

- [ ] Tema chiaro / scuro / sistema: applicato subito e salvato.
- [ ] Cambio lingua su **tutte le 8 lingue** (it, en, de, fr, es, zh, hi,
      ar): nessun testo tagliato, nessuna chiave mancante evidente.
- [ ] **Arabo (RTL)**: layout specchiato correttamente, importi leggibili.
- [ ] Nuove stringhe UI aggiunte in questo commit presenti in **tutti** gli
      `.arb` (non solo it/en).
- [ ] Formato valuta coerente: € per EUR, codice ISO per le altre valute. 🤖

## 12. Account (Supabase)

- [ ] L'app funziona **senza account** (solo locale), nessun errore di rete
      mostrato. 🤖 `sync_service_test.dart`
- [ ] Registrazione con email + password; email/password non valide →
      errori nel form. 🤖 `account_screen_test.dart`
- [ ] Login con credenziali sbagliate → errore leggibile, resta disconnesso. 🤖
- [ ] Login corretto → schermata account con l'email. 🤖
- [ ] Reset password: arriva l'email; il link, aperto **sullo stesso
      dispositivo** che l'ha richiesto, riapre l'app (deep link
      `com.alum.nipay://auth-callback`) e chiede la nuova password; dopo il
      salvataggio gli altri dispositivi vengono disconnessi. Prerequisito: il
      deep link è negli "Additional Redirect URLs" del progetto Supabase.
- [ ] Cambio password: serve la password attuale (sbagliata → errore, nessun
      cambio) 🤖; password nuova < 12 caratteri o senza numeri → errore 🤖;
      dopo il cambio, **l'altro dispositivo viene disconnesso**, questo no.
- [ ] "Esci da tutti i dispositivi" chiude anche le sessioni degli altri
      device. 🤖 (servizio finto) + verifica a mano su 2 device.
- [ ] Logout: chiede conferma e torna al form; i dati locali restano ma
      l'app mostra la schermata "Dati bloccati" finché non si rientra con lo
      stesso account. 🤖 `app_test.dart`
- [ ] Logout con "Rimuovi i dati da questo dispositivo": avviso sulle foto
      scontrini, sync finale, poi app vuota. Offline → messaggio d'errore,
      nessun dato rimosso, ancora connesso. 🤖 `account_screen_test.dart`
- [ ] Richiesta cancellazione account: serve la password attuale 🤖 → banner
      con la data esatta (+30 gg, data decisa dal server); "Annulla
      cancellazione" rimuove il banner. 🤖 Lato server: `authenticated` non
      può scrivere `deletion_requested_at` direttamente. 🤖
      `security_hardening_test.sql`
- [ ] La schermata Account mostra l'ultima sync riuscita, l'eventuale errore
      e le righe in attesa. 🤖

## 13. Sync multi-dispositivo (livello completo)

Con account A loggato su **dispositivo 1** e **dispositivo 2**:

- [ ] **Primo sync da locale**: dati creati prima del login sul dispositivo 1
      compaiono sul dispositivo 2 dopo il login, senza perdite.
- [ ] Crea/modifica/elimina su 1 → compaiono su 2 dopo "Sincronizza ora"
      o dopo aver riaperto l'app, per **ogni tipo**: portafoglio,
      categoria, tag, campo custom, centro di costo, budget, ricorrenza,
      card dashboard, transazione, tag su transazione, valore campo
      custom, nota spese. 🤖 parziale `sync_service_test.dart`
- [ ] L'eliminazione si propaga (sparisce anche sull'altro), anche per
      "togli tag" e "togli flag nota spese". 🤖
- [ ] **Conflitto**: entrambi offline, modifica la *stessa* transazione in
      modo diverso, poi riconnetti **in ordine inverso** → entrambi
      convergono sulla modifica fatta per ultima (non sull'ultimo push),
      nessun duplicato; una spesa cancellata non ricompare. 🤖
      `sync_service_test.dart` (PoC 3 + property test)
- [ ] Device nuovo su un account con > 1000 transazioni: dopo il primo
      login il numero di transazioni coincide con il server. 🤖 (paginazione)
- [ ] Orologio del device avanti/indietro di un giorno: le modifiche degli
      altri device continuano ad arrivare. 🤖 (PoC 1)
- [ ] Offline: l'app resta usabile, nessun errore bloccante; al ritorno della
      rete sincronizza.
- [ ] Allegati: **non** si sincronizzano ancora (fuori scope, M-ACC6). Solo
      verificare che non causino errori di sync.

## 14. Sicurezza

**Sempre (ogni commit importante)**
- [ ] Nessun segreto nel diff: `git diff --cached | grep -iE "service_role|secret|password|BEGIN .*PRIVATE KEY|sk_live"`
      → nessun risultato (la `anonKey` publishable in `supabase_config.dart` è
      ammessa).
- [ ] Nessun `print`/`debugPrint`/`log(` nuovo che stampi importi, email,
      token o descrizioni: `git diff --cached | grep -E "print\(|log\("`.
- [ ] Nessun `badCertificateCallback` / `HttpOverrides` / TLS disabilitato.
- [ ] Nessun accesso a Drift dalla UI (sempre tramite repository).

**Se toccato `supabase/`, sync o auth**
- [ ] Workflow GitHub **Supabase RLS** verde: isolamento tra due utenti su
      **tutte** le tabelle, `profiles` e Storage (lettura, inserimenti
      agganciati a dati altrui, spostamenti, upsert, update/delete, client
      anonimo), più l'upsert del sync sulle tabelle di join. 🤖 `supabase/tests/rls_isolation_test.sql`
- [ ] Regressione dell'audit di sicurezza (FK cross-tenant, timestamp del
      server, LWW, vincoli di dominio, cancellazione via RPC, limiti Storage,
      superficie RPC). 🤖 `supabase/tests/security_hardening_test.sql`
- [ ] Nuova tabella o nuova policy → aggiunti i casi corrispondenti in
      `rls_isolation_test.sql` (il test fallisce da solo se una tabella di
      `public` non ha la RLS abilitata, ma non sa quali policy servono).
- [ ] Contro il progetto **reale**, dopo `supabase db push`:
      `./scripts/test_rls.sh` verde (verifica che la produzione abbia
      davvero le policy, `wallets`) e, una volta per release, upload/lettura
      di un file Storage altrui con l'account di test → 403/404.
- [ ] Ogni nuova tabella Postgres ha **RLS abilitata + policy `to
      authenticated`**, colonne `updated_at`/`modified_at` e trigger
      `sync_stamp` (BEFORE INSERT OR UPDATE); FK verso righe dello stesso
      portafoglio (FK composite o check nella policy).
- [ ] **Cambio utente sullo stesso dispositivo**: login A → sync → logout
      (senza rimuovere i dati) → login B. Atteso: banner "questo dispositivo
      contiene i dati di un altro account", app bloccata (non si possono
      inserire movimenti), "Sincronizza ora" bloccato, e nella dashboard
      Supabase **nessun** portafoglio di A con `owner_user_id` di B.
      "Rimuovi i dati e sincronizza" → app vuota, poi arrivano solo i dati
      di B. 🤖 `sync_service_test.dart`, `account_screen_test.dart`, `app_test.dart`
- [ ] Rientro dello stesso utente (A → logout → A): nessun banner, dati e
      scontrini ancora presenti, sync regolare.
- [ ] Dopo il logout, riaprendo l'app non resta nessuna sessione attiva
      (la sessione è salvata nel Keychain/Keystore, non in SharedPreferences).
- [ ] Cancellazione account (livello release, su account di test): dopo la
      purge, login impossibile, righe e **tutti** i file Storage rimossi,
      anche con più di 100 allegati e sottocartelle; chiamata senza
      `x-cron-secret` → 401; `?dry_run=1` non cancella nulla. La Edge
      Function non ha test automatici (serve l'edge runtime).
- [ ] Allegati: una foto scattata con la posizione attiva, una volta
      salvata e nel PDF della nota spese, non contiene più EXIF/GPS
      (`exiftool`). 🤖 `image_sanitizer_test.dart`
- [ ] App in background: l'anteprima nell'app switcher non mostra i dati. 🤖
      (Flutter) + verifica a mano su iOS e Android.

## 15. Build e release

- [ ] `flutter build apk --debug` → installa su Waydroid
      (`adb install -r build/app/outputs/flutter-apk/app-debug.apk`) e avvia.
- [ ] `flutter build apk --release` firmata con il keystore del team (non
      quello di debug): si aggiorna **sopra** la versione già installata dai
      membri del team senza chiedere di disinstallare.
- [ ] iOS: `./scripts/build_ios_unsigned.sh` → IPA installabile con Sideloader,
      l'app si apre sull'iPhone.
- [ ] `version:` in `pubspec.yaml` incrementata per le release.
- [ ] `OVERVIEW.md` / `CLAUDE.md` / piani aggiornati se è cambiata una
      decisione o lo schema.

## 16. Punti deboli noti (da risolvere)

Emersi dalla revisione dei test di sicurezza del 2026-09-30. Finché restano
aperti, i punti ⚠️ vanno controllati a mano.

1. ~~**Il logout non isola i dati locali.**~~ **Risolto 2026-09-30**: il sync
   si blocca se i dati locali appartengono a un altro account e il logout
   può rimuovere i dati dal dispositivo (vedi CLAUDE.md). **Esteso
   2026-10-05** (SECURITY_FIX_REPORT.md): dopo il logout "semplice" i dati
   restano ma l'app è bloccata finché non si rientra con lo stesso account.
   Restano aperti: DB e foto non cifrati (M-ACC5), nessun app-lock.
2. ~~**I test RLS coprono solo `wallets`.**~~ **Risolto 2026-10-01**: 88
   test pgTAP su Supabase locale in CI (`supabase/tests/`), nessuna falla
   di isolamento trovata. Hanno scoperto un bug di sync: mancava la policy
   UPDATE su `transaction_tags`, l'upsert di un collegamento già presente
   veniva negato e la sync falliva a ripetizione (migration
   `20261001000000`). `test_rls.sh` resta come controllo a mano sulla
   produzione.
3. ~~**La purge dell'account può lasciare file.**~~ **Risolto 2026-10-05**:
   elenco paginato e ricorsivo, verifica a zero oggetti prima di
   `deleteUser`. La Edge Function resta senza test automatici.
4. ~~**Togliere il flag nota spese è una cancellazione fisica.**~~
   **Risolto 2026-10-05**: soft-delete (anche per i tag tolti).
5. **Nessun test per la sessione nel Keychain/Keystore**
   (`SecureAuthLocalStorage`) né per il logout degli altri dispositivi dopo
   il cambio password (il test usa un servizio finto).

---

## Registro esecuzione (da copiare nel commit/PR)

```
Checklist nIpay — livello: rapido | completo
Data: ____   Commit: ____   Esecutore: ____
Dispositivi: Waydroid (APK debug) / iPhone (IPA) / altro: ____
Sezioni eseguite: 1 _ 2 _ 3 _ 4 _ 5 _ 6 _ 7 _ 8 _ 9 _ 10 _ 11 _ 12 _ 13 _ 14 _ 15 _
Fallimenti / note:
```
