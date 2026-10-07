import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;
import 'package:supabase_flutter/supabase_flutter.dart' show User;

/// Deep link registrato dall'app (AndroidManifest / Info.plist) per i link
/// delle email di Supabase Auth (recupero password). Va aggiunto, identico,
/// agli "Additional Redirect URLs" del progetto Supabase.
const kAuthRedirectUrl = 'com.alum.nipay://auth-callback';

/// Categoria di errore di autenticazione. La UI la traduce con l10n: i
/// messaggi grezzi di GoTrue/PostgREST non arrivano mai all'utente
/// (SECURITY_AUDIT NIP-17), e "email non confermata" non è distinguibile
/// da "credenziali errate" (niente enumerazione degli account).
enum AuthErrorCode {
  invalidCredentials,
  wrongCurrentPassword,
  weakPassword,
  samePassword,
  rateLimited,
  reauthenticationRequired,
  network,
  unknown,
}

/// Lanciata per qualunque errore di autenticazione o di gestione account.
class AuthException implements Exception {
  const AuthException(this.code);

  final AuthErrorCode code;

  @override
  String toString() => 'AuthException(${code.name})';
}

abstract interface class AuthService {
  /// Utente attualmente loggato, o null in modalità solo-locale.
  User? get currentUser;

  /// Emette il nuovo utente ad ogni cambio di stato (login, logout, refresh
  /// del token, sessione scaduta). Emette subito lo stato corrente.
  Stream<User?> get authStateChanges;

  /// Emette quando l'app viene aperta dal link di recupero password
  /// (deep link [kAuthRedirectUrl]): la UI chiede la nuova password e
  /// chiama [completePasswordRecovery].
  Stream<void> get passwordRecoveryRequests;

  Future<void> signUpWithEmail({
    required String email,
    required String password,
  });

  Future<void> signInWithEmail({
    required String email,
    required String password,
  });

  Future<void> signOut();

  /// Chiude TUTTE le sessioni dell'account, compresa questa (device perso o
  /// rubato: SECURITY_AUDIT NIP-09).
  Future<void> signOutEverywhere();

  /// Il link nell'email riapre l'app tramite [kAuthRedirectUrl]. Va aperto
  /// sullo stesso device che l'ha richiesto (flusso PKCE).
  Future<void> sendPasswordResetEmail(String email);

  /// Imposta la nuova password durante il recupero e disconnette tutte le
  /// altre sessioni (chi aveva la vecchia password non resta dentro).
  Future<void> completePasswordRecovery(String newPassword);

  /// Cambia la password dell'utente loggato e disconnette tutte le ALTRE
  /// sessioni (altri device) — questa resta attiva. Richiede la password
  /// attuale: una sessione da sola (telefono sbloccato, token rubato) non
  /// basta per prendersi l'account (SECURITY_AUDIT NIP-08).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  });

  /// Null se non c'è una cancellazione account in corso, altrimenti il
  /// momento in cui è stata richiesta (la cancellazione fisica avviene
  /// 30 giorni dopo, lato server — M-ACC7).
  Future<DateTime?> getAccountDeletionRequestedAt();

  /// Segna l'account per la cancellazione (grace period 30 giorni,
  /// M-ACC7). La data la decide il server e serve la password attuale
  /// (SECURITY_AUDIT NIP-05). Non cancella nulla subito: la richiesta si
  /// annulla con [cancelAccountDeletion] (banner nella schermata Account).
  Future<void> requestAccountDeletion({required String currentPassword});

  /// Annulla una richiesta di cancellazione ancora in grace period.
  Future<void> cancelAccountDeletion();
}

class SupabaseAuthService implements AuthService {
  SupabaseAuthService(this._client);

  final sb.SupabaseClient _client;

  @override
  User? get currentUser => _client.auth.currentUser;

  @override
  Stream<User?> get authStateChanges =>
      _client.auth.onAuthStateChange.map((state) => state.session?.user);

