// nIpay — hard-delete definitivo degli account con grace period scaduto
// (M-ACC7). Pensata per girare su uno scheduler (Supabase Cron), MAI
// chiamabile pubblicamente: usa la service_role key (unico punto
// autorizzato a bypassare RLS in tutto il progetto) e richiede un
// segreto condiviso nell'header, non un JWT utente.
//
// Hardening (SECURITY_AUDIT.md NIP-06, NIP-19):
//   * gli allegati vengono elencati con paginazione e ricorsione nelle
//     sottocartelle; l'utente viene cancellato SOLO se nello Storage non
//     resta alcun oggetto suo (verifica lato database), altrimenti l'esito
//     è "failed" e si riprova al giro successivo;
//   * gli errori di list/remove non vengono più ignorati;
//   * confronto del segreto a tempo costante;
//   * soglia massima di account per esecuzione (MAX_PURGES_PER_RUN) e
//     modalità dry-run (`?dry_run=1`), per limitare i danni di un bug o di
//     un abuso;
//   * audit log in private.account_audit_log (via log_account_event);
//   * la risposta non contiene messaggi d'errore interni (solo nei log).
//
// Deploy: `supabase functions deploy purge-deleted-accounts --no-verify-jwt`
// (--no-verify-jwt: lo scheduler non ha un JWT utente; la protezione è il
// segreto). Env (impostale con `supabase secrets set`):
//   CRON_SECRET          stringa casuale lunga (>= 32 caratteri)
//   MAX_PURGES_PER_RUN   opzionale, default 20
// SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY sono già disponibili di
// default nel runtime delle Edge Function, non vanno impostate a mano.
//
// Scheduling (SQL editor), con il segreto in Supabase Vault invece che in
// chiaro dentro cron.job:
//   select vault.create_secret('<lo-stesso-CRON_SECRET>', 'purge_cron_secret');
//   select cron.schedule(
//     'purge-deleted-accounts-daily',
//     '0 3 * * *', -- ogni giorno alle 03:00 UTC
//     $$
//     select net.http_post(
//       url := 'https://<project-ref>.supabase.co/functions/v1/purge-deleted-accounts',
//       headers := jsonb_build_object(
//         'x-cron-secret',
//         (select decrypted_secret from vault.decrypted_secrets
//           where name = 'purge_cron_secret')
//       )
//     );
//     $$
//   );

import { timingSafeEqual } from 'node:crypto';
import { createClient, type SupabaseClient } from 'jsr:@supabase/supabase-js@2';

const BUCKET = 'attachments';
const PAGE_SIZE = 100;
const DEFAULT_MAX_PURGES = 20;

function secretMatches(provided: string | null, expected: string): boolean {
  if (provided === null) return false;
  const a = new TextEncoder().encode(provided);
  const b = new TextEncoder().encode(expected);
  // timingSafeEqual richiede lunghezze uguali: il confronto con se stesso
  // mantiene il tempo indipendente dal contenuto.
  if (a.length !== b.length) {
    timingSafeEqual(b, b);
    return false;
  }
  return timingSafeEqual(a, b);
}

/** Tutti i path degli oggetti sotto `prefix`, ricorsivo e paginato. */
async function listAllObjects(
  admin: SupabaseClient,
  prefix: string,
): Promise<string[]> {
  const paths: string[] = [];
  for (let offset = 0; ; offset += PAGE_SIZE) {
    const { data, error } = await admin.storage.from(BUCKET).list(prefix, {
      limit: PAGE_SIZE,
      offset,
      sortBy: { column: 'name', order: 'asc' },
    });
    if (error) throw new Error(`list ${prefix}: ${error.message}`);
    for (const entry of data ?? []) {
      const path = `${prefix}/${entry.name}`;
      // Le "cartelle" restituite da list() non hanno id.
      if (entry.id === null) {
        paths.push(...(await listAllObjects(admin, path)));
      } else {
        paths.push(path);
      }
    }
    if (!data || data.length < PAGE_SIZE) return paths;
  }
}

