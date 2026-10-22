import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Un amico accettato: solo id e nome visualizzato (M-SOC2).
class Friend {
  const Friend({
    required this.userId,
    required this.displayName,
    required this.friendsSince,
  });

  final String userId;
  final String? displayName;
  final DateTime? friendsSince;
}

enum FriendRequestDirection { incoming, outgoing }

enum FriendRequestStatus { pending, declined }

/// Richiesta in arrivo (sempre in attesa) o in uscita (in attesa, oppure
/// rifiutata negli ultimi 7 giorni).
class FriendRequest {
  const FriendRequest({
    required this.id,
    required this.direction,
    required this.userId,
    required this.displayName,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final FriendRequestDirection direction;

  /// L'altra persona: chi ha chiesto (in arrivo) o a chi (in uscita).
  final String userId;
  final String? displayName;
  final FriendRequestStatus status;
  final DateTime createdAt;
}

class BlockedUser {
  const BlockedUser({required this.userId, required this.displayName});

  final String userId;
  final String? displayName;
}

/// Esito di una richiesta inviata: in attesa, oppure già amici (eravate
/// amici o l'altra persona aveva già chiesto a te).
enum SendRequestResult { pending, accepted }

/// Categoria di errore per la UI (SECURITY_AUDIT NIP-17: mai il testo
/// grezzo del server). [notAvailable] copre inesistente, in cancellazione,
/// se stessi e blocchi: volutamente indistinguibili.
enum FriendsErrorCode {
  notAvailable,
  cooldown,
  tooManyPending,
  notFound,
  rateLimited,
  network,
  unknown,
}

class FriendsException implements Exception {
  const FriendsException(this.code);

  final FriendsErrorCode code;

  @override
  String toString() => 'FriendsException(${code.name})';
}

abstract interface class FriendsService {
  Future<List<Friend>> listFriends();
  Future<List<FriendRequest>> listRequests();
  Future<List<BlockedUser>> listBlocked();
  Future<SendRequestResult> sendRequest(String userId);

  /// Solo per le richieste in arrivo.
  Future<void> respond(String requestId, {required bool accept});

  /// Solo per le proprie richieste in attesa.
  Future<void> cancel(String requestId);
  Future<void> removeFriend(String userId);
  Future<void> block(String userId);
  Future<void> unblock(String userId);
}

/// Schema del deep link (Info.plist / AndroidManifest), lo stesso del
/// recupero password: il QR apre l'app da fotocamera di sistema.
const _linkPrefix = 'com.alum.nipay://friend/';

final _friendCode = RegExp(r'^[23456789ABCDEFGHJKLMNPQRSTUVWXYZ]{10}$');

/// Contenuto del QR personale.
String friendLink(String friendCode) => '$_linkPrefix$friendCode';

/// Codice amico da ciò che è stato scansionato o digitato: il link del QR
/// o il codice nudo (minuscole, spazi e trattini ammessi). Null per
/// qualunque altra cosa: QR di altre app, link estranei, codici malformati.
String? friendCodeFromScan(String raw) {
  var value = raw.trim();
  if (value.contains('://')) {
    if (!value.startsWith(_linkPrefix)) return null;
    value = value.substring(_linkPrefix.length);
  }
  final normalized = value.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
  return _friendCode.hasMatch(normalized) ? normalized : null;
}

FriendsException friendsErrorOf(Object error) => switch (error) {
  FriendsException() => error,
  sb.PostgrestException(:final hint) => FriendsException(switch (hint) {
    'not_available' => FriendsErrorCode.notAvailable,
    'cooldown' => FriendsErrorCode.cooldown,
    'too_many_pending' => FriendsErrorCode.tooManyPending,
    'not_found' => FriendsErrorCode.notFound,
    'rate_limited' => FriendsErrorCode.rateLimited,
    _ => FriendsErrorCode.unknown,
  }),
  SocketException() ||
  http.ClientException() ||
  TimeoutException() => const FriendsException(FriendsErrorCode.network),
  _ => const FriendsException(FriendsErrorCode.unknown),
};

class SupabaseFriendsService implements FriendsService {
  SupabaseFriendsService(this._client);

  final sb.SupabaseClient _client;

  Future<List<Map<String, dynamic>>> _rows(String function) async {
    final rows = await _client.rpc<List<dynamic>>(function);
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Friend>> listFriends() => _guard(() async {
    final rows = await _rows('list_friends');
    return [
      for (final r in rows)
        Friend(
          userId: r['user_id'] as String,
          displayName: r['display_name'] as String?,
          friendsSince: r['friends_since'] == null
              ? null
              : DateTime.parse(r['friends_since'] as String),
        ),
    ];
  });

  @override
  Future<List<FriendRequest>> listRequests() => _guard(() async {
    final rows = await _rows('list_friend_requests');
    return [
      for (final r in rows)
        FriendRequest(
          id: r['request_id'] as String,
          direction: r['direction'] == 'incoming'
              ? FriendRequestDirection.incoming
              : FriendRequestDirection.outgoing,
          userId: r['user_id'] as String,
          displayName: r['display_name'] as String?,
          status: r['status'] == 'declined'
              ? FriendRequestStatus.declined
              : FriendRequestStatus.pending,
          createdAt: DateTime.parse(r['created_at'] as String),
        ),
    ];
  });

  @override
  Future<List<BlockedUser>> listBlocked() => _guard(() async {
    final rows = await _rows('list_blocked');
    return [
      for (final r in rows)
        BlockedUser(
          userId: r['user_id'] as String,
          displayName: r['display_name'] as String?,
        ),
    ];
  });

  @override
  Future<SendRequestResult> sendRequest(String userId) => _guard(() async {
    final status = await _client.rpc<String>(
      'send_friend_request',
      params: {'addressee': userId},
    );
    return status == 'accepted'
        ? SendRequestResult.accepted
        : SendRequestResult.pending;
  });

  @override
  Future<void> respond(String requestId, {required bool accept}) => _guard(
    () => _client.rpc<void>(
      'respond_friend_request',
      params: {'request_id': requestId, 'accept': accept},
    ),
  );

  @override
  Future<void> cancel(String requestId) => _guard(
    () => _client.rpc<void>(
      'cancel_friend_request',
      params: {'request_id': requestId},
    ),
  );

  @override
  Future<void> removeFriend(String userId) => _guard(
    () => _client.rpc<void>('remove_friend', params: {'friend': userId}),
  );

  @override
  Future<void> block(String userId) =>
      _guard(() => _client.rpc<void>('block_user', params: {'target': userId}));

  @override
  Future<void> unblock(String userId) => _guard(
    () => _client.rpc<void>('unblock_user', params: {'target': userId}),
  );

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw friendsErrorOf(e);
    }
  }
}
