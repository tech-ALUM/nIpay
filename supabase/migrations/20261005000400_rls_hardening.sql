-- nIpay — hardening RLS/Postgres (SECURITY_AUDIT.md NIP-21)
--
--   * le funzioni owns_* erano nello schema public, quindi chiamabili come
--     RPC anche da anon: si spostano in `private` (non esposto da
--     PostgREST). Le policy le referenziano per OID, quindi continuano a
--     funzionare senza essere ricreate;
--   * tutte le policy valevano anche per anon: ora solo `to authenticated`;
--   * search_path vuoto e nomi qualificati nelle funzioni;
--   * le funzioni create in futuro nello schema public non sono più
--     eseguibili da anon per default.

alter function public.owns_wallet(uuid) set schema private;
alter function public.owns_transaction(uuid) set schema private;
alter function public.owns_tag(uuid) set schema private;
alter function public.owns_custom_field(uuid) set schema private;

create or replace function private.owns_wallet(target_wallet_id uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.wallets w
    where w.id = target_wallet_id and w.owner_user_id = (select auth.uid())
  );
$$;

create or replace function private.owns_transaction(target_transaction_id uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.transactions t
    join public.wallets w on w.id = t.wallet_id
    where t.id = target_transaction_id and w.owner_user_id = (select auth.uid())
  );
$$;

create or replace function private.owns_tag(target_tag_id uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.tags g
    join public.wallets w on w.id = g.wallet_id
    where g.id = target_tag_id and w.owner_user_id = (select auth.uid())
  );
$$;

create or replace function private.owns_custom_field(target_field_id uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.custom_field_defs f
    join public.wallets w on w.id = f.wallet_id
    where f.id = target_field_id and w.owner_user_id = (select auth.uid())
  );
$$;

revoke all on function private.owns_wallet(uuid) from public, anon;
revoke all on function private.owns_transaction(uuid) from public, anon;
revoke all on function private.owns_tag(uuid) from public, anon;
revoke all on function private.owns_custom_field(uuid) from public, anon;
grant execute on function private.owns_wallet(uuid) to authenticated, service_role;
grant execute on function private.owns_transaction(uuid) to authenticated, service_role;
grant execute on function private.owns_tag(uuid) to authenticated, service_role;
grant execute on function private.owns_custom_field(uuid) to authenticated, service_role;

-- Trigger di signup: search_path vuoto, nomi qualificati.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;
revoke all on function public.handle_new_user() from public, anon, authenticated;
revoke all on function public.sync_stamp() from public, anon, authenticated;

-- Tutte le policy dell'app (public + le policy degli allegati in storage)
-- solo per utenti autenticati.
do $$
declare
  p record;
begin
  for p in
    select schemaname, tablename, policyname
    from pg_policies
    where schemaname = 'public'
       or (schemaname = 'storage' and tablename = 'objects'
           and policyname like '% own attachment files')
  loop
    execute format('alter policy %I on %I.%I to authenticated',
                   p.policyname, p.schemaname, p.tablename);
  end loop;
end;
$$;

-- Default per le funzioni future dello schema public: niente EXECUTE
-- implicito per anon/PUBLIC (vanno concesse esplicitamente).
alter default privileges in schema public revoke execute on functions from public;
alter default privileges in schema public revoke execute on functions from anon;
