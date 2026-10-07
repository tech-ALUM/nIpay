-- nIpay — cancellazione account controllata dal server (SECURITY_AUDIT.md NIP-05)
--
-- Prima: il client scriveva deletion_requested_at con l'ora del device e la
-- policy "update own profile" permetteva qualunque valore. Con una sessione
-- rubata bastava `deletion_requested_at = '2000-01-01'` perché il job di
-- purge cancellasse l'account entro 24 ore, saltando i 30 giorni.
--
-- Ora:
--   * il ruolo authenticated non può più modificare profiles direttamente;
--   * la richiesta passa da request_account_deletion(): l'ora la decide il
--     server (now()) e serve un'autenticazione recente (password reinserita
--     negli ultimi 10 minuti, claim `amr` del JWT), così un token rubato o
--     un telefono lasciato sbloccato non bastano;
--   * cancel_account_deletion() annulla la richiesta;
--   * ogni evento finisce in un audit log non esposto via API.

-- ---------------------------------------------------------------------
-- Audit log (schema private: non esposto da PostgREST, nessun accesso per
-- anon/authenticated). Nessuna FK verso auth.users: deve sopravvivere
-- alla cancellazione dell'utente.
-- ---------------------------------------------------------------------
create table private.account_audit_log (
  id bigint generated always as identity primary key,
  at timestamptz not null default now(),
  user_id uuid not null,
  event text not null check (char_length(event) <= 64),
  details jsonb
);
alter table private.account_audit_log enable row level security;
revoke all on private.account_audit_log from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- profiles: niente più update diretto dal client.
-- ---------------------------------------------------------------------
drop policy "update own profile" on profiles;
revoke insert, update, delete on profiles from anon, authenticated;

-- ---------------------------------------------------------------------
-- Autenticazione recente: il claim `amr` del JWT di Supabase contiene
-- [{"method": "password"|"otp"|"recovery"|..., "timestamp": <epoch>}] con
-- l'istante dell'ultima autenticazione esplicita. Il refresh del token non
-- lo aggiorna: solo un nuovo login (o un link di recupero) lo fa.
-- ---------------------------------------------------------------------
create or replace function private.authenticated_within(max_age interval)
returns boolean
language sql
stable
set search_path = ''
as $$
  select coalesce(
    (
      select pg_catalog.max((e ->> 'timestamp')::bigint)
      from pg_catalog.jsonb_array_elements(
        case
          when pg_catalog.jsonb_typeof(auth.jwt() -> 'amr') = 'array'
            then auth.jwt() -> 'amr'
          else '[]'::jsonb
        end
      ) e
      where (e ->> 'timestamp') ~ '^[0-9]{1,12}$'
    ) >= extract(epoch from (pg_catalog.now() - max_age))::bigint,
    false
  );
$$;
revoke all on function private.authenticated_within(interval) from public, anon;
grant execute on function private.authenticated_within(interval) to authenticated, service_role;

create or replace function public.request_account_deletion()
returns timestamptz
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  requested timestamptz;
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  if not private.authenticated_within(interval '10 minutes') then
    raise exception 'riautenticazione richiesta'
      using errcode = '42501', hint = 'reauthentication_required';
  end if;

  -- coalesce: una seconda richiesta non sposta in avanti la data.
  update public.profiles
     set deletion_requested_at = coalesce(deletion_requested_at, pg_catalog.now())
   where id = uid
  returning deletion_requested_at into requested;

  insert into private.account_audit_log (user_id, event)
  values (uid, 'deletion_requested');
  return requested;
end;
$$;

create or replace function public.cancel_account_deletion()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  update public.profiles set deletion_requested_at = null where id = uid;
  insert into private.account_audit_log (user_id, event)
  values (uid, 'deletion_canceled');
end;
$$;

revoke all on function public.request_account_deletion() from public, anon;
revoke all on function public.cancel_account_deletion() from public, anon;
grant execute on function public.request_account_deletion() to authenticated;
grant execute on function public.cancel_account_deletion() to authenticated;

-- ---------------------------------------------------------------------
-- Supporto alla Edge Function di purge (NIP-06, NIP-19): eseguibili solo
-- con la service_role key.
-- ---------------------------------------------------------------------

-- Account con grace period scaduto, i più vecchi prima, con un tetto.
create or replace function public.purge_candidates(max_accounts integer)
returns table (user_id uuid, deletion_requested_at timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select p.id, p.deletion_requested_at
  from public.profiles p
  where p.deletion_requested_at is not null
    and p.deletion_requested_at <= pg_catalog.now() - interval '30 days'
  order by p.deletion_requested_at
  limit greatest(0, least(max_accounts, 1000));
$$;

-- Oggetti Storage residui dell'utente (verifica prima di deleteUser).
create or replace function public.count_user_storage_objects(target_user uuid)
returns bigint
language sql
stable
security definer
set search_path = ''
as $$
  select pg_catalog.count(*)
  from storage.objects o
  where o.bucket_id = 'attachments'
    and o.name like target_user::text || '/%';
$$;

create or replace function public.log_account_event(
  target_user uuid, event text, details jsonb default null
)
returns void
language sql
security definer
set search_path = ''
as $$
  insert into private.account_audit_log (user_id, event, details)
  values (target_user, event, details);
$$;

revoke all on function public.purge_candidates(integer) from public, anon, authenticated;
revoke all on function public.count_user_storage_objects(uuid) from public, anon, authenticated;
revoke all on function public.log_account_event(uuid, text, jsonb) from public, anon, authenticated;
grant execute on function public.purge_candidates(integer) to service_role;
grant execute on function public.count_user_storage_objects(uuid) to service_role;
grant execute on function public.log_account_event(uuid, text, jsonb) to service_role;
