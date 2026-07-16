import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
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
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showBudgetSheet(context, ref),
        child: const Icon(Icons.add),
      ),
      body: budgets.isEmpty
          ? Center(
              child: Text(
                l10n.noItems,
                style: TextStyle(color: context.nipay.muted),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              children: [
                for (final b in budgets) ...[
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
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
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            onPressed: () =>
                                _showBudgetSheet(context, ref, existing: b),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            onPressed: () async {
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

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setState) {
        final categories = (ref.read(categoriesProvider).valueOrNull ?? [])
            .where((c) => c.kind != CategoryKind.income)
            .toList();
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.newBudget,
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                key: const Key('budgetCategoryDropdown'),
                initialValue: categoryId,
                decoration: InputDecoration(labelText: l10n.category),
                items: [
                  for (final c in categories)
                    DropdownMenuItem(
                      value: c.id,
                      child: Text('${c.icon} ${c.name}'),
                    ),
                ],
                onChanged: existing == null
                    ? (v) => setState(() => categoryId = v)
                    : null,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const Key('budgetLimitField'),
                controller: amount,
                autofocus: existing != null,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: l10n.monthlyLimit,
                  suffixText: '€',
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('budgetSaveButton'),
                  child: Text(l10n.save),
                  onPressed: () async {
                    final cents = parseCents(amount.text);
                    if (cents == null || cents <= 0 || categoryId == null) {
                      return;
                    }
                    await ref
                        .read(budgetRepositoryProvider)
                        .setMonthlyLimit(
                          categoryId: categoryId!,
                          limitCents: cents,
                        );
                    ref.invalidate(budgetsProvider);
                    if (sheetContext.mounted) {
                      Navigator.of(sheetContext).pop();
                    }
                  },
                ),
              ),
            ],
          ),
        );
      },
    ),
  );
}
