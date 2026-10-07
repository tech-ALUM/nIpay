# nIpay — istruzioni per Claude Code

Progetto **[ALUM]**: app Flutter iOS+Android per tracciamento spese/entrate.
Team: Alberto Boffi, Francesco Miccoli, Tommaso Panseri, Paolo Gnata.

## Memoria (Open Brain)
- Cassetto: **openbrain-alum** (condiviso col team — MAI usare openbrain-priv per questo repo).
- Tag per i ricordi: `["ALUM", "nipay"]`.
- Source per i ricordi salvati: `claude-code:nIpay`.
- All'inizio di un task, cerca contesto con `search_thoughts` su openbrain-alum (tag `nipay`).
- Salvare ricordi SOLO su richiesta esplicita.

## Documenti di riferimento
- [OVERVIEW.md](OVERVIEW.md) — visione, decisioni, architettura, modello dati.
- [ACCOUNT_SYNC_PLAN.md](ACCOUNT_SYNC_PLAN.md) — account e sync (M-ACC0–M-ACC9). Le milestone M0–M11 sono chiuse (2026-07-16); i rimandati noti sono in OVERVIEW.md.
- [TEST_CHECKLIST.md](TEST_CHECKLIST.md) — checklist da passare prima dei commit importanti.

## Modello concettuale (IMPORTANTE, deciso 2026-07-16)
- **Portafogli = spazi separati**: categorie, tag, campi custom, budget e dashboard
  appartengono a un portafoglio (`walletId` su quelle tabelle, schema Drift **v2**).
- C'è sempre un **portafoglio attivo** (persistito in SharedPreferences,
  `activeWalletIdProvider`): tutta la UI è scoped su di esso. Si cambia toccando
  la wallet card in home.
- I **trasferimenti** sono cross-spazio (walletId → walletToId), senza categoria.
- Ogni nuovo portafoglio riceve il **seed** delle categorie default.
- Export JSON **v3**: globale (restore distruttivo) o per-portafoglio
  (**additivo**, con remap completo degli UUID → reimportabile più volte).
