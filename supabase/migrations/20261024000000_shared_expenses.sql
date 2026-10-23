-- nIpay — M-SOC4 (fase 1): spese divise, rimborsi e saldi (mds/FRIENDS_PLAN.md)
--
--   * shared_expenses + shared_expense_shares: una spesa pagata da uno
--     (paid_by) e divisa in quote. La somma delle quote è sempre il totale
--     (constraint trigger differito). Partecipanti: chi crea più suoi amici
--     accettati e non bloccati; chi paga è uno dei partecipanti;
--   * la spesa si modifica o si elimina solo da chi l'ha creata, e solo
--     finché nessun ALTRO partecipante ha registrato la sua quota nel
--     proprio portafoglio (registered_at, segnato dall'app): poi è
--     bloccata (decisione 2026-10-23);
--   * settlements: il rimborso lo registra chi paga, di qualunque importo
--     fino a quanto deve; conta nei saldi solo quando il ricevente lo
--     conferma. Nessuno può dichiarare di aver ricevuto soldi per un altro;
--   * saldi per persona e per valuta, senza conversioni (un tasso variabile
--     farebbe "muovere" i debiti). Finita l'amicizia saldi e rimborsi
--     restano; nuove spese insieme no;
--   * il client non legge né scrive le tabelle: solo RPC SECURITY DEFINER.
--     Niente Realtime: le liste si ricaricano all'apertura di Amici.

-- ---------------------------------------------------------------------
-- Tabelle
-- ---------------------------------------------------------------------
create table public.shared_expenses (
  id uuid primary key default gen_random_uuid(),
  created_by uuid references auth.users (id) on delete set null,
  paid_by uuid references auth.users (id) on delete set null,
  -- Facoltativa come quella delle transazioni: 1–200 caratteri.
  description text check (description is null or (
    pg_catalog.char_length(description) between 1 and 200
    and description = pg_catalog.btrim(description)
    and description !~ '[[:cntrl:]]'
  )),
  total_cents bigint not null
    check (total_cents > 0 and total_cents <= 100000000000),
  -- Le valute a 2 decimali dell'app (lib/core/currencies.dart).
  currency text not null check (currency in (
    'AUD', 'BRL', 'CAD', 'CHF', 'CNY', 'CZK', 'DKK', 'EUR', 'GBP', 'HKD',
    'HUF', 'INR', 'MXN', 'NOK', 'NZD', 'PLN', 'RON', 'SEK', 'SGD', 'TRY',
    'USD', 'ZAR'
  )),
  spent_on date not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);
create index shared_expenses_paid_by on public.shared_expenses (paid_by);
create index shared_expenses_created_by on public.shared_expenses (created_by);

create table public.shared_expense_shares (
  id uuid primary key default gen_random_uuid(),
  shared_expense_id uuid not null
    references public.shared_expenses (id) on delete cascade,
  -- Null = account cancellato: la quota resta, il partecipante è anonimo.
  user_id uuid references auth.users (id) on delete set null,
  share_cents bigint not null check (share_cents > 0),
  -- Quando il partecipante ha registrato la quota nel proprio portafoglio.
  registered_at timestamptz,
  unique (shared_expense_id, user_id)
);
create index shared_expense_shares_user on public.shared_expense_shares (user_id);

create table public.settlements (
  id uuid primary key default gen_random_uuid(),
  from_user uuid references auth.users (id) on delete set null,
  to_user uuid references auth.users (id) on delete set null,
  amount_cents bigint not null
    check (amount_cents > 0 and amount_cents <= 100000000000),
  currency text not null check (currency in (
    'AUD', 'BRL', 'CAD', 'CHF', 'CNY', 'CZK', 'DKK', 'EUR', 'GBP', 'HKD',
    'HUF', 'INR', 'MXN', 'NOK', 'NZD', 'PLN', 'RON', 'SEK', 'SGD', 'TRY',
    'USD', 'ZAR'
  )),
  status text not null default 'pending'
    check (status in ('pending', 'confirmed', 'declined')),
  created_at timestamptz not null default now(),
  responded_at timestamptz,
  check (from_user is distinct from to_user)
);
create index settlements_from on public.settlements (from_user);
create index settlements_to on public.settlements (to_user);

alter table public.shared_expenses enable row level security;
alter table public.shared_expense_shares enable row level security;
alter table public.settlements enable row level security;
revoke all on public.shared_expenses from anon, authenticated;
revoke all on public.shared_expense_shares from anon, authenticated;
revoke all on public.settlements from anon, authenticated;

-- ---------------------------------------------------------------------
-- Somma delle quote = totale, controllata a fine transazione (le RPC
-- scrivono spesa e quote in più passi).
-- ---------------------------------------------------------------------
create or replace function private.check_shared_expense_total()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  expense uuid;
  expected bigint;
  actual bigint;
begin
  if tg_table_name = 'shared_expenses' then
    expense := new.id;
  else
    expense := coalesce(new.shared_expense_id, old.shared_expense_id);
  end if;
  select e.total_cents into expected
    from public.shared_expenses e where e.id = expense;
  if not found then
    return null; -- spesa cancellata insieme alle quote
  end if;
  select coalesce(pg_catalog.sum(s.share_cents), 0) into actual
    from public.shared_expense_shares s where s.shared_expense_id = expense;
  if actual <> expected then
    raise exception 'le quote non tornano col totale'
      using errcode = '23514', hint = 'invalid_shares';
  end if;
  return null;
end;
$$;
revoke all on function private.check_shared_expense_total()
  from public, anon, authenticated;

create constraint trigger shared_expense_shares_total
  after insert or update or delete on public.shared_expense_shares
  deferrable initially deferred
  for each row execute function private.check_shared_expense_total();
create constraint trigger shared_expenses_total
  after insert or update of total_cents on public.shared_expenses
  deferrable initially deferred
  for each row execute function private.check_shared_expense_total();

-- ---------------------------------------------------------------------
-- Helper (solo per le RPC)
-- ---------------------------------------------------------------------

-- Bloccata: qualcuno che non l'ha creata ha già registrato la sua quota.
create or replace function private.shared_expense_locked(expense uuid)
returns boolean
language sql
stable
set search_path = ''
as $$
  select exists (
    select 1 from public.shared_expense_shares s
      join public.shared_expenses e on e.id = s.shared_expense_id
     where s.shared_expense_id = expense
       and s.registered_at is not null
       and s.user_id is distinct from e.created_by
  );
$$;

-- Quanto [other] deve a [me] in [cur] (negativo: quanto gli devo io): spese
-- non eliminate meno rimborsi confermati.
create or replace function private.balance_between(me uuid, other uuid, cur text)
returns bigint
language sql
stable
set search_path = ''
as $$
  select coalesce(pg_catalog.sum(f.amount), 0)::bigint from (
    select s.share_cents as amount
      from public.shared_expenses e
      join public.shared_expense_shares s on s.shared_expense_id = e.id
     where e.deleted_at is null and e.currency = cur
       and e.paid_by = me and s.user_id = other
    union all
    select -s.share_cents
      from public.shared_expenses e
      join public.shared_expense_shares s on s.shared_expense_id = e.id
     where e.deleted_at is null and e.currency = cur
       and e.paid_by = other and s.user_id = me
    union all
    select st.amount_cents from public.settlements st
     where st.status = 'confirmed' and st.currency = cur
       and st.from_user = me and st.to_user = other
    union all
    select -st.amount_cents from public.settlements st
     where st.status = 'confirmed' and st.currency = cur
       and st.from_user = other and st.to_user = me
  ) f;
$$;

-- Valida i dati di una spesa divisa; [shares] è un array JSON di
-- {user_id, share_cents}. Restituisce le quote come due array allineati.
create or replace function private.validate_shared_expense(
  me uuid,
  description text,
  total_cents bigint,
  currency text,
  spent_on date,
  paid_by uuid,
  shares jsonb,
  out user_ids uuid[],
  out share_cents bigint[]
)
language plpgsql
set search_path = ''
as $$
declare
  cleaned text := nullif(pg_catalog.btrim(coalesce(description, '')), '');
  shares_sum numeric;
begin
  if (cleaned is not null and (pg_catalog.char_length(cleaned) > 200
                               or cleaned ~ '[[:cntrl:]]'))
     or total_cents is null or total_cents <= 0 or total_cents > 100000000000
     or currency is null or currency not in (
       'AUD', 'BRL', 'CAD', 'CHF', 'CNY', 'CZK', 'DKK', 'EUR', 'GBP', 'HKD',
       'HUF', 'INR', 'MXN', 'NOK', 'NZD', 'PLN', 'RON', 'SEK', 'SGD', 'TRY',
       'USD', 'ZAR')
     or spent_on is null then
    raise exception 'spesa non valida' using hint = 'invalid_expense';
  end if;
  if shares is null or pg_catalog.jsonb_typeof(shares) <> 'array' then
    raise exception 'quote non valide' using hint = 'invalid_shares';
  end if;
  begin
    select pg_catalog.array_agg((x ->> 'user_id')::uuid),
           pg_catalog.array_agg((x ->> 'share_cents')::bigint)
      into user_ids, share_cents
      from pg_catalog.jsonb_array_elements(shares) x;
  exception when others then
    raise exception 'quote non valide' using hint = 'invalid_shares';
  end;

  select pg_catalog.sum(c) into shares_sum from pg_catalog.unnest(share_cents) c;
  if user_ids is null
     or pg_catalog.cardinality(user_ids) <> (
          select pg_catalog.count(distinct u) from pg_catalog.unnest(user_ids) u)
     or exists (select 1 from rows from (pg_catalog.unnest(user_ids), pg_catalog.unnest(share_cents)) v(u, c)
                 where v.u is null or v.c is null or v.c <= 0)
     or not (me = any (user_ids))
     or shares_sum <> total_cents then
    raise exception 'quote non valide' using hint = 'invalid_shares';
  end if;
  if pg_catalog.cardinality(user_ids) < 2 then
    raise exception 'nessun amico' using hint = 'no_participants';
  end if;
  if pg_catalog.cardinality(user_ids) > 50 then
    raise exception 'troppi partecipanti' using hint = 'too_many_participants';
  end if;
  if exists (select 1 from pg_catalog.unnest(user_ids) u
              where u <> me and not private.can_chat_with(u)) then
    raise exception 'utente non disponibile' using hint = 'not_available';
  end if;
  if paid_by is null or not (paid_by = any (user_ids)) then
    raise exception 'chi ha pagato non partecipa' using hint = 'invalid_payer';
  end if;
end;
$$;

revoke all on function private.shared_expense_locked(uuid) from public, anon, authenticated;
revoke all on function private.balance_between(uuid, uuid, text) from public, anon, authenticated;
revoke all on function private.validate_shared_expense(uuid, text, bigint, text, date, uuid, jsonb)
  from public, anon, authenticated;

-- ---------------------------------------------------------------------
-- RPC: spese divise
-- ---------------------------------------------------------------------

-- La quota di chi crea nasce già registrata: l'app salva i suoi movimenti
-- insieme alla spesa.
create or replace function public.create_shared_expense(
  description text,
  total_cents bigint,
  currency text,
  spent_on date,
  paid_by uuid,
  shares jsonb
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  expense uuid;
  ids uuid[];
  cents bigint[];
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  select v.user_ids, v.share_cents into ids, cents
    from private.validate_shared_expense(
      uid, description, total_cents, currency, spent_on, paid_by, shares) v;
  perform private.consume_rate_limit('create_shared_expense', 50, interval '24 hours');

  insert into public.shared_expenses
    (created_by, paid_by, description, total_cents, currency, spent_on)
  values
    (uid, paid_by, nullif(pg_catalog.btrim(coalesce(description, '')), ''),
     total_cents, currency, spent_on)
  returning id into expense;
  insert into public.shared_expense_shares
    (shared_expense_id, user_id, share_cents, registered_at)
  select expense, n.u, n.c, case when n.u = uid then pg_catalog.now() end
    from rows from (pg_catalog.unnest(ids), pg_catalog.unnest(cents)) n(u, c);
  return expense;
end;
$$;

-- Solo chi l'ha creata e solo finché non è bloccata. Le quote si
-- riscrivono da capo.
create or replace function public.update_shared_expense(
  target uuid,
  description text,
  total_cents bigint,
  currency text,
  spent_on date,
  paid_by uuid,
  shares jsonb
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  ids uuid[];
  cents bigint[];
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  perform 1 from public.shared_expenses e
   where e.id = target and e.created_by = uid and e.deleted_at is null
     for update;
  if not found then
    raise exception 'spesa non trovata' using hint = 'not_found';
  end if;
  if private.shared_expense_locked(target) then
    raise exception 'spesa bloccata' using hint = 'locked';
  end if;
  select v.user_ids, v.share_cents into ids, cents
    from private.validate_shared_expense(
      uid, update_shared_expense.description, update_shared_expense.total_cents,
      update_shared_expense.currency, update_shared_expense.spent_on,
      update_shared_expense.paid_by, shares) v;

  update public.shared_expenses e
     set description = nullif(pg_catalog.btrim(coalesce(update_shared_expense.description, '')), ''),
         total_cents = update_shared_expense.total_cents,
         currency = update_shared_expense.currency,
         spent_on = update_shared_expense.spent_on,
         paid_by = update_shared_expense.paid_by,
         updated_at = pg_catalog.now()
   where e.id = target;
  delete from public.shared_expense_shares s where s.shared_expense_id = target;
  insert into public.shared_expense_shares
    (shared_expense_id, user_id, share_cents, registered_at)
  select target, n.u, n.c, case when n.u = uid then pg_catalog.now() end
    from rows from (pg_catalog.unnest(ids), pg_catalog.unnest(cents)) n(u, c);
end;
$$;

create or replace function public.delete_shared_expense(target uuid)
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
  perform 1 from public.shared_expenses e
   where e.id = target and e.created_by = uid and e.deleted_at is null
     for update;
  if not found then
    raise exception 'spesa non trovata' using hint = 'not_found';
  end if;
  if private.shared_expense_locked(target) then
    raise exception 'spesa bloccata' using hint = 'locked';
  end if;
  update public.shared_expenses
     set deleted_at = pg_catalog.now(), updated_at = pg_catalog.now()
   where id = target;
end;
$$;

-- L'app la chiama dopo aver creato i movimenti nel portafoglio scelto.
-- Idempotente.
create or replace function public.register_my_share(target uuid)
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
  update public.shared_expense_shares s
     set registered_at = coalesce(s.registered_at, pg_catalog.now())
    from public.shared_expenses e
   where e.id = s.shared_expense_id
     and s.shared_expense_id = target and s.user_id = uid
     and e.deleted_at is null;
  if not found then
    raise exception 'spesa non trovata' using hint = 'not_found';
  end if;
end;
$$;

-- Le spese a cui partecipo, dalla più recente. shares: tutte le quote,
-- coi nomi (null = account cancellato).
create or replace function public.list_shared_expenses()
returns table (
  expense_id uuid,
  created_by uuid,
  paid_by uuid,
  payer_display_name text,
  description text,
  total_cents bigint,
  currency text,
  spent_on date,
  my_share_cents bigint,
  my_share_registered boolean,
  locked boolean,
  shares jsonb,
  created_at timestamptz,
  updated_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select e.id, e.created_by, e.paid_by, payer.display_name, e.description,
         e.total_cents, e.currency, e.spent_on,
         mine.share_cents, mine.registered_at is not null,
         private.shared_expense_locked(e.id),
         (select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                   'user_id', s.user_id,
                   'display_name', p.display_name,
                   'share_cents', s.share_cents,
                   'registered', s.registered_at is not null)
                 order by p.display_name nulls last, s.user_id)
            from public.shared_expense_shares s
            left join public.profiles p on p.id = s.user_id
           where s.shared_expense_id = e.id),
         e.created_at, e.updated_at
    from public.shared_expenses e
    join public.shared_expense_shares mine
      on mine.shared_expense_id = e.id and mine.user_id = (select auth.uid())
    left join public.profiles payer on payer.id = e.paid_by
   where e.deleted_at is null
   order by e.spent_on desc, e.created_at desc, e.id;
$$;

-- ---------------------------------------------------------------------
-- RPC: rimborsi e saldi
-- ---------------------------------------------------------------------

-- Saldo con ogni persona con cui ho spese o rimborsi, per valuta: positivo
-- = mi deve, negativo = le devo. Anche dopo la fine dell'amicizia; null =
-- account cancellato.
create or replace function public.friend_balances()
returns table (
  user_id uuid,
  display_name text,
  currency text,
  balance_cents bigint,
  is_friend boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  with flows as (
    select s.user_id as other, e.currency, s.share_cents as amount
      from public.shared_expenses e
      join public.shared_expense_shares s on s.shared_expense_id = e.id
     where e.deleted_at is null and e.paid_by = (select auth.uid())
       and s.user_id is distinct from e.paid_by
    union all
    select e.paid_by, e.currency, -s.share_cents
      from public.shared_expenses e
      join public.shared_expense_shares s on s.shared_expense_id = e.id
     where e.deleted_at is null and s.user_id = (select auth.uid())
       and e.paid_by is distinct from s.user_id
    union all
    select st.to_user, st.currency, st.amount_cents from public.settlements st
     where st.status = 'confirmed' and st.from_user = (select auth.uid())
    union all
    select st.from_user, st.currency, -st.amount_cents from public.settlements st
     where st.status = 'confirmed' and st.to_user = (select auth.uid())
  )
  select f.other, p.display_name, f.currency, pg_catalog.sum(f.amount)::bigint,
         f.other is not null and private.are_friends((select auth.uid()), f.other)
    from flows f
    left join public.profiles p on p.id = f.other
   group by f.other, p.display_name, f.currency
  having pg_catalog.sum(f.amount) <> 0
   order by p.display_name nulls last, f.other, f.currency;
$$;

-- Il rimborso lo registra chi paga: fino a quanto deve, meno i rimborsi
-- ancora in attesa. Vale anche dopo la fine dell'amicizia o un blocco
-- (i soldi non si perdono). Conta nei saldi quando il ricevente conferma.
create or replace function public.record_settlement(
  to_user uuid,
  amount_cents bigint,
  currency text
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
  owed bigint;
  pending bigint;
  settlement uuid;
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  if to_user is null or to_user = uid or not private.is_available_user(to_user) then
    raise exception 'utente non disponibile' using hint = 'not_available';
  end if;
  if amount_cents is null or amount_cents <= 0 or currency is null then
    raise exception 'importo non valido' using hint = 'invalid_amount';
  end if;
  perform pg_catalog.pg_advisory_xact_lock(pg_catalog.hashtext(uid::text || to_user::text));
  owed := -private.balance_between(uid, to_user, currency);
  select coalesce(pg_catalog.sum(st.amount_cents), 0) into pending
    from public.settlements st
   where st.status = 'pending' and st.currency = record_settlement.currency
     and st.from_user = uid and st.to_user = record_settlement.to_user;
  if amount_cents > owed - pending then
    raise exception 'importo oltre il debito' using hint = 'amount_too_high';
  end if;
  perform private.consume_rate_limit('record_settlement', 30, interval '24 hours');
  insert into public.settlements (from_user, to_user, amount_cents, currency)
  values (uid, to_user, amount_cents, currency)
  returning id into settlement;
  return settlement;
end;
$$;

-- Solo il ricevente, solo finché è in attesa.
create or replace function public.respond_settlement(target uuid, accept boolean)
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
  update public.settlements st
     set status = case when accept then 'confirmed' else 'declined' end,
         responded_at = pg_catalog.now()
   where st.id = target and st.to_user = uid and st.status = 'pending';
  if not found then
    raise exception 'rimborso non trovato' using hint = 'not_found';
  end if;
end;
$$;

-- Solo chi l'ha registrato, solo finché è in attesa.
create or replace function public.cancel_settlement(target uuid)
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
  delete from public.settlements st
   where st.id = target and st.from_user = uid and st.status = 'pending';
  if not found then
    raise exception 'rimborso non trovato' using hint = 'not_found';
  end if;
end;
$$;

-- In attesa (in arrivo e in uscita) e quelli chiusi negli ultimi 30 giorni.
create or replace function public.list_settlements()
returns table (
  settlement_id uuid,
  direction text,
  user_id uuid,
  display_name text,
  amount_cents bigint,
  currency text,
  status text,
  created_at timestamptz,
  responded_at timestamptz
)
language sql
stable
security definer
set search_path = ''
as $$
  select st.id,
         case when st.from_user = (select auth.uid()) then 'outgoing' else 'incoming' end,
         case when st.from_user = (select auth.uid()) then st.to_user else st.from_user end,
         p.display_name, st.amount_cents, st.currency, st.status,
         st.created_at, st.responded_at
    from public.settlements st
    left join public.profiles p
      on p.id = case when st.from_user = (select auth.uid())
                     then st.to_user else st.from_user end
   where (select auth.uid()) in (st.from_user, st.to_user)
     and (st.status = 'pending'
          or st.responded_at > pg_catalog.now() - interval '30 days')
   order by (st.status = 'pending') desc, st.created_at desc;
$$;

-- ---------------------------------------------------------------------
-- Permessi: solo utenti autenticati.
-- ---------------------------------------------------------------------
revoke all on function public.create_shared_expense(text, bigint, text, date, uuid, jsonb) from public, anon;
revoke all on function public.update_shared_expense(uuid, text, bigint, text, date, uuid, jsonb) from public, anon;
revoke all on function public.delete_shared_expense(uuid) from public, anon;
revoke all on function public.register_my_share(uuid) from public, anon;
revoke all on function public.list_shared_expenses() from public, anon;
revoke all on function public.friend_balances() from public, anon;
revoke all on function public.record_settlement(uuid, bigint, text) from public, anon;
revoke all on function public.respond_settlement(uuid, boolean) from public, anon;
revoke all on function public.cancel_settlement(uuid) from public, anon;
revoke all on function public.list_settlements() from public, anon;
grant execute on function public.create_shared_expense(text, bigint, text, date, uuid, jsonb) to authenticated;
grant execute on function public.update_shared_expense(uuid, text, bigint, text, date, uuid, jsonb) to authenticated;
grant execute on function public.delete_shared_expense(uuid) to authenticated;
grant execute on function public.register_my_share(uuid) to authenticated;
grant execute on function public.list_shared_expenses() to authenticated;
grant execute on function public.friend_balances() to authenticated;
grant execute on function public.record_settlement(uuid, bigint, text) to authenticated;
grant execute on function public.respond_settlement(uuid, boolean) to authenticated;
grant execute on function public.cancel_settlement(uuid) to authenticated;
grant execute on function public.list_settlements() to authenticated;
