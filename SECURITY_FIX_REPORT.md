# Security fix report — nIpay

| | |
|---|---|
| **Data** | 2026-10-05 |
| **Branch / base** | `beta-sergio`, commit `dc9594a` (allineato a `origin/beta-sergio`) |
| **Riferimento** | `SECURITY_AUDIT.md` (25 rilievi: 1 High, 12 Medium, 7 Low, 5 Info) |
| **Esito** | 18 rilievi risolti, 6 mitigati parzialmente (il resto è configurazione hosted o lavoro di prodotto), 1 risolvibile solo da configurazione hosted (NIP-11) |
| **Git** | modifiche solo locali, **nessun commit, nessun push, nessun deploy** |

## 1. Riepilogo esecutivo

Le correzioni chiudono le cause alla radice dei problemi più gravi:

- **Motore di sync (NIP-01…04, 14, 15)** riprogettato: coda delle modifiche
  alimentata da trigger SQLite, watermark di pull **per tabella** nel dominio
  dell'orologio del server, pull **paginato a keyset** con finestra di
  sovrapposizione, **last-write-wins** applicato sia dal server (trigger) sia
  dal client, timestamp sempre assegnati dal server, righe malformate o
  rifiutate isolate invece di bloccare la sync, mutex condiviso con logout e
  rimozione dati. Le tre PoC dell'audit sono diventate test di regressione e
  non riproducono più il difetto.
- **Ciclo di vita dell'account (catena A: NIP-05, 08, 09, 13)**: cambio
  password e cancellazione richiedono la password attuale; la data di
  cancellazione la decide il server tramite RPC, che pretende anche un login
  recente (claim `amr`); il reset password funziona via deep link con
  schermata "nuova password"; c'è "Esci da tutti i dispositivi"; i dati
  locali legati a un account non sono più visibili dopo il logout o con un
  altro account loggato.
- **Isolamento tra tenant (NIP-07)**: FK composite "stesso portafoglio" e
  controlli nelle policy chiudono riferimenti cross-tenant, oracolo di
  esistenza e squatting dei budget.
- **Abusi e configurazione (NIP-12, 20, 21)**: bucket limitato (tipo,
  dimensione, nome, quota), vincoli di dominio sul DB, helper RLS non più
  esposti come RPC, CI con action fissate per SHA, release Android con rete
  e senza fallback sulla chiave debug.

Verifiche: **159 test Flutter** (erano 107) e **154 test pgTAP** su Supabase
locale (erano 88), tutti verdi; il file di verifica dell'audit (Appendice D)
non riproduce più 17 difetti su 20 + l'informativo NIP-21. APK debug e
release compilati e ispezionati.

## 2. Stato iniziale

- Repository corretto, branch `beta-sergio` = `origin/beta-sergio`
  (`git fetch` eseguito), nessuna modifica tracciata. Non tracciati e
  **non toccati**: `SECURITY_AUDIT.md` (report di partenza, lasciato
  invariato) e `macos/` (preesistente).
- Baseline: `flutter test` 107/107 verdi; `flutter analyze` 3 info
  preesistenti (deprecation in `expense_report_pdf.dart`, due
  `prefer_initializing_formals`); pgTAP 88/88; Appendice D dell'audit: 21/21
  difetti riprodotti.

## 3. Vulnerabilità analizzate ed esito

