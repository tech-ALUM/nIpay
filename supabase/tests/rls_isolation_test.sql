-- nIpay — test di isolamento RLS su TUTTE le tabelle + Storage (M-ACC2/M-ACC3)
--
-- Gira su un Supabase locale (Docker), mai sul progetto reale:
--   supabase start && supabase test db
-- In CI: .github/workflows/supabase.yml.
--
-- Scenario: due utenti, A e B, con un set completo di righe ciascuno
-- (seminato come postgres, che bypassa la RLS). Poi si impersona A
-- (ruolo `authenticated` + claim `sub`) e si verifica che:
--   1. A veda solo le proprie righe, in ogni tabella;
--   2. A non possa inserire righe agganciate ai dati di B (wallet_id,
--      wallet_to_id, reimburse_tx_id, lati del join, prefisso Storage);
--   3. A non possa spostare le proprie righe nel wallet di B;
--   4. update/delete di A sulle righe di B non tocchino nulla;
--   5. un client anonimo non legga né scriva nulla.
-- Tutto dentro una transazione annullata alla fine: nessun residuo.

begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

-- ---------------------------------------------------------------------
-- Seed (come postgres, RLS bypassata)
--   utente A = 1111…, utente B = 2222…
--   prefisso id: a… = righe di A, b… = righe di B
-- ---------------------------------------------------------------------
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'rls-a@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'rls-b@test.local');

