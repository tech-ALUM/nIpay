-- nIpay — M-SOC5: cancellazione account, limiti di frequenza, export
-- (mds/FRIENDS_PLAN.md)
--
-- Gira su un Supabase locale (Docker), mai sul progetto reale:
--   supabase db start && supabase test db
-- Tutto dentro una transazione annullata alla fine: nessun residuo.

begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

-- ---------------------------------------------------------------------
-- Seed (come postgres). Amici: A–B, A–C, B–C, A–D.
-- ---------------------------------------------------------------------
insert into auth.users (id, email) values
  ('a1111111-1111-1111-1111-111111111111', 'del-a@test.local'),
  ('b2222222-2222-2222-2222-222222222222', 'del-b@test.local'),
  ('c3333333-3333-3333-3333-333333333333', 'del-c@test.local'),
  ('d4444444-4444-4444-4444-444444444444', 'del-d@test.local');
update profiles set display_name = 'Anna'  where id = 'a1111111-1111-1111-1111-111111111111';
update profiles set display_name = 'Bea'   where id = 'b2222222-2222-2222-2222-222222222222';
update profiles set display_name = 'Carlo' where id = 'c3333333-3333-3333-3333-333333333333';
update profiles set display_name = 'Dario' where id = 'd4444444-4444-4444-4444-444444444444';
insert into friendships (requester_id, addressee_id, status, responded_at) values
  ('a1111111-1111-1111-1111-111111111111', 'b2222222-2222-2222-2222-222222222222', 'accepted', now()),
  ('a1111111-1111-1111-1111-111111111111', 'c3333333-3333-3333-3333-333333333333', 'accepted', now()),
  ('b2222222-2222-2222-2222-222222222222', 'c3333333-3333-3333-3333-333333333333', 'accepted', now()),
  ('a1111111-1111-1111-1111-111111111111', 'd4444444-4444-4444-4444-444444444444', 'accepted', now());
insert into blocks (blocker_id, blocked_id) values
  ('c3333333-3333-3333-3333-333333333333', 'd4444444-4444-4444-4444-444444444444');

-- A crea un gruppo con B e C, una cena pagata da A; C scrive e segnala.
set local role authenticated;
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select set_config('test.grp', create_group('Viaggio', array[
  'b2222222-2222-2222-2222-222222222222'::uuid,
  'c3333333-3333-3333-3333-333333333333'::uuid])::text, true);
select set_config('test.dinner', create_shared_expense('Cena', 6000, 'EUR', current_date,
  'a1111111-1111-1111-1111-111111111111',
  jsonb_build_array(
    jsonb_build_object('user_id', 'a1111111-1111-1111-1111-111111111111', 'share_cents', 2000),
    jsonb_build_object('user_id', 'b2222222-2222-2222-2222-222222222222', 'share_cents', 2000),
    jsonb_build_object('user_id', 'c3333333-3333-3333-3333-333333333333', 'share_cents', 2000)))::text, true);
select set_config('test.amsg',
  (select message_id::text from send_message(current_setting('test.grp')::uuid, 'ciao da Anna')), true);

set local request.jwt.claims = '{"sub":"c3333333-3333-3333-3333-333333333333","role":"authenticated"}';
select set_config('test.cmsg',
  (select message_id::text from send_message(current_setting('test.grp')::uuid, 'ciao da Carlo')), true);
select delete_message(current_setting('test.cmsg')::uuid);
select report_message(current_setting('test.amsg')::uuid, 'spam');
select record_settlement('a1111111-1111-1111-1111-111111111111', 500, 'EUR');

-- =====================================================================
-- Nei 30 giorni di attesa: solo leggere e chiudere i debiti
-- =====================================================================
reset role;
update profiles set deletion_requested_at = now()
 where id = 'b2222222-2222-2222-2222-222222222222';
set local role authenticated;
set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';

select throws_ok($$ select send_message(current_setting('test.grp')::uuid, 'ci sono ancora') $$,
  'P0001', 'account in cancellazione', 'in cancellazione: niente messaggi nei gruppi');
select throws_ok($$ select open_direct_conversation('a1111111-1111-1111-1111-111111111111') $$,
  'P0001', 'account in cancellazione', 'in cancellazione: niente nuove chat');
