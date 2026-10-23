-- nIpay — M-SOC3: chat 1:1 e di gruppo (mds/FRIENDS_PLAN.md)
--
--   * conversations: 'direct' (una per coppia, direct_key) o 'group'
--     (titolo, admin). Chat 1:1 solo tra amici accettati e non bloccati;
--     finita l'amicizia resta in sola lettura e si riattiva se si torna
--     amici (stessa direct_key);
--   * messages: si leggono solo da membri (RLS, anche per Realtime). Nei
--     gruppi i messaggi di chi ho bloccato non li vedo e vedo solo quelli
--     arrivati dopo il mio ingresso. Eliminare un messaggio lo nasconde a
--     tutti: il testo passa in private.deleted_message_bodies (fuori dalla
--     portata del client, per la moderazione), il messaggio resta con
--     body null. Account cancellato: mittente null, testo cancellato;
--   * il client non scrive mai le tabelle: tutto passa da RPC SECURITY
--     DEFINER, come per le amicizie (M-SOC2);
--   * Realtime: la publication contiene SOLO messages,
--     conversation_members e friendships. Gli eventi DELETE non passano
--     dalla RLS e mandano la chiave primaria a tutti gli iscritti: per
--     questo ogni tabella pubblicata ha un id uuid casuale come chiave, e
--     last_read_at sta in conversation_reads (solo il proprietario, non
--     pubblicata: niente "letto alle" visibile agli altri).

-- ---------------------------------------------------------------------
-- Tabelle
-- ---------------------------------------------------------------------
create table public.conversations (
  id uuid primary key default gen_random_uuid(),
  kind text not null check (kind in ('direct', 'group')),
  -- Solo gruppi: 1–60 caratteri, niente spazi ai bordi né controllo.
  title text check (title is null or (
    pg_catalog.char_length(title) between 1 and 60
    and title = pg_catalog.btrim(title)
    and title !~ '[[:cntrl:]]'
  )),
  -- Solo 1:1: "<uuid minore>:<uuid maggiore>", una chat per coppia.
  direct_key text unique,
  created_by uuid references auth.users (id) on delete set null,
  created_at timestamptz not null default now(),
  check (
    (kind = 'direct' and direct_key is not null and title is null)
    or (kind = 'group' and direct_key is null and title is not null)
  )
);

create table public.conversation_members (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null
    references public.conversations (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  role text not null default 'member' check (role in ('admin', 'member')),
  joined_at timestamptz not null default clock_timestamp(),
  unique (conversation_id, user_id)
);
create index conversation_members_user on public.conversation_members (user_id);

create table public.conversation_reads (
  conversation_id uuid not null,
  user_id uuid not null,
  last_read_at timestamptz not null default clock_timestamp(),
  primary key (conversation_id, user_id),
  foreign key (conversation_id, user_id)
    references public.conversation_members (conversation_id, user_id)
    on delete cascade
);

create table public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null
    references public.conversations (id) on delete cascade,
  sender_id uuid references auth.users (id) on delete set null,
  body text check (body is null or pg_catalog.char_length(body) between 1 and 2000),
  created_at timestamptz not null default clock_timestamp(),
  deleted_at timestamptz,
  -- Un messaggio ha il testo finché non viene eliminato, mai dopo.
  check ((deleted_at is null) = (body is not null))
);
create index messages_conversation_created
  on public.messages (conversation_id, created_at desc, id desc);
create index messages_sender on public.messages (sender_id);

-- Testo dei messaggi eliminati dal mittente: solo per la moderazione,
-- dalla dashboard. Sparisce con l'account del mittente.
create table private.deleted_message_bodies (
  message_id uuid primary key references public.messages (id) on delete cascade,
  sender_id uuid not null references auth.users (id) on delete cascade,
  body text not null,
  deleted_at timestamptz not null default now()
);

-- Segnalazioni: solo INSERT via RPC, nessuna lettura dal client (nemmeno
-- le proprie). Le gestisce il titolare dalla dashboard. message_body è la
-- copia del testo al momento della segnalazione.
create table public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid references auth.users (id) on delete set null,
  reported_user_id uuid references auth.users (id) on delete set null,
  message_id uuid references public.messages (id) on delete set null,
  message_body text,
  reason text not null
    check (reason in ('spam', 'offensive', 'harassment', 'other')),
  details text check (details is null or pg_catalog.char_length(details) between 1 and 500),
  created_at timestamptz not null default now(),
  resolved_at timestamptz
);

