# Security audit — nIpay (Flutter + Supabase)

| | |
|---|---|
| **Data** | 2026-10-05 |
| **Revisione analizzata** | branch `beta-sergio`, commit `dc9594a` |
| **Backend** | progetto Supabase `tyjugoiohkktlyizfpfx` ("Nipay-test-08/09/2026") |
| **Auditor** | Claude Code (Claude Opus 5.5) |
| **Tipo** | white-box (codice, migration, configurazione) + verifiche dinamiche non distruttive |

## Sintesi esecutiva

L'isolamento dei dati in **lettura** tra utenti è solido: RLS abilitata su tutte le
tabelle, ownership radicata su `wallets.owner_user_id`, bucket privato con policy
per prefisso, nessuna `service_role` nel client, OpenAPI e GraphQL non esposti.
Non ho trovato modi per leggere dati di un altro utente.

I problemi più seri non riguardano la riservatezza ma l'**integrità** e la
**disponibilità** dei dati, e la **robustezza del ciclo di vita dell'account**:

- il motore di sync perde modifiche in modo silenzioso e permanente
  (dimostrato con tre PoC eseguite): watermark unico per tutte le tabelle,
  pull non paginato (limite `max_rows`), timestamp controllati dal client,
  nessuna gestione dei conflitti;
- un accesso momentaneo a una sessione (telefono sbloccato, token rubato)
  basta per cambiare la password senza conoscere quella attuale,
  disconnettere il proprietario dagli altri device e, retrodatando la
  richiesta di cancellazione, **distruggere l'account in meno di 24 ore**,
  saltando il grace period di 30 giorni. Il reset password via email non
  può essere completato;
- la RLS non controlla tutte le chiavi esterne (categorie, centri di costo,
  note spese) e c'è un vincolo `UNIQUE` globale: si possono creare
  riferimenti cross-tenant e bloccare la sync di un altro utente di cui si
  conoscono gli UUID;
- mancano quote e limiti (Storage, DB, email) e la cancellazione definitiva
  lascia orfani gli scontrini oltre il centesimo file.

Totale: **25 rilievi** — 0 Critical, 1 High, 12 Medium, 7 Low,
5 Informational. Sono stati dimostrati con prove eseguite i difetti di sync
(3 PoC) e quelli a livello di database (21 test pgTAP su Supabase locale).

### Legenda stato di verifica

- ✅ **Verificata**: dimostrata con una prova eseguita durante l'audit (PoC o richiesta reale).
- 🔎 **Confermata da analisi**: evidente dal codice, dalla configurazione o dal comportamento documentato delle librerie/Postgres; non eseguita.
- ⚠️ **Da verificare**: dipende da configurazioni del progetto hosted non leggibili senza credenziali di amministrazione.

## Ambito e metodologia

**Codice analizzato**: tutto `lib/` (in particolare `data/services/{auth,sync,local_data,exchange_rate}_service.dart`,
repository, `data/export/`, `features/account`, gestione allegati e PDF), `supabase/`
(migration, policy RLS e Storage, Edge Function, test pgTAP, `config.toml`), manifest
Android/iOS, workflow CI, script, documenti di progetto (`ACCOUNT_SYNC_PLAN.md`,
`TEST_CHECKLIST.md`) e la history git per il codice rimosso.

**Verifiche dinamiche eseguite** (dettaglio nell'Appendice B):

1. Richieste **anonime e di sola lettura** al progetto di test, usando la
   publishable key già presente nel repo: impostazioni Auth pubbliche, lettura
   anonima di tabelle e bucket, endpoint RPC/OpenAPI/GraphQL.
2. **PoC del motore di sync** su una **copia isolata** del repository (nello
   scratchpad, fuori dal repo), con DB in memoria e un server simulato che
   replica trigger e upsert di PostgREST. Nessuna rete, nessun dato reale.
3. **Test pgTAP su Supabase locale** (aggiornamento del 2026-10-05, dopo
   l'installazione di Colima): database Postgres 17.6 locale con le 5
   migration del repo applicate. La suite esistente del team passa (88/88),
   quindi l'ambiente è equivalente a quello della CI. Il file di verifica
   dell'audit (Appendice D) dà **21 test su 21 che confermano i difetti**.
   Tutti i test girano in una transazione annullata alla fine.

**Volutamente NON eseguito**: creazione di account, login, scritture o modifiche
sull'istanza hosted, invio di email (reset/signup), invocazione dell'Edge Function di
purge, tentativi di brute force o test di carico. In locale ho fatto solo verifiche
a livello di database (pgTAP), senza i flussi HTTP di Auth e Storage.

Nessun file del repository è stato modificato, a parte la creazione di questo report.

---

## Rilievi

## [HIGH] NIP-01 — Watermark di pull unico e inaffidabile: perdita silenziosa e permanente di modifiche

**Categoria:** Race condition / Integrità dei dati (OWASP A04 — Insecure Design)
**Severità:** High
**Componente interessato:** `lib/data/services/sync_service.dart` (`SupabaseSyncService.syncNow`, `SupabaseSyncRemote.selectChangedSince`)

### Descrizione
Il pull usa un **solo** watermark `lastPulledAt` per tutte le 13 tabelle: alla fine
della sync viene impostato al massimo degli `updated_at` visti in **qualunque**
tabella (`sync_service.dart:139-156`). Le tabelle però vengono scaricate in
sequenza, in momenti diversi. Tre meccanismi indipendenti fanno sì che righe con
`updated_at` minore del watermark non vengano scaricate **mai più**:

1. **Race tra tabelle**: una modifica a una tabella già scaricata (es. `wallets`)
   che avviene mentre la sync scarica le tabelle successive ha un `updated_at`
   più basso del massimo visto più avanti (es. su `transactions`) e viene saltata.
2. **Troncamento a `max_rows`**: `selectChangedSince` (`sync_service.dart:38-47`)
   esegue `select()` senza `order` e senza paginazione. PostgREST limita la
   risposta a `max_rows` (1000 in `supabase/config.toml:18`, 1000 di default
   anche sul progetto hosted). Se cambiano più di 1000 righe — ad esempio alla
   **prima sync di un nuovo device** di un utente con più di 1000 transazioni,
   un caso normale dopo pochi mesi d'uso — il server ne restituisce un
   sottoinsieme arbitrario. Il watermark avanza al massimo di quel sottoinsieme
   e le righe escluse vanno perse.
3. **Commit fuori ordine**: il trigger `set_updated_at` usa `now()`, cioè l'ora
   di **inizio** della transazione. Una transazione iniziata prima ma committata
   dopo un pull produce righe con `updated_at` già superato dal watermark.

In tutti e tre i casi non c'è alcun errore o log: i device restano diversi dal
server senza che nessuno se ne accorga.

### Impatto
Saldi, movimenti, note spese e budget diversi tra un device e l'altro; un device
nuovo o reinstallato vede solo una parte dei dati. Non serve un attaccante: basta
l'uso normale con due device (la sync parte ogni 5 minuti, al resume e al login,
`lib/app.dart:56-94`).

### Evidenza
- `sync_service.dart:139-156` — `pulledWatermarks` / `maxPulled = ... reduce(max)`
- `sync_service.dart:38-47` — `select().gt(column, since)` senza `order`/`range`
- `supabase/config.toml:18` — `max_rows = 1000`
- `supabase/migrations/20260908000000_initial_schema.sql:23-31` — `new.updated_at = now()`

### Verifica
✅ **PoC 2** (Appendice A), eseguita sulla copia isolata con server simulato: mentre
il device B sincronizza (wallets già scaricati, categories in corso), un altro
device rinomina il wallet e modifica una transazione. Risultato:
`wallet su server: Conto RINOMINATO — su B: Conto`, anche dopo altre due sync complete.
Il troncamento a `max_rows` è confermato dall'analisi del codice e dal
comportamento documentato di PostgREST 🔎; non l'ho provato sull'istanza (servirebbe
un account con più di 1000 righe).

### Riproduzione
1. Ambiente di staging, utente di test, device A e B.
2. Su A creare (o importare via SQL nel wallet dell'utente) più di 1000 transazioni e sincronizzare.
3. Installare l'app su B, fare login e attendere la sync.
4. Confrontare il numero di transazioni su B con `select count(*) from transactions where wallet_id = ...`.
5. Per la race: eseguire la PoC 2 dell'Appendice A.

### Rischio
È una perdita di integrità silenziosa in un'app finanziaria: l'utente non ha modo di
accorgersene e prende decisioni (rimborsi, budget, note spese) su dati incompleti.

### Mitigazione consigliata
- Un watermark **per tabella**.
- Pull **ordinato e paginato** con keyset: `order(updated_at).order(id)`, poi
  `updated_at > w OR (updated_at = w AND id > last_id)` finché le pagine non sono vuote.
- Una finestra di sovrapposizione (es. pull da `w - 2 minuti`) con applicazione
  idempotente delle righe.
- Per i commit fuori ordine, un contatore di modifica assegnato dal server (es.
  colonna `change_seq` da sequence) oppure una RPC `pull_changes(since)` che
  escluda le transazioni non ancora committate (`pg_current_snapshot()`).
- Test di regressione con più di 1000 righe e con scritture concorrenti.

---

## [MEDIUM] NIP-02 — Timestamp scelti dal client entrano nel watermark "lato server": avvelenamento permanente della sync

**Categoria:** Fiducia eccessiva nel client / Integrità (OWASP A04, A08)
**Severità:** Medium
**Componente interessato:** `sync_service.dart` (`_syncTransactionTags`, `_syncCustomFieldValues`, `_syncExpenseReportEntries`); trigger `set_updated_at` nello schema

### Descrizione
Secondo il design (commento su `SyncStates`, `lib/data/db/tables.dart`), `lastPulledAt`
deve essere nel dominio dell'orologio **server**. In tre punti però entra un valore
scelto dal client:

- **`transaction_tags`**: il pull usa `created_at` come colonna watermark
  (`sync_service.dart:703-706`). `created_at` è inviato dal client (`:697`) e
  PostgREST lo scrive sia nell'INSERT sia nel ramo `DO UPDATE` dell'upsert.
- **`custom_field_values`** e **`expense_report_entries`**: il client invia
  `updated_at` (`:742`, `:781`). I trigger `set_updated_at` sono solo
  `BEFORE UPDATE` (`initial_schema.sql:176, 299`), quindi in INSERT resta il
  valore del client.
- Nessun `CHECK` impedisce date future.
- Più in generale, **ogni** tabella accetta in INSERT un `updated_at` esplicito
  scelto dal client, perché nessun trigger copre l'INSERT: l'app oggi non lo
  invia per le altre tabelle, ma un client modificato o un token rubato sì (vedi
  la verifica sotto, provata su `wallets`).

Il massimo di questi valori diventa il `lastPulledAt` **unico** (NIP-01) di tutti
i device dell'utente.

### Impatto
Un device con l'orologio avanti, anche solo di qualche ora, oppure un client
malevolo o un token rubato, può inviare `created_at = 2099-01-01`. Da quel momento
tutti gli altri device dell'utente smettono di ricevere **qualsiasi** modifica, su
tutte le tabelle, senza errori. L'effetto resta anche dopo la revoca del token e
sparisce solo cancellando i dati locali di ogni device. Con l'orologio indietro
succede il contrario: le righe nuove nascono con timestamp già superati dal
watermark e nessun altro device le scarica.

### Evidenza
- `sync_service.dart:697, 703-706, 742, 781`
- `initial_schema.sql:76-299` — tutti i trigger sono `before update` (nessun `before insert`)

### Verifica
✅ **PoC 1** (Appendice A): il device A ha l'orologio avanti di un giorno e crea
un'associazione tag. Dopo la sync, B ha `lastPulledAt = 2026-10-06 10:00Z` mentre
il server è a `2026-10-05 10:00:03Z`. A cambia poi un importo (sul server diventa
99900); B, anche dopo una nuova sync, mostra ancora `1000`.
✅ **pgTAP su Postgres reale** (Appendice D, test 13-15): `wallets.updated_at = 2099`
viene accettato in INSERT, `custom_field_values.updated_at` del client viene
conservato, e `transaction_tags.created_at` scelto dal client resta anche
nell'upsert `ON CONFLICT DO UPDATE` (lo stesso SQL che PostgREST genera per
`Prefer: resolution=merge-duplicates`).

### Riproduzione
Solo in staging, con un utente di test:
1. Fare login e sincronizzare sul device B.
2. Con il token del device A:
   `POST /rest/v1/transaction_tags` con header `Prefer: resolution=merge-duplicates`
   e body `{"transaction_id":"<tx propria>","tag_id":"<tag proprio>","created_at":"2099-01-01T00:00:00Z"}`.
3. Sincronizzare B: in `sync_states` di B il `last_pulled_at` diventa 2099.
4. Modificare una transazione da A: B non la riceverà più.

### Rischio
Chiunque abbia per un momento una sessione valida, o un device configurato male,
causa un blocco permanente e invisibile della sincronizzazione.

### Mitigazione consigliata
- Trigger `BEFORE INSERT OR UPDATE` che imponga `updated_at = clock_timestamp()` su
  tutte le tabelle.
- Aggiungere a `transaction_tags` un `updated_at` assegnato dal server e usarlo
  come watermark, invece di `created_at`.
- Non inviare mai `updated_at` dal client.
- `CHECK (created_at <= now() + interval '5 minutes')`.
- Lato client, scartare i watermark nel futuro rispetto all'ora del server (ad
  esempio l'header `Date` della risposta).

---

## [MEDIUM] NIP-03 — Nessuna gestione dei conflitti: vince l'ultimo push, e l'"eco" del push sovrascrive modifiche più recenti

**Categoria:** Race condition / Integrità
**Severità:** Medium
**Componente interessato:** `sync_service.dart` (upsert incondizionato in tutte le `_syncX`), trigger `set_updated_at`

### Descrizione
Il push è un upsert senza condizioni (`sync_service.dart:34`) e il server
riassegna `updated_at` a ogni scrittura. Il server quindi non sa su quale versione
della riga il client ha lavorato e non può rifiutare una scrittura basata su dati
vecchi:

- una modifica fatta **offline** ore prima, e inviata dopo, sovrascrive una
  modifica più recente fatta su un altro device. Vince l'ultimo che fa push, non
  l'ultimo che ha scritto;
- un soft-delete fatto su B può essere annullato da un push di A che ha ancora
  `deleted_at = null`;
- **eco**: le righe scaricate vengono salvate localmente con `updatedAt` uguale
  all'`updated_at` del server. Se questo è maggiore del `pushCutoff`, catturato con
  l'orologio locale *prima* del pull (`:137`), alla sync successiva vengono
  re-inviate e possono sovrascrivere modifiche ancora più recenti di altri device.
  Succede sempre quando l'orologio del device è indietro rispetto al server, e
  comunque per le righe modificate durante la sync.

### Impatto
Si perdono modifiche concorrenti (importi corretti che tornano al valore
precedente, spese cancellate che ricompaiono) senza alcun avviso.

### Evidenza
`sync_service.dart:34` (`upsert(rows)`), `:137` (`pushCutoff = DateTime.now()`),
`:208-210` e analoghe (selezione `updatedAt > pushSince`); in nessun punto viene
confrontata la versione.

### Verifica
✅ **PoC 3** (Appendice A): A, offline, imposta 1500; B imposta 2000 e sincronizza;
quando A torna online il valore finale è **1500** sia sul server sia su B. Ho
osservato anche l'eco: nella prima esecuzione della PoC 2, con l'orologio del
device circa 1,5 ore indietro rispetto al server simulato, la sync successiva di B
ha re-inviato la propria copia vecchia e annullato la rinomina fatta da un altro
device.

### Riproduzione
Due device di test con lo stesso account. Mettere A offline e modificare l'importo
di una spesa. Su B modificare la stessa spesa e sincronizzare. Riportare A online e
sincronizzare: prevale il valore di A.

### Rischio
I conflitti sono normali in un'app offline-first multi-device. Senza una
risoluzione esplicita i dati finanziari si corrompono in silenzio. La beta M-ACC9
prevede proprio questo test ("conflitto intenzionale").

### Mitigazione consigliata
- Concorrenza ottimistica: il client invia il `base_updated_at` (o una versione
  intera) su cui ha lavorato, e il server applica la scrittura solo se coincide
  (RPC `upsert_if_unchanged` o trigger che rifiuta con 409). In caso di conflitto
  il client riscarica e risolve (LWW su un timestamp HLC validato, oppure merge per
  campo).
- Tracciare le righe "sporche" con un flag locale invece di confrontare
  `updatedAt > pushSince`, così le righe appena scaricate non vengono re-inviate.
- Tombstone vincenti: un `deleted_at` non deve poter essere annullato da un push
  basato su una versione precedente.

---

## [MEDIUM] NIP-04 — Sync fragile: una singola riga "avvelenata" blocca per sempre la sincronizzazione (nessuna validazione server-side, errori ignorati)

**Categoria:** Validazione input / Error handling / Disponibilità
**Severità:** Medium
**Componente interessato:** schema SQL (assenza di `CHECK`), pull in `sync_service.dart`, `lib/app.dart:79-82`, vincolo `budgets.unique(category_id)`

### Descrizione
- Il server accetta valori che il client non sa gestire: `currency` (testo libero,
  mentre il client usa una lista curata), `color_hex`, `icon`, `dashboard_cards.type`,
  `config_json`, `custom_field_defs.options` (`jsonb` arbitrario), importi
  negativi, testi di lunghezza illimitata. Gli unici `CHECK` presenti sono su
  `kind`, `type`, `frequency` e `status`.
- Il pull fa cast diretti (`row['options'] as List?`, `as int`, `byName(...)`).
  Una riga non conforme lancia un'eccezione a metà sync. Lo stato viene salvato
  solo alla fine (`sync_service.dart:158-166`), quindi la stessa riga viene
  riscaricata e fa fallire **ogni** sync successiva, su tutti i device.
- Alcune schermate usano `int.parse` sul colore (`category_manager_screen.dart:167`,
  `wallet_form_sheet.dart:362`): un `color_hex` malformato fa crashare la schermata.
- `budgets` ha `unique (category_id)` (`initial_schema.sql:190`) e gli id sono
  generati dal client. Se due device offline creano un budget sulla stessa
  categoria (con due id diversi), il secondo push fallisce con 23505. A quel punto
  `_syncBudgets` lancia un'eccezione e **tutte le tabelle successive** (ricorrenze,
  dashboard, transazioni, note spese…) smettono di sincronizzarsi, per sempre, e
  dalla UI non c'è modo di rimediare.
