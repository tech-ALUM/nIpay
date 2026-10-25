# Informativa sulla privacy di nIpay

> **Bozza del 2026-10-25, da far rivedere a un legale prima della
> pubblicazione.** Copre M-ACC0 (account e sincronizzazione) e M-SOC0
> (amici, chat, spese divise). Le note per chi la rivede sono in fondo.

**Ultimo aggiornamento:** {{DATA_PUBBLICAZIONE}}

## Dati del titolare

| | |
|---|---|
| Titolare del trattamento | {{RAGIONE_SOCIALE}} ("ALUM", "noi") |
| Sede legale | {{INDIRIZZO_SEDE}} |
| Partita IVA / C.F. | {{PARTITA_IVA}} |
| Contatto privacy | {{EMAIL_PRIVACY}} |

Non abbiamo nominato un responsabile della protezione dei dati (DPO): per
qualsiasi domanda scrivi al contatto privacy qui sopra.

## 1. In breve

- nIpay è un'app per tenere traccia di spese ed entrate. **Puoi usarla
  senza account**: in quel caso i dati restano solo sul tuo dispositivo e
  noi non riceviamo nulla.
- Se crei un account, i tuoi dati vengono **sincronizzati sui nostri
  server nell'Unione Europea** (Francoforte), così li ritrovi su altri
  dispositivi.
- Se usi **Amici**, alcune informazioni diventano visibili alle persone
  con cui ti colleghi (sezione 5).
- **Non vendiamo i tuoi dati, non mostriamo pubblicità e non usiamo
  strumenti di analisi o di tracciamento.**
- I messaggi della chat **non sono cifrati end-to-end** (sezione 9).

## 2. Quali dati trattiamo

### 2.1 Account

- **Email** e **password**. La password non la vediamo mai: la conserva il
  nostro fornitore in forma cifrata con un algoritmo a senso unico
  (hash).
- Data di creazione dell'account, ultimo accesso, conferma dell'email.
- Se chiedi di cancellare l'account, la **data della richiesta**.

### 2.2 Dati finanziari che inserisci

Sono sincronizzati solo se hai un account:

- **portafogli**: nome, colore, icona, valuta, saldo iniziale, ordine,
  archiviazione;
- **transazioni**: tipo, importo, data, categoria, descrizione, note,
  valuta e importo d'origine se diversi da quelli del portafoglio;
- **categorie, tag, budget, regole ricorrenti, configurazione della
  dashboard**;
- **campi personalizzati**: qualunque informazione tu scelga di
  aggiungere;
- **nota spese**: centri di costo, note spese e loro stato, indicazioni
  "rimborsabile" e "fattura elettronica".

I campi liberi (descrizioni, note, campi personalizzati) contengono ciò
che scrivi tu. **Ti chiediamo di non inserirvi dati sensibili**, ad
esempio sulla salute, né dati personali di altre persone.

### 2.3 Foto degli scontrini

Le foto che alleghi alle transazioni **restano sul tuo dispositivo**: oggi
non le carichiamo sui nostri server. Quando scegli una foto, l'app
rimuove la posizione GPS e gli altri metadati (EXIF). Se in futuro le
sincronizzeremo, aggiorneremo questa informativa prima di farlo.

### 2.4 Amici, chat e spese divise

Solo se usi queste funzioni:

- **profilo**: nome visualizzato e codice amico (un codice casuale che
  puoi rigenerare);
- **amicizie**: con chi sei amico, richieste inviate e ricevute, persone
  bloccate;
- **chat**: le conversazioni e i gruppi di cui fai parte, il tuo ruolo,
  i messaggi che invii e quando hai letto l'ultima volta una
  conversazione;
- **spese divise**: descrizione, importo totale, valuta, data, chi ha
  pagato, partecipanti e quote, rimborsi e loro stato;
- **segnalazioni** che invii: motivo, dettagli facoltativi, e la copia
  del messaggio segnalato.

### 2.5 Dati tecnici

- **Limiti di frequenza**: per prevenire abusi registriamo l'ora di
  alcune azioni, ad esempio quante richieste di amicizia invii. Ogni
  registrazione serve per al massimo 24 ore e viene cancellata entro il
  giorno successivo, e comunque insieme all'account.
- **Log del server**: il nostro fornitore registra, per motivi di
  sicurezza e funzionamento, indirizzo IP, ora e tipo di richiesta.
  Questi log restano per il breve periodo previsto dal suo servizio.
- **Tassi di cambio**: per convertire le valute l'app scarica i tassi
  pubblici da Frankfurter (api.frankfurter.dev), un servizio basato sui
  dati della Banca Centrale Europea. La richiesta non contiene alcun dato
  tuo; il servizio vede solo l'indirizzo IP del dispositivo, come
  qualsiasi sito web.

### 2.6 Cosa NON raccogliamo

