# nIpay — Piano amicizie, chat e spese divise

> Obiettivo: permettere agli utenti con account di diventare **amici**
> (scansionando un QR), **chattare** 1:1 e in gruppo e **dividere le
> spese** stile Splitwise ("chi deve cosa"), senza rompere i principi già
> fissati: modalità solo locale permanente, portafogli come spazi isolati,
> RLS default-deny, sicurezza prima delle feature.
>
> Prerequisito: account e sync di [ACCOUNT_SYNC_PLAN.md](ACCOUNT_SYNC_PLAN.md)
> (M-ACC0–M-ACC9). La decisione "**NON condivisione di un portafoglio tra
> utenti**" resta valida: le spese divise vivono in tabelle proprie, e
> ognuno registra la **propria** parte nel **proprio** portafoglio.

## Decisioni (2026-10-22, Sergio)

- [x] **Amicizia su richiesta + accettazione**: chi scansiona il QR (o
  inserisce il codice) invia una richiesta; l'amicizia esiste solo dopo
  che il **ricevente** la accetta. Rifiutare non manda notifiche.
- [x] **QR = codice personale fisso**, rigenerabile a mano ("Rigenera
  codice" invalida il vecchio). Il codice NON è lo user id: è una stringa
  casuale dedicata.
- [x] **Spese divise stile Splitwise**: una spesa pagata da uno, divisa
  tra più persone; l'app tiene i saldi "chi deve cosa" e i saldi si
  chiudono con un **rimborso**.
- [x] **Divisione**: in parti uguali di default, con importi personalizzati
  per persona (la somma deve tornare col totale).
- [x] **Chat 1:1 e di gruppo**, messaggi **istantanei** (Supabase
  Realtime, riattivato SOLO sulle tabelle della chat — vedi M-SOC3).
- [x] **Profilo visibile agli amici**: nome visualizzato scelto
  dall'utente + avatar con le iniziali. L'email non è mai visibile ad
  altri utenti.
- [x] **Notifiche**: solo in-app per ora (badge e contatori). Le push sono
  fuori scope finché non c'è l'account Apple Developer (vedi in fondo).
- [x] **Blocca e segnala** fin dalla prima versione (requisito Apple per
  i contenuti generati dagli utenti, guideline 1.2).
- [x] **Tutta l'interfaccia tradotta in tutte le lingue dell'app**
  (vincolante per ogni milestone, vedi "Traduzioni" sotto).
- [x] **Solo con account**: senza login la sezione Amici mostra "Accedi
  per usare Amici". La modalità solo locale resta identica a oggi.
- [x] **Spese divise dal foglio "Nuova transazione"** (non dalla chat):
  inserisco la spesa, aggiungo gli amici con cui condividerla e segno chi
  ha pagato tra me e loro; l'app calcola chi deve cosa (M-SOC4).
- [x] **Modello contabile**: ognuno registra nel proprio portafoglio la
  **propria quota come spesa** alla data della spesa; la differenza tra
  quanto ha pagato e la sua quota diventa un movimento "**con amici**",
  escluso dai totali come i trasferimenti. Saldo del portafoglio e
  statistiche restano entrambi veri.
- [x] **Account cancellato**: i suoi messaggi diventano "Messaggio
  eliminato" e il mittente "Utente eliminato"; le spese divise restano
  per non falsare i saldi degli altri, con il partecipante anonimizzato.
- [x] **Tab dedicata "Amici"** nella barra di navigazione (5 voci).

## Traduzioni (vincolante per ogni milestone)

L'app ha **8 lingue**: italiano, inglese, arabo (RTL), tedesco, spagnolo,
francese, hindi, cinese (`lib/l10n/app_*.arb`, template `app_en.arb`).

- [ ] Ogni stringa nuova di Amici, chat, richieste, spese divise, errori,
  stati vuoti, segnalazioni, permesso fotocamera e messaggi di sistema
  entra in **tutti gli 8 file arb nello stesso commit**: niente ripiego
  sull'inglese.
- [ ] Plurali e parametri con la sintassi ICU (`{count, plural, ...}`,
  `{name}`): "Mario ti deve {amount}", "{count} richieste" — mai frasi
  composte concatenando pezzi tradotti (l'ordine delle parole cambia tra
  lingue).
- [ ] **Arabo (RTL)**: verificare a schermo la chat (bolle invertite),
  le tessere amico, le frecce "ti deve / gli devi" e il QR; usare
  `EdgeInsetsDirectional` / `AlignmentDirectional` come nel resto dell'app.
- [ ] Testo del permesso fotocamera aggiornato (scontrini **e** QR) nelle
  `InfoPlist.strings` iOS di ogni lingua e nella stringa Android.
- [x] **Controllo automatico (2026-10-22)**: `untranslated-messages-file`
  in `l10n.yaml` (scrive `build/untranslated_messages.json`) e passo
  "Check translations" in `.github/workflows/ci.yml`, che fallisce se il
  file non è `{}`: una lingua non resta indietro in silenzio.
- [x] **Debito esistente chiuso (2026-10-22)** (non legato ad Amici):
  `ar`, `de`, `es`, `fr`, `hi` e `zh` avevano 150 stringhe contro le 206
  di `en`/`it` (le 56 di account e sync M-ACC comparivano in inglese).
  Ora tutte e 8 le lingue hanno 206 stringhe; schermata Account
  verificata a schermo in arabo (RTL). Il controllo CI si può attivare.

---

## M-SOC0 — Fondamenta legali e store (PRIMA del codice)

Come M-ACC0: senza questo i nuovi dati sono un rischio legale.

- [ ] **Privacy policy aggiornata** — nuovi dati trattati:
  - nome visualizzato e codice amico;
  - grafo delle amicizie (chi è amico di chi, richieste, blocchi);
  - messaggi (testo) e appartenenza ai gruppi;
  - spese divise: descrizione, importi, valuta, partecipanti, rimborsi;
  - segnalazioni inviate.
  Dichiarare che i messaggi **non sono cifrati end-to-end** (cifrati in
  transito e a riposo da Supabase) e che un messaggio **segnalato** può
  essere letto dal titolare per la moderazione.
- [ ] **Termini d'uso** con regole di condotta e "tolleranza zero" per
  contenuti offensivi (richiesto da Apple per chat tra utenti), contatto
  per segnalazioni e impegno a gestirle entro 24 ore.
- [ ] **Store**: le dichiarazioni "nessun dato raccolto" dell'analisi
  2026-08-09 non valgono più per chi usa Amici → aggiornare Data safety
  (Play) e privacy label (Apple): messaggi, contenuti utente, identificativi.
- [ ] **Età minima** per account con chat: in Italia l'età del consenso
  digitale è 14 anni (art. 2-quinquies Codice privacy); da fissare
  insieme alla classificazione d'età sugli store (una chat tra utenti
  alza il rating) e da verificare con una fonte legale prima del lancio.

