import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';
import 'stat_cards.dart';

/// Tipi di card disponibili; il valore è salvato in DashboardCard.type.
const kCardTypes = ['categoryDonut', 'trend', 'cashflow', 'budget'];

String cardTitle(AppLocalizations l10n, String type) => switch (type) {
  'categoryDonut' => l10n.cardCategoryDonut,
  'trend' => l10n.cardTrend,
  'cashflow' => l10n.cardCashflow,
  'budget' => l10n.cardBudget,
  _ => type,
};

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final cards = ref.watch(dashboardCardsProvider).valueOrNull ?? const [];
    final month = ref.watch(statsMonthProvider);
    final monthLabel = '${_monthNames[month.month - 1]} ${month.year}';

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.statsTab,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  onPressed: () => ref.read(statsMonthProvider.notifier).state =
                      DateTime(month.year, month.month - 1),
                  icon: const Icon(Icons.chevron_left),
                ),
                Text(
                  monthLabel,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                IconButton(
                  onPressed: () => ref.read(statsMonthProvider.notifier).state =
                      DateTime(month.year, month.month + 1),
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
          ),
          Expanded(
            child: ReorderableListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 96),
              onReorderItem: (oldIndex, newIndex) {
                if (oldIndex >= cards.length) return;
                ref
                    .read(dashboardRepositoryProvider)
                    .moveCard(cards[oldIndex].id, newIndex);
              },
              footer: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: _AddCardButton(
                  emptyHint: cards.isEmpty ? l10n.emptyDashboard : null,
                ),
              ),
              children: [
                for (final card in cards)
                  Padding(
                    key: ValueKey(card.id),
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.drag_indicator,
                                  size: 16,
                                  color: palette.muted,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    cardTitle(l10n, card.type),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontSize: 14),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => ref
                                      .read(dashboardRepositoryProvider)
                                      .removeCard(card.id),
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: palette.muted,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            StatCardBody(type: card.type, month: month),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddCardButton extends ConsumerWidget {
  const _AddCardButton({this.emptyHint});

  final String? emptyHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    return Column(
      children: [
        if (emptyHint != null) ...[
          Text(
            emptyHint!,
            style: TextStyle(color: palette.muted, fontSize: 13),
          ),
          const SizedBox(height: 12),
        ],
        InkWell(
          key: const Key('addCardButton'),
          borderRadius: BorderRadius.circular(20),
          onTap: () async {
            final type = await showDialog<String>(
              context: context,
              builder: (dialogContext) => SimpleDialog(
                title: Text(l10n.addCard),
                children: [
                  for (final t in kCardTypes)
                    SimpleDialogOption(
                      onPressed: () => Navigator.of(dialogContext).pop(t),
                      child: Text(cardTitle(l10n, t)),
                    ),
                ],
              ),
            );
            if (type != null) {
              await ref.read(dashboardRepositoryProvider).addCard(type: type);
            }
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: palette.line,
                width: 2,
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '＋ ${l10n.addCard}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: palette.muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

const _monthNames = [
  'gen',
  'feb',
  'mar',
  'apr',
  'mag',
  'giu',
  'lug',
  'ago',
  'set',
  'ott',
  'nov',
  'dic',
];
