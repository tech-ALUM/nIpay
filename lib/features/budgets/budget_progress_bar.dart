import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';

/// Riga budget: categoria, speso/tetto e barra colorata (teal < 80%, giallo
/// ≥ 80%, rosso ≥ 100%). Oltre al colore, un'icona segnala gli stati di
/// attenzione e la barra espone la percentuale agli screen reader.
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
    final palette = context.nipay;
    final currency = ref.watch(activeWalletProvider)?.currency ?? 'EUR';
    final progress = ref
        .watch(budgetProgressProvider(budget.categoryId))
        .valueOrNull;
    final spent = progress?.spentCents ?? 0;
    final ratio = budget.limitCents == 0 ? 0.0 : spent / budget.limitCents;
    final (color, iconColor, statusIcon) = ratio >= 1
        ? (palette.danger, palette.danger, Icons.error_outline)
        : ratio >= .8
        ? (palette.warning, palette.warningStrong, Icons.warning_amber_rounded)
        : (palette.income, palette.income, null);
    final l10n = AppLocalizations.of(context)!;
    final label = category?.label(l10n) ?? '—';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            if (statusIcon != null) ...[
              ExcludeSemantics(
                child: Icon(statusIcon, size: 16, color: iconColor),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              '${formatCents(spent, currency: currency)} / '
              '${formatCents(budget.limitCents, currency: currency)}',
              style: moneyStyle(
                size: 12.5,
                weight: FontWeight.w600,
                color: palette.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio.clamp(0.0, 1.0),
            minHeight: 8,
            backgroundColor: palette.surface2,
            color: color,
            semanticsLabel: category?.displayName(l10n),
            semanticsValue: '${(ratio * 100).round()}%',
          ),
        ),
      ],
    );
  }
}
