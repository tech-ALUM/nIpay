#!/usr/bin/env bash
# Controlla che ogni migration in supabase/migrations/ sia applicata al
# progetto Supabase hosted. Unica fonte di verità: usato sia in locale sia
# dalla CI (.github/workflows/hosted-migrations.yml).
#
# Si collega col ruolo in sola lettura ci_migrations_reader
# (supabase/migrations/20261021000000_ci_migrations_reader.sql), che vede
# solo supabase_migrations.schema_migrations. Non applica nulla: segnala.
#
# Uso:
#   HOSTED_MIGRATIONS_DB_URL='postgresql://ci_migrations_reader.<ref>:<password>@<pooler>:5432/postgres' \
#     ./scripts/check_hosted_migrations.sh
#
# Esce con 1 (e l'elenco) se nel repo c'è una migration non applicata.
set -euo pipefail

cd "$(dirname "${BASH_SOURCE[0]}")/.."

if [[ -z "${HOSTED_MIGRATIONS_DB_URL:-}" ]]; then
  echo "::error::HOSTED_MIGRATIONS_DB_URL non impostata" >&2
  exit 2
fi

workdir="$(mktemp -d)"
trap 'rm -rf "$workdir"' EXIT

# Versione = prefisso numerico del nome file (20261005000000_xxx.sql).
for f in supabase/migrations/*.sql; do
  basename "$f" | cut -d_ -f1
done | sort -u >"$workdir/repo"

psql "$HOSTED_MIGRATIONS_DB_URL" -v ON_ERROR_STOP=1 -X -q -t -A \
  -c 'select version from supabase_migrations.schema_migrations' \
  | sort -u >"$workdir/hosted"

missing="$(comm -23 "$workdir/repo" "$workdir/hosted")"
unknown="$(comm -13 "$workdir/repo" "$workdir/hosted")"

# Applicata sull'hosted ma assente dal repo: qualcuno l'ha creata altrove
# (dashboard, altro branch). Non blocca, ma va riportata nel repo.
for v in $unknown; do
  echo "::warning::$v è applicata all'hosted ma non esiste in supabase/migrations/"
done

if [[ -n "$missing" ]]; then
  for v in $missing; do
    echo "::error::$v non è applicata al progetto hosted"
  done
  echo "Applicarle con: supabase db push (dalla cartella del progetto, collegato all'hosted)" >&2
  exit 1
fi

echo "OK: tutte le $(wc -l <"$workdir/repo" | tr -d ' ') migration del repo sono applicate all'hosted."
