-- nIpay — limiti dello Storage allegati (SECURITY_AUDIT.md NIP-12, NIP-25)
--
-- Il bucket era senza file_size_limit né allowed_mime_types, e la policy
-- controllava solo il primo segmento del path: qualunque utente registrato
-- poteva caricare file di qualunque tipo e dimensione (HTML, eseguibili),
-- in numero illimitato, e distribuirli con URL firmati dal dominio del
-- progetto.
--
-- Ora:
--   * solo immagini (JPEG/PNG/WebP) e PDF, al massimo 10 MiB a file;
--   * nome obbligatorio "{uid}/{uuid}.{ext}" (niente sottocartelle, niente
--     nomi arbitrari): coerente con attachments.storage_path (NIP-25);
--   * quota per utente: massimo 2000 file e 500 MiB in totale.

update storage.buckets
   set file_size_limit = 10485760,
       allowed_mime_types = array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
 where id = 'attachments';

-- Path ammesso per il file di un allegato dell'utente corrente.
create or replace function private.is_own_attachment_path(object_name text)
returns boolean
language sql
stable
set search_path = ''
as $$
  select auth.uid() is not null
    and object_name ~ (
      '^' || auth.uid()::text
      || '/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}\.(jpg|jpeg|png|webp|pdf)$'
    );
$$;

-- Quota: conta anche i file che l'utente non potrebbe vedere tramite la
-- RLS (security definer), così la verifica non dipende dalle policy select.
create or replace function private.attachment_quota_available()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select pg_catalog.count(*) < 2000
     and coalesce(pg_catalog.sum((o.metadata ->> 'size')::bigint), 0) < 524288000
  from storage.objects o
  where o.bucket_id = 'attachments'
    and o.name like auth.uid()::text || '/%';
$$;

revoke all on function private.is_own_attachment_path(text) from public, anon;
revoke all on function private.attachment_quota_available() from public, anon;
grant execute on function private.is_own_attachment_path(text) to authenticated, service_role;
grant execute on function private.attachment_quota_available() to authenticated, service_role;

drop policy "insert own attachment files" on storage.objects;
drop policy "update own attachment files" on storage.objects;

create policy "insert own attachment files" on storage.objects for insert
  to authenticated
  with check (
    bucket_id = 'attachments'
    and private.is_own_attachment_path(name)
    and private.attachment_quota_available()
  );

create policy "update own attachment files" on storage.objects for update
  to authenticated
  using (
    bucket_id = 'attachments'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'attachments'
    and private.is_own_attachment_path(name)
  );
