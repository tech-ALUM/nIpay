# nIpay

App mobile (iOS + Android) per il tracciamento di spese ed entrate multi-portafoglio — progetto ALUM.

- **Visione e decisioni**: [OVERVIEW.md](OVERVIEW.md)
- **Piano di implementazione**: [STEPS.md](STEPS.md)

## Stack

Flutter · Riverpod · Drift (SQLite) · fl_chart · go_router · l10n IT+EN

## Sviluppo

```bash
flutter pub get
flutter gen-l10n        # genera lib/l10n/app_localizations*.dart
flutter analyze
flutter test
flutter run             # dispositivo/emulatore Android collegato
```

Build APK debug: `flutter build apk --debug` (output in `build/app/outputs/flutter-apk/`).

Versione Flutter di riferimento: **3.44.6 stable** (la stessa usata in CI, vedi `.github/workflows/ci.yml`).

## Struttura

```
lib/
  core/       # tema, utilità, costanti
  data/       # schema Drift, repository (la UI non tocca mai Drift direttamente)
  features/   # una cartella per feature (wallets, transactions, stats, ...)
  l10n/       # arb IT+EN + file generati
```

Convenzioni chiave (dettagli in [CLAUDE.md](CLAUDE.md)): importi in centesimi (int), record con UUID + soft-delete (sync-ready), stringhe UI sempre in l10n.
