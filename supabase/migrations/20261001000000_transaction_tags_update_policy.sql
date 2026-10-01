-- nIpay — policy UPDATE mancante su transaction_tags
--
-- Il motore di sync invia ogni tabella con un upsert (PostgREST →
-- INSERT … ON CONFLICT DO UPDATE). Su transaction_tags c'erano solo
-- policy select/insert/delete: quando un collegamento tag↔transazione
-- già presente sul server veniva reinviato (sync interrotta a metà, riga
-- appena scaricata da un altro device con created_at successivo al
-- watermark di push), il ramo DO UPDATE veniva negato dalla RLS
-- ("new row violates row-level security policy (USING expression)") e
-- la sync falliva a ogni tentativo, senza mai avanzare il watermark.
--
-- Stessa condizione di ownership delle altre policy della tabella:
-- entrambi i lati del join devono appartenere all'utente, sia sulla
-- riga esistente (USING) sia su quella risultante (WITH CHECK).
-- Coperto da supabase/tests/rls_isolation_test.sql (sezione 6).

create policy "update own transaction_tags" on transaction_tags for update
  using (owns_transaction(transaction_id) and owns_tag(tag_id))
  with check (owns_transaction(transaction_id) and owns_tag(tag_id));