| ID | Sev. | Titolo (breve) | Esito |
|---|---|---|---|
| NIP-01 | High | Watermark unico, pull non paginato | ✅ Risolta |
| NIP-02 | Med | Timestamp del client nel watermark | ✅ Risolta |
| NIP-03 | Med | Nessuna gestione conflitti, "eco" del push | ✅ Risolta |
| NIP-04 | Med | Riga avvelenata blocca la sync, nessun CHECK | ✅ Risolta |
| NIP-05 | Med | Grace period scelto dal client | ✅ Risolta (manca email di avviso) |
| NIP-06 | Med | Purge incompleta degli scontrini | ✅ Risolta nel codice (non eseguita) |
| NIP-07 | Med | Riferimenti cross-tenant, UNIQUE globale | ✅ Risolta (ID squatting: mitigato) |
| NIP-08 | Med | Cambio password senza riautenticazione | ✅ Risolta (+ impostazione hosted) |
| NIP-09 | Med | Reset non completabile, sessioni non revocabili | ✅ Risolta (+ redirect URL hosted) |
| NIP-10 | Med | Password policy debole, no MFA/CAPTCHA | 🟡 Parziale (dashboard) |
| NIP-11 | Med | SMTP di default: DoS email | ⛔ Solo configurazione hosted |
| NIP-12 | Med | Nessuna quota Storage/DB | ✅ Risolta (quote DB per righe: no) |
| NIP-13 | Med | Dati locali in chiaro/visibili dopo logout | 🟡 Parziale (cifratura e app-lock no) |
| NIP-14 | Low | Sync concorrenti, race con logout/wipe | ✅ Risolta |
| NIP-15 | Low | Cancellazioni fisiche non propagate | ✅ Risolta |
| NIP-16 | Low | EXIF/GPS nel PDF, PDF temporanei | ✅ Risolta |
| NIP-17 | Low | Errori grezzi del backend in UI | ✅ Risolta (hint PostgREST: server) |
| NIP-18 | Low | Import dormiente: path traversal | 🟡 Mitigata (ID negli export: resta) |
| NIP-19 | Low | Hardening Edge Function | ✅ Risolta nel codice (non eseguita) |
| NIP-20 | Low | CI/supply chain, firma, INTERNET | ✅ Risolta |
| NIP-21 | Info | Hardening Supabase/Postgres | ✅ Risolta (Realtime hosted: dashboard) |
| NIP-22 | Info | config.toml diverso dall'hosted | 🟡 config.toml allineato; hosted da allineare |
| NIP-23 | Info | Servizi esterni a runtime | 🟡 Tassi validati; font non inclusi |
| NIP-24 | Info | Validazione input client | ✅ Risolta |
| NIP-25 | Info | Note per la sync allegati | 🟡 Preventive applicate (path, nomi) |

## 4. Correzioni effettuate

**NIP-01 — High.** *Causa*: un solo `lastPulledAt` per 13 tabelle, `select`
senza `order`/paginazione (troncamento a `max_rows`), commit fuori ordine.
*Soluzione*: tabella `SyncCursors` (watermark per utente+tabella, orologio
del server); `SyncRemote.fetchPage` ordinato su (`updated_at`, chiave) con
filtro keyset (`or=(updated_at.gt.ts, and(updated_at.eq.ts, id.gt.k)…)`,
valori validati e quotati); ci si ferma solo su pagina vuota (robusto a
qualunque `max_rows`); ripartenza da `watermark − 2 min` per i commit tardivi
con applicazione idempotente; cursore salvato a ogni pagina nella stessa
transazione dell'applicazione. Indici `(updated_at, pk)` sul server.
*File*: `lib/data/services/sync_service.dart`, `lib/data/db/tables.dart`,
`supabase/migrations/20261005000000_sync_integrity.sql`.
*Verifica*: PoC 2 invertita, test con 37 righe/pagine da 10/`max_rows`=4,
test della riga committata in ritardo. *Risultato*: nessuna perdita.

**NIP-02 — Medium.** *Causa*: trigger solo `BEFORE UPDATE`, `created_at` del
client come watermark di `transaction_tags`. *Soluzione*: trigger unico
`sync_stamp` `BEFORE INSERT OR UPDATE` su tutte le 14 tabelle:
`updated_at = clock_timestamp()`, `created_at`/`modified_at` limitati a
"adesso", `created_at` immutabile; `transaction_tags` ottiene `updated_at`;
bonifica dei timestamp futuri già presenti; il client non invia mai
`updated_at`. *Verifica*: PoC 1 invertita (device con orologio +1/+2 giorni),
test "il client non invia `updated_at`", pgTAP su INSERT/upsert con date 2099.
*Risultato*: risolta.