Non raccogliamo la tua posizione, la rubrica, dati di utilizzo, dati per
la pubblicità o identificativi pubblicitari, né rapporti sugli arresti
anomali. **La fotocamera** serve solo a fotografare scontrini e a
leggere il codice QR di un amico: l'immagine del QR non viene salvata.

## 3. Perché li trattiamo e su quale base giuridica

| Finalità | Base giuridica (GDPR) |
|---|---|
| Creare e gestire l'account, sincronizzare i dati, far funzionare Amici, chat e spese divise | Esecuzione del contratto, cioè dei Termini d'uso (art. 6.1.b) |
| Sicurezza, prevenzione degli abusi, limiti di frequenza, log tecnici | Legittimo interesse a proteggere il servizio e gli utenti (art. 6.1.f) |
| Gestire le segnalazioni e moderare i contenuti | Legittimo interesse alla sicurezza degli utenti e obbligo di gestire contenuti illeciti (art. 6.1.f e 6.1.c) |
| Rispondere alle tue richieste sui diritti privacy | Obbligo di legge (art. 6.1.c) |

Non usiamo i tuoi dati per profilazione, decisioni automatizzate o
marketing.

## 4. Con chi li condividiamo

- **Supabase Inc.** ci fornisce database, autenticazione e server. È
  nostro **responsabile del trattamento** (art. 28 GDPR) in base al suo
  accordo sul trattamento dei dati (DPA,
  https://supabase.com/legal/dpa). I dati sono conservati nella **regione
  UE di Francoforte** (Germania), su infrastruttura Amazon Web Services.
  Se un sub-fornitore di Supabase accede ai dati da fuori dello Spazio
  Economico Europeo, il trasferimento è coperto dalle clausole
  contrattuali tipo della Commissione Europea incluse nel DPA.
- **Apple e Google** distribuiscono l'app tramite App Store e Google Play
  e trattano i dati del tuo account store come titolari autonomi, secondo
  le loro informative.
- **Autorità**, solo se un obbligo di legge ce lo impone.

Non cediamo i tuoi dati a nessun altro.

## 5. Cosa vedono gli altri utenti

- Chi conosce il tuo **codice amico** (perché glielo hai mostrato o
  inviato) può vedere il tuo **nome visualizzato** e mandarti una
  richiesta di amicizia. Il codice non permette di cercarti per nome o
  email: la tua email non è mai visibile agli altri.
- I tuoi **amici** vedono il tuo nome visualizzato e da quando siete
  amici.
- Chi è nelle tue **chat** vede i messaggi che invii. In un gruppo, chi
  entra dopo vede solo i messaggi successivi al suo ingresso.
- I partecipanti di una **spesa divisa** vedono descrizione, totale,
  data, chi ha pagato, le quote di ciascuno e se ciascuno ha registrato
  la propria quota. Tra due persone sono visibili i rimborsi che le
  riguardano.
- Se **blocchi** qualcuno, non lo sa. Nei gruppi che avete in comune
  restate entrambi, ma i suoi messaggi per te spariscono.
- Le **segnalazioni** sono riservate: la persona segnalata non sa chi
  l'ha segnalata.
- **I tuoi dati finanziari personali** (portafogli, transazioni, budget e
  così via) non sono mai visibili agli altri utenti. Lo sono solo le
  spese che scegli di dividere.

## 6. Per quanto tempo li conserviamo

| Dati | Conservazione |
|---|---|
| Account, dati finanziari, profilo, amicizie | Finché hai l'account |
| Messaggi | Finché esiste l'account di chi li ha inviati |
| Testo di un messaggio che hai eliminato | 90 giorni dall'eliminazione, solo per la moderazione; gli altri vedono subito "Messaggio eliminato" |
| Copia del messaggio in una segnalazione | Finché la segnalazione è aperta; quando la chiudiamo, la copia viene cancellata |
| Segnalazioni chiuse (senza testo) | Finché esiste l'account di chi le ha inviate |
| Limiti di frequenza | Al massimo 2 giorni |
| Log tecnici del fornitore | Il breve periodo previsto dal servizio Supabase |

### Cancellazione dell'account

Puoi cancellare l'account dall'app (Account → Elimina account).
Dopo la richiesta:

1. Per **30 giorni** l'account resta in attesa: puoi ripensarci e
   annullare la cancellazione accedendo di nuovo. In questo periodo puoi
   solo leggere i tuoi dati e saldare i debiti con gli amici: non puoi
   mandare messaggi, aggiungere amici, entrare in chat o creare spese
   divise.
2. Allo scadere dei 30 giorni cancelliamo **definitivamente** l'account e
   tutti i dati collegati: dati finanziari, profilo, amicizie, blocchi,
   appartenenza alle chat, testi dei messaggi.
3. Alcune informazioni condivise restano agli altri, **senza più alcun
   collegamento a te**, perché fanno parte dei loro conti: nelle spese
   divise e nei rimborsi restano gli importi, ma il tuo nome sparisce.
   Nelle chat i tuoi messaggi restano come messaggi di un utente
   cancellato, senza testo.

I dati che hai sul dispositivo li controlli tu: uscendo dall'account puoi
scegliere di rimuoverli, oppure disinstallare l'app.

## 7. I tuoi diritti

Hai il diritto di:

- **accedere** ai tuoi dati e riceverne copia (art. 15);
- **correggerli** (art. 16): molti li modifichi direttamente nell'app,
  ad esempio il nome visualizzato;
- **cancellarli** (art. 17): dall'app, come descritto sopra;
- **limitarne il trattamento** (art. 18);
- riceverli in un **formato leggibile da una macchina** (portabilità,
  art. 20): su richiesta ti mandiamo un file JSON con tutti i tuoi dati,
  social compresi;
- **opporti** ai trattamenti basati sul legittimo interesse (art. 21).

Per esercitarli scrivi a {{EMAIL_PRIVACY}} dall'email del tuo account. Ti
rispondiamo entro un mese. Possiamo chiederti di confermare la tua
identità prima di consegnare dei dati.

Hai anche il diritto di presentare reclamo al **Garante per la protezione
dei dati personali** (www.garanteprivacy.it) o all'autorità del paese UE
in cui vivi.

## 8. Età minima

nIpay con account è riservato a chi ha **almeno 16 anni**. Se scopriamo
che un account appartiene a una persona più giovane, lo cancelliamo. Se
sei un genitore e pensi che tuo figlio abbia creato un account, scrivici.

## 9. Sicurezza

- Le comunicazioni tra l'app e i server sono **cifrate (HTTPS/TLS)**.
- I dati sui server sono **cifrati a riposo** dal nostro fornitore e ogni
  utente può leggere solo i propri dati, grazie a regole di accesso
  applicate dal database stesso.
- Le credenziali di accesso sono salvate nell'archivio sicuro del
  dispositivo (Portachiavi su iOS, Keystore su Android).
- **I messaggi non sono cifrati end-to-end.** Sono cifrati durante
  l'invio e sui server, ma tecnicamente chi gestisce il servizio potrebbe
  leggerli. **Non lo facciamo**, tranne nel caso di un messaggio che ci
  viene **segnalato**: per decidere sulla segnalazione leggiamo quel
  messaggio. Per lo stesso motivo il testo di un messaggio eliminato
  resta accessibile a noi per 90 giorni.
- Il database locale dell'app è protetto dalla cifratura del dispositivo
  (attiva quando il telefono è bloccato con un codice), non da una
  cifratura propria dell'app.

Nessun sistema è sicuro al 100%. Se si verifica una violazione che mette a
rischio i tuoi dati, la notifichiamo al Garante e, se richiesto, a te.

## 10. Modifiche

Se cambiamo questa informativa in modo rilevante, te lo diciamo nell'app
prima che le modifiche si applichino. La data in cima indica l'ultima
versione.

---

## Note per la revisione legale (da togliere prima della pubblicazione)

1. **Base giuridica.** Il piano M-ACC0 diceva "consenso esplicito
   all'attivazione dell'account". La bozza usa invece l'**esecuzione del
   contratto** (art. 6.1.b) per il servizio: il consenso è revocabile in
   ogni momento e mal si adatta a dati necessari a far funzionare l'app.
   La casella da spuntare alla registrazione resta: serve ad accettare i
   Termini e a confermare di aver letto l'informativa e di avere almeno
   16 anni. Da confermare con il legale.
2. **Età minima 16 anni** (decisione 2026-10-25): soglia GDPR di default,
   valida in tutta l'UE. L'app oggi non chiede l'età: va aggiunta la
   dichiarazione alla registrazione.
3. **Moderazione**: le segnalazioni si gestiscono dalla dashboard di
   Supabase. Serve una procedura scritta, con chi le legge, entro quanto
   tempo e quali azioni si prendono; i Termini promettono 24 ore.
4. **Digital Services Act**: nIpay ospita contenuti degli utenti (chat),
   quindi rientra tra i servizi di hosting. Verificare gli obblighi
   minimi: punto di contatto, motivazione delle rimozioni.
5. **Log Supabase**: la durata dipende dal piano; sul piano gratuito è
   breve, ma va verificata e, se possibile, indicata con un numero.
6. **Trasferimenti extra-UE**: confermare l'elenco dei sub-fornitori
   Supabase (https://supabase.com/legal/subprocessors) e iscriversi alle
   notifiche dei cambi (M-ACC0).
7. Compilare il blocco **Dati del titolare** e il **contatto privacy**:
   deve essere una casella letta davvero, perché i termini di legge
   decorrono dalla ricezione.
