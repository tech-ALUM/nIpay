-- nIpay — M-SOC3: chat 1:1 e di gruppo (mds/FRIENDS_PLAN.md)
--
-- Gira su un Supabase locale (Docker), mai sul progetto reale:
--   supabase db start && supabase test db
-- Tutto dentro una transazione annullata alla fine: nessun residuo.
-- Gli id delle conversazioni passano tra un utente e l'altro come
-- impostazioni locali (test.*), leggibili da qualunque ruolo.

begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

-- ---------------------------------------------------------------------
-- Seed (come postgres). Amici: A–B, A–C, B–C, A–D, A–E. E ha chiesto la
-- cancellazione, G non è amico di nessuno.
-- ---------------------------------------------------------------------
insert into auth.users (id, email) values
  ('a1111111-1111-1111-1111-111111111111', 'chat-a@test.local'),
  ('b2222222-2222-2222-2222-222222222222', 'chat-b@test.local'),
  ('c3333333-3333-3333-3333-333333333333', 'chat-c@test.local'),
  ('d4444444-4444-4444-4444-444444444444', 'chat-d@test.local'),
  ('e5555555-5555-5555-5555-555555555555', 'chat-e@test.local'),
  ('f7777777-7777-7777-7777-777777777777', 'chat-g@test.local');
update profiles set display_name = 'Anna'  where id = 'a1111111-1111-1111-1111-111111111111';
update profiles set display_name = 'Bea'   where id = 'b2222222-2222-2222-2222-222222222222';
update profiles set display_name = 'Carlo' where id = 'c3333333-3333-3333-3333-333333333333';
update profiles set display_name = 'Dario' where id = 'd4444444-4444-4444-4444-444444444444';
update profiles set display_name = 'Elsa', deletion_requested_at = now()
 where id = 'e5555555-5555-5555-5555-555555555555';
update profiles set display_name = 'Gino'  where id = 'f7777777-7777-7777-7777-777777777777';
insert into friendships (requester_id, addressee_id, status, responded_at) values
  ('a1111111-1111-1111-1111-111111111111', 'b2222222-2222-2222-2222-222222222222', 'accepted', now()),
  ('a1111111-1111-1111-1111-111111111111', 'c3333333-3333-3333-3333-333333333333', 'accepted', now()),
  ('b2222222-2222-2222-2222-222222222222', 'c3333333-3333-3333-3333-333333333333', 'accepted', now()),
  ('d4444444-4444-4444-4444-444444444444', 'a1111111-1111-1111-1111-111111111111', 'accepted', now()),
  ('a1111111-1111-1111-1111-111111111111', 'e5555555-5555-5555-5555-555555555555', 'accepted', now());

select has_table('public', 'conversations', 'tabella conversations');
select has_table('public', 'messages', 'tabella messages');
select has_table('public', 'reports', 'tabella reports');
select ok((select bool_and(c.relrowsecurity) from pg_class c
            join pg_namespace n on n.oid = c.relnamespace
           where (n.nspname, c.relname) in (
             ('public', 'conversations'), ('public', 'conversation_members'),
             ('public', 'conversation_reads'), ('public', 'messages'),
             ('public', 'reports'), ('private', 'deleted_message_bodies'))),
  'RLS attiva su tutte le tabelle della chat');
select set_eq(
  $$ select pr.prrelid from pg_publication_rel pr
       join pg_publication p on p.oid = pr.prpubid
      where p.pubname = 'supabase_realtime' $$,
  $$ values ('public.conversation_members'::regclass::oid),
            ('public.friendships'::regclass::oid),
            ('public.messages'::regclass::oid) $$,
  'Realtime pubblica solo chat e amicizie, mai le tabelle dei portafogli');
select is((select puballtables from pg_publication where pubname = 'supabase_realtime'),
  false, 'la publication non è "per tutte le tabelle"');
select is(
  (select count(*)::int from pg_index i
    where i.indisprimary and i.indnatts = 1
      and i.indrelid in ('public.messages'::regclass,
                         'public.conversation_members'::regclass,
                         'public.friendships'::regclass)),
  3, 'le tabelle pubblicate hanno una chiave a colonna singola (id casuale negli eventi DELETE)');

-- =====================================================================
-- A apre la chat 1:1 con B e scrive
-- =====================================================================
set local role authenticated;
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok($$ insert into conversations (kind, direct_key)
  values ('direct', 'x:y') $$,
  '42501', null, 'niente insert diretto nelle conversazioni');
