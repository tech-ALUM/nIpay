import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Storage della sessione Supabase su Keychain (iOS) / Keystore (Android)
/// invece che SharedPreferences in chiaro (ACCOUNT_SYNC_PLAN.md, M-ACC4:
/// "token di sessione mai in shared_preferences").
class SecureAuthLocalStorage extends LocalStorage {
  SecureAuthLocalStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _sessionKey = 'supabase.session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return (await _storage.read(key: _sessionKey)) != null;
  }

  @override
  Future<String?> accessToken() => _storage.read(key: _sessionKey);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _sessionKey, value: persistSessionString);
}

/// Storage del code verifier del flusso PKCE (usato solo durante il
/// login OAuth, vita breve) — stessa scelta di sicurezza dello storage
/// di sessione, per coerenza.
class SecureAuthAsyncStorage extends GotrueAsyncStorage {
  SecureAuthAsyncStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  @override
  Future<String?> getItem({required String key}) => _storage.read(key: key);

  @override
  Future<void> removeItem({required String key}) => _storage.delete(key: key);

  @override
  Future<void> setItem({required String key, required String value}) =>
      _storage.write(key: key, value: value);
}