select throws_ok($$ select create_group('Nuovo', array['a1111111-1111-1111-1111-111111111111'::uuid]) $$,
  'P0001', 'account in cancellazione', 'in cancellazione: niente nuovi gruppi');
select throws_ok($$ select send_friend_request('d4444444-4444-4444-4444-444444444444') $$,
  'P0001', 'account in cancellazione', 'in cancellazione: niente richieste di amicizia');
select throws_ok($$ select create_shared_expense('Pizza', 2000, 'EUR', current_date,
    'b2222222-2222-2222-2222-222222222222',
    jsonb_build_array(
      jsonb_build_object('user_id', 'b2222222-2222-2222-2222-222222222222', 'share_cents', 1000),
      jsonb_build_object('user_id', 'a1111111-1111-1111-1111-111111111111', 'share_cents', 1000))) $$,
  'P0001', 'account in cancellazione', 'in cancellazione: niente nuove spese divise');
select is((select count(*)::int from list_messages(current_setting('test.grp')::uuid)),
  2, 'in cancellazione la chat si legge ancora (anche il messaggio eliminato)');
select lives_ok($$ select register_my_share(current_setting('test.dinner')::uuid) $$,
  'in cancellazione si registra ancora la propria quota');
select lives_ok($$ select record_settlement('a1111111-1111-1111-1111-111111111111', 2000, 'EUR') $$,
  'in cancellazione si saldano ancora i debiti');

reset role;
update profiles set deletion_requested_at = null
 where id = 'b2222222-2222-2222-2222-222222222222';
set local role authenticated;
set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';
select lives_ok($$ select send_message(current_setting('test.grp')::uuid, 'sono tornata') $$,
  'annullata la cancellazione, si scrive di nuovo');

-- =====================================================================
-- Limiti di frequenza non coperti dagli altri file
-- =====================================================================
set local request.jwt.claims = '{"sub":"d4444444-4444-4444-4444-444444444444","role":"authenticated"}';
-- Le chiamate stanno nella lista di una sottoquery: così una funzione
-- volatile gira per ogni riga (in un lateral senza dipendenze da g
-- girerebbe una volta sola).
select throws_ok($$ select count(*) from (select regenerate_friend_code()
    from generate_series(1, 6)) x $$,
  'P0001', 'troppe richieste', 'codice amico: al massimo 5 rigenerazioni in 24 ore');
select throws_ok($$ select count(*) from (select resolve_friend_code('ZZZZZZZZZZ')
    from generate_series(1, 31)) x $$,
  'P0001', 'troppe richieste', 'ricerca per codice: al massimo 30 all''ora');
select throws_ok($$ select count(*) from generate_series(1, 21) g,
    lateral create_group('G' || g, array['a1111111-1111-1111-1111-111111111111'::uuid]) $$,
  'P0001', 'troppe richieste', 'al massimo 20 gruppi nuovi in 24 ore');
select throws_ok($$ select count(*) from generate_series(1, 51) g,
    lateral create_shared_expense('S' || g, 200, 'EUR', current_date,
      'd4444444-4444-4444-4444-444444444444',
      jsonb_build_array(
        jsonb_build_object('user_id', 'd4444444-4444-4444-4444-444444444444', 'share_cents', 100),
        jsonb_build_object('user_id', 'a1111111-1111-1111-1111-111111111111', 'share_cents', 100))) $$,
  'P0001', 'troppe richieste', 'al massimo 50 spese divise nuove in 24 ore');
select throws_ok($$ select count(*) from (select report_user(
    'a1111111-1111-1111-1111-111111111111', 'spam') from generate_series(1, 21)) x $$,
  'P0001', 'troppe richieste', 'al massimo 20 segnalazioni in 24 ore');

-- Rimborsi: A deve 50 € a D, li rende un centesimo alla volta.
set local request.jwt.claims = '{"sub":"d4444444-4444-4444-4444-444444444444","role":"authenticated"}';
select create_shared_expense('Grande', 10000, 'EUR', current_date,
  'd4444444-4444-4444-4444-444444444444',
  jsonb_build_array(
    jsonb_build_object('user_id', 'd4444444-4444-4444-4444-444444444444', 'share_cents', 5000),
    jsonb_build_object('user_id', 'a1111111-1111-1111-1111-111111111111', 'share_cents', 5000)));
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select throws_ok($$ select count(*) from (select record_settlement(
    'd4444444-4444-4444-4444-444444444444', 1, 'EUR') from generate_series(1, 31)) x $$,
  'P0001', 'troppe richieste', 'al massimo 30 rimborsi registrati in 24 ore');

