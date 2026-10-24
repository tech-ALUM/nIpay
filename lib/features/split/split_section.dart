import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../data/services/shared_expense_service.dart';
import '../../l10n/app_localizations.dart';
import '../friends/friends_ui.dart';
import '../transactions/share_with_friends_card.dart';
import 'edit_shared_expense_sheet.dart';
import 'register_sheet.dart';

/// Spese divise nella tab Amici (M-SOC4): cose da fare (quote e rimborsi
/// da registrare, rimborsi da confermare), saldi per persona e valuta con
/// Salda, spese recenti. Sparisce se non c'è nulla.
class SplitSection extends ConsumerWidget {
  const SplitSection({super.key});

  static const _recentCount = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final myId = ref.watch(authStateProvider).valueOrNull?.id;
    final expenses = ref.watch(sharedExpensesProvider).valueOrNull ?? const [];
    final balances = ref.watch(friendBalancesProvider).valueOrNull ?? const [];
    final settlements = ref.watch(settlementsProvider).valueOrNull ?? const [];
    if (myId == null ||
        (expenses.isEmpty && balances.isEmpty && settlements.isEmpty)) {
      return const SizedBox.shrink();
    }

    final todo = <Widget>[
      for (final e in expenses)
        if (!e.myShareRegistered)
          _TodoTile(
            key: ValueKey('todoShare_${e.id}'),
            icon: Icons.receipt_long_outlined,
            text: l10n.registerShareItem(
              e.description ?? l10n.sharedExpenseFallbackTitle,
              formatCents(e.myShareCents, currency: e.currency),
            ),
            actions: [
              _ActionButton(
                key: ValueKey('registerShare_${e.id}'),
                label: l10n.registerAction,
                onPressed: () => _register(context, ref, ShareTarget(e)),
              ),
            ],
          ),
      for (final s in settlements) ?_settlementTile(context, ref, l10n, s),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(l10n.splitSection),
        if (todo.isNotEmpty) ...[
          _CardList(title: l10n.splitTodo, children: todo),
          const SizedBox(height: 12),
        ],
        if (balances.isNotEmpty) ...[
          _CardList(
            title: l10n.splitBalances,
            children: [
              for (final b in balances)
                _BalanceTile(
                  key: ValueKey('balance_${b.userId}_${b.currency}'),
                  balance: b,
                  onSettle: b.balanceCents < 0 && b.userId != null
                      ? () => _settle(context, ref, b)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        if (expenses.isNotEmpty)
          _CardList(
            title: l10n.splitRecent,
            children: [
              for (final e in expenses.take(_recentCount))
                ListTile(
                  key: ValueKey('sharedExpense_${e.id}'),
                  title: Text(e.description ?? l10n.sharedExpenseFallbackTitle),
                  subtitle: Text(
                    e.paidBy == myId
                        ? l10n.sharedExpensePaidByYou(
                            formatCents(e.myShareCents, currency: e.currency),
                          )
                        : l10n.sharedExpensePaidBy(
                            e.paidBy == null
                                ? l10n.deletedUser
                                : personName(l10n, e.payerDisplayName),
                            formatCents(e.myShareCents, currency: e.currency),
                          ),
                  ),
                  trailing: Text(
                    formatCents(e.totalCents, currency: e.currency),
                    style: moneyStyle(size: 15),
                  ),
                  onTap: () => showSharedExpenseSheet(context, e),
                ),
            ],
          ),
      ],
    );
  }

  /// Riga "da fare" per un rimborso, o null se non c'è nulla da fare.
  Widget? _settlementTile(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
    Settlement s,
  ) {
    final name = s.userId == null
        ? l10n.deletedUser
        : personName(l10n, s.displayName);
    final amount = formatCents(s.amountCents, currency: s.currency);
    final incoming = s.direction == SettlementDirection.incoming;
    return switch (s.status) {
      SettlementStatus.pending when incoming => _TodoTile(
        key: ValueKey('settlement_${s.id}'),
        icon: Icons.payments_outlined,
        text: l10n.settleIncoming(name, amount),
        actions: [
          _ActionButton(
            key: ValueKey('settlementReceived_${s.id}'),
            label: l10n.settleReceived,
            onPressed: () => _respond(context, ref, s, accept: true),
          ),
          _ActionButton(
            key: ValueKey('settlementNotReceived_${s.id}'),
            label: l10n.settleNotReceived,
            outlined: true,
            onPressed: () => _respond(context, ref, s, accept: false),
          ),
        ],
      ),
      SettlementStatus.pending => _TodoTile(
        key: ValueKey('settlement_${s.id}'),
        icon: Icons.hourglass_empty_rounded,
        text: l10n.settleWaiting(name, amount),
        actions: [
          _ActionButton(
            key: ValueKey('settlementCancel_${s.id}'),
            label: l10n.cancel,
            outlined: true,
            onPressed: () =>
                _run(context, ref, (service) => service.cancelSettlement(s.id)),
          ),
        ],
      ),
      SettlementStatus.confirmed when !s.myRegistered => _TodoTile(
        key: ValueKey('settlement_${s.id}'),
        icon: Icons.payments_outlined,
        text: incoming
            ? l10n.registerSettlementIn(name, amount)
            : l10n.registerSettlementOut(name, amount),
        actions: [
          _ActionButton(
            key: ValueKey('registerSettlement_${s.id}'),
            label: l10n.registerAction,
            onPressed: () => _register(context, ref, SettlementTarget(s)),
          ),
        ],
      ),
      SettlementStatus.declined when !incoming => _TodoTile(
        key: ValueKey('settlement_${s.id}'),
        icon: Icons.info_outline,
        text: l10n.settleDeclined(name, amount),
        actions: const [],
      ),
      _ => null,
    };
  }

  static Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function(SharedExpenseService service) action,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      await action(ref.read(sharedExpenseServiceProvider));
    } on SharedExpenseException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(sharedExpenseErrorText(l10n, e.code))),
      );
    } finally {
      refreshSplits(ref);
    }
  }

  static Future<void> _register(
    BuildContext context,
    WidgetRef ref,
    RegisterTarget target,
  ) async {
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    if (await showRegisterSheet(context, target)) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.registerDone)));
    }
  }

  /// "Ricevuto": conferma e propone subito dove registrare l'entrata.
  /// "Non ricevuto": chiede conferma, è definitivo.
  static Future<void> _respond(
    BuildContext context,
    WidgetRef ref,
    Settlement s, {
    required bool accept,
  }) async {
    final l10n = AppLocalizations.of(context)!;
    if (!accept) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: Text(l10n.settleNotReceived),
          content: Text(
            l10n.settleIncoming(
              personName(l10n, s.displayName),
              formatCents(s.amountCents, currency: s.currency),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const Key('settlementDeclineConfirm'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.settleNotReceived),
            ),
          ],
        ),
      );
      if (sure != true || !context.mounted) return;
    }
    var ok = true;
    await _run(context, ref, (service) async {
      try {
        await service.respondSettlement(s.id, accept: accept);
      } on SharedExpenseException {
        ok = false;
        rethrow;
      }
    });
    if (!accept || !ok || !context.mounted) return;
    await _register(
      context,
      ref,
      SettlementTarget(
        Settlement(
          id: s.id,
          direction: s.direction,
          userId: s.userId,
          displayName: s.displayName,
          amountCents: s.amountCents,
          currency: s.currency,
          status: SettlementStatus.confirmed,
          createdAt: s.createdAt,
          myRegistered: false,
        ),
      ),
    );
  }

  static Future<void> _settle(
    BuildContext context,
    WidgetRef ref,
    FriendBalance balance,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final sent = await showAppSheet<bool>(
      context,
      builder: (_) => _SettleSheet(balance: balance),
    );
    if (sent == true) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            l10n.settleRecorded(personName(l10n, balance.displayName)),
          ),
        ),
      );
    }
  }
}