- Se una sync si interrompe dopo i wallet ma prima delle categorie, al riavvio il
  bootstrap (`lib/core/providers.dart`, `seedDefaults` per i wallet "senza
  categorie") crea un secondo set di categorie di default con UUID nuovi, che poi
  viene sincronizzato: categorie duplicate su tutti i device.
- Le sync in background ignorano ogni errore (`catchError((_) {})`): l'utente non
  sa che la sync è bloccata da giorni.

### Impatto
Blocco persistente della sincronizzazione dell'account, che può nascere da un bug,
da una race offline, oppure da un'azione deliberata con un token rubato (basta una
PATCH su `custom_field_defs.options`). Dati che divergono senza avviso e crash
della UI.

### Evidenza
`initial_schema.sql` (assenza di CHECK, `:190`), `sync_service.dart:158-166` e i
blocchi di pull (`:382` per `options`), `app.dart:79-82`.

### Verifica
✅ **pgTAP su Postgres reale** (Appendice D, test 16-18): il DB accetta `options`
non-array, `color_hex = 'zzz'`, `currency = 'NON-UNA-VALUTA'`, importi negativi
e una descrizione da 1 MB. 🔎 Che il pull vada poi in errore e blocchi la sync
deriva dall'analisi del codice (`as List?`, cast diretti).

### Riproduzione
In staging, con il token di un utente di test:
`PATCH /rest/v1/custom_field_defs?id=eq.<id>` con body `{"options":{"a":1}}`.
Dall'app, "Sincronizza ora" fallisce a ogni tentativo e sugli altri device la sync
si ferma.
Per il budget: due device offline creano un budget sulla stessa categoria, poi
sincronizzano entrambi.

### Rischio
Un singolo dato inatteso rende inutilizzabile la funzione principale dell'account,
senza segnali per l'utente né strumenti di recupero.

### Mitigazione consigliata
- Vincoli `CHECK` lato DB, ad esempio:
  - `currency ~ '^[A-Z]{3}$'` (oppure FK verso una tabella delle valute);
  - `color_hex ~ '^#[0-9A-Fa-f]{6}$'`;
  - `amount_cents >= 0`;
  - `length(name) <= 100` e limiti analoghi sugli altri testi;
  - `jsonb_typeof(options) = 'array'`.
- Indice unico parziale su budgets `(wallet_id, category_id) where deleted_at is null`
  e gestione del conflitto (merge) lato client.
- Parsing difensivo **per riga**: le righe non valide vanno in quarantena e il
  watermark avanza comunque.
- Isolare gli errori per tabella, così un problema su `budgets` non blocca `transactions`.
- Rendere visibile in UI lo stato della sync (ultimo successo, errore persistente).

---

## [MEDIUM] NIP-05 — Cancellazione account: il grace period dipende da un timestamp scelto dal client

**Categoria:** Fiducia nel client / Business logic
**Severità:** Medium
**Componente interessato:** `lib/data/services/auth_service.dart:112-117`; policy `"update own profile"` (`20260908010000_rls_policies.sql:66-67`); `supabase/functions/purge-deleted-accounts/index.ts:42-46`

### Descrizione
È il client a scrivere `deletion_requested_at`, con l'ora del device
(`DateTime.now()`), e la policy `"update own profile"` permette all'utente di
scrivere qualunque valore in qualunque colonna del proprio profilo. L'Edge Function
cancella definitivamente gli account con `deletion_requested_at <= now() - 30 giorni`.

Chiunque abbia un access token valido può quindi impostare
`deletion_requested_at = '2000-01-01'`: l'account viene distrutto alla prossima
esecuzione del cron, entro 24 ore, saltando i 30 giorni.

Inoltre l'interfaccia `AuthService` (`auth_service.dart:49-52`) dice che un nuovo
login annulla la richiesta "automaticamente", ma non è implementato. L'annullamento
richiede di aprire la schermata Account e toccare un pulsante; il banner compare
solo lì e nessuna email avvisa l'utente.

### Impatto
Con una sessione rubata, i dati cloud dell'utente vengono distrutti in modo
irreversibile entro 24 ore, senza che possa intervenire. Anche un device con la
data sbagliata accorcia o allunga il grace period.

### Evidenza
- `auth_service.dart:116` — `update({'deletion_requested_at': DateTime.now().toIso8601String()})`
- `rls_policies.sql:66-67` — `update own profile using (id = auth.uid()) with check (id = auth.uid())`, senza restrizioni sulle colonne
- `index.ts:42-46` — `.lte('deletion_requested_at', cutoff)`

### Verifica
✅ **pgTAP su Postgres reale** (Appendice D, test 11-12): l'utente autenticato
imposta `deletion_requested_at = '2000-01-01'` sul proprio profilo e il valore
viene salvato. Non ho invocato l'Edge Function (cancellazione definitiva): ne
deriva dalla query `lte(cutoff)` 🔎. Nessuna scrittura sull'istanza hosted.

### Riproduzione
Solo in staging, con un account usa e getta:
1. `PATCH /rest/v1/profiles?id=eq.<uid>` con body `{"deletion_requested_at":"2000-01-01T00:00:00Z"}` → risposta 204.
2. Invocare la function di staging con l'header `x-cron-secret`: l'utente compare in `purged` con `ok: true`.

### Rischio
La garanzia "hai 30 giorni per ripensarci", comunicata all'utente, si può aggirare.
In combinazione con NIP-08, NIP-09 e NIP-13 porta alla catena di attacco A
(vedi sezione "Catene di vulnerabilità").

### Mitigazione consigliata
- Togliere al client la scrittura della colonna:
  `revoke update (deletion_requested_at) on profiles from authenticated`.
- Esporre RPC `security definer` `request_account_deletion()` (che imposta `now()`
  lato server) e `cancel_account_deletion()`; in alternativa un trigger che forzi
  `now()` per qualunque valore non nullo.
- Chiedere la riautenticazione (password o nonce) prima della richiesta.
- Inviare email di conferma e di promemoria.
- Implementare l'annullamento al login, oppure correggere la documentazione.
- Limitare la policy di update di `profiles` alle sole colonne davvero modificabili.

---

## [MEDIUM] NIP-06 — Cancellazione definitiva incompleta: gli scontrini sopravvivono alla cancellazione dell'account

**Categoria:** Esposizione di dati sensibili / Conformità (GDPR art. 17) / Error handling
**Severità:** Medium
**Componente interessato:** `supabase/functions/purge-deleted-accounts/index.ts:58-67`; soft-delete lato server

### Descrizione
- `admin.storage.from('attachments').list(userId)` senza opzioni restituisce al
  massimo **100 oggetti** (default di storage-js) e non è ricorsivo. Se l'utente ha
  più di 100 allegati, o file in sottocartelle (possibili, perché la policy Storage
  controlla solo il primo segmento del path), il resto non viene cancellato.
- Gli errori di `list` e `remove` vengono ignorati (`const { data: files } = ...`,
  e il risultato di `remove` non è controllato). La funzione procede con
  `deleteUser` e riporta `ok: true`. Dopo la cancellazione dell'utente non resta
  alcun riferimento per ritrovare quei file: diventano orfani permanenti.
- I dati soft-deleted (`deleted_at`) restano sul server per sempre: cancellare una
  spesa nell'app non la toglie dal cloud.
- Dal repo non si può verificare se la function sia stata deployata e schedulata
  (`ACCOUNT_SYNC_PLAN.md`, M-ACC7: "da fare manualmente"). Se non lo è, nessun
  account viene davvero cancellato, anche se all'utente viene mostrata una data di
  cancellazione.

### Impatto
Le foto degli scontrini (che possono contenere nome, carta parziale, indirizzo,
luogo) restano conservate dopo una richiesta di cancellazione. È una violazione del
diritto all'oblio e di quanto promesso all'utente.

### Evidenza
`index.ts:58-67` (`list(userId)` senza `limit`/`offset`, nessun controllo di
`error`), `index.ts:72-76`.

### Verifica
🔎 Analisi del codice; il limite di 100 è il default documentato di
`storage-js` `list()`. Non ho invocato la function perché avrebbe effetti reali.

### Riproduzione
In staging: utente di test con 101 oggetti in `attachments/<uid>/` (oppure uno
solo in `<uid>/sub/file.jpg`) e `deletion_requested_at` impostato a 31 giorni fa.
Invocare la function e poi contare, con la service role, gli oggetti rimasti con
prefisso `<uid>/`.

### Rischio
Esposizione legale (GDPR) e reputazionale; i dati restano sotto la responsabilità
del titolare senza una base giuridica.

### Mitigazione consigliata
- Paginare `list` (limit/offset fino a esaurimento) e scendere nelle sottocartelle,
  oppure enumerare `storage.objects` per prefisso.
- Controllare che il numero di oggetti residui sia 0 **prima** di `deleteUser`;
  in caso contrario segnare l'esito come fallito e ritentare.
- Loggare e mandare un alert sui fallimenti.
- Job periodico che elimini definitivamente i dati soft-deleted dopo N giorni.
- Test automatico della function.
- Verificare in dashboard che il cron esista ed esegua davvero.

---

## [MEDIUM] NIP-07 — Riferimenti cross-tenant non coperti dalla RLS (FK, UNIQUE globale, ID scelti dal client)

**Categoria:** Broken Access Control / BOLA (OWASP A01) — isolamento tra tenant
**Severità:** Medium
**Componente interessato:** `supabase/migrations/20260908010000_rls_policies.sql` (policy insert/update di `categories`, `transactions`, `budgets`, `recurring_rules`, `expense_report_entries`); `20260908000000_initial_schema.sql`