**Fatto quando**: privacy policy e termini pubblicati prima di qualunque
amicizia reale.

---

## M-SOC1 — Profilo e codice amico ✅ (2026-10-22)

- [x] Migration [`20261022000000_profiles_friend_code.sql`](../supabase/migrations/20261022000000_profiles_friend_code.sql):
  `profiles` guadagna
  - `display_name text` (1–40 caratteri, niente spazi ai bordi né
    caratteri di controllo; check constraint);
  - `friend_code text not null unique` (10 caratteri da un alfabeto di 32
    senza ambigui, 50 bit da `extensions.gen_random_bytes`, generati
    **dal server** in `private.new_friend_code()`; assegnato anche ai
    profili esistenti e a ogni signup da `handle_new_user`);
  - `friend_code_rotated_at timestamptz`.
- [x] RPC `set_display_name(new_name)`: il client non scrive `profiles`
  direttamente (NIP-05); stesse regole lato app in
  `normalizeDisplayName` (`lib/core/validation.dart`), che conta i
  caratteri come Postgres (`runes`, non unità UTF-16).
- [x] RPC `regenerate_friend_code()`: nuovo codice, il vecchio smette
  subito di funzionare; massimo 5 rigenerazioni in 24 ore.
- [x] RPC `resolve_friend_code(code)` → solo `id` + `display_name`.
  Accetta minuscole, spazi e trattini; niente risultati (indistinguibili
  tra loro) per codice proprio, inesistente, malformato o di un account
  in cancellazione; massimo 30 ricerche/ora. Limiti in
  `private.rate_limit_events` + `private.consume_rate_limit` (riusabili
  per richieste, messaggi e segnalazioni).