alter table public.conversations enable row level security;
alter table public.conversation_members enable row level security;
alter table public.conversation_reads enable row level security;
alter table public.messages enable row level security;
alter table public.reports enable row level security;
alter table private.deleted_message_bodies enable row level security;

-- ---------------------------------------------------------------------
-- Helper per le policy (SECURITY DEFINER: leggono conversation_members
-- senza passare dalla sua RLS, che a sua volta li usa)
-- ---------------------------------------------------------------------
create or replace function private.is_member(conv uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.conversation_members m
     where m.conversation_id = conv and m.user_id = (select auth.uid())
  );
$$;

-- Un messaggio si vede se sono membro e, nei gruppi, se è arrivato dopo
-- il mio ingresso e non l'ha mandato qualcuno che ho bloccato. Nelle chat
-- 1:1 lo storico resta visibile anche dopo un blocco (sola lettura).
create or replace function private.can_read_message(
  conv uuid,
  sender uuid,
  sent_at timestamptz
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.conversation_members m
      join public.conversations c on c.id = m.conversation_id
     where m.conversation_id = conv
       and m.user_id = (select auth.uid())
       and (
         c.kind = 'direct'
         or (
           sent_at >= m.joined_at
           and (sender is null or not exists (
             select 1 from public.blocks b
              where b.blocker_id = (select auth.uid()) and b.blocked_id = sender
           ))
         )
       )
  );
$$;

revoke all on function private.is_member(uuid) from public, anon;
revoke all on function private.can_read_message(uuid, uuid, timestamptz) from public, anon;
grant execute on function private.is_member(uuid) to authenticated, service_role;
grant execute on function private.can_read_message(uuid, uuid, timestamptz)
  to authenticated, service_role;

-- Solo per le RPC (non per le policy).
create or replace function private.are_friends(a uuid, b uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.friendships f
     where f.status = 'accepted'
       and least(f.requester_id, f.addressee_id) = least(a, b)
       and greatest(f.requester_id, f.addressee_id) = greatest(a, b)
  );
$$;