insert into wallets (id, owner_user_id, name, color_hex) values
  ('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Wallet A', '#111111'),
  ('b0000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'Wallet B', '#222222');

insert into categories (id, wallet_id, name, icon, color_hex, kind) values
  ('a0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Cat A', 'cart', '#111111', 'expense'),
  ('b0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', 'Cat B', 'cart', '#222222', 'expense');

insert into tags (id, wallet_id, name) values
  ('a0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'tag A'),
  ('b0000000-0000-0000-0000-000000000003', 'b0000000-0000-0000-0000-000000000001', 'tag B');

insert into transactions (id, wallet_id, type, amount_cents, date) values
  ('a0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000001', 'expense', 100, now()),
  ('b0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000001', 'expense', 200, now());

insert into transaction_tags (transaction_id, tag_id) values
  ('a0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000003'),
  ('b0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000003');

insert into custom_field_defs (id, wallet_id, name, type) values
  ('a0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'campo A', 'text'),
  ('b0000000-0000-0000-0000-000000000005', 'b0000000-0000-0000-0000-000000000001', 'campo B', 'text');

insert into custom_field_values (transaction_id, field_id, value) values
  ('a0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000005', 'valore A'),
  ('b0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000005', 'valore B');

insert into budgets (id, wallet_id, category_id, limit_cents) values
  ('a0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 1000),
  ('b0000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 2000);

insert into recurring_rules (id, wallet_id, type, amount_cents, frequency, start_at, next_run_at) values
  ('a0000000-0000-0000-0000-000000000007', 'a0000000-0000-0000-0000-000000000001', 'expense', 100, 'monthly', now(), now()),
  ('b0000000-0000-0000-0000-000000000007', 'b0000000-0000-0000-0000-000000000001', 'expense', 200, 'monthly', now(), now());

insert into attachments (id, transaction_id, mime_type) values
  ('a0000000-0000-0000-0000-000000000008', 'a0000000-0000-0000-0000-000000000004', 'image/jpeg'),
  ('b0000000-0000-0000-0000-000000000008', 'b0000000-0000-0000-0000-000000000004', 'image/jpeg');

insert into dashboard_cards (id, wallet_id, type, position) values
  ('a0000000-0000-0000-0000-000000000009', 'a0000000-0000-0000-0000-000000000001', 'cashflow', 0),
  ('b0000000-0000-0000-0000-000000000009', 'b0000000-0000-0000-0000-000000000001', 'cashflow', 0);

insert into cost_centers (id, wallet_id, name) values
  ('a0000000-0000-0000-0000-00000000000a', 'a0000000-0000-0000-0000-000000000001', 'CdC A'),
  ('b0000000-0000-0000-0000-00000000000a', 'b0000000-0000-0000-0000-000000000001', 'CdC B');

insert into expense_reports (id, wallet_id, name, date_from, date_to, status) values
  ('a0000000-0000-0000-0000-00000000000b', 'a0000000-0000-0000-0000-000000000001', 'Nota A', now(), now(), 'draft'),
  ('b0000000-0000-0000-0000-00000000000b', 'b0000000-0000-0000-0000-000000000001', 'Nota B', now(), now(), 'draft');

insert into expense_report_entries (transaction_id, cost_center_id) values
  ('a0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-00000000000a'),
  ('b0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-00000000000a');

insert into storage.objects (bucket_id, name) values
  ('attachments', '11111111-1111-1111-1111-111111111111/scontrino-a.jpg'),
  ('attachments', '22222222-2222-2222-2222-222222222222/scontrino-b.jpg');

-- Ogni tabella con RLS deve averla abilitata (rete di sicurezza per le
-- tabelle aggiunte in futuro: se ne manca una, questo test fallisce).
select is(
  (select count(*)::int from pg_tables
    where schemaname = 'public' and not rowsecurity),
  0,
  'RLS abilitata su tutte le tabelle di public'
);

-- =====================================================================
-- Utente A
-- =====================================================================
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

-- 1. Lettura: solo le proprie righe -----------------------------------
select is((select count(*)::int from profiles), 1, 'A vede solo il proprio profilo');
select is((select id from profiles), '11111111-1111-1111-1111-111111111111'::uuid, 'il profilo visibile è quello di A');
select is((select count(*)::int from wallets), 1, 'A vede solo il proprio wallet');
select is((select count(*)::int from categories), 1, 'A vede solo le proprie categorie');
select is((select count(*)::int from tags), 1, 'A vede solo i propri tag');
select is((select count(*)::int from transactions), 1, 'A vede solo le proprie transazioni');
select is((select count(*)::int from transaction_tags), 1, 'A vede solo i propri transaction_tags');
select is((select count(*)::int from custom_field_defs), 1, 'A vede solo i propri campi custom');
select is((select count(*)::int from custom_field_values), 1, 'A vede solo i propri valori custom');
select is((select count(*)::int from budgets), 1, 'A vede solo i propri budget');
select is((select count(*)::int from recurring_rules), 1, 'A vede solo le proprie ricorrenze');
select is((select count(*)::int from attachments), 1, 'A vede solo i propri allegati');
select is((select count(*)::int from dashboard_cards), 1, 'A vede solo le proprie card');
select is((select count(*)::int from cost_centers), 1, 'A vede solo i propri centri di costo');
select is((select count(*)::int from expense_reports), 1, 'A vede solo le proprie note spese');
select is((select count(*)::int from expense_report_entries), 1, 'A vede solo le proprie voci nota spese');
select is(
  (select count(*)::int from storage.objects where bucket_id = 'attachments'),
  1,
  'A vede solo i propri file in Storage'
);

-- 2. Inserimento agganciato ai dati di B -------------------------------
select throws_ok(
  $$ insert into wallets (owner_user_id, name, color_hex)
     values ('22222222-2222-2222-2222-222222222222', 'intestato a B', '#000000') $$,
  '42501', null, 'A non può creare un wallet intestato a B'
);
select throws_ok(
  $$ insert into profiles (id) values ('11111111-1111-1111-1111-111111111111') $$,
  '42501', null, 'A non può inserire profili (solo il trigger di signup)'
);
select throws_ok(
  $$ insert into categories (wallet_id, name, icon, color_hex, kind)
     values ('b0000000-0000-0000-0000-000000000001', 'x', 'x', '#000000', 'expense') $$,
  '42501', null, 'A non può creare categorie nel wallet di B'
);
select throws_ok(
  $$ insert into tags (wallet_id, name) values ('b0000000-0000-0000-0000-000000000001', 'x') $$,
  '42501', null, 'A non può creare tag nel wallet di B'
);
select throws_ok(
  $$ insert into transactions (wallet_id, type, amount_cents, date)
     values ('b0000000-0000-0000-0000-000000000001', 'expense', 1, now()) $$,
  '42501', null, 'A non può creare transazioni nel wallet di B'
);
select throws_ok(
  $$ insert into transactions (wallet_id, type, amount_cents, date, wallet_to_id)
     values ('a0000000-0000-0000-0000-000000000001', 'transfer', 1, now(),
             'b0000000-0000-0000-0000-000000000001') $$,
  '42501', null, 'A non può trasferire verso il wallet di B'
);
select throws_ok(
  $$ insert into transaction_tags (transaction_id, tag_id)
     values ('a0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000003') $$,
  '42501', null, 'A non può usare un tag di B sulla propria transazione'
);
select throws_ok(
  $$ insert into transaction_tags (transaction_id, tag_id)
     values ('b0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000003') $$,
  '42501', null, 'A non può taggare una transazione di B'
);
select throws_ok(
  $$ insert into custom_field_defs (wallet_id, name, type)
     values ('b0000000-0000-0000-0000-000000000001', 'x', 'text') $$,
  '42501', null, 'A non può creare campi custom nel wallet di B'
);
select throws_ok(
  $$ insert into custom_field_values (transaction_id, field_id, value)
     values ('a0000000-0000-0000-0000-000000000004', 'b0000000-0000-0000-0000-000000000005', 'x') $$,
  '42501', null, 'A non può usare un campo custom di B'
);
select throws_ok(
  $$ insert into custom_field_values (transaction_id, field_id, value)
     values ('b0000000-0000-0000-0000-000000000004', 'a0000000-0000-0000-0000-000000000005', 'x') $$,
  '42501', null, 'A non può scrivere valori custom sulle transazioni di B'
);
select throws_ok(
  $$ insert into budgets (wallet_id, category_id, limit_cents)
     values ('b0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 1) $$,
  '42501', null, 'A non può creare budget nel wallet di B'
);
select throws_ok(
  $$ insert into recurring_rules (wallet_id, type, amount_cents, frequency, start_at, next_run_at)
     values ('b0000000-0000-0000-0000-000000000001', 'expense', 1, 'monthly', now(), now()) $$,
  '42501', null, 'A non può creare ricorrenze nel wallet di B'
);
select throws_ok(
  $$ insert into attachments (transaction_id, mime_type)
     values ('b0000000-0000-0000-0000-000000000004', 'image/jpeg') $$,
  '42501', null, 'A non può agganciare allegati alle transazioni di B'
);
select throws_ok(
  $$ insert into dashboard_cards (wallet_id, type, position)
     values ('b0000000-0000-0000-0000-000000000001', 'cashflow', 1) $$,
  '42501', null, 'A non può creare card nel wallet di B'
);
select throws_ok(
  $$ insert into cost_centers (wallet_id, name) values ('b0000000-0000-0000-0000-000000000001', 'x') $$,
  '42501', null, 'A non può creare centri di costo nel wallet di B'
);
select throws_ok(
  $$ insert into expense_reports (wallet_id, name, date_from, date_to, status)
     values ('b0000000-0000-0000-0000-000000000001', 'x', now(), now(), 'draft') $$,
  '42501', null, 'A non può creare note spese nel wallet di B'
);
select throws_ok(
  $$ insert into expense_reports (wallet_id, name, date_from, date_to, status, reimburse_tx_id)
     values ('a0000000-0000-0000-0000-000000000001', 'x', now(), now(), 'reimbursed',
             'b0000000-0000-0000-0000-000000000004') $$,
  '42501', null, 'A non può collegare come rimborso una transazione di B'
);
select throws_ok(
  $$ insert into expense_report_entries (transaction_id)
     values ('b0000000-0000-0000-0000-000000000004')
     on conflict do nothing $$,
  '42501', null, 'A non può creare voci nota spese sulle transazioni di B'
);
select throws_ok(
  $$ insert into storage.objects (bucket_id, name)
     values ('attachments', '22222222-2222-2222-2222-222222222222/intruso.jpg') $$,
  '42501', null, 'A non può caricare file nel prefisso Storage di B'
);
select lives_ok(
  $$ insert into storage.objects (bucket_id, name)
     values ('attachments', '11111111-1111-1111-1111-111111111111/nuovo.jpg') $$,
  'A può caricare file nel proprio prefisso Storage'
);

-- 3. Spostare le proprie righe dentro il wallet di B --------------------
select throws_ok(
  $$ update wallets set owner_user_id = '22222222-2222-2222-2222-222222222222'
     where id = 'a0000000-0000-0000-0000-000000000001' $$,
  '42501', null, 'A non può regalare il proprio wallet a B'
);
select throws_ok(
  $$ update categories set wallet_id = 'b0000000-0000-0000-0000-000000000001'
     where id = 'a0000000-0000-0000-0000-000000000002' $$,
  '42501', null, 'A non può spostare una categoria nel wallet di B'
);
select throws_ok(
  $$ update transactions set wallet_id = 'b0000000-0000-0000-0000-000000000001'
     where id = 'a0000000-0000-0000-0000-000000000004' $$,
  '42501', null, 'A non può spostare una transazione nel wallet di B'
);
select throws_ok(
  $$ update transactions set type = 'transfer', wallet_to_id = 'b0000000-0000-0000-0000-000000000001'
     where id = 'a0000000-0000-0000-0000-000000000004' $$,
  '42501', null, 'A non può trasformare una transazione in trasferimento verso B'
);
select throws_ok(
  $$ update transaction_tags set tag_id = 'b0000000-0000-0000-0000-000000000003'
     where transaction_id = 'a0000000-0000-0000-0000-000000000004' $$,
  '42501', null, 'A non può far puntare un proprio transaction_tag a un tag di B'
);
select throws_ok(
  $$ update custom_field_values set field_id = 'b0000000-0000-0000-0000-000000000005'
     where transaction_id = 'a0000000-0000-0000-0000-000000000004' $$,
  '42501', null, 'A non può far puntare un proprio valore custom a un campo di B'
);
select throws_ok(
  $$ update expense_reports set reimburse_tx_id = 'b0000000-0000-0000-0000-000000000004'
     where id = 'a0000000-0000-0000-0000-00000000000b' $$,
  '42501', null, 'A non può collegare a posteriori un rimborso di B'
);
select throws_ok(
  $$ update storage.objects
     set name = '22222222-2222-2222-2222-222222222222/spostato.jpg'
     where name = '11111111-1111-1111-1111-111111111111/scontrino-a.jpg' $$,
  '42501', null, 'A non può spostare un proprio file nel prefisso di B'
);

-- 4. Upsert con l'id di una riga di B (lo stesso percorso del sync) -----
select throws_ok(
  $$ insert into wallets (id, owner_user_id, name, color_hex)
     values ('b0000000-0000-0000-0000-000000000001',
             '11111111-1111-1111-1111-111111111111', 'dirottato', '#000000')
     on conflict (id) do update set name = excluded.name,
       owner_user_id = excluded.owner_user_id $$,
  '42501', null, 'A non può dirottare il wallet di B con un upsert'
);
select throws_ok(
  $$ insert into transactions (id, wallet_id, type, amount_cents, date)
     values ('b0000000-0000-0000-0000-000000000004',
             'a0000000-0000-0000-0000-000000000001', 'expense', 1, now())
     on conflict (id) do update set wallet_id = excluded.wallet_id $$,
  '42501', null, 'A non può dirottare una transazione di B con un upsert'
);

-- 5. Update/delete sulle righe di B: nessun effetto (verificato sotto) --
update profiles set deletion_requested_at = now()
  where id = '22222222-2222-2222-2222-222222222222';
update wallets set name = 'hacked' where id = 'b0000000-0000-0000-0000-000000000001';
update categories set name = 'hacked' where id = 'b0000000-0000-0000-0000-000000000002';
update tags set name = 'hacked' where id = 'b0000000-0000-0000-0000-000000000003';
update transactions set amount_cents = 0 where id = 'b0000000-0000-0000-0000-000000000004';
update custom_field_values set value = 'hacked'
  where transaction_id = 'b0000000-0000-0000-0000-000000000004';
update budgets set limit_cents = 0 where id = 'b0000000-0000-0000-0000-000000000006';
update expense_report_entries set reimbursable = false
  where transaction_id = 'b0000000-0000-0000-0000-000000000004';
delete from transaction_tags where transaction_id = 'b0000000-0000-0000-0000-000000000004';
delete from recurring_rules where id = 'b0000000-0000-0000-0000-000000000007';
delete from attachments where id = 'b0000000-0000-0000-0000-000000000008';
delete from dashboard_cards where id = 'b0000000-0000-0000-0000-000000000009';
delete from cost_centers where id = 'b0000000-0000-0000-0000-00000000000a';
delete from expense_reports where id = 'b0000000-0000-0000-0000-00000000000b';
delete from custom_field_defs where id = 'b0000000-0000-0000-0000-000000000005';
-- Supabase blocca ogni DELETE diretto su storage.objects (trigger
-- storage.protect_delete); l'API Storage lo sblocca con questa variabile
-- e si affida alla RLS: la stessa condizione la riproduciamo qui.
set local storage.allow_delete_query = 'true';
select lives_ok(
  $$ delete from storage.objects
     where name = '22222222-2222-2222-2222-222222222222/scontrino-b.jpg' $$,
  'delete di A sui file di B non dà errore (e non cancella nulla, vedi sotto)'
);
-- ultimo: la cascata cancellerebbe tutto il resto di B
delete from wallets where id = 'b0000000-0000-0000-0000-000000000001';

-- 6. Compatibilità con il sync: ri-inviare righe proprie già presenti --
-- Il motore di sync fa upsert (INSERT … ON CONFLICT DO UPDATE) e può
-- reinviare una riga che il server ha già (sync interrotta, riga appena
-- scaricata da un altro device): l'upsert del proprietario deve passare.
select lives_ok(
  $$ insert into transaction_tags (transaction_id, tag_id, created_at)
     values ('a0000000-0000-0000-0000-000000000004',
             'a0000000-0000-0000-0000-000000000003', now())
     on conflict (transaction_id, tag_id) do update set created_at = excluded.created_at $$,
  'il proprietario può ri-inviare (upsert) un transaction_tag già presente'
);
select lives_ok(
  $$ insert into custom_field_values (transaction_id, field_id, value)
     values ('a0000000-0000-0000-0000-000000000004',
             'a0000000-0000-0000-0000-000000000005', 'nuovo valore')
     on conflict (transaction_id, field_id) do update set value = excluded.value $$,
  'il proprietario può ri-inviare (upsert) un valore custom già presente'
);
select lives_ok(
  $$ insert into expense_report_entries (transaction_id, reimbursable)
     values ('a0000000-0000-0000-0000-000000000004', false)
     on conflict (transaction_id) do update set reimbursable = excluded.reimbursable $$,
  'il proprietario può ri-inviare (upsert) una voce nota spese già presente'
);

-- =====================================================================
-- Verifica come postgres: le righe di B sono intatte
-- =====================================================================
reset role;

select is(
  (select deletion_requested_at from profiles where id = '22222222-2222-2222-2222-222222222222'),
  null,
  'il profilo di B non è stato toccato (nessuna richiesta di cancellazione)'
);
select is((select name from wallets where id = 'b0000000-0000-0000-0000-000000000001'), 'Wallet B', 'wallet di B intatto');
select is((select owner_user_id from wallets where id = 'b0000000-0000-0000-0000-000000000001'),
  '22222222-2222-2222-2222-222222222222'::uuid, 'wallet di B ancora di B');
select is((select name from categories where id = 'b0000000-0000-0000-0000-000000000002'), 'Cat B', 'categoria di B intatta');
select is((select name from tags where id = 'b0000000-0000-0000-0000-000000000003'), 'tag B', 'tag di B intatto');
select is((select amount_cents from transactions where id = 'b0000000-0000-0000-0000-000000000004'), 200::bigint, 'transazione di B intatta');
select is((select wallet_id from transactions where id = 'b0000000-0000-0000-0000-000000000004'),
  'b0000000-0000-0000-0000-000000000001'::uuid, 'transazione di B ancora nel wallet di B');
select is((select value from custom_field_values where transaction_id = 'b0000000-0000-0000-0000-000000000004'), 'valore B', 'valore custom di B intatto');
select is((select limit_cents from budgets where id = 'b0000000-0000-0000-0000-000000000006'), 2000::bigint, 'budget di B intatto');
select is((select reimbursable from expense_report_entries where transaction_id = 'b0000000-0000-0000-0000-000000000004'), true, 'voce nota spese di B intatta');
select is((select count(*)::int from transaction_tags where transaction_id = 'b0000000-0000-0000-0000-000000000004'), 1, 'transaction_tag di B non cancellato');
select is((select count(*)::int from recurring_rules where id = 'b0000000-0000-0000-0000-000000000007'), 1, 'ricorrenza di B non cancellata');
select is((select count(*)::int from attachments where id = 'b0000000-0000-0000-0000-000000000008'), 1, 'allegato di B non cancellato');
select is((select count(*)::int from dashboard_cards where id = 'b0000000-0000-0000-0000-000000000009'), 1, 'card di B non cancellata');
select is((select count(*)::int from cost_centers where id = 'b0000000-0000-0000-0000-00000000000a'), 1, 'centro di costo di B non cancellato');
select is((select count(*)::int from expense_reports where id = 'b0000000-0000-0000-0000-00000000000b'), 1, 'nota spese di B non cancellata');
select is((select count(*)::int from custom_field_defs where id = 'b0000000-0000-0000-0000-000000000005'), 1, 'campo custom di B non cancellato');
select is(
  (select count(*)::int from storage.objects
    where name = '22222222-2222-2222-2222-222222222222/scontrino-b.jpg'),
  1, 'file Storage di B non cancellato'
);

-- =====================================================================
-- Client anonimo (anon key, nessun token)
-- =====================================================================
set local role anon;
set local request.jwt.claim.sub = '';
set local request.jwt.claims = '{"role":"anon"}';

select is((select count(*)::int from profiles), 0, 'anon non vede profili');
select is((select count(*)::int from wallets), 0, 'anon non vede wallet');
select is((select count(*)::int from categories), 0, 'anon non vede categorie');
select is((select count(*)::int from tags), 0, 'anon non vede tag');
select is((select count(*)::int from transactions), 0, 'anon non vede transazioni');
select is((select count(*)::int from transaction_tags), 0, 'anon non vede transaction_tags');
select is((select count(*)::int from custom_field_defs), 0, 'anon non vede campi custom');
select is((select count(*)::int from custom_field_values), 0, 'anon non vede valori custom');
select is((select count(*)::int from budgets), 0, 'anon non vede budget');
select is((select count(*)::int from recurring_rules), 0, 'anon non vede ricorrenze');
select is((select count(*)::int from attachments), 0, 'anon non vede allegati');
select is((select count(*)::int from dashboard_cards), 0, 'anon non vede card');
select is((select count(*)::int from cost_centers), 0, 'anon non vede centri di costo');
select is((select count(*)::int from expense_reports), 0, 'anon non vede note spese');
select is((select count(*)::int from expense_report_entries), 0, 'anon non vede voci nota spese');
select is(
  (select count(*)::int from storage.objects where bucket_id = 'attachments'),
  0, 'anon non vede file in Storage'
);
select throws_ok(
  $$ insert into wallets (owner_user_id, name, color_hex)
     values ('11111111-1111-1111-1111-111111111111', 'anon', '#000000') $$,
  '42501', null, 'anon non può creare wallet'
);

reset role;
select * from finish();
rollback;
