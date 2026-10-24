-- nIpay — M-SOC5: cancellazione account e dati social (mds/FRIENDS_PLAN.md)
--
-- La cancellazione definitiva (Edge Function purge-deleted-accounts →
-- auth.users) porta già via, per cascata, amicizie, blocchi, membri e
-- letture delle chat; anonimizza messaggi, quote, rimborsi e chi ha
-- segnalato. Qui si chiude il resto:
--
--   * segnalazioni: la copia del messaggio serve alla moderazione solo
--     finché la segnalazione è aperta; chiusa (resolved_at), sparisce;
--   * i contatori dei limiti di frequenza spariscono con l'account;
--   * nei 30 giorni di attesa (deletion_requested_at) l'account può solo
--     leggere e chiudere i debiti (decisione 2026-10-24): niente messaggi,
--     richieste o accettazioni di amicizia, chat o gruppi, spese divise.
--     Rimborsi e registrazioni restano possibili. Lo impongono trigger
--     sulle tabelle, così vale per ogni RPC, sempre su chi fa l'azione
--     (auth.uid()); la cascata della cancellazione (auth.uid() null) passa;
--   * export dei dati di un utente SOLO su richiesta al supporto
--     (decisione 2026-10-24, coerente con quella del 2026-09-13: niente
--     export in app): private.export_user_data, chiamabile solo con la
--     service_role, mai dal client.

-- ---------------------------------------------------------------------
-- Segnalazioni chiuse: via la copia del messaggio.
-- ---------------------------------------------------------------------
create or replace function private.drop_resolved_report_body()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.resolved_at is not null then
    new.message_body := null;
  end if;
  return new;
end;
$$;
revoke all on function private.drop_resolved_report_body() from public, anon, authenticated;
create trigger reports_drop_body_when_resolved
  before insert or update of resolved_at on public.reports
  for each row execute function private.drop_resolved_report_body();
update public.reports set message_body = null where resolved_at is not null;

-- ---------------------------------------------------------------------
-- Limiti di frequenza: legati all'account.
-- ---------------------------------------------------------------------
delete from private.rate_limit_events e
 where not exists (select 1 from auth.users u where u.id = e.user_id);
alter table private.rate_limit_events
  add constraint rate_limit_events_user_fk
  foreign key (user_id) references auth.users (id) on delete cascade;

-- ---------------------------------------------------------------------
-- Account in cancellazione: solo lettura e debiti.
-- ---------------------------------------------------------------------
create or replace function private.require_active_account()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  -- Senza utente (cascata della cancellazione, service_role, dashboard)
  -- non c'è nessuno da fermare.
  if uid is null then
    return new;
  end if;
  -- IF annidati: un AND leggerebbe il campo anche sulle altre tabelle.
  if tg_table_name = 'shared_expenses' then
    -- Eliminare la propria spesa divisa resta possibile.
    if new.deleted_at is not null then
      return new;
    end if;
  elsif tg_table_name = 'friendships' then
    -- Rifiutare una richiesta resta possibile.
    if new.status = 'declined' then
      return new;
    end if;
  end if;
  if exists (select 1 from public.profiles p
              where p.id = uid and p.deletion_requested_at is not null) then
    raise exception 'account in cancellazione' using hint = 'pending_deletion';
  end if;
  return new;
end;
$$;
revoke all on function private.require_active_account() from public, anon, authenticated;

create trigger messages_require_active_account
  before insert on public.messages
  for each row execute function private.require_active_account();
create trigger friendships_require_active_account
  before insert or update on public.friendships
  for each row execute function private.require_active_account();
create trigger conversation_members_require_active_account
  before insert on public.conversation_members
  for each row execute function private.require_active_account();
create trigger shared_expenses_require_active_account
  before insert or update on public.shared_expenses
  for each row execute function private.require_active_account();

