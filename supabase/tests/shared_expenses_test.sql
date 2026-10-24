-- nIpay — M-SOC4: spese divise, rimborsi e saldi (mds/FRIENDS_PLAN.md)
--
-- Gira su un Supabase locale (Docker), mai sul progetto reale:
--   supabase db start && supabase test db
-- Tutto dentro una transazione annullata alla fine: nessun residuo.

begin;
create extension if not exists pgtap with schema extensions;
select no_plan();

-- ---------------------------------------------------------------------
-- Seed (come postgres). Amici: A–B, A–C, B–C, A–E. E ha chiesto la
-- cancellazione, D non è amico di A.
-- ---------------------------------------------------------------------
insert into auth.users (id, email) values
  ('a1111111-1111-1111-1111-111111111111', 'split-a@test.local'),
  ('b2222222-2222-2222-2222-222222222222', 'split-b@test.local'),
  ('c3333333-3333-3333-3333-333333333333', 'split-c@test.local'),
  ('d4444444-4444-4444-4444-444444444444', 'split-d@test.local'),
  ('e5555555-5555-5555-5555-555555555555', 'split-e@test.local');
update profiles set display_name = 'Anna'  where id = 'a1111111-1111-1111-1111-111111111111';
update profiles set display_name = 'Bea'   where id = 'b2222222-2222-2222-2222-222222222222';
update profiles set display_name = 'Carlo' where id = 'c3333333-3333-3333-3333-333333333333';
update profiles set display_name = 'Dario' where id = 'd4444444-4444-4444-4444-444444444444';
update profiles set display_name = 'Elsa', deletion_requested_at = now()
 where id = 'e5555555-5555-5555-5555-555555555555';
insert into friendships (requester_id, addressee_id, status, responded_at) values
  ('a1111111-1111-1111-1111-111111111111', 'b2222222-2222-2222-2222-222222222222', 'accepted', now()),
  ('a1111111-1111-1111-1111-111111111111', 'c3333333-3333-3333-3333-333333333333', 'accepted', now()),
  ('b2222222-2222-2222-2222-222222222222', 'c3333333-3333-3333-3333-333333333333', 'accepted', now()),
  ('a1111111-1111-1111-1111-111111111111', 'e5555555-5555-5555-5555-555555555555', 'accepted', now());

-- Quote in JSON: coppie (utente, centesimi).
create function pg_temp.shares(variadic pairs text[]) returns jsonb
language sql as $$
  select coalesce(jsonb_agg(jsonb_build_object(
           'user_id', pairs[i], 'share_cents', pairs[i + 1]::bigint)), '[]')
    from generate_series(1, coalesce(array_length(pairs, 1), 0), 2) i;
$$;
grant execute on function pg_temp.shares(text[]) to authenticated, anon;

select has_table('public', 'shared_expenses', 'tabella shared_expenses');
select has_table('public', 'shared_expense_shares', 'tabella shared_expense_shares');
select has_table('public', 'settlements', 'tabella settlements');
select ok((select bool_and(c.relrowsecurity) from pg_class c
            where c.oid in ('public.shared_expenses'::regclass,
                            'public.shared_expense_shares'::regclass,
                            'public.settlements'::regclass)),
  'RLS attiva sulle tabelle delle spese divise');

-- =====================================================================
-- A crea la cena: 60 € pagati da A, 20 € a testa con B e C
-- =====================================================================
set local role authenticated;
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';

select throws_ok($$ select count(*) from shared_expenses $$,
  '42501', null, 'niente lettura diretta delle spese divise');
select throws_ok($$ select count(*) from settlements $$,
  '42501', null, 'niente lettura diretta dei rimborsi');
select throws_ok($$ insert into shared_expenses (paid_by, total_cents, currency, spent_on)
  values ('a1111111-1111-1111-1111-111111111111', 100, 'EUR', current_date) $$,
  '42501', null, 'niente insert diretto: le spese passano dalle RPC');

select throws_ok($$ select create_shared_expense('Cena', 6000, 'EUR', current_date,
    'a1111111-1111-1111-1111-111111111111',
    pg_temp.shares('a1111111-1111-1111-1111-111111111111', '2000',
                   'b2222222-2222-2222-2222-222222222222', '2000')) $$,
  'P0001', 'quote non valide', 'le quote devono tornare col totale');
select throws_ok($$ select create_shared_expense('Cena', 6000, 'EUR', current_date,
    'b2222222-2222-2222-2222-222222222222',
    pg_temp.shares('b2222222-2222-2222-2222-222222222222', '3000',
                   'c3333333-3333-3333-3333-333333333333', '3000')) $$,
  'P0001', 'quote non valide', 'chi crea la spesa ne fa parte');
