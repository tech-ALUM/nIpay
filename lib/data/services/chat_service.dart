import 'dart:async';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

enum ConversationKind { direct, group }

enum MemberRole { admin, member }

/// Una conversazione della lista Chat (M-SOC3). Per le 1:1 [peerId] è
/// l'altra persona (null se ha cancellato l'account); [canSend] false =
/// sola lettura (non più amici, blocco, account cancellato).
class Conversation {
  const Conversation({
    required this.id,
    required this.kind,
    required this.title,
    required this.peerId,
    required this.peerDisplayName,
    required this.memberCount,
    required this.myRole,
    required this.canSend,
    required this.lastMessage,
    required this.unreadCount,
    required this.createdAt,
  });

  final String id;
  final ConversationKind kind;

  /// Solo gruppi.
  final String? title;
  final String? peerId;
  final String? peerDisplayName;
  final int memberCount;
  final MemberRole myRole;
  final bool canSend;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime createdAt;

  bool get isGroup => kind == ConversationKind.group;

  /// Per l'ordine della lista: ultimo messaggio, o la creazione.
  DateTime get activityAt => lastMessage?.createdAt ?? createdAt;
}

/// Un messaggio. Eliminato ([deleted]) = senza testo; [senderId] null =
/// account del mittente cancellato.
class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderDisplayName,
    required this.body,
    required this.createdAt,
    required this.deleted,
  });

  final String id;
  final String conversationId;
  final String? senderId;
  final String? senderDisplayName;
  final String? body;
  final DateTime createdAt;
  final bool deleted;

  ChatMessage copyWith({String? senderDisplayName}) => ChatMessage(
    id: id,
    conversationId: conversationId,
    senderId: senderId,
    senderDisplayName: senderDisplayName ?? this.senderDisplayName,
    body: body,
    createdAt: createdAt,
    deleted: deleted,
  );
}

class ConversationMember {
  const ConversationMember({
    required this.userId,
    required this.displayName,
    required this.role,
    required this.joinedAt,
  });

  final String userId;
  final String? displayName;
  final MemberRole role;
  final DateTime joinedAt;
}

enum ReportReason { spam, offensive, harassment, other }

/// Evento in tempo reale. I messaggi arrivano interi (senza il nome del
/// mittente, che la chat ricava dai membri); per membri e amicizie basta
/// sapere che qualcosa è cambiato.
sealed class ChatEvent {
  const ChatEvent();
}

class MessageChanged extends ChatEvent {
  const MessageChanged(this.message);

  final ChatMessage message;
}

class MembershipChanged extends ChatEvent {
  const MembershipChanged();
}

class FriendshipsChanged extends ChatEvent {
  const FriendshipsChanged();
}

/// Categoria di errore per la UI (SECURITY_AUDIT NIP-17: mai il testo
/// grezzo del server).
enum ChatErrorCode {
  notAvailable,
  notFound,
  readOnly,
  invalidMessage,
  invalidTitle,
  noMembers,
  tooManyMembers,
  invalidReport,
  rateLimited,

  /// Il mio account è in cancellazione: solo lettura e debiti (M-SOC5).
  pendingDeletion,
  network,
  unknown,
}

class ChatException implements Exception {
  const ChatException(this.code);

  final ChatErrorCode code;

  @override
  String toString() => 'ChatException(${code.name})';
}

/// Regole del server (migration 20261023010000), ripetute qui per
/// rispondere subito senza una chiamata.
const kMaxMessageLength = 2000;
const kMaxGroupTitleLength = 60;
const kMaxGroupMembers = 50;
const kMaxReportDetailsLength = 500;

abstract interface class ChatService {
  Future<List<Conversation>> listConversations();

  /// Dalla più recente. [before] = ultimo messaggio della pagina
  /// precedente (keyset), null per la prima pagina.
  Future<List<ChatMessage>> listMessages(
    String conversationId, {
    ChatMessage? before,
    int pageSize = 50,
  });
  Future<List<ConversationMember>> listMembers(String conversationId);

  /// Restituisce l'id della chat 1:1 con un amico (la crea se serve).
  Future<String> openDirect(String friendId);
  Future<String> createGroup(String title, List<String> memberIds);
  Future<void> addMembers(String conversationId, List<String> memberIds);
  Future<void> removeMember(String conversationId, String userId);
  Future<void> leaveGroup(String conversationId);

