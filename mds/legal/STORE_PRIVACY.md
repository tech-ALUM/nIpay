# Store: dichiarazioni privacy ed età (M-ACC0 + M-SOC0)

Bozza del 2026-10-25. Le risposte vengono da cosa fa davvero l'app oggi
(stessa base dell'[informativa](privacy-policy.it.md)). Se l'app cambia
(foto scontrini sincronizzate, login con Google/Apple, analytics),
queste risposte vanno riviste insieme all'informativa.

**Le dichiarazioni del 2026-08-09 ("nessun dato raccolto") non valgono
più**: con account, sincronizzazione e Amici l'app raccoglie dati.

## Cosa serve prima di compilare

1. **Due indirizzi web pubblici**, uno per l'informativa e uno per i
   termini, in italiano e in inglese: le bozze in questa cartella, riviste
   dal legale e con i dati del titolare compilati.
2. **Un indirizzo web per la cancellazione dell'account**, che Google
   Play chiede. Può essere una sezione dell'informativa che spiega:
   - come cancellarlo dall'app;
   - che in alternativa si può scrivere al contatto privacy;
   - quali dati vengono cancellati e dopo quanto (30 giorni).
3. **Un account di prova** per i revisori, con almeno un amico e una chat,
   così vedono le funzioni social e le segnalazioni.

## App Store Connect → App Privacy

**Data Collection:** "Yes, we collect data from this app".

Per ogni tipo qui sotto rispondi:

- **Linked to the user's identity**: Yes. Ogni dato è legato
  all'account.
- **Used for tracking**: No. Non c'è niente di questo tipo nell'app.
- **Purpose**: App Functionality, che per Apple comprende anche sicurezza
  e prevenzione degli abusi.

| Categoria Apple | Tipo | Perché |
|---|---|---|
| Contact Info | **Name** | nome visualizzato in Amici |
| Contact Info | **Email Address** | account |
| Financial Info | **Other Financial Info** | transazioni, budget, spese divise, rimborsi sincronizzati |
| Contacts | **Contacts** | Apple vi fa rientrare il "social graph": amici, richieste, blocchi |
| User Content | **Emails or Text Messages** | messaggi della chat |
| User Content | **Other User Content** | note, campi personalizzati, nomi dei gruppi, segnalazioni |
| Identifiers | **User ID** | id dell'account e codice amico |

**Da NON dichiarare** (non raccolti):
- Photos or Videos: gli scontrini restano sul dispositivo;
- Location;
- Usage Data;
- Diagnostics;
- Purchases;
- Device ID;
- Health;
- Browsing e Search History.

**Privacy Policy URL**: l'indirizzo dell'informativa.

## Google Play Console → Contenuti dell'app → Sicurezza dei dati

**Raccolta e condivisione:**
- **L'app raccoglie o condivide dati?** Sì.
- **Tutti i dati sono criptati in transito?** Sì.
- **Gli utenti possono chiedere la cancellazione?** Sì, dall'app e
  all'indirizzo web della cancellazione.

Per ogni tipo qui sotto rispondi:
- **Raccolto** sì, **Condiviso** no. Supabase è un fornitore di servizi e
  per Google non conta come condivisione.
- **Trattato in modo temporaneo** no.
- **Facoltativo**: Sì. L'app si usa anche senza account, quindi ogni
  raccolta è facoltativa.

| Categoria Google | Tipo | Finalità |
|---|---|---|
| Informazioni personali | **Nome** | Funzionalità dell'app |
| Informazioni personali | **Indirizzo email** | Funzionalità dell'app, Gestione dell'account |
| Informazioni personali | **ID utente** | Funzionalità dell'app, Gestione dell'account |
| Informazioni finanziarie | **Altre informazioni finanziarie** | Funzionalità dell'app |
| Messaggi | **Altri messaggi in-app** | Funzionalità dell'app |
| Attività nelle app | **Altri contenuti generati dagli utenti** | Funzionalità dell'app; Prevenzione di frodi, sicurezza e conformità (segnalazioni) |

**Da NON dichiarare:**
- Foto: elaborate solo sul dispositivo, Google non le conta come
  raccolta;
- Posizione;
- Contatti: per Google sono la rubrica del telefono, che l'app non legge;
- Informazioni sull'app e sulle prestazioni;
- ID dispositivo;
- Cronologia web.

**Norme sulla privacy**: l'indirizzo dell'informativa.

**Cancellazione dell'account** (Contenuti dell'app → Eliminazione
dell'account): l'indirizzo web della cancellazione.

## Età e classificazione

Decisione 2026-10-25: **età minima 16 anni** per l'account.

- **App Store** (App Information → Age Rating):
  - nel questionario rispondi Sì a **contenuti generati dagli utenti** e
    a **messaggi e chat** tra utenti;
  - se il risultato è sotto 16+, alza la classificazione a **16+**,
    perché coincida con i Termini.
- **Google Play**:
  - **Pubblico di destinazione**: seleziona solo le fasce dai 16 anni in
    su, mai quelle sotto i 13 (altrimenti scattano le norme Famiglie);
  - **Classificazione dei contenuti (IARC)**: rispondi Sì a "gli utenti
    possono interagire o scambiarsi contenuti".

## Note per la revisione Apple

Da scrivere in App Review Information → Notes:

- La chat è possibile solo tra **amici accettati**: ci si aggiunge
  scambiando un codice o un QR, non c'è ricerca pubblica.
- Ci sono **segnala** (messaggio e utente) e **blocca**. Le segnalazioni
  sono esaminate entro 24 ore e i Termini prevedono la tolleranza zero.
- La cancellazione dell'account è nell'app: Account → Elimina account.
- Credenziali dell'account di prova e nome dell'amico già collegato.

## Supabase (M-ACC0)

- Archivia una copia del DPA (https://supabase.com/legal/dpa) con la data
  di creazione del progetto.
- Iscriviti alle notifiche sui cambi dei sub-fornitori, dalla stessa
  pagina legale.
- Attiva la protezione dalle password trapelate (Authentication →
  Policies), che è ancora segnalata dal Security Advisor.
