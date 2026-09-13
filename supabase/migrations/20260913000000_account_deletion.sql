-- nIpay — cancellazione account con grace period (M-ACC7)
--
-- deletion_requested_at valorizzato = l'utente ha chiesto la cancellazione.
-- Un nuovo login entro 30 giorni la annulla (azzerando il campo dal
-- client — RLS "update own profile" già lo permette, nessuna policy
-- nuova necessaria). Allo scadere dei 30 giorni, un job schedulato
-- lato server (Edge Function + cron, fuori da questa migration — vedi
-- ACCOUNT_SYNC_PLAN.md M-ACC7) cancella fisicamente l'utente da
-- auth.users: la cascata (`on delete cascade` già presente su
-- wallets.owner_user_id e su ogni tabella figlia) elimina tutto il
-- resto senza bisogno di cancellazioni manuali riga per riga.

alter table profiles add column deletion_requested_at timestamptz;
