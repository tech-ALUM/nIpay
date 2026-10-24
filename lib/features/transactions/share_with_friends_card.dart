import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/split_accounting.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../data/services/friends_service.dart';
import '../../data/services/shared_expense_service.dart';
import '../../l10n/app_localizations.dart';
import '../friends/friends_ui.dart';

/// Bozza della condivisione di una spesa (M-SOC4): con chi, chi ha pagato
/// (null = io) e, se [custom], gli importi scritti per persona.
@immutable
class ShareDraft {
  const ShareDraft({
    this.friendIds = const [],
    this.payerId,
    this.custom = false,
    this.customCents = const {},
  });

  final List<String> friendIds;
  final String? payerId;
  final bool custom;

  /// Per persona (anche la mia, con il mio id); null = non ancora scritto.
  final Map<String, int?> customCents;

  bool get isActive => friendIds.isNotEmpty;

  ShareDraft copyWith({
    List<String>? friendIds,
    ValueGetter<String?>? payerId,
    bool? custom,
    Map<String, int?>? customCents,
  }) => ShareDraft(
    friendIds: friendIds ?? this.friendIds,
    payerId: payerId == null ? this.payerId : payerId(),
    custom: custom ?? this.custom,
    customCents: customCents ?? this.customCents,
  );

  /// Io per primo, poi gli amici nell'ordine scelto.
  List<String> participants(String myId) => [myId, ...friendIds];

  /// Le quote, o perché non si può salvare.
  ({List<int>? shares, SplitError? error}) resolve(String myId, int total) =>
      resolveShares(
        totalCents: total,
        participants: participants(myId),
        custom: custom ? customCents : null,
      );
}

/// Testo per l'utente di un errore delle spese divise (mai il testo del
/// server).
String sharedExpenseErrorText(
  AppLocalizations l10n,
  SharedExpenseErrorCode code,
) => switch (code) {
  SharedExpenseErrorCode.invalidExpense ||
  SharedExpenseErrorCode.invalidShares ||
  SharedExpenseErrorCode.noParticipants ||
  SharedExpenseErrorCode.tooManyParticipants ||
  SharedExpenseErrorCode.invalidPayer => l10n.shareErrorInvalid,
  SharedExpenseErrorCode.notAvailable => l10n.friendsErrorNotAvailable,
  SharedExpenseErrorCode.rateLimited => l10n.authErrorRateLimited,
  SharedExpenseErrorCode.pendingDeletion => l10n.accountPendingDeletionError,
  SharedExpenseErrorCode.network => l10n.authErrorNetwork,
  SharedExpenseErrorCode.locked => l10n.splitLocked,
  SharedExpenseErrorCode.notFound => l10n.splitNotFound,
  SharedExpenseErrorCode.amountTooHigh => l10n.settleTooMuch,
  SharedExpenseErrorCode.invalidAmount => l10n.invalidAmount,
  SharedExpenseErrorCode.unknown => l10n.authErrorGeneric,
};

String splitErrorText(AppLocalizations l10n, SplitError error) =>
    switch (error) {
      SplitError.tooSmall => l10n.shareTooSmall,
      SplitError.mismatch => l10n.shareSplitMismatch,
    };

/// Card "Condividi con amici" del foglio transazione (solo nuove spese, con
/// account e almeno un amico). Senza connessione lo dice al posto dei
/// controlli: la spesa si salva comunque come spesa normale.
class ShareWithFriendsCard extends ConsumerStatefulWidget {
  const ShareWithFriendsCard({
    super.key,
    required this.draft,
    required this.onChanged,
    required this.myId,
    required this.friends,
    required this.totalCents,
    required this.currency,
    this.errorText,
  });

  final ShareDraft draft;
  final ValueChanged<ShareDraft> onChanged;
  final String myId;
  final List<Friend> friends;

  /// Totale nella valuta digitata; null se l'importo non è ancora valido.
  final int? totalCents;
  final String currency;
  final String? errorText;

  @override
  ConsumerState<ShareWithFriendsCard> createState() =>
      _ShareWithFriendsCardState();
}

class _ShareWithFriendsCardState extends ConsumerState<ShareWithFriendsCard> {
  final _amounts = <String, TextEditingController>{};

