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
- [STEPS.md](STEPS.md) — piano milestone M0–M11, tutte ✅ (2026-07-16). Lì sono annotati anche i rimandati.

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

## Regole di progetto
- Stack: Flutter 3.44.6 + Riverpod 2.6 (v3 confligge con drift_dev) + Drift.
- La UI non accede mai a Drift direttamente: sempre attraverso i repository
  (`lib/data/repositories/`), interfacce astratte.
- Ogni tabella: `id` UUID, `createdAt`, `updatedAt`, `deletedAt` (soft-delete),
  DateTime come testo ISO (build.yaml). Niente cancellazioni fisiche (eccetto
  il wipe dell'import globale).
- Importi in **centesimi (int)**, formattazione SOLO via `lib/core/money.dart`
  (attenzione: NBSP prima di €, minus tipografico U+2212).
- Stringhe UI sempre in l10n (arb IT + EN), mai hardcoded.
- **TDD**: test prima, in `test/data/` (DB in memoria) e `test/app_test.dart`
  (widget test; usare `_unmount()` a fine test per il Timer di Drift).
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
  Impeller→OpenGLES. Install: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`
  (adb su 192.168.240.112:5555).
- **Release firmata**: `flutter build apk --release`; keystore in
  `~/Documents/ALUM/keys/nipay-release.jks` + `android/key.properties` (fuori
  da git). NON perdere il keystore.
- iOS: non buildabile da questo PC Linux (serve Mac/Codemagic).
- Git: remote via alias `github.com-alum`; identità folder-based (albertoboffi-ALUM).
- Design system: repo `design/` + progetto Claude Design "nIpay"
  (id bd9976c0-fc4b-4478-898e-186d6b354a2b). Direzione scelta: **Bold Ink**
  dark+light (tema in `lib/core/theme/app_theme.dart`).
