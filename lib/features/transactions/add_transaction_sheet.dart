import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/tables.dart';
import '../../l10n/app_localizations.dart';

Future<void> showAddTransactionSheet(BuildContext context) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddTransactionSheet(),
    );

class _AddTransactionSheet extends ConsumerStatefulWidget {
  const _AddTransactionSheet();

  @override
  ConsumerState<_AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<_AddTransactionSheet> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String? _walletId;
  String? _walletToId;
  String? _categoryId;
  DateTime _date = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final cents = parseCents(_amount.text);
    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    final walletId = _walletId ?? wallets.firstOrNull?.id;
    if (cents == null || cents <= 0 || walletId == null) {
      setState(() => _error = l10n.invalidAmount);
      return;
    }

    final repo = ref.read(transactionRepositoryProvider);
    switch (_type) {
      case TransactionType.expense:
        await repo.createExpense(
          walletId: walletId,
          amountCents: cents,
          date: _date,
          categoryId: _categoryId,
          description: _description.text.trim(),
        );
      case TransactionType.income:
        await repo.createIncome(
          walletId: walletId,
          amountCents: cents,
          date: _date,
          categoryId: _categoryId,
          description: _description.text.trim(),
        );
      case TransactionType.transfer:
        final toId =
            _walletToId ??
            wallets.where((w) => w.id != walletId).firstOrNull?.id;
        if (toId == null) {
          setState(() => _error = l10n.invalidAmount);
          return;
        }
        await repo.createTransfer(
          fromWalletId: walletId,
          toWalletId: toId,
          amountCents: cents,
          date: _date,
          description: _description.text.trim(),
        );
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final categories = (ref.watch(categoriesProvider).valueOrNull ?? [])
        .where(
          (c) => switch (_type) {
            TransactionType.expense => c.kind != CategoryKind.income,
            TransactionType.income => c.kind != CategoryKind.expense,
            TransactionType.transfer => false,
          },
        )
        .toList();
    final walletId = _walletId ?? wallets.firstOrNull?.id;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.newTransaction,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            SegmentedButton<TransactionType>(
              segments: [
                ButtonSegment(
                  value: TransactionType.expense,
                  label: Text(l10n.expense),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  label: Text(l10n.income),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  label: Text(l10n.transfer),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: 16),
            TextField(
              key: const Key('amountField'),
              controller: _amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: moneyStyle(size: 28),
              decoration: InputDecoration(
                labelText: l10n.amount,
                suffixText: '€',
                errorText: _error,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('descriptionField'),
              controller: _description,
              decoration: InputDecoration(labelText: l10n.description),
            ),
            const SizedBox(height: 12),
            if (wallets.isNotEmpty)
              DropdownButtonFormField<String>(
                key: const Key('walletDropdown'),
                initialValue: walletId,
                decoration: InputDecoration(
                  labelText: _type == TransactionType.transfer
                      ? l10n.fromWallet
                      : l10n.wallet,
                ),
                items: [
                  for (final w in wallets)
                    DropdownMenuItem(value: w.id, child: Text(w.name)),
                ],
                onChanged: (v) => setState(() => _walletId = v),
              ),
            if (_type == TransactionType.transfer && wallets.length > 1) ...[
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                key: const Key('walletToDropdown'),
                initialValue:
                    _walletToId ??
                    wallets.where((w) => w.id != walletId).firstOrNull?.id,
                decoration: InputDecoration(labelText: l10n.toWallet),
                items: [
                  for (final w in wallets.where((w) => w.id != walletId))
                    DropdownMenuItem(value: w.id, child: Text(w.name)),
                ],
                onChanged: (v) => setState(() => _walletToId = v),
              ),
            ],
            if (_type != TransactionType.transfer) ...[
              const SizedBox(height: 16),
              Text(l10n.category, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in categories)
                    ChoiceChip(
                      label: Text(
                        '${c.icon} ${c.name}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: _categoryId == c.id,
                      onSelected: (sel) =>
                          setState(() => _categoryId = sel ? c.id : null),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(Icons.event, color: palette.muted),
              title: Text(
                '${_date.day}/${_date.month}/${_date.year}',
                style: const TextStyle(fontSize: 14),
              ),
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
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                key: const Key('txSaveButton'),
                onPressed: _save,
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