- [x] La SELECT diretta su `profiles` resta "solo il proprio profilo".
- [x] App: `ProfileService` (`lib/data/services/profile_service.dart`,
  come `AuthService`: i `repositories` restano per Drift), errori del
  server tradotti (`profileErrorOf`), card **Profilo** in Account (nome
  modificabile, codice amico `ABCDE-23456` con copia e rigenerazione
  confermata) e dialog riutilizzabile `showDisplayNameDialog`
  (`lib/features/friends/`). 15 stringhe nuove nelle 8 lingue.
- [x] Test: pgTAP `supabase/tests/profiles_friend_code_test.sql` (34:
  formato e unicità, nessuna lettura di codici altrui, niente update
  diretto, validazione del nome, risoluzione, rigenerazione, limiti
  contati davvero, anonimo bloccato); Dart: validazione, formato del
  codice, traduzione degli errori, 6 test widget della card Profilo.
- **Spostato a M-SOC2** (dipende da `friendships` e `blocks`): la vista
  `friend_profiles` (`security_invoker = true`) e il filtro sui blocchi
  in `resolve_friend_code`; il prompt "Come ti chiami?" alla prima
  apertura della tab Amici (il dialog esiste già); il QR del codice.
- Migration applicata all'hosted il 2026-10-22.

**Fatto quando**: nome e codice gestiti ✓, stringhe nelle 8 lingue ✓,
test pgTAP verdi ✓, nessuna via per leggere email o codici altrui ✓.

---

## M-SOC2 — Richieste di amicizia, QR, blocchi

**Stato (2026-10-22)**: database fatto e testato in locale — migration
[`20261022010000_friendships.sql`](../supabase/migrations/20261022010000_friendships.sql)
e 56 test pgTAP in `supabase/tests/friendships_test.sql` (flusso
richiesta/accettazione/rifiuto con attesa di 7 giorni, richieste
incrociate, annulla, rimuovi, blocca/sblocca invisibile al bloccato,
limiti 20 in attesa e 30 invii/giorno, anonimo bloccato). **Cambiato
rispetto al piano**: niente vista `friend_profiles`: le letture sono RPC
SECURITY DEFINER (`list_friends`, `list_friend_requests`,
`list_blocked`) che restituiscono solo id e nome — una vista
`security_invoker` avrebbe richiesto di aprire `profiles` agli amici con
tutte le colonne.

