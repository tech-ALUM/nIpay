-- nIpay — M-SOC0: conservazione dei messaggi eliminati (mds/FRIENDS_PLAN.md)
--
-- Il testo di un messaggio eliminato dal mittente resta in
-- private.deleted_message_bodies solo per la moderazione. Decisione
-- 2026-10-25: si conserva 90 giorni, poi sparisce (privacy policy,
-- mds/legal/privacy-policy.it.md). Una segnalazione aperta ha già la sua copia
-- (reports.message_body), quindi la moderazione non perde nulla.

create extension if not exists pg_cron;

create or replace function private.purge_deleted_message_bodies()
returns integer
language sql
set search_path = ''
as $$
  with gone as (
    delete from private.deleted_message_bodies
     where deleted_at < pg_catalog.now() - interval '90 days'
    returning 1
  )
  select pg_catalog.count(*)::integer from gone;
$$;
revoke all on function private.purge_deleted_message_bodies() from public, anon, authenticated;

-- Limiti di frequenza: la finestra più lunga è 24 ore. consume_rate_limit
-- pulisce solo quando lo stesso utente ripete la stessa azione; questa
-- pulizia toglie anche gli eventi di chi non l'ha più ripetuta, così
-- l'informativa può dire "al massimo 24 ore".
create or replace function private.purge_expired_rate_limit_events()
returns integer
language sql
set search_path = ''
as $$
  with gone as (
    delete from private.rate_limit_events
     where at < pg_catalog.now() - interval '24 hours'
    returning 1
  )
  select pg_catalog.count(*)::integer from gone;
$$;
revoke all on function private.purge_expired_rate_limit_events() from public, anon, authenticated;

-- Ogni giorno alle 03:30 UTC, dopo purge-deleted-accounts-daily.
select cron.schedule(
  'purge-deleted-message-bodies-daily',
  '30 3 * * *',
  'select private.purge_deleted_message_bodies(); select private.purge_expired_rate_limit_events()'
);
