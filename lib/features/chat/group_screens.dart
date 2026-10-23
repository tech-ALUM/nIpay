import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/friends_service.dart';
import '../../l10n/app_localizations.dart';
import '../friends/friends_ui.dart';
import 'chat_screen.dart';
import 'chat_ui.dart';

/// Amici da spuntare (nuovo gruppo, aggiungi membri). [excluded] = già
/// nel gruppo.
class _FriendChecklist extends StatelessWidget {
  const _FriendChecklist({
    required this.friends,
    required this.selected,
    required this.onChanged,
    this.excluded = const {},
  });

  final List<Friend> friends;
  final Set<String> selected;
  final Set<String> excluded;
  final void Function(String userId, bool selected) onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final available = [
      for (final f in friends)
        if (!excluded.contains(f.userId)) f,
    ];
    if (available.isEmpty) {
      return EmptyState(
        icon: Icons.group_outlined,
        message: excluded.isEmpty ? l10n.noFriendsYet : l10n.noFriendsToAdd,
      );
    }
    return Column(
      children: [
        for (final f in available)
          CheckboxListTile(
            key: ValueKey('pickFriend_${f.userId}'),
            value: selected.contains(f.userId),
            contentPadding: EdgeInsets.zero,
            secondary: InitialsAvatar(name: f.displayName),
            title: Text(personName(l10n, f.displayName)),
            onChanged: (v) => onChanged(f.userId, v ?? false),
          ),
      ],
    );
  }
}

/// Nuovo gruppo: nome e amici. Creato, si apre la chat al suo posto.
class NewGroupScreen extends ConsumerStatefulWidget {
  const NewGroupScreen({super.key});

  @override
  ConsumerState<NewGroupScreen> createState() => _NewGroupScreenState();
}

class _NewGroupScreenState extends ConsumerState<NewGroupScreen> {
  final _title = TextEditingController();
  final _selected = <String>{};
  String? _titleError;
  String? _membersError;
  bool _creating = false;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final l10n = AppLocalizations.of(context)!;
    final title = _title.text.trim();
    setState(() {
      _titleError = title.isEmpty || title.length > kMaxGroupTitleLength
          ? l10n.groupNameInvalid
          : null;
      _membersError = _selected.isEmpty ? l10n.groupNeedsMembers : null;
    });
    if (_titleError != null || _membersError != null) return;
    if (_selected.length + 1 > kMaxGroupMembers) {
      setState(() => _membersError = l10n.chatErrorTooManyMembers);
      return;
    }
    setState(() => _creating = true);
    try {
      final id = await ref
          .read(chatServiceProvider)
          .createGroup(title, _selected.toList());
      if (!mounted) return;
      ref.invalidate(conversationsProvider);
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => ChatScreen(conversationId: id)),
      );
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(chatErrorText(l10n, e.code))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final friends = ref.watch(friendsListProvider).valueOrNull ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.newGroup)),
      body: SafeArea(
        child: CenteredListView(
          children: [
            TextField(
              key: const Key('groupTitleField'),
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              maxLength: kMaxGroupTitleLength,
              decoration: InputDecoration(
                labelText: l10n.groupName,
                errorText: _titleError,
              ),
            ),
            SectionHeader(l10n.chooseFriends),
            if (_membersError != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _membersError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _FriendChecklist(
                  friends: friends,
                  selected: _selected,
                  onChanged: (id, v) => setState(() {
                    v ? _selected.add(id) : _selected.remove(id);
                    _membersError = null;
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('createGroupButton'),
              onPressed: _creating ? null : _create,
              child: Text(l10n.createGroup),
            ),
          ],
        ),
      ),
    );
  }
}

/// Membri del gruppo. Gli admin aggiungono e tolgono; chiunque può uscire.
class GroupInfoScreen extends ConsumerStatefulWidget {
  const GroupInfoScreen({super.key, required this.conversationId});

  final String conversationId;

  @override
  ConsumerState<GroupInfoScreen> createState() => _GroupInfoScreenState();
}

