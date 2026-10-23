-- Nome visualizzato già al signup (M-SOC2). Con la conferma email attiva
-- il client non ha una sessione subito dopo signUp, quindi non può
-- chiamare set_display_name: il nome arriva nei metadati della
-- registrazione (options.data.display_name) e lo salva il trigger.
--
-- I metadati li scrive il client: stesse regole di set_display_name, e un
-- nome non valido o assente lascia display_name vuoto senza mai bloccare
-- la registrazione (l'app lo richiede poi dal dialog "Come ti chiami?").
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  meta jsonb := new.raw_user_meta_data;
  cleaned text;
begin
  if pg_catalog.jsonb_typeof(meta) = 'object'
     and pg_catalog.jsonb_typeof(meta -> 'display_name') = 'string' then
    cleaned := pg_catalog.btrim(meta ->> 'display_name');
    if pg_catalog.char_length(cleaned) not between 1 and 40
       or cleaned ~ '[[:cntrl:]]' then
      cleaned := null;
    end if;
  end if;
  insert into public.profiles (id, friend_code, display_name)
  values (new.id, private.new_friend_code(), cleaned);
  return new;
end;
$$;
revoke all on function public.handle_new_user() from public, anon, authenticated;