**NIP-03 — Medium.** *Causa*: upsert incondizionato, righe "sporche"
dedotte da `updatedAt > pushCutoff` (eco delle righe scaricate).
*Soluzione*: colonna `modified_at` (= `updatedAt` locale) con LWW nel
trigger (una scrittura non più recente viene saltata con `RETURN NULL`, il
resto del batch passa; gli update interni delle FK non sono soggetti a LWW);
LWW anche in locale al pull (una modifica locale più recente non viene
sovrascritta); coda `SyncOutbox` riempita da trigger SQLite con `seq`
AUTOINCREMENT: una voce si conferma solo se nessuna modifica l'ha riscritta
durante l'invio, le righe scaricate escono dalla coda (niente eco).
Compatibilità: un update senza `modified_at` (client non aggiornato, SQL
manuale) vale come modifica "di adesso". *Verifica*: PoC 3 invertita,
tombstone non annullato da un push vecchio, modifica durante push/pull,
property test LWW (30 sequenze casuali), pgTAP LWW. *Risultato*: risolta.

**NIP-04 — Medium.** *Causa*: nessun vincolo di dominio, cast diretti nel
pull, stato salvato solo a fine sync, `UNIQUE(category_id)` globale, seed
duplicato, errori ignorati. *Soluzione*: vincoli `CHECK … NOT VALID`
(valuta ISO, colore `#RRGGBB`, importi ≥ 0, lunghezze, `options` array di
stringhe, `config_json` oggetto ≤ 16 KB); indice unico parziale
`(wallet_id, category_id) where deleted_at is null`; lettura difensiva per
riga (`_Row`): le righe malformate finiscono in quarantena e il watermark
avanza; push con fallback riga per riga sui rifiuti (`SyncRowRejectedException`
per SQLSTATE 22/23/42501); id deterministici (UUIDv5) per budget e categorie
di default, seed con data di modifica "antica" che non vince mai sulle
modifiche dell'utente; risoluzione dei budget duplicati legacy; stato della
sync (ultimo successo, errore, righe in attesa) salvato e mostrato in
Account. *Verifica*: test riga manomessa, riga rifiutata, budget offline su
due device (deterministico e legacy), errore registrato; pgTAP sui vincoli.
*Risultato*: risolta.

