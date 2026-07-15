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
| Valuta | **Solo EUR** |
| Lingua | **IT + EN** (flutter l10n fin dall'inizio) |
| Import/Export | JSON (canonico, backup/restore round-trip) + Excel multi-foglio |
| Design | Mini design-system su **Claude Design** (claude.ai/design) prima della UI, poi tradotto in tema Flutter |
| Distribuzione | Uso personale/team: APK diretto, TestFlight in seguito |

## Funzionalità

### Core
- **Portafogli multipli** (Wallet): nome, colore/icona, saldo iniziale, archiviabili.
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
| `Wallet` | nome, icona/colore, saldo iniziale, `archivedAt` |
| `Transaction` | tipo (`expense` / `income` / `transfer`), importo (centesimi, int), data, wallet (e `walletTo` per i transfer), categoria, note |
| `Category` | gerarchica (`parentId`), colore, icona, tipo (spesa/entrata/entrambi), ordinamento |
| `Tag` + `TransactionTag` | many-to-many |
| `CustomFieldDef` / `CustomFieldValue` | definizione (nome, tipo, opzioni) + valore per transazione |
| `RecurringRule` | template transazione + cadenza (RRULE-like), prossima esecuzione |
| `Budget` | categoria, importo mensile, periodo |
| `Attachment` | transazione, path file locale, mimetype |
| `DashboardCard` | tipo card, posizione, config filtri (JSON) |

Importi sempre in **centesimi (int)** per evitare errori di floating point.

## Non-obiettivi (per ora)

- Sync cloud / multi-dispositivo (architettura predisposta, non implementato)
- Multi-valuta
- Import da export bancari o altre app
- Pubblicazione su App Store / Play Store
- Multi-utente / portafogli condivisi

## Riferimenti

- Repo: https://github.com/tech-ALUM/nIpay
- Piano di implementazione: [STEPS.md](STEPS.md)
- Design system: progetto Claude Design "nIpay" (da creare — vedi STEPS.md, M1)
