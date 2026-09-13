-- nIpay — schema iniziale Postgres (M-ACC1)
--
-- Speculare allo schema Drift locale (lib/data/db/tables.dart), con due
-- differenze deliberate:
--   1. `wallet_id` è NOT NULL ovunque qui (in locale è nullable solo per
--      compatibilità con la vecchia migrazione v1→v2, il codice lo
--      valorizza sempre) — qui partiamo da zero, e la RLS di M-ACC2 deve
--      poter risolvere l'owner di ogni riga tramite `wallet_id`: una riga
--      orfana sarebbe un buco di sicurezza o un dato invisibile per sempre.
--   2. Colonne in snake_case (idiomatico Postgres) invece di camelCase.
--
-- RLS abilitata su ogni tabella in fondo a questo file, SENZA policy:
-- default-deny fino a M-ACC2. Non è "temporaneo e poi mi ricordo di
-- abilitarla" — è il default sicuro da subito.

create extension if not exists pgcrypto;

-- ---------------------------------------------------------------------
-- Funzione di supporto: updated_at assegnato dal server, mai dal client.
-- Previene che un device con orologio sbagliato corrompa il
-- last-write-wins del motore di sync (M-ACC6).
-- ---------------------------------------------------------------------
create or replace function set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

-- ---------------------------------------------------------------------
-- profiles — 1:1 con auth.users, creata ora per non fare una migration
-- a parte quando servirà (M-ACC1). Auto-popolata alla creazione utente.
-- ---------------------------------------------------------------------
create table profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  created_at timestamptz not null default now()
);

create or replace function handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id) values (new.id);
  return new;
end;
$$;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function handle_new_user();