select throws_ok($$ insert into messages (conversation_id, sender_id, body)
  values (gen_random_uuid(), 'a1111111-1111-1111-1111-111111111111', 'ciao') $$,
  '42501', null, 'niente insert diretto nei messaggi');

select set_config('test.ab',
  open_direct_conversation('b2222222-2222-2222-2222-222222222222')::text, true);
select is(open_direct_conversation('b2222222-2222-2222-2222-222222222222'),
  current_setting('test.ab')::uuid, 'riaprire la chat 1:1 restituisce la stessa');
select throws_ok($$ select open_direct_conversation('f7777777-7777-7777-7777-777777777777') $$,
  'P0001', 'utente non disponibile', 'niente chat 1:1 con chi non è amico');
select throws_ok($$ select open_direct_conversation('e5555555-5555-5555-5555-555555555555') $$,
  'P0001', 'utente non disponibile', 'niente chat 1:1 con un account in cancellazione');
select throws_ok($$ select open_direct_conversation('a1111111-1111-1111-1111-111111111111') $$,
  'P0001', 'utente non disponibile', 'niente chat con se stessi');

select set_config('test.first',
  (select message_id::text from send_message(current_setting('test.ab')::uuid, '  ciao Bea  ')),
  true);
select is((select body from messages where id = current_setting('test.first')::uuid),
  'ciao Bea', 'il testo arriva senza spazi ai bordi');
select lives_ok($$ select send_message(current_setting('test.ab')::uuid, E'riga 1\nriga 2') $$,
  'a capo ammessi');
select throws_ok($$ select send_message(current_setting('test.ab')::uuid, '   ') $$,
  'P0001', 'messaggio non valido', 'niente messaggi vuoti');
select throws_ok($$ select send_message(current_setting('test.ab')::uuid, repeat('x', 2001)) $$,
  'P0001', 'messaggio non valido', 'niente messaggi oltre 2000 caratteri');
select throws_ok($$ select send_message(current_setting('test.ab')::uuid, E'ciao\x07') $$,
  'P0001', 'messaggio non valido', 'niente caratteri di controllo');
select throws_ok($$ update messages set body = 'modificato' $$,
  '42501', null, 'messaggi immutabili: niente update diretto');

-- =====================================================================
-- B legge: non letti, storia, segno di lettura
-- =====================================================================
set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';

select results_eq(
  $$ select kind, peer_display_name, can_send, last_body, unread_count
       from list_conversations() $$,
  $$ values ('direct'::text, 'Anna'::text, true, E'riga 1\nriga 2'::text, 2) $$,
  'B vede la chat con Anna, ultimo messaggio e 2 non letti');
select results_eq(
  $$ select body, sender_display_name from list_messages(current_setting('test.ab')::uuid) $$,
  $$ values (E'riga 1\nriga 2'::text, 'Anna'::text), ('ciao Bea'::text, 'Anna'::text) $$,
  'storia dalla più recente, col nome del mittente');
select results_eq(
  $$ select l.body from list_messages(current_setting('test.ab')::uuid) f,
            lateral list_messages(current_setting('test.ab')::uuid,
                                  f.created_at, f.message_id, 10) l
      where f.body = E'riga 1\nriga 2' $$,
  $$ values ('ciao Bea'::text) $$,
  'paginazione keyset: dopo il più recente arriva il precedente');
select lives_ok($$ select mark_conversation_read(current_setting('test.ab')::uuid) $$,
  'B segna la chat come letta');
select is((select unread_count from list_conversations()), 0, 'dopo la lettura: 0 non letti');
select is((select count(*)::int from conversation_reads), 1,
  'B vede solo il proprio segno di lettura, non quello di Anna');

-- =====================================================================
-- G non è membro: non vede né scrive nulla
-- =====================================================================
set local request.jwt.claims = '{"sub":"f7777777-7777-7777-7777-777777777777","role":"authenticated"}';

select is((select count(*)::int from messages), 0, 'G non legge messaggi altrui');
select is((select count(*)::int from conversations), 0, 'G non vede conversazioni altrui');
select is((select count(*)::int from conversation_members), 0, 'G non vede i membri altrui');
select throws_ok($$ select * from list_messages(current_setting('test.ab')::uuid) $$,
  'P0001', 'conversazione non trovata', 'G: niente storia di una chat altrui');
