import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/split_accounting.dart';
import '../../core/ui/ui.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../data/services/exchange_rate_service.dart';
import '../../data/services/shared_expense_service.dart';
import '../../l10n/app_localizations.dart';
import '../friends/friends_ui.dart';
import '../transactions/share_with_friends_card.dart';

/// Cosa registrare in un portafoglio (M-SOC4): la propria quota di una
/// spesa divisa o un rimborso confermato.
sealed class RegisterTarget {
  const RegisterTarget();
}

class ShareTarget extends RegisterTarget {
  const ShareTarget(this.expense);

  final SharedExpense expense;
}

class SettlementTarget extends RegisterTarget {
  const SettlementTarget(this.settlement);

  final Settlement settlement;
}

final _walletCategoriesProvider = StreamProvider.family<List<Category>, String>(
  (ref, walletId) => ref.watch(categoryRepositoryProvider).watchAll(walletId),
);

/// "Registra in un portafoglio": sceglie portafoglio (e categoria per la
/// quota), crea i movimenti in locale e poi lo segna sul server; se il
/// server rifiuta, i movimenti appena creati vengono tolti. True se fatto.
Future<bool> showRegisterSheet(
  BuildContext context,
  RegisterTarget target,
) async =>
    await showAppSheet<bool>(
      context,
      builder: (_) => _RegisterSheet(target: target),
    ) ==
    true;

class _RegisterSheet extends ConsumerStatefulWidget {
  const _RegisterSheet({required this.target});

  final RegisterTarget target;

  @override
  ConsumerState<_RegisterSheet> createState() => _RegisterSheetState();
}

class _RegisterSheetState extends ConsumerState<_RegisterSheet> {
  String? _walletId;
  String? _categoryId;
  double? _rate;
  String? _rateFor;
  String? _error;
  bool _saving = false;

  String get _currency => switch (widget.target) {
    ShareTarget(:final expense) => expense.currency,
    SettlementTarget(:final settlement) => settlement.currency,
  };

  /// Quanto entra nei calcoli: il totale della spesa o il rimborso.
  int get _entryTotal => switch (widget.target) {
    ShareTarget(:final expense) => expense.totalCents,
    SettlementTarget(:final settlement) => settlement.amountCents,
  };

  Future<void> _loadRate(Wallet wallet) async {
    if (wallet.currency == _currency) {
      setState(() {
        _rate = 1;
        _rateFor = wallet.id;
      });
      return;
    }
    try {
      final rate = await ref
          .read(exchangeRateServiceProvider)
          .getRate(from: _currency, to: wallet.currency);
      if (!mounted) return;
      setState(() {
        _rate = rate;
        _rateFor = wallet.id;
        _error = null;
      });
    } on ExchangeRateException catch (e) {
      if (!mounted) return;
      setState(() {
        _rate = null;
        _rateFor = wallet.id;
        _error = e.message;
      });
    }
  }

  ShareMovements _entryMovements(String myId) => switch (widget.target) {
    ShareTarget(:final expense) => movementsForShare(
      iPaid: expense.paidBy == myId,
      totalCents: expense.totalCents,
      myShareCents: expense.myShareCents,
    ),
    SettlementTarget(:final settlement) =>
      settlement.direction == SettlementDirection.outgoing
          ? (
              expenseCents: 0,
              friendOutCents: settlement.amountCents,
              friendInCents: 0,
            )
          : (
              expenseCents: 0,
              friendOutCents: 0,
              friendInCents: settlement.amountCents,
            ),
  };

  ShareMovements _localMovements(ShareMovements entry, double rate) {
    if (rate == 1) return entry;
    final walletTotal = (_entryTotal * rate).round();
    return switch (widget.target) {
      ShareTarget() => convertShareMovements(
        entry,
        entryTotalCents: _entryTotal,
        walletTotalCents: walletTotal,
      ),
      SettlementTarget() => (
        expenseCents: 0,
        friendOutCents: entry.friendOutCents == 0 ? 0 : walletTotal,
        friendInCents: entry.friendInCents == 0 ? 0 : walletTotal,
      ),
    };
  }

  String _description(AppLocalizations l10n) => switch (widget.target) {
    ShareTarget(:final expense) =>
      expense.description ?? l10n.sharedExpenseFallbackTitle,
    SettlementTarget(:final settlement) =>
      settlement.direction == SettlementDirection.outgoing
          ? l10n.settleTitle(personName(l10n, settlement.displayName))
          : l10n.registerSettlementIn(
              personName(l10n, settlement.displayName),
              formatCents(settlement.amountCents, currency: _currency),
            ),
  };

