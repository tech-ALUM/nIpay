-- nIpay — bucket Storage per gli allegati (M-ACC3)
--
-- Path convenzionale: {owner_user_id}/{attachment_id} (deciso in
-- ACCOUNT_SYNC_PLAN.md) — non indovinabile, non sequenziale.
-- Le policy verificano il primo segmento del path, non la colonna
-- `owner` di storage.objects (che un client potrebbe non impostare
-- correttamente): il path è la fonte di verità.
--
-- Accesso sempre via signed URL a tempo generata lato client dopo
-- autenticazione — mai bucket pubblico, mai URL permanenti.

insert into storage.buckets (id, name, public)
values ('attachments', 'attachments', false)
on conflict (id) do nothing;

create policy "select own attachment files" on storage.objects for select
  using (
    bucket_id = 'attachments'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "insert own attachment files" on storage.objects for insert
  with check (
    bucket_id = 'attachments'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "update own attachment files" on storage.objects for update
  using (
    bucket_id = 'attachments'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'attachments'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "delete own attachment files" on storage.objects for delete
  using (
    bucket_id = 'attachments'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