select throws_ok($$ select create_shared_expense('Cena', 6000, 'EUR', current_date,
    'a1111111-1111-1111-1111-111111111111',
    pg_temp.shares('a1111111-1111-1111-1111-111111111111', '2000',
                   'a1111111-1111-1111-1111-111111111111', '2000',
                   'b2222222-2222-2222-2222-222222222222', '2000')) $$,
  'P0001', 'quote non valide', 'niente partecipanti doppi');
select throws_ok($$ select create_shared_expense('Cena', 6000, 'EUR', current_date,
    'a1111111-1111-1111-1111-111111111111',
    pg_temp.shares('a1111111-1111-1111-1111-111111111111', '6000',
                   'b2222222-2222-2222-2222-222222222222', '0')) $$,
  'P0001', 'quote non valide', 'niente quote a zero');
select throws_ok($$ select create_shared_expense('Cena', 6000, 'EUR', current_date,
    'a1111111-1111-1111-1111-111111111111', '[{"user_id": "nope"}]'::jsonb) $$,
  'P0001', 'quote non valide', 'quote malformate');
select throws_ok($$ select create_shared_expense('Solo io', 6000, 'EUR', current_date,
    'a1111111-1111-1111-1111-111111111111',
    pg_temp.shares('a1111111-1111-1111-1111-111111111111', '6000')) $$,
  'P0001', 'nessun amico', 'una spesa divisa ha almeno un amico');
select throws_ok($$ select create_shared_expense('Con Dario', 6000, 'EUR', current_date,
    'a1111111-1111-1111-1111-111111111111',
    pg_temp.shares('a1111111-1111-1111-1111-111111111111', '3000',
                   'd4444444-4444-4444-4444-444444444444', '3000')) $$,
  'P0001', 'utente non disponibile', 'solo con amici accettati');
select throws_ok($$ select create_shared_expense('Con Elsa', 6000, 'EUR', current_date,
    'a1111111-1111-1111-1111-111111111111',
    pg_temp.shares('a1111111-1111-1111-1111-111111111111', '3000',
                   'e5555555-5555-5555-5555-555555555555', '3000')) $$,
  'P0001', 'utente non disponibile', 'niente spese con un account in cancellazione');
select throws_ok($$ select create_shared_expense('Cena', 6000, 'EUR', current_date,
    'd4444444-4444-4444-4444-444444444444',
    pg_temp.shares('a1111111-1111-1111-1111-111111111111', '3000',
                   'b2222222-2222-2222-2222-222222222222', '3000')) $$,
  'P0001', 'chi ha pagato non partecipa', 'chi paga è uno dei partecipanti');
select throws_ok($$ select create_shared_expense('Cena', 6000, 'XXX', current_date,
    'a1111111-1111-1111-1111-111111111111',
    pg_temp.shares('a1111111-1111-1111-1111-111111111111', '3000',
                   'b2222222-2222-2222-2222-222222222222', '3000')) $$,
  'P0001', 'spesa non valida', 'solo le valute dell''app');
select throws_ok($$ select create_shared_expense(repeat('x', 201), 6000, 'EUR', current_date,
    'a1111111-1111-1111-1111-111111111111',
    pg_temp.shares('a1111111-1111-1111-1111-111111111111', '3000',
                   'b2222222-2222-2222-2222-222222222222', '3000')) $$,
  'P0001', 'spesa non valida', 'descrizione fino a 200 caratteri');

select set_config('test.dinner', create_shared_expense('  Cena  ', 6000, 'EUR', current_date,
    'a1111111-1111-1111-1111-111111111111',
    pg_temp.shares('a1111111-1111-1111-1111-111111111111', '2000',
                   'b2222222-2222-2222-2222-222222222222', '2000',
                   'c3333333-3333-3333-3333-333333333333', '2000'))::text, true);
select results_eq(
  $$ select description, total_cents, my_share_cents, my_share_registered, locked,
            jsonb_array_length(shares)
       from list_shared_expenses() $$,
  $$ values ('Cena'::text, 6000::bigint, 2000::bigint, true, false, 3) $$,
  'A vede la cena: la sua quota è già registrata, la spesa non è bloccata');