select throws_ok($$ select send_message(current_setting('test.ab')::uuid, 'intruso') $$,
  'P0001', 'conversazione non trovata', 'G: niente invio in una chat altrui');
select throws_ok($$ select * from list_conversation_members(current_setting('test.ab')::uuid) $$,
  'P0001', 'conversazione non trovata', 'G: niente elenco membri di una chat altrui');

-- =====================================================================
-- Gruppo creato da A con B e C
-- =====================================================================
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok($$ select create_group('  ', array['b2222222-2222-2222-2222-222222222222'::uuid]) $$,
  'P0001', 'titolo non valido', 'niente gruppi senza titolo');
select throws_ok($$ select create_group('Solo io', '{}') $$,
  'P0001', 'nessun membro', 'niente gruppi senza altri membri');
select throws_ok($$ select create_group('Con estranei',
    array['b2222222-2222-2222-2222-222222222222'::uuid, 'f7777777-7777-7777-7777-777777777777'::uuid]) $$,
  'P0001', 'utente non disponibile', 'nei gruppi solo propri amici');
select set_config('test.grp', create_group(' Viaggio ', array[
  'b2222222-2222-2222-2222-222222222222'::uuid,
  'c3333333-3333-3333-3333-333333333333'::uuid,
  'b2222222-2222-2222-2222-222222222222'::uuid])::text, true);
select results_eq(
  $$ select display_name, role from list_conversation_members(current_setting('test.grp')::uuid)
      order by display_name $$,
  $$ values ('Anna'::text, 'admin'::text), ('Bea', 'member'), ('Carlo', 'member') $$,
  'gruppo con A admin, B e C membri (doppioni ignorati)');
select is((select title from conversations where id = current_setting('test.grp')::uuid),
  'Viaggio', 'titolo senza spazi ai bordi');
select lives_ok($$ select send_message(current_setting('test.grp')::uuid, 'prima di Dario') $$,
  'A scrive nel gruppo');

-- C scrive nel gruppo e nella chat 1:1 con B.
set local request.jwt.claims = '{"sub":"c3333333-3333-3333-3333-333333333333","role":"authenticated"}';
select lives_ok($$ select send_message(current_setting('test.grp')::uuid, 'ciao da Carlo') $$,
  'C scrive nel gruppo');
select set_config('test.bc',
  open_direct_conversation('b2222222-2222-2222-2222-222222222222')::text, true);
select lives_ok($$ select send_message(current_setting('test.bc')::uuid, 'Carlo a Bea') $$,
  'C scrive a B in 1:1');

-- B: niente aggiunte da non admin, poi blocca C.
set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';
select throws_ok($$ select add_group_members(current_setting('test.grp')::uuid,
    array['a1111111-1111-1111-1111-111111111111'::uuid]) $$,
  'P0001', 'gruppo non trovato', 'solo gli admin aggiungono membri');
select throws_ok($$ select remove_group_member(current_setting('test.grp')::uuid,
    'c3333333-3333-3333-3333-333333333333') $$,
  'P0001', 'gruppo non trovato', 'solo gli admin tolgono membri');
select lives_ok($$ select block_user('c3333333-3333-3333-3333-333333333333') $$, 'B blocca C');

select is(
  (select count(*)::int from list_messages(current_setting('test.grp')::uuid)
    where sender_id = 'c3333333-3333-3333-3333-333333333333'),
  0, 'nel gruppo B non vede più i messaggi di chi ha bloccato');
select is((select count(*)::int from messages
            where conversation_id = current_setting('test.grp')::uuid),
  1, 'anche la lettura diretta (e quindi Realtime) li esclude');
select results_eq(
  $$ select body from list_messages(current_setting('test.bc')::uuid) $$,
  $$ values ('Carlo a Bea'::text) $$,
  'nella chat 1:1 lo storico resta visibile anche dopo il blocco');
select is(
  (select can_send from list_conversations()
    where conversation_id = current_setting('test.bc')::uuid),
  false, 'la chat 1:1 con C è in sola lettura');
select throws_ok($$ select send_message(current_setting('test.bc')::uuid, 'ehi') $$,
  'P0001', 'chat in sola lettura', 'B non scrive a chi ha bloccato');

