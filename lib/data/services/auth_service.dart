import 'package:supabase_flutter/supabase_flutter.dart';

/// Lanciata per qualunque errore di autenticazione (credenziali sbagliate,
/// email già in uso, password troppo debole, ecc.), con il messaggio già
/// pronto per l'utente (Supabase lo restituisce in inglese: la UI traduce
/// i casi noti, il messaggio grezzo resta solo fallback).
class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

abstract interface class AuthService {
  /// Utente attualmente loggato, o null in modalità solo-locale.
  User? get currentUser;

  /// Emette il nuovo utente ad ogni cambio di stato (login, logout, refresh
  /// del token, sessione scaduta). Emette subito lo stato corrente.
  Stream<User?> get authStateChanges;

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  /// Cambia la password dell'utente loggato e disconnette tutte le ALTRE
  /// sessioni (altri device) — questa resta attiva. Coerente con
  /// ACCOUNT_SYNC_PLAN.md, M-ACC4: un cambio password deve invalidare
  /// eventuali sessioni rubate/dimenticate altrove.
  Future<void> changePassword(String newPassword);

  /// Null se non c'è una cancellazione account in corso, altrimenti il
  /// momento in cui è stata richiesta (la cancellazione fisica avviene
  /// 30 giorni dopo, lato server — M-ACC7).
  Future<DateTime?> getAccountDeletionRequestedAt();

  /// Segna l'account per la cancellazione (grace period 30 giorni,
  /// M-ACC7). Non cancella nulla subito: un nuovo login entro la
  /// finestra annulla la richiesta automaticamente lato UI
  /// ([cancelAccountDeletion]).
  Future<void> requestAccountDeletion();

  /// Annulla una richiesta di cancellazione ancora in grace period.
  Future<void> cancelAccountDeletion();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final SupabaseClient _client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<User?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((state) => state.session?.user);

  @override
  Future<void> signUpWithEmail({
    required String email,
    required String password,
  }) => _guard(() => _client.auth.signUp(email: email, password: password));

  @override
  Future<void> signInWithEmail({
    required String email,
    required String password,
  }) => _guard(
    () => _client.auth.signInWithPassword(email: email, password: password),
  );

  @override
  Future<void> signOut() => _guard(() => _client.auth.signOut());

  @override
  Future<void> sendPasswordResetEmail(String email) =>
      _guard(() => _client.auth.resetPasswordForEmail(email));

  @override
  Future<void> changePassword(String newPassword) => _guard(() async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
    await _client.auth.signOut(scope: SignOutScope.others);
  });

  @override
  Future<DateTime?> getAccountDeletionRequestedAt() => _guardValue(() async {
    final userId = currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from('profiles')
        .select('deletion_requested_at')
        .eq('id', userId)
        .maybeSingle();
    final value = row?['deletion_requested_at'] as String?;
    return value == null ? null : DateTime.parse(value);
  });

  @override
  Future<void> requestAccountDeletion() => _guard(() async {
    final userId = currentUser!.id;
    await _client
        .from('profiles')
        .update({'deletion_requested_at': DateTime.now().toIso8601String()})
        .eq('id', userId);
  });

  @override
  Future<void> cancelAccountDeletion() => _guard(() async {
    final userId = currentUser!.id;
    await _client
        .from('profiles')
        .update({'deletion_requested_at': null})
        .eq('id', userId);
  });

  Future<void> _guard(Future<void> Function() action) => _guardValue(action);

  Future<T> _guardValue<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthApiException catch (e) {
      throw AuthException(e.message);
    } on PostgrestException catch (e) {
      throw AuthException(e.message);
    }
  }
}