**App fatta (2026-10-22)**: `FriendsService`
(`lib/data/services/friends_service.dart`, errori tradotti con
`friendsErrorOf`), tab **Amici** (5ª voce, badge con le richieste in
arrivo; senza account solo l'invito ad accedere) con richieste in
arrivo/uscita, amici (rimuovi/blocca con conferma) e bloccati (sblocca),
prompt "Come ti chiami?" alla prima apertura, schermata **Il mio QR**
(`qr_flutter`, link `com.alum.nipay://friend/<codice>`, copia e
condividi) e **Aggiungi amico** (`mobile_scanner` + codice a mano, stesso
percorso: codice → chi è → conferma → richiesta). 40 stringhe nelle 8
lingue; permesso fotocamera aggiornato (scontrini e QR). Test: parsing del
QR (rifiuta QR di altre app), mappatura errori, 11 widget test del
flusso; build iOS ok.

Fatto anche (2026-10-22): migration M-SOC1 e M-SOC2 applicate all'hosted
con `supabase db push` (13 versioni allineate al repo, codice amico
assegnato ai profili esistenti); verifica a schermo su simulatore iPhone 17
(tab da non loggato e loggato, tema chiaro/scuro, arabo RTL, Il mio QR con
il QR vero); gli stati di errore del server mostrano "Impossibile
caricare" + Riprova invece di un'eccezione; "Come ti chiami?" compare solo
con la tab Amici visibile.

Ancora aperto in M-SOC2:
- Aprire l'app dal link del QR letto con la fotocamera di sistema (oggi
  il QR si scansiona da dentro l'app; serve un gestore dei deep link
  `friend/` accanto a quello dell'auth).
- Testo del permesso fotocamera solo in italiano: localizzarlo richiede
  `InfoPlist.strings` per lingua nel progetto Xcode.
- Prova end-to-end con due account veri (richiesta, accettazione,
  blocco).

### Da M-SOC1

- Vista `friend_profiles` (`with (security_invoker = true)`): solo `id` +
  `display_name` degli amici accettati.
- `resolve_friend_code` filtra i blocchi in entrambe le direzioni.
- Prompt "Come ti chiami?" (`showDisplayNameDialog`) alla prima apertura
  della tab Amici se il nome non è impostato.

### Modello

- `friendships`: `id`, `requester_id`, `addressee_id`, `status`
  (`pending` | `accepted` | `declined`), `created_at`, `responded_at`.
  - Unicità della **coppia** indipendente dall'ordine (indice unico su
    `least(requester_id, addressee_id), greatest(...)`).
  - `requester_id <> addressee_id` (check).
- `blocks`: `blocker_id`, `blocked_id`, `created_at` (PK sulla coppia).

### Flusso

