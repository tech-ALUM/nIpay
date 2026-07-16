import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/tables.dart';
import '../../l10n/app_localizations.dart';

class RecurringManagerScreen extends ConsumerWidget {
  const RecurringManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final rules = ref.watch(recurringRulesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurring)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecurringSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: rules.isEmpty
          ? Center(
              child: Text(l10n.noItems, style: TextStyle(color: palette.muted)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                for (final r in rules)
                  ListTile(
                    leading: Icon(
                      r.pausedAt != null
                          ? Icons.pause_circle_outline
                          : Icons.autorenew,
                      color: r.pausedAt != null
                          ? palette.muted
                          : NipayColors.coral,
                      size: 22,
                    ),
                    title: Text(
                      r.description.isEmpty ? '—' : r.description,
                      style: const TextStyle(fontSize: 14),
                    ),
                    subtitle: Text(
                      '${_freqLabel(l10n, r.frequency)} · ${l10n.nextRun} '
                      '${r.nextRunAt.day}/${r.nextRunAt.month}/${r.nextRunAt.year}'
                      '${r.pausedAt != null ? ' · ${l10n.paused}' : ''}',
                      style: TextStyle(fontSize: 11, color: palette.muted),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          r.type == TransactionType.expense
                              ? formatCents(-r.amountCents)
                              : formatCents(r.amountCents, signed: true),
                          style: moneyStyle(
                            size: 13,
                            color: r.type == TransactionType.expense
                                ? palette.expense
                                : palette.income,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            r.pausedAt != null ? Icons.play_arrow : Icons.pause,
                            size: 18,
                          ),
                          onPressed: () async {
                            final repo = ref.read(recurringRepositoryProvider);
                            if (r.pausedAt != null) {
                              await repo.resume(r.id);
                              await repo.generateDue(now: DateTime.now());
                            } else {
                              await repo.pause(r.id);
                            }
                            ref.invalidate(recurringRulesProvider);
                          },
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: Theme.of(context).colorScheme.error,
                          ),
                          onPressed: () async {
                            await ref
                                .read(recurringRepositoryProvider)
                                .softDelete(r.id);
                            ref.invalidate(recurringRulesProvider);
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}

String _freqLabel(AppLocalizations l10n, RecurrenceFrequency f) => switch (f) {
  RecurrenceFrequency.daily => l10n.freqDaily,
  RecurrenceFrequency.weekly => l10n.freqWeekly,
  RecurrenceFrequency.monthly => l10n.freqMonthly,
  RecurrenceFrequency.yearly => l10n.freqYearly,
};

Future<void> _showRecurringSheet(BuildContext context, WidgetRef ref) {
  final l10n = AppLocalizations.of(context)!;
  final amount = TextEditingController();
  final description = TextEditingController();
  var type = TransactionType.expense;
  var frequency = RecurrenceFrequency.monthly;
  String? walletId;
  String? categoryId;
  var startAt = DateTime.now();

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setState) {
        final wallets = ref.read(walletsProvider).valueOrNull ?? [];
        final categories = (ref.read(categoriesProvider).valueOrNull ?? [])
            .where(
              (c) => type == TransactionType.expense
                  ? c.kind != CategoryKind.income
                  : c.kind != CategoryKind.expense,
            )
            .toList();
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.newRecurring,
                  style: Theme.of(sheetContext).textTheme.titleLarge,
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
                  ],
                  selected: {type},
                  onSelectionChanged: (s) => setState(() => type = s.first),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: amount,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: l10n.amount,
                    suffixText: '€',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: description,
                  decoration: InputDecoration(labelText: l10n.description),
                ),
                const SizedBox(height: 12),
                if (wallets.isNotEmpty)
                  DropdownButtonFormField<String>(
                    initialValue: walletId ?? wallets.first.id,
                    decoration: InputDecoration(labelText: l10n.wallet),
                    items: [
                      for (final w in wallets)
                        DropdownMenuItem(value: w.id, child: Text(w.name)),
                    ],
                    onChanged: (v) => setState(() => walletId = v),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String?>(
                  initialValue: categoryId,
                  decoration: InputDecoration(labelText: l10n.category),
                  items: [
                    DropdownMenuItem(
                      value: null,
                      child: Text(l10n.allCategories),
                    ),
                    for (final c in categories)
                      DropdownMenuItem(
                        value: c.id,
                        child: Text('${c.icon} ${c.name}'),
                      ),
                  ],
                  onChanged: (v) => setState(() => categoryId = v),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<RecurrenceFrequency>(
                  initialValue: frequency,
                  decoration: InputDecoration(labelText: l10n.frequency),
                  items: [
                    for (final f in RecurrenceFrequency.values)
                      DropdownMenuItem(
                        value: f,
                        child: Text(_freqLabel(l10n, f)),
                      ),
                  ],
                  onChanged: (v) => setState(() => frequency = v!),
                ),
                const SizedBox(height: 8),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event, size: 18),
                  title: Text(
                    '${l10n.startDate}: ${startAt.day}/${startAt.month}/${startAt.year}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: sheetContext,
                      initialDate: startAt,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setState(() => startAt = picked);
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    child: Text(l10n.save),
                    onPressed: () async {
                      final cents = parseCents(amount.text);
                      final wId = walletId ?? wallets.firstOrNull?.id;
                      if (cents == null || cents <= 0 || wId == null) return;
                      final repo = ref.read(recurringRepositoryProvider);
                      await repo.create(
                        walletId: wId,
                        categoryId: categoryId,
                        type: type,
                        amountCents: cents,
                        description: description.text.trim(),
                        frequency: frequency,
                        startAt: startAt,
                      );
                      // Materializza subito le occorrenze già scadute.
                      await repo.generateDue(now: DateTime.now());
                      ref.invalidate(recurringRulesProvider);
                      if (sheetContext.mounted) {
                        Navigator.of(sheetContext).pop();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}
