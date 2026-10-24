import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/split_accounting.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../data/services/exchange_rate_service.dart';
import '../../data/services/friends_service.dart';
import '../../data/services/shared_expense_service.dart';
import '../../l10n/app_localizations.dart';
import '../transactions/share_with_friends_card.dart';

/// Elimina una spesa divisa (solo chi l'ha creata, finché non è bloccata)
/// e i miei movimenti locali collegati. Null se fatto, altrimenti l'errore.
Future<String?> deleteSharedExpense(
  WidgetRef ref,
  AppLocalizations l10n,
  SharedExpense expense,
) async {
  try {
    await ref.read(sharedExpenseServiceProvider).delete(expense.id);
  } on SharedExpenseException catch (e) {
    return sharedExpenseErrorText(l10n, e.code);
  }
  final repo = ref.read(transactionRepositoryProvider);
  for (final t in await repo.linkedTo(expense.id)) {
    await repo.softDelete(t.id);
  }
  refreshSplits(ref);
  return null;
}

/// Modifica di una spesa divisa da parte di chi l'ha creata, finché nessun
/// altro ha registrato la quota (decisione 2026-10-24). True se salvata.
Future<bool> showEditSharedExpenseSheet(
  BuildContext context,
  SharedExpense expense,
) async =>
    await showAppSheet<bool>(
      context,
      builder: (_) => _EditSharedExpenseSheet(expense: expense),
    ) ==
    true;

class _EditSharedExpenseSheet extends ConsumerStatefulWidget {
  const _EditSharedExpenseSheet({required this.expense});

  final SharedExpense expense;

  @override
  ConsumerState<_EditSharedExpenseSheet> createState() =>
      _EditSharedExpenseSheetState();
}