  @override
  void dispose() {
    for (final c in _amounts.values) {
      c.dispose();
    }
    super.dispose();
  }

  ShareDraft get _draft => widget.draft;

  String _name(AppLocalizations l10n, String userId) {
    if (userId == widget.myId) return l10n.youLabel;
    final friend = widget.friends.where((f) => f.userId == userId).firstOrNull;
    return personName(l10n, friend?.displayName);
  }

  String _money(int cents) => formatCents(cents, currency: widget.currency);

  Future<void> _pickFriends() async {
    final l10n = AppLocalizations.of(context)!;
    final picked = await showAppSheet<List<String>>(
      context,
      builder: (_) => _FriendPicker(
        friends: widget.friends,
        initial: _draft.friendIds.toSet(),
        title: l10n.chooseFriends,
        confirm: l10n.apply,
      ),
    );
    if (picked == null) return;
    final payer = _draft.payerId;
    widget.onChanged(
      _draft.copyWith(
        friendIds: picked,
        // Chi ha pagato deve restare tra i partecipanti.
        payerId: () => payer != null && picked.contains(payer) ? payer : null,
        customCents: {
          for (final e in _draft.customCents.entries)
            if (e.key == widget.myId || picked.contains(e.key)) e.key: e.value,
        },
      ),
    );
  }

  void _remove(String userId) {
    final friends = [..._draft.friendIds]..remove(userId);
    widget.onChanged(
      _draft.copyWith(
        friendIds: friends,
        payerId: () => _draft.payerId == userId ? null : _draft.payerId,
        customCents: {..._draft.customCents}..remove(userId),
      ),
    );
  }

  TextEditingController _amountFor(String userId) =>
      _amounts.putIfAbsent(userId, () {
        final cents = _draft.customCents[userId];
        return TextEditingController(
          // Come il campo importo in modifica: "12,50".
          text: cents == null
              ? ''
              : (cents / 100).toStringAsFixed(2).replaceAll('.', ','),
        );
      });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final scheme = Theme.of(context).colorScheme;
    final online = ref.watch(chatConnectionProvider).valueOrNull ?? true;
    final participants = _draft.participants(widget.myId);
    final total = widget.totalCents;
    final resolved = total == null ? null : _draft.resolve(widget.myId, total);