  /// Il messaggio salvato (testo ripulito, ora del server).
  Future<ChatMessage> send(String conversationId, String body);
  Future<void> deleteMessage(String messageId);
  Future<void> markRead(String conversationId);
  Future<void> reportMessage(
    String messageId,
    ReportReason reason, {
    String? details,
  });
  Future<void> reportUser(
    String userId,
    ReportReason reason, {
    String? details,
  });

  /// Eventi in tempo reale dell'utente loggato. La RLS del server lascia
  /// passare solo quelli delle sue conversazioni.
  Stream<ChatEvent> events();

  /// True quando il canale in tempo reale è collegato: senza, l'invio è
  /// disattivato con una spiegazione (niente coda offline in v1).
  Stream<bool> connection();
}

ChatException chatErrorOf(Object error) => switch (error) {
  ChatException() => error,
  sb.PostgrestException(:final hint) => ChatException(switch (hint) {
    'not_available' => ChatErrorCode.notAvailable,
    'not_found' => ChatErrorCode.notFound,
    'read_only' => ChatErrorCode.readOnly,
    'invalid_message' => ChatErrorCode.invalidMessage,
    'invalid_title' => ChatErrorCode.invalidTitle,
    'no_members' => ChatErrorCode.noMembers,
    'too_many_members' => ChatErrorCode.tooManyMembers,
    'invalid_report' => ChatErrorCode.invalidReport,
    'rate_limited' => ChatErrorCode.rateLimited,
    'pending_deletion' => ChatErrorCode.pendingDeletion,
    _ => ChatErrorCode.unknown,
  }),
  SocketException() ||
  http.ClientException() ||
  TimeoutException() => const ChatException(ChatErrorCode.network),
  _ => const ChatException(ChatErrorCode.unknown),
};

