-- nIpay — riferimenti cross-tenant (SECURITY_AUDIT.md NIP-07, NIP-25)
--
-- Le policy controllavano wallet_id, wallet_to_id, reimburse_tx_id e i lati
-- dei join, ma non le altre foreign key: un utente poteva collegare righe
-- proprie a categorie/centri di costo/note spese di un altro utente, e la
-- differenza tra 23503 (inesistente) e successo (esistente) era un oracolo
-- sull'esistenza degli UUID altrui. L'integrità referenziale ignora la RLS
-- per definizione, quindi la correzione è strutturale:
--
--   * FK COMPOSITE (wallet_id, x_id) → x (wallet_id, id): la riga
--     referenziata deve stare nello STESSO portafoglio, quindi nello stesso
--     tenant. Un UUID di un altro utente e un UUID inesistente danno lo
--     stesso errore (23503): niente oracolo.
--   * expense_report_entries non ha wallet_id: le policy verificano che
--     centro di costo e nota spese stiano nel portafoglio della transazione
--     (la policy è valutata prima dei vincoli: 42501 in entrambi i casi).
--
-- NOT VALID: i vincoli valgono per le righe nuove o modificate senza far
-- fallire la migration su eventuali dati storici incoerenti.

-- Chiavi candidate per le FK composite.
alter table categories add constraint categories_wallet_id_id_key unique (wallet_id, id);
alter table cost_centers add constraint cost_centers_wallet_id_id_key unique (wallet_id, id);
alter table expense_reports add constraint expense_reports_wallet_id_id_key unique (wallet_id, id);

-- categories.parent_id → categoria dello stesso portafoglio.
alter table categories drop constraint categories_parent_id_fkey;
alter table categories add constraint categories_parent_same_wallet_fkey
  foreign key (wallet_id, parent_id) references categories (wallet_id, id)
  on delete set null (parent_id) not valid;

-- transactions.category_id
alter table transactions drop constraint transactions_category_id_fkey;
alter table transactions add constraint transactions_category_same_wallet_fkey
  foreign key (wallet_id, category_id) references categories (wallet_id, id)
  on delete set null (category_id) not valid;

-- budgets.category_id
alter table budgets drop constraint budgets_category_id_fkey;
alter table budgets add constraint budgets_category_same_wallet_fkey
  foreign key (wallet_id, category_id) references categories (wallet_id, id)
  on delete cascade not valid;

-- recurring_rules.category_id
alter table recurring_rules drop constraint recurring_rules_category_id_fkey;
alter table recurring_rules add constraint recurring_rules_category_same_wallet_fkey
  foreign key (wallet_id, category_id) references categories (wallet_id, id)
  on delete set null (category_id) not valid;

-- ---------------------------------------------------------------------
-- expense_report_entries: cost_center_id e report_id nello stesso
-- portafoglio della transazione.
-- ---------------------------------------------------------------------
grant usage on schema private to authenticated, service_role;

create or replace function private.expense_entry_refs_ok(
  target_transaction_id uuid, target_cost_center_id uuid, target_report_id uuid
)
returns boolean
language sql
stable
set search_path = ''
as $$
  select
    (target_cost_center_id is null or exists (
      select 1
      from public.cost_centers c
      join public.transactions t on t.wallet_id = c.wallet_id
      where c.id = target_cost_center_id and t.id = target_transaction_id
    ))
    and
    (target_report_id is null or exists (
      select 1
      from public.expense_reports r
      join public.transactions t on t.wallet_id = r.wallet_id
      where r.id = target_report_id and t.id = target_transaction_id
    ));
$$;
revoke all on function private.expense_entry_refs_ok(uuid, uuid, uuid) from public, anon;
grant execute on function private.expense_entry_refs_ok(uuid, uuid, uuid) to authenticated, service_role;

drop policy "insert own expense_report_entries" on expense_report_entries;
drop policy "update own expense_report_entries" on expense_report_entries;
create policy "insert own expense_report_entries" on expense_report_entries for insert
  with check (
    owns_transaction(transaction_id)
    and private.expense_entry_refs_ok(transaction_id, cost_center_id, report_id)
  );
create policy "update own expense_report_entries" on expense_report_entries for update
  using (owns_transaction(transaction_id))
  with check (
    owns_transaction(transaction_id)
    and private.expense_entry_refs_ok(transaction_id, cost_center_id, report_id)
  );

-- ---------------------------------------------------------------------
-- attachments.storage_path (NIP-25): quando valorizzato deve essere
-- esattamente "{owner_user_id}/{attachment_id}.{ext}", cioè il path che
-- le policy Storage concedono al proprietario. Impedisce di registrare il
-- path di un file di un altro utente (oggi innocuo, domani un bug).
-- ---------------------------------------------------------------------
create or replace function private.attachments_check_storage_path()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  owner uuid;
begin
  if new.storage_path is null then
    return new;
  end if;
  select w.owner_user_id into owner
  from public.transactions t
  join public.wallets w on w.id = t.wallet_id
  where t.id = new.transaction_id;
  if owner is null
     or new.storage_path !~ ('^' || owner::text || '/' || new.id::text || '\.(jpg|jpeg|png|webp|pdf)$') then
    raise exception 'storage_path non valido per questo allegato'
      using errcode = '23514';
  end if;
  return new;
end;
$$;
revoke all on function private.attachments_check_storage_path() from public, anon;

create trigger attachments_check_storage_path
  before insert or update of storage_path, transaction_id on attachments
  for each row execute function private.attachments_check_storage_path();