  Future<void> _register(Wallet wallet) async {
    final l10n = AppLocalizations.of(context)!;
    final myId = ref.read(authStateProvider).valueOrNull?.id;
    final rate = _rateFor == wallet.id ? _rate : null;
    if (myId == null || rate == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final entry = _entryMovements(myId);
    final local = _localMovements(entry, rate);
    final converted = rate != 1;
    final description = _description(l10n);
    final date = switch (widget.target) {
      ShareTarget(:final expense) => expense.spentOn,
      SettlementTarget() => DateTime.now(),
    };
    final expenseId = switch (widget.target) {
      ShareTarget(:final expense) => expense.id,
      SettlementTarget() => null,
    };
    final repo = ref.read(transactionRepositoryProvider);
    final created = <String>[];
    try {
      if (local.expenseCents > 0) {
        created.add(
          await repo.createExpense(
            walletId: wallet.id,
            amountCents: local.expenseCents,
            date: date,
            categoryId: _categoryId,
            description: description,
            entryCurrency: converted ? _currency : null,
            entryAmountCents: converted ? entry.expenseCents : null,
            sharedExpenseId: expenseId,
          ),
        );
      }
      final outgoing = local.friendOutCents > 0;
      if (outgoing || local.friendInCents > 0) {
        created.add(
          await repo.createFriendMovement(
            walletId: wallet.id,
            amountCents: outgoing ? local.friendOutCents : local.friendInCents,
            date: date,
            outgoing: outgoing,
            description: description,
            entryCurrency: converted ? _currency : null,
            entryAmountCents: converted
                ? (outgoing ? entry.friendOutCents : entry.friendInCents)
                : null,
            sharedExpenseId: expenseId,
          ),
        );
      }
      final service = ref.read(sharedExpenseServiceProvider);
      switch (widget.target) {
        case ShareTarget(:final expense):
          await service.registerMyShare(expense.id);
        case SettlementTarget(:final settlement):
          await service.registerMySettlement(settlement.id);
      }
      refreshSplits(ref);
      if (mounted) Navigator.of(context).pop(true);
    } on SharedExpenseException catch (e) {
      // Il server non l'ha segnato: via i movimenti, niente doppioni.
      for (final id in created) {
        await repo.softDelete(id);
      }
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = sharedExpenseErrorText(l10n, e.code);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final wallets = ref.watch(walletsProvider).valueOrNull ?? const <Wallet>[];
    final active = ref.watch(activeWalletProvider);
    final wallet =
        wallets.where((w) => w.id == _walletId).firstOrNull ?? active;
    if (wallet != null && _rateFor != wallet.id) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _rateFor != wallet.id) _loadRate(wallet);
      });
    }
    final myId = ref.watch(authStateProvider).valueOrNull?.id;
    final rate = wallet != null && _rateFor == wallet.id ? _rate : null;
    final isShare = widget.target is ShareTarget;
    final categories = !isShare || wallet == null
        ? const <Category>[]
        : (ref.watch(_walletCategoriesProvider(wallet.id)).valueOrNull ??
                  const <Category>[])
              .where((c) => c.kind != CategoryKind.income)
              .toList();

    final entryAmount = switch (widget.target) {
      ShareTarget(:final expense) => expense.myShareCents,
      SettlementTarget(:final settlement) => settlement.amountCents,
    };
    final headline = switch (widget.target) {
      ShareTarget(:final expense) => l10n.registerShareItem(
        expense.description ?? l10n.sharedExpenseFallbackTitle,
        formatCents(entryAmount, currency: _currency),
      ),
      SettlementTarget(:final settlement) =>
        settlement.direction == SettlementDirection.outgoing
            ? l10n.registerSettlementOut(
                personName(l10n, settlement.displayName),
                formatCents(entryAmount, currency: _currency),
              )
            : l10n.registerSettlementIn(
                personName(l10n, settlement.displayName),
                formatCents(entryAmount, currency: _currency),
              ),
    };
    // Quanto cambia questo portafoglio: la quota (spesa) o il rimborso.
    final preview = rate == null || myId == null || rate == 1
        ? null
        : switch (_localMovements(_entryMovements(myId), rate)) {
            final m =>
              isShare ? m.expenseCents : m.friendOutCents + m.friendInCents,
          };

    return SheetScaffold(
      title: l10n.registerTitle,
      actions: [
        FilledButton(
          key: const Key('registerConfirmButton'),
          onPressed: _saving || wallet == null || rate == null
              ? null
              : () => _register(wallet),
          child: Text(l10n.registerAction),
        ),
      ],
      children: [
        Text(headline, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          key: const Key('registerWalletDropdown'),
          initialValue: wallet?.id,
          isExpanded: true,
          decoration: InputDecoration(labelText: l10n.wallet),
          items: [
            for (final w in wallets)
              DropdownMenuItem(
                value: w.id,
                child: Text('${w.name} · ${w.currency}'),
              ),
          ],
          onChanged: (id) => setState(() {
            _walletId = id;
            _categoryId = null;
          }),
        ),
        if (preview != null && wallet != null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.registerConverted(
              formatCents(preview, currency: wallet.currency),
            ),
            key: const Key('registerConvertedPreview'),
          ),
        ],
        if (isShare) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            key: const Key('registerCategoryDropdown'),
            initialValue: _categoryId,
            isExpanded: true,
            decoration: InputDecoration(labelText: l10n.category),
            items: [
              DropdownMenuItem(value: null, child: Text(l10n.none)),
              for (final c in categories)
                DropdownMenuItem(value: c.id, child: Text(c.label(l10n))),
            ],
            onChanged: (id) => setState(() => _categoryId = id),
          ),
        ],
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(
            _error!,
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
      ],
    );
  }
}
