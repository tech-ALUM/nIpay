-- nIpay — M-SOC2: richieste di amicizia e blocchi (mds/FRIENDS_PLAN.md)
--
--   * friendships: una riga per coppia (in qualunque ordine), pending →
--     accepted | declined. L'amicizia esiste solo se il RICEVENTE accetta;
--   * blocks: chi blocca rompe amicizia e richieste e non riceve più nulla;
--     chi è bloccato non può saperlo (stessi errori di un utente
--     inesistente, il codice amico non porta a nessuno);
--   * il client non scrive mai le tabelle: tutto passa da RPC SECURITY
--     DEFINER che applicano le regole. Le letture "di dominio" (amici,
--     richieste, bloccati) sono RPC che restituiscono solo id e nome
--     visualizzato: una vista security_invoker avrebbe richiesto di aprire
--     profiles agli amici con tutte le colonne (codice amico compreso).

-- ---------------------------------------------------------------------
-- Tabelle
-- ---------------------------------------------------------------------
create table public.friendships (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references auth.users (id) on delete cascade,
  addressee_id uuid not null references auth.users (id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'declined')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (requester_id <> addressee_id)
);
-- Una sola riga per coppia, indipendentemente da chi ha chiesto.
create unique index friendships_pair_key on public.friendships (
  least(requester_id, addressee_id),
  greatest(requester_id, addressee_id)
);
create index friendships_addressee_status on public.friendships (addressee_id, status);
create index friendships_requester_status on public.friendships (requester_id, status);

