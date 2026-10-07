-- nIpay — integrità della sync lato server (SECURITY_AUDIT.md NIP-01..04, NIP-15)
--
-- Prima di questa migration:
--   * i trigger set_updated_at erano solo BEFORE UPDATE: in INSERT restava
--     l'updated_at scelto dal client, e transaction_tags usava created_at
--     (sempre scelto dal client) come watermark di pull → un orologio avanti
--     o un client malevolo "avvelenava" la sync di tutti i device (NIP-02);
--   * l'upsert era incondizionato: vinceva l'ultimo push, non l'ultima
--     modifica, e un tombstone poteva essere annullato da un push vecchio
--     (NIP-03);
--   * nessun vincolo di dominio: una riga malformata bloccava il pull di
--     tutti i device (NIP-04); il vincolo UNIQUE (category_id) globale sui
--     budget faceva fallire la sync al primo duplicato (NIP-04/NIP-07);
--   * transaction_tags ed expense_report_entries venivano cancellate
--     fisicamente in locale e la rimozione non si propagava mai (NIP-15).
--
-- Modello dopo questa migration (tutte le tabelle sincronizzate):
--   updated_at   versione assegnata SOLO dal server (clock_timestamp()) a
--                ogni scrittura accettata: è il watermark di pull, nessun
--                valore del client può entrarci.
--   modified_at  momento della modifica sul device (last-write-wins). Il
--                server lo limita a "adesso" (mai nel futuro) e scarta le
--                scritture che non sono più recenti della versione che ha
--                già: un push offline vecchio non sovrascrive più una
--                modifica successiva, un tombstone non torna indietro.
--   created_at   limitato a "adesso" in INSERT, immutabile dopo.
--
-- Un UPDATE che non tocca modified_at (SQL editor, client non ancora
-- aggiornato) vale come modifica fatta "adesso"; uno che porta un
-- modified_at più vecchio di quello sul server viene ignorato.

-- ---------------------------------------------------------------------
-- 1. Colonne mancanti
-- ---------------------------------------------------------------------
alter table custom_field_values
  add column created_at timestamptz not null default now();
alter table expense_report_entries
  add column created_at timestamptz not null default now(),
  add column deleted_at timestamptz;
alter table transaction_tags
  add column updated_at timestamptz not null default now(),
  add column deleted_at timestamptz;

-- I vecchi trigger vanno rimossi PRIMA del backfill (altrimenti ogni
-- update del backfill riscriverebbe updated_at).
drop trigger wallets_set_updated_at on wallets;
drop trigger categories_set_updated_at on categories;
drop trigger tags_set_updated_at on tags;
drop trigger transactions_set_updated_at on transactions;
drop trigger custom_field_defs_set_updated_at on custom_field_defs;
drop trigger custom_field_values_set_updated_at on custom_field_values;
drop trigger budgets_set_updated_at on budgets;
drop trigger recurring_rules_set_updated_at on recurring_rules;
drop trigger attachments_set_updated_at on attachments;
drop trigger dashboard_cards_set_updated_at on dashboard_cards;
drop trigger cost_centers_set_updated_at on cost_centers;
drop trigger expense_reports_set_updated_at on expense_reports;
drop trigger expense_report_entries_set_updated_at on expense_report_entries;
drop function set_updated_at();

-- modified_at + bonifica dei timestamp nel futuro già scritti da client
-- (eventuale avvelenamento pregresso, NIP-02).
do $$
declare
  t text;