**NIP-05 — Medium.** *Causa*: il client scriveva `deletion_requested_at` con
qualunque valore. *Soluzione*: revocati INSERT/UPDATE/DELETE su `profiles`
per `anon`/`authenticated`; RPC `request_account_deletion()` (security
definer, `now()` del server, richiede autenticazione negli ultimi 10 minuti
dal claim `amr`, non sposta in avanti una richiesta esistente) e
`cancel_account_deletion()`; audit log in `private.account_audit_log`;
l'app chiede la password e riautentica prima della richiesta; testo
corretto (l'annullamento è dal banner, non automatico al login).
*File*: `20261005000200_account_deletion_rpc.sql`, `auth_service.dart`,
`account_screen.dart`. *Verifica*: pgTAP (update diretto → 42501, senza
`amr`/con login vecchio → rifiutata, data = `now()`), widget test con
password errata/corretta. *Risultato*: risolta; email di conferma/promemoria
non implementata (serve SMTP).

**NIP-06 / NIP-19 — Medium / Low.** *Causa*: `list()` non paginato né
ricorsivo, errori ignorati, nessun limite, confronto non costante.
*Soluzione*: elenco paginato e ricorsivo, `remove` a blocchi con controllo
errori, verifica `count_user_storage_objects = 0` prima di `deleteUser`
(altrimenti esito "failed" e nuovo tentativo), confronto a tempo costante,
segreto ≥ 32 caratteri, soglia `MAX_PURGES_PER_RUN` (stop con 409 se i
candidati la superano), `?dry_run=1`, audit log, risposta senza dettagli
interni, istruzioni cron con Supabase Vault; RPC di supporto eseguibili solo
dalla `service_role`. *Verifica*: pgTAP su RPC, permessi e cascata completa
della cancellazione utente con i nuovi vincoli; la function **non è stata
eseguita** (manca l'edge runtime in locale: le immagini Docker andrebbero
scaricate). *Risultato*: risolta nel codice, da collaudare in staging.

**NIP-07 — Medium.** *Causa*: le policy non controllavano tutte le FK; FK e
UNIQUE ignorano la RLS. *Soluzione*: FK composite `(wallet_id, x_id) →
(wallet_id, id)` per `categories.parent_id`, `transactions.category_id`,
`budgets.category_id`, `recurring_rules.category_id` (`ON DELETE SET NULL
(col)`); per `expense_report_entries` controllo nella policy che centro di
costo e nota spese stiano nel portafoglio della transazione; via l'UNIQUE
globale. UUID di un altro utente e UUID inesistente danno ora lo stesso
errore. *Verifica*: pgTAP (11 casi cross-tenant + casi legittimi).
*Risultato*: risolta; lo squatting di un id v4 non ancora sincronizzato resta
possibile in teoria (vedi §9), ma colpisce solo quella riga.

**NIP-08 — Medium.** Cambio password con password attuale verificata
(nuovo login) prima di `updateUser`, poi `signOut(others)`;
`secure_password_change = true` in `config.toml`. *Verifica*: widget test
(password errata → nessun cambio). *Risultato*: risolta lato app.

**NIP-09 — Medium.** Deep link `com.alum.nipay://auth-callback`
(AndroidManifest + `CFBundleURLTypes`) passato come `redirectTo`; evento
`passwordRecovery` → dialogo "nuova password" → `signOut(others)`;
pulsante "Esci da tutti i dispositivi" (`SignOutScope.global`). Il flusso
PKCE rende inutile il codice intercettato da un'altra app con lo stesso
schema. *Verifica*: build Android con intent-filter verificato
nell'APK; widget test del logout globale. *Risultato*: risolta lato app;
il flusso email→app va provato su device dopo aver aggiunto il redirect URL
nell'hosted.

**NIP-10 / NIP-11 — Medium.** Password nuove ≥ 12 caratteri con lettere e
numeri (registrazione, cambio, recupero), errori del server tradotti;
`config.toml` con `minimum_password_length = 12`,
`password_requirements = "letters_digits"`; pausa di 60 s tra due richieste
di reset dallo stesso device. SMTP custom, CAPTCHA, leaked password
protection e MFA richiedono la dashboard/credenziali del team (§8).

**NIP-12 — Medium.** Bucket `attachments`: 10 MiB, solo JPEG/PNG/WebP/PDF;
policy di upload con nome obbligatorio `{uid}/{uuid}.{ext}` (niente
sottocartelle) e quota per utente (2000 file, 500 MiB); limiti di lunghezza
sui testi (NIP-04). *Verifica*: pgTAP. *Risultato*: risolta.

**NIP-13 — Medium.** `allowBackup="false"`, `fullBackupContent="false"`,
`dataExtractionRules` che esclude tutto; schermata **"Dati bloccati"** quando
i dati appartengono a un account non loggato o diverso da quello loggato
(niente più spese di B nei dati di A); copertura dell'app quando non è in
primo piano e anteprima dei recenti disattivata su Android 13+.
*Verifica*: manifest dell'APK debug e release ispezionati con `aapt`;
widget test (blocco, dati solo-locali utilizzabili, schermo di privacy).
*Residuo*: cifratura DB/foto (M-ACC5) e app-lock biometrico non fatti.

**NIP-14 — Low.** `SyncLock` rientrante condiviso da `syncNow`, `wipe()` e
logout (`SyncService.exclusive`); la sync si ferma (`SyncAbortedException`)
se l'utente cambia a metà. *Verifica*: test wipe durante una sync, cambio
utente a metà, sync concorrenti serializzate. *Risultato*: risolta.

**NIP-15 — Low.** `transaction_tags` (`updatedAt`, `deletedAt`) ed
`expense_report_entries` (`deletedAt`) con soft-delete in locale e sul
server; tutte le query filtrano le righe cancellate. *Verifica*: test di
propagazione di "togli tag" e "togli flag nota spese". *Risultato*: risolta.

**NIP-16 — Low.** `sanitizeImage` toglie EXIF/XMP/IPTC/commenti senza
ricodifica (JPEG/PNG/WebP), conservando solo l'orientamento; applicato alla
scelta della foto e dentro `buildExpenseReportPdf` (copre anche gli
scontrini già salvati); PDF in una cartella temporanea dedicata svuotata a
ogni export. *Verifica*: test con GPS fittizio, anche end-to-end sul PDF
generato da una foto reale. *Risultato*: risolta (comportamento Android da
confermare su device).

**NIP-17 — Low.** `AuthException` con codici (`AuthErrorCode`) tradotti in
l10n; "email non confermata" = "credenziali errate"; errore di avvio
generico invece di `'$e'`. *Verifica*: widget test.

**NIP-18 — Low.** `relativePath` validato in import
(`attachments/<uuid>.<ext>`) e in lettura (`attachmentFile`), formato export
v4. *Verifica*: test con 4 path malevoli su entrambi gli import.

**NIP-20 — Low.** Action fissate per SHA (con versione in commento),
`permissions: contents: read`, Dependabot (actions + pub); release Android
che **fallisce** senza `key.properties`; `INTERNET` nel manifest `main`.
*Verifica*: APK release costruito con un keystore usa-e-getta (poi
eliminati keystore, `key.properties` e APK): permesso presente, non
debuggable; senza keystore la build si ferma con un messaggio esplicito.

**NIP-21 — Info.** `owns_*` spostate nello schema `private` (con
`(select auth.uid())` e `search_path = ''`), `EXECUTE` revocato ad `anon`,
tutte le policy `to authenticated`, default privileges che non concedono più
`EXECUTE` ad `anon` sulle funzioni future, Realtime spento in `config.toml`.
**NIP-22**: `config.toml` allineato (conferme email, password, cambio
password sicuro, redirect URL). **NIP-23**: tassi di cambio validati
(intervallo plausibile, variazione massima ×1.5 rispetto alla cache,
cache illeggibile ignorata). **NIP-24**: tipo allegato dai magic bytes,
regex email, limiti di lunghezza nei form. **NIP-25**: `storage_path`
vincolato a `{owner}/{id}.{ext}` (trigger).

## 5. File e componenti modificati

- **Supabase**: 5 nuove migration `supabase/migrations/20261005*`
  (integrità sync, riferimenti tenant, RPC cancellazione, Storage,
  hardening RLS); `functions/purge-deleted-accounts/index.ts`;
  `config.toml`; nuovo test `tests/security_hardening_test.sql`;
  `tests/rls_isolation_test.sql` adeguato (upload con nome UUID, update
  diretto di `profiles` ora vietato). Nessuna migration esistente modificata.
- **DB locale**: `tables.dart`, `app_database.dart` (+ `.g.dart`), schema
  Drift **v7** con migrazione e backfill della coda.
- **Servizi**: `sync_service.dart` (riscritto), `sync_lock.dart` (nuovo),
  `auth_service.dart`, `local_data_service.dart`,
  `exchange_rate_service.dart`; repository budget, categorie, tag, nota spese.
- **Core**: `ids.dart`, `validation.dart`, `image_sanitizer.dart`,
  `attachment_files.dart` (nuovi); `providers.dart`.
- **UI**: `app.dart` (blocco dati, schermo di privacy, dialogo di recupero),
  `account_screen.dart`, form con limiti di lunghezza, dettaglio
  transazione, nota spese, `expense_report_pdf.dart`, `json_codec.dart`;
  stringhe IT/EN (le altre lingue usano il fallback inglese come già
  avveniva) e classi l10n rigenerate.
- **Piattaforme/CI**: `AndroidManifest.xml`, `res/xml/data_extraction_rules.xml`,
  `MainActivity.kt`, `build.gradle.kts`, `ios/Runner/Info.plist`,
  workflow GitHub, `.github/dependabot.yml`.
- **Test**: `sync_service_test.dart` (riscritto, 29 test), nuovi
  `migration_v7_test.dart` (+ fixture dello schema v6 reale),
  `image_sanitizer_test.dart`; aggiornati test account, app, export, tassi.
- **Documentazione**: `CLAUDE.md`, `TEST_CHECKLIST.md`, questo report.

Totale: 53 file modificati (+6670/−1207, di cui ~1450 righe generate da
Drift e ~1100 da gen-l10n) e 17 file nuovi.

## 6. Motivazioni tecniche principali

- **LWW su `modified_at` limitato dal server** invece di una versione
  intera con rifiuto 409: non richiede RPC per tabella né gestione dei
  conflitti nell'interfaccia, converge su tutti i device ("vince l'ultima
  modifica"), e il limite a "adesso" impedisce a un orologio sbagliato di
  vincere per giorni. I tombstone vincono contro ogni push basato su una
  modifica precedente; una modifica *successiva* alla cancellazione fatta su
  un device offline la annulla (comportamento LWW voluto e documentato).
- **Coda alimentata da trigger SQLite**: nessun percorso di scrittura
  (repository, seed, ricorrenze, import) può dimenticare di marcare una riga.
- **FK composite** anziché sole policy: l'integrità referenziale stessa
  impedisce il cross-tenant e non esiste più un oracolo FK.
- **Riautenticazione via `amr`**: il server verifica davvero che la
  password sia stata reinserita, senza dipendere dal client.
- **Vincoli `NOT VALID`** e scritture "legacy" accettate: la migration non
  può fallire su dati storici e i client non ancora aggiornati non perdono
  modifiche in silenzio.
- **Rimozione metadati senza ricodifica**: nessuna perdita di qualità,
  orientamento conservato, funziona anche sugli scontrini già salvati.

## 7. Test e verifiche eseguiti

| Controllo | Esito |
|---|---|
| `flutter analyze` (progetto intero) | 3 info, tutte preesistenti (nessuna nuova) |
| `flutter test` | **159/159** verdi (baseline 107) |
| `supabase db reset --local` (tutte le migration da zero, Postgres 17.6) | OK |
| `supabase test db` | **154/154** (89 isolamento RLS + 65 regressione audit) |
| Appendice D dell'audit sul nuovo schema | 17/20 difetti non più riproducibili + NIP-21; restano #7 (da solo non è più un oracolo: anche l'UUID di B dà 23503) e #10/#20 (ID squatting, §9) |
| PoC 1-3 dell'audit come test di regressione | non riproducono più il difetto |
| Migrazione Drift v6→v7 su schema v6 reale (dump di `dc9594a`) | OK (dati, coda, indice budget) |
| `flutter build apk --debug` e release (keystore usa-e-getta) + `aapt`/`apksigner` | INTERNET, backup off, deep link, non debuggable, firma corretta |
| Release senza `key.properties` | fallisce con messaggio esplicito |
| Grep del diff per segreti e log | nessun risultato |