1. A mostra il proprio QR: `com.alum.nipay://friend/<friend_code>` (stesso
   schema del deep link già usato per l'auth; aperto da fotocamera di
   sistema porta dentro l'app). Sotto il QR: il codice in chiaro e
   "Condividi" (share sheet).
2. B scansiona (o inserisce il codice a mano) → l'app chiama
   `resolve_friend_code` e mostra "Inviare la richiesta a **Mario R.**?".
3. B conferma → `send_friend_request(addressee)` crea la riga `pending`.
4. A vede la richiesta in **Richieste** (badge sulla tab) → **Accetta** o
   **Rifiuta**. Solo `addressee_id` può cambiare lo stato.
5. Accettata → amici. Rifiutata → `declined`; B vede "Richiesta non
   accettata", nessuna notifica attiva. B non può reinviare per 7 giorni.

Regole lato DB (RPC SECURITY DEFINER + check, non solo nel client):
- niente richieste verso chi ti ha bloccato o che hai bloccato;
- se esiste già una richiesta `pending` inversa (A→B mentre B→A), la
  nuova richiesta la **accetta** direttamente (entrambi lo vogliono);
- massimo 20 richieste `pending` in uscita per utente;
- **Annulla richiesta** (solo il mittente, finché `pending`);
- **Rimuovi amico** (entrambi): cancella la riga, le chat 1:1 restano in
  sola lettura, i saldi aperti restano visibili e saldabili;
- **Blocca**: rimuove l'amicizia, esce dalle chat 1:1 con quella persona,
  impedisce richieste e messaggi in entrambe le direzioni.

### RLS

- `friendships`: SELECT se `auth.uid()` è requester o addressee; nessun
  INSERT/UPDATE/DELETE diretto (solo via RPC, che controllano le regole
  sopra). Policy `TO authenticated` (NIP-21).
- `blocks`: SELECT/INSERT/DELETE solo per `blocker_id = auth.uid()`. Chi
  è bloccato **non** può sapere di esserlo.

### App

- Nuovi package: `mobile_scanner` (scansione QR, usa il permesso
  fotocamera già dichiarato per gli scontrini — aggiornare il testo del
  permesso) e `qr_flutter` (disegno del QR). Versioni da verificare al
  momento dell'aggiunta, valutare peso e manutenzione.
- Schermate: **Amici** (lista + saldi), **Il mio QR**, **Scansiona**,
  **Richieste** (ricevute / inviate). Stringhe in tutte le lingue arb.
- Repository `FriendsRepository` (interfaccia astratta come gli altri),
  la UI non chiama Supabase direttamente.

**Fatto quando**: flusso QR → richiesta → accettazione funzionante tra due
account reali, in tutte le 8 lingue (arabo verificato a schermo); test pgTAP su: nessuno può accettare per conto d'altri,
nessuna richiesta tra utenti bloccati, nessuna lettura di richieste altrui.

---

## M-SOC3 — Chat 1:1 e di gruppo (Realtime)

### Modello

- `conversations`: `id`, `kind` (`direct` | `group`), `title` (solo
  gruppi, 1–60 caratteri), `created_by`, `created_at`.
  - `direct`: una sola per coppia (indice unico sulla coppia ordinata,
    tenuto in una colonna dedicata).
- `conversation_members`: `conversation_id`, `user_id`, `role` (`admin` |
  `member`), `joined_at`, `last_read_at`.
- `messages`: `id`, `conversation_id`, `sender_id`, `body` (1–2000
  caratteri), `created_at`, `deleted_at` (soft-delete: il mittente può
  eliminare un proprio messaggio).
- `reports`: `id`, `reporter_id`, `reported_user_id`, `message_id`
  (nullable: si può segnalare un messaggio o un utente), `reason` (enum:
  spam, offensivo, molestie, altro + testo opzionale ≤ 500), `created_at`,
  `resolved_at`. Solo INSERT dal client (e solo su messaggi di chat di cui
  si è membri); lette e gestite dal titolare via dashboard Supabase.
  Massimo 20 segnalazioni/giorno per utente.

### Regole

- Chat 1:1 solo tra **amici accettati** e non bloccati.
- Gruppi: li crea chiunque; si possono aggiungere **solo propri amici**;
  gli admin aggiungono/rimuovono membri; chiunque può uscire. Massimo 50
  membri.
- Leggere e scrivere messaggi solo se membro (helper
  `private.is_member(conversation_id)`, come `owns_wallet`).
- Messaggi immutabili dopo l'invio (niente modifica in v1), eliminabili
  dal mittente.
- Limite di invio (es. 30 messaggi/minuto per utente) via trigger.

### Realtime (riattivazione controllata)

- Riattivare Realtime in `supabase/config.toml` e nell'hosted, ma con la
  **publication** limitata a `messages`, `conversation_members` e
  `friendships` (mai alle tabelle finanziarie dei portafogli).
- `postgres_changes` di Supabase applica la RLS di SELECT: verificare con
  due client che un non membro **non** riceva eventi della conversazione.
- Aggiornare la nota NIP-21 di [SECURITY_AUDIT.md](SECURITY_AUDIT.md):
  Realtime non è più spento, ma limitato per publication + RLS.
- Non letti: `last_read_at` per membro → badge sulla tab Amici e sulla
  singola chat.

### App

- Lista conversazioni, chat con invio, pull di storia paginata (keyset su
  `created_at, id`, come il pull della sync), indicatore "offline:
  i messaggi arrivano quando torni online". Niente coda di invio offline
  in v1: senza rete il campo d'invio è disabilitato **con spiegazione**.
- Pressione lunga su un messaggio: **Elimina** (propri), **Segnala**
  (altrui: motivo + "blocca anche questo utente" proposto come opzione).
  Profilo di un amico: Rimuovi amico, Blocca, Segnala.

**Fatto quando**: due dispositivi chattano in tempo reale, interfaccia
nelle 8 lingue; test pgTAP di isolamento sulle tabelle chat (incluso:
nessuno legge le segnalazioni, nemmeno le proprie dopo l'invio; non si
segnala un messaggio di una chat di cui non si è membri); test manuale "il non membro non riceve
eventi Realtime" documentato.

---

## M-SOC4 — Spese divise e saldi

### Modello (server)

- `shared_expenses`: `id`, `created_by`, `paid_by`,
  `description`, `total_cents`, `currency` (ISO, solo valute a 2 decimali
  di `lib/core/currencies.dart`), `spent_on` (data), `created_at`,
  `updated_at`, `deleted_at`.
- `shared_expense_shares`: `shared_expense_id`, `user_id`, `share_cents`
  (> 0). Trigger **deferred** che verifica somma quote = totale.
- `settlements` (rimborsi): `id`, `from_user`, `to_user`, `amount_cents`,
  `currency`, `created_at`, `confirmed_at`. Il rimborso lo registra chi
  paga; il ricevente lo **conferma** (stesso spirito delle richieste di
  amicizia: nessuno può dichiarare di aver ricevuto soldi per un altro).
- Saldi: RPC `friend_balances()` → per ogni amico e per **ogni valuta**:
  quanto ti deve / quanto gli devi, da spese non cancellate meno rimborsi
  confermati. Saldi per valuta, senza conversioni automatiche lato
  server (le conversioni a tasso variabile farebbero "muovere" i debiti).

### Regole

- Partecipanti: chi crea la spesa più suoi **amici accettati** (non
  bloccati). Chi paga deve essere tra i partecipanti: chi crea oppure
  uno degli amici aggiunti.
- Modifica/eliminazione: solo `created_by`; gli altri partecipanti vedono
  la modifica in Amici (badge "spesa modificata") e possono aggiornare i
  movimenti registrati.
- Valuta: quella della spesa; ognuno vede la propria quota anche
  convertita nella valuta del proprio portafoglio (anteprima con
  `ExchangeRateService`, come nel foglio transazione).

### Modello contabile nei portafogli

Esempio: A paga una cena da 60 € per A, B, C (20 € a testa).

| Chi | Spesa (conta in statistiche e budget) | Movimento "con amici" (escluso dai totali) | Saldo del portafoglio (cumulato) |
|---|---|---|---|
| A (ha pagato) | −20 € "Ristoranti" | −40 € anticipo per B e C | −60 € (quanto è uscito davvero) |
| B (deve 20) | −20 € "Ristoranti" | +20 € debito verso A | 0 € (non ha ancora pagato) |
| B salda | — | −20 € rimborso ad A | −20 € |
| A riceve | — | +20 € rimborso da B | −40 € |

- Chi crea la spesa la sta già inserendo in un proprio portafoglio: al
  salvataggio i suoi movimenti (quota + "con amici") nascono lì, in
  automatico.
- Gli altri partecipanti vedono in Amici una card "Registra la tua quota
  (20 €) in [portafoglio ▾]": un tocco crea i due movimenti nel
  portafoglio scelto. Mai scritture automatiche nei portafogli altrui (i
  portafogli restano spazi isolati).
- Se ha pagato un amico, chi crea la spesa registra la propria quota come
  spesa e un "con amici" positivo (debito): il saldo del suo portafoglio
  non cambia finché non salda.
- Nuovo tipo di transazione locale `friend` ("con amici"): come
  `transfer` è **escluso** dai totali spese/entrate e dai budget, ma
  modifica il saldo. Impatto: enum Drift, check constraint Postgres,
  export JSON (bump `kExportSchemaVersion`), Excel, statistiche, filtri.
- Collegamento: colonna nullable `shared_expense_id` su `Transactions`
  (Drift **v8** + migration Postgres + sync), così modifica o
  cancellazione della spesa divisa propone di aggiornare i movimenti
  collegati.
- Test: property-based (`forAll`) sui saldi — per ogni sequenza di spese
  e rimborsi, la somma dei saldi tra tutti i partecipanti è zero e il
  saldo di ogni portafoglio corrisponde al denaro uscito/entrato.

### App — dal foglio "Nuova transazione"

Il flusso parte da una normale spesa:

1. Inserisco la transazione come oggi (tipo **Spesa**, importo totale,
   valuta, categoria, descrizione, data).
2. Nuova card **"Condividi con amici"** (solo con account e almeno un
   amico, solo per le spese): **+ Aggiungi amici** apre la lista dei miei
   amici con selezione multipla.
3. **Chi ha pagato?**: scelta singola tra "Io" e gli amici aggiunti
   (default "Io").
4. **Divisione**: parti uguali (default) oppure importi per persona; con
   importi personalizzati il foglio mostra quanto manca o avanza rispetto
   al totale e **Salva** spiega l'errore invece di disattivarsi (regola
   di CLAUDE.md).