class _GroupInfoScreenState extends ConsumerState<GroupInfoScreen> {
  List<ConversationMember>? _members;
  ChatErrorCode? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final members = await ref
          .read(chatServiceProvider)
          .listMembers(widget.conversationId);
      if (mounted) setState(() => _members = members);
    } on ChatException catch (e) {
      if (mounted) setState(() => _error = e.code);
    }
  }

  Future<void> _run(Future<void> Function(ChatService s) action) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await action(ref.read(chatServiceProvider));
      ref.invalidate(conversationsProvider);
      await _load();
    } on ChatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(chatErrorText(l10n, e.code))));
    }
  }

  Future<void> _remove(ConversationMember m) async {
    final l10n = AppLocalizations.of(context)!;
    if (!await confirmDeletion(
      context,
      title: l10n.removeFromGroup,
      message: l10n.removeFromGroupBody(personName(l10n, m.displayName)),
    )) {
      return;
    }
    await _run((s) => s.removeMember(widget.conversationId, m.userId));
  }

  Future<void> _leave() async {
    final l10n = AppLocalizations.of(context)!;
    if (!await confirmDeletion(
      context,
      title: l10n.leaveGroup,
      message: l10n.leaveGroupBody,
    )) {
      return;
    }
    try {
      await ref.read(chatServiceProvider).leaveGroup(widget.conversationId);
      ref.invalidate(conversationsProvider);
      if (!mounted) return;
      // Fuori dal gruppo anche la chat non ha più senso: si torna alla tab.
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on ChatException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(chatErrorText(l10n, e.code))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final myId = ref.watch(authStateProvider).valueOrNull?.id;
    final members = _members;
    final amAdmin =
        members?.any((m) => m.userId == myId && m.role == MemberRole.admin) ??
        false;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.groupInfo)),
      body: SafeArea(
        child: switch ((members, _error)) {
          (_, final code?) => Center(
            child: EmptyState(
              icon: Icons.cloud_off_outlined,
              message: chatErrorText(l10n, code),
            ),
          ),
          (null, _) => const Center(child: CircularProgressIndicator()),
          (final list?, _) => CenteredListView(
            children: [
              SectionHeader(
                l10n.groupMembersCount(list.length),
                action: amAdmin && list.length < kMaxGroupMembers
                    ? TextButton.icon(
                        key: const Key('addMembersButton'),
                        icon: const Icon(Icons.person_add_alt_1_outlined),
                        label: Text(l10n.addMembers),
                        onPressed: () async {
                          final added = await Navigator.of(context).push<bool>(
                            MaterialPageRoute(
                              builder: (_) => _AddMembersScreen(
                                conversationId: widget.conversationId,
                                existing: {for (final m in list) m.userId},
                              ),
                            ),
                          );
                          if (added == true) await _load();
                        },
                      )
                    : null,
              ),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, m) in list.indexed) ...[
                      if (i > 0) const Divider(indent: 72),
                      ListTile(
                        key: ValueKey('member_${m.userId}'),
                        leading: InitialsAvatar(name: m.displayName),
                        title: Text(
                          m.userId == myId
                              ? l10n.youLabel
                              : personName(l10n, m.displayName),
                        ),
                        subtitle: m.role == MemberRole.admin
                            ? Text(
                                l10n.groupAdmin,
                                style: TextStyle(color: context.nipay.muted),
                              )
                            : null,
                        trailing: amAdmin && m.userId != myId
                            ? IconButton(
                                key: ValueKey('removeMember_${m.userId}'),
                                tooltip: l10n.removeFromGroup,
                                icon: const Icon(
                                  Icons.person_remove_alt_1_outlined,
                                ),
                                onPressed: () => _remove(m),
                              )
                            : null,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                key: const Key('leaveGroupButton'),
                style: destructiveButtonStyle(context),
                onPressed: _leave,
                child: Text(l10n.leaveGroup),
              ),
            ],
          ),
        },
      ),
    );
  }
}

class _AddMembersScreen extends ConsumerStatefulWidget {
  const _AddMembersScreen({
    required this.conversationId,
    required this.existing,
  });

  final String conversationId;
  final Set<String> existing;

  @override
  ConsumerState<_AddMembersScreen> createState() => _AddMembersScreenState();
}

class _AddMembersScreenState extends ConsumerState<_AddMembersScreen> {
  final _selected = <String>{};
  bool _saving = false;

  Future<void> _add() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selected.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.groupNeedsMembers)));
      return;
    }
    if (widget.existing.length + _selected.length > kMaxGroupMembers) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.chatErrorTooManyMembers)));
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(chatServiceProvider)
          .addMembers(widget.conversationId, _selected.toList());
      ref.invalidate(conversationsProvider);
      if (mounted) Navigator.of(context).pop(true);
    } on ChatException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(chatErrorText(l10n, e.code))));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final friends = ref.watch(friendsListProvider).valueOrNull ?? const [];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.addMembers)),
      body: SafeArea(
        child: CenteredListView(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _FriendChecklist(
                  friends: friends,
                  selected: _selected,
                  excluded: widget.existing,
                  onChanged: (id, v) => setState(
                    () => v ? _selected.add(id) : _selected.remove(id),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              key: const Key('confirmAddMembersButton'),
              onPressed: _saving ? null : _add,
              child: Text(l10n.addMembers),
            ),
          ],
        ),
      ),
    );
  }
}
