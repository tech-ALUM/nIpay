/// Configurazione del progetto Supabase (M-ACC4).
///
/// `anonKey` è la publishable/anon key: pensata per stare nel client
/// pubblico, protetta dalla RLS lato server (ACCOUNT_SYNC_PLAN.md,
/// M-ACC2) — non è un segreto, a differenza della service_role key, che
/// non deve MAI comparire in questo repo.
class SupabaseConfig {
  const SupabaseConfig._();

  static const url = 'https://tyjugoiohkktlyizfpfx.supabase.co';
  static const anonKey = 'sb_publishable_-lTLdJmpYQwpvrOX-FBccQ_bVuocTFA';
}
