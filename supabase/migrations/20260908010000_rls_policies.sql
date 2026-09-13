-- nIpay — policy RLS reali (M-ACC2)
--
-- Fino a questa migration ogni tabella aveva RLS abilitata ma zero
-- policy (default-deny, M-ACC1). Qui aggiungiamo le policy che
-- permettono a un utente autenticato di accedere SOLO ai propri dati.
--
-- Modello: `wallets.owner_user_id` è la root dell'ownership. Ogni altra
-- tabella ha `wallet_id` (NOT NULL, deviazione da locale — vedi M-ACC1)
-- o arriva al wallet tramite `transaction_id`/`tag_id`/`field_id`.
--
-- Le funzioni owns_* centralizzano la logica di verifica ownership:
-- un solo posto da controllare/testare invece di ripetere la stessa
-- EXISTS in 15 policy leggermente diverse (più facile da auditare).

create or replace function owns_wallet(target_wallet_id uuid)
returns boolean
language sql
stable
set search_path = public
as $$
  select exists (
    select 1 from wallets w
    where w.id = target_wallet_id and w.owner_user_id = auth.uid()
  );
$$;

create or replace function owns_transaction(target_transaction_id uuid)
returns boolean
language sql
stable
set search_path = public
as $$
  select exists (
    select 1 from transactions t
    join wallets w on w.id = t.wallet_id
    where t.id = target_transaction_id and w.owner_user_id = auth.uid()
  );
$$;

create or replace function owns_tag(target_tag_id uuid)
returns boolean
language sql
stable
set search_path = public
as $$
  select coalesce(owns_wallet(wallet_id), false) from tags where id = target_tag_id;
$$;

create or replace function owns_custom_field(target_field_id uuid)
returns boolean
language sql
stable
set search_path = public
as $$
  select coalesce(owns_wallet(wallet_id), false) from custom_field_defs where id = target_field_id;
$$;

-- ---------------------------------------------------------------------
-- profiles — un utente vede/modifica solo la propria riga. L'insert è
-- riservato al trigger handle_new_user (security definer, bypassa RLS
-- perché eseguito come owner delle tabelle) — nessuna policy insert
-- per il ruolo authenticated.
-- ---------------------------------------------------------------------
create policy "select own profile" on profiles for select
  using (id = auth.uid());
create policy "update own profile" on profiles for update
  using (id = auth.uid()) with check (id = auth.uid());

-- ---------------------------------------------------------------------
-- wallets — root dell'ownership.
-- ---------------------------------------------------------------------
create policy "select own wallets" on wallets for select
  using (owner_user_id = auth.uid());
create policy "insert own wallets" on wallets for insert
  with check (owner_user_id = auth.uid());
create policy "update own wallets" on wallets for update
  using (owner_user_id = auth.uid()) with check (owner_user_id = auth.uid());
create policy "delete own wallets" on wallets for delete
  using (owner_user_id = auth.uid());

-- ---------------------------------------------------------------------
-- categories, tags, custom_field_defs, budgets, recurring_rules,
-- dashboard_cards, cost_centers, expense_reports — tutte hanno una
-- colonna wallet_id propria (NOT NULL): stesso pattern per tutte.
-- ---------------------------------------------------------------------
create policy "select own categories" on categories for select using (owns_wallet(wallet_id));
create policy "insert own categories" on categories for insert with check (owns_wallet(wallet_id));
create policy "update own categories" on categories for update using (owns_wallet(wallet_id)) with check (owns_wallet(wallet_id));
create policy "delete own categories" on categories for delete using (owns_wallet(wallet_id));

create policy "select own tags" on tags for select using (owns_wallet(wallet_id));
create policy "insert own tags" on tags for insert with check (owns_wallet(wallet_id));
create policy "update own tags" on tags for update using (owns_wallet(wallet_id)) with check (owns_wallet(wallet_id));
create policy "delete own tags" on tags for delete using (owns_wallet(wallet_id));

create policy "select own custom_field_defs" on custom_field_defs for select using (owns_wallet(wallet_id));
create policy "insert own custom_field_defs" on custom_field_defs for insert with check (owns_wallet(wallet_id));
create policy "update own custom_field_defs" on custom_field_defs for update using (owns_wallet(wallet_id)) with check (owns_wallet(wallet_id));
create policy "delete own custom_field_defs" on custom_field_defs for delete using (owns_wallet(wallet_id));

create policy "select own budgets" on budgets for select using (owns_wallet(wallet_id));
create policy "insert own budgets" on budgets for insert with check (owns_wallet(wallet_id));
create policy "update own budgets" on budgets for update using (owns_wallet(wallet_id)) with check (owns_wallet(wallet_id));
create policy "delete own budgets" on budgets for delete using (owns_wallet(wallet_id));

create policy "select own recurring_rules" on recurring_rules for select using (owns_wallet(wallet_id));
create policy "insert own recurring_rules" on recurring_rules for insert with check (owns_wallet(wallet_id));
create policy "update own recurring_rules" on recurring_rules for update using (owns_wallet(wallet_id)) with check (owns_wallet(wallet_id));
create policy "delete own recurring_rules" on recurring_rules for delete using (owns_wallet(wallet_id));