async function purgeUserFiles(
  admin: SupabaseClient,
  userId: string,
): Promise<number> {
  const paths = await listAllObjects(admin, userId);
  for (let i = 0; i < paths.length; i += PAGE_SIZE) {
    const { error } = await admin.storage
      .from(BUCKET)
      .remove(paths.slice(i, i + PAGE_SIZE));
    if (error) throw new Error(`remove: ${error.message}`);
  }
  return paths.length;
}

async function audit(
  admin: SupabaseClient,
  userId: string,
  event: string,
  details: Record<string, unknown>,
): Promise<void> {
  const { error } = await admin.rpc('log_account_event', {
    target_user: userId,
    event,
    details,
  });
  if (error) console.error(`audit log failed for ${userId}: ${error.message}`);
}

Deno.serve(async (req) => {
  const expectedSecret = Deno.env.get('CRON_SECRET');
  if (
    !expectedSecret ||
    expectedSecret.length < 32 ||
    !secretMatches(req.headers.get('x-cron-secret'), expectedSecret)
  ) {
    return new Response('Unauthorized', { status: 401 });
  }

  const dryRun = new URL(req.url).searchParams.get('dry_run') === '1';
  const maxPurges = Math.max(
    0,
    Math.min(
      Number.parseInt(Deno.env.get('MAX_PURGES_PER_RUN') ?? '', 10) ||
        DEFAULT_MAX_PURGES,
      1000,
    ),
  );

  const admin = createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!,
    { auth: { persistSession: false, autoRefreshToken: false } },
  );

  // Uno in più del tetto: se ci sono più candidati del previsto ci si
  // ferma e si segnala (un picco anomalo va guardato da una persona).
  const { data: candidates, error: selectError } = await admin.rpc(
    'purge_candidates',
    { max_accounts: maxPurges + 1 },
  );
  if (selectError) {
    console.error(`purge_candidates: ${selectError.message}`);
    return Response.json({ error: 'internal_error' }, { status: 500 });
  }

  const due = (candidates ?? []) as { user_id: string }[];
  if (due.length > maxPurges) {
    console.error(
      `purge aborted: ${due.length} accounts due, threshold ${maxPurges}`,
    );
    return Response.json(
      { error: 'threshold_exceeded', threshold: maxPurges },
      { status: 409 },
    );
  }

  if (dryRun) {
    return Response.json({ dryRun: true, due: due.map((c) => c.user_id) });
  }

  const results: { id: string; ok: boolean }[] = [];
  for (const { user_id: userId } of due) {
    try {
      // Gli oggetti Storage non hanno una foreign key verso auth.users:
      // vanno rimossi esplicitamente, la cascata del database non li tocca.
      const removed = await purgeUserFiles(admin, userId);

      const { data: remaining, error: countError } = await admin.rpc(
        'count_user_storage_objects',
        { target_user: userId },
      );
      if (countError) throw new Error(`count: ${countError.message}`);
      if (Number(remaining) !== 0) {
        throw new Error(`${remaining} storage objects still present`);
      }

      // Cancella l'utente da auth.users: la cascata (`on delete cascade`
      // su wallets.owner_user_id e su ogni tabella figlia) elimina
      // automaticamente profilo, portafogli, transazioni, ecc.
      const { error: deleteError } = await admin.auth.admin.deleteUser(userId);
      if (deleteError) throw new Error(`deleteUser: ${deleteError.message}`);

      await audit(admin, userId, 'account_purged', { files: removed });
      results.push({ id: userId, ok: true });
    } catch (error) {
      const message = error instanceof Error ? error.message : String(error);
      console.error(`purge failed for ${userId}: ${message}`);
      await audit(admin, userId, 'account_purge_failed', {});
      results.push({ id: userId, ok: false });
    }
  }

  return Response.json({ purged: results });
});
