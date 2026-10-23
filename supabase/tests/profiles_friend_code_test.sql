-- nIpay — M-SOC1: nome visualizzato e codice amico (mds/FRIENDS_PLAN.md)
--
-- Gira su un Supabase locale (Docker), mai sul progetto reale:
--   supabase db start && supabase test db
-- Tutto dentro una transazione annullata alla fine: nessun residuo.

begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

-- ---------------------------------------------------------------------
-- Seed (come postgres, RLS bypassata). Il trigger su auth.users crea i
-- profili e assegna il codice amico.
-- ---------------------------------------------------------------------
insert into auth.users (id, email) values
  ('11111111-1111-1111-1111-111111111111', 'friend-a@test.local'),
  ('22222222-2222-2222-2222-222222222222', 'friend-b@test.local'),
  ('33333333-3333-3333-3333-333333333333', 'friend-c@test.local');

select ok(
  (select bool_and(friend_code ~ '^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{10}$')
     from profiles
    where id in ('11111111-1111-1111-1111-111111111111',
                 '22222222-2222-2222-2222-222222222222',
                 '33333333-3333-3333-3333-333333333333')),
  'ogni nuovo profilo riceve un codice amico di 10 caratteri senza ambigui');
select is(
  (select count(distinct friend_code)::int from profiles
    where id in ('11111111-1111-1111-1111-111111111111',
                 '22222222-2222-2222-2222-222222222222',
                 '33333333-3333-3333-3333-333333333333')),
  3, 'i codici amico sono diversi tra utenti');
select col_not_null('public', 'profiles', 'friend_code',
  'friend_code è obbligatorio');
select col_is_unique('public', 'profiles', array['friend_code'],
  'friend_code è unico');

-- Codici fissi per i test successivi; C ha chiesto la cancellazione.
update profiles set friend_code = 'AAAAAAAAAA', display_name = 'Anna'
 where id = '11111111-1111-1111-1111-111111111111';
update profiles set friend_code = 'BBBBBBBBBB', display_name = 'Bea'
 where id = '22222222-2222-2222-2222-222222222222';
update profiles set friend_code = 'CCCCCCCCCC', display_name = 'Carlo',
       deletion_requested_at = now()
 where id = '33333333-3333-3333-3333-333333333333';

select throws_ok($$ update profiles set display_name = repeat('x', 41)
  where id = '11111111-1111-1111-1111-111111111111' $$,
  '23514', null, 'il database rifiuta un nome oltre 40 caratteri');
select throws_ok($$ update profiles set display_name = ' Anna '
  where id = '11111111-1111-1111-1111-111111111111' $$,
  '23514', null, 'il database rifiuta un nome con spazi ai bordi');
select throws_ok($$ update profiles set friend_code = 'AAAAAAAAA0'
  where id = '11111111-1111-1111-1111-111111111111' $$,
  '23514', null, 'il database rifiuta un codice con caratteri ambigui');

select is(has_function_privilege('authenticated', 'private.new_friend_code()', 'execute'),
  false, 'il generatore di codici non è chiamabile dal client');

-- =====================================================================
-- Utente A
-- =====================================================================
set local role authenticated;
set local request.jwt.claim.sub = '11111111-1111-1111-1111-111111111111';
set local request.jwt.claims = '{"sub":"11111111-1111-1111-1111-111111111111","role":"authenticated"}';

select is((select friend_code from profiles where id = '11111111-1111-1111-1111-111111111111'),
  'AAAAAAAAAA', 'A legge il proprio codice amico');
select is((select count(*)::int from profiles where id = '22222222-2222-2222-2222-222222222222'),
  0, 'A non legge il profilo (né il codice) di B');
select throws_ok($$ update profiles set display_name = 'Hacker'
  where id = '11111111-1111-1111-1111-111111111111' $$,
  '42501', null, 'A non modifica il profilo direttamente, solo via RPC');
select throws_ok($$ select * from private.rate_limit_events $$,
  '42501', null, 'A non legge i contatori dei limiti');

-- set_display_name ------------------------------------------------------
select is(set_display_name('  Anna Rossi  '), 'Anna Rossi',
  'set_display_name toglie gli spazi ai bordi e restituisce il nome salvato');
select is((select display_name from profiles where id = '11111111-1111-1111-1111-111111111111'),
  'Anna Rossi', 'il nome è salvato sul proprio profilo');
select throws_ok($$ select set_display_name('   ') $$,
  '22023', null, 'nome vuoto rifiutato');
select throws_ok($$ select set_display_name(repeat('x', 41)) $$,
  '22023', null, 'nome oltre 40 caratteri rifiutato');
select throws_ok($$ select set_display_name(E'Anna\nRossi') $$,
  '22023', null, 'nome con caratteri di controllo rifiutato');
select is(set_display_name('Àñnä 李'), 'Àñnä 李',
  'nomi con accenti e alfabeti non latini accettati');

-- resolve_friend_code ---------------------------------------------------
select results_eq(
  $$ select * from resolve_friend_code('bbbbb-bbbbb') $$,
  $$ values ('22222222-2222-2222-2222-222222222222'::uuid, 'Bea'::text) $$,
  'il codice di B (minuscolo, con trattino) restituisce solo id e nome di B');
select is((select count(*)::int from resolve_friend_code('AAAAAAAAAA')),
  0, 'il proprio codice non restituisce niente');
select is((select count(*)::int from resolve_friend_code('ZZZZZZZZZZ')),
  0, 'un codice inesistente non restituisce niente');
