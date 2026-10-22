import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../data/services/friends_service.dart';
import '../../l10n/app_localizations.dart';
import '../account/account_screen.dart';
import 'add_friend_screen.dart';
import 'display_name_dialog.dart';
import 'friends_ui.dart';
import 'my_qr_screen.dart';

/// Tab Amici (M-SOC2): richieste in arrivo/uscita, amici, bloccati, e le
/// due vie per aggiungersi (il mio QR, scansiona o inserisci un codice).
/// Senza account mostra solo l'invito ad accedere.
class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key, this.active = true});

  /// False quando un'altra tab è selezionata: la shell tiene montate tutte
  /// le tab (IndexedStack), quindi la schermata non può accorgersene da
  /// sola.
  final bool active;

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  bool _askedForName = false;

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  /// Esegue un'azione sul server e aggiorna le liste; errori tradotti.
  Future<void> _run(Future<void> Function(FriendsService s) action) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      await action(ref.read(friendsServiceProvider));
    } on FriendsException catch (e) {
      _showSnack(friendsErrorText(l10n, e.code));
    } finally {
      if (mounted) refreshFriends(ref);
    }
  }

  Future<bool> _confirm({
    required String title,
    required String body,
    required String action,
    bool destructive = false,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(AppLocalizations.of(dialogContext)!.cancel),
          ),
          FilledButton(
            key: const Key('friendsConfirmButton'),
            style: destructive ? destructiveButtonStyle(dialogContext) : null,
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(action),
          ),
        ],
      ),
    );
    return confirmed == true;
  }

  Future<void> _removeFriend(Friend friend) async {
    final l10n = AppLocalizations.of(context)!;
    final name = personName(l10n, friend.displayName);
    if (!await _confirm(
      title: l10n.removeFriend,
      body: l10n.removeFriendBody(name),
      action: l10n.removeFriend,
      destructive: true,
    )) {
      return;
    }
    await _run((s) => s.removeFriend(friend.userId));
  }

  Future<void> _block(String userId, String? displayName) async {
    final l10n = AppLocalizations.of(context)!;
    final name = personName(l10n, displayName);
    if (!await _confirm(
      title: l10n.blockUser,
      body: l10n.blockUserBody(name),
      action: l10n.blockUser,
      destructive: true,
    )) {
      return;
    }
    await _run((s) => s.block(userId));
  }

  /// La tab è davvero davanti all'utente: selezionata e senza un'altra
  /// schermata aperta sopra (Il mio QR, Account…).
  bool get _isVisible =>
      widget.active && (ModalRoute.of(context)?.isCurrent ?? true);

  /// Alla prima apertura con account, chiede il nome se non c'è ancora:
  /// è quello che vedranno gli amici. Aspetta che la tab sia visibile,
  /// altrimenti il dialog coprirebbe un'altra schermata.
  void _maybeAskForName(String? displayName) {
    if (_askedForName || displayName != null || !_isVisible) return;
    _askedForName = true;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (!_isVisible) {
        _askedForName = false; // ci si riprova al prossimo build visibile
        return;
      }
      final saved = await showDisplayNameDialog(context);
      if (saved != null) ref.invalidate(myProfileProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authStateProvider).valueOrNull;

    if (user == null) {
      return SafeArea(
        child: CenteredListView(
          children: [
            PageHeader(l10n.friendsTab),
            Card(
              child: EmptyState(
                icon: Icons.group_outlined,
                message: l10n.friendsSignInPrompt,
                action: FilledButton(
                  key: const Key('friendsSignInButton'),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AccountScreen()),
                  ),
                  child: Text(l10n.signIn),
                ),
              ),
            ),
          ],
        ),
      );
    }

    final profile = ref.watch(myProfileProvider);
    final profileValue = profile.valueOrNull;
    if (profile.hasValue && profileValue != null) {
      _maybeAskForName(profileValue.displayName);
    }
    final friends = ref.watch(friendsListProvider);
    final requests = ref.watch(friendRequestsProvider).valueOrNull ?? const [];
    final blocked = ref.watch(blockedUsersProvider).valueOrNull ?? const [];
    final incoming = [
      for (final r in requests)
        if (r.direction == FriendRequestDirection.incoming) r,
    ];
    final outgoing = [
      for (final r in requests)
        if (r.direction == FriendRequestDirection.outgoing) r,
    ];

    return SafeArea(
      child: RefreshIndicator(
        onRefresh: () async {
          refreshFriends(ref);
          await ref.read(friendsListProvider.future);
        },
        child: CenteredListView(
          children: [
            PageHeader(l10n.friendsTab),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    key: const Key('myQrButton'),
                    icon: const Icon(Icons.qr_code_2_rounded),
                    label: Text(l10n.myQrCode),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const MyQrScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    key: const Key('addFriendButton'),
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: Text(l10n.addFriend),
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddFriendScreen(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            if (incoming.isNotEmpty || outgoing.isNotEmpty) ...[
              SectionHeader(l10n.friendRequests),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, r) in [
                      ...incoming,
                      ...outgoing,
                    ].indexed) ...[
                      if (i > 0) const Divider(indent: 72),
                      _RequestTile(
                        request: r,
                        onAccept: () =>
                            _run((s) => s.respond(r.id, accept: true)),
                        onDecline: () =>
                            _run((s) => s.respond(r.id, accept: false)),
                        onCancel: () => _run((s) => s.cancel(r.id)),
                        onBlock: () => _block(r.userId, r.displayName),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            SectionHeader(l10n.friendsSection),
            Card(
              clipBehavior: Clip.antiAlias,
              // L'errore va controllato per primo: leggere `value` di un
              // AsyncValue in errore rilancia l'eccezione (e il build
              // esplode); `valueOrNull` invece restituisce null.
              child: switch (friends) {
                AsyncValue(hasError: true) => EmptyState(
                  icon: Icons.cloud_off_outlined,
                  message: l10n.friendsLoadFailed,
                  action: OutlinedButton(
                    onPressed: () => refreshFriends(ref),
                    child: Text(l10n.retry),
                  ),
                ),
                AsyncValue(:final valueOrNull?) when valueOrNull.isEmpty =>
                  EmptyState(
                    icon: Icons.group_add_outlined,
                    message: l10n.noFriendsYet,
                  ),
                AsyncValue(:final valueOrNull?) => Column(
                  children: [
                    for (final (i, f) in valueOrNull.indexed) ...[
                      if (i > 0) const Divider(indent: 72),
                      ListTile(
                        key: ValueKey('friend_${f.userId}'),
                        leading: InitialsAvatar(name: f.displayName),
                        title: Text(personName(l10n, f.displayName)),
                        trailing: PopupMenuButton<String>(
                          key: ValueKey('friendMenu_${f.userId}'),
                          tooltip: MaterialLocalizations.of(
                            context,
                          ).showMenuTooltip,
                          onSelected: (v) => v == 'remove'
                              ? _removeFriend(f)
                              : _block(f.userId, f.displayName),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'remove',
                              child: Text(l10n.removeFriend),
                            ),
                            PopupMenuItem(
                              value: 'block',
                              child: Text(l10n.blockUser),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
                _ => const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator()),
                ),
              },
            ),
            if (blocked.isNotEmpty) ...[
              SectionHeader(l10n.blockedSection),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    for (final (i, b) in blocked.indexed) ...[
                      if (i > 0) const Divider(indent: 72),
                      ListTile(
                        leading: InitialsAvatar(name: b.displayName),
                        title: Text(personName(l10n, b.displayName)),
                        trailing: TextButton(
                          key: ValueKey('unblock_${b.userId}'),
                          onPressed: () => _run((s) => s.unblock(b.userId)),
                          child: Text(l10n.unblockUser),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Una richiesta: in arrivo (accetta / rifiuta / blocca) o in uscita
/// (in attesa → annulla; rifiutata → solo lo stato).
class _RequestTile extends StatelessWidget {
  const _RequestTile({
    required this.request,
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
    required this.onBlock,
  });

  final FriendRequest request;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onCancel;
  final VoidCallback onBlock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final muted = context.nipay.muted;
    final name = personName(l10n, request.displayName);
    final incoming = request.direction == FriendRequestDirection.incoming;
    final declined = request.status == FriendRequestStatus.declined;
    return Padding(
      key: ValueKey('request_${request.id}'),
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              InitialsAvatar(name: request.displayName),
              const SizedBox(width: 16),
              Expanded(
                child: MergeSemantics(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        incoming
                            ? l10n.incomingRequestSubtitle
                            : declined
                            ? l10n.outgoingDeclined
                            : l10n.outgoingPending,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(color: muted),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (incoming || !declined)
            Padding(
              padding: const EdgeInsetsDirectional.only(start: 56, top: 6),
              child: Wrap(
                spacing: 8,
                runSpacing: 4,
                children: incoming
                    ? [
                        FilledButton(
                          key: ValueKey('accept_${request.id}'),
                          onPressed: onAccept,
                          child: Text(l10n.acceptRequest),
                        ),
                        OutlinedButton(
                          key: ValueKey('decline_${request.id}'),
                          onPressed: onDecline,
                          child: Text(l10n.declineRequest),
                        ),
                        TextButton(
                          key: ValueKey('blockRequest_${request.id}'),
                          onPressed: onBlock,
                          child: Text(l10n.blockUser),
                        ),
                      ]
                    : [
                        TextButton(
                          key: ValueKey('cancel_${request.id}'),
                          onPressed: onCancel,
                          child: Text(l10n.cancelRequest),
                        ),
                      ],
              ),
            ),
        ],
      ),
    );
  }
}
