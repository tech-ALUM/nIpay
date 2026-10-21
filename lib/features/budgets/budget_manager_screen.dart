import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../l10n/app_localizations.dart';
import 'budget_progress_bar.dart';

class BudgetManagerScreen extends ConsumerWidget {
  const BudgetManagerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final budgets = ref.watch(budgetsProvider).valueOrNull ?? const <Budget>[];
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.budgets)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showBudgetSheet(context, ref),
        icon: const Icon(Icons.add),
        label: Text(l10n.newBudget),
      ),
      body: budgets.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.savings_outlined,
                message: l10n.noItems,
              ),
            )
          : CenteredListView(
              children: [
                for (final b in budgets) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        8,
                        4,
                        8,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: BudgetProgressBar(
                              budget: b,
                              category: categories
                                  .where((c) => c.id == b.categoryId)
                                  .firstOrNull,
                            ),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: l10n.edit,
                            icon: const Icon(Icons.edit_outlined),
                            onPressed: () =>
                                _showBudgetSheet(context, ref, existing: b),
                          ),
                          IconButton(
                            tooltip: l10n.delete,
                            icon: Icon(
                              Icons.delete_outline,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () async {
                              final category = categories
                                  .where((c) => c.id == b.categoryId)
                                  .firstOrNull;
                              final confirmed = await confirmDeletion(
                                context,
                                title: l10n.deleteItemTitle(
                                  '${l10n.budgets} ${category?.displayName(l10n) ?? ''}'
                                      .trim(),
                                ),
                              );
                              if (!confirmed) return;
                              await ref
                                  .read(budgetRepositoryProvider)
                                  .softDelete(b.id);
                              ref.invalidate(budgetsProvider);
                            },
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

Future<void> _showBudgetSheet(
  BuildContext context,
  WidgetRef ref, {
  Budget? existing,
}) {
  final l10n = AppLocalizations.of(context)!;
  final amount = TextEditingController(
    text: existing == null
        ? ''
        : (existing.limitCents / 100).toStringAsFixed(2).replaceAll('.', ','),
  );
  String? categoryId = existing?.categoryId;
  String? categoryError;
  String? amountError;

  return showAppSheet<void>(
    context,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setState) {
        final categories = (ref.read(categoriesProvider).valueOrNull ?? [])
            .where((c) => c.kind != CategoryKind.income)
            .toList();
        final currency = ref.read(activeWalletProvider)?.currency ?? 'EUR';
        return SheetScaffold(
          title: existing == null ? l10n.newBudget : l10n.budgets,
          actions: [
            FilledButton(
              key: const Key('budgetSaveButton'),
              onPressed: () async {
                final cents = parseCents(amount.text);
                final validAmount = cents != null && cents > 0;
                setState(() {
                  categoryError = categoryId == null
                      ? l10n.fieldRequired
                      : null;
                  amountError = validAmount ? null : l10n.invalidAmount;
                });
                if (!validAmount || categoryId == null) return;
                final active = ref.read(activeWalletProvider);
                if (active == null) return;
                await ref
                    .read(budgetRepositoryProvider)
                    .setMonthlyLimit(
                      walletId: active.id,
                      categoryId: categoryId!,
                      limitCents: cents,
                    );
                ref.invalidate(budgetsProvider);
                if (sheetContext.mounted) {
                  Navigator.of(sheetContext).pop();
                }
              },
              child: Text(l10n.save),
            ),
          ],
          children: [
            DropdownButtonFormField<String>(
              key: const Key('budgetCategoryDropdown'),
              initialValue: categoryId,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: l10n.category,
                errorText: categoryError,
              ),
              items: [
                for (final c in categories)
                  DropdownMenuItem(value: c.id, child: Text(c.label(l10n))),
              ],
              onChanged: existing == null
                  ? (v) => setState(() {
                      categoryId = v;
                      categoryError = null;
                    })
                  : null,
            ),
            kFieldGap,
            TextField(
              key: const Key('budgetLimitField'),
              controller: amount,
              autofocus: existing != null,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: moneyStyle(size: 18),
              onChanged: (_) {
                if (amountError != null) setState(() => amountError = null);
              },
              decoration: InputDecoration(
                labelText: l10n.monthlyLimit,
                errorText: amountError,
                suffixText: currency == 'EUR' ? '€' : currency,
              ),
            ),
          ],
        );
      },
    ),
  );
}