select results_eq(
  $$ select display_name, currency, balance_cents, is_friend from friend_balances() $$,
  $$ values ('Bea'::text, 'EUR'::text, 2000::bigint, true),
            ('Carlo', 'EUR', 2000::bigint, true) $$,
  'A: Bea e Carlo gli devono 20 € ciascuno');

-- =====================================================================
-- B vede la sua quota, non può modificare
-- =====================================================================
set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';

select results_eq(
  $$ select payer_display_name, my_share_cents, my_share_registered from list_shared_expenses() $$,
  $$ values ('Anna'::text, 2000::bigint, false) $$,
  'B vede la cena pagata da Anna, quota da registrare');
select results_eq(
  $$ select display_name, balance_cents from friend_balances() $$,
  $$ values ('Anna'::text, -2000::bigint) $$,
  'B deve 20 € ad Anna');
select throws_ok($$ select update_shared_expense(current_setting('test.dinner')::uuid,
    'Cena', 6000, 'EUR', current_date, 'b2222222-2222-2222-2222-222222222222',
    pg_temp.shares('b2222222-2222-2222-2222-222222222222', '6000',
                   'a1111111-1111-1111-1111-111111111111', '0')) $$,
  'P0001', 'spesa non trovata', 'solo chi l''ha creata modifica una spesa');
select throws_ok($$ select delete_shared_expense(current_setting('test.dinner')::uuid) $$,
  'P0001', 'spesa non trovata', 'solo chi l''ha creata elimina una spesa');

-- A corregge l'importo prima che altri registrino la quota.
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select lives_ok($$ select update_shared_expense(current_setting('test.dinner')::uuid,
    'Cena', 9000, 'EUR', current_date, 'a1111111-1111-1111-1111-111111111111',
    pg_temp.shares('a1111111-1111-1111-1111-111111111111', '3000',
                   'b2222222-2222-2222-2222-222222222222', '3000',
                   'c3333333-3333-3333-3333-333333333333', '3000')) $$,
  'A modifica la spesa finché nessun altro ha registrato la quota');
select is((select balance_cents from friend_balances() where display_name = 'Bea'),
  3000::bigint, 'il saldo segue la modifica');

-- B registra la quota: da qui la spesa è bloccata.
set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';
select lives_ok($$ select register_my_share(current_setting('test.dinner')::uuid) $$,
  'B registra la sua quota');
select lives_ok($$ select register_my_share(current_setting('test.dinner')::uuid) $$,
  'registrare due volte non cambia nulla');
select is((select my_share_registered from list_shared_expenses()), true,
  'per B la quota risulta registrata');

set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select is((select locked from list_shared_expenses()), true,
  'registrata da un altro, la spesa è bloccata');
select throws_ok($$ select update_shared_expense(current_setting('test.dinner')::uuid,
    'Cena', 6000, 'EUR', current_date, 'a1111111-1111-1111-1111-111111111111',
    pg_temp.shares('a1111111-1111-1111-1111-111111111111', '3000',
                   'b2222222-2222-2222-2222-222222222222', '3000')) $$,
  'P0001', 'spesa bloccata', 'una spesa bloccata non si modifica');
select throws_ok($$ select delete_shared_expense(current_setting('test.dinner')::uuid) $$,
  'P0001', 'spesa bloccata', 'una spesa bloccata non si elimina');

-- =====================================================================
-- C paga un taxi in dollari: saldi per valuta, mai convertiti
-- =====================================================================
set local request.jwt.claims = '{"sub":"c3333333-3333-3333-3333-333333333333","role":"authenticated"}';
select lives_ok($$ select create_shared_expense('Taxi', 1000, 'USD', current_date,
    'c3333333-3333-3333-3333-333333333333',
    pg_temp.shares('c3333333-3333-3333-3333-333333333333', '500',
                   'a1111111-1111-1111-1111-111111111111', '500')) $$,
  'C crea una spesa in dollari pagata da lui');

set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select results_eq(
  $$ select currency, balance_cents from friend_balances() where display_name = 'Carlo'
      order by currency $$,
  $$ values ('EUR'::text, 3000::bigint), ('USD', -500::bigint) $$,
  'con Carlo: un saldo per valuta, nessuna compensazione tra valute');

-- Una spesa eliminata (non ancora registrata da altri) esce dai saldi.
select set_config('test.gone', create_shared_expense(null, 400, 'EUR', current_date,
    'a1111111-1111-1111-1111-111111111111',
    pg_temp.shares('a1111111-1111-1111-1111-111111111111', '200',
                   'b2222222-2222-2222-2222-222222222222', '200'))::text, true);