create policy "select own dashboard_cards" on dashboard_cards for select using (owns_wallet(wallet_id));
create policy "insert own dashboard_cards" on dashboard_cards for insert with check (owns_wallet(wallet_id));
create policy "update own dashboard_cards" on dashboard_cards for update using (owns_wallet(wallet_id)) with check (owns_wallet(wallet_id));
create policy "delete own dashboard_cards" on dashboard_cards for delete using (owns_wallet(wallet_id));

create policy "select own cost_centers" on cost_centers for select using (owns_wallet(wallet_id));
create policy "insert own cost_centers" on cost_centers for insert with check (owns_wallet(wallet_id));
create policy "update own cost_centers" on cost_centers for update using (owns_wallet(wallet_id)) with check (owns_wallet(wallet_id));
create policy "delete own cost_centers" on cost_centers for delete using (owns_wallet(wallet_id));

-- expense_reports: in più, se reimburse_tx_id è valorizzato in insert/update
-- deve puntare a una transazione del proprio wallet (difesa in profondità,
-- non solo integrità referenziale).
create policy "select own expense_reports" on expense_reports for select using (owns_wallet(wallet_id));
create policy "insert own expense_reports" on expense_reports for insert
  with check (owns_wallet(wallet_id) and (reimburse_tx_id is null or owns_transaction(reimburse_tx_id)));
create policy "update own expense_reports" on expense_reports for update
  using (owns_wallet(wallet_id))
  with check (owns_wallet(wallet_id) and (reimburse_tx_id is null or owns_transaction(reimburse_tx_id)));
create policy "delete own expense_reports" on expense_reports for delete using (owns_wallet(wallet_id));

-- ---------------------------------------------------------------------
-- transactions — ownership primaria via wallet_id. In insert/update,
-- se wallet_to_id è valorizzato (trasferimento) deve appartenere anche
-- lui all'utente: evita che un client malevolo referenzi il wallet di
-- un altro utente come destinazione.
-- ---------------------------------------------------------------------
create policy "select own transactions" on transactions for select
  using (owns_wallet(wallet_id));
create policy "insert own transactions" on transactions for insert
  with check (owns_wallet(wallet_id) and (wallet_to_id is null or owns_wallet(wallet_to_id)));
create policy "update own transactions" on transactions for update
  using (owns_wallet(wallet_id))
  with check (owns_wallet(wallet_id) and (wallet_to_id is null or owns_wallet(wallet_to_id)));
create policy "delete own transactions" on transactions for delete
  using (owns_wallet(wallet_id));

-- ---------------------------------------------------------------------
-- attachments, expense_report_entries — arrivano al wallet tramite
-- transaction_id (nessuna colonna wallet_id propria).
-- ---------------------------------------------------------------------
create policy "select own attachments" on attachments for select using (owns_transaction(transaction_id));
create policy "insert own attachments" on attachments for insert with check (owns_transaction(transaction_id));
create policy "update own attachments" on attachments for update using (owns_transaction(transaction_id)) with check (owns_transaction(transaction_id));
create policy "delete own attachments" on attachments for delete using (owns_transaction(transaction_id));

create policy "select own expense_report_entries" on expense_report_entries for select using (owns_transaction(transaction_id));
create policy "insert own expense_report_entries" on expense_report_entries for insert with check (owns_transaction(transaction_id));
create policy "update own expense_report_entries" on expense_report_entries for update using (owns_transaction(transaction_id)) with check (owns_transaction(transaction_id));
create policy "delete own expense_report_entries" on expense_report_entries for delete using (owns_transaction(transaction_id));

-- ---------------------------------------------------------------------
-- transaction_tags, custom_field_values — join table, PK composta:
-- entrambi i lati del join devono appartenere all'utente.
-- ---------------------------------------------------------------------
create policy "select own transaction_tags" on transaction_tags for select
  using (owns_transaction(transaction_id) and owns_tag(tag_id));
create policy "insert own transaction_tags" on transaction_tags for insert
  with check (owns_transaction(transaction_id) and owns_tag(tag_id));
create policy "delete own transaction_tags" on transaction_tags for delete
  using (owns_transaction(transaction_id) and owns_tag(tag_id));

create policy "select own custom_field_values" on custom_field_values for select
  using (owns_transaction(transaction_id) and owns_custom_field(field_id));
create policy "insert own custom_field_values" on custom_field_values for insert
  with check (owns_transaction(transaction_id) and owns_custom_field(field_id));
create policy "update own custom_field_values" on custom_field_values for update
  using (owns_transaction(transaction_id) and owns_custom_field(field_id))
  with check (owns_transaction(transaction_id) and owns_custom_field(field_id));
create policy "delete own custom_field_values" on custom_field_values for delete
  using (owns_transaction(transaction_id) and owns_custom_field(field_id));
