import 'dart:async';

import 'package:nipay/data/services/chat_service.dart';

/// Doppio di [ChatService]: conversazioni e messaggi in memoria, chiamate
/// registrate, eventi in tempo reale emessi a mano con [emit].
class FakeChatService implements ChatService {
  FakeChatService({this.myId = 'me'});

  final String myId;
  final conversations = <Conversation>[];
  final messages = <String, List<ChatMessage>>{};
  final members = <String, List<ConversationMember>>{};
  final calls = <String>[];
  final _events = StreamController<ChatEvent>.broadcast();
  final _connection = StreamController<bool>.broadcast();
  ChatErrorCode? failNext;
  int _nextId = 0;
  DateTime _clock = DateTime.utc(2026, 10, 23, 9);

  void _maybeFail() {
    final code = failNext;
    if (code == null) return;
    failNext = null;
    throw ChatException(code);
  }

  DateTime _tick() => _clock = _clock.add(const Duration(minutes: 1));

  void emit(ChatEvent event) => _events.add(event);

  void setOnline(bool online) => _connection.add(online);

  /// Messaggio di un altro, come arriverebbe dal server.
  ChatMessage incoming(
    String conversationId,
    String body, {
    String senderId = 'bea',
  }) {
    final m = ChatMessage(
      id: 'm${_nextId++}',
      conversationId: conversationId,
      senderId: senderId,
      senderDisplayName: null,
      body: body,
      createdAt: _tick(),
      deleted: false,
    );
    messages.putIfAbsent(conversationId, () => []).insert(0, m);
    return m;
  }

  @override
  Future<List<Conversation>> listConversations() async {
    _maybeFail();
    return [...conversations];
  }

  @override
  Future<List<ChatMessage>> listMessages(
    String conversationId, {
    ChatMessage? before,
    int pageSize = 50,
  }) async {
    _maybeFail();
    calls.add('list:$conversationId:${before?.id}');
    final all = messages[conversationId] ?? const [];
    final start = before == null
        ? 0
        : all.indexWhere((m) => m.id == before.id) + 1;
    return all.skip(start).take(pageSize).toList();
  }

  @override
  Future<List<ConversationMember>> listMembers(String conversationId) async {
    _maybeFail();
    return [...?members[conversationId]];
  }

  @override
  Future<String> openDirect(String friendId) async {
    _maybeFail();
    calls.add('openDirect:$friendId');
    return 'direct-$friendId';
  }

  @override
  Future<String> createGroup(String title, List<String> memberIds) async {
    _maybeFail();
    calls.add('createGroup:$title:${memberIds.join(',')}');
    return 'group-new';
  }

  @override
  Future<void> addMembers(String conversationId, List<String> memberIds) async {
    _maybeFail();
    calls.add('addMembers:$conversationId:${memberIds.join(',')}');
  }

  @override
  Future<void> removeMember(String conversationId, String userId) async {
    _maybeFail();
    calls.add('removeMember:$conversationId:$userId');
    members[conversationId]?.removeWhere((m) => m.userId == userId);
  }

  @override
  Future<void> leaveGroup(String conversationId) async {
    _maybeFail();
    calls.add('leaveGroup:$conversationId');
  }

  @override
  Future<ChatMessage> send(String conversationId, String body) async {
    _maybeFail();
    calls.add('send:$conversationId:$body');
    final m = ChatMessage(
      id: 'm${_nextId++}',
      conversationId: conversationId,
      senderId: myId,
      senderDisplayName: null,
      body: body.trim(),
      createdAt: _tick(),
      deleted: false,
    );
    messages.putIfAbsent(conversationId, () => []).insert(0, m);
    return m;
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    _maybeFail();
    calls.add('delete:$messageId');
  }

  @override
  Future<void> markRead(String conversationId) async {
    calls.add('markRead:$conversationId');
  }

  @override
  Future<void> reportMessage(
    String messageId,
    ReportReason reason, {
    String? details,
  }) async {
    _maybeFail();
    calls.add('reportMessage:$messageId:${reason.name}:$details');
  }

  @override
  Future<void> reportUser(
    String userId,
    ReportReason reason, {
    String? details,
  }) async {
    _maybeFail();
    calls.add('reportUser:$userId:${reason.name}:$details');
  }

  @override
  Stream<ChatEvent> events() => _events.stream;

  @override
  Stream<bool> connection() => _connection.stream;
}

Conversation fakeConversation({
  required String id,
  ConversationKind kind = ConversationKind.direct,
  String? title,
  String? peerId = 'bea',
  String? peerDisplayName = 'Bea',
  int memberCount = 2,
  MemberRole myRole = MemberRole.member,
  bool canSend = true,
  ChatMessage? lastMessage,
  int unreadCount = 0,
}) => Conversation(
  id: id,
  kind: kind,
  title: title,
  peerId: kind == ConversationKind.group ? null : peerId,
  peerDisplayName: kind == ConversationKind.group ? null : peerDisplayName,
  memberCount: memberCount,
  myRole: myRole,
  canSend: canSend,
  lastMessage: lastMessage,
  unreadCount: unreadCount,
  createdAt: DateTime.utc(2026, 10, 23, 8),
);
