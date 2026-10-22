-- nIpay — M-SOC2: richieste di amicizia e blocchi (mds/FRIENDS_PLAN.md)
--
-- Gira su un Supabase locale (Docker), mai sul progetto reale:
--   supabase db start && supabase test db
-- Tutto dentro una transazione annullata alla fine: nessun residuo.

begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

-- ---------------------------------------------------------------------
-- Seed (come postgres). A, B, C, D attivi; E ha chiesto la cancellazione.
-- ---------------------------------------------------------------------
insert into auth.users (id, email) values
  ('a1111111-1111-1111-1111-111111111111', 'fr-a@test.local'),
  ('b2222222-2222-2222-2222-222222222222', 'fr-b@test.local'),
  ('c3333333-3333-3333-3333-333333333333', 'fr-c@test.local'),
  ('d4444444-4444-4444-4444-444444444444', 'fr-d@test.local'),
  ('e5555555-5555-5555-5555-555555555555', 'fr-e@test.local');
update profiles set display_name = 'Anna',  friend_code = 'AAAAAAAAAA' where id = 'a1111111-1111-1111-1111-111111111111';
update profiles set display_name = 'Bea',   friend_code = 'BBBBBBBBBB' where id = 'b2222222-2222-2222-2222-222222222222';
update profiles set display_name = 'Carlo', friend_code = 'CCCCCCCCCC' where id = 'c3333333-3333-3333-3333-333333333333';
update profiles set display_name = 'Dario', friend_code = 'DDDDDDDDDD' where id = 'd4444444-4444-4444-4444-444444444444';
update profiles set display_name = 'Elsa',  friend_code = 'EEEEEEEEEE', deletion_requested_at = now()
 where id = 'e5555555-5555-5555-5555-555555555555';

select has_table('public', 'friendships', 'tabella friendships');
select has_table('public', 'blocks', 'tabella blocks');

-- =====================================================================
-- A invia una richiesta a B
-- =====================================================================
set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok($$ insert into friendships (requester_id, addressee_id)
  values ('a1111111-1111-1111-1111-111111111111', 'b2222222-2222-2222-2222-222222222222') $$,
  '42501', null, 'niente insert diretto: le richieste passano dalle RPC');

select is(send_friend_request('b2222222-2222-2222-2222-222222222222'), 'pending',
  'A → B: richiesta in attesa');
select is(send_friend_request('b2222222-2222-2222-2222-222222222222'), 'pending',
  'reinviare la stessa richiesta è idempotente');
select is((select count(*)::int from friendships), 1,
  'A vede una sola riga, la propria richiesta');
select throws_ok($$ update friendships set status = 'accepted' $$,
  '42501', null, 'A non può accettare da sé con un update diretto');
select throws_ok($$ select send_friend_request('a1111111-1111-1111-1111-111111111111') $$,
  'P0001', 'utente non disponibile', 'niente richieste a se stessi');
select throws_ok($$ select send_friend_request('99999999-9999-9999-9999-999999999999') $$,
  'P0001', 'utente non disponibile', 'utente inesistente: errore generico');
select throws_ok($$ select send_friend_request('e5555555-5555-5555-5555-555555555555') $$,
  'P0001', 'utente non disponibile', 'account in cancellazione: stesso errore generico');

select results_eq(
  $$ select direction, user_id, display_name, status from list_friend_requests() $$,
  $$ values ('outgoing'::text, 'b2222222-2222-2222-2222-222222222222'::uuid, 'Bea'::text, 'pending'::text) $$,
  'A vede la richiesta in uscita verso Bea');
select throws_ok($$ select respond_friend_request(
    (select id from friendships limit 1), true) $$,
  'P0001', 'richiesta non trovata', 'chi ha inviato non può accettare la propria richiesta');

-- =====================================================================
-- C (estraneo) non vede né tocca la richiesta A → B
-- =====================================================================
reset role;
create temp table req_ab as select id from friendships;
grant select on req_ab to authenticated;
set local role authenticated;
set local request.jwt.claim.sub = 'c3333333-3333-3333-3333-333333333333';
set local request.jwt.claims = '{"sub":"c3333333-3333-3333-3333-333333333333","role":"authenticated"}';

select is((select count(*)::int from friendships), 0, 'C non vede le richieste altrui');
select throws_ok($$ select respond_friend_request((select id from req_ab), true) $$,
  'P0001', 'richiesta non trovata', 'C non può accettare per conto di B');
select throws_ok($$ select cancel_friend_request((select id from req_ab)) $$,
  'P0001', 'richiesta non trovata', 'C non può annullare la richiesta di A');

-- =====================================================================
-- B accetta
-- =====================================================================
set local request.jwt.claim.sub = 'b2222222-2222-2222-2222-222222222222';
set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';

