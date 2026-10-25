-- nIpay — M-SOC0: i testi dei messaggi eliminati durano 90 giorni
-- (mds/FRIENDS_PLAN.md)
--
-- Gira su un Supabase locale (Docker), mai sul progetto reale:
--   supabase db start && supabase test db
-- Tutto dentro una transazione annullata alla fine: nessun residuo.

begin;
create extension if not exists pgtap with schema extensions;
select plan(8);

insert into auth.users (id, email) values
  ('a1111111-1111-1111-1111-111111111111', 'ret-a@test.local');
insert into conversations (id, kind, title, created_by) values
  ('c0000000-0000-0000-0000-000000000001', 'group', 'Gruppo',
   'a1111111-1111-1111-1111-111111111111');
insert into messages (id, conversation_id, sender_id, body, deleted_at) values
  ('e0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001',
   'a1111111-1111-1111-1111-111111111111', null, now() - interval '91 days'),
  ('e0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001',
   'a1111111-1111-1111-1111-111111111111', null, now() - interval '89 days');
insert into private.deleted_message_bodies (message_id, sender_id, body, deleted_at) values
  ('e0000000-0000-0000-0000-000000000001', 'a1111111-1111-1111-1111-111111111111',
   'vecchio', now() - interval '91 days'),
  ('e0000000-0000-0000-0000-000000000002', 'a1111111-1111-1111-1111-111111111111',
   'recente', now() - interval '89 days');

select is(private.purge_deleted_message_bodies(), 1,
  'cancella solo i testi eliminati da più di 90 giorni');
select is((select array_agg(body) from private.deleted_message_bodies),
  array['recente'], 'il testo eliminato da meno di 90 giorni resta');
select is((select count(*)::int from messages
            where conversation_id = 'c0000000-0000-0000-0000-000000000001'), 2,
  'i messaggi restano, come "Messaggio eliminato"');
select is(private.purge_deleted_message_bodies(), 0, 'una seconda passata non trova nulla');

select is(
  (select schedule from cron.job where jobname = 'purge-deleted-message-bodies-daily'),
  '30 3 * * *', 'il job gira ogni giorno alle 03:30 UTC');

select ok(
  not has_function_privilege('authenticated', 'private.purge_deleted_message_bodies()', 'execute'),
  'un utente non può chiamare la pulizia');

insert into private.rate_limit_events (user_id, action, at) values
  ('a1111111-1111-1111-1111-111111111111', 'report', now() - interval '25 hours'),
  ('a1111111-1111-1111-1111-111111111111', 'report', now() - interval '23 hours');
select is(private.purge_expired_rate_limit_events(), 1,
  'i limiti di frequenza più vecchi di 24 ore spariscono anche senza nuove azioni');
select is((select count(*)::int from private.rate_limit_events
            where user_id = 'a1111111-1111-1111-1111-111111111111'), 1,
  'gli eventi ancora nella finestra restano');

select * from finish();
rollback;
