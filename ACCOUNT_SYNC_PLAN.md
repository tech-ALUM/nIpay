# nIpay — Piano account multi-dispositivo (sync)

> Obiettivo: permettere a un utente di usare l'app su più dispositivi con
> portafogli e spese sincronizzati, mantenendo l'uso 100% locale come
> opzione per chi non vuole un account. Vincoli: **sicurezza** (nessun
> account/dato accessibile da utenti non autorizzati), **legale** (GDPR,
> conservazione dati), **efficienza** (niente overengineering per un team
> di 4 persone).
>
> Non tocca il modello concettuale esistente (portafogli come spazi
> isolati, vedi [CLAUDE.md](CLAUDE.md)): aggiunge solo un livello di
> ownership + sincronizzazione sopra lo schema Drift attuale, che è già
> "sync-ready" (`id` UUID, `createdAt`, `updatedAt`, `deletedAt` soft-delete
> su ogni tabella tramite `SyncColumns`).
>
> Backend scelto: **Supabase** (Postgres + Auth + Storage + RLS), region
> **EU (Frankfurt)**. Motore di sync: scritto in casa (push/pull su
> `updatedAt`), non un vendor dedicato — vedi motivazioni nella
> discussione di brainstorming che ha originato questo file.

## Decisioni bloccate (2026-09-08)

- [x] **Scope confermato**: solo multi-device stesso utente, NON
  condivisione di un portafoglio tra utenti diversi. Se in futuro cambia,
  il modello RLS/ownership in M-ACC1 va rifatto (membership N:M invece di
  `owner_user_id` singolo) — quella milestone non prevede questo caso.
- [x] **Login**: email/password + **Google Sign-In** + **Apple Sign-In**,
  tutti e tre disponibili fin dal lancio (non solo email/password come
  baseline). Nota: Apple non impone Sign in with Apple finché la
  distribuzione resta sideload e non App Store, ma va comunque
  implementato per scelta prodotto — vedi impatti in M-ACC4.
- [x] **Modalità "solo locale"**: resta disponibile **permanentemente**,
  non è una fase transitoria. L'app deve continuare a funzionare al 100%
  senza account indefinitamente, per chi non vuole crearne uno.
- [x] **Titolare del trattamento**: entità "**ALUM**" — va riportato
  come tale in privacy policy e nella configurazione dell'account
  Supabase/DPA.

---

## M-ACC0 — Fondamenta legali e di sicurezza (da fare PRIMA del codice)

Bloccante: senza questo, qualunque dato reale raccolto in produzione è
un rischio legale, non solo tecnico.

