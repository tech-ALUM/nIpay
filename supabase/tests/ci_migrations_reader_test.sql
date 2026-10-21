-- nIpay — il ruolo della CI (20261021000000_ci_migrations_reader.sql) legge
-- solo l'elenco delle migration, nient'altro.
--
-- Gira su un Supabase locale (Docker), mai sul progetto reale:
--   supabase start && supabase test db

begin;
create extension if not exists pgtap with schema extensions;
select plan(4);

select has_role('ci_migrations_reader');

select ok(
  has_table_privilege(
    'ci_migrations_reader', 'supabase_migrations.schema_migrations', 'select'
  ),
  'ci_migrations_reader legge l''elenco delle migration'
);

select ok(
  not has_table_privilege(
    'ci_migrations_reader', 'supabase_migrations.schema_migrations',
    'insert, update, delete, truncate'
  ),
  'ci_migrations_reader non modifica l''elenco delle migration'
);

select is(
  (
    select pg_catalog.count(*)::int
    from pg_catalog.pg_tables
    where schemaname in ('public', 'auth', 'storage', 'private')
      and has_table_privilege(
        'ci_migrations_reader',
        format('%I.%I', schemaname, tablename),
        'select, insert, update, delete'
      )
  ),
  0,
  'ci_migrations_reader non accede a nessuna tabella di dati, Auth o Storage'
);

select * from finish();
rollback;
