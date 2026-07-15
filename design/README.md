# nIpay — Design system (M1)

Mini design-system per la review del team prima dell'implementazione della UI Flutter.
Basato sulla **brand identity ALUM** (coral `#FF6F61`, teal `#0E7C86`, ink `#15181D`,
paper `#F7F8FA`; font Space Grotesk / Inter / JetBrains Mono).

Ogni file si apre con doppio click nel browser (nessun server necessario).

## Contenuto

| File | Cosa mostra |
|---|---|
| `foundation/colors.html` | Palette ALUM + token semantici (spesa=coral, entrata=teal, trasferimento=grigio, warning budget) |
| `foundation/typography.html` | Scala tipografica; importi sempre in JetBrains Mono |
| `mockups/home.html` | Home: saldo totale (banda ink), card portafogli, budget del mese, ultime transazioni, FAB coral |
| `mockups/transactions.html` | Lista transazioni: ricerca, chip filtri, raggruppamento per giorno con totale, tag |
| `mockups/add-transaction.html` | Inserimento: segmented Spesa/Entrata/Trasferimento, griglia categorie, campi custom, foto scontrino |
| `mockups/dashboard.html` | Statistiche: dashboard componibile (drag handle ⠿ + config ⚙ per card, "+ Aggiungi card") |

## Regole chiave

- Coral è l'accento primario (FAB, CTA, spese) — deliberato, non ovunque; teal il secondario (entrate, selezioni).
- Importi **sempre** JetBrains Mono, colorati per tipo. I trasferimenti sono neutri e senza segno.
- Titoli Space Grotesk, testo Inter.
- Dark mode: paper→ink come sfondo, superfici `#1E222A` (da definire in fase tema Flutter).

## Direzione scelta

**A — Bold Ink** (scelta di Alberto, 2026-07-15), in **doppio tema switchabile in-app**:
dark (`directions/a-bold-ink.html`) come identità principale + light
(`directions/a-bold-ink-light.html`) con la stessa personalità. In Flutter:
`ThemeData` dark + light e toggle `ThemeMode` (sistema/chiaro/scuro) nelle impostazioni.
Le altre direzioni (B, C) restano come riferimento storico.

## Review

Commenti del team: issue GitHub sul repo o direttamente ad Alberto.
Questi mockup verranno caricati anche su Claude Design (claude.ai/design) come
progetto "nIpay" appena autorizzato l'accesso da una sessione interattiva.
Dopo l'approvazione, il design viene tradotto in `ThemeData` Flutter (vedi STEPS.md, M1).
