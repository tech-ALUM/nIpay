# nIpay — istruzioni per Claude Code

Progetto **[ALUM]**: app Flutter iOS+Android per tracciamento spese/entrate multi-portafoglio.
Team: Alberto Boffi, Francesco Miccoli, Tommaso Panseri, Paolo Gnata.

## Memoria (Open Brain)
- Cassetto: **openbrain-alum** (condiviso col team — MAI usare openbrain-priv per questo repo).
- Tag per i ricordi: `["ALUM", "nipay"]`.
- Source per i ricordi salvati: `claude-code:nIpay`.
- All'inizio di un task, cerca contesto con `search_thoughts` su openbrain-alum (tag `nipay`).
- Salvare ricordi SOLO su richiesta esplicita.

## Documenti di riferimento
- [OVERVIEW.md](OVERVIEW.md) — visione, decisioni, architettura, modello dati (fonte: brainstorming 2026-07-15).
- [STEPS.md](STEPS.md) — piano a milestone M0–M9. Aggiornare le checkbox man mano.

## Regole di progetto
- Stack: Flutter + Riverpod + Drift. La UI non accede mai a Drift direttamente: sempre attraverso i repository.
- Ogni tabella: `id` UUID, `createdAt`, `updatedAt`, `deletedAt` (soft-delete). Niente cancellazioni fisiche.
- Importi in **centesimi (int)**, valuta solo EUR.
- Stringhe UI sempre in l10n (arb IT + EN), mai hardcoded.
- Niente skill/template Dewesoft in questo repo (è [ALUM]).
- Git: remote via alias `github.com-alum`; identità folder-based già corretta (albertoboffi-ALUM).