select lives_ok($$ select delete_shared_expense(current_setting('test.gone')::uuid) $$,
  'A elimina una spesa che nessuno ha registrato');
select is((select balance_cents from friend_balances() where display_name = 'Bea'),
  3000::bigint, 'la spesa eliminata non conta nei saldi');
select is((select count(*)::int from list_shared_expenses()
            where expense_id = current_setting('test.gone')::uuid),
  0, 'e non compare più nella lista');

-- =====================================================================
-- Rimborsi: B deve 30 € ad Anna
-- =====================================================================
set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';
select throws_ok($$ select record_settlement('a1111111-1111-1111-1111-111111111111', 5000, 'EUR') $$,
  'P0001', 'importo oltre il debito', 'non si rimborsa più di quanto si deve');
select throws_ok($$ select record_settlement('a1111111-1111-1111-1111-111111111111', 0, 'EUR') $$,
  'P0001', 'importo non valido', 'importo del rimborso positivo');
select throws_ok($$ select record_settlement('d4444444-4444-4444-4444-444444444444', 100, 'EUR') $$,
  'P0001', 'importo oltre il debito', 'niente rimborsi a chi non si deve nulla');
select set_config('test.s1',
  record_settlement('a1111111-1111-1111-1111-111111111111', 2000, 'EUR')::text, true);
select throws_ok($$ select record_settlement('a1111111-1111-1111-1111-111111111111', 1500, 'EUR') $$,
  'P0001', 'importo oltre il debito', 'i rimborsi in attesa contano nel limite');
select set_config('test.s2',
  record_settlement('a1111111-1111-1111-1111-111111111111', 1000, 'EUR')::text, true);
select is((select balance_cents from friend_balances()), -3000::bigint,
  'un rimborso in attesa non cambia il saldo');
select is((select count(*)::int from list_settlements()
            where direction = 'outgoing' and status = 'pending'),
  2, 'B vede i due rimborsi in attesa');
select lives_ok($$ select cancel_settlement(current_setting('test.s2')::uuid) $$,
  'B annulla un rimborso in attesa');
select throws_ok($$ select register_my_settlement(current_setting('test.s1')::uuid) $$,
  'P0001', 'rimborso non trovato', 'un rimborso in attesa non si registra');
select throws_ok($$ select respond_settlement(current_setting('test.s1')::uuid, true) $$,
  'P0001', 'rimborso non trovato', 'chi paga non può confermare da sé');

set local request.jwt.claims = '{"sub":"c3333333-3333-3333-3333-333333333333","role":"authenticated"}';
select throws_ok($$ select respond_settlement(current_setting('test.s1')::uuid, true) $$,
  'P0001', 'rimborso non trovato', 'nessuno conferma rimborsi altrui');

set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select results_eq(
  $$ select direction, display_name, amount_cents, status from list_settlements() $$,
  $$ values ('incoming'::text, 'Bea'::text, 2000::bigint, 'pending'::text) $$,
  'Anna vede il rimborso in arrivo da Bea');
select lives_ok($$ select respond_settlement(current_setting('test.s1')::uuid, true) $$,
  'Anna conferma il rimborso');
select is((select my_registered from list_settlements()
            where settlement_id = current_setting('test.s1')::uuid),
  false, 'confermato, per Anna è ancora da registrare');
select lives_ok($$ select register_my_settlement(current_setting('test.s1')::uuid) $$,
  'Anna registra l''entrata nel suo portafoglio');
select lives_ok($$ select register_my_settlement(current_setting('test.s1')::uuid) $$,
  'registrare due volte non cambia nulla');
select is((select my_registered from list_settlements()
            where settlement_id = current_setting('test.s1')::uuid),
  true, 'per Anna il rimborso risulta registrato');
select is((select balance_cents from friend_balances() where display_name = 'Bea'),
  1000::bigint, 'confermato, il rimborso scala il saldo');
select throws_ok($$ select respond_settlement(current_setting('test.s1')::uuid, true) $$,
  'P0001', 'rimborso non trovato', 'un rimborso si conferma una volta sola');
select throws_ok($$ select record_settlement('b2222222-2222-2222-2222-222222222222', 100, 'EUR') $$,
  'P0001', 'importo oltre il debito', 'Anna non deve nulla a Bea: niente rimborso');

set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';
select set_config('test.s3',
  record_settlement('a1111111-1111-1111-1111-111111111111', 500, 'EUR')::text, true);
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select lives_ok($$ select respond_settlement(current_setting('test.s3')::uuid, false) $$,
  'Anna rifiuta un rimborso che non ha ricevuto');
