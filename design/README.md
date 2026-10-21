# nIpay — Design system (M1)

Mini design-system per la review del team prima dell'implementazione della UI Flutter.
Basato sulla **brand identity ALUM** (coral `#FF6F61`, teal `#0E7C86`, ink `#15181D`,
paper `#F7F8FA`; font Space Grotesk / Inter / JetBrains Mono).

Ogni file si apre con doppio click nel browser (nessun server necessario).

## Contenuto

| File | Cosa mostra |
|---|---|
| `foundation/colors.html` | Palette ALUM + token semantici (spesa=coral, entrata=teal, trasferimento=grigio, warning budget) |
| `foundation/typography.html` | Scala tipografica di Bold Ink (oggi: vedi "Ink Aurora" sotto) |
| `mockups/home.html` | Home: saldo totale (banda ink), card portafogli, budget del mese, ultime transazioni, FAB coral |
| `mockups/transactions.html` | Lista transazioni: ricerca, chip filtri, raggruppamento per giorno con totale, tag |
| `mockups/add-transaction.html` | Inserimento: segmented Spesa/Entrata/Trasferimento, griglia categorie, campi custom, foto scontrino |
| `mockups/dashboard.html` | Statistiche: dashboard componibile (drag handle ⠿ + config ⚙ per card, "+ Aggiungi card") |

## Regole chiave

- Coral è l'accento primario (FAB, CTA, spese) — deliberato, non ovunque; teal il secondario (entrate, selezioni).
- Importi **sempre** con `moneyStyle` (oggi Space Grotesk, cifre tabulari; nei mockup M1 JetBrains Mono), colorati per tipo. I trasferimenti sono neutri e senza segno.
- Titoli e testo: vedi "Ink Aurora" sotto (nei mockup M1: Space Grotesk / Inter).
- Dark mode: paper→ink come sfondo, superfici `#1E222A` (da definire in fase tema Flutter).

## Direzione scelta

**A — Bold Ink** (scelta di Alberto, 2026-07-15), in **doppio tema switchabile in-app**:
dark (`directions/a-bold-ink.html`) come identità principale + light
(`directions/a-bold-ink-light.html`) con la stessa personalità. In Flutter:
`ThemeData` dark + light e toggle `ThemeMode` (sistema/chiaro/scuro) nelle impostazioni.
Le altre direzioni (B, C) restano come riferimento storico.

### Evoluzione: Ink Aurora (2026-10-21)

Stessi colori del brand e stesso doppio tema, con più profondità e
movimento (solo presentazione, nessun cambio di funzionalità):

- **Gradienti**: CTA e FAB coral → magenta `#FF3D7F` (ink sopra, 5.3:1);
  banda saldo con mesh indigo → ink → teal profondo e bagliori coral/cyan.
- **Profondità**: sfondo dark più scuro (`#0B0E14`), card in rilievo con
  ombre a strati, card portafoglio con ombra del proprio colore.
- **Font**: titoli Bricolage Grotesque, testo Plus Jakarta Sans, importi
  Space Grotesk (sostituiscono Manrope / Inter / Nunito del 2026-10-07).
- **Movimento**: ingresso a cascata, feedback al tocco, saldo che scorre,
  dissolvenza tra le tab; tutto spento con "Riduci movimento".

I mockup in questa cartella restano quelli di Bold Ink: il riferimento
aggiornato è il tema Flutter (`lib/core/theme/app_theme.dart`).

## Review

Commenti del team: issue GitHub sul repo o direttamente ad Alberto.
Questi mockup verranno caricati anche su Claude Design (claude.ai/design) come
progetto "nIpay" appena autorizzato l'accesso da una sessione interattiva.
Dopo l'approvazione, il design viene tradotto in `ThemeData` Flutter (`lib/core/theme/app_theme.dart`).