select results_eq(
  $$ select direction, user_id, display_name, status from list_friend_requests() $$,
  $$ values ('incoming'::text, 'a1111111-1111-1111-1111-111111111111'::uuid, 'Anna'::text, 'pending'::text) $$,
  'B vede la richiesta in arrivo da Anna');
select lives_ok($$ select respond_friend_request((select id from req_ab), true) $$,
  'B accetta la richiesta');
select results_eq($$ select user_id, display_name from list_friends() $$,
  $$ values ('a1111111-1111-1111-1111-111111111111'::uuid, 'Anna'::text) $$,
  'B vede Anna tra gli amici (solo id e nome)');
select is((select count(*)::int from list_friend_requests()), 0,
  'accettata: niente più richieste in sospeso per B');

set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select results_eq($$ select user_id, display_name from list_friends() $$,
  $$ values ('b2222222-2222-2222-2222-222222222222'::uuid, 'Bea'::text) $$,
  'A vede Bea tra gli amici');
select is(send_friend_request('b2222222-2222-2222-2222-222222222222'), 'accepted',
  'già amici: la richiesta risponde "accettata" senza duplicati');

-- =====================================================================
-- Richieste incrociate: la seconda accetta la prima
-- =====================================================================
set local request.jwt.claim.sub = 'c3333333-3333-3333-3333-333333333333';
set local request.jwt.claims = '{"sub":"c3333333-3333-3333-3333-333333333333","role":"authenticated"}';
select is(send_friend_request('d4444444-4444-4444-4444-444444444444'), 'pending', 'C → D in attesa');
set local request.jwt.claim.sub = 'd4444444-4444-4444-4444-444444444444';
set local request.jwt.claims = '{"sub":"d4444444-4444-4444-4444-444444444444","role":"authenticated"}';
select is(send_friend_request('c3333333-3333-3333-3333-333333333333'), 'accepted',
  'D → C mentre C → D è in attesa: amicizia accettata');
select is((select count(*)::int from list_friends()), 1, 'D ha un amico (C)');

-- =====================================================================
-- Rifiuto e attesa di 7 giorni
-- =====================================================================
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select is(send_friend_request('c3333333-3333-3333-3333-333333333333'), 'pending', 'A → C in attesa');

set local request.jwt.claim.sub = 'c3333333-3333-3333-3333-333333333333';
set local request.jwt.claims = '{"sub":"c3333333-3333-3333-3333-333333333333","role":"authenticated"}';
select lives_ok($$ select respond_friend_request(
    (select r.request_id from list_friend_requests() r where r.direction = 'incoming'), false) $$,
  'C rifiuta la richiesta di A');

set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select results_eq(
  $$ select direction, display_name, status from list_friend_requests() $$,
  $$ values ('outgoing'::text, 'Carlo'::text, 'declined'::text) $$,
  'A vede la propria richiesta come non accettata');
select throws_ok($$ select send_friend_request('c3333333-3333-3333-3333-333333333333') $$,
  'P0001', 'richiesta rifiutata di recente', 'dopo un rifiuto, niente nuova richiesta per 7 giorni');

reset role;
update friendships set responded_at = now() - interval '8 days'
 where requester_id = 'a1111111-1111-1111-1111-111111111111'
   and addressee_id = 'c3333333-3333-3333-3333-333333333333';
set local role authenticated;
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select is(send_friend_request('c3333333-3333-3333-3333-333333333333'), 'pending',
  'passati 7 giorni la richiesta si può rinviare');
select is((select count(*)::int from list_friend_requests() where status = 'declined'), 0,
  'il vecchio rifiuto non compare più');

-- Annullare una richiesta inviata
select lives_ok($$ select cancel_friend_request(
    (select r.request_id from list_friend_requests() r where r.user_id = 'c3333333-3333-3333-3333-333333333333')) $$,
  'A annulla la richiesta in attesa verso C');
select is((select count(*)::int from list_friend_requests()), 0, 'richiesta annullata sparita');

-- Rimuovere un amico
select lives_ok($$ select remove_friend('b2222222-2222-2222-2222-222222222222') $$, 'A rimuove B');
select is((select count(*)::int from list_friends()), 0, 'A non ha più B tra gli amici');
set local request.jwt.claim.sub = 'b2222222-2222-2222-2222-222222222222';
set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';
select is((select count(*)::int from list_friends()), 0, 'nemmeno B ha più A');

-- =====================================================================
-- Blocchi: D blocca A
-- =====================================================================
set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select is(send_friend_request('d4444444-4444-4444-4444-444444444444'), 'pending', 'A → D in attesa');