-- Posso scrivere a peer in 1:1 o aggiungerlo a un mio gruppo: amici
-- accettati, nessun blocco, account non in cancellazione.
create or replace function private.can_chat_with(peer uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select peer is not null
     and peer <> (select auth.uid())
     and private.are_friends((select auth.uid()), peer)
     and not private.is_blocked_between((select auth.uid()), peer)
     and private.is_available_user(peer);
$$;

create or replace function private.direct_peer(conv uuid)
returns uuid
language sql
stable
set search_path = ''
as $$
  select m.user_id from public.conversation_members m
   where m.conversation_id = conv and m.user_id <> (select auth.uid())
   limit 1;
$$;

revoke all on function private.are_friends(uuid, uuid) from public, anon, authenticated;
revoke all on function private.can_chat_with(uuid) from public, anon, authenticated;
revoke all on function private.direct_peer(uuid) from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- RLS: solo lettura per i membri. Nessuna scrittura diretta.
-- ---------------------------------------------------------------------
create policy "members read conversations" on public.conversations
  for select to authenticated
  using (private.is_member(id));
create policy "members read members" on public.conversation_members
  for select to authenticated
  using (private.is_member(conversation_id));
create policy "read own read marker" on public.conversation_reads
  for select to authenticated
  using (user_id = (select auth.uid()));
create policy "members read messages" on public.messages
  for select to authenticated
  using (private.can_read_message(conversation_id, sender_id, created_at));

revoke all on public.conversations from anon;
revoke all on public.conversation_members from anon;
revoke all on public.conversation_reads from anon;
revoke all on public.messages from anon;
revoke all on public.reports from anon, authenticated;
revoke all on private.deleted_message_bodies from public, anon, authenticated;
revoke insert, update, delete, truncate on public.conversations from authenticated;
revoke insert, update, delete, truncate on public.conversation_members from authenticated;
revoke insert, update, delete, truncate on public.conversation_reads from authenticated;
revoke insert, update, delete, truncate on public.messages from authenticated;
grant select on public.conversations to authenticated;
grant select on public.conversation_members to authenticated;
grant select on public.conversation_reads to authenticated;
grant select on public.messages to authenticated;

-- Account cancellato: i suoi messaggi diventano "Messaggio eliminato" di
-- "Utente eliminato" (la FK mette sender_id a null, qui si toglie il testo).
create or replace function private.wipe_message_of_deleted_sender()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.sender_id is null and old.sender_id is not null then
    new.body := null;
    new.deleted_at := coalesce(new.deleted_at, pg_catalog.now());
  end if;
  return new;
end;
$$;
revoke all on function private.wipe_message_of_deleted_sender()
  from public, anon, authenticated;
create trigger messages_wipe_on_sender_delete
  before update of sender_id on public.messages
  for each row execute function private.wipe_message_of_deleted_sender();

-- ---------------------------------------------------------------------
-- RPC: conversazioni
-- ---------------------------------------------------------------------

-- Apre (o crea) la chat 1:1 con un amico. Errore generico se non si può
-- chattare: non amici, blocco, account in cancellazione.
create or replace function public.open_direct_conversation(friend uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  key text;
  conv uuid;
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  if not private.can_chat_with(friend) then
    raise exception 'utente non disponibile' using hint = 'not_available';
  end if;
  key := least(uid, friend)::text || ':' || greatest(uid, friend)::text;
  insert into public.conversations (kind, direct_key, created_by)
  values ('direct', key, uid)
  on conflict (direct_key) do nothing
  returning id into conv;
  if conv is null then
    select c.id into conv from public.conversations c where c.direct_key = key;
  end if;
  insert into public.conversation_members (conversation_id, user_id)
  values (conv, uid), (conv, friend)
  on conflict (conversation_id, user_id) do nothing;
  insert into public.conversation_reads (conversation_id, user_id)
  values (conv, uid), (conv, friend)
  on conflict (conversation_id, user_id) do nothing;
  return conv;
end;
$$;

-- Gruppo con titolo e almeno un amico; chi lo crea è admin. Massimo 50
-- membri, me compreso.
create or replace function public.create_group(title text, member_ids uuid[])
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  cleaned text := pg_catalog.btrim(coalesce(title, ''));
  others uuid[];
  conv uuid;
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  if pg_catalog.char_length(cleaned) not between 1 and 60
     or cleaned ~ '[[:cntrl:]]' then
    raise exception 'titolo non valido' using hint = 'invalid_title';
  end if;
  others := array(
    select distinct x from pg_catalog.unnest(coalesce(member_ids, '{}')) x
     where x is not null and x <> uid
  );
  if pg_catalog.cardinality(others) = 0 then
    raise exception 'nessun membro' using hint = 'no_members';
  end if;
  if pg_catalog.cardinality(others) + 1 > 50 then
    raise exception 'troppi membri' using hint = 'too_many_members';
  end if;
  if exists (select 1 from pg_catalog.unnest(others) x
              where not private.can_chat_with(x)) then
    raise exception 'utente non disponibile' using hint = 'not_available';
  end if;
  perform private.consume_rate_limit('create_group', 20, interval '24 hours');

  insert into public.conversations (kind, title, created_by)
  values ('group', cleaned, uid)
  returning id into conv;
  insert into public.conversation_members (conversation_id, user_id, role)
  values (conv, uid, 'admin');
  insert into public.conversation_members (conversation_id, user_id)
  select conv, x from pg_catalog.unnest(others) x;
  insert into public.conversation_reads (conversation_id, user_id)
  select conv, m.user_id from public.conversation_members m
   where m.conversation_id = conv;
  return conv;
end;
$$;

-- Ruolo di uid nel gruppo, con il gruppo bloccato per la durata della
-- transazione (le modifiche ai membri vanno in fila). Null se non membro.
create or replace function private.lock_group_role(conv uuid, uid uuid)
returns text
language plpgsql
set search_path = ''
as $$
declare
  r text;
begin
  perform 1 from public.conversations c
   where c.id = conv and c.kind = 'group'
     for update;
  if not found then
    return null;
  end if;
  select m.role into r from public.conversation_members m
   where m.conversation_id = conv and m.user_id = uid;
  return r;
end;
$$;
revoke all on function private.lock_group_role(uuid, uuid) from public, anon, authenticated;

-- Solo gli admin, solo propri amici.
create or replace function public.add_group_members(conv uuid, member_ids uuid[])
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  others uuid[];
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  if private.lock_group_role(conv, uid) is distinct from 'admin' then
    raise exception 'gruppo non trovato' using hint = 'not_found';
  end if;
  others := array(
    select distinct x from pg_catalog.unnest(coalesce(member_ids, '{}')) x
     where x is not null
       and not exists (select 1 from public.conversation_members m
                        where m.conversation_id = conv and m.user_id = x)
  );
  if pg_catalog.cardinality(others) = 0 then
    return;
  end if;
  if exists (select 1 from pg_catalog.unnest(others) x
              where not private.can_chat_with(x)) then
    raise exception 'utente non disponibile' using hint = 'not_available';
  end if;
  if (select pg_catalog.count(*) from public.conversation_members m
       where m.conversation_id = conv) + pg_catalog.cardinality(others) > 50 then
    raise exception 'troppi membri' using hint = 'too_many_members';
  end if;
  insert into public.conversation_members (conversation_id, user_id)
  select conv, x from pg_catalog.unnest(others) x;
  insert into public.conversation_reads (conversation_id, user_id)
  select conv, x from pg_catalog.unnest(others) x;
end;
$$;

-- Solo gli admin, non se stessi (per quello c'è leave_group).
create or replace function public.remove_group_member(conv uuid, member uuid)
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
  if private.lock_group_role(conv, uid) is distinct from 'admin'
     or member is null or member = uid then
    raise exception 'gruppo non trovato' using hint = 'not_found';
  end if;
  delete from public.conversation_members m
   where m.conversation_id = conv and m.user_id = member;
  if not found then
    raise exception 'membro non trovato' using hint = 'not_found';
  end if;
end;
$$;

-- Chiunque può uscire. Se esce l'ultimo admin, diventa admin il membro
-- entrato da più tempo; se esce l'ultimo membro, il gruppo sparisce.
create or replace function public.leave_group(conv uuid)
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
  if private.lock_group_role(conv, uid) is null then
    raise exception 'gruppo non trovato' using hint = 'not_found';
  end if;
  delete from public.conversation_members m
   where m.conversation_id = conv and m.user_id = uid;
  if not exists (select 1 from public.conversation_members m
                  where m.conversation_id = conv) then
    delete from public.conversations c where c.id = conv;
    return;
  end if;
  if not exists (select 1 from public.conversation_members m
                  where m.conversation_id = conv and m.role = 'admin') then
    update public.conversation_members
       set role = 'admin'
     where id = (select m.id from public.conversation_members m
                  where m.conversation_id = conv
                  order by m.joined_at, m.id
                  limit 1);
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- RPC: messaggi
-- ---------------------------------------------------------------------

-- Testo ripulito dagli spazi ai bordi, 1–2000 caratteri; a capo e
-- tabulazioni ammessi, altri caratteri di controllo no. Chat 1:1 non più
-- tra amici (o con un blocco): sola lettura, hint read_only.
create or replace function public.send_message(conv uuid, body text)
returns table (message_id uuid, created_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  conv_kind text;
  cleaned text := pg_catalog.btrim(coalesce(body, ''), E' \t\r\n');
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  select c.kind into conv_kind
    from public.conversations c
    join public.conversation_members m on m.conversation_id = c.id
   where c.id = conv and m.user_id = uid;
  if not found then
    raise exception 'conversazione non trovata' using hint = 'not_found';
  end if;
  if conv_kind = 'direct' and not private.can_chat_with(private.direct_peer(conv)) then
    raise exception 'chat in sola lettura' using hint = 'read_only';
  end if;
  if pg_catalog.char_length(cleaned) not between 1 and 2000
     or cleaned ~ E'[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x7f]' then
    raise exception 'messaggio non valido' using hint = 'invalid_message';
  end if;
  perform private.consume_rate_limit('send_message', 30, interval '1 minute');
  return query
    insert into public.messages as msg (conversation_id, sender_id, body)
    values (conv, uid, cleaned)
    returning msg.id, msg.created_at;
end;
$$;

-- Solo il mittente. Tutti vedono "Messaggio eliminato"; il testo resta
-- solo in private.deleted_message_bodies.
create or replace function public.delete_message(target uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  old_body text;
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  select m.body into old_body
    from public.messages m
   where m.id = target and m.sender_id = uid and m.deleted_at is null
     for update;
  if not found then
    raise exception 'messaggio non trovato' using hint = 'not_found';
  end if;
  insert into private.deleted_message_bodies (message_id, sender_id, body)
  values (target, uid, old_body);
  update public.messages
     set body = null, deleted_at = pg_catalog.now()
   where id = target;
end;
$$;

create or replace function public.mark_conversation_read(conv uuid)
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
  update public.conversation_reads r
     set last_read_at = pg_catalog.clock_timestamp()
   where r.conversation_id = conv and r.user_id = uid;
  if not found then
    raise exception 'conversazione non trovata' using hint = 'not_found';
  end if;
end;
$$;

-- ---------------------------------------------------------------------
-- RPC: letture (degli altri solo id e nome visualizzato)
-- ---------------------------------------------------------------------

-- Le mie conversazioni, dalla più recente. peer_* solo per le 1:1 (null
-- se l'altro ha cancellato l'account). can_send false = sola lettura.
create or replace function public.list_conversations()
returns table (
  conversation_id uuid,
  kind text,
  title text,
  peer_id uuid,
  peer_display_name text,
  member_count integer,
  my_role text,
  can_send boolean,
  last_message_id uuid,
  last_sender_id uuid,
  last_body text,
  last_message_at timestamptz,
  last_message_deleted boolean,
  unread_count integer,
  created_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select c.id, c.kind, c.title,
         peer.user_id, pp.display_name,
         (select pg_catalog.count(*)::integer from public.conversation_members x
           where x.conversation_id = c.id),
         me.role,
         case when c.kind = 'group' then true
              else private.can_chat_with(peer.user_id) end,
         last.id, last.sender_id, last.body, last.created_at,
         last.deleted_at is not null,
         (select pg_catalog.count(*)::integer from public.messages u
           where u.conversation_id = c.id
             and u.created_at > coalesce(rd.last_read_at, me.joined_at)
             and u.sender_id is distinct from me.user_id
             and u.deleted_at is null
             and private.can_read_message(u.conversation_id, u.sender_id, u.created_at)),
         c.created_at
    from public.conversation_members me
    join public.conversations c on c.id = me.conversation_id
    left join public.conversation_reads rd
      on rd.conversation_id = me.conversation_id and rd.user_id = me.user_id
    left join lateral (
      select m.user_id from public.conversation_members m
       where c.kind = 'direct'
         and m.conversation_id = c.id and m.user_id <> me.user_id
       limit 1
    ) peer on true
    left join public.profiles pp on pp.id = peer.user_id
    left join lateral (
      select m.id, m.sender_id, m.body, m.created_at, m.deleted_at
        from public.messages m
       where m.conversation_id = c.id
         and private.can_read_message(m.conversation_id, m.sender_id, m.created_at)
       order by m.created_at desc, m.id desc
       limit 1
    ) last on true
   where me.user_id = (select auth.uid())
   order by coalesce(last.created_at, c.created_at) desc, c.id;
$$;

create or replace function public.list_conversation_members(conv uuid)
returns table (user_id uuid, display_name text, role text, joined_at timestamptz)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.is_member(conv) then
    raise exception 'conversazione non trovata' using hint = 'not_found';
  end if;
  return query
    select m.user_id, p.display_name, m.role, m.joined_at
      from public.conversation_members m
      join public.profiles p on p.id = m.user_id
     where m.conversation_id = conv
     order by m.joined_at, m.user_id;
end;
$$;

-- Storia paginata, dalla più recente: keyset su (created_at, id), come il
-- pull della sync. Pagine da 1 a 100 (default 50).
create or replace function public.list_messages(
  conv uuid,
  before_at timestamptz default null,
  before_id uuid default null,
  page_size integer default 50
)
returns table (
  message_id uuid,
  sender_id uuid,
  sender_display_name text,
  body text,
  created_at timestamptz,
  deleted boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
begin
  if not private.is_member(conv) then
    raise exception 'conversazione non trovata' using hint = 'not_found';
  end if;
  return query
    select m.id, m.sender_id, p.display_name, m.body, m.created_at,
           m.deleted_at is not null
      from public.messages m
      left join public.profiles p on p.id = m.sender_id
     where m.conversation_id = conv
       and private.can_read_message(m.conversation_id, m.sender_id, m.created_at)
       and (before_at is null
            or m.created_at < before_at
            or (m.created_at = before_at and m.id < before_id))
     order by m.created_at desc, m.id desc
     limit least(greatest(coalesce(page_size, 50), 1), 100);
end;
$$;

-- ---------------------------------------------------------------------
-- RPC: segnalazioni (massimo 20 al giorno per utente)
-- ---------------------------------------------------------------------
create or replace function private.clean_report_details(details text)
returns text
language plpgsql
immutable
set search_path = ''
as $$
declare
  cleaned text := nullif(pg_catalog.btrim(coalesce(details, '')), '');
begin
  if cleaned is not null and pg_catalog.char_length(cleaned) > 500 then
    raise exception 'segnalazione non valida' using hint = 'invalid_report';
  end if;
  return cleaned;
end;
$$;
revoke all on function private.clean_report_details(text) from public, anon, authenticated;

-- Un messaggio altrui di una chat che vedo.
create or replace function public.report_message(
  target uuid,
  reason text,
  details text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  msg public.messages%rowtype;
  snapshot text;
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  if reason is null or reason not in ('spam', 'offensive', 'harassment', 'other') then
    raise exception 'segnalazione non valida' using hint = 'invalid_report';
  end if;
  select * into msg from public.messages m
   where m.id = target
     and private.can_read_message(m.conversation_id, m.sender_id, m.created_at);
  if not found or msg.sender_id is not distinct from uid then
    raise exception 'messaggio non trovato' using hint = 'not_found';
  end if;
  snapshot := coalesce(
    msg.body,
    (select d.body from private.deleted_message_bodies d where d.message_id = msg.id)
  );
  perform private.consume_rate_limit('report', 20, interval '24 hours');
  insert into public.reports
    (reporter_id, reported_user_id, message_id, message_body, reason, details)
  values
    (uid, msg.sender_id, msg.id, snapshot, reason,
     private.clean_report_details(details));
end;
$$;

-- Un utente (dal profilo di un amico, da una richiesta, da un gruppo).
create or replace function public.report_user(
  target uuid,
  reason text,
  details text default null
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
  if reason is null or reason not in ('spam', 'offensive', 'harassment', 'other') then
    raise exception 'segnalazione non valida' using hint = 'invalid_report';
  end if;
  if target is null or target = uid
     or not exists (select 1 from public.profiles p where p.id = target) then
    raise exception 'utente non disponibile' using hint = 'not_available';
  end if;
  perform private.consume_rate_limit('report', 20, interval '24 hours');
  insert into public.reports (reporter_id, reported_user_id, reason, details)
  values (uid, target, reason, private.clean_report_details(details));
end;
$$;

-- ---------------------------------------------------------------------
-- Permessi: solo utenti autenticati.
-- ---------------------------------------------------------------------
revoke all on function public.open_direct_conversation(uuid) from public, anon;
revoke all on function public.create_group(text, uuid[]) from public, anon;
revoke all on function public.add_group_members(uuid, uuid[]) from public, anon;
revoke all on function public.remove_group_member(uuid, uuid) from public, anon;
revoke all on function public.leave_group(uuid) from public, anon;
revoke all on function public.send_message(uuid, text) from public, anon;
revoke all on function public.delete_message(uuid) from public, anon;
revoke all on function public.mark_conversation_read(uuid) from public, anon;
revoke all on function public.list_conversations() from public, anon;
revoke all on function public.list_conversation_members(uuid) from public, anon;
revoke all on function public.list_messages(uuid, timestamptz, uuid, integer) from public, anon;
revoke all on function public.report_message(uuid, text, text) from public, anon;
revoke all on function public.report_user(uuid, text, text) from public, anon;
grant execute on function public.open_direct_conversation(uuid) to authenticated;
grant execute on function public.create_group(text, uuid[]) to authenticated;
grant execute on function public.add_group_members(uuid, uuid[]) to authenticated;
grant execute on function public.remove_group_member(uuid, uuid) to authenticated;
grant execute on function public.leave_group(uuid) to authenticated;
grant execute on function public.send_message(uuid, text) to authenticated;
grant execute on function public.delete_message(uuid) to authenticated;
grant execute on function public.mark_conversation_read(uuid) to authenticated;
grant execute on function public.list_conversations() to authenticated;
grant execute on function public.list_conversation_members(uuid) to authenticated;
grant execute on function public.list_messages(uuid, timestamptz, uuid, integer) to authenticated;
grant execute on function public.report_message(uuid, text, text) to authenticated;
grant execute on function public.report_user(uuid, text, text) to authenticated;

-- ---------------------------------------------------------------------
-- Realtime: SOLO le tabelle della chat e delle amicizie, mai quelle dei
-- portafogli (SECURITY_AUDIT NIP-21). Gli eventi rispettano la RLS di
-- SELECT qui sopra.
-- ---------------------------------------------------------------------
do $$
begin
  if not exists (select 1 from pg_catalog.pg_publication
                  where pubname = 'supabase_realtime') then
    create publication supabase_realtime;
  end if;
end;
$$;
alter publication supabase_realtime
  add table public.messages, public.conversation_members, public.friendships;
