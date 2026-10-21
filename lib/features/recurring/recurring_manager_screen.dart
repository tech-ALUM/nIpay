import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../core/validation.dart';
import '../../data/db/tables.dart';
import '../../l10n/app_localizations.dart';
import '../wallets/wallet_form_sheet.dart' show requireWallet;

class RecurringManagerScreen extends ConsumerWidget {
  const RecurringManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final currency = ref.watch(activeWalletProvider)?.currency ?? 'EUR';
    final rules = ref.watch(recurringRulesProvider).valueOrNull ?? const [];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.recurring)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (requireWallet(context, ref)) _showRecurringSheet(context, ref);
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.newRecurring),
      ),
      body: rules.isEmpty
          ? Center(
              child: EmptyState(icon: Icons.autorenew, message: l10n.noItems),
            )
          : CenteredListView(
              children: [
                for (final r in rules) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        14,
                        16,
                        6,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          MergeSemantics(
                            child: Row(
                              children: [
                                IconBadge(
                                  icon: r.pausedAt != null
                                      ? Icons.pause
                                      : Icons.autorenew,
                                  color: r.pausedAt != null
                                      ? palette.muted
                                      : palette.expense,
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        r.description.isEmpty
                                            ? '—'
                                            : r.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleSmall,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${_freqLabel(l10n, r.frequency)} · '
                                        '${l10n.nextRun} '
                                        '${formatDate(context, r.nextRunAt)}'
                                        '${r.pausedAt != null ? ' · ${l10n.paused}' : ''}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  r.type == TransactionType.expense
                                      ? formatCents(
                                          -r.amountCents,
                                          currency: currency,
                                        )
                                      : formatCents(
                                          r.amountCents,
                                          currency: currency,
                                          signed: true,
                                        ),
                                  style: moneyStyle(
                                    size: 15,
                                    color: r.type == TransactionType.expense
                                        ? palette.expense
                                        : palette.income,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Azioni con etichetta, non solo icone: pausa e
                          // ripresa cambiano cosa verrà registrato in futuro.
                          Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 4,
                            children: [
                              TextButton.icon(
                                icon: Icon(
                                  r.pausedAt != null
                                      ? Icons.play_arrow
                                      : Icons.pause,
                                  size: 20,
                                ),
                                label: Text(
                                  r.pausedAt != null ? l10n.resume : l10n.pause,
                                ),
                                onPressed: () async {
                                  final repo = ref.read(
                                    recurringRepositoryProvider,
                                  );
                                  if (r.pausedAt != null) {
                                    await repo.resume(r.id);
                                    await repo.generateDue(now: DateTime.now());
                                  } else {
                                    await repo.pause(r.id);
                                  }
                                  ref.invalidate(recurringRulesProvider);
                                },
                              ),
                              TextButton.icon(
                                style: TextButton.styleFrom(
                                  foregroundColor: Theme.of(
                                    context,
                                  ).colorScheme.error,
                                ),
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                ),
                                label: Text(l10n.delete),
                                onPressed: () async {
                                  final confirmed = await confirmDeletion(
                                    context,
                                    title: l10n.deleteItemTitle(
                                      r.description.isEmpty
                                          ? l10n.recurring
                                          : r.description,
                                    ),
                                  );
                                  if (!confirmed) return;
                                  await ref
                                      .read(recurringRepositoryProvider)
                                      .softDelete(r.id);
                                  ref.invalidate(recurringRulesProvider);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
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
  String? amountError;

  return showAppSheet<void>(
    context,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setState) {
        final wallets = ref.read(walletsProvider).valueOrNull ?? [];
        final selectedWalletId = walletId ?? wallets.firstOrNull?.id;
        final selectedCurrency =
            wallets
                .where((w) => w.id == selectedWalletId)
                .firstOrNull
                ?.currency ??
            'EUR';
        final categories = (ref.read(categoriesProvider).valueOrNull ?? [])
            .where(
              (c) => type == TransactionType.expense
                  ? c.kind != CategoryKind.income
                  : c.kind != CategoryKind.expense,
            )
            .toList();
        return SheetScaffold(
          title: l10n.newRecurring,
          header: SegmentedButton<TransactionType>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: TransactionType.expense,
                icon: const Icon(Icons.north_east_rounded, size: 18),
                label: Text(l10n.expense),
              ),
              ButtonSegment(
                value: TransactionType.income,
                icon: const Icon(Icons.south_west_rounded, size: 18),
                label: Text(l10n.income),
              ),
            ],
            selected: {type},
            onSelectionChanged: (s) => setState(() => type = s.first),
          ),
          actions: [
            FilledButton(
              onPressed: () async {
                final cents = parseCents(amount.text);
                final validAmount = cents != null && cents > 0;
                setState(
                  () => amountError = validAmount ? null : l10n.invalidAmount,
                );
                if (!validAmount || selectedWalletId == null) return;
                final repo = ref.read(recurringRepositoryProvider);
                await repo.create(
                  walletId: selectedWalletId,
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
              child: Text(l10n.save),
            ),
          ],
          children: [
            TextField(
              controller: amount,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: moneyStyle(size: 18),
              onChanged: (_) {
                if (amountError != null) setState(() => amountError = null);
              },
              decoration: InputDecoration(
                labelText: l10n.amount,
                errorText: amountError,
                suffixText: selectedCurrency == 'EUR' ? '€' : selectedCurrency,
              ),
            ),
            kFieldGap,
            TextField(
              controller: description,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [
                LengthLimitingTextInputFormatter(kMaxDescriptionLength),
              ],
              decoration: InputDecoration(labelText: l10n.description),
            ),
            if (wallets.isNotEmpty) ...[
              kFieldGap,
              DropdownButtonFormField<String>(
                initialValue: walletId ?? wallets.first.id,
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: l10n.wallet,
                  prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                ),
                items: [
                  for (final w in wallets)
                    DropdownMenuItem(value: w.id, child: Text(w.name)),
                ],
                onChanged: (v) => setState(() => walletId = v),
              ),
            ],
            kFieldGap,
            DropdownButtonFormField<String?>(
              initialValue: categoryId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.category,
                prefixIcon: const Icon(Icons.category_outlined),
              ),
              items: [
                DropdownMenuItem(value: null, child: Text(l10n.allCategories)),
                for (final c in categories)
                  DropdownMenuItem(value: c.id, child: Text(c.label(l10n))),
              ],
              onChanged: (v) => setState(() => categoryId = v),
            ),
            kFieldGap,
            DropdownButtonFormField<RecurrenceFrequency>(
              initialValue: frequency,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.frequency,
                prefixIcon: const Icon(Icons.autorenew),
              ),
              items: [
                for (final f in RecurrenceFrequency.values)
                  DropdownMenuItem(value: f, child: Text(_freqLabel(l10n, f))),
              ],
              onChanged: (v) => setState(() => frequency = v!),
            ),
            kFieldGap,
            DateField(
              label: l10n.startDate,
              value: formatDate(sheetContext, startAt),
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
          ],
        );
      },
    ),
  );
}