class _CardList extends StatelessWidget {
  const _CardList({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: context.nipay.muted),
          ),
        ),
        for (final (i, child) in children.indexed) ...[
          if (i > 0) const Divider(indent: 16, endIndent: 16),
          child,
        ],
      ],
    ),
  );
}

class _TodoTile extends StatelessWidget {
  const _TodoTile({
    super.key,
    required this.icon,
    required this.text,
    required this.actions,
  });

  final IconData icon;
  final String text;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: context.nipay.muted),
            const SizedBox(width: 12),
            Expanded(child: Text(text)),
          ],
        ),
        if (actions.isNotEmpty)
          Padding(
            padding: const EdgeInsetsDirectional.only(start: 32, top: 6),
            child: Wrap(spacing: 8, runSpacing: 4, children: actions),
          ),
      ],
    ),
  );
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.outlined = false,
  });

  final String label;
  final VoidCallback onPressed;
  final bool outlined;

  @override
  Widget build(BuildContext context) => outlined
      ? OutlinedButton(onPressed: onPressed, child: Text(label))
      : FilledButton(onPressed: onPressed, child: Text(label));
}

class _BalanceTile extends StatelessWidget {
  const _BalanceTile({super.key, required this.balance, this.onSettle});

  final FriendBalance balance;
  final VoidCallback? onSettle;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final b = balance;
    final owesMe = b.balanceCents > 0;
    final amount = formatCents(b.balanceCents.abs(), currency: b.currency);
    return ListTile(
      leading: InitialsAvatar(name: b.userId == null ? null : b.displayName),
      title: Text(
        b.userId == null ? l10n.deletedUser : personName(l10n, b.displayName),
      ),
      subtitle: Text(
        owesMe ? l10n.balanceOwesYou(amount) : l10n.balanceYouOwe(amount),
        style: TextStyle(color: owesMe ? palette.income : palette.expense),
      ),
      trailing: onSettle == null
          ? null
          : TextButton(
              key: ValueKey('settle_${b.userId}_${b.currency}'),
              onPressed: onSettle,
              child: Text(l10n.settleAction),
            ),
    );
  }
}

/// "Salda": quanto rimborsare (proposto tutto il debito, al massimo quello).
class _SettleSheet extends ConsumerStatefulWidget {
  const _SettleSheet({required this.balance});