Non eseguiti (motivo): Edge Function e flussi HTTP Auth/Storage (servono
edge runtime/Kong in locale, da scaricare), build iOS (non richiesta per la
verifica, `Info.plist` validato con `plutil`), prove su device fisici.

## 8. Azioni manuali richieste (fuori dal codice)

1. **Ordine di deploy**: `supabase db push` delle migration `20261005*`
   **prima** di distribuire la nuova app (il nuovo client invia
   `modified_at`, che un DB non migrato rifiuta). Le app vecchie continuano
   a funzionare sul DB migrato, ma vanno aggiornate.
2. **Dashboard Supabase (hosted)**: password minima 12 + lettere e numeri;
   *Leaked password protection*; *Secure password change*; *Additional
   Redirect URLs* += `com.alum.nipay://auth-callback`; SMTP custom
   (Resend/Postmark/SES); CAPTCHA su signup/login/recover (richiede anche
   l'integrazione del token nell'app); valutare MFA TOTP; spegnere Realtime;
   verificare `max_rows`, durata JWT/refresh token.
3. **Edge Function**: deploy, `CRON_SECRET` ≥ 32 caratteri in Vault, job
   cron come da commento nel file, collaudo in staging con > 100 file e
   sottocartelle (`?dry_run=1` prima).