    return Material(
      key: const Key('shareWithFriendsCard'),
      color: _draft.isActive ? palette.surface2 : scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: palette.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.group_outlined, color: palette.muted),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.shareWithFriends,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (online)
                  TextButton.icon(
                    key: const Key('shareAddFriendsButton'),
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: Text(l10n.shareAddFriends),
                    onPressed: _pickFriends,
                  ),
              ],
            ),
            if (!online)
              Padding(
                padding: const EdgeInsets.fromLTRB(40, 4, 8, 4),
                child: Text(
                  l10n.shareNeedsConnection,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: palette.muted),
                ),
              )
            else if (_draft.isActive) ...[
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final id in _draft.friendIds)
                      InputChip(
                        key: ValueKey('shareFriend_$id'),
                        avatar: InitialsAvatar(
                          name: widget.friends
                              .where((f) => f.userId == id)
                              .firstOrNull
                              ?.displayName,
                          radius: 12,
                        ),
                        label: Text(_name(l10n, id)),
                        onDeleted: () => _remove(id),
                        deleteButtonTooltipMessage: MaterialLocalizations.of(
                          context,
                        ).deleteButtonTooltip,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              FieldLabel(l10n.shareWhoPaid),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final id in participants)
                    ChoiceChip(
                      key: ValueKey('sharePayer_$id'),
                      label: Text(
                        id == widget.myId
                            ? l10n.sharePaidByMe
                            : _name(l10n, id),
                      ),
                      selected: (_draft.payerId ?? widget.myId) == id,
                      onSelected: (_) => widget.onChanged(
                        _draft.copyWith(
                          payerId: () => id == widget.myId ? null : id,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              SegmentedButton<bool>(
                key: const Key('shareSplitMode'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.shareSplitEqually),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.shareSplitCustom),
                  ),
                ],
                selected: {_draft.custom},
                onSelectionChanged: (s) =>
                    widget.onChanged(_draft.copyWith(custom: s.first)),
              ),
              if (_draft.custom) ...[
                const SizedBox(height: 8),
                for (final id in participants)
                  Padding(
                    padding: const EdgeInsets.only(top: 6, right: 8),
                    child: Row(
                      children: [
                        Expanded(child: Text(_name(l10n, id))),
                        SizedBox(
                          width: 140,
                          child: TextField(
                            key: ValueKey('shareAmount_$id'),
                            controller: _amountFor(id),
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: moneyInputFormatters,
                            textAlign: TextAlign.end,
                            style: moneyStyle(size: 16),
                            decoration: InputDecoration(
                              isDense: true,
                              suffixText: widget.currency,
                            ),
                            onChanged: (text) => widget.onChanged(
                              _draft.copyWith(
                                customCents: {
                                  ..._draft.customCents,
                                  id: parseCents(text),
                                },
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (total != null) ...[
                  const SizedBox(height: 8),
                  _SplitBalance(
                    total: total,
                    assigned: participants.fold(
                      0,
                      (sum, id) => sum + (_draft.customCents[id] ?? 0),
                    ),
                    money: _money,
                  ),
                ],
              ],
              if (resolved?.shares case final shares?) ...[
                const SizedBox(height: 12),
                ..._preview(l10n, participants, shares),
              ],
              if (widget.errorText case final error?)
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 8),
                  child: Text(error, style: TextStyle(color: scheme.error)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  /// "Bea ti deve 20 €" (ho pagato io) o "Devi 15 € a Luca", più la mia quota.
  List<Widget> _preview(
    AppLocalizations l10n,
    List<String> participants,
    List<int> shares,
  ) {
    final payer = _draft.payerId ?? widget.myId;
    final myShare = shares[participants.indexOf(widget.myId)];
    final lines = <String>[
      if (payer == widget.myId)
        for (var i = 0; i < participants.length; i++)
          if (participants[i] != widget.myId)
            l10n.shareOwesYou(_name(l10n, participants[i]), _money(shares[i]))
          else
            ...const []
      else
        l10n.shareYouOwe(_name(l10n, payer), _money(myShare)),
      l10n.shareYourShare(_money(myShare)),
    ];
    return [
      for (final line in lines)
        Padding(
          padding: const EdgeInsets.only(top: 2, right: 8),
          child: Text(line, style: Theme.of(context).textTheme.bodyMedium),
        ),
    ];
  }
}

/// Quanto manca o avanza rispetto al totale, con gli importi per persona.
class _SplitBalance extends StatelessWidget {
  const _SplitBalance({
    required this.total,
    required this.assigned,
    required this.money,
  });

  final int total;
  final int assigned;
  final String Function(int cents) money;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final diff = total - assigned;
    if (diff == 0) return const SizedBox.shrink();
    return Text(
      diff > 0
          ? l10n.shareRemaining(money(diff))
          : l10n.shareExcess(money(-diff)),
      key: const Key('shareSplitBalance'),
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.error,
      ),
    );
  }
}

class _FriendPicker extends StatefulWidget {
  const _FriendPicker({
    required this.friends,
    required this.initial,
    required this.title,
    required this.confirm,
  });

  final List<Friend> friends;
  final Set<String> initial;
  final String title;
  final String confirm;

  @override
  State<_FriendPicker> createState() => _FriendPickerState();
}

class _FriendPickerState extends State<_FriendPicker> {
  late final _selected = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SheetScaffold(
      title: widget.title,
      actions: [
        FilledButton(
          key: const Key('shareFriendsConfirm'),
          onPressed: () => Navigator.of(context).pop([
            // L'ordine della lista amici, non quello dei tocchi.
            for (final f in widget.friends)
              if (_selected.contains(f.userId)) f.userId,
          ]),
          child: Text(widget.confirm),
        ),
      ],
      children: [
        for (final f in widget.friends)
          CheckboxListTile(
            key: ValueKey('sharePick_${f.userId}'),
            value: _selected.contains(f.userId),
            contentPadding: EdgeInsets.zero,
            secondary: InitialsAvatar(name: f.displayName),
            title: Text(personName(l10n, f.displayName)),
            onChanged: (v) => setState(
              () => v == true
                  ? _selected.add(f.userId)
                  : _selected.remove(f.userId),
            ),
          ),
      ],
    );
  }
}