set local request.jwt.claims = '{"sub":"c3333333-3333-3333-3333-333333333333","role":"authenticated"}';
select throws_ok($$ select send_message(current_setting('test.bc')::uuid, 'ehi') $$,
  'P0001', 'chat in sola lettura', 'C non scrive a chi l''ha bloccato');
select is(
  (select count(*)::int from list_messages(current_setting('test.grp')::uuid)),
  2, 'C (bloccato) continua a vedere tutto il gruppo e non sa del blocco');

-- =====================================================================
-- A aggiunge D: D vede solo i messaggi dal suo ingresso
-- =====================================================================
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select throws_ok($$ select add_group_members(current_setting('test.grp')::uuid,
    array['f7777777-7777-7777-7777-777777777777'::uuid]) $$,
  'P0001', 'utente non disponibile', 'l''admin aggiunge solo propri amici');
select lives_ok($$ select add_group_members(current_setting('test.grp')::uuid,
    array['d4444444-4444-4444-4444-444444444444'::uuid]) $$,
  'A aggiunge D');
select lives_ok($$ select send_message(current_setting('test.grp')::uuid, 'benvenuto Dario') $$,
  'A scrive dopo l''ingresso di D');

set local request.jwt.claims = '{"sub":"d4444444-4444-4444-4444-444444444444","role":"authenticated"}';
select results_eq(
  $$ select body from list_messages(current_setting('test.grp')::uuid) $$,
  $$ values ('benvenuto Dario'::text) $$,
  'D vede solo i messaggi arrivati dopo il suo ingresso');
select is((select unread_count from list_conversations()
            where conversation_id = current_setting('test.grp')::uuid),
  1, 'i non letti di D contano solo quelli visibili');

-- =====================================================================
-- Eliminazione e segnalazioni
-- =====================================================================
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select set_config('test.msg',
  (select message_id::text from list_messages(current_setting('test.grp')::uuid)
    where body = 'prima di Dario'), true);

set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';
select throws_ok($$ select delete_message(current_setting('test.msg')::uuid) $$,
  'P0001', 'messaggio non trovato', 'solo il mittente elimina un messaggio');
select throws_ok($$ select report_message(current_setting('test.msg')::uuid, 'boh') $$,
  'P0001', 'segnalazione non valida', 'motivo della segnalazione obbligatorio e noto');
select throws_ok($$ select report_message(current_setting('test.msg')::uuid, 'other', repeat('x', 501)) $$,
  'P0001', 'segnalazione non valida', 'dettagli della segnalazione fino a 500 caratteri');

set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select throws_ok($$ select report_message(current_setting('test.msg')::uuid, 'spam') $$,
  'P0001', 'messaggio non trovato', 'niente segnalazioni dei propri messaggi');
select lives_ok($$ select delete_message(current_setting('test.msg')::uuid) $$,
  'A elimina il proprio messaggio');
select throws_ok($$ select delete_message(current_setting('test.msg')::uuid) $$,
  'P0001', 'messaggio non trovato', 'un messaggio si elimina una volta sola');

set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';
select results_eq(
  $$ select body, deleted from list_messages(current_setting('test.grp')::uuid)
      where message_id = current_setting('test.msg')::uuid $$,
  $$ values (null::text, true) $$,
  'agli altri il messaggio eliminato arriva senza testo');
select lives_ok($$ select report_message(current_setting('test.msg')::uuid, 'offensive', '  brutto  ') $$,
  'B segnala il messaggio eliminato di A');
select lives_ok($$ select report_user('a1111111-1111-1111-1111-111111111111', 'harassment') $$,
  'B segnala A come utente');
select throws_ok($$ select report_user('b2222222-2222-2222-2222-222222222222', 'spam') $$,
  'P0001', 'utente non disponibile', 'niente segnalazioni di se stessi');
select throws_ok($$ select count(*) from reports $$,
  '42501', null, 'nessuno legge le segnalazioni, nemmeno le proprie');
select throws_ok($$ select count(*) from private.deleted_message_bodies $$,
  '42501', null, 'il testo dei messaggi eliminati è fuori dalla portata del client');

set local request.jwt.claims = '{"sub":"f7777777-7777-7777-7777-777777777777","role":"authenticated"}';
select throws_ok($$ select report_message(current_setting('test.msg')::uuid, 'spam') $$,
  'P0001', 'messaggio non trovato', 'non si segnala un messaggio di una chat di cui non si è membri');

