# nIpay — Overview

> App mobile (iOS + Android) per il tracciamento di spese ed entrate, multi-portafoglio, super customizzabile, con statistiche componibili e import/export completo.
>
> **Fonte delle decisioni**: sessione di brainstorming Claude Code con Alberto Boffi del 2026-07-15. Nessuna decisione qui riportata è inventata: ogni scelta è stata confermata esplicitamente in quella sessione.

## Obiettivo

Tracciare spese e entrate mensili in modo flessibile per uso **personale/team ALUM** (Alberto Boffi, Francesco Miccoli, Tommaso Panseri, Paolo Gnata). Nessuna pubblicazione store prevista per ora: distribuzione via APK diretto (Android) e TestFlight (iOS, in futuro).

## Decisioni chiave (2026-07-15)

| Tema | Decisione |
|---|---|
| Stack | **Flutter** (Dart), unico codebase iOS+Android |
| State management | **Riverpod** |
| Persistenza | **Drift** (SQLite tipizzato, query reattive, migrazioni) |
| Dati | **Solo locale**, offline-first, ma architettura **sync-ready** per futuro sync cloud |
| Valuta | **Multi-valuta** (decisione 2026-08-11, sostituisce "solo EUR"): ogni portafoglio ha una valuta scelta alla creazione; ogni transazione può essere inserita in una valuta diversa, convertita al salvataggio con tasso di cambio live |
| Lingua | **IT + EN** (flutter l10n fin dall'inizio) |
| Import/Export | JSON (canonico, backup/restore round-trip) + Excel multi-foglio |
| Design | Mini design-system su **Claude Design** (claude.ai/design) prima della UI, poi tradotto in tema Flutter |
| Distribuzione | Uso personale/team: APK diretto, TestFlight in seguito |

## Funzionalità

### Core
- **Portafogli multipli = spazi separati** (decisione 2026-07-16): ogni portafoglio è un libro contabile indipendente con le SUE categorie, tag, campi custom, budget e dashboard. In home si cambia spazio toccando la card del portafoglio (attivo persistito). I trasferimenti restano possibili tra spazi diversi.
- **Transazioni**: spesa, entrata, **trasferimento** tra portafogli (origine → destinazione, escluso dai totali di spesa/entrata).
- **Categorie custom**: gerarchiche (categoria/sottocategoria), colore + icona, create/modificate/riordinate dall'utente. Set di default alla prima apertura.
- **Tag liberi** sulle transazioni.
- **Campi custom**: l'utente definisce campi aggiuntivi (testo, numero, scelta, data) che compaiono sulle transazioni.

### Automazioni
- **Transazioni ricorrenti**: regole con cadenza configurabile (es. stipendio, affitto, abbonamenti) che generano transazioni automaticamente.
- **Budget per categoria**: tetto mensile con barra di avanzamento e avviso all'avvicinarsi del limite.

### Allegati
- Foto/file per transazione (es. scontrini), salvati nella directory dell'app e riferiti dal DB.

### Statistiche — dashboard componibile
L'utente compone la propria dashboard scegliendo, ordinando e configurando le card:
- Torta spese per categoria
- Trend mensile spese/entrate
- Cash flow (entrate − uscite)
- Avanzamento budget
- Confronto tra periodi

Ogni card è filtrabile per periodo, portafogli, categorie. La configurazione è persistita nel DB.

### Import / Export
- **JSON**: formato canonico completo e **versionato** (`schemaVersion`). Round-trip perfetto: export → import ripristina tutto (portafogli, transazioni, categorie, tag, campi custom, ricorrenze, budget, config dashboard). Con allegati l'export diventa un archivio **.zip** (JSON + cartella allegati).
- **Excel (.xlsx)**: multi-foglio (Transazioni, Portafogli, Categorie, Budget), leggibile e **reimportabile** — senza allegati.
- Scopo primario: **backup/restore e migrazione dispositivo** (non import da export bancari, valutabile in futuro).

## Architettura

```
UI (Flutter widgets, tema da design-system)
  └── State (Riverpod providers)
        └── Repository layer (interfacce astratte)   ← confine sync-ready
              └── Drift (SQLite locale)
```

- **Offline-first, sync-ready**: ogni record ha `id` UUID, `createdAt`, `updatedAt` e soft-delete (`deletedAt`). Nessuna cancellazione fisica. Quando si vorrà il sync cloud, si aggiunge un sync engine sotto il repository layer senza toccare UI e logica.
- **Repository pattern**: la UI non conosce Drift; ogni entità ha il suo repository con query reattive (Stream).

## Modello dati (entità principali)

| Entità | Note |
|---|---|
| `Wallet` | nome, icona/colore, saldo iniziale, **valuta** (ISO 4217, scelta alla creazione, modificabile in seguito — converte solo il saldo iniziale al tasso attuale, non lo storico), `archivedAt` |
| `Transaction` | tipo (`expense` / `income` / `transfer`), importo (centesimi, int, nella valuta del wallet), data, wallet (e `walletTo` per i transfer), categoria, note; se inserita in valuta diversa: `entryCurrency`/`entryAmountCents` (importo originale) e, per i transfer cross-valuta, `amountCentsTo` (credito convertito nella valuta di destinazione) |
| `Category` | gerarchica (`parentId`), colore, icona, tipo (spesa/entrata/entrambi), ordinamento |
| `Tag` + `TransactionTag` | many-to-many |
| `CustomFieldDef` / `CustomFieldValue` | definizione (nome, tipo, opzioni) + valore per transazione |
| `RecurringRule` | template transazione + cadenza (RRULE-like), prossima esecuzione |
| `Budget` | categoria, importo mensile, periodo |
| `Attachment` | transazione, path file locale, mimetype |
| `DashboardCard` | tipo card, posizione, config filtri (JSON) |

Importi sempre in **centesimi (int)** per evitare errori di floating point.

## Non-obiettivi (per ora)

- Import da export bancari o altre app
- Pubblicazione su App Store / Play Store
- Multi-utente / portafogli condivisi

## Rimandati noti

Lasciati fuori deliberatamente durante le milestone M0–M11 (completate il
2026-07-16; il piano di dettaglio `STEPS.md` è stato rimosso, resta nella
storia git):

- Archivio portafogli nella UI (il campo `archivedAt` esiste già).
- UI per le sottocategorie (`parentId` già nel modello dati).
- Notifiche push locali per i budget (oggi solo snackbar in-app; servirebbe
  `flutter_local_notifications` + permessi Android 13).
- Confronto periodi come card dedicata e filtri per-card nella dashboard
  (il selettore periodo è globale).
- Pulizia dei file allegati orfani (le foto di transazioni eliminate
  restano su disco).
- In modifica di una transazione non si cambiano tag e allegati (solo in
  creazione).

## Riferimenti

- Repo: https://github.com/tech-ALUM/nIpay
- Account e sync: [ACCOUNT_SYNC_PLAN.md](ACCOUNT_SYNC_PLAN.md)
- Checklist di test: [TEST_CHECKLIST.md](TEST_CHECKLIST.md)
- Design system: progetto Claude Design "nIpay" + mockup in `design/`; tema
  in `lib/core/theme/app_theme.dart`
