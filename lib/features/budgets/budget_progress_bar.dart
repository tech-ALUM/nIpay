import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';

/// Riga budget: categoria, speso/tetto in mono e barra colorata
/// (teal < 80%, giallo ≥ 80%, rosso ≥ 100%).
class BudgetProgressBar extends ConsumerWidget {
  const BudgetProgressBar({
    super.key,
    required this.budget,
    required this.category,
  });

  final Budget budget;
  final Category? category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref
        .watch(budgetProgressProvider(budget.categoryId))
        .valueOrNull;
    final spent = progress?.spentCents ?? 0;
    final ratio = budget.limitCents == 0 ? 0.0 : spent / budget.limitCents;
    final color = ratio >= 1
        ? NipayColors.over
        : ratio >= .8
        ? NipayColors.warn
        : context.nipay.income;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${category?.icon ?? ''} ${category?.name ?? '—'}',
                style: const TextStyle(fontSize: 13),
              ),
            ),
            Text(
              '${formatCents(spent)} / ${formatCents(budget.limitCents)}',
              style: moneyStyle(
                size: 11,
                weight: FontWeight.w500,
                color: context.nipay.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 6,
            backgroundColor: context.nipay.surface2,
            color: color,
          ),
        ),
      ],
    );
  }
}