5. Anteprima sotto: "Mario ti deve 20 €", "Devi 15 € a Luca".
6. **Salva**: crea prima la spesa divisa sul server, poi la transazione
   locale (la mia quota + il movimento "con amici"). Se il server
   rifiuta, non nasce nulla in locale e l'errore compare nel foglio.
   Senza rete la card "Condividi con amici" non è disponibile e lo dice
   ("Serve la connessione per condividere"): la spesa si può comunque
   salvare come spesa normale.

Il resto:
- Sezione Amici: saldo per amico ("Ti deve 20 €" / "Gli devi 15 $"),
  spese divise in comune, card "Registra la tua quota", **Salda**.
- Modifica di una transazione con spesa divisa: la card "Condividi con
  amici" è modificabile solo da chi l'ha creata.

**Fatto quando**: l'esempio della tabella, inserito dal foglio
transazione, torna identico su tre dispositivi reali; foglio e sezione
Amici nelle 8 lingue; test property-based dei saldi verdi; budget e
statistiche contano solo le quote.

---

## M-SOC5 — Hardening, cancellazione account, beta

- [ ] **Cancellazione account** (M-ACC7): al hard-delete dopo i 30 giorni
  → amicizie, blocchi, appartenenze e richieste cancellati; messaggi
  anonimizzati secondo la decisione sopra; spese divise e rimborsi
  restano con il partecipante anonimizzato; segnalazioni: chi ha
  segnalato viene anonimizzato, il messaggio segnalato resta leggibile
  al titolare solo finché la segnalazione è aperta. Export GDPR esteso a
  messaggi inviati, spese divise e rimborsi.
