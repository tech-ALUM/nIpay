-- nIpay — M-SOC1: nome visualizzato e codice amico (mds/FRIENDS_PLAN.md)
--
--   * profiles guadagna display_name (lo vedono gli amici, mai l'email) e
--     friend_code (il contenuto del QR personale: casuale, generato dal
--     server, NON lo user id);
--   * il client non scrive profiles direttamente (NIP-05): nome e codice
--     passano da RPC SECURITY DEFINER che validano e limitano la frequenza;
--   * resolve_friend_code restituisce solo id + nome visualizzato.
--
-- Rimandato a M-SOC2 (servono friendships/blocks): la vista
-- friend_profiles e il filtro sui blocchi in resolve_friend_code.

-- ---------------------------------------------------------------------
-- Generatore del codice amico: 10 caratteri da un alfabeto di 32 senza
-- simboli ambigui (niente 0/O, 1/I) → 50 bit casuali da pgcrypto, non
-- enumerabile. Il byte % 32 è uniforme (256 è multiplo di 32).
-- ---------------------------------------------------------------------
create or replace function private.new_friend_code()
returns text
language plpgsql
volatile
set search_path = ''
as $$
declare
  alphabet constant text := '23456789ABCDEFGHJKLMNPQRSTUVWXYZ';
  bytes bytea;
  code text;
begin
  loop
    bytes := extensions.gen_random_bytes(10);
    code := '';
    for i in 0..9 loop
      code := code || pg_catalog.substr(
        alphabet, (pg_catalog.get_byte(bytes, i) % 32) + 1, 1);
    end loop;
    exit when not exists (
      select 1 from public.profiles p where p.friend_code = code);
  end loop;
  return code;
end;
$$;
revoke all on function private.new_friend_code() from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- profiles
-- ---------------------------------------------------------------------
alter table public.profiles
  add column display_name text,
  add column friend_code text,
  add column friend_code_rotated_at timestamptz;

-- Profili già esistenti: un codice a testa prima del NOT NULL.
update public.profiles
   set friend_code = private.new_friend_code()
 where friend_code is null;

alter table public.profiles
  alter column friend_code set not null,
  add constraint profiles_friend_code_key unique (friend_code),
  add constraint profiles_friend_code_format
    check (friend_code ~ '^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{10}$'),
  -- Stesse regole di set_display_name e di validateDisplayName lato app
  -- (lib/core/validation.dart): 1–40 caratteri, niente spazi ai bordi né
  -- caratteri di controllo.
  add constraint profiles_display_name_format check (
    display_name is null or (
      pg_catalog.char_length(display_name) between 1 and 40
      and display_name = pg_catalog.btrim(display_name)
      and display_name !~ '[[:cntrl:]]'
    )
  );

-- Signup: il profilo nasce già col suo codice.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, friend_code)
  values (new.id, private.new_friend_code());
  return new;
end;
$$;
revoke all on function public.handle_new_user() from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- Limiti di frequenza per utente (schema private: mai esposto). Una
-- richiesta rifiutata annulla anche il proprio inserimento, quindi
-- conta solo quella andata a buon fine.
-- ---------------------------------------------------------------------
create table private.rate_limit_events (
  id bigint generated always as identity primary key,
  user_id uuid not null,
  action text not null check (pg_catalog.char_length(action) <= 32),
  at timestamptz not null default pg_catalog.now()
);
create index rate_limit_events_lookup
  on private.rate_limit_events (user_id, action, at);
alter table private.rate_limit_events enable row level security;
revoke all on private.rate_limit_events from public, anon, authenticated;

create or replace function private.consume_rate_limit(
  action_name text,
  max_events integer,
  per interval
)
returns void
language plpgsql
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  -- Pulizia degli eventi scaduti dello stesso utente: la tabella non
  -- cresce senza limite.
  delete from private.rate_limit_events e
   where e.user_id = uid and e.action = action_name
     and e.at < pg_catalog.now() - per;
  if (select pg_catalog.count(*) from private.rate_limit_events e
       where e.user_id = uid and e.action = action_name) >= max_events then
    raise exception 'troppe richieste' using hint = 'rate_limited';
  end if;
  insert into private.rate_limit_events (user_id, action)
  values (uid, action_name);
end;
$$;
revoke all on function private.consume_rate_limit(text, integer, interval)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- RPC per l'app
-- ---------------------------------------------------------------------
create or replace function public.set_display_name(new_name text)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  cleaned text := pg_catalog.btrim(coalesce(new_name, ''));
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  if pg_catalog.char_length(cleaned) not between 1 and 40
     or cleaned ~ '[[:cntrl:]]' then
    raise exception 'nome non valido'
      using errcode = '22023', hint = 'invalid_display_name';
  end if;
  update public.profiles set display_name = cleaned where id = uid;
  return cleaned;
end;
$$;

-- Il vecchio codice smette subito di funzionare: chi lo aveva non può più
-- mandare richieste (le amicizie esistenti restano, M-SOC2).
create or replace function public.regenerate_friend_code()
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  code text;
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  perform private.consume_rate_limit(
    'regenerate_friend_code', 5, interval '24 hours');
  code := private.new_friend_code();
  update public.profiles
     set friend_code = code, friend_code_rotated_at = pg_catalog.now()
   where id = uid;
  return code;
end;
$$;

-- Dal codice scansionato al profilo: solo id e nome visualizzato. Accetta
-- minuscole, spazi e trattini (codice digitato a mano). Nessun risultato
-- per il proprio codice, per codici inesistenti o malformati e per gli
-- account in cancellazione — tutti indistinguibili tra loro. Volatile (non
-- stable): registra la chiamata nel limite di frequenza.
create or replace function public.resolve_friend_code(code text)
returns table (id uuid, display_name text)
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  normalized text := pg_catalog.upper(
    pg_catalog.regexp_replace(coalesce(code, ''), '[^0-9A-Za-z]', '', 'g'));
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  perform private.consume_rate_limit(
    'resolve_friend_code', 30, interval '1 hour');
  if normalized !~ '^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{10}$' then
    return;
  end if;
  return query
    select p.id, p.display_name
      from public.profiles p
     where p.friend_code = normalized
       and p.id <> uid
       and p.deletion_requested_at is null;
end;
$$;

revoke all on function public.set_display_name(text) from public, anon;
revoke all on function public.regenerate_friend_code() from public, anon;
revoke all on function public.resolve_friend_code(text) from public, anon;
grant execute on function public.set_display_name(text) to authenticated;
grant execute on function public.regenerate_friend_code() to authenticated;
grant execute on function public.resolve_friend_code(text) to authenticated;
