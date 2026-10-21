-- nIpay — ruolo in sola lettura per il controllo "migration non applicate"
-- (.github/workflows/hosted-migrations.yml).
--
-- Il 2026-10-21 la sync era bloccata da due settimane perché le migration
-- 20260913* e 20261005* non erano mai state applicate al progetto hosted.
-- La CI ora confronta ogni giorno supabase/migrations/ con le migration
-- registrate sull'hosted, collegandosi con questo ruolo.
--
-- Privilegio minimo (come il GITHUB_TOKEN, SECURITY_AUDIT NIP-20): può solo
-- fare login e leggere supabase_migrations.schema_migrations, nessun
-- accesso ai dati degli utenti, ad Auth o a Storage. Creato SENZA
-- password: finché non la si imposta a mano dal SQL editor (mai in una
-- migration, finirebbe in git) il login è impossibile.

do $$
begin
  if not exists (
    select 1 from pg_catalog.pg_roles where rolname = 'ci_migrations_reader'
  ) then
    create role ci_migrations_reader
      with login noinherit nocreatedb nocreaterole noreplication
      connection limit 2;
  end if;
end;
$$;

alter role ci_migrations_reader set statement_timeout = '10s';
alter role ci_migrations_reader set default_transaction_read_only = on;

grant usage on schema supabase_migrations to ci_migrations_reader;
grant select on supabase_migrations.schema_migrations to ci_migrations_reader;