-- ---------------------------------------------------------------------
-- Export su richiesta (art. 15 e 20 GDPR): tutto ciò che è dell'utente
-- in un solo JSON. Degli altri solo id e nome visualizzato, quanto basta
-- a capire con chi. Uso dal SQL editor della dashboard:
--   select private.export_user_data('<uuid>');
-- ---------------------------------------------------------------------
create or replace function private.export_user_data(target uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  with my_wallets as (
    select w.id from public.wallets w where w.owner_user_id = target
  ),
  my_transactions as (
    select t.id from public.transactions t
     where t.wallet_id in (select id from my_wallets)
  ),
  my_conversations as (
    select m.conversation_id as id from public.conversation_members m
     where m.user_id = target
  )
  select pg_catalog.jsonb_build_object(
    'exported_at', pg_catalog.now(),
    'user_id', target,
    -- Solo colonne descrittive: mai password o token.
    'account', (select pg_catalog.to_jsonb(u)
                  from (select id, email, created_at, last_sign_in_at,
                               email_confirmed_at
                          from auth.users where id = target) u),
    'profile', (select pg_catalog.to_jsonb(p) from public.profiles p where p.id = target),
    'wallets', coalesce((select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x))
      from public.wallets x where x.id in (select id from my_wallets)), '[]'),
    'categories', coalesce((select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x))
      from public.categories x where x.wallet_id in (select id from my_wallets)), '[]'),
    'tags', coalesce((select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x))
      from public.tags x where x.wallet_id in (select id from my_wallets)), '[]'),
    'transactions', coalesce((select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x))
      from public.transactions x where x.id in (select id from my_transactions)), '[]'),
    'transaction_tags', coalesce((select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x))
      from public.transaction_tags x where x.transaction_id in (select id from my_transactions)), '[]'),
    'custom_field_defs', coalesce((select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x))
      from public.custom_field_defs x where x.wallet_id in (select id from my_wallets)), '[]'),
    'custom_field_values', coalesce((select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x))
      from public.custom_field_values x where x.transaction_id in (select id from my_transactions)), '[]'),
    'budgets', coalesce((select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x))
      from public.budgets x where x.wallet_id in (select id from my_wallets)), '[]'),
    'recurring_rules', coalesce((select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x))
      from public.recurring_rules x where x.wallet_id in (select id from my_wallets)), '[]'),
    'attachments', coalesce((select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x))
      from public.attachments x where x.transaction_id in (select id from my_transactions)), '[]'),
    'dashboard_cards', coalesce((select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x))
      from public.dashboard_cards x where x.wallet_id in (select id from my_wallets)), '[]'),
    'cost_centers', coalesce((select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x))
      from public.cost_centers x where x.wallet_id in (select id from my_wallets)), '[]'),
    'expense_reports', coalesce((select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x))
      from public.expense_reports x where x.wallet_id in (select id from my_wallets)), '[]'),
    'expense_report_entries', coalesce((select pg_catalog.jsonb_agg(pg_catalog.to_jsonb(x))
      from public.expense_report_entries x where x.transaction_id in (select id from my_transactions)), '[]'),
    'friendships', coalesce((select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
        'other_user_id', case when f.requester_id = target then f.addressee_id else f.requester_id end,
        'other_display_name', p.display_name,
        'i_requested', f.requester_id = target,
        'status', f.status, 'created_at', f.created_at, 'responded_at', f.responded_at))
      from public.friendships f
      left join public.profiles p
        on p.id = case when f.requester_id = target then f.addressee_id else f.requester_id end
     where target in (f.requester_id, f.addressee_id)), '[]'),
    'blocks', coalesce((select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
        'blocked_user_id', b.blocked_id, 'created_at', b.created_at))
      from public.blocks b where b.blocker_id = target), '[]'),
    'conversations', coalesce((select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
        'id', c.id, 'kind', c.kind, 'title', c.title, 'created_at', c.created_at,
        'role', m.role, 'joined_at', m.joined_at))
      from public.conversations c
      join public.conversation_members m on m.conversation_id = c.id and m.user_id = target), '[]'),
    'messages_sent', coalesce((select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
        'id', x.id, 'conversation_id', x.conversation_id,
        'body', coalesce(x.body, d.body), 'created_at', x.created_at,
        'deleted_at', x.deleted_at))
      from public.messages x
      left join private.deleted_message_bodies d on d.message_id = x.id
     where x.sender_id = target), '[]'),
    'reports_made', coalesce((select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
        'reported_user_id', r.reported_user_id, 'message_id', r.message_id,
        'reason', r.reason, 'details', r.details, 'created_at', r.created_at,
        'resolved_at', r.resolved_at))
      from public.reports r where r.reporter_id = target), '[]'),
    'shared_expenses', coalesce((select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
        'id', e.id, 'description', e.description, 'total_cents', e.total_cents,
        'currency', e.currency, 'spent_on', e.spent_on, 'i_created', e.created_by = target,
        'paid_by', e.paid_by, 'deleted_at', e.deleted_at,
        'shares', (select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
                     'user_id', s.user_id, 'display_name', p.display_name,
                     'share_cents', s.share_cents))
                     from public.shared_expense_shares s
                     left join public.profiles p on p.id = s.user_id
                    where s.shared_expense_id = e.id)))
      from public.shared_expenses e
     where exists (select 1 from public.shared_expense_shares s
                    where s.shared_expense_id = e.id and s.user_id = target)), '[]'),
    'settlements', coalesce((select pg_catalog.jsonb_agg(pg_catalog.jsonb_build_object(
        'id', st.id, 'from_user', st.from_user, 'to_user', st.to_user,
        'amount_cents', st.amount_cents, 'currency', st.currency,
        'status', st.status, 'created_at', st.created_at,
        'responded_at', st.responded_at))
      from public.settlements st where target in (st.from_user, st.to_user)), '[]')
  );
$$;
revoke all on function private.export_user_data(uuid) from public, anon, authenticated;
grant execute on function private.export_user_data(uuid) to service_role;