4. Eseguire la query di confronto policy hosted/locale (audit §6, punto 12)
   e il Security Advisor dopo il push.

## 9. Problemi e rischi residui

- **ID squatting** (NIP-07): chi conosce in anticipo l'UUID v4 di una riga
  non ancora sincronizzata di un altro utente può occuparlo; ora l'effetto
  è limitato a quella riga (resta in coda, segnalata in Account) e non
  blocca più la sync. Soluzione completa: chiavi primarie per tenant.
- **NIP-13**: DB e foto non cifrati (M-ACC5), nessun app-lock biometrico,
  esclusione dai backup iCloud/Data Protection iOS non configurate.
- **NIP-10/11**: finché la dashboard non è configurata, il server accetta
  ancora password deboli via API e l'invio email resta esauribile.
- **NIP-23**: Google Fonts scaricati a runtime (per includerli negli asset
  servono i file dei font: download da autorizzare).
- **NIP-18**: gli export (codice dormiente) contengono ancora gli UUID reali.
- **NIP-06**: i dati soft-deleted restano sul server (una purge periodica è
  una scelta di retention, e oltre la finestra un device offline non
  riceverebbe più le cancellazioni).
- **Cambi di comportamento da confermare col team**: dopo il logout i dati
  restano ma l'app è bloccata finché non si rientra con lo stesso account
  (anche dopo la purge di un account cancellato: i dati si possono solo
  rimuovere); password richiesta per cambio password e cancellazione; prima
  sync dopo l'aggiornamento riscarica tutto (una volta).