- **Nota spese (v2 dell'app, M11)**: proprietà della singola spesa
  (ExpenseReportEntries: centro di costo, rimborsabile, fattura elettronica);
  schermata dedicata con export **PDF con giustificativi** per intervallo date
  (`lib/data/export/expense_report_pdf.dart`), archivio note con stati
  bozza→inviata→rimborsata, card "Da rimborsare" in home. Schema Drift **v3**.
- **Multi-valuta (decisione 2026-08-11, sostituisce "solo EUR")**: ogni
  `Wallet.currency` è scelta alla creazione (lista curata in
  `lib/core/currencies.dart`, solo valute a 2 decimali). Le transazioni possono
  essere inserite in un'altra valuta (`entryCurrency`/`entryAmountCents`);
  conversione via `ExchangeRateService` prima del salvataggio (vedi sotto
  per la sorgente dei tassi). I trasferimenti cross-valuta convertono due
  volte (entry→valuta "Da"→valuta "A", campo `amountCentsTo`). `formatCents`
  richiede `currency:` (default `'EUR'`); tutte le schermate risolvono la
  valuta dal portafoglio attivo (`activeWalletProvider`). Schema Drift **v5**.
- **Cambio valuta a posteriori (decisione 2026-08-13, semplificata lo stesso
  giorno)**: un portafoglio può cambiare valuta anche dopo la creazione
  (`WalletRepository.changeCurrency`, foglio azioni portafoglio in home).
  Converte **solo il saldo iniziale** del portafoglio, al tasso del momento;
  transazioni storiche, budget e regole ricorrenti NON vengono toccati —
  restano nei loro importi originali, semplicemente letti nella nuova
  valuta (scelta deliberata: niente bulk-update su potenzialmente migliaia
  di righe). Il bottone "Salva" nel foglio azioni è l'unica conferma: fa
  rinomina + cambio valuta insieme, senza dialogo separato.
- **Tassi di cambio: cache giornaliera, non più live-bloccante (decisione
  2026-08-14, sostituisce "blocca se l'API non risponde")**: `getRate` in
  `CachedExchangeRateService` (Frankfurter, `base=EUR`, no chiave) non fa mai
  una chiamata di rete bloccante se esiste già una cache locale
  (SharedPreferences), **anche se vecchia di giorni** — l'app resta
  utilizzabile offline indefinitamente. Se la cache non è di oggi, un
  refresh parte in background per la prossima chiamata, senza bloccare
  quella in corso. `ExchangeRateException` scatta solo se non esiste ALCUNA
  cache pregressa (mai scaricata con successo, tipicamente al primissimo
  utilizzo offline) — l'unico caso in cui serve ancora un fetch bloccante.

- **Security fix (2026-10-05, vedi SECURITY_FIX_REPORT.md)**:
  - **Sync**: coda `SyncOutbox` riempita da trigger SQLite (niente più
    `updatedAt > lastPushedAt`), watermark di pull **per tabella**
    (`SyncCursors`, orologio del server) con paginazione keyset e finestra
    di sovrapposizione, **last-write-wins** su `modified_at` (= `updatedAt`
    locale, limitato a "adesso" dal server; trigger `sync_stamp`), righe
    malformate/rifiutate isolate senza bloccare la sync, `SyncLock` condiviso
    con logout e `wipe()`. Il client non invia mai `updated_at`. Schema
    Drift **v7**. Tag e voci nota spese: soft-delete. Budget e categorie di
    default hanno id deterministici (`lib/core/ids.dart`).
  - **Dati locali legati all'account**: se appartengono a un account non
    loggato (dopo il logout) o diverso da quello loggato, l'app mostra una
    schermata di blocco (`localDataAccessProvider`) finché non si rientra
    con l'account giusto o si rimuovono i dati.
  - **Auth**: password nuove ≥ 12 caratteri con lettere e numeri
    (`lib/core/validation.dart`, da tenere uguale alla dashboard); cambio
    password e cancellazione account chiedono la password attuale; la
    cancellazione passa dalla RPC `request_account_deletion` (data del
    server, login recente via claim `amr`); reset via deep link
    `com.alum.nipay://auth-callback` (da aggiungere agli Additional
    Redirect URLs dell'hosted). Errori sempre tradotti, mai il testo del
    server.
  - **Supabase**: migration `20261005*` da applicare PRIMA di distribuire
    l'app aggiornata; helper RLS nello schema `private` (non esposto);
    `profiles` non scrivibile dal client; Storage limitato a
    JPEG/PNG/WebP/PDF ≤ 10 MiB, nome `{uid}/{uuid}.{ext}`, quota per utente.
    Test: `supabase/tests/security_hardening_test.sql`.
  - **Allegati**: EXIF/GPS rimossi alla scelta della foto e nel PDF
    (`lib/core/image_sanitizer.dart`); path solo `attachments/<uuid>.<ext>`
    (`lib/core/attachment_files.dart`).

## Regole di progetto
- Stack: Flutter 3.44.6 + Riverpod 2.6 (v3 confligge con drift_dev) + Drift.
- La UI non accede mai a Drift direttamente: sempre attraverso i repository
  (`lib/data/repositories/`), interfacce astratte.
- Ogni tabella: `id` UUID, `createdAt`, `updatedAt`, `deletedAt` (soft-delete),
  DateTime come testo ISO (build.yaml). Niente cancellazioni fisiche (eccetto
  il wipe dell'import globale e `LocalDataService.wipe`, vedi sotto).
- **Dati locali legati a un account (decisione 2026-09-30)**: il primo utente
  che sincronizza "rivendica" il device (riga in `SyncStates`, scritta PRIMA
  di inviare dati). Se poi entra un account diverso, `syncNow` lancia
  `LocalDataOwnedByAnotherUserException` senza inviare nulla e la schermata
  account mostra un banner: rimuovere i dati locali o uscire. Il logout di
  default **conserva** i dati; la casella "Rimuovi i dati da questo
  dispositivo" fa sync finale (se fallisce, non cancella nulla) → logout →
  `wipe()` (tutte le tabelle + cartella `attachments/`). Motivo: le foto
  scontrini non sono sincronizzate, un wipe automatico le perderebbe.
- Importi in **centesimi (int)**, formattazione SOLO via `lib/core/money.dart`
  (attenzione: NBSP prima di €, minus tipografico U+2212).
- Stringhe UI sempre in l10n (arb IT + EN), mai hardcoded.
- **TDD**: test prima, in `test/data/` (DB in memoria) e `test/app_test.dart`
  (widget test; usare `_unmount()` a fine test per il Timer di Drift).
- **Property-based testing** (deciso 2026-08-12): per logica pura/algoritmica
  ad alto rischio (parsing importi, round-trip export/import, saldi), oltre
  ai test a esempi fissi usare `forAll` da `test/support/property.dart` —
  harness minimale in-repo, senza dipendenze esterne (valutate e scartate:
  `glados` incompatibile con Dart 3, `kiri_check` in conflitto con
  l'`analyzer` richiesto da `drift_dev`, le alternative senza questo
  conflitto troppo poco adottate). Esempi: `test/core/money_property_test.dart`,
  `test/data/export_property_test.dart`, `test/data/balance_property_test.dart`.
- Dopo modifiche allo schema: `dart run build_runner build --delete-conflicting-outputs`
  e incrementare `schemaVersion` + migration in `app_database.dart`; valutare
  bump di `kExportSchemaVersion`.
- Niente skill/template Dewesoft in questo repo (è [ALUM]).

## Build e ambienti
- `flutter analyze && flutter test` prima di ogni commit; CI su GitHub Actions.
- **iOS**: build in CI (`.github/workflows/ios.yml`, runner macOS, ipa NON
  firmata come artifact); installazione sull'iPhone di Alberto via
  `~/Documents/ALUM/altstore/sideloader-cli install -i nipay-unsigned.ipa`
  (Dadoum Sideloader, Apple ID gratuito, rifirma ogni 7 giorni). AltServer-Linux
  NON funziona (firma rifiutata da iOS 27, errore AMFI CoreTrust).
- **Waydroid** (form factor telefono già configurato): usare l'APK **debug** —
  il driver Vulkan del container crasha, solo il manifest debug forza
  Impeller→OpenGLES. Solo per sviluppo: mai distribuire build debug
  (`debuggable`) su device reali, ora la release ha il permesso INTERNET. Install: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
  (adb su 192.168.240.112:5555).
- **Release firmata**: `flutter build apk --release`; keystore in
  `~/Documents/ALUM/keys/nipay-release.jks` + `android/key.properties` (fuori
  da git). NON perdere il keystore. Senza `key.properties` la build release
  fallisce (niente più fallback sulla chiave debug).
- iOS: non buildabile da questo PC Linux (serve Mac/Codemagic).
- Git: remote via alias `github.com-alum`; identità folder-based (albertoboffi-ALUM).
- Design system: repo `design/` + progetto Claude Design "nIpay"
  (id bd9976c0-fc4b-4478-898e-186d6b354a2b). Direzione scelta: **Bold Ink**
  dark+light (tema in `lib/core/theme/app_theme.dart`).
