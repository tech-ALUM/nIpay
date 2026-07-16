# nIpay — Piano di implementazione (STEPS)

> Milestone incrementali: ognuna lascia l'app in uno stato funzionante e testabile.
> Decisioni di riferimento in [OVERVIEW.md](OVERVIEW.md) (sessione brainstorming 2026-07-15 con Alberto Boffi).
>
> Ambiente di sviluppo: Linux → si compila e testa **Android**; la build iOS richiede un Mac o CI (es. Codemagic) e arriva in M9.

## M0 — Setup progetto ✅ (2026-07-15)
- [x] `flutter create` con org `com.alum.nipay`, struttura cartelle per feature (`lib/features/...`, `lib/data/...`, `lib/core/...`)
- [x] Lint (`flutter_lints` + regole custom), formattazione, `analysis_options.yaml`
- [x] Dipendenze base: `flutter_riverpod`, `drift`, `drift_flutter`, `uuid`, `intl`, `fl_chart`, `go_router` (Riverpod 2.6: la v3 confligge con drift_dev/flutter_test su Flutter 3.44.6, migrare quando si allinea)
- [x] Scaffold l10n IT+EN (`flutter gen-l10n`, file `app_it.arb` / `app_en.arb`)
- [x] CI GitHub Actions: analyze + test + build APK debug su ogni push
- [x] README con istruzioni di build

**Fatto quando**: l'app vuota compila su Android ✓ (app-debug.apk buildato in locale), CI verde (da verificare al primo run su GitHub).

## M1 — Design system (Claude Design)
- [ ] Creare progetto design-system "nIpay" su claude.ai/design (bloccato: serve autorizzazione Claude Design da sessione interattiva; intanto i file sono in `design/` nel repo)
- [x] Palette colori, tipografia, spaziature (foundation) — `design/foundation/` (brand ALUM)
- [x] Mockup HTML delle schermate chiave: home/portafogli, lista transazioni, inserimento transazione, dashboard statistiche — `design/mockups/`
- [ ] Review del team ALUM sui mockup
- [ ] Tradurre il design approvato in `ThemeData` Flutter (light + dark) e widget base (card, bottoni, chip)

**Fatto quando**: il team ha approvato i mockup e il tema Flutter li rispecchia.

## M2 — Layer dati ✅ (2026-07-15)
- [x] Schema Drift: tutte le tabelle di OVERVIEW.md (Wallet, Transaction, Category, Tag, CustomFieldDef/Value, RecurringRule, Budget, Attachment, DashboardCard)
- [x] Convenzioni sync-ready su ogni tabella: `id` UUID testuale, `createdAt`, `updatedAt`, `deletedAt` (soft-delete); DateTime salvati come ISO-8601 (build.yaml)
- [x] Importi in centesimi (int)
- [x] Repository per entità con query reattive (Stream) e interfacce astratte
- [x] Seed categorie di default (repository idempotente; il wiring "alla prima apertura" arriva con la UI in M3)
- [x] Test unitari sui repository (DB in memoria) — 20 test, TDD

**Fatto quando**: CRUD completo da test per ogni entità ✓, zero accessi a Drift fuori dal layer dati ✓. Nota: trasferimenti ricorrenti non supportati (UnsupportedError), ricorrenza mensile con riporto giorno (31 gen + 1 mese → inizio marzo) — rivedere se servirà "ultimo giorno del mese".

## M3 — Portafogli e transazioni (MVP usabile) ✅ (2026-07-16)
- [x] CRUD portafogli: crea (nome, colore, saldo iniziale), rinomina/elimina con long-press sulla card (archivio UI rimandato)
- [x] CRUD transazioni: spesa/entrata con importo, data, categoria, descrizione (tag in inserimento arrivano con M4)
- [x] Trasferimenti tra portafogli (esclusi dai totali spesa/entrata)
- [x] Lista transazioni con filtri: mese, portafoglio, categoria, ricerca testo (filtro tag in M4; filtro client-side, query dedicata in M6)
- [x] Saldo per portafoglio e totale + entrate/uscite del mese in home
- [x] Widget test dei flussi principali (crea portafoglio → saldo; aggiungi spesa → saldo e lista aggiornati)
- [x] Extra da M1: tema Bold Ink dark+light in Flutter (`lib/core/theme/app_theme.dart`) con switch Sistema/Chiaro/Scuro nelle impostazioni

**Fatto quando**: uso quotidiano reale possibile ✓ (24 test verdi, analyze pulito). Nota: preferenza tema non ancora persistita (StateProvider in-memory, serve shared_preferences).

