-- nIpay — M-SOC4 (fase 2): movimenti "con amici" nelle transazioni sincronizzate
--
--   * due tipi nuovi, come in Drift (schema v8): friendOut = soldi usciti
--     per altri (anticipo della loro quota, rimborso inviato), friendIn =
--     soldi messi da altri per te (tua quota pagata da un amico, rimborso
--     ricevuto). L'importo resta sempre >= 0 (transactions_amount_nonneg):
--     il verso lo dà il tipo, come per spese ed entrate;
--   * un movimento con amici non ha portafoglio di destinazione né
--     categoria (non è una spesa: non conta in statistiche e budget);
--   * shared_expense_id collega la propria quota e i movimenti con amici
--     alla spesa divisa sul server. Le regole ricorrenti restano solo
--     spesa/entrata/trasferimento.

alter table public.transactions drop constraint transactions_type_check;
alter table public.transactions add constraint transactions_type_check
  check (type in ('expense', 'income', 'transfer', 'friendOut', 'friendIn'));

alter table public.transactions add constraint transactions_friend_shape
  check (type not in ('friendOut', 'friendIn')
         or (wallet_to_id is null and category_id is null));

alter table public.transactions
  add column shared_expense_id uuid
    references public.shared_expenses (id) on delete set null;
create index transactions_shared_expense
  on public.transactions (shared_expense_id)
  where shared_expense_id is not null;
