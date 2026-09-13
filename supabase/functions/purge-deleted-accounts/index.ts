// nIpay — hard-delete definitivo degli account con grace period scaduto
// (M-ACC7). Pensata per girare su uno scheduler (Supabase Cron), MAI
// chiamabile pubblicamente: usa la service_role key (unico punto
// autorizzato a bypassare RLS in tutto il progetto) e richiede un
// segreto condiviso nell'header, non un JWT utente.
//
// Deploy: `supabase functions deploy purge-deleted-accounts --no-verify-jwt`
// Env richieste (impostale con `supabase secrets set`):
//   CRON_SECRET               stringa a caso, generata una volta
// SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY sono già disponibili di
// default nel runtime delle Edge Function, non vanno impostate a mano.
//
// Scheduling: Dashboard → Database → Cron Jobs, oppure SQL:
//   select cron.schedule(
//     'purge-deleted-accounts-daily',
//     '0 3 * * *', -- ogni giorno alle 03:00 UTC
//     $$
//     select net.http_post(
//       url := 'https://<project-ref>.supabase.co/functions/v1/purge-deleted-accounts',
//       headers := jsonb_build_object('x-cron-secret', '<lo-stesso-CRON_SECRET>')
//     );
//     $$
//   );

import { createClient } from 'jsr:@supabase/supabase-js@2';

const GRACE_PERIOD_DAYS = 30;

Deno.serve(async (req) => {
  const expectedSecret = Deno.env.get('CRON_SECRET');
  if (!expectedSecret || req.headers.get('x-cron-secret') !== expectedSecret) {
    return new Response('Unauthorized', { status: 401 });
  }

  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  const admin = createClient(supabaseUrl, serviceRoleKey);

  const cutoff = new Date();
  cutoff.setUTCDate(cutoff.getUTCDate() - GRACE_PERIOD_DAYS);

  const { data: profiles, error: selectError } = await admin
    .from('profiles')
    .select('id')
    .not('deletion_requested_at', 'is', null)
    .lte('deletion_requested_at', cutoff.toISOString());

  if (selectError) {
    return Response.json({ error: selectError.message }, { status: 500 });
  }

  const results: { id: string; ok: boolean; error?: string }[] = [];

  for (const profile of profiles ?? []) {
    const userId = profile.id as string;
    try {
      // Gli oggetti Storage non hanno una foreign key verso auth.users:
      // vanno rimossi esplicitamente, la cascata del database non li
      // tocca.
      const { data: files } = await admin.storage
        .from('attachments')
        .list(userId);
      if (files && files.length > 0) {
        await admin.storage
          .from('attachments')
          .remove(files.map((f) => `${userId}/${f.name}`));
      }

      // Cancella l'utente da auth.users: la cascata (`on delete cascade`
      // già su wallets.owner_user_id e su ogni tabella figlia, M-ACC1)
      // elimina automaticamente profilo, portafogli, transazioni, ecc.
      const { error: deleteError } = await admin.auth.admin.deleteUser(
        userId,
      );
      if (deleteError) throw deleteError;

      results.push({ id: userId, ok: true });
    } catch (error) {
      results.push({
        id: userId,
        ok: false,
        error: error instanceof Error ? error.message : String(error),
      });
    }
  }

  return Response.json({ purged: results });
});