- [ ] **pgTAP** in `supabase/tests/`: isolamento di tutte le nuove
  tabelle (utente A / B / C esterno / anonimo), RPC che non si possono
  chiamare per conto d'altri, rate limit, blocchi.
- [ ] Rate limit verificati (codici, richieste, messaggi, segnalazioni).
- [ ] Addendum a [SECURITY_AUDIT.md](SECURITY_AUDIT.md) con revisione
  delle nuove superfici (RPC SECURITY DEFINER, Realtime, contenuti utente
  e segnalazioni).
- [ ] Migration applicate all'hosted PRIMA della build che le usa (come
  per `20261005*`); il workflow `hosted-migrations.yml` le controlla.
- [ ] Beta interna con i 4 membri del team: amicizie incrociate, un
  gruppo, una cena divisa e saldata.

---

## Fuori scope (rimandato esplicitamente)

- **Notifiche push** (FCM + APNs + Edge Function di invio): dopo l'account
  Apple Developer.
- Cifratura end-to-end dei messaggi.
- Allegati e foto nei messaggi, foto profilo.
- Coda di invio offline per messaggi e spese divise, e cache locale delle
  chat (in v1 chat e condivisione richiedono la rete).
- Conversione automatica dei debiti tra valute diverse ("semplifica
  debiti" multi-valuta).
- Spese divise mostrate come card dentro le chat (in v1 vivono nella
  sezione Amici).
- Ricerca utenti per nome o email (si diventa amici solo con QR o codice:
  niente directory pubblica degli utenti).