create table public.blocks (
  blocker_id uuid not null references auth.users (id) on delete cascade,
  blocked_id uuid not null references auth.users (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index blocks_blocked on public.blocks (blocked_id);

alter table public.friendships enable row level security;
alter table public.blocks enable row level security;

create policy "select own friendships" on public.friendships
  for select to authenticated
  using (auth.uid() = requester_id or auth.uid() = addressee_id);
-- Solo i blocchi che ho fatto io: chi è bloccato non vede nulla.
create policy "select own blocks" on public.blocks
  for select to authenticated
  using (auth.uid() = blocker_id);

revoke all on public.friendships from anon;
revoke all on public.blocks from anon;
revoke insert, update, delete, truncate on public.friendships from authenticated;
revoke insert, update, delete, truncate on public.blocks from authenticated;
grant select on public.friendships to authenticated;
grant select on public.blocks to authenticated;

-- ---------------------------------------------------------------------
-- Helper (schema private, mai esposti)
-- ---------------------------------------------------------------------
create or replace function private.is_blocked_between(a uuid, b uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.blocks bl
     where (bl.blocker_id = a and bl.blocked_id = b)
        or (bl.blocker_id = b and bl.blocked_id = a)
  );
$$;

-- Esiste e non ha chiesto la cancellazione dell'account.
create or replace function private.is_available_user(target uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles p
     where p.id = target and p.deletion_requested_at is null
  );
$$;

revoke all on function private.is_blocked_between(uuid, uuid) from public, anon, authenticated;
revoke all on function private.is_available_user(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- RPC: richieste
-- ---------------------------------------------------------------------

-- Restituisce lo stato risultante: 'pending' (richiesta in attesa) o
-- 'accepted' (eravate già amici, oppure l'altro aveva già chiesto a te:
-- entrambi lo volete). Utente inesistente, in cancellazione, se stessi o
-- blocco in una delle due direzioni: tutti lo stesso errore generico.
create or replace function public.send_friend_request(addressee uuid)
returns text
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  existing public.friendships%rowtype;
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  perform private.consume_rate_limit(
    'send_friend_request', 30, interval '24 hours');
  if addressee is null
     or addressee = uid
     or not private.is_available_user(addressee)
     or private.is_blocked_between(uid, addressee) then
    raise exception 'utente non disponibile' using hint = 'not_available';
  end if;

  select * into existing
    from public.friendships f
   where least(f.requester_id, f.addressee_id) = least(uid, addressee)
     and greatest(f.requester_id, f.addressee_id) = greatest(uid, addressee)
     for update;

  if found and existing.status = 'accepted' then
    return 'accepted';
  end if;
  if found and existing.status = 'pending' then
    if existing.requester_id = uid then
      return 'pending';
    end if;
    update public.friendships
       set status = 'accepted', responded_at = pg_catalog.now()
     where id = existing.id;
    return 'accepted';
  end if;
  if found and existing.requester_id = uid
     and existing.responded_at > pg_catalog.now() - interval '7 days' then
    raise exception 'richiesta rifiutata di recente' using hint = 'cooldown';
  end if;

  if (select pg_catalog.count(*) from public.friendships f
       where f.requester_id = uid and f.status = 'pending') >= 20 then
    raise exception 'troppe richieste in attesa' using hint = 'too_many_pending';
  end if;

  if found then
    -- Rifiuto vecchio (o rifiutata dall'altro lato): la riga riparte.
    update public.friendships
       set requester_id = uid,
           addressee_id = addressee,
           status = 'pending',
           created_at = pg_catalog.now(),
           responded_at = null
     where id = existing.id;
  else
    insert into public.friendships (requester_id, addressee_id)
    values (uid, addressee);
  end if;
  return 'pending';
end;
$$;

-- Solo il destinatario, solo finché è in attesa. Nessuna notifica attiva
-- al rifiuto: chi ha chiesto vede "non accettata" nelle proprie richieste.
create or replace function public.respond_friend_request(
  request_id uuid,
  accept boolean
)
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
  update public.friendships
     set status = case when accept then 'accepted' else 'declined' end,
         responded_at = pg_catalog.now()
   where id = request_id and addressee_id = uid and status = 'pending';
  if not found then
    raise exception 'richiesta non trovata' using hint = 'not_found';
  end if;
end;
$$;

-- Solo chi ha inviato, solo finché è in attesa.
create or replace function public.cancel_friend_request(request_id uuid)
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
  delete from public.friendships
   where id = request_id and requester_id = uid and status = 'pending';
  if not found then
    raise exception 'richiesta non trovata' using hint = 'not_found';
  end if;
end;
$$;

create or replace function public.remove_friend(friend uuid)
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
  delete from public.friendships f
   where f.status = 'accepted'
     and least(f.requester_id, f.addressee_id) = least(uid, friend)
     and greatest(f.requester_id, f.addressee_id) = greatest(uid, friend);
  if not found then
    raise exception 'amicizia non trovata' using hint = 'not_found';
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- RPC: blocchi
-- ---------------------------------------------------------------------

-- Blocca e cancella amicizia e richieste della coppia (in entrambe le
-- direzioni). Sbloccare non ripristina l'amicizia.
create or replace function public.block_user(target uuid)
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
  if target is null or target = uid
     or not exists (select 1 from public.profiles p where p.id = target) then
    raise exception 'utente non disponibile' using hint = 'not_available';
  end if;
  insert into public.blocks (blocker_id, blocked_id)
  values (uid, target)
  on conflict do nothing;
  delete from public.friendships f
   where least(f.requester_id, f.addressee_id) = least(uid, target)
     and greatest(f.requester_id, f.addressee_id) = greatest(uid, target);
end;
$$;

create or replace function public.unblock_user(target uuid)
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
  delete from public.blocks where blocker_id = uid and blocked_id = target;
end;
$$;

-- ---------------------------------------------------------------------
-- RPC: letture (solo id e nome visualizzato degli altri)
-- ---------------------------------------------------------------------
create or replace function public.list_friends()
returns table (user_id uuid, display_name text, friends_since timestamptz)
language sql
stable
security definer
set search_path = ''
as $$
  select other.id, p.display_name, f.responded_at
    from public.friendships f
    cross join lateral (
      select case when f.requester_id = auth.uid()
                  then f.addressee_id else f.requester_id end as id
    ) other
    join public.profiles p on p.id = other.id
   where f.status = 'accepted'
     and auth.uid() in (f.requester_id, f.addressee_id)
   order by p.display_name nulls last, other.id;
$$;

-- In arrivo: solo in attesa. In uscita: in attesa e i rifiuti degli
-- ultimi 7 giorni (per mostrare "non accettata" durante l'attesa).
create or replace function public.list_friend_requests()
returns table (
  request_id uuid,
  direction text,
  user_id uuid,
  display_name text,
  status text,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select f.id, 'incoming', f.requester_id, p.display_name, f.status, f.created_at
    from public.friendships f
    join public.profiles p on p.id = f.requester_id
   where f.addressee_id = auth.uid() and f.status = 'pending'
  union all
  select f.id, 'outgoing', f.addressee_id, p.display_name, f.status, f.created_at
    from public.friendships f
    join public.profiles p on p.id = f.addressee_id
   where f.requester_id = auth.uid()
     and (f.status = 'pending'
          or (f.status = 'declined'
              and f.responded_at > pg_catalog.now() - interval '7 days'))
   order by 6 desc;
$$;

create or replace function public.list_blocked()
returns table (user_id uuid, display_name text)
language sql
stable
security definer
set search_path = ''
as $$
  select bl.blocked_id, p.display_name
    from public.blocks bl
    join public.profiles p on p.id = bl.blocked_id
   where bl.blocker_id = auth.uid()
   order by bl.created_at desc;
$$;

-- ---------------------------------------------------------------------
-- resolve_friend_code (M-SOC1) ora ignora anche i blocchi, in entrambe le
-- direzioni: il codice di chi ti ha bloccato non porta a nessuno.
-- ---------------------------------------------------------------------
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
       and p.deletion_requested_at is null
       and not private.is_blocked_between(uid, p.id);
end;
$$;

-- ---------------------------------------------------------------------
-- Permessi: solo utenti autenticati.
-- ---------------------------------------------------------------------
revoke all on function public.send_friend_request(uuid) from public, anon;
revoke all on function public.respond_friend_request(uuid, boolean) from public, anon;
revoke all on function public.cancel_friend_request(uuid) from public, anon;
revoke all on function public.remove_friend(uuid) from public, anon;
revoke all on function public.block_user(uuid) from public, anon;
revoke all on function public.unblock_user(uuid) from public, anon;
revoke all on function public.list_friends() from public, anon;
revoke all on function public.list_friend_requests() from public, anon;
revoke all on function public.list_blocked() from public, anon;
grant execute on function public.send_friend_request(uuid) to authenticated;
grant execute on function public.respond_friend_request(uuid, boolean) to authenticated;
grant execute on function public.cancel_friend_request(uuid) to authenticated;
grant execute on function public.remove_friend(uuid) to authenticated;
grant execute on function public.block_user(uuid) to authenticated;
grant execute on function public.unblock_user(uuid) to authenticated;
grant execute on function public.list_friends() to authenticated;
grant execute on function public.list_friend_requests() to authenticated;
grant execute on function public.list_blocked() to authenticated;