select is((select balance_cents from friend_balances() where display_name = 'Bea'),
  1000::bigint, 'un rimborso rifiutato non conta');

-- =====================================================================
-- Fine dell'amicizia: saldo e rimborsi restano, nuove spese no
-- =====================================================================
set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';
select results_eq(
  $$ select status, my_registered from list_settlements()
      where settlement_id = current_setting('test.s1')::uuid $$,
  $$ values ('confirmed'::text, false) $$,
  'per Bea il rimborso confermato resta da registrare, separato da quello di Anna');
set local request.jwt.claims = '{"sub":"c3333333-3333-3333-3333-333333333333","role":"authenticated"}';
select throws_ok($$ select register_my_settlement(current_setting('test.s1')::uuid) $$,
  'P0001', 'rimborso non trovato', 'nessuno registra rimborsi altrui');
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select lives_ok($$ select remove_friend('b2222222-2222-2222-2222-222222222222') $$,
  'Anna rimuove Bea dagli amici');
select results_eq(
  $$ select balance_cents, is_friend from friend_balances() where display_name = 'Bea' $$,
  $$ values (1000::bigint, false) $$,
  'il saldo con Bea resta, non più come amica');
select throws_ok($$ select create_shared_expense('Pizza', 2000, 'EUR', current_date,
    'a1111111-1111-1111-1111-111111111111',
    pg_temp.shares('a1111111-1111-1111-1111-111111111111', '1000',
                   'b2222222-2222-2222-2222-222222222222', '1000')) $$,
  'P0001', 'utente non disponibile', 'niente nuove spese con chi non è più amico');

set local request.jwt.claims = '{"sub":"b2222222-2222-2222-2222-222222222222","role":"authenticated"}';
select lives_ok($$ select record_settlement('a1111111-1111-1111-1111-111111111111', 1000, 'EUR') $$,
  'Bea può ancora saldare il suo debito');

-- =====================================================================
-- Invarianti (come postgres)
-- =====================================================================
reset role;
select is(
  (select count(*)::int
     from (values ('EUR'), ('USD')) cur(c),
          (values ('a1111111-1111-1111-1111-111111111111'::uuid),
                  ('b2222222-2222-2222-2222-222222222222'::uuid),
                  ('c3333333-3333-3333-3333-333333333333'::uuid)) x(a),
          (values ('a1111111-1111-1111-1111-111111111111'::uuid),
                  ('b2222222-2222-2222-2222-222222222222'::uuid),
                  ('c3333333-3333-3333-3333-333333333333'::uuid)) y(b)
    where private.balance_between(x.a, y.b, cur.c)
          + private.balance_between(y.b, x.a, cur.c) <> 0),
  0, 'quanto uno deve all''altro è sempre l''opposto: i saldi si annullano');

set constraints shared_expense_shares_total immediate;
select throws_ok($$ update shared_expense_shares set share_cents = share_cents + 1
  where shared_expense_id = current_setting('test.dinner')::uuid
    and user_id = 'a1111111-1111-1111-1111-111111111111' $$,
  '23514', 'le quote non tornano col totale',
  'il database rifiuta quote che non tornano col totale');
set constraints all deferred;

-- Account cancellato: le spese restano, il partecipante è anonimo.
delete from auth.users where id = 'c3333333-3333-3333-3333-333333333333';
set local role authenticated;
set local request.jwt.claims = '{"sub":"a1111111-1111-1111-1111-111111111111","role":"authenticated"}';
select results_eq(
  $$ select currency, balance_cents from friend_balances() where user_id is null
      order by currency $$,
  $$ values ('EUR'::text, 3000::bigint), ('USD', -500::bigint) $$,
  'i saldi con un account cancellato restano, senza nome');
select is((select jsonb_array_length(shares) from list_shared_expenses()
            where expense_id = current_setting('test.dinner')::uuid),
  3, 'la cena tiene la quota del partecipante cancellato');

-- =====================================================================
-- Client anonimo
-- =====================================================================
reset role;
set local role anon;
set local request.jwt.claims = '{"role":"anon"}';
select throws_ok($$ select * from friend_balances() $$, '42501', null,
  'anonimo: niente saldi');
select throws_ok($$ select * from list_shared_expenses() $$, '42501', null,
  'anonimo: niente spese divise');
select throws_ok($$ select record_settlement('a1111111-1111-1111-1111-111111111111', 100, 'EUR') $$,
  '42501', null, 'anonimo: niente rimborsi');

select * from finish();
rollback;
