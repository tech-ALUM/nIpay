import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Profilo dell'utente loggato (M-SOC1, mds/FRIENDS_PLAN.md): il nome che
/// vedono gli amici e il codice amico personale (contenuto del QR).
class MyProfile {
  const MyProfile({required this.displayName, required this.friendCode});

  /// Null finché l'utente non lo sceglie.
  final String? displayName;

  /// 10 caratteri dall'alfabeto senza ambigui; mostrarlo con
  /// [formatFriendCode].
  final String friendCode;
}

/// Chi corrisponde a un codice amico: solo id e nome, mai l'email.
class FriendCodeMatch {
  const FriendCodeMatch({required this.userId, required this.displayName});

  final String userId;
  final String? displayName;
}

/// Categoria di errore del profilo. La UI la traduce con l10n: il testo
/// grezzo del server non arriva mai all'utente (SECURITY_AUDIT NIP-17).
enum ProfileErrorCode { invalidDisplayName, rateLimited, network, unknown }

class ProfileException implements Exception {
  const ProfileException(this.code);

  final ProfileErrorCode code;

  @override
  String toString() => 'ProfileException(${code.name})';
}

abstract interface class ProfileService {
  /// Profilo dell'utente loggato, o null se non c'è nessuno loggato.
  Future<MyProfile?> getMyProfile();

  /// Salva il nome visualizzato e restituisce quello registrato dal server.
  Future<String> setDisplayName(String name);

  /// Nuovo codice amico: il precedente smette subito di funzionare.
  Future<String> regenerateFriendCode();

  /// Profilo a cui appartiene [code] (QR scansionato o digitato), o null
  /// se il codice non porta a nessuno (inesistente, proprio, malformato).
  Future<FriendCodeMatch?> resolveFriendCode(String code);
}

/// "ABCDE23456" → "ABCDE-23456": più facile da leggere e dettare.
String formatFriendCode(String code) =>
    code.length == 10 ? '${code.substring(0, 5)}-${code.substring(5)}' : code;

/// Traduce un errore di rete o di PostgREST nella categoria per la UI.
ProfileException profileErrorOf(Object error) => switch (error) {
  ProfileException() => error,
  sb.PostgrestException(hint: 'rate_limited') => const ProfileException(
    ProfileErrorCode.rateLimited,
  ),
  sb.PostgrestException(hint: 'invalid_display_name') => const ProfileException(
    ProfileErrorCode.invalidDisplayName,
  ),
  SocketException() ||
  http.ClientException() ||
  TimeoutException() => const ProfileException(ProfileErrorCode.network),
  _ => const ProfileException(ProfileErrorCode.unknown),
};

class SupabaseProfileService implements ProfileService {
  SupabaseProfileService(this._client);

  final sb.SupabaseClient _client;

  @override
  Future<MyProfile?> getMyProfile() => _guard(() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    final row = await _client
        .from('profiles')
        .select('display_name, friend_code')
        .eq('id', userId)
        .maybeSingle();
    if (row == null) return null;
    return MyProfile(
      displayName: row['display_name'] as String?,
      friendCode: row['friend_code'] as String,
    );
  });

  @override
  Future<String> setDisplayName(String name) => _guard(
    () => _client.rpc<String>('set_display_name', params: {'new_name': name}),
  );

  @override
  Future<String> regenerateFriendCode() =>
      _guard(() => _client.rpc<String>('regenerate_friend_code'));

  @override
  Future<FriendCodeMatch?> resolveFriendCode(String code) => _guard(() async {
    final rows = await _client.rpc<List<dynamic>>(
      'resolve_friend_code',
      params: {'code': code},
    );
    if (rows.isEmpty) return null;
    final row = rows.first as Map<String, dynamic>;
    return FriendCodeMatch(
      userId: row['id'] as String,
      displayName: row['display_name'] as String?,
    );
  });

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw profileErrorOf(e);
    }
  }
}