## M4 — Customizzazione ✅ (2026-07-16)
- [x] Gestione categorie: crea/modifica/elimina, colore+icona, riordino drag&drop (Altro → Categorie); gerarchia supportata dal layer dati ma non ancora esposta nella UI
- [x] Gestione tag (Altro → Tag) + creazione tag al volo dal sheet transazione
- [x] Campi custom: definizione (testo, numero, scelta, data) in Altro → Campi custom, compilazione nel sheet transazione
- [x] Ricerca lista estesa ai valori dei campi custom + filtro per tag

**Fatto quando**: una transazione può avere categoria custom, tag e campi custom creati dall'utente ✓ (29 test verdi). Rimandato: UI per sottocategorie (parentId già nel modello dati).

## M5 — Ricorrenze e budget ✅ (2026-07-16)
- [x] RecurringRule: template + cadenza, generazione automatica all'apertura app (catch-up nel bootstrap) e subito alla creazione
- [x] UI gestione ricorrenze: Altro → Ricorrenze (crea, pausa/riprendi, elimina, prossima occorrenza visibile)
- [x] Budget mensile per categoria con barra di avanzamento (sezione in home + manager in Altro → Budget; colori teal/giallo ≥80%/rosso ≥100%)
- [x] Avviso budget all'80% e al superamento: snackbar in-app al salvataggio della spesa (notifiche push locali rimandate: servirebbe flutter_local_notifications + permessi Android 13)

**Fatto quando**: stipendio/affitto si generano da soli ✓; sforare un budget è visibile e avvisato ✓ (31 test verdi).

## M6 — Statistiche (dashboard componibile) ✅ (2026-07-16)
- [x] Motore di aggregazione TDD: spese per categoria e serie mensile 6 mesi (query Drift), cash flow da totalsForPeriod
- [x] Card fl_chart: donut per categoria (top-5 + altro), trend mensile a barre, cash flow KPI, avanzamento budget
- [x] Dashboard componibile: aggiungi (dialog), rimuovi (✕), riordina (drag), selettore mese globale della tab
- [x] Persistenza configurazione dashboard (tabella DashboardCard, stream reattivo)

**Fatto quando**: dashboard personale persistita ✓ (34 test verdi). Rimandato: confronto periodi come card dedicata e filtri per-card (portafogli/categorie) — il selettore periodo è per ora globale.

## M7 — Allegati ✅ (2026-07-16)
- [x] Foto da camera/galleria per transazione (image_picker, max 2000px q85)
- [x] Storage in `<documents>/attachments/` con nome UUID; thumbnail e viewer zoom nel dettaglio transazione (tap su una riga)
- [x] Dettaglio transazione con eliminazione (soft-delete)
- [ ] Pulizia file orfani (rimandata: i file di transazioni eliminate restano su disco)

**Fatto quando**: scontrino fotografabile e riapribile dalla transazione ✓.

## M8 — Export / Import ✅ (2026-07-16)
- [x] Export JSON canonico versionato (`schemaVersion: 1`, tutte le 11 tabelle); con allegati → .zip (nipay.json + attachments/)
- [x] Import JSON: validazione app+schema, wipe transazionale e restore completo, ripristino file allegati dallo zip
- [x] Export Excel multi-foglio (Portafogli, Categorie, Transazioni, Budget) reimportabile
- [x] Import Excel round-trip (solo file nIpay; ripristina le 4 tabelle dei fogli)
- [x] Condivisione via share sheet (share_plus) e selezione file per l'import (file_selector), con dialog di conferma distruttiva
- [x] Test round-trip TDD: JSON completo (11 tabelle + saldo ricalcolato) ed Excel

**Fatto quando**: il test round-trip JSON e Excel passa ✓ (37 test verdi).

## M9 — Polish e release ✅ (2026-07-16)
- [x] Localizzazione IT+EN completa (tutte le stringhe UI in arb, nessuna hardcoded)
- [x] Preferenza tema persistita (shared_preferences) — chiuso il debito di M3
- [x] Onboarding minimo: empty state guidato al primo avvio (crea portafoglio)
- [x] Icona app Android+iOS (mark coral/teal su ink, generata da assets/icon/icon.png); splash default Flutter
- [x] Build APK release **firmato** (keystore in ~/Documents/ALUM/keys/, key.properties fuori da git, fallback debug in CI)
- [ ] Build iOS via Mac/Codemagic + TestFlight (impossibile da Linux — serve un Mac del team o Codemagic)

**Fatto quando**: APK release firmato pronto per la distribuzione al team ✓ (37 test verdi). iOS rimandata a quando c'è un Mac.

## Futuro (fuori scope, predisposto)
- Sync cloud multi-dispositivo (il repository layer e i campi UUID/updatedAt/deletedAt sono già pronti)
- Import da export bancari (CSV home banking) con mappatura colonne
- Multi-valuta