- **Osservati, fuori scope**: le ricorrenze dovute possono essere generate
  due volte da due device (id casuali: suggerito id deterministico
  regola+data); le date "di business" sono inviate senza fuso orario
  (convenzione preesistente lasciata invariata per non spostare le date).

## 10. Stato finale della sicurezza

Riservatezza tra tenant: **buona** (invariata) e ora anche **integrità
referenziale** per tenant. Integrità e disponibilità della sync:
**adeguate** — nessuna perdita silenziosa nei casi dimostrati dall'audit,
timestamp solo dal server, conflitti risolti in modo deterministico, errori
isolati e visibili. Ciclo di vita dell'account: la **catena A è interrotta**
in tre punti (password per azioni sensibili, data di cancellazione del
server con login recente, dati locali non visibili senza l'account). Restano
da completare le impostazioni dell'hosted (§8) prima di aprire la
registrazione all'esterno del team.

## 11. Stato Git finale

- Branch `beta-sergio`, HEAD `dc9594a` = `origin/beta-sergio`: **nessun
  commit creato, nessun push, nessun merge, nessuna PR, nessun deploy**.
- Working tree: 53 file modificati e 17 non tracciati creati da questo
  lavoro (migration, test, sorgenti nuovi, fixture, `dependabot.yml`,
  `res/xml/`, questo report); `SECURITY_AUDIT.md` e `macos/` preesistenti e
  non toccati.
- Nessun file fuori dal repository modificato. Ambiente locale: Colima e il
  database Supabase locale sono stati avviati per i test pgTAP (DB di test
  ricreato da zero; nessun dato reale).