DateTime? _date(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

MemberRole _role(Object? value) =>
    value == 'admin' ? MemberRole.admin : MemberRole.member;

/// Riga di `messages` (evento Realtime o risposta del server).
ChatMessage chatMessageFromRow(Map<String, dynamic> r) => ChatMessage(
  id: (r['message_id'] ?? r['id']) as String,
  conversationId: (r['conversation_id'] ?? '') as String,
  senderId: r['sender_id'] as String?,
  senderDisplayName: r['sender_display_name'] as String?,
  body: r['body'] as String?,
  createdAt: DateTime.parse(r['created_at'] as String),
  deleted: r['deleted'] as bool? ?? r['deleted_at'] != null,
);

class SupabaseChatService implements ChatService {
  SupabaseChatService(this._client);

  final sb.SupabaseClient _client;

  Future<List<Map<String, dynamic>>> _rows(
    String function, [
    Map<String, dynamic>? params,
  ]) async {
    final rows = await _client.rpc<List<dynamic>>(function, params: params);
    return rows.cast<Map<String, dynamic>>();
  }

  @override
  Future<List<Conversation>> listConversations() => _guard(() async {
    final rows = await _rows('list_conversations');
    return [
      for (final r in rows)
        Conversation(
          id: r['conversation_id'] as String,
          kind: r['kind'] == 'group'
              ? ConversationKind.group
              : ConversationKind.direct,
          title: r['title'] as String?,
          peerId: r['peer_id'] as String?,
          peerDisplayName: r['peer_display_name'] as String?,
          memberCount: r['member_count'] as int,
          myRole: _role(r['my_role']),
          canSend: r['can_send'] as bool,
          lastMessage: r['last_message_id'] == null
              ? null
              : ChatMessage(
                  id: r['last_message_id'] as String,
                  conversationId: r['conversation_id'] as String,
                  senderId: r['last_sender_id'] as String?,
                  senderDisplayName: null,
                  body: r['last_body'] as String?,
                  createdAt: DateTime.parse(r['last_message_at'] as String),
                  deleted: r['last_message_deleted'] as bool,
                ),
          unreadCount: r['unread_count'] as int,
          createdAt: DateTime.parse(r['created_at'] as String),
        ),
    ];
  });

  @override
  Future<List<ChatMessage>> listMessages(
    String conversationId, {
    ChatMessage? before,
    int pageSize = 50,
  }) => _guard(() async {
    final rows = await _rows('list_messages', {
      'conv': conversationId,
      'before_at': before?.createdAt.toUtc().toIso8601String(),
      'before_id': before?.id,
      'page_size': pageSize,
    });
    return [
      for (final r in rows)
        chatMessageFromRow({...r, 'conversation_id': conversationId}),
    ];
  });

  @override
  Future<List<ConversationMember>> listMembers(String conversationId) =>
      _guard(() async {
        final rows = await _rows('list_conversation_members', {
          'conv': conversationId,
        });
        return [
          for (final r in rows)
            ConversationMember(
              userId: r['user_id'] as String,
              displayName: r['display_name'] as String?,
              role: _role(r['role']),
              joinedAt: _date(r['joined_at'])!,
            ),
        ];
      });

  @override
  Future<String> openDirect(String friendId) => _guard(
    () => _client.rpc<String>(
      'open_direct_conversation',
      params: {'friend': friendId},
    ),
  );

  @override
  Future<String> createGroup(String title, List<String> memberIds) => _guard(
    () => _client.rpc<String>(
      'create_group',
      params: {'title': title, 'member_ids': memberIds},
    ),
  );

  @override
  Future<void> addMembers(String conversationId, List<String> memberIds) =>
      _guard(
        () => _client.rpc<void>(
          'add_group_members',
          params: {'conv': conversationId, 'member_ids': memberIds},
        ),
      );

  @override
  Future<void> removeMember(String conversationId, String userId) => _guard(
    () => _client.rpc<void>(
      'remove_group_member',
      params: {'conv': conversationId, 'member': userId},
    ),
  );

  @override
  Future<void> leaveGroup(String conversationId) => _guard(
    () => _client.rpc<void>('leave_group', params: {'conv': conversationId}),
  );

  @override
  Future<ChatMessage> send(String conversationId, String body) =>
      _guard(() async {
        final rows = await _rows('send_message', {
          'conv': conversationId,
          'body': body,
        });
        final r = rows.single;
        return ChatMessage(
          id: r['message_id'] as String,
          conversationId: conversationId,
          senderId: _client.auth.currentUser?.id,
          senderDisplayName: null,
          body: body.trim(),
          createdAt: DateTime.parse(r['created_at'] as String),
          deleted: false,
        );
      });

  @override
  Future<void> deleteMessage(String messageId) => _guard(
    () => _client.rpc<void>('delete_message', params: {'target': messageId}),
  );

  @override
  Future<void> markRead(String conversationId) => _guard(
    () => _client.rpc<void>(
      'mark_conversation_read',
      params: {'conv': conversationId},
    ),
  );

  @override
  Future<void> reportMessage(
    String messageId,
    ReportReason reason, {
    String? details,
  }) => _guard(
    () => _client.rpc<void>(
      'report_message',
      params: {'target': messageId, 'reason': reason.name, 'details': details},
    ),
  );

  @override
  Future<void> reportUser(
    String userId,
    ReportReason reason, {
    String? details,
  }) => _guard(
    () => _client.rpc<void>(
      'report_user',
      params: {'target': userId, 'reason': reason.name, 'details': details},
    ),
  );

  final _connection = StreamController<bool>.broadcast();

  @override
  Stream<bool> connection() => _connection.stream;

  @override
  Stream<ChatEvent> events() {
    late final StreamController<ChatEvent> controller;
    sb.RealtimeChannel? channel;
    controller = StreamController<ChatEvent>(
      onListen: () {
        channel = _client
            .channel('nipay-chat')
            .onPostgresChanges(
              event: sb.PostgresChangeEvent.all,
              schema: 'public',
              table: 'messages',
              callback: (payload) {
                // DELETE (gruppo cancellato, account cancellato): niente
                // contenuto da mostrare, la lista si ricarica.
                if (payload.newRecord.isEmpty) {
                  controller.add(const MembershipChanged());
                  return;
                }
                controller.add(
                  MessageChanged(chatMessageFromRow(payload.newRecord)),
                );
              },
            )
            .onPostgresChanges(
              event: sb.PostgresChangeEvent.all,
              schema: 'public',
              table: 'conversation_members',
              callback: (_) => controller.add(const MembershipChanged()),
            )
            .onPostgresChanges(
              event: sb.PostgresChangeEvent.all,
              schema: 'public',
              table: 'friendships',
              callback: (_) => controller.add(const FriendshipsChanged()),
            )
            .subscribe((status, _) {
              _connection.add(status == sb.RealtimeSubscribeStatus.subscribed);
            });
      },
      onCancel: () async {
        final c = channel;
        channel = null;
        if (c != null) await _client.removeChannel(c);
        _connection.add(false);
      },
    );
    return controller.stream;
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e) {
      throw chatErrorOf(e);
    }
  }
}
