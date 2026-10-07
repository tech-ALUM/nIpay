-- nIpay — regressione delle correzioni di SECURITY_AUDIT.md (lato database)
--
-- Gira su un Supabase locale (Docker), mai sul progetto reale:
--   supabase start && supabase test db
-- Ogni test descrive il comportamento CORRETTO dopo le correzioni (il file
-- dell'audit, Appendice D, asseriva i difetti). Tutto dentro una
-- transazione annullata alla fine: nessun residuo.

begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

-- ---------------------------------------------------------------------
-- Seed (come postgres, RLS bypassata)
-- ---------------------------------------------------------------------
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'sec-a@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'sec-b@test.local');
insert into wallets (id, owner_user_id, name, color_hex) values
  ('a0000000-0000-0000-0000-000000000001', '11111111-1111-1111-1111-111111111111', 'Wallet A', '#111111'),
  ('a0000000-0000-0000-0000-0000000000a9', '11111111-1111-1111-1111-111111111111', 'Wallet A2', '#111111'),
  ('b0000000-0000-0000-0000-000000000001', '22222222-2222-2222-2222-222222222222', 'Wallet B', '#222222');
insert into categories (id, wallet_id, name, icon, color_hex, kind) values
  ('a0000000-0000-0000-0000-000000000002', 'a0000000-0000-0000-0000-000000000001', 'Cat A', 'cart', '#111111', 'expense'),
  ('a0000000-0000-0000-0000-0000000000a2', 'a0000000-0000-0000-0000-0000000000a9', 'Cat A2', 'cart', '#111111', 'expense'),
  ('b0000000-0000-0000-0000-000000000002', 'b0000000-0000-0000-0000-000000000001', 'Cat B', 'cart', '#222222', 'expense'),
  ('b0000000-0000-0000-0000-0000000000b2', 'b0000000-0000-0000-0000-000000000001', 'Cat B2', 'cart', '#222222', 'expense');
insert into budgets (id, wallet_id, category_id, limit_cents) values
  ('b0000000-0000-0000-0000-000000000006', 'b0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 2000);
insert into tags (id, wallet_id, name) values
  ('a0000000-0000-0000-0000-000000000003', 'a0000000-0000-0000-0000-000000000001', 'tag A');
insert into custom_field_defs (id, wallet_id, name, type) values
  ('a0000000-0000-0000-0000-000000000005', 'a0000000-0000-0000-0000-000000000001', 'campo A', 'text');
insert into transactions (id, wallet_id, type, amount_cents, date, category_id) values
  ('a0000000-0000-0000-0000-00000000000c', 'a0000000-0000-0000-0000-000000000001', 'expense', 100, now(), 'a0000000-0000-0000-0000-000000000002'),
  ('a0000000-0000-0000-0000-00000000000d', 'a0000000-0000-0000-0000-000000000001', 'expense', 100, now(), null);
insert into cost_centers (id, wallet_id, name) values
  ('a0000000-0000-0000-0000-00000000000a', 'a0000000-0000-0000-0000-000000000001', 'CdC A'),
  ('a0000000-0000-0000-0000-0000000000aa', 'a0000000-0000-0000-0000-0000000000a9', 'CdC A2'),
  ('b0000000-0000-0000-0000-00000000000a', 'b0000000-0000-0000-0000-000000000001', 'CdC B');
insert into expense_reports (id, wallet_id, name, date_from, date_to, status) values
  ('b0000000-0000-0000-0000-00000000000b', 'b0000000-0000-0000-0000-000000000001', 'Nota B', now(), now(), 'draft');
update profiles set deletion_requested_at = null;

-- =====================================================================
-- NIP-12: limiti del bucket
-- =====================================================================
select is((select file_size_limit from storage.buckets where id = 'attachments'),
  10485760::bigint, 'NIP-12: bucket attachments con file_size_limit 10 MiB');
select is((select allowed_mime_types from storage.buckets where id = 'attachments'),
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf'],
  'NIP-12: bucket attachments limitato a immagini e PDF');

-- =====================================================================
-- Utente A
-- =====================================================================
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

-- NIP-07: niente riferimenti verso righe di B --------------------------
select throws_ok($$ insert into transactions (wallet_id, type, amount_cents, date, category_id)
  values ('a0000000-0000-0000-0000-000000000001', 'expense', 1, now(), 'b0000000-0000-0000-0000-000000000002') $$,
  '23503', null, 'NIP-07: A non può usare la categoria di B su una propria transazione');
select throws_ok($$ insert into transactions (wallet_id, type, amount_cents, date, category_id)
  values ('a0000000-0000-0000-0000-000000000001', 'expense', 1, now(), '99999999-9999-9999-9999-999999999999') $$,
  '23503', null, 'NIP-07: UUID inesistente dà lo stesso errore dell''UUID di B (nessun oracolo)');
select throws_ok($$ insert into categories (wallet_id, name, icon, color_hex, kind, parent_id)
  values ('a0000000-0000-0000-0000-000000000001', 'x', 'x', '#000000', 'expense', 'b0000000-0000-0000-0000-000000000002') $$,
  '23503', null, 'NIP-07: A non può usare la categoria di B come parent');
select throws_ok($$ insert into recurring_rules (wallet_id, category_id, type, amount_cents, frequency, start_at, next_run_at)
  values ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 'expense', 1, 'monthly', now(), now()) $$,
  '23503', null, 'NIP-07: A non può usare la categoria di B in una ricorrenza');
select throws_ok($$ insert into budgets (wallet_id, category_id, limit_cents)
  values ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-000000000002', 1) $$,
  '23503', null, 'NIP-07: budget sulla categoria di B rifiutato come un UUID inesistente (nessun oracolo 23505)');
select throws_ok($$ insert into budgets (wallet_id, category_id, limit_cents)
  values ('a0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-0000000000b2', 1) $$,
  '23503', null, 'NIP-07: A non può occupare il budget su una categoria di B');
select throws_ok($$ insert into expense_report_entries (transaction_id, cost_center_id)
  values ('a0000000-0000-0000-0000-00000000000c', 'b0000000-0000-0000-0000-00000000000a') $$,
  '42501', null, 'NIP-07: A non può usare il centro di costo di B');
select throws_ok($$ insert into expense_report_entries (transaction_id, report_id)
  values ('a0000000-0000-0000-0000-00000000000c', 'b0000000-0000-0000-0000-00000000000b') $$,
  '42501', null, 'NIP-07: A non può agganciare la nota spese di B');
select throws_ok($$ insert into expense_report_entries (transaction_id, cost_center_id)
  values ('a0000000-0000-0000-0000-00000000000c', '99999999-9999-9999-9999-999999999999') $$,
  '42501', null, 'NIP-07: centro di costo inesistente → stesso errore (nessun oracolo)');
-- Integrità anche dentro il tenant: categorie e centri di costo restano
-- nel portafoglio di appartenenza.
select throws_ok($$ insert into transactions (wallet_id, type, amount_cents, date, category_id)
  values ('a0000000-0000-0000-0000-000000000001', 'expense', 1, now(), 'a0000000-0000-0000-0000-0000000000a2') $$,
  '23503', null, 'NIP-07: niente categoria di un altro portafoglio (stesso utente)');
select throws_ok($$ insert into expense_report_entries (transaction_id, cost_center_id)
  values ('a0000000-0000-0000-0000-00000000000c', 'a0000000-0000-0000-0000-0000000000aa') $$,
  '42501', null, 'NIP-07: niente centro di costo di un altro portafoglio (stesso utente)');
-- I casi legittimi continuano a funzionare.
select lives_ok($$ insert into transactions (wallet_id, type, amount_cents, date, category_id)
  values ('a0000000-0000-0000-0000-000000000001', 'expense', 1, now(), 'a0000000-0000-0000-0000-000000000002') $$,
  'NIP-07: A usa la propria categoria');
select lives_ok($$ insert into budgets (id, wallet_id, category_id, limit_cents)
  values ('a0000000-0000-0000-0000-000000000006', 'a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 1000) $$,
  'NIP-07: A crea il budget sulla propria categoria');
select lives_ok($$ insert into expense_report_entries (transaction_id, cost_center_id)
  values ('a0000000-0000-0000-0000-00000000000c', 'a0000000-0000-0000-0000-00000000000a') $$,
  'NIP-07: A usa il proprio centro di costo');

-- NIP-04: un solo budget vivo per categoria nel portafoglio ------------
select throws_ok($$ insert into budgets (wallet_id, category_id, limit_cents)
  values ('a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 5) $$,
  '23505', null, 'NIP-04: secondo budget vivo sulla stessa categoria rifiutato');
update budgets set deleted_at = now(), modified_at = clock_timestamp()
  where id = 'a0000000-0000-0000-0000-000000000006';
select lives_ok($$ insert into budgets (wallet_id, category_id, limit_cents)
  values ('a0000000-0000-0000-0000-000000000001', 'a0000000-0000-0000-0000-000000000002', 5) $$,
  'NIP-04: dopo il soft-delete si può ricreare il budget sulla categoria');

-- NIP-05: richiesta di cancellazione solo via RPC ----------------------
select throws_ok($$ update profiles set deletion_requested_at = '2000-01-01T00:00:00Z'
  where id = '11111111-1111-1111-1111-111111111111' $$,
  '42501', null, 'NIP-05: A non può scrivere deletion_requested_at direttamente');
select throws_ok($$ select request_account_deletion() $$,
  '42501', null, 'NIP-05: senza autenticazione recente (amr) la richiesta è rifiutata');
-- Token con login di 2 ore fa: non basta.
select set_config('request.jwt.claims',
  json_build_object('sub', '11111111-1111-1111-1111-111111111111', 'role', 'authenticated',
    'amr', json_build_array(json_build_object('method', 'password',
      'timestamp', extract(epoch from now() - interval '2 hours')::bigint)))::text, true);
select throws_ok($$ select request_account_deletion() $$,
  '42501', null, 'NIP-05: login vecchio di 2 ore → riautenticazione richiesta');
-- Password appena reinserita: la richiesta passa e la data è del server.
select set_config('request.jwt.claims',
  json_build_object('sub', '11111111-1111-1111-1111-111111111111', 'role', 'authenticated',
    'amr', json_build_array(json_build_object('method', 'password',
      'timestamp', extract(epoch from now())::bigint)))::text, true);
select is(request_account_deletion(), now(), 'NIP-05: la data della richiesta è now() del server');
select is((select deletion_requested_at from profiles where id = '11111111-1111-1111-1111-111111111111'),
  now(), 'NIP-05: deletion_requested_at salvato con l''ora del server');
select lives_ok($$ select cancel_account_deletion() $$, 'NIP-05: A annulla la richiesta');
select is((select deletion_requested_at from profiles where id = '11111111-1111-1111-1111-111111111111'),
  null, 'NIP-05: richiesta annullata');
select throws_ok($$ select purge_candidates(10) $$, '42501', null,
  'NIP-06/19: purge_candidates non eseguibile da un utente');
select throws_ok($$ select log_account_event('11111111-1111-1111-1111-111111111111', 'x') $$, '42501', null,
  'NIP-19: audit log non scrivibile da un utente');

-- NIP-02: timestamp assegnati dal server --------------------------------
insert into wallets (id, owner_user_id, name, color_hex, updated_at, modified_at, created_at)
  values ('a0000000-0000-0000-0000-0000000000a2', '11111111-1111-1111-1111-111111111111', 'W2', '#000000',
          '2099-01-01T00:00:00Z', '2099-01-01T00:00:00Z', '2099-01-01T00:00:00Z');
select ok((select updated_at <= clock_timestamp() from wallets where id = 'a0000000-0000-0000-0000-0000000000a2'),
  'NIP-02: updated_at futuro ignorato in INSERT (assegnato dal server)');
select ok((select modified_at <= clock_timestamp() and created_at <= clock_timestamp()
           from wallets where id = 'a0000000-0000-0000-0000-0000000000a2'),
  'NIP-02: modified_at e created_at mai nel futuro');
insert into custom_field_values (transaction_id, field_id, value, updated_at)
  values ('a0000000-0000-0000-0000-00000000000c', 'a0000000-0000-0000-0000-000000000005', 'v', '2099-01-01T00:00:00Z');
select ok((select updated_at <= clock_timestamp() from custom_field_values
           where transaction_id = 'a0000000-0000-0000-0000-00000000000c'),
  'NIP-02: custom_field_values.updated_at del client ignorato');
insert into transaction_tags (transaction_id, tag_id, created_at)
  values ('a0000000-0000-0000-0000-00000000000c', 'a0000000-0000-0000-0000-000000000003', '2099-01-01T00:00:00Z');
insert into transaction_tags (transaction_id, tag_id, created_at, modified_at)
  values ('a0000000-0000-0000-0000-00000000000c', 'a0000000-0000-0000-0000-000000000003', '2099-06-01T00:00:00Z', '2099-06-01T00:00:00Z')
  on conflict (transaction_id, tag_id) do update
    set created_at = excluded.created_at, modified_at = excluded.modified_at;
select ok((select created_at <= clock_timestamp() and updated_at <= clock_timestamp()
           from transaction_tags where transaction_id = 'a0000000-0000-0000-0000-00000000000c'),
  'NIP-02: transaction_tags senza timestamp futuri, anche dopo un upsert');

-- NIP-03: last-write-wins sul server ------------------------------------
update transactions set amount_cents = 500, modified_at = clock_timestamp()
  where id = 'a0000000-0000-0000-0000-00000000000d';
update transactions set amount_cents = 999, modified_at = '2000-01-01T00:00:00Z'
  where id = 'a0000000-0000-0000-0000-00000000000d';
select is((select amount_cents from transactions where id = 'a0000000-0000-0000-0000-00000000000d'),
  500::bigint, 'NIP-03: una modifica più vecchia non sovrascrive quella più recente');
update transactions set deleted_at = clock_timestamp(), modified_at = clock_timestamp()
  where id = 'a0000000-0000-0000-0000-00000000000d';
insert into transactions (id, wallet_id, type, amount_cents, date, deleted_at, modified_at)
  values ('a0000000-0000-0000-0000-00000000000d', 'a0000000-0000-0000-0000-000000000001', 'expense', 1, now(), null, now() - interval '1 hour')
  on conflict (id) do update
    set deleted_at = excluded.deleted_at, amount_cents = excluded.amount_cents, modified_at = excluded.modified_at;
select isnt((select deleted_at from transactions where id = 'a0000000-0000-0000-0000-00000000000d'),
  null, 'NIP-03: un push basato su una versione precedente non annulla il tombstone');
update transactions set amount_cents = 777
  where id = 'a0000000-0000-0000-0000-00000000000c';
select is((select amount_cents from transactions where id = 'a0000000-0000-0000-0000-00000000000c'),
  777::bigint, 'NIP-03: un update senza modified_at (client non aggiornato) vale come modifica di adesso');
select ok((select modified_at <= clock_timestamp() and modified_at > now() - interval '1 minute'
           from transactions where id = 'a0000000-0000-0000-0000-00000000000c'),
  'NIP-03: ... e riceve un modified_at del server');

-- NIP-04/12: vincoli di dominio -----------------------------------------
select throws_ok($$ insert into custom_field_defs (wallet_id, name, type, options)
  values ('a0000000-0000-0000-0000-000000000001', 'x', 'choice', '{"non":"una lista"}'::jsonb) $$,
  '23514', null, 'NIP-04: options non-array rifiutato');
select throws_ok($$ insert into custom_field_defs (wallet_id, name, type, options)
  values ('a0000000-0000-0000-0000-000000000001', 'x', 'choice', '[1, 2]'::jsonb) $$,
  '23514', null, 'NIP-04: options con elementi non stringa rifiutato');
select lives_ok($$ insert into custom_field_defs (wallet_id, name, type, options)
  values ('a0000000-0000-0000-0000-000000000001', 'x', 'choice', '["a", "b"]'::jsonb) $$,
  'NIP-04: options lista di stringhe accettato');
select throws_ok($$ insert into wallets (owner_user_id, name, color_hex)
  values ('11111111-1111-1111-1111-111111111111', 'x', 'zzz') $$,
  '23514', null, 'NIP-04: color_hex non valido rifiutato');
select throws_ok($$ insert into wallets (owner_user_id, name, color_hex, currency)
  values ('11111111-1111-1111-1111-111111111111', 'x', '#000000', 'NON-UNA-VALUTA') $$,
  '23514', null, 'NIP-04: currency non ISO rifiutata');
select throws_ok($$ insert into transactions (wallet_id, type, amount_cents, date)
  values ('a0000000-0000-0000-0000-000000000001', 'expense', -50000, now()) $$,
  '23514', null, 'NIP-04: importo negativo rifiutato');
select throws_ok($$ insert into transactions (wallet_id, type, amount_cents, date, description)
  values ('a0000000-0000-0000-0000-000000000001', 'expense', 1, now(), repeat('x', 1000000)) $$,
  '23514', null, 'NIP-04/12: descrizione da 1 MB rifiutata');
select throws_ok($$ insert into dashboard_cards (wallet_id, type, position, config_json)
  values ('a0000000-0000-0000-0000-000000000001', 'cashflow', 0, '[1]'::jsonb) $$,
  '23514', null, 'NIP-04: config_json non oggetto rifiutato');

-- NIP-25: storage_path coerente con proprietario e id -------------------
select throws_ok($$ insert into attachments (id, transaction_id, mime_type, storage_path)
  values ('a0000000-0000-0000-0000-0000000000e2', 'a0000000-0000-0000-0000-00000000000c', 'image/jpeg',
          '22222222-2222-2222-2222-222222222222/a0000000-0000-0000-0000-0000000000e2.jpg') $$,
  '23514', null, 'NIP-25: storage_path nel prefisso di un altro utente rifiutato');
select lives_ok($$ insert into attachments (id, transaction_id, mime_type, storage_path)
  values ('a0000000-0000-0000-0000-0000000000e3', 'a0000000-0000-0000-0000-00000000000c', 'image/jpeg',
          '11111111-1111-1111-1111-111111111111/a0000000-0000-0000-0000-0000000000e3.jpg') $$,
  'NIP-25: storage_path {uid}/{id}.{ext} accettato');

-- NIP-12: nomi e quota dei file Storage -----------------------------------
select throws_ok($$ insert into storage.objects (bucket_id, name)
  values ('attachments', '11111111-1111-1111-1111-111111111111/pagina.html') $$,
  '42501', null, 'NIP-12: nome file arbitrario rifiutato');
select throws_ok($$ insert into storage.objects (bucket_id, name)
  values ('attachments', '11111111-1111-1111-1111-111111111111/sub/a0000000-0000-0000-0000-0000000000e4.jpg') $$,
  '42501', null, 'NIP-12: sottocartelle rifiutate');
select lives_ok($$ insert into storage.objects (bucket_id, name)
  values ('attachments', '11111111-1111-1111-1111-111111111111/a0000000-0000-0000-0000-0000000000e4.jpg') $$,
  'NIP-12: {uid}/{uuid}.jpg accettato');

-- Azioni referenziali interne: la cancellazione di una categoria azzera
-- category_id nelle transazioni (il trigger LWW non deve bloccarle).
reset role;
delete from categories where id = 'a0000000-0000-0000-0000-000000000002';
select is((select count(*)::int from transactions
           where wallet_id = 'a0000000-0000-0000-0000-000000000001' and category_id is not null),
  0, 'ON DELETE SET NULL (category_id) funziona con il trigger LWW');
select is((select wallet_id from transactions where id = 'a0000000-0000-0000-0000-00000000000c'),
  'a0000000-0000-0000-0000-000000000001'::uuid, 'SET NULL (category_id) non tocca wallet_id');

-- =====================================================================
-- Utente B: lo "squatting" del budget non è più possibile
-- =====================================================================
set local role authenticated;
set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
select lives_ok($$ insert into budgets (id, wallet_id, category_id, limit_cents)
  values ('b0000000-0000-0000-0000-0000000000c1', 'b0000000-0000-0000-0000-000000000001', 'b0000000-0000-0000-0000-0000000000b2', 500)
  on conflict (id) do update set limit_cents = excluded.limit_cents $$,
  'NIP-07: B crea/sincronizza il budget sulla propria categoria');

-- =====================================================================
-- NIP-21: superficie RPC e ruoli delle policy
-- =====================================================================
reset role;
select is((select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname = 'public' and p.proname like 'owns\_%'),
  0, 'NIP-21: nessuna funzione owns_* nello schema esposto');
select ok(not has_function_privilege('anon', 'private.owns_wallet(uuid)', 'execute'),
  'NIP-21: anon non può eseguire owns_wallet');
select ok(not has_function_privilege('anon', 'public.request_account_deletion()', 'execute'),
  'NIP-21: anon non può chiamare request_account_deletion');
select ok(not has_function_privilege('authenticated', 'public.purge_candidates(integer)', 'execute'),
  'NIP-21: authenticated non può chiamare purge_candidates');
select is((select count(*)::int from pg_policies
           where (schemaname = 'public'
                  or (schemaname = 'storage' and policyname like '% own attachment files'))
             and roles <> '{authenticated}'),
  0, 'NIP-21: tutte le policy dell''app valgono solo per authenticated');
select is((select count(*)::int from pg_proc p join pg_namespace n on n.oid = p.pronamespace
           where n.nspname in ('public', 'private') and p.prosecdef is false
             and p.prolang <> (select oid from pg_language where lanname = 'c')
             and not exists (select 1 from unnest(coalesce(p.proconfig, '{}')) c where c like 'search_path=%')),
  0, 'NIP-21: tutte le funzioni dell''app hanno search_path fissato');

-- =====================================================================
-- NIP-06/19: supporto alla purge (service_role) e cascata completa
-- =====================================================================
update profiles set deletion_requested_at = now() - interval '31 days'
  where id = '22222222-2222-2222-2222-222222222222';
set local role service_role;
select is((select array_agg(user_id) from purge_candidates(10)),
  array['22222222-2222-2222-2222-222222222222'::uuid],
  'NIP-06: purge_candidates restituisce solo gli account con grace period scaduto');
select is((select count(*)::int from purge_candidates(0)), 0, 'NIP-19: il tetto per esecuzione è rispettato');
select lives_ok($$ select log_account_event('22222222-2222-2222-2222-222222222222', 'account_purged', '{"files": 0}') $$,
  'NIP-19: la service_role scrive nell''audit log');
select is(count_user_storage_objects('22222222-2222-2222-2222-222222222222'), 0::bigint,
  'NIP-06: conteggio degli oggetti Storage residui');
reset role;
-- La cancellazione dell'utente (deleteUser) deve passare con i nuovi
-- vincoli e trigger: cascata su portafogli, categorie, transazioni...
select lives_ok($$ delete from auth.users where id = '22222222-2222-2222-2222-222222222222' $$,
  'NIP-06: la cancellazione dell''utente B riesce (cascata completa)');
select is((select count(*)::int from wallets where owner_user_id = '22222222-2222-2222-2222-222222222222'),
  0, 'NIP-06: nessun portafoglio di B resta dopo la cancellazione');
select is((select count(*)::int from categories where wallet_id = 'b0000000-0000-0000-0000-000000000001'),
  0, 'NIP-06: nessuna categoria di B resta dopo la cancellazione');
select is((select count(*)::int from private.account_audit_log
           where user_id = '22222222-2222-2222-2222-222222222222'),
  1, 'NIP-19: l''audit log sopravvive alla cancellazione dell''utente');

select * from finish();
rollback;
