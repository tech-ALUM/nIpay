import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/tables.dart';
import '../../l10n/app_localizations.dart';

Future<String?> _promptNewTag(BuildContext context, AppLocalizations l10n) {
  final controller = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.newTag),
      content: TextField(
        key: const Key('newTagField'),
        controller: controller,
        autofocus: true,
        decoration: InputDecoration(labelText: l10n.tagName),
        onSubmitted: (v) => Navigator.of(dialogContext).pop(v.trim()),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          key: const Key('tagSaveButton'),
          onPressed: () =>
              Navigator.of(dialogContext).pop(controller.text.trim()),
          child: Text(l10n.save),
        ),
      ],
    ),
  );
}

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
  final Set<String> _selectedTagIds = {};
  final Map<String, String> _fieldValues = {};

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
    final String txId;
    switch (_type) {
      case TransactionType.expense:
        txId = await repo.createExpense(
          walletId: walletId,
          amountCents: cents,
          date: _date,
          categoryId: _categoryId,
          description: _description.text.trim(),
        );
      case TransactionType.income:
        txId = await repo.createIncome(
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
        txId = await repo.createTransfer(
          fromWalletId: walletId,
          toWalletId: toId,
          amountCents: cents,
          date: _date,
          description: _description.text.trim(),
        );
    }

    final tagRepo = ref.read(tagRepositoryProvider);
    for (final tagId in _selectedTagIds) {
      await tagRepo.tagTransaction(txId, tagId);
    }
    final fieldRepo = ref.read(customFieldRepositoryProvider);
    for (final entry in _fieldValues.entries) {
      if (entry.value.trim().isNotEmpty) {
        await fieldRepo.setValue(
          transactionId: txId,
          fieldId: entry.key,
          value: entry.value.trim(),
        );
      }
    }

    // Avviso budget: se la spesa porta la categoria oltre l'80% o il 100%.
    if (_type == TransactionType.expense && _categoryId != null && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final budgets = await ref.read(budgetRepositoryProvider).getAll();
      if (budgets.any((b) => b.categoryId == _categoryId)) {
        final p = await ref
            .read(budgetRepositoryProvider)
            .progressFor(categoryId: _categoryId!, month: DateTime.now());
        final ratio = p.limitCents == 0 ? 0.0 : p.spentCents / p.limitCents;
        if (ratio >= .8 && mounted) {
          final name =
              (ref.read(categoriesProvider).valueOrNull ?? [])
                  .where((c) => c.id == _categoryId)
                  .firstOrNull
                  ?.name ??
              '';
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                ratio >= 1
                    ? l10n.budgetExceeded(name)
                    : l10n.budgetNear(name, (ratio * 100).round()),
              ),
              backgroundColor: ratio >= 1 ? NipayColors.over : NipayColors.warn,
            ),
          );
        }
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  /// Input per ogni campo custom definito, in base al tipo.
  List<Widget> _buildCustomFields(AppLocalizations l10n) {
    final defs = ref.watch(customFieldDefsProvider).valueOrNull ?? const [];
    if (defs.isEmpty) return const [];
    return [
      const SizedBox(height: 16),
      Text(l10n.customFields, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 8),
      for (final d in defs) ...[
        switch (d.type) {
          CustomFieldType.choice => DropdownButtonFormField<String>(
            initialValue: _fieldValues[d.id],
            decoration: InputDecoration(labelText: d.name, isDense: true),
            items: [
              for (final o in d.options ?? const <String>[])
                DropdownMenuItem(value: o, child: Text(o)),
            ],
            onChanged: (v) => setState(() => _fieldValues[d.id] = v ?? ''),
          ),
          CustomFieldType.date => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.event, size: 18),
            title: Text(
              _fieldValues[d.id] ?? d.name,
              style: const TextStyle(fontSize: 13),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(
                  () => _fieldValues[d.id] =
                      '${picked.year}-${picked.month.toString().padLeft(2, "0")}-${picked.day.toString().padLeft(2, "0")}',
                );
              }
            },
          ),
          _ => TextField(
            keyboardType: d.type == CustomFieldType.number
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: InputDecoration(labelText: d.name, isDense: true),
            onChanged: (v) => _fieldValues[d.id] = v,
          ),
        },
        const SizedBox(height: 8),
      ],
    ];
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
            if (_type != TransactionType.transfer) ...[
              const SizedBox(height: 16),
              Text(l10n.tags, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t
                      in ref.watch(tagsProvider).valueOrNull ?? const [])
                    FilterChip(
                      label: Text(
                        '#${t.name}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      selected: _selectedTagIds.contains(t.id),
                      onSelected: (sel) => setState(
                        () => sel
                            ? _selectedTagIds.add(t.id)
                            : _selectedTagIds.remove(t.id),
                      ),
                    ),
                  ActionChip(
                    key: const Key('addTagChip'),
                    label: const Text('＋', style: TextStyle(fontSize: 12)),
                    onPressed: () async {
                      final name = await _promptNewTag(context, l10n);
                      if (name == null || name.isEmpty) return;
                      final id = await ref
                          .read(tagRepositoryProvider)
                          .create(name);
                      ref.invalidate(tagsProvider);
                      setState(() => _selectedTagIds.add(id));
                    },
                  ),
                ],
              ),
              ..._buildCustomFields(l10n),
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