  final FriendBalance balance;

  @override
  ConsumerState<_SettleSheet> createState() => _SettleSheetState();
}

class _SettleSheetState extends ConsumerState<_SettleSheet> {
  late final _amount = TextEditingController(
    text: (widget.balance.balanceCents.abs() / 100)
        .toStringAsFixed(2)
        .replaceAll('.', ','),
  );
  String? _error;
  bool _sending = false;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final l10n = AppLocalizations.of(context)!;
    final b = widget.balance;
    final owed = b.balanceCents.abs();
    final cents = parseCents(_amount.text);
    if (cents == null || cents <= 0) {
      setState(() => _error = l10n.invalidAmount);
      return;
    }
    if (cents > owed) {
      setState(
        () => _error = l10n.settleAmountMax(
          formatCents(owed, currency: b.currency),
        ),
      );
      return;
    }
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      await ref
          .read(sharedExpenseServiceProvider)
          .recordSettlement(
            toUser: b.userId!,
            amountCents: cents,
            currency: b.currency,
          );
      refreshSplits(ref);
      if (mounted) Navigator.of(context).pop(true);
    } on SharedExpenseException catch (e) {
      if (!mounted) return;
      setState(() {
        _sending = false;
        _error = sharedExpenseErrorText(l10n, e.code);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final b = widget.balance;
    return SheetScaffold(
      title: l10n.settleTitle(personName(l10n, b.displayName)),
      actions: [
        FilledButton(
          key: const Key('settleSendButton'),
          onPressed: _sending ? null : _send,
          child: Text(l10n.settleAction),
        ),
      ],
      children: [
        TextField(
          key: const Key('settleAmountField'),
          controller: _amount,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: moneyInputFormatters,
          style: moneyStyle(size: 28),
          decoration: InputDecoration(
            labelText: l10n.amount,
            suffixText: b.currency,
            errorText: _error,
            helperText: l10n.balanceYouOwe(
              formatCents(b.balanceCents.abs(), currency: b.currency),
            ),
          ),
        ),
      ],
    );
  }
}

/// Dettaglio di una spesa divisa: totale, chi ha pagato, le quote.
Future<void> showSharedExpenseSheet(
  BuildContext context,
  SharedExpense expense,
) => showAppSheet<void>(
  context,
  builder: (_) => _SharedExpenseSheet(expense: expense),
);

class _SharedExpenseSheet extends ConsumerWidget {
  const _SharedExpenseSheet({required this.expense});

  final SharedExpense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final e = expense;
    final myId = ref.watch(authStateProvider).valueOrNull?.id;
    String nameOf(String? userId, String? displayName) => userId == null
        ? l10n.deletedUser
        : userId == myId
        ? l10n.youLabel
        : personName(l10n, displayName);
    // Solo chi l'ha creata, finché nessun altro ha registrato la quota.
    final editable = e.createdBy != null && e.createdBy == myId && !e.locked;
    return SheetScaffold(
      title: e.description ?? l10n.sharedExpenseFallbackTitle,
      actions: [
        if (editable) ...[
          OutlinedButton.icon(
            key: const Key('deleteSharedExpenseButton'),
            icon: const Icon(Icons.delete_outline, size: 20),
            label: Text(l10n.delete),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              if (!await confirmDeletion(
                context,
                title: l10n.delete,
                message: l10n.deleteSharedExpenseBody,
              )) {
                return;
              }
              final error = await deleteSharedExpense(ref, l10n, e);
              if (error != null) {
                messenger.showSnackBar(SnackBar(content: Text(error)));
                return;
              }
              navigator.pop();
            },
          ),
          FilledButton.icon(
            key: const Key('editSharedExpenseButton'),
            icon: const Icon(Icons.edit_outlined, size: 20),
            label: Text(l10n.edit),
            onPressed: () async {
              final navigator = Navigator.of(context);
              if (await showEditSharedExpenseSheet(context, e)) {
                navigator.pop();
              }
            },
          ),
        ],
      ],
      children: [
        Text(
          formatCents(e.totalCents, currency: e.currency),
          style: moneyStyle(size: 32),
        ),
        const SizedBox(height: 4),
        Text(
          '${formatDate(context, e.spentOn)} · '
          '${l10n.shareWhoPaid} ${nameOf(e.paidBy, e.payerDisplayName)}',
          style: TextStyle(color: palette.muted),
        ),
        const SizedBox(height: 12),
        for (final s in e.shares)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: InitialsAvatar(
              name: s.userId == null ? null : s.displayName,
            ),
            title: Text(nameOf(s.userId, s.displayName)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  formatCents(s.shareCents, currency: e.currency),
                  style: moneyStyle(size: 15),
                ),
                if (s.registered) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.check_circle_outline,
                    size: 18,
                    color: palette.income,
                  ),
                ],
              ],
            ),
          ),
        if (e.locked && e.createdBy == myId) ...[
          const SizedBox(height: 8),
          Text(l10n.splitLocked, style: TextStyle(color: palette.muted)),
        ],
      ],
    );
  }
}