- [ ] **Privacy policy**: cosa si raccoglie, perché, per quanto tempo,
  con chi si condivide (Supabase come responsabile del
  trattamento/processor). Inventario dati da coprire (tutto quanto
  già raccolto in locale oggi, più i dati d'account):
  - **Account**: email, password (hashata da Supabase Auth), identità
    da provider OAuth (Google/Apple sub id) se usati.
  - **Portafogli**: nome, colore, icona, saldo iniziale, valuta,
    ordine di visualizzazione, stato archiviato.
  - **Transazioni**: tipo (spesa/entrata/trasferimento), importo,
    data, categoria, descrizione, note libere, valuta di inserimento
    e importo convertito (se diversa da quella del portafoglio).
  - **Categorie e tag**: nome, icona, colore, gerarchia.
  - **Campi custom** (definizioni e valori): qualunque dato libero
    l'utente scelga di tracciare (potenzialmente dati sensibili se
    l'utente ci mette informazioni personali — va detto esplicitamente
    che l'utente è responsabile di ciò che inserisce in questi campi).
  - **Budget** per categoria (limiti di spesa).
  - **Regole ricorrenti** (template di transazioni ripetute).
  - **Allegati**: foto degli scontrini (potenzialmente dati personali
    di terzi se lo scontrino li contiene, es. altri nominativi) — file
    immagine, non solo metadati.
  - **Centri di costo e note spese**: nome, periodo, stato
    bozza/inviata/rimborsata, flag fattura elettronica/rimborsabile.
  - **Configurazione dashboard**: card scelte e relativa configurazione.
  - Nessun dato di localizzazione GPS, contatti o altri permessi di
    sistema attualmente richiesti dall'app — se in futuro se ne
    aggiungono, la privacy policy va aggiornata di conseguenza.
- [ ] **DPA con Supabase**: l'accettazione è **implicita** nell'accettare
  i Termini di Servizio Supabase (nessuna firma/controfirma separata da
  cercare in dashboard, quella serve solo su piani Enterprise
  negoziati). Passi concreti comunque da fare:
  - Archiviare copia del testo DPA (supabase.com/legal/dpa) + data di
    creazione progetto, come prova di accountability GDPR.
  - Iscriversi al form di notifica cambi subprocessor sulla stessa
    pagina legale (Supabase dà 30 giorni di preavviso, ma solo a chi
    si iscrive; 5 giorni di finestra per obiezione scritta).
  - Controllare la lista subprocessor attuale, coerenza con la
    privacy policy.
  - Nominare Supabase come responsabile del trattamento nella privacy
    policy ALUM, con link al DPA pubblico.
  - Nota: la region EU da sola **non basta** per compliance — verificare
    in M-ACC1 che backup/log/Edge Function non escano dalla region.
- [x] **Politica di conservazione dati**: i dati di un account
  cancellato restano **30 giorni** (grace period per recupero
  accidentale/ripensamento), poi hard-delete fisico definitivo — vedi
  M-ACC7.
- [ ] **Base giuridica del trattamento**: consenso esplicito
  all'attivazione dell'account (checkbox non pre-spuntata), non
  "legittimo interesse".
- [x] Region Supabase: **EU (Frankfurt, `eu-central-1`)**, confermata da
  Project Settings — non cambiabile facilmente dopo, verificato ora
  prima che ci siano dati reali.

**Fatto quando**: privacy policy pubblicata (anche una singola pagina
statica) e DPA Supabase accettato, prima di qualunque account reale.

---

## M-ACC1 — Progetto Supabase e schema Postgres

- [x] Creare progetto Supabase, region EU, piano Free per partire.
- [x] Schema Postgres speculare alle tabelle Drift (`Wallets`,
  `Transactions`, `Categories`, `Tags`, `Budgets`, `RecurringRules`,
  `Attachments`, `CustomFieldDefs`, `CustomFieldValues`,
  `ExpenseReports`, `ExpenseReportEntries`, `CostCenters`,
  `DashboardCards`), stessi tipi (`id` UUID, timestamp, soft-delete) —
  [`supabase/migrations/20260908000000_initial_schema.sql`](supabase/migrations/20260908000000_initial_schema.sql).
  **Deviazione deliberata dal locale**: `wallet_id` è NOT NULL su tutte
  le tabelle figlie (in locale è nullable solo per compatibilità con
  la vecchia migrazione v1→v2) — la RLS di M-ACC2 deve poter sempre
  risolvere l'owner via join su `wallet_id`, una riga orfana sarebbe
  un buco di sicurezza o un dato invisibile per sempre.
- [x] `Wallets` guadagna `owner_user_id uuid references auth.users(id)`
  — root dell'ownership; tutte le tabelle figlie ereditano l'accesso
  via FK a `wallet_id`.
- [x] Tabella `profiles` (1:1 con `auth.users`) per dati app-specific
  futuri, con trigger di auto-creazione alla registrazione utente.
- [x] `updated_at` **assegnato da trigger Postgres** (`set_updated_at()`
  su ogni tabella), mai fidarsi del valore mandato dal client —
  previene che un device con orologio sbagliato corrompa l'ordine di
  last-write-wins.
- [x] Constraint di integrità lato DB (check constraints sugli enum,
  `ON DELETE` coerenti per ogni FK) come seconda linea oltre alla
  validazione client.
- [x] **RLS abilitata su ogni tabella già in questa migration**, senza
  policy (default-deny): nessuno — nemmeno il proprietario — può
  leggere/scrivere finché M-ACC2 non aggiunge le policy. Evita una
  finestra di esposizione totale tra "tabella creata" e "policy
  scritta".
- [x] Applicare la migration al progetto Supabase reale e verificare che
  tutte le tabelle esistano senza errori — verificato via REST API
  (`https://tyjugoiohkktlyizfpfx.supabase.co`): 15/15 tabelle presenti,
  RLS attiva e blocca INSERT/SELECT anonimi (`42501` su tentativo di
  scrittura non autorizzata).

**Fatto quando**: schema Postgres completo ✓, migrazioni versionate
(SQL in `supabase/migrations/` nel repo) ✓, nessuna tabella senza
`owner_user_id` risolvibile (direttamente o via join) ✓, migration
applicata con successo al progetto reale ✓.

---

## M-ACC2 — Row Level Security (sicurezza dati, punto critico)

Questa è la milestone che garantisce "nessun account o informazione di
account accessibile da utenti non autorizzati" — va trattata come
security-critical, non come un dettaglio implementativo.

- [x] RLS **abilitata su ogni singola tabella** fin dal primo giorno —
  fatto già in M-ACC1 (default-deny prima ancora di avere policy).
- [x] Policy su `Wallets`: `owner_user_id = auth.uid()` per
  SELECT/INSERT/UPDATE/DELETE — vedi sotto.
- [x] Policy sulle tabelle figlie: accesso solo se il `wallet_id`
  referenziato appartiene a `auth.uid()` (via funzioni helper) — vedi
  sotto.
- [x] **Nessuna policy "permissive true"**: verificato per lettura
  diretta del file di migration, ogni policy usa `owns_wallet`/
  `owns_transaction`/owner diretto — da ri-verificare ad ogni futura
  modifica prima del deploy.
- [x] `service_role` key **mai** nel client mobile — solo in Edge
  Functions server-side (es. hard-delete GDPR, M-ACC7). Nel client
  solo `anon` key, sicura da esporre perché RLS fa il lavoro —
  verificato più sotto in questa stessa milestone.
- [x] Policy scritte per tutte le 15 tabelle —
  [`supabase/migrations/20260908010000_rls_policies.sql`](supabase/migrations/20260908010000_rls_policies.sql).
  Funzioni helper `owns_wallet`/`owns_transaction`/`owns_tag`/
  `owns_custom_field` centralizzano la verifica di ownership (un solo
  posto da auditare invece di ripetere la stessa `EXISTS` ovunque).
  Difesa in profondità aggiunta su `transactions.wallet_to_id` e
  `expense_reports.reimburse_tx_id`: anche i riferimenti incrociati tra
  wallet devono appartenere allo stesso utente.
- [x] **Test automatici delle policy** —
  [`scripts/test_rls.sh`](scripts/test_rls.sh) eseguito contro il
  progetto reale: **6/6 passati**. Verificato che l'utente autenticato
  non veda/modifichi/cancelli un wallet di un altro owner, non possa
  crearne uno intestato ad altri (403), e che un client anonimo resti
  bloccato ovunque. Nota di processo: al primo tentativo la migration
  delle policy non era stata applicata (falso positivo sui test SELECT,
  che tornano `[]` sia con policy corrette sia in puro default-deny —
  solo l'INSERT lo ha smascherato) — riapplicata con successo.
  `owner_user_id` non può essere un UUID arbitrario nel wallet
  "fantasma" di test: FK verso `auth.users`, quindi serve l'id di un
  account realmente esistente (anche non confermato).
- [x] `service_role` key **mai** nel client mobile — verificato
  grepando il bundle iOS compilato (`Runner.app`, incluso il
  `kernel_blob.bin` con `-a` per non saltare i binari): due falsi
  positivi controllati e chiariti (un commento della libreria
  `supabase` su "service_role key in the browser", e la costante
  `_secretKeyPrefix = 'sb_secret_'` usata per riconoscere il *formato*
  di una chiave, non una chiave vera incorporata) — nessuna vera
  service_role key presente.

**Fatto quando**: `scripts/test_rls.sh` eseguito con 0 fallimenti ✓,
nessuna policy "true" residua ✓, `service_role` key verificata assente
da qualunque asset del client (grep su APK/IPA buildati) — da fare in
M-ACC4/M-ACC8.

---

## M-ACC3 — Storage allegati (foto scontrini)

- [x] Bucket Supabase Storage **privato** (mai pubblico) —
  [`supabase/migrations/20260908020000_storage_attachments.sql`](supabase/migrations/20260908020000_storage_attachments.sql).
- [x] Path per oggetto: `{owner_user_id}/{attachment_id}` — non
  indovinabile, non sequenziale. Le policy verificano il primo
  segmento del path (`storage.foldername`), non la colonna `owner` di
  `storage.objects` — il path è la fonte di verità, non un campo che
  un client potrebbe non valorizzare correttamente.
- [x] Policy di Storage sullo stesso principio ownership-by-path di
  `Attachments`/`Transactions`: accesso solo al proprietario.
- [ ] Accesso via **signed URL a tempo**, mai URL permanenti pubblici —
  da implementare lato client in M-ACC6/M-ACC4 (qui è pronta solo la
  base SQL, la generazione della signed URL è codice app).
- [ ] Download on-demand (non tutti gli allegati al sync, solo quando
  l'utente apre la spesa) — da implementare nel motore di sync
  (M-ACC6).
- [x] Applicata la migration al progetto reale e verificata via test
  diretto sull'API Storage (l'endpoint di metadata `/bucket/{id}`
  risponde 404 anche a bucket esistenti — probabilmente riservato a
  `service_role` — non è un test attendibile; verificato invece con
  upload/list/download reali): upload nel proprio prefisso riuscito,
  upload nel prefisso di un altro utente respinto (`403`), lettura di
  un file altrui non trovata (`404` — l'isolamento nasconde anche
  l'esistenza del file, non solo il contenuto).

**Fatto quando**: un allegato caricato da utente A restituisce 403/404
se richiesto con le credenziali di utente B ✓, verificato con test
reale contro il progetto Supabase.

---

## M-ACC4 — Autenticazione lato app

- [x] Dipendenza `supabase_flutter` (+ `flutter_secure_storage`).
- [x] Feature module `lib/features/account/account_screen.dart` (login,
  signup, logout, reset password) — form unico con toggle accedi/
  registrati, validazione locale (email/password), messaggi d'errore
  tradotti dove noti. Segue le convenzioni esistenti: repository/
  service pattern (`AuthService` astratto + `SupabaseAuthService`),
  Riverpod (`authServiceProvider`, `authStateProvider`), l10n IT+EN,
  niente stringhe hardcoded. Entry point aggiunto in Impostazioni.
  Testato con 5 widget test (`test/features/account/account_screen_test.dart`)
  contro un `FakeAuthService` — nessuna chiamata di rete nei test,
  nessuna dipendenza da `Supabase.initialize()` nella suite.
- [x] **Token di sessione in `flutter_secure_storage`**
  (`lib/core/secure_auth_storage.dart`: `SecureAuthLocalStorage` per la
  sessione, `SecureAuthAsyncStorage` per il code verifier PKCE) —
  Keychain iOS / Keystore Android, mai `shared_preferences`. Wired in
  `main.dart` via `FlutterAuthClientOptions`. **Verificato su
  simulatore iOS reale**: login con account di test
  (`sergioboffi2002@gmail.com`) contro il progetto Supabase reale
  riuscito, "Signed in as sergioboffi2002@gmail.com" mostrato
  correttamente; sessione **sopravvive al riavvio completo dell'app**
  (kill + relaunch), confermando che il token è davvero persistito nel
  Keychain e non solo in memoria.
- [x] Indicatore utente loggato in home (`lib/features/home/home_screen.dart`,
  `_SignedInBadge`): chip con email, visibile solo se loggato (nessun
  banner permanente da ignorare in modalità solo-locale), tappabile →
  apre `AccountScreen`. Verificato su simulatore.
- [x] Bug reale trovato e corretto durante la verifica su simulatore:
  `AccountScreen` andava in crash al primo push da `Navigator`
  (mancava uno `Scaffold` — il widget test lo mascherava avvolgendo lui
  stesso il widget in uno `Scaffold` di comodo). Corretto in
  `account_screen.dart` e nel test, che ora non fornisce più uno
  Scaffold esterno, per intercettare regressioni simili in futuro.
- [ ] **Login social**: Google Sign-In (`google_sign_in` + provider
  Google configurato in Supabase Auth) e **Apple Sign-In**
  (`sign_in_with_apple` + provider Apple in Supabase Auth), oltre a
  email/password. Richiede configurazione esterna (Google Cloud
  Console, Apple Developer) che solo il team può fare — non
  implementabile senza quelle credenziali. Note implementative restano
  valide per quando si procede:
  - Apple Sign-In su iOS richiede capability "Sign in with Apple" nel
    provisioning/entitlements — impatta il processo di sideload/CI
    già in uso (`.github/workflows/ios.yml`), da verificare che la
    firma non gestita da Apple ufficialmente (Dadoum Sideloader) non
    rompa il flusso OAuth.
  - Su Android l'Apple Sign-In passa via web (redirect), verificare
    deep link di ritorno all'app.
  - I tre metodi devono convergere sullo **stesso `auth.users.id`** se
    un utente li usa con la stessa email — configurare account linking
    in Supabase per evitare utenti duplicati con provider diversi.
- [ ] Password policy minima configurata esplicitamente in Supabase
  Auth (lunghezza, non assumere i default) — si applica solo al metodo
  email/password. Da fare in dashboard, non da codice.
- [ ] Refresh token rotation abilitata — da verificare/attivare in
  dashboard Supabase Auth.
- [ ] **SMTP custom** (es. Resend, Postmark) configurato in Supabase Auth
  prima del lancio: il provider email di default ha un rate limit molto
  basso (osservato durante i test di M-ACC2: pochi signup consecutivi
  bastano a bloccarlo con `over_email_send_rate_limit`) — inutilizzabile
  anche per una beta con pochi utenti in parallelo.
- [ ] Schermata "dispositivi collegati" con possibilità di revoca
  remota di una sessione (device perso/rubato) — non ancora
  implementata, da valutare anche la disponibilità API lato Supabase
  per un utente (non admin) per elencare le proprie sessioni.
- [x] **Cambio password** per l'utente già loggato (non solo reset via
  email): `AuthService.changePassword` chiama `updateUser` e poi
  `signOut(scope: SignOutScope.others)` — **logout forzato di tutte le
  ALTRE sessioni incluso in questa stessa chiamata**, nessuna
  operazione admin/service_role necessaria per farlo (il client
  GoTrue lo supporta nativamente). UI: dialogo "Cambia password" nella
  vista utente loggato (`account_screen.dart`), 7 test totali sul
  feature (incluso nuovo/conferma non coincidenti, errore auth).
  Verificato a schermo su simulatore.
- [ ] Toggle esplicito "modalità account" vs "solo locale": per ora
  implicito (non loggato = locale, coerente con la decisione presa in
  premessa), nessun interruttore dedicato — da rivalutare quando
  esiste il motore di sync (M-ACC6) e "sospendere la sync" diventa
  un'azione concreta da esporre.
- [x] `service_role` key verificata assente da qualunque asset del
  client — fatto in M-ACC2 (grep sul bundle iOS compilato, incluso il
  binario, con esito pulito dopo aver chiarito due falsi positivi).

**Fatto quando**: login/logout/reset funzionanti ✓ (verificato con test
automatici, non ancora su device reale), nessun token in storage non
cifrato (da verificare ispezionando i file dell'app su device/emulatore
reale), sessioni revocabili da remoto (da fare).

---

## M-ACC5 — Cifratura del DB locale

Indipendente dalla sync in sé, ma diventa prioritario appena il device
aggrega dati sincronizzati da più fonti.

- [x] **Decisione (2026-09-13): rimandata**, non abbandonata. Il piano
  originale assumeva `sqlcipher_flutter_libs`, ma quel pacchetto è
  **obsoleto** dalla v3.x di `sqlite3` (che il progetto già usa,
  `sqlite3: 3.5.1`) — vedi
  [github.com/simolus3/sqlite3.dart/UPGRADING_TO_V3.md](https://github.com/simolus3/sqlite3.dart/blob/main/UPGRADING_TO_V3.md).
  Il meccanismo attuale è un **hook nativo di build** in `pubspec.yaml`
  (`hooks: user_defines: sqlite3: source: sqlcipher` o `sqlite3mc`),
  una feature Dart/Flutter recente (native assets/hooks) e poco matura
  nel nostro setup — rischio concreto di rompere la build su iOS/
  Android/CI se tentata senza un branch isolato e test approfonditi
  su entrambe le piattaforme.
  Scelta fatta: **affidarsi per ora alle protezioni del sistema
  operativo** (iOS Data Protection, Android File-Based Encryption —
  entrambe cifrano lo storage dell'app quando il device è bloccato)
  invece di SQLCipher a livello applicativo. Più debole (non protegge
  un device sbloccato o rootato/jailbroken), ma zero rischio di build
  oggi. **Da rivalutare** quando il meccanismo hooks sarà più maturo
  o quando emerge un pacchetto community stabile equivalente a
  `sqlcipher_flutter_libs` per `sqlite3` v3.x.
- [ ] Migrare il DB Drift locale a SQLCipher/SQLite3MultipleCiphers via
  hook nativo — **rimandato**, vedi sopra.
- [ ] Chiave di cifratura derivata da materiale in secure storage di
  sistema — **rimandato**, dipende dal punto precedente.
- [ ] Path di migrazione per utenti esistenti con DB non cifrato —
  **rimandato**, dipende dai punti precedenti.
- [ ] (Opzionale, valutare con team) App-lock biometrico
  (Face ID/impronta) all'apertura — indipendente dalla cifratura,
  resta valutabile a prescindere.

**Fatto quando**: rivalutato con `sqlite3` hooks maturo, oppure quando
emerge un'alternativa stabile. Nel frattempo: nessuna azione, la
milestone resta esplicitamente aperta e documentata come rischio noto
(non un dimenticato).

---

## M-ACC6 — Motore di sync

- [x] Tabella locale `SyncStates` (Drift, schema v6): **due** watermark
  invece di uno solo — `lastPushedAt` (dominio orologio locale) e
  `lastPulledAt` (dominio orologio server) — deviazione deliberata dal
  piano originale per evitare bug di clock-skew tra device e Postgres,
  vedi commento su `SyncStates` in `tables.dart`.
- [x] `SyncService`/`SupabaseSyncService` in
  [`lib/data/services/sync_service.dart`](lib/data/services/sync_service.dart):
  - **Push/Pull** per 13 tabelle su 14 (tutte tranne `Attachments`, vedi
    nota sotto), genitori-prima-dei-figli per rispettare le foreign key
    sia su Postgres (push) sia in locale (pull, lo schema Drift usa
    `.references()` anch'esso).
  - Accesso di rete isolato dietro un'interfaccia `SyncRemote` (stesso
    pattern di `AuthService`) — la logica di sync è testabile con un
    finto server in memoria, zero chiamate reali nei test.
  - **Cancellazioni**: propagate via `deletedAt`, nessuna tabella di
    tombstone separata.
  - **Conflict resolution**: last-write-wins su `updated_at`
    server-assegnato — verificato con test di proprietà (sotto).
  - **First sync**: nessun codice speciale necessario — con watermark
    a epoch (mai sincronizzato), la sync ordinaria fa già "push tutto
    il locale + pull tutto il remoto" naturalmente, sia per un account
    nuovo sia per un secondo device che si aggancia a un account
    esistente.
  - **Nota di scope**: gli **allegati** (foto scontrini) sono esclusi
    da questa prima versione — richiedono anche l'upload/download del
    file binario su Storage (M-ACC3), non solo la riga di metadata;
    rimandato a un passo successivo dedicato.
- [x] Trigger di sync: al login (incluso avvio app con sessione già
  valida), al resume dell'app (`WidgetsBindingObserver`), periodico
  ogni 5 minuti come rete di sicurezza, e pulsante manuale
  "Sincronizza ora" in `account_screen.dart` — tutti fire-and-forget,
  mai bloccanti per la UI, errori di rete inghiottiti silenziosamente
  (`syncNow()` non deve mai far crashare l'app).
- [x] Import globale distruttivo: **verificato che non serve alcuna
  modifica ora** — la funzione (`importFromJson` in `json_codec.dart`)
  esiste nel codec ma non è collegata a nessuna schermata, quindi non
  c'è nulla da disabilitare oggi. Decisione presa (disabilitare in
  modalità account) registrata come vincolo per quando quella UI verrà
  eventualmente costruita.
- [x] Test in
  [`test/data/sync_service_test.dart`](test/data/sync_service_test.dart)
  (6 test, incluso uno di proprietà su 30 trial): push con
  `owner_user_id` corretto, convergenza a due device (wallet e
  categorie con FK), propagazione soft-delete, e **last-write-wins**
  con sequenze casuali di scritture alternate tra due device — tutti
  verdi. Un giro di questo test ha scovato e corretto un bug nel test
  stesso (timestamp fissi nel passato incompatibili col dominio
  dell'orologio reale usato dal watermark di push).
- [x] **Comportamento noto e accettato (2026-09-13)**: login su un
  account che ha già dati su un device diverso, da un device con dati
  locali preesistenti → i due insiemi si **uniscono** (nessuna perdita,
  nessun riconoscimento duplicati per nome: due portafogli con lo
  stesso nome restano due portafogli distinti). Nessuna schermata di
  conferma pre-sync per ora — valutata e rimandata deliberatamente,
  non dimenticata.
- [x] **Fix 2026-09-30 — cambio utente sullo stesso device.** Prima,
  login A → logout → login B faceva caricare i portafogli locali di A
  con `owner_user_id` = B (quelli mai sincronizzati finivano davvero
  nell'account di B; gli altri bloccavano il sync per la RLS). Ora il
  primo utente che sincronizza rivendica il device (riga `SyncStates`
  scritta prima di ogni push); un utente diverso riceve
  `LocalDataOwnedByAnotherUserException` e la schermata account offre
  "Rimuovi i dati e sincronizza" o "Esci". Il logout conserva i dati
  di default, con opzione di rimozione (sync finale obbligatoria prima
  del wipe). Test: 4 nuovi in `sync_service_test.dart`, 3 in
  `local_data_service_test.dart`, 6 widget test in
  `account_screen_test.dart`.

**Fatto quando**: due device con lo stesso account convergono sugli
stessi dati dopo sync ✓ (verificato con test automatici — verifica
end-to-end su simulatore reale contro Supabase non ancora fatta), test
di conflitto verdi ✓, nessuna perdita dati nel first-sync da locale
esistente ✓ (per costruzione, non caso speciale).

---

## M-ACC7 — Diritti GDPR (export, cancellazione)

- [x] **Export dati: RIMOSSO su decisione esplicita (2026-09-13)**.
  Era stato costruito (pulsante "Esporta i miei dati" in
  `account_screen.dart`, riuso di `exportToJson`), poi tolto su
  richiesta: **nessuna esportazione dati in nessun formato**, in
  nessun punto dell'app collegato all'account. Il PDF nota spese resta
  invariato (funzione distinta, per il rimborso, non toccata da
  questa decisione).
  **Attenzione compliance**: l'art. 20 GDPR (diritto alla portabilità
  dei dati) richiede che un utente possa ottenere i propri dati in un
  formato leggibile su richiesta — segnalato esplicitamente prima di
  procedere. Decisione presa comunque: se in futuro serve, valutare
  un percorso non self-service (richiesta manuale via supporto) invece
  di un pulsante in app, per restare conformi senza riesporre la
  funzione nell'interfaccia.
- [x] **Cancellazione account**: flusso a due fasi implementato:
  1. Richiesta utente → `profiles.deletion_requested_at = now()`
     (colonna aggiunta in
     [`supabase/migrations/20260913000000_account_deletion.sql`](supabase/migrations/20260913000000_account_deletion.sql));
     nessuna nuova RLS necessaria (la policy "update own profile" di
     M-ACC2 già copre questo campo). Banner con data esatta di
     cancellazione + pulsante "Annulla cancellazione" mostrato finché
     il campo è valorizzato.
  2. Hard-delete allo scadere dei 30 giorni: Edge Function
     [`supabase/functions/purge-deleted-accounts/index.ts`](supabase/functions/purge-deleted-accounts/index.ts),
     `service_role`, protetta da un segreto condiviso nell'header (mai
     invocabile pubblicamente) — cancella prima i file Storage
     dell'utente (niente FK verso `auth.users`, la cascata DB non li
     tocca), poi l'utente da `auth.users`: la cascata già presente
     (`on delete cascade` su `wallets.owner_user_id` e su ogni tabella
     figlia, M-ACC1) elimina automaticamente tutto il resto.
     **Da fare manualmente** (non automatizzabile da qui): deploy
     (`supabase functions deploy purge-deleted-accounts --no-verify-jwt`),
     impostare il secret `CRON_SECRET`, schedulare via Supabase Cron —
     istruzioni nei commenti in testa al file.
  3. Comunicazione chiara: data esatta mostrata nel banner, un nuovo
     login prima della scadenza permette di annullare con un tap.
- [ ] Audit log lato server per: cancellazione account, export dati,
  cambio password — non ancora fatto, rimandato.
- [ ] Test automatici: la UI (banner, richiesta, annullamento) è
  coperta da 2 nuovi widget test con `FakeAuthService` — **l'Edge
  Function non è testata automaticamente** (richiede deploy reale),
  da verificare manualmente dopo il deploy.

**Fatto quando**: un utente può esportare tutti i propri dati ✓ e
richiedere la cancellazione dell'account con effetto reale entro il
grace period ✓ — **il deploy e la schedulazione dell'Edge Function
restano da fare manualmente** prima che l'hard-delete effettivo
funzioni in produzione.

---

## M-ACC8 — Hardening finale e igiene dipendenze

- [x] Nessun dato finanziario o PII nei log/crash reporter — verificato
  via grep (`print`/`debugPrint`/`log(`) su tutti i file toccati da
  M-ACC4/6/7: nessuna occorrenza. Nessun crash reporter (Sentry/
  Crashlytics) ancora introdotto, quindi nessun rischio attuale di
  questo tipo — da ricontrollare se mai se ne aggiunge uno.
- [x] Verifica TLS mai disabilitata — grep su `badCertificateCallback`,
  `allowBadCertificates`, `HttpOverrides`, `SecurityContext` in tutto
  `lib/`: nessuna occorrenza.
- [x] `flutter pub outdated` — `supabase_flutter`, `flutter_secure_storage`
  e pacchetti collegati (gotrue/postgrest/storage_client/realtime)
  sono già alla versione più recente risolvibile, nessun aggiornamento
  di sicurezza pendente su questi. Altri pacchetti non correlati alla
  sicurezza (drift, go_router) hanno versioni più recenti disponibili
  — bump deliberatamente rimandato, fuori scope per questo hardening
  (`flutter_riverpod` v3 resta bloccato per l'incompatibilità nota con
  `drift_dev`, vedi CLAUDE.md).
- [x] Grep sulla history del repo (`git log --all -p`, `git grep` su
  tutti i commit) per `service_role`/`SERVICE_ROLE`: **nessuna
  occorrenza in nessun commit**. Verificato anche che
  `android/key.properties`, `*.jks`, `*.keystore`, `local.properties`
  siano coperti dal `.gitignore` di Android di default (non serviva
  aggiungerli, già a posto). L'unica occorrenza di "service_role" in
  `lib/` è un commento che spiega perché quella chiave NON deve
  esserci nel client — confermato assente per davvero.

**Fatto quando**: `flutter analyze && flutter test` verde ✓, nessun
warning di sicurezza noto aperto ✓, dipendenze rilevanti per la
sicurezza aggiornate ✓ (altre non correlate, deliberatamente
rimandate).

---

## M-ACC9 — Beta interna e rollout

- [ ] Beta con i 4 membri del team ALUM, 2 device ciascuno.
- [ ] Verifica end-to-end: creazione account → uso su device 1 →
  sync → uso su device 2 → conflitto intenzionale (stessa spesa
  modificata su entrambi offline) → verifica risoluzione corretta.
- [ ] Verifica cancellazione account end-to-end (compreso Storage).
- [ ] Solo dopo beta verde: rollout a utenti reali.

**Fatto quando**: beta completata senza perdita dati o accesso
incrociato tra account, feedback team raccolto.

---

## Fuori scope (esplicitamente rimandato)

- Condivisione di un portafoglio tra utenti diversi (famiglia/team) —
  richiederebbe ripensare l'ownership da singolo a membership N:M.
- Multi-account simultaneo sullo stesso device.
- 2FA/MFA (valutabile in futuro, non bloccante per il lancio).
- Certificate pinning (sproporzionato per la scala/minaccia attuale).