begin
  foreach t in array array[
    'wallets', 'categories', 'tags', 'transactions', 'transaction_tags',
    'custom_field_defs', 'custom_field_values', 'budgets', 'recurring_rules',
    'attachments', 'dashboard_cards', 'cost_centers', 'expense_reports',
    'expense_report_entries'
  ] loop
    execute format('alter table public.%I add column modified_at timestamptz', t);
    execute format(
      'update public.%I set
         created_at = least(created_at, now()),
         updated_at = least(updated_at, now()),
         modified_at = least(updated_at, now())', t);
    execute format('alter table public.%I alter column modified_at set not null', t);
    execute format('alter table public.%I alter column modified_at set default now()', t);
  end loop;
end;
$$;

-- transaction_tags: il watermark ora è updated_at (server), non created_at.
update transaction_tags set updated_at = least(created_at, now()), modified_at = least(created_at, now());

-- ---------------------------------------------------------------------
-- 2. Trigger unico: timestamp del server + last-write-wins
-- ---------------------------------------------------------------------
create or replace function public.sync_stamp()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  ts timestamptz := clock_timestamp();
begin
  if tg_op = 'INSERT' then
    new.created_at := least(coalesce(new.created_at, ts), ts);
    new.modified_at := least(coalesce(new.modified_at, ts), ts);
    new.updated_at := ts;
    return new;
  end if;

  new.created_at := old.created_at;

  -- Update generato dal database stesso (es. ON DELETE SET NULL di una
  -- foreign key): nessun confronto LWW (sopprimerlo romperebbe
  -- l'integrità referenziale), ma nuova versione da propagare ai device.
  if pg_trigger_depth() > 1 then
    new.modified_at := ts;
    new.updated_at := ts;
    return new;
  end if;

  if new.modified_at is not distinct from old.modified_at then
    -- Scrittura senza un proprio modified_at (client precedente a questa
    -- versione, SQL manuale): vale come modifica fatta adesso. Così un
    -- device non ancora aggiornato non perde in silenzio le sue modifiche.
    new.modified_at := ts;
  else
    new.modified_at := least(new.modified_at, ts);
    if new.modified_at <= old.modified_at then
      -- Scrittura non più recente della versione già sul server (push
      -- offline vecchio, client malevolo): si tiene quella del server.
      -- RETURN NULL salta solo questa riga, il resto del batch passa.
      return null;
    end if;
  end if;
  new.updated_at := ts;
  return new;
end;
$$;

do $$
declare
  t text;
begin
  foreach t in array array[
    'wallets', 'categories', 'tags', 'transactions', 'transaction_tags',
    'custom_field_defs', 'custom_field_values', 'budgets', 'recurring_rules',
    'attachments', 'dashboard_cards', 'cost_centers', 'expense_reports',
    'expense_report_entries'
  ] loop
    execute format(
      'create trigger %I before insert or update on public.%I
         for each row execute function public.sync_stamp()',
      t || '_sync_stamp', t);
  end loop;
end;
$$;

-- ---------------------------------------------------------------------
-- 3. Indici per il pull paginato (keyset su updated_at + chiave primaria)
-- ---------------------------------------------------------------------
create index wallets_sync_idx on wallets (updated_at, id);
create index categories_sync_idx on categories (updated_at, id);
create index tags_sync_idx on tags (updated_at, id);
create index transactions_sync_idx on transactions (updated_at, id);
create index transaction_tags_sync_idx on transaction_tags (updated_at, transaction_id, tag_id);
create index custom_field_defs_sync_idx on custom_field_defs (updated_at, id);
create index custom_field_values_sync_idx on custom_field_values (updated_at, transaction_id, field_id);
create index budgets_sync_idx on budgets (updated_at, id);
create index recurring_rules_sync_idx on recurring_rules (updated_at, id);
create index attachments_sync_idx on attachments (updated_at, id);
create index dashboard_cards_sync_idx on dashboard_cards (updated_at, id);
create index cost_centers_sync_idx on cost_centers (updated_at, id);
create index expense_reports_sync_idx on expense_reports (updated_at, id);
create index expense_report_entries_sync_idx on expense_report_entries (updated_at, transaction_id);

-- ---------------------------------------------------------------------
-- 4. Vincoli di dominio (NIP-04, NIP-12)
--
-- NOT VALID: valgono per ogni riga nuova o modificata, senza far fallire
-- la migration se esistono già righe fuori dominio. I limiti di lunghezza
-- sono volutamente larghi rispetto a quelli dei form dell'app.
-- ---------------------------------------------------------------------
create schema if not exists private;
revoke all on schema private from public;

-- Array JSON di sole stringhe, con limiti su numero e lunghezza.
create or replace function private.is_bounded_string_array(
  value jsonb, max_items integer, max_len integer
)
returns boolean
language sql
immutable
set search_path = ''
as $$
  select value is null or (
    pg_catalog.jsonb_typeof(value) = 'array'
    and pg_catalog.jsonb_array_length(value) <= max_items
    and not exists (
      select 1 from pg_catalog.jsonb_array_elements(value) e
      where pg_catalog.jsonb_typeof(e) <> 'string'
         or pg_catalog.char_length(e #>> '{}') > max_len
    )
  );
$$;

alter table wallets
  add constraint wallets_name_len check (char_length(name) <= 200) not valid,
  add constraint wallets_color_hex check (color_hex ~ '^#[0-9A-Fa-f]{6}$') not valid,
  add constraint wallets_icon_len check (char_length(icon) <= 64) not valid,
  add constraint wallets_currency check (currency ~ '^[A-Z]{3}$') not valid;

alter table categories
  add constraint categories_name_len check (char_length(name) <= 200) not valid,
  add constraint categories_icon_len check (char_length(icon) <= 64) not valid,
  add constraint categories_color_hex check (color_hex ~ '^#[0-9A-Fa-f]{6}$') not valid;

alter table tags
  add constraint tags_name_len check (char_length(name) <= 200) not valid;

alter table transactions
  add constraint transactions_amount_nonneg check (amount_cents >= 0) not valid,
  add constraint transactions_entry_amount_nonneg check (entry_amount_cents is null or entry_amount_cents >= 0) not valid,
  add constraint transactions_amount_to_nonneg check (amount_cents_to is null or amount_cents_to >= 0) not valid,
  add constraint transactions_entry_currency check (entry_currency is null or entry_currency ~ '^[A-Z]{3}$') not valid,
  add constraint transactions_description_len check (char_length(description) <= 1000) not valid,
  add constraint transactions_note_len check (note is null or char_length(note) <= 10000) not valid;

alter table custom_field_defs
  add constraint custom_field_defs_name_len check (char_length(name) <= 200) not valid,
  add constraint custom_field_defs_options check (private.is_bounded_string_array(options, 200, 200)) not valid;

alter table custom_field_values
  add constraint custom_field_values_value_len check (char_length(value) <= 2000) not valid;

alter table budgets
  add constraint budgets_limit_nonneg check (limit_cents >= 0) not valid;

alter table recurring_rules
  add constraint recurring_rules_amount_nonneg check (amount_cents >= 0) not valid,
  add constraint recurring_rules_description_len check (char_length(description) <= 1000) not valid;

alter table attachments
  add constraint attachments_mime_type check (mime_type ~ '^[a-z]+/[a-z0-9.+-]{1,80}$') not valid;

alter table dashboard_cards
  add constraint dashboard_cards_type_len check (char_length(type) <= 64) not valid,
  add constraint dashboard_cards_config check (
    jsonb_typeof(config_json) = 'object' and octet_length(config_json::text) <= 16384
  ) not valid;

alter table cost_centers
  add constraint cost_centers_name_len check (char_length(name) <= 200) not valid;

alter table expense_reports
  add constraint expense_reports_name_len check (char_length(name) <= 200) not valid;

-- ---------------------------------------------------------------------
-- 5. Budget: un budget "vivo" per categoria DENTRO il portafoglio.
--
-- Il vecchio unique (category_id) era globale tra tutti i tenant (oracolo
-- di esistenza, squatting) e contava anche i budget cancellati: due
-- device offline sulla stessa categoria bloccavano la sync per sempre.
-- ---------------------------------------------------------------------
alter table budgets drop constraint budgets_category_id_key;
create unique index budgets_wallet_category_live_key
  on budgets (wallet_id, category_id) where deleted_at is null;