  @override
  Stream<void> get passwordRecoveryRequests => _client.auth.onAuthStateChange
      .where((state) => state.event == sb.AuthChangeEvent.passwordRecovery)
      .map((_) {});

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
  Future<void> signOutEverywhere() =>
      _guard(() => _client.auth.signOut(scope: sb.SignOutScope.global));

  @override
  Future<void> sendPasswordResetEmail(String email) => _guard(
    () =>
        _client.auth.resetPasswordForEmail(email, redirectTo: kAuthRedirectUrl),
  );

  @override
  Future<void> completePasswordRecovery(String newPassword) => _guard(() async {
    await _client.auth.updateUser(sb.UserAttributes(password: newPassword));
    await _client.auth.signOut(scope: sb.SignOutScope.others);
  });

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) => _guard(() async {
    await _reauthenticate(currentPassword);
    await _client.auth.updateUser(sb.UserAttributes(password: newPassword));
    await _client.auth.signOut(scope: sb.SignOutScope.others);
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

  /// La data la imposta il server (RPC `request_account_deletion`), che
  /// pretende anche un login recente: per questo la password viene
  /// verificata subito prima.
  @override
  Future<void> requestAccountDeletion({required String currentPassword}) =>
      _guard(() async {
        await _reauthenticate(currentPassword);
        await _client.rpc<void>('request_account_deletion');
      });

  @override
  Future<void> cancelAccountDeletion() =>
      _guard(() => _client.rpc<void>('cancel_account_deletion'));

  /// Verifica la password attuale con un nuovo login: aggiorna anche
  /// l'istante di autenticazione (`amr`) che il server controlla per le
  /// operazioni sensibili.
  Future<void> _reauthenticate(String password) async {
    final email = currentUser?.email;
    if (email == null) throw const AuthException(AuthErrorCode.unknown);
    try {
      await _client.auth.signInWithPassword(email: email, password: password);
    } on sb.AuthApiException catch (e) {
      if (e.code == 'invalid_credentials' || e.statusCode == '400') {
        throw const AuthException(AuthErrorCode.wrongCurrentPassword);
      }
      rethrow;
    }
  }

  Future<void> _guard(Future<void> Function() action) => _guardValue(action);

  Future<T> _guardValue<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on AuthException {
      rethrow;
    } on sb.AuthException catch (e) {
      throw AuthException(_codeOf(e));
    } on sb.PostgrestException catch (e) {
      throw AuthException(
        e.hint == 'reauthentication_required'
            ? AuthErrorCode.reauthenticationRequired
            : AuthErrorCode.unknown,
      );
    } on SocketException {
      throw const AuthException(AuthErrorCode.network);
    } on http.ClientException {
      throw const AuthException(AuthErrorCode.network);
    } on TimeoutException {
      throw const AuthException(AuthErrorCode.network);
    }
  }

  static AuthErrorCode _codeOf(sb.AuthException e) {
    if (e is sb.AuthWeakPasswordException) return AuthErrorCode.weakPassword;
    if (e is sb.AuthRetryableFetchException) return AuthErrorCode.network;
    if (e.statusCode == '429') return AuthErrorCode.rateLimited;
    return switch (e.code) {
      // Stesso messaggio per credenziali errate ed email non confermata:
      // altrimenti la risposta rivela quali email hanno un account.
      'invalid_credentials' ||
      'email_not_confirmed' => AuthErrorCode.invalidCredentials,
      'weak_password' => AuthErrorCode.weakPassword,
      'same_password' => AuthErrorCode.samePassword,
      'over_request_rate_limit' ||
      'over_email_send_rate_limit' => AuthErrorCode.rateLimited,
      'reauthentication_needed' ||
      'reauthentication_not_valid' => AuthErrorCode.reauthenticationRequired,
      _ => AuthErrorCode.unknown,
    };
  }
}