reset role;
select results_eq(
  $$ select reported_user_id, message_body, reason, details from reports
      where message_id = current_setting('test.msg')::uuid $$,
  $$ values ('a1111111-1111-1111-1111-111111111111'::uuid, 'prima di Dario'::text,
             'offensive'::text, 'brutto'::text) $$,
  'la segnalazione conserva una copia del testo, anche se eliminato');
select is((select body from private.deleted_message_bodies
            where message_id = current_setting('test.msg')::uuid),
  'prima di Dario', 'il testo eliminato resta solo nello schema private');

-- =====================================================================
-- Uscita dal gruppo e passaggio di admin
-- =====================================================================
set local role authenticated;
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select throws_ok($$ select remove_group_member(current_setting('test.grp')::uuid,
    'a1111111-1111-1111-1111-111111111111') $$,
  'P0001', 'gruppo non trovato', 'l''admin non si toglie da sé: per quello c''è leave_group');
select lives_ok($$ select remove_group_member(current_setting('test.grp')::uuid,
    'd4444444-4444-4444-4444-444444444444') $$, 'A toglie D');
select lives_ok($$ select leave_group(current_setting('test.grp')::uuid) $$, 'A (unico admin) esce');
select is((select count(*)::int from conversations
            where id = current_setting('test.grp')::uuid),
  0, 'chi è uscito non vede più il gruppo');

set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';
select results_eq(
  $$ select (count(*) filter (where role = 'admin'))::int, count(*)::int
       from list_conversation_members(current_setting('test.grp')::uuid) $$,
  $$ values (1, 2) $$,
  'uscito l''ultimo admin, uno dei membri più vecchi diventa admin');
select lives_ok($$ select leave_group(current_setting('test.grp')::uuid) $$, 'B esce');

set local request.jwt.claims = '{"sub":"c3333333-3333-3333-3333-333333333333","role":"authenticated"}';
select is((select role from list_conversation_members(current_setting('test.grp')::uuid)),
  'admin', 'resta solo C, admin');
select lives_ok($$ select leave_group(current_setting('test.grp')::uuid) $$, 'esce anche C');

reset role;
select is((select count(*)::int from conversations where id = current_setting('test.grp')::uuid),
  0, 'uscito l''ultimo membro il gruppo sparisce, messaggi compresi');

-- =====================================================================
-- Limite di invio: 30 messaggi al minuto
-- =====================================================================
set local role authenticated;
set local request.jwt.claims = '{"sub":"d4444444-4444-4444-4444-444444444444","role":"authenticated"}';
select set_config('test.ad',
  open_direct_conversation('a1111111-1111-1111-1111-111111111111')::text, true);
select throws_ok($$ select count(*) from generate_series(1, 31) g,
    lateral send_message(current_setting('test.ad')::uuid, 'msg ' || g) $$,
  'P0001', 'troppe richieste', 'il 31° messaggio nello stesso minuto viene rifiutato');

-- =====================================================================
-- Account cancellato: "Messaggio eliminato" di "Utente eliminato"
-- =====================================================================
reset role;
delete from auth.users where id = 'c3333333-3333-3333-3333-333333333333';
select results_eq(
  $$ select sender_id, body, deleted_at is not null from messages
      where conversation_id = current_setting('test.bc')::uuid $$,
  $$ values (null::uuid, null::text, true) $$,
  'i messaggi di un account cancellato restano senza mittente né testo');

set local role authenticated;
set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';
select results_eq(
  $$ select peer_id, can_send, last_message_deleted from list_conversations()
      where conversation_id = current_setting('test.bc')::uuid $$,
  $$ values (null::uuid, false, true) $$,
  'B vede la chat con un utente eliminato, in sola lettura');

-- =====================================================================
-- Client anonimo
-- =====================================================================
reset role;
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select throws_ok($$ select count(*) from messages $$, '42501', null,
  'anonimo: niente lettura dei messaggi');
select throws_ok($$ select * from list_conversations() $$, '42501', null,
  'anonimo: niente elenco conversazioni');
select throws_ok($$ select send_message(current_setting('test.ab')::uuid, 'x') $$, '42501', null,
  'anonimo: niente invio');
select throws_ok($$ select report_user('a1111111-1111-1111-1111-111111111111', 'spam') $$,
  '42501', null, 'anonimo: niente segnalazioni');

select * from finish();
rollback;