-- =====================================================================
-- Segnalazione chiusa: la copia del messaggio sparisce
-- =====================================================================
reset role;
select isnt((select message_body from reports
              where message_id = current_setting('test.amsg')::uuid),
  null, 'segnalazione aperta: la copia del messaggio c''è');
update reports set resolved_at = now()
 where message_id = current_setting('test.amsg')::uuid;
select is((select message_body from reports
            where message_id = current_setting('test.amsg')::uuid),
  null, 'segnalazione chiusa: la copia del messaggio sparisce');

-- =====================================================================
-- Export su richiesta: solo service_role
-- =====================================================================
select is(has_function_privilege('authenticated', 'private.export_user_data(uuid)', 'execute'),
  false, 'l''app non può chiamare l''export');
select is(has_function_privilege('anon', 'private.export_user_data(uuid)', 'execute'),
  false, 'un anonimo non può chiamare l''export');
select is(has_function_privilege('service_role', 'private.export_user_data(uuid)', 'execute'),
  true, 'il titolare (service_role) può chiamare l''export');
select set_config('test.export',
  private.export_user_data('c3333333-3333-3333-3333-333333333333')::text, true);
select ok(current_setting('test.export')::jsonb ?& array[
    'account', 'profile', 'wallets', 'transactions', 'friendships', 'blocks',
    'conversations', 'messages_sent', 'reports_made', 'shared_expenses', 'settlements'],
  'l''export contiene finanze, amicizie, chat, spese divise e rimborsi');
select is((select body from jsonb_to_recordset(current_setting('test.export')::jsonb -> 'messages_sent')
             as m(body text)),
  'ciao da Carlo', 'l''export riporta anche il testo dei propri messaggi eliminati');
select is(jsonb_array_length(current_setting('test.export')::jsonb -> 'shared_expenses'),
  1, 'l''export contiene le spese divise a cui si partecipa');
select ok(current_setting('test.export') not like '%encrypted_password%'
          and current_setting('test.export') not like '%recovery_token%',
  'l''export non contiene password né token');

-- =====================================================================
-- Cancellazione definitiva di C (quello che fa purge-deleted-accounts)
-- =====================================================================
delete from auth.users where id = 'c3333333-3333-3333-3333-333333333333';

select is((select count(*)::int from friendships
            where 'c3333333-3333-3333-3333-333333333333' in (requester_id, addressee_id)),
  0, 'amicizie e richieste cancellate');
select is((select count(*)::int from blocks
            where 'c3333333-3333-3333-3333-333333333333' in (blocker_id, blocked_id)),
  0, 'blocchi cancellati');
select is((select count(*)::int from conversation_members
            where user_id = 'c3333333-3333-3333-3333-333333333333'),
  0, 'uscito da tutti i gruppi');
select is((select count(*)::int from conversation_reads
            where user_id = 'c3333333-3333-3333-3333-333333333333'),
  0, 'ore di lettura cancellate');
select results_eq(
  $$ select sender_id, body from messages where id = current_setting('test.cmsg')::uuid $$,
  $$ values (null::uuid, null::text) $$,
  'i suoi messaggi diventano "Messaggio eliminato" di "Utente eliminato"');
select is((select count(*)::int from private.deleted_message_bodies
            where message_id = current_setting('test.cmsg')::uuid),
  0, 'il testo dei suoi messaggi eliminati sparisce');
select is((select count(*)::int from shared_expense_shares
            where shared_expense_id = current_setting('test.dinner')::uuid and user_id is null),
  1, 'la sua quota resta, anonima, e i saldi degli altri non cambiano');
select is((select count(*)::int from settlements where from_user is null),
  1, 'i suoi rimborsi restano, anonimi');
select is((select count(*)::int from reports where reporter_id is null),
  1, 'le sue segnalazioni restano, senza autore');
select is((select count(*)::int from private.rate_limit_events
            where user_id = 'c3333333-3333-3333-3333-333333333333'),
  0, 'i suoi contatori dei limiti spariscono');
select is((select count(*)::int from profiles
            where id = 'c3333333-3333-3333-3333-333333333333'),
  0, 'profilo cancellato');

select * from finish();
rollback;