set local request.jwt.claim.sub = 'd4444444-4444-4444-4444-444444444444';
set local request.jwt.claims = '{"sub":"d4444444-4444-4444-4444-444444444444","role":"authenticated"}';
select lives_ok($$ select block_user('a1111111-1111-1111-1111-111111111111') $$, 'D blocca A');
select is((select count(*)::int from list_friend_requests()), 0,
  'bloccare cancella la richiesta in arrivo da A');
select results_eq($$ select user_id, display_name from list_blocked() $$,
  $$ values ('a1111111-1111-1111-1111-111111111111'::uuid, 'Anna'::text) $$,
  'D vede A tra i bloccati');
select throws_ok($$ select send_friend_request('a1111111-1111-1111-1111-111111111111') $$,
  'P0001', 'utente non disponibile', 'chi blocca non può inviare richieste al bloccato');
select throws_ok($$ insert into blocks (blocker_id, blocked_id)
  values ('d4444444-4444-4444-4444-444444444444', 'b2222222-2222-2222-2222-222222222222') $$,
  '42501', null, 'niente insert diretto nei blocchi: solo block_user');

set local request.jwt.claim.sub = 'a1111111-1111-1111-1111-111111111111';
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select is((select count(*)::int from blocks), 0, 'A non può sapere di essere bloccato');
select is((select count(*)::int from friendships), 0, 'A non vede più la richiesta verso D');
select is((select count(*)::int from resolve_friend_code('DDDDDDDDDD')), 0,
  'il codice di chi ti ha bloccato non porta a nessuno');
select throws_ok($$ select send_friend_request('d4444444-4444-4444-4444-444444444444') $$,
  'P0001', 'utente non disponibile', 'A bloccato: stesso errore di un utente inesistente');

-- Il blocco rompe anche un'amicizia esistente (C e D sono amici)
set local request.jwt.claim.sub = 'd4444444-4444-4444-4444-444444444444';
set local request.jwt.claims = '{"sub":"d4444444-4444-4444-4444-444444444444","role":"authenticated"}';
select lives_ok($$ select block_user('c3333333-3333-3333-3333-333333333333') $$, 'D blocca C');
select is((select count(*)::int from list_friends()), 0, 'bloccare rimuove l''amicizia');
select lives_ok($$ select unblock_user('c3333333-3333-3333-3333-333333333333') $$, 'D sblocca C');
select is((select count(*)::int from list_blocked()), 1, 'resta bloccato solo A');
select is((select count(*)::int from list_friends()), 0,
  'sbloccare non ripristina l''amicizia');

-- =====================================================================
-- Limiti: 20 richieste in attesa, 30 invii al giorno
-- =====================================================================
reset role;
insert into auth.users (id, email)
select ('f0000000-0000-0000-0000-' || lpad(i::text, 12, '0'))::uuid, 'fr-f' || i || '@test.local'
  from generate_series(1, 21) i;
insert into friendships (requester_id, addressee_id)
select 'b2222222-2222-2222-2222-222222222222',
       ('f0000000-0000-0000-0000-' || lpad(i::text, 12, '0'))::uuid
  from generate_series(1, 20) i;
set local role authenticated;
set local request.jwt.claim.sub = 'b2222222-2222-2222-2222-222222222222';
set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';
select throws_ok($$ select send_friend_request('f0000000-0000-0000-0000-000000000021') $$,
  'P0001', 'troppe richieste in attesa', 'oltre 20 richieste in attesa: rifiutata');

reset role;
insert into private.rate_limit_events (user_id, action)
select 'c3333333-3333-3333-3333-333333333333', 'send_friend_request'
  from generate_series(1, 30);
set local role authenticated;
set local request.jwt.claim.sub = 'c3333333-3333-3333-3333-333333333333';
set local request.jwt.claims = '{"sub":"c3333333-3333-3333-3333-333333333333","role":"authenticated"}';
select throws_ok($$ select send_friend_request('f0000000-0000-0000-0000-000000000021') $$,
  'P0001', 'troppe richieste', 'oltre 30 invii in 24 ore: rifiutato');

-- =====================================================================
-- Client anonimo
-- =====================================================================
reset role;
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select throws_ok($$ select send_friend_request('b2222222-2222-2222-2222-222222222222') $$,
  '42501', null, 'anonimo: niente richieste');
select throws_ok($$ select * from list_friends() $$, '42501', null, 'anonimo: niente lista amici');
select throws_ok($$ select block_user('b2222222-2222-2222-2222-222222222222') $$,
  '42501', null, 'anonimo: niente blocchi');
select throws_ok($$ select count(*) from friendships $$, '42501', null,
  'anonimo: niente lettura delle amicizie');

select * from finish();
rollback;