### Descrizione
Le policy controllano `wallet_id` e, in alcuni casi, `wallet_to_id`,
`reimburse_tx_id` e i due lati delle tabelle di join. Non controllano però le altre
FK, che possono puntare a righe di altri utenti:

| Colonna | Schema |
|---|---|
| `categories.parent_id` | `initial_schema.sql:92` |
| `transactions.category_id` | `:128` |
| `budgets.category_id` (+ `unique (category_id)` **globale**) | `:188-190` |
| `recurring_rules.category_id` | `:205` |
| `expense_report_entries.cost_center_id`, `report_id` | `:293, :296` |

In Postgres i controlli di integrità referenziale e di unicità **ignorano la RLS**
(documentazione di `CREATE POLICY`: *"Referential integrity checks… always bypass
row security"*). Di conseguenza un utente autenticato può:

1. collegare righe proprie a UUID di altri utenti. Non può leggerle (l'embedding
   PostgREST resta filtrato), ma crea dati incoerenti;
2. usare le risposte come **oracolo di esistenza**: un errore FK 23503 contro un
   successo, un 23505 su `budgets`, un 42501 sull'upsert con un id già esistente
   (il test pgTAP "Upsert con l'id di una riga di B" lo conferma) rivelano se un
   UUID esiste in qualunque tenant e se la vittima ha già un budget su una certa
   categoria;
3. fare un **DoS mirato**: se crea per primo un budget sulla categoria della
   vittima, la vittima non riuscirà mai a sincronizzare un budget su quella
   categoria (23505) e, per NIP-04, tutta la sua sync si blocca;
4. fare **ID squatting**: gli id sono generati dal client, quindi chi conosce gli
   UUID di righe non ancora sincronizzate di un altro utente può inserirle per
   primo. La sync della vittima fallirà per sempre (RLS `USING` sul ramo `DO UPDATE`).

**Precondizione**: conoscere UUID della vittima, che sono v4 e non indovinabili.
I possibili vettori sono i file di export JSON, che contengono gli ID originali e
sono pensati per essere condivisi nel team (UI rimossa ma codice presente,
`lib/data/export/json_codec.dart:56-130`), i futuri URL firmati con path
`{uid}/{attachment_id}` e i backup globali ripristinati su un altro account.
I test pgTAP attuali non coprono questi casi.

### Impatto
Viola l'invariante "ogni riferimento resta nel proprio tenant". Permette un DoS
persistente tra account e offre un canale laterale sull'esistenza dei dati. Non
consente di leggere dati altrui.

### Evidenza
Policy `"insert/update own categories|transactions|budgets|recurring_rules|expense_report_entries"`
(`rls_policies.sql:87-88, 102-103, 107-108, 140-145, 158-159`): controllano solo
`owns_wallet(wallet_id)` o `owns_transaction(transaction_id)`.

### Verifica
✅ **pgTAP su Postgres reale** (Appendice D, test 3-10 e 19-20), con due utenti
simulati A e B:
- A collega righe proprie a categoria, parent, centro di costo e nota spese di B:
  inserimenti accettati;
- oracolo di esistenza: un UUID inesistente dà `23503`, l'UUID di B dà successo;
  `23505` su `budgets` rivela che B ha già un budget su quella categoria;
- squatting del budget: A crea per primo il budget sulla categoria di B, e B
  riceve `23505` provando a creare o sincronizzare il budget sulla **propria**
  categoria;
- ID squatting: A inserisce una categoria con un UUID che B userà, e l'upsert di
  B su quell'id fallisce con `42501`.

### Riproduzione
Il file completo usato per la verifica è nell'Appendice D. Versione minima, da
aggiungere a `supabase/tests/rls_isolation_test.sql` nella sezione "Utente A",
poi eseguire `supabase start && supabase test db`. Oggi questi test **passano**,
quindi dimostrano il problema; dopo la correzione vanno invertiti in `throws_ok(..., '42501')`.

```sql
select lives_ok(
  $$ insert into transactions (wallet_id, type, amount_cents, date, category_id)
     values ('a0000000-0000-0000-0000-000000000001', 'expense', 1, now(),
             'b0000000-0000-0000-0000-000000000002') $$,
  'BUG: A collega una propria transazione alla categoria di B');

select lives_ok(
  $$ insert into categories (wallet_id, name, icon, color_hex, kind, parent_id)
     values ('a0000000-0000-0000-0000-000000000001', 'x', 'x', '#000000', 'expense',
             'b0000000-0000-0000-0000-000000000002') $$,
  'BUG: A usa la categoria di B come parent');

-- Oracolo: B ha già un budget su "Cat B" → 23505 (unique) invece di 42501 (RLS)
select throws_ok(
  $$ insert into budgets (wallet_id, category_id, limit_cents)
     values ('a0000000-0000-0000-0000-000000000001',
             'b0000000-0000-0000-0000-000000000002', 1) $$,
  '23505', null, 'BUG: il vincolo UNIQUE rivela che B ha un budget su quella categoria');
```

### Rischio
L'isolamento tra tenant è la promessa centrale dell'architettura e il team lo
considera completo ("difesa in profondità" su `wallet_to_id`/`reimburse_tx_id`).
Questa lacuna è facile da chiudere ora e costosa da sistemare a dati in produzione.

### Mitigazione consigliata
- Soluzione strutturale: FK **composite** che impongono lo stesso wallet. Ad
  esempio `unique (wallet_id, id)` su `categories` e
  `foreign key (wallet_id, category_id) references categories (wallet_id, id)` su
  transazioni, budget e ricorrenze; lo stesso schema per `parent_id`,
  `cost_center_id` e `report_id`. In questo modo è l'integrità referenziale stessa
  a impedire il cross-tenant.
- In aggiunta, o in alternativa: condizioni nelle policy, ad esempio
  `and (category_id is null or owns_category(category_id))`.
- Sostituire `unique (category_id)` con `unique (wallet_id, category_id)`,
  parziale su `deleted_at is null`.
- Estendere i test pgTAP a tutte le FK.

---

## [MEDIUM] NIP-08 — Cambio password senza riautenticazione, con logout forzato degli altri dispositivi

**Categoria:** Autenticazione / Gestione sessioni (OWASP A07)
**Severità:** Medium
**Componente interessato:** `auth_service.dart:93-96`; `account_screen.dart` (`_ChangePasswordDialog`); impostazione Auth "Secure password change"

### Descrizione
Il dialogo chiede solo la nuova password e la conferma. `updateUser(password)`
viene chiamato con la sola sessione, senza password attuale e senza nonce di
riautenticazione; subito dopo `signOut(scope: others)` revoca le sessioni degli
altri device.

Chi ha accesso alla sessione (telefono sbloccato, dato che non c'è un app-lock,
vedi NIP-13, oppure un token esfiltrato) può quindi cambiare la password e, con la
stessa azione, scollegare il proprietario da tutti i suoi altri dispositivi. Il
recupero via email non funziona (NIP-09).

### Impatto
Account takeover completo e duraturo a partire da un accesso di pochi secondi.
La misura pensata come difesa (il logout degli altri device) diventa uno strumento
dell'attaccante.

### Evidenza
`auth_service.dart:94-95`; `supabase/config.toml:227`
(`secure_password_change = false` nella configurazione locale).

### Verifica
🔎 Codice e configurazione locale. ⚠️ Il valore hosted di "Secure password change"
non si può leggere anonimamente (non è esposto da `/auth/v1/settings`): va
controllato in dashboard.

### Riproduzione
In staging, fare login con un utente di test e inviare
`PUT /auth/v1/user` con `Authorization: Bearer <access_token>` e body
`{"password":"NuovaPassword123!"}`: risposta 200 senza password attuale.

### Rischio
Chiunque prenda in mano il telefono per un momento può prendersi l'account.

### Mitigazione consigliata
- Chiedere la password attuale (verificandola con `signInWithPassword` prima
  dell'update), oppure abilitare "Secure password change" e usare
  `reauthenticate()` con nonce.
- Notificare via email ogni cambio password.
- App-lock locale per le azioni sensibili (cambio password, cancellazione account,
  logout con rimozione dei dati).

---

## [MEDIUM] NIP-09 — Recupero account e revoca delle sessioni incompleti

**Categoria:** Autenticazione / Gestione sessioni
**Severità:** Medium
**Componente interessato:** `auth_service.dart:89-90`; assenza di deep link (`ios/Runner/Info.plist`, `android/app/src/main/AndroidManifest.xml`); `main.dart` (flusso PKCE di default)

### Descrizione
- "Password dimenticata" chiama `resetPasswordForEmail(email)` senza `redirectTo`,
  e l'app non registra URL scheme né App Link e non gestisce il callback. Con il
  flusso PKCE (default di `supabase_flutter`) il code verifier resta nel secure
  storage del device che ha fatto la richiesta. Il link nell'email porta al Site URL
  del progetto (in locale `http://127.0.0.1:3000`, `config.toml:158`), quindi il
  reset non può essere completato. In `TEST_CHECKLIST.md:163` la voce "Reset
  password" non è spuntata.
- I refresh token di Supabase non scadono di default. `signOut()` (scope `local`)
  revoca solo la sessione corrente; non esiste "esci da tutti i dispositivi" né un
  elenco dei dispositivi (`ACCOUNT_SYNC_PLAN.md`, M-ACC4, voce aperta).

Messi insieme, con un device perso o rubato l'unico modo per revocarne la sessione
è "Cambia password" da un altro device già collegato. Chi non ne ha un altro non
può né resettare la password né revocare la sessione: il ladro conserva l'accesso
ai dati cloud a tempo indeterminato e, con NIP-05 e NIP-08, può prendersi l'account
o distruggerlo.

### Impatto
Account non recuperabili e sessioni rubate non revocabili.

### Evidenza
`auth_service.dart:89-90`; nessun `CFBundleURLTypes` né `intent-filter` con
scheme personalizzato; nessuna gestione di `AuthChangeEvent.passwordRecovery` in `lib/`.

### Verifica
🔎 Analisi del codice e dei manifest. Non ho inviato email di reset: avrebbe
consumato la quota (NIP-11) e mandato messaggi reali.

### Riproduzione
In staging: "Password dimenticata" con un utente di test, poi aprire il link
dell'email sul telefono. Non si torna nell'app e non c'è modo di impostare una
nuova password.

### Rischio
Utenti chiusi fuori dal proprio account e impossibilità di reagire a un furto.

### Mitigazione consigliata
- Deep link (es. `com.alum.nipay://auth-callback`) passato come `redirectTo` e
  aggiunto agli *Additional Redirect URLs* (lista esatta, senza wildcard).
- Gestire `AuthChangeEvent.passwordRecovery` con una schermata "Nuova password".
- Aggiungere "Esci da tutti i dispositivi" (`signOut(scope: SignOutScope.global)`).
- Valutare il timebox o il timeout di inattività delle sessioni.
- Revocare tutte le sessioni dopo un reset.

---

## [MEDIUM] NIP-10 — Politica password debole lato server; nessuna MFA, CAPTCHA o protezione da password compromesse

**Categoria:** Autenticazione (OWASP A07)
**Severità:** Medium
**Componente interessato:** configurazione Supabase Auth; `account_screen.dart:418, 539`

### Descrizione
Il minimo di 8 caratteri è controllato **solo** nel client. Il server, in base a
`config.toml:181` (`minimum_password_length = 6`, `password_requirements = ""`) e
alla voce ancora aperta in `ACCOUNT_SYNC_PLAN.md` ("Password policy minima
configurata"), accetta password di 6 caratteri senza requisiti, e chi usa l'API
direttamente aggira il controllo. Inoltre:

- nessun controllo contro le password già trapelate (leaked password protection);
- MFA disabilitata (`[auth.mfa.totp] enroll_enabled = false`);
- nessun CAPTCHA su signup, login e recover.

Il brute force e il credential stuffing sono limitati solo dal rate limit per IP,
che un attacco distribuito aggira.

### Impatto
Account compromessi tramite credential stuffing o password spraying, con lettura
di tutti i dati finanziari e possibile distruzione dell'account (NIP-05).

### Evidenza
`config.toml:181-184`, `[auth.mfa.totp]` (`:301-303`); validator client-side in `account_screen.dart:418, 539`.

### Verifica
🔎 Configurazione e codice. ⚠️ I valori hosted non si leggono anonimamente. Non ho
fatto tentativi di login.

### Riproduzione
In staging: `POST /auth/v1/signup` con una password `abc123` → accettata se la
policy è quella di default.

### Rischio
Per un'app che custodisce dati finanziari e scontrini, la sola password debole è
l'unica barriera.

### Mitigazione consigliata
- Dashboard Supabase: lunghezza minima di almeno 10-12 caratteri, requisiti di
  composizione, leaked password protection.
- CAPTCHA (hCaptcha o Turnstile) su signup, login e recover.
- MFA TOTP opzionale, e richiesta per le azioni distruttive.
- Allineare `config.toml` ai valori di produzione.

---

## [MEDIUM] NIP-11 — SMTP di default: blocco banale di registrazione e reset password, abuso dell'invio email

**Categoria:** Disponibilità / Configurazione
**Severità:** Medium
**Componente interessato:** Supabase Auth hosted (provider email integrato)

### Descrizione
La conferma email è obbligatoria (verificato: `mailer_autoconfirm: false`,
`disable_signup: false`). Con il provider email integrato di Supabase il limite di
invio è **globale per progetto** e molto basso: pochi messaggi l'ora (2 l'ora in
`config.toml:198`; `ACCOUNT_SYNC_PLAN.md:301-305` riporta blocchi
`over_email_send_rate_limit` già osservati nei test).

Un anonimo può esaurirlo con 2-3 richieste l'ora (`/auth/v1/recover` con email
qualsiasi, oppure signup). Da quel momento nessun nuovo utente riceve la mail di
conferma, e quindi non può usare l'account, e nessuno può resettare la password.
Gli stessi endpoint permettono di far inviare email dal progetto a indirizzi
arbitrari, con rischi di spam e di sospensione.

### Impatto
Blocco dell'onboarding e del recupero account per tutti gli utenti, sostenibile a
costo quasi nullo.

### Evidenza
Risposta di `GET /auth/v1/settings` (Appendice B); `ACCOUNT_SYNC_PLAN.md:301-305`.

### Verifica
✅ Parziale, in sola lettura: `mailer_autoconfirm: false`, signup abilitata, unico
provider `email`. Non ho inviato richieste di reset o signup perché avrebbero
mandato email reali e consumato la quota.

### Riproduzione
In staging con SMTP di default: inviare tre volte
`POST /auth/v1/recover {"email":"x@example.com"}` → `429 over_email_send_rate_limit`.
Un signup legittimo subito dopo non riceve l'email di conferma.

### Rischio
Il servizio diventa inutilizzabile per i nuovi utenti appena qualcuno lo vuole.

### Mitigazione consigliata
SMTP personalizzato (Resend, Postmark, SES) con limiti adeguati; CAPTCHA su signup
e recover; monitoraggio dei 429.

---

## [MEDIUM] NIP-12 — Nessuna quota per utente su Storage e Database: abuso di costi, hosting di contenuti, DoS dell'intero progetto

**Categoria:** Consumo illimitato di risorse (OWASP API4:2023) / Configurazione
**Severità:** Medium
**Componente interessato:** `supabase/migrations/20260908020000_storage_attachments.sql:12-13`; tutte le tabelle; signup aperta

### Descrizione
Il bucket `attachments` è creato senza `file_size_limit` e senza
`allowed_mime_types`. Qualunque utente registrato (la signup è aperta, basta
un'email) può:

- caricare nel proprio prefisso file di qualunque tipo (HTML, SVG, eseguibili) fino
  al limite globale (50 MiB in locale), in numero illimitato;
- generare URL firmati e distribuirli: il contenuto viene servito dal dominio del
  progetto `*.supabase.co`;
- inserire via PostgREST righe senza limite e testi di qualunque lunghezza
  (`description`, `note`, `value`, `name`).

Il client oggi **non usa** lo Storage (gli allegati non sono sincronizzati): la
superficie d'attacco esiste senza servire a nulla.

### Impatto
- Superamento delle quote del piano: sul piano Free il progetto va in sola lettura
  o viene sospeso, per tutti gli utenti.
- Costi imprevisti sui piani a consumo.
- Uso del progetto per ospitare phishing o malware, con rischio di sospensione da
  parte di Supabase.

### Evidenza
`storage_attachments.sql:12-13` (`insert into storage.buckets (id, name, public) values ('attachments','attachments', false)`); assenza di `CHECK (length(...))`.

### Verifica
✅ **pgTAP su Postgres reale** (Appendice D, test 1-2): il bucket `attachments`
creato dalle migration ha `file_size_limit` e `allowed_mime_types` a `null`
(test 18: descrizione da 1 MB accettata in una transazione). ✅ Lato anonimo
l'isolamento regge:
`GET /storage/v1/bucket` → `[]`, list del bucket → `[]`. Non ho fatto upload
perché richiedono un account.

### Riproduzione
In staging, con un utente di test: upload di `<uid>/test.html` con
`Content-Type: text/html` (50 MB), poi `createSignedUrl` e verifica della
dimensione accettata e del Content-Type servito.

### Rischio
Un solo utente malintenzionato può degradare o fermare il servizio per tutti.

### Mitigazione consigliata
- Limiti sul bucket:
  `update storage.buckets set file_size_limit = 10485760, allowed_mime_types = '{image/jpeg,image/png,image/heic,image/webp,application/pdf}' where id = 'attachments'`.
- Policy Storage che vincolino il nome a `{uid}/{uuid}.{ext}` e, quando gli
  allegati saranno sincronizzati, all'esistenza di una riga `attachments` dello
  stesso utente.
- Quote per utente (trigger che conti righe e byte per owner).
- Limiti di lunghezza sui testi.
- Tenere lo Storage spento finché non serve, e configurare alert di utilizzo.

---

## [MEDIUM] NIP-13 — Dati finanziari locali in chiaro e accessibili dopo il logout; dati mescolati tra account sullo stesso device

**Categoria:** Esposizione di dati sensibili (OWASP Mobile M9 — Insecure Data Storage) / Gestione sessioni
**Severità:** Medium
**Componente interessato:** `lib/features/account/account_screen.dart:237-364`; DB Drift non cifrato; `<documents>/attachments/`; `android/app/src/main/AndroidManifest.xml`; `sync_service.dart:110-125`

### Descrizione
- Dopo il logout, con la scelta di default, tutti i dati restano leggibili
  nell'app **senza alcuna autenticazione**: chi prende il telefono vede saldi,
  movimenti e scontrini. Non esiste un app-lock (biometria o PIN).
- Il DB SQLite e le foto sono salvati in chiaro (la cifratura M-ACC5 è
  rimandata). Su Android manca `android:allowBackup="false"`/`dataExtractionRules`,
  quindi l'auto-backup (attivo di default) copia DB e scontrini nei backup cloud o
  `adb backup`. Le build **debug**, che il `CLAUDE.md` indica di usare su
  Waydroid, sono `debuggable`: `adb shell run-as com.alum.nipay` dà accesso
  completo ai file senza root.
- **Dati mescolati tra account**: A fa logout tenendo i dati, poi B fa login sullo
  stesso device. La sync di B è bloccata ma l'app resta utilizzabile, quindi le
  spese che B inserisce finiscono nel dataset locale di A e, al successivo login di
  A, vengono caricate **nell'account di A** (fuga di dati da B verso A).
  Viceversa, B può "Rimuovere i dati" di A (`account_screen.dart:237-262`) senza
  alcuna autenticazione di A, distruggendo le modifiche non sincronizzate e tutti
  gli scontrini, che non vengono mai sincronizzati.
- Nessun `FLAG_SECURE` e nessun oscuramento nell'app switcher: l'anteprima mostra i dati.

### Impatto
Perdita di riservatezza con un device perso, condiviso o con backup accessibili;
dati di un account che finiscono in un altro; perdita di dati.

### Evidenza
- `account_screen.dart:295-364`: il default è `removeLocalData = false`
- `local_data_service.dart`: la rimozione è opzionale
- `AndroidManifest.xml:2-5`: nessun attributo di backup
- `ACCOUNT_SYNC_PLAN.md` M-ACC5: "rimandata"

### Verifica
- ✅ **APK release compilato in locale** (`flutter build apk --release`, poi
  `aapt dump xmltree`): nel manifest finale, dopo il merge dei plugin, non
  compaiono né `allowBackup` né `dataExtractionRules`. Valgono quindi i default:
  backup e trasferimento da device a device attivi.
- ✅ **Simulatore iOS** (build `dc9594a`, ispezione in sola lettura del
  container): `Documents/nipay.sqlite` inizia con `SQLite format 3` e si
  interroga con `sqlite3` senza alcuna chiave. Le descrizioni delle spese sono
  leggibili in chiaro (ho estratto solo i conteggi). Gli scontrini vengono
  salvati in `Documents/attachments/` come normali file JPEG.
- ✅ **Lato positivo**: nel container non c'è alcun `access_token` o
  `refresh_token` in chiaro, perché la sessione sta nel Keychain.
- 🔎 Il comportamento al logout e il mescolamento tra account derivano
  dall'analisi del codice: non li ho provati, perché servirebbe fare login e
  logout con account reali.

### Riproduzione
Su un device di test:
1. Login A, aggiungere una spesa, logout con l'opzione di default: l'app mostra ancora tutto.
2. Login B: compare il banner. Aggiungere comunque una spesa come B, poi logout B.
3. Login A e sync: la spesa di B compare nel cloud di A.

### Rischio
Un'app finanziaria in cui i dati sono accessibili a chiunque abbia in mano il
telefono, e in cui i dati di due persone si possono mescolare.

### Mitigazione consigliata
- App-lock biometrico/PIN (`local_auth`) all'avvio e al resume.
- Al logout, rimuovere i dati di default, oppure cifrarli con una chiave legata
  all'account.
- Completare M-ACC5 (SQLCipher o sqlite3mc) e cifrare gli allegati.
- `android:allowBackup="false"` o regole di esclusione per DB e allegati.
- Non distribuire mai build `debuggable` su device reali.
- Se ci sono dati di un altro account, bloccare **l'uso** dell'app (non solo la
  sync) finché non si sceglie cosa fare, e chiedere le credenziali di A prima di
  cancellarne i dati.
- `FLAG_SECURE` o oscuramento quando l'app va in background.

---

## [LOW] NIP-14 — Sync concorrenti non serializzate; race con logout, wipe e cambio account

**Categoria:** Race condition
**Severità:** Low
**Componente interessato:** `lib/app.dart:56-94`, `account_screen.dart:295-364`, `sync_service.dart:104-167`

### Descrizione
`syncNow` può partire in parallelo da quattro trigger (timer di 5 minuti, resume,
cambio di stato auth, pulsante manuale) senza alcun mutex. L'`userId` viene letto
all'inizio (`:105`), ma le richieste HTTP usano il JWT **corrente** del client
Supabase:

- se durante una sync l'utente fa logout e un altro utente fa login, il resto
  della sync gira con il token del nuovo utente e scrive nel DB locale i dati di B
  sotto il watermark di A;
- nel logout con rimozione dei dati (`account_screen.dart:358-361`), una sync in
  background ancora in corso può reinserire righe scaricate e la riga `SyncStates`
  di A **dopo** il `wipe()`. Il device "pulito" contiene ancora dati di A e il suo
  marchio di proprietà.

### Impatto
Dati residui dopo la rimozione, dati di account diversi mescolati, watermark che
tornano indietro. La finestra temporale è stretta.

### Evidenza
`app.dart:58-61, 73, 81, 93`; `sync_service.dart:105, 158-166`.

### Verifica
🔎 Analisi del codice.

### Riproduzione
In un test con `FakeSyncRemote`: rallentare `selectChangedSince` e lanciare
`syncNow()` in parallelo con `wipe()`, poi verificare che dopo il wipe esistano
righe o `SyncStates`.

### Rischio
Garanzie di privacy ("dati rimossi da questo dispositivo") non sempre rispettate.

### Mitigazione consigliata
- Un lock (es. package `synchronized`) attorno a `syncNow` e `wipe`.
- Interrompere la sync se `currentUser.id != userId`.
- Far sì che il wipe aspetti o annulli la sync in corso.
- Sospendere il timer durante il logout.

---

## [LOW] NIP-15 — Cancellazioni fisiche locali non propagate: dati che ricompaiono, anche nelle note spese

**Categoria:** Integrità
**Severità:** Low
**Componente interessato:** `lib/data/repositories/tag_repository.dart:60-65`; `expense_report_repository.dart:82-84`

### Descrizione
Rimuovere un tag da una spesa (`untagTransaction`) o togliere una spesa dalla nota
spese (`clearExpenseData`) fa un `DELETE` fisico locale. La sync non conosce le
cancellazioni fisiche: sul server e sugli altri device la riga resta, e un device
nuovo la riscarica. È anche contrario alla regola di progetto "niente
cancellazioni fisiche".

### Impatto
Una spesa tolta dalla nota spese su un device resta "da rimborsare" e compare nel
PDF generato da un altro device, con il rischio di chiedere un rimborso non
dovuto. I tag rimossi ricompaiono.

### Evidenza
`tag_repository.dart:61` (`_db.delete(_db.transactionTags)`), `expense_report_repository.dart:82`.

### Verifica
🔎 Analisi del codice.

### Riproduzione
Due device dello stesso utente. Su A togliere una spesa dalla nota spese e
sincronizzare. Su B sincronizzare: la spesa è ancora segnata come nota spese.

### Rischio
Documenti contabili inviati a terzi con dati sbagliati.

### Mitigazione consigliata
Soft-delete (`deleted_at` più `updated_at` assegnato dal server) anche per
`transaction_tags` ed `expense_report_entries`, oppure tombstone; test di sync
dedicati alle rimozioni.

---

## [LOW] NIP-16 — Export PDF della nota spese: metadati EXIF/GPS degli scontrini e file temporanei che restano

**Categoria:** Esposizione di dati sensibili
**Severità:** Low
**Componente interessato:** `add_transaction_sheet.dart:446-452`; `lib/data/export/expense_report_pdf.dart:154`; `expense_report_screen.dart:105-110`

### Descrizione
Le foto vengono salvate e poi inserite nel PDF così come sono; il PDF è pensato
per essere condiviso con datore di lavoro, commercialista e simili. `image_picker`,
quando ridimensiona (`maxWidth: 2000`), copia i metadati EXIF (su Android anche il
GPS) e `pw.MemoryImage` incorpora il JPEG originale. Posizione e dati del
dispositivo potrebbero quindi essere estratti dal PDF. Il PDF resta inoltre nella
directory temporanea.

### Impatto
La posizione (ad esempio di casa) e altri metadati arrivano a terzi.

### Evidenza
`add_transaction_sheet.dart:448-452`, `expense_report_pdf.dart:154`, `expense_report_screen.dart:106-110`.

### Verifica
✅ **Lato PDF verificato**. Ho preso una copia dell'icona dell'app, ci ho aggiunto
un segmento EXIF con GPS fittizio (45°27'12,34"N, 9°11'56,78"E) e l'ho passata alla
funzione reale `buildExpenseReportPdf` (test nella copia isolata). Nel PDF
generato l'immagine è incorporata **byte per byte** (stream `/DCTDecode` di
139.642 byte, identico all'originale): il segmento EXIF è intatto e ImageIO di
macOS, estraendo l'immagine dal PDF, legge `LatitudeRef = N`, `Longitude =
9.1991…`, `LongitudeRef = E`. Chi riceve il PDF può quindi leggere la posizione
con strumenti standard.
✅ **Verificato end-to-end anche lato app** (simulatore iOS 27 pulito, modalità
solo locale, nessun account). Ho aggiunto la stessa immagine geotaggata alla
libreria Foto, l'ho allegata a una spesa con il pulsante "Gallery" e ho salvato.
Il file `Documents/attachments/<uuid>.jpg` è stato ricodificato da
`image_picker` (154.980 byte, contro i 139.642 dell'originale) ma **conserva le
coordinate**: ImageIO legge `Latitude = 45.4534…`, `Longitude = 9.1991…`.
Il selettore di sistema di iOS mostra di default l'opzione "Posizione: sì", e
l'app non rimuove i metadati.
Quindi una foto scattata con la geolocalizzazione attiva porta la posizione sia
nel DB/allegati locali sia nel PDF condiviso. ⚠️ Su Android non verificato: il
plugin copia esplicitamente i tag EXIF durante il ridimensionamento.

### Riproduzione
Fotografare uno scontrino con la geolocalizzazione della fotocamera attiva, poi:
`exiftool <documents>/attachments/<uuid>.jpg`; esportare la nota spese e lanciare
`pdfimages -all nota.pdf out && exiftool out-*`.

### Rischio
Dati personali condivisi senza che l'utente lo sappia.

### Mitigazione consigliata
Ricodificare le immagini senza metadati prima di salvarle (package `image`),
cancellare il PDF temporaneo dopo la condivisione, informare l'utente.

---

## [LOW] NIP-17 — Messaggi d'errore del backend mostrati all'utente e dettagli dello schema esposti

**Categoria:** Divulgazione di informazioni negli errori (OWASP A05/A09)
**Severità:** Low
**Componente interessato:** `auth_service.dart:131-139`; `account_screen.dart` (`_showError`); `lib/app.dart:99`; PostgREST

### Descrizione
I messaggi grezzi di GoTrue e PostgREST vengono mostrati in UI, ad esempio
`new row violates row-level security policy for table "profiles"`.
L'errore "Email not confirmed", diverso da "Invalid login credentials", rivela
l'esistenza di account non confermati. `Text('$e')` mostra direttamente le
eccezioni del bootstrap. PostgREST risponde con suggerimenti sui nomi delle tabelle.

### Impatto
Enumerazione limitata degli account e dello schema; messaggi incomprensibili per l'utente.

### Evidenza
`auth_service.dart:135-137` (anche `PostgrestException` → `AuthException(e.message)`); `app.dart:99`.

### Verifica
✅ `GET /rest/v1/wallet` da anonimo →
`{"code":"PGRST205",…,"hint":"Perhaps you meant the table 'public.wallets'"}`. Il
resto è confermato dall'analisi del codice 🔎.

### Riproduzione
Lanciare `curl "$SUPABASE_URL/rest/v1/wallet?select=id" -H "apikey: $ANON"`.

### Rischio
Basso: lo schema non è un segreto, ma i dettagli aiutano chi attacca.

### Mitigazione consigliata
Tradurre i codici d'errore in messaggi l10n generici, non mostrare `$e`, loggare i
dettagli solo internamente.

---

## [LOW] NIP-18 — Codice di import/export dormiente: path traversal e ID estranei conservati

**Categoria:** Validazione input / Path traversal (OWASP A01/A03)
**Severità:** Low (codice oggi non raggiungibile dalla UI)
**Componente interessato:** `lib/data/export/json_codec.dart:56-130, 222-224, 304`; consumatori di `relativePath`: `transaction_detail_sheet.dart:90-91`, `expense_report_screen.dart:89`

### Descrizione
La UI di backup e ripristino è stata rimossa (commit `4e95828`), ma il codec è
ancora nel codice e coperto da test. Se venisse riattivato:

- `Attachment.fromJson` prende `relativePath` dal file, e l'app lo apre con
  `File('${appDir.path}/${a.relativePath}')`. Un export (pensato per essere
  scambiato tra membri del team) con `relativePath: "../Library/…"` farebbe
  leggere all'app file arbitrari della sandbox e li inserirebbe nel PDF della nota
  spese, cioè li farebbe uscire tramite la condivisione. Il vecchio importer zip
  (`backup_actions.dart`, nella history) estraeva le entry `attachments/...` usando
  il nome dell'entry.
- `importFromJson` (restore globale) reinserisce gli **ID originali**. Se il
  backup appartiene a un altro utente, la sync va in conflitto permanente con le
  sue righe (NIP-07, ID squatting). Gli export espongono comunque gli UUID di chi
  li crea.

### Impatto
Lettura di file interni dell'app tramite un file malevolo; blocco della sync tra
account.

### Evidenza
`json_codec.dart:222-224, 304`; `git show 4e95828^:lib/features/settings/backup_actions.dart` (righe 101-115).

### Verifica
🔎 Analisi del codice; il codice non è raggiungibile dalla UI attuale.

### Riproduzione
In un test: costruire un JSON di export con `attachments[0].relativePath = "../shared_prefs/FlutterSharedPreferences.xml"`,
importarlo con `importWalletFromJson` e chiamare l'export PDF: il file viene letto.

### Rischio
Una vulnerabilità latente che tornerebbe attiva alla riattivazione della funzione.

### Mitigazione consigliata
Prima di riattivare:
- rigenerare sempre `relativePath` (`attachments/<uuid>.<ext>`, con whitelist delle
  estensioni) e controllare che il path risolto resti sotto `attachments/`;
- rifiutare le entry zip con `..` o con path assoluti, e limitare dimensioni e
  numero di file (zip bomb);
- rimappare gli ID anche nel restore globale, oppure bloccarlo se è collegato un
  altro account;
- validare lo schema del JSON;
- non includere ID interni negli export condivisibili.

---

## [LOW] NIP-19 — Edge Function di purge: hardening

**Categoria:** Gestione dei segreti / Configurazione
**Severità:** Low
**Componente interessato:** `supabase/functions/purge-deleted-accounts/index.ts`

### Descrizione
- Il deploy avviene con `--no-verify-jwt` e la protezione è affidata solo a un
  segreto condiviso.
- Il confronto `!==` (`:31`) non è a tempo costante (rischio solo teorico).
- Le istruzioni prevedono di scrivere il segreto in chiaro dentro
  `cron.schedule(...)`, quindi viene salvato in `cron.job` e finisce nei backup e
  nelle viste accessibili a chi ha accesso al DB.
- La risposta contiene messaggi d'errore interni.
- Non c'è audit log.
- Non c'è un limite al numero di cancellazioni per esecuzione: un bug o un abuso
  in massa di NIP-05 produrrebbero cancellazioni in blocco senza alcun freno.

### Impatto
Superficie ridotta, ma la function ha i privilegi massimi (service role) e il
compito più distruttivo dell'intero sistema.

### Evidenza
`index.ts:6-24, 31, 49, 82`.

### Verifica
🔎 Analisi del codice. La function non è stata invocata.

### Riproduzione
Non serve: è evidente dal codice. In staging, chiamare la function senza header
deve restituire 401.

### Rischio
Una compromissione o un errore qui distrugge dati di tutti gli utenti.

### Mitigazione consigliata
- Segreto in Supabase Vault, letto nel job con `vault.decrypted_secrets`.
- Confronto a tempo costante.
- Tabella di audit.
- Soglia di sicurezza (oltre N cancellazioni per run: stop e alert).
- Modalità dry-run.
- Test automatico.

---

## [LOW] NIP-20 — Pipeline di build e supply chain

**Categoria:** Supply chain / Configurazione (OWASP A08)
**Severità:** Low
**Componente interessato:** `.github/workflows/*.yml`; `android/app/build.gradle.kts:44-51`; `android/app/src/main/AndroidManifest.xml`

### Descrizione
- Le action di terze parti sono referenziate con tag mutabili
  (`subosito/flutter-action@v2`, `supabase/setup-cli@v1`, `actions/*@v4`) invece
  che con lo SHA: se un tag viene compromesso, esegue codice nella CI.
- Nei workflow manca un blocco `permissions:` minimo.
- La build release passa silenziosamente alla chiave **debug** se manca
  `key.properties`: si producono APK "release" non aggiornabili e non attribuibili.
- Il manifest `main` non dichiara `android.permission.INTERNET` (presente solo nei
  manifest debug e profile), e nessun plugin la aggiunge nel merge: **la release
  non può accedere alla rete**. Sync, tassi di cambio e Google Fonts non
  funzionano, e questo spinge a distribuire build debug, che sono debuggable
  (NIP-13).

### Impatto
Rischio di supply chain nella CI; distribuzione di build non sicure.

### Evidenza
`ci.yml`, `ios.yml`, `supabase.yml`; `build.gradle.kts:44-51`; `AndroidManifest.xml` (main).

### Verifica
✅ **APK release compilato in locale** (`flutter build apk --release
--target-platform android-arm64`, 25,4 MB):
- `aapt dump permissions` → l'unico permesso è
  `com.alum.nipay.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION`: **manca `INTERNET`**;
- `apksigner verify --print-certs` → `CN=Android Debug`: senza `key.properties`
  la build "release" viene firmata con la chiave debug senza alcun avviso;
- l'APK release non è `debuggable` (corretto).
Le action non pinnate e i permessi dei workflow sono confermati dall'analisi
dei file 🔎.

### Riproduzione
`flutter build apk --release && aapt dump permissions build/app/outputs/flutter-apk/app-release.apk`.

### Rischio
Basso, ma cresce con l'apertura del repo o del team.

### Mitigazione consigliata
- Pin delle action per SHA e Dependabot.
- `permissions: contents: read` nei workflow.
- Far fallire la build release se manca il keystore.
- Dichiarare INTERNET nel manifest `main` e verificarlo.

---

## [INFORMATIONAL] NIP-21 — Hardening di Supabase/Postgres

**Categoria:** Configurazione / Defense in depth
**Severità:** Informational
**Componente interessato:** `supabase/migrations/*.sql`, impostazioni del progetto

### Descrizione
- Le policy sono create senza `TO authenticated` e si applicano anche ad `anon`
  (oggi senza conseguenze, perché `auth.uid()` è null).
- Le funzioni `owns_*` sono chiamabili come RPC: ✅
  `POST /rest/v1/rpc/owns_wallet` da anonimo → `false`; ✅ pgTAP
  `has_function_privilege('anon', 'public.owns_wallet(uuid)', 'execute')` → true. Oggi non rivelano nulla,
  perché sono `SECURITY INVOKER`, ma qualunque futura funzione nello schema
  `public` sarà pubblica per default.
- Performance della RLS: `auth.uid()` e le funzioni `owns_*` vengono valutate per
  ogni riga. Con tabelle grandi le query rallentano (possibile DoS indiretto sulla
  sync).
- `set_updated_at()` non ha `set search_path` (lint Supabase `function_search_path_mutable`).
- Realtime è abilitato ma non usato.
- Controlli con esito positivo ✅: OpenAPI non accessibile con la publishable key
  ("Secret API key required"), `pg_graphql` disabilitato, nessuna riga o bucket
  visibile da anonimo, funzioni trigger non esposte (`rpc/set_updated_at` → PGRST202).

### Impatto
Nessun impatto diretto oggi; si riduce il margine d'errore per il futuro.

### Evidenza
`rls_policies.sql` (tutte le policy), `initial_schema.sql:23-31`.

### Verifica
✅ Le richieste anonime sono elencate nell'Appendice B.

### Riproduzione
Vedi Appendice B.

### Rischio
Basso.

### Mitigazione consigliata
- Aggiungere `TO authenticated` a tutte le policy.
- Spostare gli helper in uno schema non esposto (`private`) oppure
  `revoke execute on function ... from anon, authenticated` (restano usabili dalle
  policy se sono `security definer` con owner adeguato).
- Usare `(select auth.uid())` e la forma
  `wallet_id in (select id from wallets where owner_user_id = (select auth.uid()))`.
- `set search_path = ''` sui trigger.
- Disabilitare Realtime, o accettare solo canali privati.
- Lanciare periodicamente il Security Advisor di Supabase.

---

## [INFORMATIONAL] NIP-22 — Configurazione locale (CI) diversa dal progetto hosted e non versionata

**Categoria:** Configurazione
**Severità:** Informational
**Componente interessato:** `supabase/config.toml`, impostazioni Auth hosted

### Descrizione
`config.toml`, che è la configurazione usata dai test pgTAP in CI, ha
`enable_confirmations = false`, `minimum_password_length = 6`,
`secure_password_change = false` e `site_url` su localhost. Il progetto hosted ha
invece `mailer_autoconfirm = false` (verificato). La configurazione Auth di
produzione non è versionata né riproducibile.

### Impatto
I test girano su un ambiente diverso da quello reale; le modifiche fatte in
dashboard non sono tracciate né soggette a review.

### Evidenza
`config.toml:158, 181, 225, 227`; Appendice B.

### Verifica
✅ Confronto tra `config.toml` e `/auth/v1/settings`.

### Riproduzione
Vedi Appendice B.

### Rischio
Regressioni di configurazione non intercettate.

### Mitigazione consigliata
Allineare `config.toml` ai valori di produzione, gestire la configurazione con
`supabase config push` (o un approccio IaC) e una checklist di release.

---

## [INFORMATIONAL] NIP-23 — Servizi esterni chiamati a runtime e fiducia nei loro dati

**Categoria:** Privacy / Integrità dei dati esterni
**Severità:** Informational
**Componente interessato:** `lib/core/theme/app_theme.dart` (google_fonts); `lib/data/services/exchange_rate_service.dart`

### Descrizione
- `google_fonts` scarica i font da Google a runtime: IP e user agent dell'utente
  arrivano a Google. Questo è incoerente con l'idea di privacy label "nessun dato
  raccolto" (memoria di progetto sulla pubblicazione negli store) e ci sono
  precedenti GDPR nell'UE.
- I tassi di Frankfurter vengono usati senza controlli di plausibilità: un tasso a
  0 o enorme, oppure un servizio compromesso, altererebbe in modo permanente gli
  importi salvati. La cache in SharedPreferences non è firmata.

### Impatto
Dati personali verso terze parti non dichiarate; possibile alterazione degli importi.

### Evidenza
`app_theme.dart:103-173`; `exchange_rate_service.dart:85-117`.

### Verifica
🔎 Analisi del codice.

### Riproduzione
Un proxy (mitmproxy) su un device di test mostra le richieste a `fonts.gstatic.com`
e `api.frankfurter.dev`.

### Rischio
Basso.

### Mitigazione consigliata
- Includere i font tra gli asset e impostare `GoogleFonts.config.allowRuntimeFetching = false`.
- Intervalli di plausibilità sui tassi e conferma dell'utente quando la
  variazione è anomala.
- Dichiarare i servizi terzi nella privacy policy.

---

## [INFORMATIONAL] NIP-24 — Validazione minima degli input lato client

**Categoria:** Validazione input
**Severità:** Informational
**Componente interessato:** `add_transaction_sheet.dart:401-409`; `account_screen.dart:408, 471`

### Descrizione
- L'estensione dell'allegato si ricava dal path (`img.path.split('.').last`) senza
  whitelist. Se il nome del file non contiene un punto, il path relativo contiene
  `/` (es. `attachments/<uuid>.nipay/cache/...`) e la copia fallisce a metà del
  salvataggio. Il mimeType di fallback `image/$ext` non viene validato.
- L'email viene validata solo con `contains('@')`; descrizioni e note non hanno
  limiti di lunghezza (vedi anche NIP-04 e NIP-12).

### Impatto
Salvataggi a metà (transazione salvata, allegato perso); dati poco puliti.

### Evidenza
Righe indicate sopra.

### Verifica
🔎 Analisi del codice.

### Riproduzione
Selezionare dalla galleria un file senza estensione (dipende dal provider).

### Rischio
Basso.

### Mitigazione consigliata
Ricavare tipo ed estensione dai magic bytes con una whitelist, generare i path
solo nell'app, mettere limiti di lunghezza nei form.

---

## [INFORMATIONAL] NIP-25 — Note di sicurezza per la futura sync degli allegati (M-ACC3/M-ACC6)

**Categoria:** Secure design
**Severità:** Informational
**Componente interessato:** `attachments.storage_path`; policy Storage; futuro codice di upload e download

### Descrizione
La sync degli allegati non è ancora implementata. Prima di farlo:

- `storage_path` è testo libero e non è validato rispetto all'owner: oggi un
  utente può scrivere il path di un altro utente, senza effetti grazie alle policy
  Storage, ma con il rischio di bug futuri;
- serve una politica per la durata degli URL firmati;
- serve un ciclo di vita dei file: cancellare il file quando l'allegato o la
  transazione vengono soft-deleted, e al purge (NIP-06);
- i path locali non devono derivare da dati del server senza normalizzazione
  (stesso rischio di NIP-18).

### Impatto
Prevenzione.

### Evidenza
`initial_schema.sql:230`; `storage_attachments.sql`.

### Verifica
🔎 Analisi del codice.

### Riproduzione
Non applicabile.

### Rischio
Basso oggi, più alto quando la funzione verrà attivata.

### Mitigazione consigliata
- `CHECK (storage_path is null or storage_path = <owner> || '/' || id::text)`,
  tramite trigger che ricava l'owner.
- URL firmati di durata non superiore a 60 secondi, mai salvati né loggati.
- Download in una cache locale cifrata.
- Job di pulizia degli oggetti orfani.

---

## Catene di vulnerabilità

Rilievi poco gravi presi da soli, che combinati producono un impatto maggiore.

**A — "Telefono sbloccato per due minuti" → account perso e dati distrutti**
NIP-13 (nessun app-lock) → NIP-08 (cambio password senza la password attuale,
con logout di tutti gli altri device della vittima) → NIP-09 (la vittima non può
resettare la password né revocare la sessione) → NIP-05 (`deletion_requested_at`
retrodatato) → entro 24 ore l'account e tutti i dati cloud vengono cancellati in
modo irreversibile, mentre gli scontrini oltre il centesimo restano comunque orfani
(NIP-06). **Impatto complessivo: High.**

**B — "Blocco silenzioso e persistente della sync"**
Token rubato, device con l'orologio sbagliato o client malevolo → NIP-02
(`created_at` 2099) oppure NIP-04 (riga malformata) → tutti i device dell'utente
smettono di sincronizzare; gli errori vengono ignorati (`catchError`), quindi
nessuno se ne accorge, e il problema resta anche dopo il cambio password.

**C — "Export condiviso nel team"**
File di export con gli UUID originali (NIP-18) → NIP-07 (budget con `UNIQUE`
globale, ID squatting) → la sync della vittima si blocca per sempre (NIP-04) e lei
non lo sa.

**D — "Onboarding e recupero bloccati"**
NIP-11 (SMTP di default) + NIP-10 (nessun CAPTCHA) → con poche richieste l'ora
nessuno può confermare l'email o resettare la password; il reset è già rotto per
conto suo (NIP-09).

**E — "Device condiviso"**
NIP-13 (logout che conserva i dati, uso non bloccato) + NIP-14 (race con il wipe)
→ dati di B caricati nel cloud di A, oppure dati di A rimasti sul device dopo una
rimozione "completata".

---

## 1. Riepilogo delle vulnerabilità ordinate per severità

| ID | Severità | Titolo | Verifica |
|---|---|---|---|
| NIP-01 | **High** | Watermark di pull unico e inaffidabile: perdita silenziosa di modifiche | ✅ PoC 2 (+🔎 max_rows) |
| NIP-02 | Medium | Timestamp del client nel watermark: avvelenamento della sync | ✅ PoC 1 + pgTAP |
| NIP-03 | Medium | Nessuna gestione dei conflitti, eco del push | ✅ PoC 3 |
| NIP-04 | Medium | Riga "avvelenata" blocca la sync; nessun CHECK; errori ignorati | ✅ pgTAP (DB) + 🔎 (client) |
| NIP-05 | Medium | Grace period della cancellazione controllato dal client | ✅ pgTAP (+🔎 purge) |
| NIP-06 | Medium | Purge incompleto: scontrini orfani dopo la cancellazione | 🔎 |
| NIP-07 | Medium | Riferimenti cross-tenant non coperti dalla RLS | ✅ pgTAP (10 test) |
| NIP-08 | Medium | Cambio password senza riautenticazione | 🔎 / ⚠️ |
| NIP-09 | Medium | Reset password non completabile, sessioni non revocabili | 🔎 |
| NIP-10 | Medium | Password policy debole, nessuna MFA/CAPTCHA | 🔎 / ⚠️ |
| NIP-11 | Medium | SMTP di default: DoS di signup e reset | ✅ parziale |
| NIP-12 | Medium | Nessuna quota su Storage e DB | ✅ pgTAP + isolamento anon |
| NIP-13 | Medium | Dati locali in chiaro dopo il logout, dati mescolati tra account | ✅ DB in chiaro, backup attivo + 🔎 logout |
| NIP-14 | Low | Sync concorrenti e race con logout/wipe | 🔎 |
| NIP-15 | Low | Cancellazioni fisiche non propagate | 🔎 |
| NIP-16 | Low | EXIF/GPS nel PDF, file temporanei | ✅ iOS end-to-end (app + PDF) |
| NIP-17 | Low | Errori del backend mostrati e hint sullo schema | ✅ |
| NIP-18 | Low | Import/export dormiente: path traversal, ID estranei | 🔎 |
| NIP-19 | Low | Hardening dell'Edge Function di purge | 🔎 |
| NIP-20 | Low | CI e supply chain, firma di fallback, permesso INTERNET | ✅ APK + 🔎 CI |
| NIP-21 | Info | Hardening Supabase/Postgres | ✅ |
| NIP-22 | Info | Configurazione locale diversa dall'hosted | ✅ |
| NIP-23 | Info | Servizi esterni a runtime (font, tassi) | 🔎 |
| NIP-24 | Info | Validazione input client minima | 🔎 |
| NIP-25 | Info | Note per la futura sync degli allegati | 🔎 |

## 2. Vulnerabilità più urgenti da correggere

1. **NIP-01, NIP-02, NIP-03, NIP-04 — motore di sync.** Durante la beta stanno già
   facendo divergere i dati, in modo silenzioso. Correggerli prima della beta
   M-ACC9 con i 4 membri del team: watermark per tabella, pull paginato e
   ordinato, timestamp solo dal server (trigger `BEFORE INSERT OR UPDATE`),
   concorrenza ottimistica, parsing difensivo e stato della sync visibile.
2. **NIP-05 + NIP-08 (+ NIP-09) — catena A.** Pochi interventi la chiudono:
   colonna `deletion_requested_at` assegnata dal server tramite RPC, password
   attuale richiesta per cambiarla, deep link per il reset.
3. **NIP-07 — RLS sulle FK cross-tenant.** Si corregge con una migration (FK
   composite e unique per wallet) più qualche test pgTAP. Molto meglio farlo prima
   che ci siano dati di utenti reali.
4. **NIP-12 — limiti del bucket.** Una sola istruzione SQL elimina la superficie
   di abuso più economica.
5. **NIP-11 + NIP-10 — SMTP custom, CAPTCHA e password policy.** Sono
   prerequisiti per aprire la registrazione all'esterno del team.
6. **NIP-06 — purge completo e verificato.** Prerequisito GDPR per il rilascio
   pubblico.

## 3. Aree che non ho potuto verificare

- **Configurazione Auth hosted non pubblica**: lunghezza minima della password,
  "Secure password change", Site URL e redirect URL, durata del JWT, rotazione
  dei refresh token, timebox delle sessioni, rate limit effettivi, SMTP
  configurato. Vanno controllati in dashboard.
- **Max rows di PostgREST** sul progetto hosted (presunto 1000, il default).
- **Deploy e schedulazione dell'Edge Function** `purge-deleted-accounts`
  (presenza del cron, impostazione del `CRON_SECRET`).
- **Policy RLS realmente applicate sull'istanza**: non si possono leggere con la
  publishable key. Le verifiche pgTAP sono state fatte sulle migration del repo
  applicate in locale; ho assunto che l'hosted coincida (le verifiche anonime
  sono coerenti con questa ipotesi). La query su `pg_policies` della sezione 6
  permette di confermarlo.
- **Flussi HTTP autenticati** (cambio password via GoTrue, Edge Function di
  cancellazione definitiva con più di 100 file, upload su Storage e Content-Type
  servito, rate limit delle email, link di reset): non eseguiti. Le verifiche a
  livello di database sono state fatte in locale con pgTAP (Appendice D).
- **Build mobili**: ho verificato l'APK release e la build su simulatore iOS. Restano
  da verificare su device fisico la classe di Data Protection iOS (il
  simulatore non la applica), il comportamento EXIF su Android e il contenuto
  effettivo dei backup del device.
- **Dipendenze**: non ho fatto uno scan CVE completo di `pubspec.lock` (ho solo
  controllato le versioni dei pacchetti di auth, storage, secure storage, archive
  e pdf, nessuno con problemi noti rilevanti per l'uso fatto qui).

## 4. Assunzioni fatte durante l'audit

- Il progetto `tyjugoiohkktlyizfpfx` è un ambiente di **test** (lo dice il nome) ed
  è quello usato dall'app (`lib/core/supabase_config.dart`).
- Le migration in `supabase/migrations/` sono quelle applicate, senza modifiche
  manuali in dashboard.
- Valori di default di Supabase per tutto ciò che non è documentato nel repo:
  max rows 1000, refresh token senza scadenza, SMTP integrato con rate limit
  globale.
- Modello di minaccia: utenti registrati malevoli (la signup è aperta), possesso
  temporaneo di un device sbloccato o di un token, device condivisi, clock dei
  device non affidabili. Non ho considerato un attaccante con accesso
  all'infrastruttura Supabase o al repository GitHub.
- La publishable key nel client non è un segreto, come previsto dal design di
  Supabase; non l'ho considerata una vulnerabilità.

## 5. Valutazione complessiva

**Riservatezza tra tenant: buona.** Il modello di ownership è chiaro e
centralizzato (`owns_*`), la RLS è attiva ovunque e c'è un test automatico che lo
verifica, i controlli sui riferimenti incrociati principali sono presenti, la
sessione è salvata nel secure storage, non c'è `service_role` nel client, OpenAPI
e GraphQL non sono esposti. Il team ha lavorato con attenzione (test pgTAP in CI,
verifica della `service_role` nel binario, default-deny fin dalla prima migration).

**Integrità e disponibilità: insufficienti per un'app finanziaria.** Il motore di
sync perde modifiche in condizioni d'uso normali (dimostrato), si fida di
timestamp del client, non gestisce i conflitti e può bloccarsi in modo permanente
senza avvisare nessuno. La RLS protegge la lettura ma non tutta l'integrità
referenziale.

**Ciclo di vita dell'account: fragile.** Le singole debolezze di reset, cambio
password, revoca delle sessioni e cancellazione formano una catena che, da un
accesso momentaneo, arriva alla distruzione irreversibile dell'account.

**Giudizio**: adeguata per la beta interna, **non ancora pronta** per utenti
esterni né per la pubblicazione negli store. Con le correzioni prioritarie
(sezione 2), quasi tutte limitate e ben circoscritte, il livello diventerebbe
buono.

## 6. Test consigliati da eseguire in staging

Da eseguire su un progetto Supabase separato dalla produzione, con account usa e getta.

1. **pgTAP cross-tenant** (NIP-07): aggiungere i test dell'appendice di NIP-07
   per tutte le FK (`category_id`, `parent_id`, `cost_center_id`, `report_id`) e
   per gli unique; dopo il fix devono fallire con 42501.
2. **pgTAP profiles** (NIP-05): `authenticated` non deve poter scrivere
   `deletion_requested_at` direttamente; la RPC deve impostare `now()`.
3. **Sync a carico** (NIP-01): 5.000 transazioni, primo login da un device nuovo,
   confronto dei conteggi per tabella con il server.
4. **Sync concorrente** (NIP-01, NIP-03, NIP-14): due emulatori che modificano gli
   stessi record mentre sono offline, poi sync in ordine invertito; sync
   automatica durante logout con rimozione dei dati.
5. **Clock skew** (NIP-02): device con data +1 giorno e −1 giorno; verificare che
   `last_pulled_at` non superi mai l'ora del server.
6. **Dati malformati** (NIP-04): PATCH con valori fuori dominio (`options` non
   array, `currency` non ISO, `color_hex` errato, importo negativo); l'app deve
   isolarli senza bloccare la sync.
7. **Edge Function di purge** (NIP-06, NIP-19): utente con 250 file e sottocartelle;
   dopo il purge 0 oggetti residui; chiamata senza o con header sbagliato → 401;
   soglia massima di cancellazioni.
8. **Flussi Auth** (NIP-08, NIP-09, NIP-10, NIP-11): reset password end-to-end via
   deep link; cambio password che richiede quella attuale; signup con password
   debole rifiutata; CAPTCHA; rate limit di `/recover` con SMTP custom.
9. **Storage** (NIP-12): upload oltre il limite di dimensione e con MIME non
   ammesso → rifiutato; path non conforme a `{uid}/{uuid}.{ext}` → rifiutato.
10. **Mobile** (NIP-13, NIP-16, NIP-20): `adb backup` o auto-backup sulla release
    (DB escluso), `run-as` impossibile sulla release, app-lock, EXIF assente
    nelle immagini salvate e nel PDF, `aapt dump permissions` sulla release.
11. **Supabase Security Advisor e Performance Advisor** dopo ogni migration, con
    l'esito allegato alla PR.
12. **Policy hosted contro migration**: lanciare nel SQL Editor dell'hosted
    `select schemaname, tablename, policyname, cmd, roles, qual, with_check from pg_policies where schemaname in ('public','storage') order by 1,2,3;`
    e confrontare il risultato con lo stesso comando sul DB locale.
13. **Verifiche dell'audit come regressione**: aggiungere a `supabase/tests/` il
    file dell'Appendice D, invertendo ogni asserzione "VULN" man mano che il
    relativo difetto viene corretto.

---

## Appendice A — PoC del motore di sync (eseguite)

Le PoC sono state eseguite su una **copia del repository nello scratchpad** (il
repository originale non è stato toccato), con DB Drift in memoria e un server
simulato che si comporta come Postgres e PostgREST:

- `updated_at` viene assegnato dal server a ogni INSERT e UPDATE, **tranne**
  quando il client invia esplicitamente la colonna su una riga nuova (i trigger
  sono solo `BEFORE UPDATE`);
- `transaction_tags.created_at` è sempre quello inviato dal client.

Comando: `flutter test test/poc/sync_watermark_poc_test.dart`. Output rilevante:

```
00:00 +0: PoC 1: created_at del client avvelena il watermark di pull
lastPulledAt di B dopo la prima sync: 2026-10-06 10:00:00.000Z (orologio server: 2026-10-05 10:00:03.000Z)
importo su server: 99900 — importo su B dopo la sync: 1000
00:00 +1: PoC 2: watermark unico + pull sequenziale perde modifiche concorrenti
wallet su server: Conto RINOMINATO — su B: Conto
00:00 +2: PoC 3: nessun controllo di conflitto — una modifica offline più vecchia sovrascrive quella più recente di un altro device
valore finale server: 1500 — su B: 1500 (ultima modifica in ordine di tempo: 2000)
00:00 +3: All tests passed!
```

Ogni test passa proprio perché **asserisce il comportamento difettoso**. Dopo le
correzioni le asserzioni vanno invertite e il file può diventare un test di
regressione in `test/data/`.

Sorgente completo della PoC (per riprodurla, copiarla in `test/poc/` di una copia del repo):

<details>
<summary>test/poc/sync_watermark_poc_test.dart</summary>

```dart
// PoC NON distruttiva (copia isolata del repo, DB in memoria, nessuna rete).
// Dimostra due difetti del watermark di pull in SupabaseSyncService:
//  1. un timestamp scelto dal client (transaction_tags.created_at) entra nel
//     watermark "lato server" -> un device con orologio avanti (o un client
//     malevolo) fa saltare tutte le modifiche successive agli altri device;
//  2. un unico watermark (max su tutte le tabelle) + pull sequenziale ->
//     una modifica concorrente a una tabella già scaricata viene persa.
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nipay/data/db/app_database.dart';
import 'package:nipay/data/db/tables.dart';
import 'package:nipay/data/services/sync_service.dart';

/// "Server" che imita Postgres+PostgREST: updated_at assegnato dal server
/// (orologio reale simulato) su INSERT/UPDATE, TRANNE dove il client manda
/// esplicitamente la colonna watermark su una riga nuova (il trigger
/// set_updated_at è solo BEFORE UPDATE) e per transaction_tags.created_at,
/// che il client invia sempre e PostgREST scrive anche nel DO UPDATE.
class RealisticRemote implements SyncRemote {
  RealisticRemote(this.serverNow);
  DateTime serverNow;
  final Map<String, Map<String, Map<String, dynamic>>> tables = {};
  void Function(String table)? onSelect;

  static const _pk = {
    'transaction_tags': ['transaction_id', 'tag_id'],
    'custom_field_values': ['transaction_id', 'field_id'],
    'expense_report_entries': ['transaction_id'],
  };
  String _key(String t, Map<String, dynamic> r) =>
      (_pk[t] ?? ['id']).map((c) => r[c]).join('|');

  DateTime tick() => serverNow = serverNow.add(const Duration(seconds: 1));

  @override
  Future<void> upsert(String table, List<Map<String, dynamic>> rows) async {
    final store = tables.putIfAbsent(table, () => {});
    for (final row in rows) {
      final k = _key(table, row);
      final exists = store.containsKey(k);
      final stamped = {...row};
      if (table != 'transaction_tags') {
        final clientSent = row.containsKey('updated_at');
        if (exists || !clientSent) {
          stamped['updated_at'] = tick().toIso8601String();
        }
      }
      store[k] = stamped;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> selectChangedSince(
    String table,
    DateTime since, {
    String column = 'updated_at',
  }) async {
    onSelect?.call(table);
    return (tables[table] ?? {}).values
        .where((r) => DateTime.parse(r[column] as String).isAfter(since))
        .map((r) => Map<String, dynamic>.from(r))
        .toList();
  }
}

const user = 'user-1';
final t0 = DateTime.utc(2026, 10, 5, 10);

Future<void> seed(AppDatabase db, DateTime deviceNow) async {
  await db.into(db.wallets).insert(WalletsCompanion.insert(
      id: 'w1', createdAt: deviceNow, updatedAt: deviceNow,
      name: 'Conto', colorHex: '#000000'));
  await db.into(db.transactions).insert(TransactionsCompanion.insert(
      id: 'tx1', createdAt: deviceNow, updatedAt: deviceNow,
      type: TransactionType.expense, amountCents: 1000, date: deviceNow,
      walletId: 'w1'));
  await db.into(db.tags).insert(TagsCompanion.insert(
      id: 'tag1', createdAt: deviceNow, updatedAt: deviceNow,
      walletId: const Value('w1'), name: 'lavoro'));
}

void main() {
  test('PoC 1: created_at del client avvelena il watermark di pull', () async {
    final remote = RealisticRemote(t0);
    final devA = AppDatabase(NativeDatabase.memory());
    final devB = AppDatabase(NativeDatabase.memory());
    final syncA = SupabaseSyncService(remote, devA, currentUserId: () => user);
    final syncB = SupabaseSyncService(remote, devB, currentUserId: () => user);

    // Device A ha l'orologio avanti di un giorno (o è un client malevolo
    // con created_at = 2099): crea dati e un'associazione tag.
    final skewed = t0.add(const Duration(days: 1));
    await seed(devA, t0);
    await devA.into(devA.transactionTags).insert(
        TransactionTagsCompanion.insert(
            transactionId: 'tx1', tagId: 'tag1', createdAt: skewed));
    await syncA.syncNow();

    // Device B (stesso utente) scarica tutto: watermark = created_at skewed.
    await syncB.syncNow();
    final stateB = await devB.select(devB.syncStates).getSingle();
    print('lastPulledAt di B dopo la prima sync: ${stateB.lastPulledAt.toUtc()}'
        ' (orologio server: ${remote.serverNow})');

    // A modifica l'importo (dopo), e sincronizza: il server lo marca "ora".
    await (devA.update(devA.transactions)..where((t) => t.id.equals('tx1')))
        .write(TransactionsCompanion(
            amountCents: const Value(99900),
            updatedAt: Value(DateTime.now().add(const Duration(days: 3)))));
    await syncA.syncNow();
    expect(remote.tables['transactions']!['tx1']!['amount_cents'], 99900);

    // B sincronizza di nuovo: la modifica NON arriva.
    await syncB.syncNow();
    final txB = await (devB.select(devB.transactions)
          ..where((t) => t.id.equals('tx1')))
        .getSingle();
    print('importo su server: 99900 — importo su B dopo la sync: ${txB.amountCents}');
    expect(txB.amountCents, 1000, reason: 'modifica persa silenziosamente');
    await devA.close();
    await devB.close();
  });

  test('PoC 2: watermark unico + pull sequenziale perde modifiche concorrenti',
      () async {
    // Orologio server leggermente indietro rispetto al device: esclude
    // l'effetto "eco" del push (PoC 3) e isola il problema del watermark.
    final base = DateTime.now().toUtc().subtract(const Duration(hours: 1));
    final remote = RealisticRemote(base);
    final devA = AppDatabase(NativeDatabase.memory());
    final devB = AppDatabase(NativeDatabase.memory());
    final syncA = SupabaseSyncService(remote, devA, currentUserId: () => user);
    final syncB = SupabaseSyncService(remote, devB, currentUserId: () => user);
    await seed(devA, base.subtract(const Duration(hours: 1)));
    await syncA.syncNow();
    await syncB.syncNow();

    // Mentre B sta sincronizzando (wallets già scaricati, categories in
    // corso), un altro device rinomina il wallet e modifica una transazione.
    var injected = false;
    remote.onSelect = (table) {
      if (table == 'categories' && !injected) {
        injected = true;
        final w = Map<String, dynamic>.from(remote.tables['wallets']!['w1']!)
          ..remove('updated_at');
        remote.upsert('wallets', [{...w, 'name': 'Conto RINOMINATO'}]);
        final t = Map<String, dynamic>.from(remote.tables['transactions']!['tx1']!)
          ..remove('updated_at');
        remote.upsert('transactions', [{...t, 'description': 'modificata'}]);
      }
    };
    await syncB.syncNow();
    remote.onSelect = null;
    await syncB.syncNow(); // anche le sync successive non la recuperano
    await syncB.syncNow();
    final wB = await devB.select(devB.wallets).getSingle();
    print('wallet su server: ${remote.tables['wallets']!['w1']!['name']} — su B: ${wB.name}');
    expect(remote.tables['wallets']!['w1']!['name'], 'Conto RINOMINATO');
    expect(wB.name, 'Conto', reason: 'rinomina persa per sempre su B');
    await devA.close();
    await devB.close();
  });

  test('PoC 3: nessun controllo di conflitto — una modifica offline più '
      'vecchia sovrascrive quella più recente di un altro device', () async {
    final base = DateTime.now().toUtc().subtract(const Duration(hours: 1));
    final remote = RealisticRemote(base);
    final devA = AppDatabase(NativeDatabase.memory());
    final devB = AppDatabase(NativeDatabase.memory());
    final syncA = SupabaseSyncService(remote, devA, currentUserId: () => user);
    final syncB = SupabaseSyncService(remote, devB, currentUserId: () => user);
    await seed(devA, base.subtract(const Duration(hours: 1)));
    await syncA.syncNow();
    await syncB.syncNow();

    // 10:00 A (offline) corregge l'importo a 1500.
    await (devA.update(devA.transactions)..where((t) => t.id.equals('tx1')))
        .write(TransactionsCompanion(
            amountCents: const Value(1500),
            updatedAt: Value(DateTime.now())));
    await Future<void>.delayed(const Duration(milliseconds: 20));
    // 10:05 B corregge l'importo a 2000 e sincronizza subito.
    await (devB.update(devB.transactions)..where((t) => t.id.equals('tx1')))
        .write(TransactionsCompanion(
            amountCents: const Value(2000),
            updatedAt: Value(DateTime.now())));
    await syncB.syncNow();
    // 10:30 A torna online: la sua modifica PIÙ VECCHIA vince ovunque.
    await syncA.syncNow();
    await syncB.syncNow();
    final txB = await (devB.select(devB.transactions)
          ..where((t) => t.id.equals('tx1')))
        .getSingle();
    print('valore finale server: ${remote.tables['transactions']!['tx1']!['amount_cents']}'
        ' — su B: ${txB.amountCents} (ultima modifica in ordine di tempo: 2000)');
    expect(remote.tables['transactions']!['tx1']!['amount_cents'], 1500);
    await devA.close();
    await devB.close();
  });
}
```

</details>

## Appendice B — Richieste effettuate verso l'istanza (tutte anonime e in sola lettura)

Data: 2026-10-05. Header: solo `apikey: <publishable key presente nel repo>`.

| Richiesta | Risposta | Uso nel report |
|---|---|---|
| `GET /auth/v1/settings` | `"disable_signup":false,"mailer_autoconfirm":false`, unico provider `email`, `anonymous_users:false` | NIP-11, NIP-22 |
| `GET /rest/v1/profiles?select=*` | `[]` | isolamento anon ✅ |
| `GET /rest/v1/wallets?select=id&limit=1` | `[]` | isolamento anon ✅ |
| `GET /rest/v1/wallet?select=id` | `PGRST205`, hint `Perhaps you meant the table 'public.wallets'` | NIP-17 |
| `POST /rest/v1/rpc/owns_wallet` | `false` | NIP-21 |
| `POST /rest/v1/rpc/set_updated_at` | `PGRST202` (non esposta) | NIP-21 ✅ |
| `GET /rest/v1/` | `Secret API key required` | NIP-21 ✅ |
| `POST /graphql/v1` (introspection) | `pg_graphql extension is not enabled` | NIP-21 ✅ |
| `GET /storage/v1/bucket` | `[]` | NIP-12 ✅ |
| `POST /storage/v1/object/list/attachments` | `[]` | NIP-12 ✅ |

Non ho effettuato signup, login, reset, scritture, upload né chiamate all'Edge Function.

## Appendice C — Punti di forza rilevati

- RLS abilitata su tutte le tabelle fin dalla prima migration (default-deny), con
  un test che fallisce se una tabella nuova ne è priva.
- Ownership centralizzata in funzioni `owns_*` con `search_path` fissato e
  `SECURITY INVOKER`: nessun oracolo via RPC.
- Controlli espliciti su `wallet_to_id`, `reimburse_tx_id` e su entrambi i lati
  delle tabelle di join.
- `updated_at` assegnato dal server in UPDATE: l'intenzione è corretta, va solo
  estesa a INSERT (NIP-02).
- Sessione Supabase e code verifier PKCE in Keychain/Keystore
  (`secure_auth_storage.dart`), nessun token in SharedPreferences. ✅ Verificato
  sul simulatore: nessun token in chiaro nel container dell'app.
- Nessuna `service_role` nel client né nella history; `.temp`, `key.properties`
  e keystore esclusi da git.
- Bucket privato con isolamento per prefisso; OpenAPI e GraphQL non esposti; conferma email attiva sull'hosted.
- Test pgTAP di isolamento in CI su Supabase locale, mai sul progetto reale.
- Blocco della sync con dati locali di un altro account (fix `85d1483`): un
  buon presidio, da estendere all'uso dell'app (NIP-13).

## Appendice D — Verifiche pgTAP su Supabase locale (eseguite)

Ambiente: Supabase CLI 2.117.0, Postgres 17.6.1.166 in Docker (Colima), creato da
una copia isolata del repo con le 5 migration di `supabase/migrations/`. Per
allinearla all'hosted, nella copia ho impostato `enable_confirmations = true`.
Esecuzione:
`docker exec -i supabase_db_nipay-audit psql -U postgres -X -q -tA < audit_findings_test.sql`.
Ho usato `psql` dentro il container perché `supabase test db` non vede i file
fuori dalla home, dato che Colima monta nella VM solo la home. Con il file dentro
`supabase/tests/` del repo basta `supabase test db`.

Controllo dell'ambiente: la suite del team `rls_isolation_test.sql` dà **88/88 ok**.

Risultato del file di verifica: ogni `ok` conferma il difetto indicato.

```
ok 1 - VULN NIP-12: bucket attachments senza file_size_limit
ok 2 - VULN NIP-12: bucket attachments senza allowed_mime_types
ok 3 - VULN NIP-07: transazione di A con category_id di B
ok 4 - VULN NIP-07: categoria di A con parent_id di B
ok 5 - VULN NIP-07: ricorrenza di A con category_id di B
ok 6 - VULN NIP-07: voce nota spese di A con centro di costo e nota spese di B
ok 7 - VULN NIP-07: UUID inesistente → 23503, UUID di B → successo (oracolo)
ok 8 - VULN NIP-07: 23505 rivela che B ha un budget su Cat B
ok 9 - VULN NIP-07: A occupa per primo il budget sulla categoria Cat B2 di B
ok 10 - VULN NIP-07: A inserisce una categoria con un UUID che B userà
ok 11 - VULN NIP-05: A retrodata la propria richiesta di cancellazione
ok 12 - VULN NIP-05: il valore retrodatato è stato salvato
ok 13 - VULN NIP-02: wallets.updated_at futuro accettato in INSERT
ok 14 - VULN NIP-02: custom_field_values.updated_at del client conservato
ok 15 - VULN NIP-02: transaction_tags.created_at (watermark) scelto dal client, anche in upsert
ok 16 - VULN NIP-04: options non-array accettato (il pull fa "as List?" e lancia)
ok 17 - VULN NIP-04: color_hex e currency non validi accettati
ok 18 - VULN NIP-04/12: importo negativo e descrizione da 1 MB accettati
ok 19 - VULN NIP-07: B non può più creare/sincronizzare il budget sulla PROPRIA categoria
ok 20 - VULN NIP-07: la sync di B fallisce sull'id occupato da A
ok 21 - INFO NIP-21: anon può eseguire owns_wallet via RPC
1..21
```

<details>
<summary>supabase/tests/audit_findings_test.sql</summary>

```sql
-- Verifiche dell'audit di sicurezza (SECURITY_AUDIT.md) su Supabase LOCALE.
-- Convenzione: ogni test che PASSA conferma la presenza del difetto
-- ("VULN …"). Dopo le correzioni le asserzioni vanno invertite.
-- Tutto dentro una transazione annullata: nessun residuo.
begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

-- Seed come postgres (RLS bypassata) ---------------------------------
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'audit-a@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'audit-b@test.local');
insert into wallets (id, owner_user_id, name, color_hex) values
  ('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Wallet A', '#111111'),
  ('b0000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'Wallet B', '#222222');
insert into categories (id, wallet_id, name, icon, color_hex, kind) values
  ('b0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', 'Cat B', 'cart', '#222222', 'expense'),
  ('b0000000-0000-0000-0000-0000000000b2', 'b0000000-0000-0000-0000-000000000001', 'Cat B2 (senza budget)', 'cart', '#222222', 'expense');
insert into budgets (id, wallet_id, category_id, limit_cents) values
  ('b0000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 2000);
insert into tags (id, wallet_id, name) values
  ('a0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'tag A');
insert into custom_field_defs (id, wallet_id, name, type) values
  ('a0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'campo A', 'text');
insert into transactions (id, wallet_id, type, amount_cents, date) values
  ('a0000000-0000-0000-0000-00000000000c', 'a0000000-0000-0000-0000-000000000001', 'expense', 100, now()),
  ('a0000000-0000-0000-0000-00000000000d', 'a0000000-0000-0000-0000-000000000001', 'expense', 100, now());
insert into cost_centers (id, wallet_id, name) values
  ('b0000000-0000-0000-0000-00000000000a', 'b0000000-0000-0000-0000-000000000001', 'CdC B');
insert into expense_reports (id, wallet_id, name, date_from, date_to, status) values
  ('b0000000-0000-0000-0000-00000000000b', 'b0000000-0000-0000-0000-000000000001', 'Nota B', now(), now(), 'draft');

-- NIP-12: limiti del bucket (come postgres) ---------------------------
select is((select file_size_limit from storage.buckets where id = 'attachments'), null,
  'VULN NIP-12: bucket attachments senza file_size_limit');
select is((select allowed_mime_types from storage.buckets where id = 'attachments'), null,
  'VULN NIP-12: bucket attachments senza allowed_mime_types');

-- =====================================================================
-- Utente A
-- =====================================================================
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

-- NIP-07: FK verso righe di B ------------------------------------------
select lives_ok($$ insert into transactions (wallet_id, type, amount_cents, date, category_id)
  values ('a0000000-0000-0000-0000-000000000001', 'expense', 1, now(), 'b0000000-0000-0000-0000-000000000002') $$,
  'VULN NIP-07: transazione di A con category_id di B');
select lives_ok($$ insert into categories (wallet_id, name, icon, color_hex, kind, parent_id)
  values ('a0000000-0000-0000-0000-000000000001', 'x', 'x', '#000000', 'expense', 'b0000000-0000-0000-0000-000000000002') $$,
  'VULN NIP-07: categoria di A con parent_id di B');
select lives_ok($$ insert into recurring_rules (wallet_id, category_id, type, amount_cents, frequency, start_at, next_run_at)
  values ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 'expense', 1, 'monthly', now(), now()) $$,
  'VULN NIP-07: ricorrenza di A con category_id di B');
select lives_ok($$ insert into expense_report_entries (transaction_id, cost_center_id, report_id)
  values ('a0000000-0000-0000-0000-00000000000c', 'b0000000-0000-0000-0000-00000000000a', 'b0000000-0000-0000-0000-00000000000b') $$,
  'VULN NIP-07: voce nota spese di A con centro di costo e nota spese di B');

-- NIP-07: oracolo di esistenza (FK) ------------------------------------
select throws_ok($$ insert into transactions (wallet_id, type, amount_cents, date, category_id)
  values ('a0000000-0000-0000-0000-000000000001', 'expense', 1, now(), '99999999-9999-9999-9999-999999999999') $$,
  '23503', null, 'VULN NIP-07: UUID inesistente → 23503, UUID di B → successo (oracolo)');

-- NIP-07: oracolo + squatting sul vincolo UNIQUE globale dei budget ----
select throws_ok($$ insert into budgets (wallet_id, category_id, limit_cents)
  values ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 1) $$,
  '23505', null, 'VULN NIP-07: 23505 rivela che B ha un budget su Cat B');
select lives_ok($$ insert into budgets (wallet_id, category_id, limit_cents)
  values ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-0000000000b2', 1) $$,
  'VULN NIP-07: A occupa per primo il budget sulla categoria Cat B2 di B');

-- NIP-07: ID squatting (id scelto dal client) --------------------------
select lives_ok($$ insert into categories (id, wallet_id, name, icon, color_hex, kind)
  values ('b0000000-0000-0000-0000-0000000000f0', 'a0000000-0000-0000-0000-000000000001', 'squat', 'x', '#000000', 'expense') $$,
  'VULN NIP-07: A inserisce una categoria con un UUID che B userà');

-- NIP-05: deletion_requested_at arbitrario ----------------------------
select lives_ok($$ update profiles set deletion_requested_at = '2000-01-01T00:00:00Z'
  where id = '11111111-1111-1111-1111-111111111111' $$,
  'VULN NIP-05: A retrodata la propria richiesta di cancellazione');
select is((select deletion_requested_at from profiles where id = '11111111-1111-1111-1111-111111111111'),
  '2000-01-01T00:00:00Z'::timestamptz, 'VULN NIP-05: il valore retrodatato è stato salvato');

-- NIP-02: timestamp del client conservati -----------------------------
insert into wallets (id, owner_user_id, name, color_hex, updated_at)
  values ('a0000000-0000-0000-0000-0000000000a2', '11111111-1111-1111-1111-111111111111', 'W2', '#000000', '2099-01-01T00:00:00Z');
select is((select updated_at from wallets where id = 'a0000000-0000-0000-0000-0000000000a2'),
  '2099-01-01T00:00:00Z'::timestamptz, 'VULN NIP-02: wallets.updated_at futuro accettato in INSERT');
insert into custom_field_values (transaction_id, field_id, value, updated_at)
  values ('a0000000-0000-0000-0000-00000000000c', 'a0000000-0000-0000-0000-000000000005', 'v', '2099-01-01T00:00:00Z');
select is((select updated_at from custom_field_values where transaction_id = 'a0000000-0000-0000-0000-00000000000c'),
  '2099-01-01T00:00:00Z'::timestamptz, 'VULN NIP-02: custom_field_values.updated_at del client conservato');
insert into transaction_tags (transaction_id, tag_id, created_at)
  values ('a0000000-0000-0000-0000-00000000000c', 'a0000000-0000-0000-0000-000000000003', '2099-01-01T00:00:00Z');
-- stesso SQL che PostgREST genera per upsert (Prefer: resolution=merge-duplicates)
insert into transaction_tags (transaction_id, tag_id, created_at)
  values ('a0000000-0000-0000-0000-00000000000c', 'a0000000-0000-0000-0000-000000000003', '2099-06-01T00:00:00Z')
  on conflict (transaction_id, tag_id) do update set created_at = excluded.created_at;
select is((select created_at from transaction_tags where transaction_id = 'a0000000-0000-0000-0000-00000000000c'),
  '2099-06-01T00:00:00Z'::timestamptz, 'VULN NIP-02: transaction_tags.created_at (watermark) scelto dal client, anche in upsert');

-- NIP-04: nessuna validazione server-side -----------------------------
select lives_ok($$ insert into custom_field_defs (wallet_id, name, type, options)
  values ('a0000000-0000-0000-0000-000000000001', 'x', 'choice', '{"non":"una lista"}'::jsonb) $$,
  'VULN NIP-04: options non-array accettato (il pull fa "as List?" e lancia)');
select lives_ok($$ insert into wallets (owner_user_id, name, color_hex, currency)
  values ('11111111-1111-1111-1111-111111111111', 'x', 'zzz', 'NON-UNA-VALUTA') $$,
  'VULN NIP-04: color_hex e currency non validi accettati');
select lives_ok($$ insert into transactions (wallet_id, type, amount_cents, date, description)
  values ('a0000000-0000-0000-0000-000000000001', 'expense', -50000, now(), repeat('x', 1000000)) $$,
  'VULN NIP-04/12: importo negativo e descrizione da 1 MB accettati');

-- =====================================================================
-- Utente B: effetti dello squatting di A
-- =====================================================================
set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

select throws_ok($$ insert into budgets (id, wallet_id, category_id, limit_cents)
  values ('b0000000-0000-0000-0000-0000000000c1', 'b0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-0000000000b2', 500)
  on conflict (id) do update set limit_cents = excluded.limit_cents $$,
  '23505', null, 'VULN NIP-07: B non può più creare/sincronizzare il budget sulla PROPRIA categoria');
select throws_ok($$ insert into categories (id, wallet_id, name, icon, color_hex, kind)
  values ('b0000000-0000-0000-0000-0000000000f0', 'b0000000-0000-0000-0000-000000000001', 'mia', 'x', '#000000', 'expense')
  on conflict (id) do update set name = excluded.name $$,
  '42501', null, 'VULN NIP-07: la sync di B fallisce sull''id occupato da A');

-- =====================================================================
-- Anon
-- =====================================================================
reset role;
select ok(has_function_privilege('anon', 'public.owns_wallet(uuid)', 'execute'),
  'INFO NIP-21: anon può eseguire owns_wallet via RPC');

select * from finish();
rollback;
```

</details>