-- ---------------------------------------------------------------------
-- wallets — root dell'ownership: owner_user_id è la sorgente di verità
-- per la RLS di tutte le tabelle figlie (via join su wallet_id).
-- ---------------------------------------------------------------------
create table wallets (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  owner_user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,
  color_hex text not null,
  icon text not null default 'wallet',
  initial_balance_cents bigint not null default 0,
  archived_at timestamptz,
  position integer not null default 0,
  currency text not null default 'EUR'
);
create index wallets_owner_idx on wallets (owner_user_id);
create trigger wallets_set_updated_at before update on wallets
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------
-- categories
-- ---------------------------------------------------------------------
create table categories (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  wallet_id uuid not null references wallets (id) on delete cascade,
  name text not null,
  icon text not null,
  color_hex text not null,
  kind text not null check (kind in ('expense', 'income', 'both')),
  parent_id uuid references categories (id) on delete set null,
  sort_order integer not null default 0,
  is_default boolean not null default false
);
create index categories_wallet_idx on categories (wallet_id);
create trigger categories_set_updated_at before update on categories
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------
-- tags
-- ---------------------------------------------------------------------
create table tags (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  wallet_id uuid not null references wallets (id) on delete cascade,
  name text not null
);
create index tags_wallet_idx on tags (wallet_id);
create trigger tags_set_updated_at before update on tags
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------
-- transactions
-- ---------------------------------------------------------------------
create table transactions (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  wallet_id uuid not null references wallets (id) on delete cascade,
  type text not null check (type in ('expense', 'income', 'transfer')),
  amount_cents bigint not null,
  date timestamptz not null,
  wallet_to_id uuid references wallets (id) on delete cascade,
  category_id uuid references categories (id) on delete set null,
  description text not null default '',
  note text,
  entry_currency text,
  entry_amount_cents bigint,
  amount_cents_to bigint
);
create index transactions_wallet_date_idx on transactions (wallet_id, date);
create index transactions_wallet_to_idx on transactions (wallet_to_id);
create trigger transactions_set_updated_at before update on transactions
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------
-- transaction_tags — join N:M, PK composta come in locale.
-- ---------------------------------------------------------------------
create table transaction_tags (
  transaction_id uuid not null references transactions (id) on delete cascade,
  tag_id uuid not null references tags (id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (transaction_id, tag_id)
);

-- ---------------------------------------------------------------------
-- custom_field_defs / custom_field_values
-- ---------------------------------------------------------------------
create table custom_field_defs (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  wallet_id uuid not null references wallets (id) on delete cascade,
  name text not null,
  type text not null check (type in ('text', 'number', 'choice', 'date')),
  expense_report_only boolean not null default false,
  options jsonb,
  sort_order integer not null default 0
);
create index custom_field_defs_wallet_idx on custom_field_defs (wallet_id);
create trigger custom_field_defs_set_updated_at before update on custom_field_defs
  for each row execute function set_updated_at();

create table custom_field_values (
  transaction_id uuid not null references transactions (id) on delete cascade,
  field_id uuid not null references custom_field_defs (id) on delete cascade,
  value text not null,
  updated_at timestamptz not null default now(),
  primary key (transaction_id, field_id)
);
create trigger custom_field_values_set_updated_at before update on custom_field_values
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------
-- budgets
-- ---------------------------------------------------------------------
create table budgets (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  wallet_id uuid not null references wallets (id) on delete cascade,
  category_id uuid not null references categories (id) on delete cascade,
  limit_cents bigint not null,
  unique (category_id)
);
create index budgets_wallet_idx on budgets (wallet_id);
create trigger budgets_set_updated_at before update on budgets
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------
-- recurring_rules
-- ---------------------------------------------------------------------
create table recurring_rules (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  wallet_id uuid not null references wallets (id) on delete cascade,
  category_id uuid references categories (id) on delete set null,
  type text not null check (type in ('expense', 'income', 'transfer')),
  amount_cents bigint not null,
  description text not null default '',
  frequency text not null check (frequency in ('daily', 'weekly', 'monthly', 'yearly')),
  start_at timestamptz not null,
  next_run_at timestamptz not null,
  end_at timestamptz,
  paused_at timestamptz
);
create index recurring_rules_wallet_idx on recurring_rules (wallet_id);
create trigger recurring_rules_set_updated_at before update on recurring_rules
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------
-- attachments — metadato; il file binario vive in Storage (M-ACC3).
-- storage_path nullable: una riga può sincronizzarsi prima che l'upload
-- del file finisca (righe piccole, upload potenzialmente lento/offline).
-- ---------------------------------------------------------------------
create table attachments (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  transaction_id uuid not null references transactions (id) on delete cascade,
  storage_path text,
  mime_type text not null
);
create index attachments_transaction_idx on attachments (transaction_id);
create trigger attachments_set_updated_at before update on attachments
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------
-- dashboard_cards
-- ---------------------------------------------------------------------
create table dashboard_cards (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  wallet_id uuid not null references wallets (id) on delete cascade,
  type text not null,
  position integer not null,
  config_json jsonb not null default '{}'::jsonb
);
create index dashboard_cards_wallet_idx on dashboard_cards (wallet_id);
create trigger dashboard_cards_set_updated_at before update on dashboard_cards
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------
-- cost_centers
-- ---------------------------------------------------------------------
create table cost_centers (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  wallet_id uuid not null references wallets (id) on delete cascade,
  name text not null
);
create index cost_centers_wallet_idx on cost_centers (wallet_id);
create trigger cost_centers_set_updated_at before update on cost_centers
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------
-- expense_reports
-- ---------------------------------------------------------------------
create table expense_reports (
  id uuid primary key default gen_random_uuid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz,
  wallet_id uuid not null references wallets (id) on delete cascade,
  name text not null,
  date_from timestamptz not null,
  date_to timestamptz not null,
  status text not null check (status in ('draft', 'sent', 'reimbursed')),
  reimburse_tx_id uuid references transactions (id) on delete set null
);
create index expense_reports_wallet_idx on expense_reports (wallet_id);
create trigger expense_reports_set_updated_at before update on expense_reports
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------
-- expense_report_entries — PK = transaction_id, come in locale.
-- ---------------------------------------------------------------------
create table expense_report_entries (
  transaction_id uuid primary key references transactions (id) on delete cascade,
  cost_center_id uuid references cost_centers (id) on delete set null,
  reimbursable boolean not null default true,
  e_invoice boolean not null default false,
  report_id uuid references expense_reports (id) on delete set null,
  updated_at timestamptz not null default now()
);
create trigger expense_report_entries_set_updated_at before update on expense_report_entries
  for each row execute function set_updated_at();

-- ---------------------------------------------------------------------
-- RLS: default-deny su ogni tabella. Le policy arrivano in M-ACC2,
-- insieme ai test che verificano che utente A non veda mai dati di B.
-- Fino a quel momento, con RLS abilitata e zero policy, NESSUNO (nemmeno
-- il proprietario) può leggere/scrivere via anon/authenticated key —
-- il che è esattamente il comportamento sicuro da avere di default.
-- ---------------------------------------------------------------------
alter table profiles enable row level security;
alter table wallets enable row level security;
alter table categories enable row level security;
alter table tags enable row level security;
alter table transactions enable row level security;
alter table transaction_tags enable row level security;
alter table custom_field_defs enable row level security;
alter table custom_field_values enable row level security;
alter table budgets enable row level security;
alter table recurring_rules enable row level security;
alter table attachments enable row level security;
alter table dashboard_cards enable row level security;
alter table cost_centers enable row level security;
alter table expense_reports enable row level security;
alter table expense_report_entries enable row level security;