select is((select count(*)::int from resolve_friend_code('CCCCCCCCCC')),
  0, 'un account in cancellazione non è trovabile');
select is((select count(*)::int from resolve_friend_code('not a code')),
  0, 'un codice malformato non restituisce niente');

-- regenerate_friend_code ------------------------------------------------
select isnt(regenerate_friend_code(), 'AAAAAAAAAA',
  'regenerate_friend_code assegna un codice nuovo');
select ok((select friend_code ~ '^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{10}$'
             from profiles where id = '11111111-1111-1111-1111-111111111111'),
  'il codice rigenerato rispetta il formato');

-- =====================================================================
-- Utente B
-- =====================================================================
set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

select is((select count(*)::int from resolve_friend_code('AAAAAAAAAA')),
  0, 'il vecchio codice di A non funziona più dopo la rigenerazione');

-- =====================================================================
-- Limiti di frequenza (contatori riempiti come postgres)
-- =====================================================================
reset role;
-- Le chiamate fatte sopra sono state davvero contate: A ha cercato 5
-- codici e rigenerato il proprio una volta, B ha cercato un codice.
select is((select count(*)::int from private.rate_limit_events
            where user_id = '11111111-1111-1111-1111-111111111111'
              and action = 'resolve_friend_code'),
  5, 'ogni ricerca di codice viene registrata nel contatore');
select is((select count(*)::int from private.rate_limit_events
            where user_id = '11111111-1111-1111-1111-111111111111'
              and action = 'regenerate_friend_code'),
  1, 'ogni rigenerazione viene registrata nel contatore');

insert into private.rate_limit_events (user_id, action)
select '22222222-2222-2222-2222-222222222222', 'resolve_friend_code'
  from generate_series(1, 30);
insert into private.rate_limit_events (user_id, action)
select '22222222-2222-2222-2222-222222222222', 'regenerate_friend_code'
  from generate_series(1, 5);

set local role authenticated;
set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';

select throws_ok($$ select * from resolve_friend_code('AAAAAAAAAA') $$,
  'P0001', null, 'oltre 30 ricerche di codici in un''ora: rifiutate');
select throws_ok($$ select regenerate_friend_code() $$,
  'P0001', null, 'oltre 5 rigenerazioni in 24 ore: rifiutate');

reset role;
update private.rate_limit_events set at = now() - interval '2 hours'
 where user_id = '22222222-2222-2222-2222-222222222222'
   and action = 'resolve_friend_code';
set local role authenticated;
set local request.jwt.claim.sub = '22222222-2222-2222-2222-222222222222';
set local request.jwt.claims = '{"sub":"22222222-2222-2222-2222-222222222222","role":"authenticated"}';
select lives_ok($$ select * from resolve_friend_code('ZZZZZZZZZZ') $$,
  'passata l''ora, le ricerche ripartono');

-- =====================================================================
-- Client anonimo
-- =====================================================================
reset role;
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';

select throws_ok($$ select * from resolve_friend_code('BBBBBBBBBB') $$,
  '42501', null, 'anonimo: niente ricerca di codici');
select throws_ok($$ select set_display_name('x') $$,
  '42501', null, 'anonimo: niente modifica del nome');
select throws_ok($$ select regenerate_friend_code() $$,
  '42501', null, 'anonimo: niente rigenerazione del codice');

-- =====================================================================
-- Nome al signup (metadati della registrazione, 20261023000000)
-- =====================================================================
reset role;
insert into auth.users (id, email, raw_user_meta_data) values
  ('44444444-4444-4444-4444-444444444444', 'meta-ok@test.local',
   '{"display_name": "  Dario  "}'),
  ('55555555-5555-5555-5555-555555555555', 'meta-long@test.local',
   jsonb_build_object('display_name', repeat('x', 41))),
  ('66666666-6666-6666-6666-666666666666', 'meta-obj@test.local',
   '{"display_name": {"x": 1}}'),
  ('77777777-7777-7777-7777-777777777777', 'meta-ctrl@test.local',
   jsonb_build_object('display_name', 'Eva' || chr(10)));
insert into auth.users (id, email) values
  ('88888888-8888-8888-8888-888888888888', 'meta-none@test.local');

select is(
  (select display_name from profiles
    where id = '44444444-4444-4444-4444-444444444444'),
  'Dario', 'signup: il nome dei metadati viene salvato senza spazi ai bordi');
select is(
  (select display_name from profiles
    where id = '55555555-5555-5555-5555-555555555555'),
  null, 'signup: un nome oltre 40 caratteri resta vuoto');
select is(
  (select display_name from profiles
    where id = '66666666-6666-6666-6666-666666666666'),
  null, 'signup: un nome che non è testo resta vuoto');
select is(
  (select display_name from profiles
    where id = '77777777-7777-7777-7777-777777777777'),
  null, 'signup: un nome con caratteri di controllo resta vuoto');
select is(
  (select display_name from profiles
    where id = '88888888-8888-8888-8888-888888888888'),
  null, 'signup senza metadati: profilo creato, nome vuoto');
select is(
  (select count(*)::int from profiles
    where id in ('55555555-5555-5555-5555-555555555555',
                 '66666666-6666-6666-6666-666666666666',
                 '77777777-7777-7777-7777-777777777777',
                 '88888888-8888-8888-8888-888888888888')
      and friend_code is not null),
  4, 'signup: un nome scartato non blocca la registrazione né il codice');

select * from finish();
rollback;