class _EditSharedExpenseSheetState
    extends ConsumerState<_EditSharedExpenseSheet> {
  late final TextEditingController _description;
  late final TextEditingController _amount;
  late DateTime _date;
  late ShareDraft _draft;
  String? _error;
  String? _shareError;
  bool _saving = false;

  SharedExpense get _e => widget.expense;

  @override
  void initState() {
    super.initState();
    final myId = ref.read(authStateProvider).valueOrNull?.id;
    _description = TextEditingController(text: _e.description ?? '');
    _amount = TextEditingController(
      text: (_e.totalCents / 100).toStringAsFixed(2).replaceAll('.', ','),
    );
    _date = _e.spentOn;
    final friendIds = [
      for (final s in _e.shares)
        if (s.userId != null && s.userId != myId) s.userId!,
    ];
    final byUser = {
      for (final s in _e.shares)
        if (s.userId != null) s.userId!: s.shareCents,
    };
    final order = [?myId, ...friendIds];
    final equal = splitEqually(_e.totalCents, order.length);
    final isEqual = [
      for (final id in order) byUser[id],
    ].indexed.every((p) => p.$2 == equal[p.$1]);
    _draft = ShareDraft(
      friendIds: friendIds,
      payerId: _e.paidBy == myId ? null : _e.paidBy,
      custom: !isEqual,
      customCents: isEqual ? const {} : byUser,
    );
  }

  @override
  void dispose() {
    _description.dispose();
    _amount.dispose();
    super.dispose();
  }

  /// Gli amici della card: quelli di adesso più i partecipanti che non lo
  /// sono più (il server poi rifiuterà, ma il nome si vede).
  List<Friend> _friends(List<Friend> current, String? myId) => [
    ...current,
    for (final s in _e.shares)
      if (s.userId != null &&
          s.userId != myId &&
          !current.any((f) => f.userId == s.userId))
        Friend(
          userId: s.userId!,
          displayName: s.displayName,
          friendsSince: null,
        ),
  ];

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final myId = ref.read(authStateProvider).valueOrNull?.id;
    final cents = parseCents(_amount.text);
    if (myId == null || cents == null || cents <= 0) {
      setState(() => _error = l10n.invalidAmount);
      return;
    }
    final resolved = _draft.resolve(myId, cents);
    final shares = resolved.shares;
    if (shares == null) {
      setState(() => _shareError = splitErrorText(l10n, resolved.error!));
      return;
    }
    final participants = _draft.participants(myId);
    final payer = _draft.payerId ?? myId;
    final description = _description.text.trim();
    setState(() {
      _saving = true;
      _error = null;
      _shareError = null;
    });

    // Prima tutto ciò che può fallire in locale (il tasso), poi il server.
    final repo = ref.read(transactionRepositoryProvider);
    final linked = await repo.linkedTo(_e.id);
    final myShareTx = linked
        .where((t) => t.type == TransactionType.expense)
        .firstOrNull;
    final entry = movementsForShare(
      iPaid: payer == myId,
      totalCents: cents,
      myShareCents: shares[participants.indexOf(myId)],
    );
    var local = entry;
    final converted = myShareTx?.entryCurrency != null;
    if (myShareTx != null && converted) {
      final wallets = ref.read(walletsProvider).valueOrNull ?? const <Wallet>[];
      final wallet = wallets
          .where((w) => w.id == myShareTx.walletId)
          .firstOrNull;
      if (wallet != null) {
        try {
          final rate = await ref
              .read(exchangeRateServiceProvider)
              .getRate(from: _e.currency, to: wallet.currency);
          local = convertShareMovements(
            entry,
            entryTotalCents: cents,
            walletTotalCents: (cents * rate).round(),
          );
        } on ExchangeRateException catch (e) {
          if (!mounted) return;
          setState(() {
            _saving = false;
            _error = e.message;
          });
          return;
        }
      }
    }

    try {
      await ref
          .read(sharedExpenseServiceProvider)
          .update(
            _e.id,
            description: description.isEmpty ? null : description,
            totalCents: cents,
            currency: _e.currency,
            spentOn: _date,
            paidBy: payer,
            shares: [
              for (var i = 0; i < participants.length; i++)
                (userId: participants[i], shareCents: shares[i]),
            ],
          );
    } on SharedExpenseException catch (e) {
      if (!mounted) return;
      final text = sharedExpenseErrorText(l10n, e.code);
      setState(() {
        _saving = false;
        _error = text;
        _shareError = text;
      });
      return;
    }

    // La mia quota resta la stessa transazione (tag, scontrino, nota
    // spese); il movimento "con amici" si rifà, il verso può cambiare.
    if (myShareTx != null) {
      final text = description.isEmpty
          ? l10n.sharedExpenseFallbackTitle
          : description;
      await repo.updateTransaction(
        myShareTx.id,
        amountCents: local.expenseCents,
        date: _date,
        description: text,
        entryAmountCents: converted ? entry.expenseCents : null,
      );
      for (final t in linked) {
        if (t.id != myShareTx.id) await repo.softDelete(t.id);
      }
      final outgoing = local.friendOutCents > 0;
      if (outgoing || local.friendInCents > 0) {
        await repo.createFriendMovement(
          walletId: myShareTx.walletId,
          amountCents: outgoing ? local.friendOutCents : local.friendInCents,
          date: _date,
          outgoing: outgoing,
          description: text,
          entryCurrency: converted ? _e.currency : null,
          entryAmountCents: converted
              ? (outgoing ? entry.friendOutCents : entry.friendInCents)
              : null,
          sharedExpenseId: _e.id,
        );
      }
    }
    refreshSplits(ref);
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final myId = ref.watch(authStateProvider).valueOrNull?.id;
    final friends = _friends(
      ref.watch(friendsListProvider).valueOrNull ?? const <Friend>[],
      myId,
    );
    final cents = parseCents(_amount.text);
    return SheetScaffold(
      title: l10n.editSharedExpense,
      actions: [
        FilledButton(
          key: const Key('editSharedSaveButton'),
          onPressed: _saving ? null : _save,
          child: Text(l10n.save),
        ),
      ],
      children: [
        TextField(
          key: const Key('editSharedAmountField'),
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: moneyInputFormatters,
          style: moneyStyle(size: 28),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l10n.amount,
            suffixText: _e.currency,
            errorText: _error,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          key: const Key('editSharedDescriptionField'),
          controller: _description,
          maxLength: 200,
          decoration: InputDecoration(labelText: l10n.description),
        ),
        DateField(
          label: l10n.date,
          value: formatDate(context, _date),
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _date,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (picked != null) setState(() => _date = picked);
          },
        ),
        const SizedBox(height: 12),
        if (myId != null)
          ShareWithFriendsCard(
            draft: _draft,
            onChanged: (d) => setState(() {
              _draft = d;
              _shareError = null;
            }),
            myId: myId,
            friends: friends,
            totalCents: cents != null && cents > 0 ? cents : null,
            currency: _e.currency,
            errorText: _shareError,
          ),
      ],
    );
  }
}
