import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../data/services/chat_service.dart';
import '../../l10n/app_localizations.dart';
import 'chat_ui.dart';
import 'group_screens.dart';
import 'report_sheet.dart';

/// Una conversazione (M-SOC3): storia paginata dal server, nuovi messaggi
/// in tempo reale, invio. In sola lettura (non più amici, blocco, account
/// cancellato) o offline il campo d'invio è spento con la spiegazione.
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  static const _pageSize = 50;

  final _input = TextEditingController();

  /// Dal più recente al più vecchio (la lista è disegnata al contrario).
  List<ChatMessage> _messages = const [];
  Map<String, ConversationMember> _members = const {};
  StreamSubscription<ChatEvent>? _events;
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = false;
  bool _sending = false;
  bool _markingRead = false;
  ChatErrorCode? _loadError;
  String? _inputError;

  ChatService get _service => ref.read(chatServiceProvider);

  @override
  void initState() {
    super.initState();
    _subscribe(ref.read(chatEventsProvider));
    _load();
  }

  @override
  void dispose() {
    _events?.cancel();
    _input.dispose();
    super.dispose();
  }

  void _subscribe(Stream<ChatEvent> events) {
    _events?.cancel();
    _events = events.listen(_onEvent);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final results = await Future.wait([
        _service.listMessages(widget.conversationId, pageSize: _pageSize),
        _service.listMembers(widget.conversationId),
      ]);
      if (!mounted) return;
      final page = results[0] as List<ChatMessage>;
      setState(() {
        _members = {
          for (final m in results[1] as List<ConversationMember>) m.userId: m,
        };
        _messages = const [];
        for (final m in page) {
          _messages = _merge(_messages, m);
        }
        _hasMore = page.length == _pageSize;
        _loading = false;
      });
      unawaited(_markRead());
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.code;
      });
    }
  }

  Future<void> _loadEarlier() async {
    if (_loadingMore || _messages.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _service.listMessages(
        widget.conversationId,
        before: _messages.last,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        for (final m in page) {
          _messages = _merge(_messages, m);
        }
        _hasMore = page.length == _pageSize;
      });
    } on ChatException catch (e) {
      _snack(chatErrorText(AppLocalizations.of(context)!, e.code));
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _onEvent(ChatEvent event) {
    if (!mounted) return;
    switch (event) {
      case MessageChanged(:final message)
          when message.conversationId == widget.conversationId:
        if (message.senderId != null &&
            !_members.containsKey(message.senderId)) {
          unawaited(_reloadMembers());
        }
        setState(() => _messages = _merge(_messages, message));
        if (message.senderId != ref.read(authStateProvider).valueOrNull?.id) {
          unawaited(_markRead());
        }
      case MembershipChanged():
        unawaited(_reloadMembers());
      case MessageChanged() || FriendshipsChanged():
        break;
    }
  }

  Future<void> _reloadMembers() async {
    try {
      final members = await _service.listMembers(widget.conversationId);
      if (!mounted) return;
      setState(() => _members = {for (final m in members) m.userId: m});
    } on ChatException {
      // Uscito o tolto dal gruppo: la lista conversazioni lo riflette.
    }
  }

  /// Solo se la chat è davvero davanti all'utente; il badge si aggiorna
  /// ricaricando la lista.
  Future<void> _markRead() async {
    if (_markingRead || !(ModalRoute.of(context)?.isCurrent ?? true)) return;
    _markingRead = true;
    try {
      await _service.markRead(widget.conversationId);
      if (mounted) ref.invalidate(conversationsProvider);
    } on ChatException {
      // Non blocca la lettura: riprova al prossimo messaggio.
    } finally {
      _markingRead = false;
    }
  }

  /// Inserisce [incoming] in [messages] (dal più recente al più vecchio) e
  /// restituisce la nuova lista. Lo stesso messaggio può arrivare due
  /// volte: dalla risposta di [ChatService.send] e dall'evento in tempo
  /// reale; e un messaggio già in lista può tornare aggiornato (eliminato).
  /// Il nome del mittente si completa dai membri.
  List<ChatMessage> _merge(List<ChatMessage> messages, ChatMessage incoming) {
    final named = incoming.senderDisplayName != null
        ? incoming
        : incoming.copyWith(
            senderDisplayName: _members[incoming.senderId]?.displayName,
          );
    // Stesso id = stesso messaggio (doppione o aggiornamento): si sostituisce.
    final rest = [
      for (final m in messages)
        if (m.id != named.id) m,
    ];
    // Stesso ordine del server (created_at, id) decrescente. Si scorre
    // dall'alto: i messaggi nuovi si fermano subito, quelli vecchi in fondo.
    var i = 0;
    while (i < rest.length && _isAfter(rest[i], named)) {
      i++;
    }
    return [...rest.take(i), named, ...rest.skip(i)];
  }

  static bool _isAfter(ChatMessage a, ChatMessage b) =>
      a.createdAt.isAfter(b.createdAt) ||
      (a.createdAt.isAtSameMomentAs(b.createdAt) && a.id.compareTo(b.id) > 0);

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    final text = _input.text.trim();
    if (text.isEmpty) return;
    if (text.length > kMaxMessageLength) {
      setState(() => _inputError = l10n.chatErrorInvalidMessage);
      return;
    }
    setState(() {
      _sending = true;
      _inputError = null;
    });
    try {
      final sent = await _service.send(widget.conversationId, text);
      if (!mounted) return;
      _input.clear();
      setState(() => _messages = _merge(_messages, sent));
      ref.invalidate(conversationsProvider);
    } on ChatException catch (e) {
      if (e.code == ChatErrorCode.readOnly) {
        ref.invalidate(conversationsProvider);
      }
      _snack(chatErrorText(l10n, e.code));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _onLongPress(ChatMessage m, String? myId) async {
    final l10n = AppLocalizations.of(context)!;
    final mine = m.senderId != null && m.senderId == myId;
    if (mine && m.deleted) return;
    if (!mine && m.senderId == null) return;
    final action = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (mine)
              ListTile(
                key: const Key('deleteMessageAction'),
                leading: const Icon(Icons.delete_outline),
                title: Text(l10n.deleteMessage),
                onTap: () => Navigator.of(sheetContext).pop('delete'),
              )
            else
              ListTile(
                key: const Key('reportMessageAction'),
                leading: const Icon(Icons.flag_outlined),
                title: Text(l10n.reportAction),
                onTap: () => Navigator.of(sheetContext).pop('report'),
              ),
          ],
        ),
      ),
    );
    if (!mounted || action == null) return;
    if (action == 'delete') {
      if (!await confirmDeletion(
        context,
        title: l10n.deleteMessage,
        message: l10n.deleteMessageBody,
      )) {
        return;
      }
      try {
        await _service.deleteMessage(m.id);
      } on ChatException catch (e) {
        _snack(chatErrorText(l10n, e.code));
      }
    } else {
      final sent = await showReportSheet(
        context,
        userId: m.senderId!,
        displayName: m.senderDisplayName,
        messageId: m.id,
      );
      if (sent) _snack(l10n.reportSent);
    }
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    // Il canale cambia con l'account (anche appena se ne conosce lo stato).
    ref.listen(chatEventsProvider, (_, next) => _subscribe(next));
    final l10n = AppLocalizations.of(context)!;
    final myId = ref.watch(authStateProvider).valueOrNull?.id;
    final conversation =
        (ref.watch(conversationsProvider).valueOrNull ?? const <Conversation>[])
            .where((c) => c.id == widget.conversationId)
            .firstOrNull;
    final online = ref.watch(chatConnectionProvider).valueOrNull ?? true;
    final canSend = conversation?.canSend ?? true;
    final isGroup = conversation?.isGroup ?? false;

    return Scaffold(
      appBar: AppBar(
        title: conversation == null
            ? null
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversationTitle(l10n, conversation),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (isGroup)
                    Text(
                      l10n.groupMembersCount(conversation.memberCount),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: context.nipay.muted,
                      ),
                    ),
                ],
              ),
        actions: [
          if (isGroup)
            IconButton(
              key: const Key('groupInfoButton'),
              tooltip: l10n.groupInfo,
              icon: const Icon(Icons.info_outline),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      GroupInfoScreen(conversationId: widget.conversationId),
                ),
              ),
            )
          else if (conversation?.peerId case final peerId?)
            IconButton(
              key: const Key('reportPeerButton'),
              tooltip: l10n.reportAction,
              icon: const Icon(Icons.flag_outlined),
              onPressed: () async {
                final sent = await showReportSheet(
                  context,
                  userId: peerId,
                  displayName: conversation?.peerDisplayName,
                );
                if (sent) _snack(l10n.reportSent);
              },
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (!canSend)
              _Banner(icon: Icons.lock_outline, text: l10n.chatReadOnly)
            else if (!online)
              _Banner(icon: Icons.cloud_off_outlined, text: l10n.chatOffline),
            Expanded(child: _body(l10n, myId, isGroup)),
            _InputBar(
              controller: _input,
              enabled: canSend && online && !_sending,
              errorText: _inputError,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(AppLocalizations l10n, String? myId, bool isGroup) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_loadError case final code?) {
      return Center(
        child: EmptyState(
          icon: Icons.cloud_off_outlined,
          message: chatErrorText(l10n, code),
          action: OutlinedButton(onPressed: _load, child: Text(l10n.retry)),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.chat_bubble_outline,
          message: l10n.chatEmpty,
        ),
      );
    }
    return ListView.builder(
      key: const Key('chatMessages'),
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: _messages.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i == _messages.length) {
          return Center(
            child: TextButton(
              key: const Key('loadEarlierButton'),
              onPressed: _loadingMore ? null : _loadEarlier,
              child: Text(l10n.loadEarlierMessages),
            ),
          );
        }
        final m = _messages[i];
        return _Bubble(
          key: ValueKey('message_${m.id}'),
          message: m,
          mine: m.senderId != null && m.senderId == myId,
          showSender: isGroup,
          sender: senderName(l10n, m, myId),
          onLongPress: () => _onLongPress(m, myId),
        );
      },
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: scheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: context.nipay.muted),
            const SizedBox(width: 10),
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodySmall),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({
    super.key,
    required this.message,
    required this.mine,
    required this.showSender,
    required this.sender,
    required this.onLongPress,
  });

  final ChatMessage message;
  final bool mine;
  final bool showSender;
  final String sender;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final muted = context.nipay.muted;
    final body = message.deleted ? l10n.messageDeleted : (message.body ?? '');
    final time = formatTime(context, message.createdAt);
    return Align(
      alignment: mine
          ? AlignmentDirectional.centerEnd
          : AlignmentDirectional.centerStart,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Semantics(
          label: '$sender, $time: $body',
          excludeSemantics: true,
          child: GestureDetector(
            onLongPress: onLongPress,
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 3),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
              decoration: BoxDecoration(
                color: mine
                    ? scheme.primaryContainer
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (showSender && !mine)
                    Text(
                      sender,
                      style: text.labelMedium?.copyWith(color: scheme.primary),
                    ),
                  Text(
                    body,
                    style: message.deleted
                        ? text.bodyMedium?.copyWith(
                            fontStyle: FontStyle.italic,
                            color: muted,
                          )
                        : text.bodyMedium?.copyWith(
                            color: mine ? scheme.onPrimaryContainer : null,
                          ),
                  ),
                  const SizedBox(height: 2),
                  Text(time, style: text.labelSmall?.copyWith(color: muted)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.enabled,
    required this.errorText,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final String? errorText;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.nipay.line)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                key: const Key('chatInput'),
                controller: controller,
                enabled: enabled,
                minLines: 1,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: l10n.messageHint,
                  errorText: errorText,
                ),
              ),
            ),
            const SizedBox(width: 6),
            IconButton.filled(
              key: const Key('chatSendButton'),
              tooltip: l10n.sendMessage,
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
