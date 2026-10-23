-- nIpay — M-SOC4 (fase 2): movimenti "con amici" nelle transazioni
--
-- Gira su un Supabase locale (Docker), mai sul progetto reale:
--   supabase db start && supabase test db
-- Tutto dentro una transazione annullata alla fine: nessun residuo.

begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

-- Seed (come postgres): A con un portafoglio, una categoria e una spesa
-- divisa con B.
insert into auth.users (id, email) values
  ('a1111111-1111-1111-1111-111111111111', 'fm-a@test.local'),
  ('b2222222-2222-2222-2222-222222222222', 'fm-b@test.local');
insert into wallets (id, owner_user_id, name, color_hex) values
  ('a0000000-0000-0000-0000-000000000001', 'a1111111-1111-1111-1111-111111111111', 'Wallet A', '#111111'),
  ('a0000000-0000-0000-0000-000000000009', 'a1111111-1111-1111-1111-111111111111', 'Wallet A2', '#111111');
insert into categories (id, wallet_id, name, icon, color_hex, kind) values
  ('a0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Cat A', 'cart', '#111111', 'expense');
insert into shared_expenses (id, created_by, paid_by, total_cents, currency, spent_on) values
  ('5e000000-0000-0000-0000-000000000001', 'a1111111-1111-1111-1111-111111111111',
   'a1111111-1111-1111-1111-111111111111', 6000, 'EUR', current_date);
insert into shared_expense_shares (shared_expense_id, user_id, share_cents) values
  ('5e000000-0000-0000-0000-000000000001', 'a1111111-1111-1111-1111-111111111111', 3000),
  ('5e000000-0000-0000-0000-000000000001', 'b2222222-2222-2222-2222-222222222222', 3000);

set local role authenticated;
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select lives_ok($$ insert into transactions
  (wallet_id, type, amount_cents, date, category_id, shared_expense_id)
  values ('a0000000-0000-0000-0000-000000000001', 'expense', 3000, now(),
          'a0000000-0000-0000-0000-000000000002', '5e000000-0000-0000-0000-000000000001') $$,
  'la propria quota è una spesa normale, collegata alla spesa divisa');
select lives_ok($$ insert into transactions
  (wallet_id, type, amount_cents, date, shared_expense_id)
  values ('a0000000-0000-0000-0000-000000000001', 'friendOut', 3000, now(),
          '5e000000-0000-0000-0000-000000000001') $$,
  'friendOut: l''anticipo per gli altri');
select lives_ok($$ insert into transactions (wallet_id, type, amount_cents, date)
  values ('a0000000-0000-0000-0000-000000000001', 'friendIn', 1500, now()) $$,
  'friendIn: un rimborso ricevuto, anche senza spesa collegata');
select throws_ok($$ insert into transactions (wallet_id, type, amount_cents, date)
  values ('a0000000-0000-0000-0000-000000000001', 'friend', 100, now()) $$,
  '23514', null, 'solo i tipi noti');
select throws_ok($$ insert into transactions (wallet_id, type, amount_cents, date)
  values ('a0000000-0000-0000-0000-000000000001', 'friendOut', -100, now()) $$,
  '23514', null, 'importo mai negativo: il verso lo dà il tipo');
select throws_ok($$ insert into transactions (wallet_id, type, amount_cents, date, category_id)
  values ('a0000000-0000-0000-0000-000000000001', 'friendOut', 100, now(),
          'a0000000-0000-0000-0000-000000000002') $$,
  '23514', null, 'un movimento con amici non ha categoria');
select throws_ok($$ insert into transactions (wallet_id, type, amount_cents, date, wallet_to_id)
  values ('a0000000-0000-0000-0000-000000000001', 'friendIn', 100, now(),
          'a0000000-0000-0000-0000-000000000009') $$,
  '23514', null, 'un movimento con amici non ha portafoglio di destinazione');
select throws_ok($$ insert into transactions (wallet_id, type, amount_cents, date, shared_expense_id)
  values ('a0000000-0000-0000-0000-000000000001', 'friendOut', 100, now(),
          '99999999-9999-9999-9999-999999999999') $$,
  '23503', null, 'il collegamento punta a una spesa divisa esistente');
select throws_ok($$ insert into recurring_rules
  (wallet_id, type, amount_cents, frequency, start_at, next_run_at)
  values ('a0000000-0000-0000-0000-000000000001', 'friendOut', 100, 'monthly', now(), now()) $$,
  '23514', null, 'le regole ricorrenti restano solo spesa, entrata e trasferimento');

select * from finish();
rollback;
