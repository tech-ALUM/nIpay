-- nIpay — M-SOC4 (fase 4): registrazione dei rimborsi nei portafogli
--
-- Decisione 2026-10-24: i movimenti di un rimborso nascono solo DOPO la
-- conferma, per entrambi: chi riceve registra l'entrata quando conferma,
-- chi ha pagato vede "Rimborso confermato: registralo". Come per le quote
-- delle spese divise (registered_at), il server tiene traccia di chi l'ha
-- già registrato, così l'app non lo ripropone e non lo registra due volte.

alter table public.settlements
  add column from_registered_at timestamptz,
  add column to_registered_at timestamptz;

-- Solo un rimborso confermato, solo la propria parte. Idempotente.
create or replace function public.register_my_settlement(target uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  uid uuid := auth.uid();
begin
  if uid is null then
    raise exception 'autenticazione richiesta' using errcode = '42501';
  end if;
  update public.settlements st
     set from_registered_at = case when st.from_user = uid
                                   then coalesce(st.from_registered_at, pg_catalog.now())
                                   else st.from_registered_at end,
         to_registered_at = case when st.to_user = uid
                                 then coalesce(st.to_registered_at, pg_catalog.now())
                                 else st.to_registered_at end
   where st.id = target and st.status = 'confirmed'
     and uid in (st.from_user, st.to_user);
  if not found then
    raise exception 'rimborso non trovato' using hint = 'not_found';
  end if;
end;
$$;

-- Come prima, più my_registered (la mia parte è nel mio portafoglio).
drop function public.list_settlements();
create function public.list_settlements()
returns table (
  settlement_id uuid,
  direction text,
  user_id uuid,
  display_name text,
  amount_cents bigint,
  currency text,
  status text,
  created_at timestamptz,
  responded_at timestamptz,
  my_registered boolean
)
language sql
stable
security definer
set search_path = ''
as $$
  select st.id,
         case when st.from_user = (select auth.uid()) then 'outgoing' else 'incoming' end,
         case when st.from_user = (select auth.uid()) then st.to_user else st.from_user end,
         p.display_name, st.amount_cents, st.currency, st.status,
         st.created_at, st.responded_at,
         case when st.from_user = (select auth.uid())
              then st.from_registered_at is not null
              else st.to_registered_at is not null end
    from public.settlements st
    left join public.profiles p
      on p.id = case when st.from_user = (select auth.uid())
                     then st.to_user else st.from_user end
   where (select auth.uid()) in (st.from_user, st.to_user)
     and (st.status = 'pending'
          -- Confermati ancora da registrare: restano finché non lo sono.
          or (st.status = 'confirmed' and case when st.from_user = (select auth.uid())
                                               then st.from_registered_at is null
                                               else st.to_registered_at is null end)
          or st.responded_at > pg_catalog.now() - interval '30 days')
   order by (st.status = 'pending') desc, st.created_at desc;
$$;

revoke all on function public.register_my_settlement(uuid) from public, anon;
revoke all on function public.list_settlements() from public, anon;
grant execute on function public.register_my_settlement(uuid) to authenticated;
grant execute on function public.list_settlements() to authenticated;
