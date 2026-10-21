import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
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
    final usedTypes = cards.map((c) => c.type).toSet();

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final padding = centeredPadding(
            constraints.maxWidth,
            bottom: kFabClearance,
          );
          return ReorderableListView(
            padding: padding,
            header: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PageHeader(l10n.statsTab),
                Center(
                  child: MonthSwitcher(
                    month: month,
                    onChanged: (m) =>
                        ref.read(statsMonthProvider.notifier).state = m,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
            onReorderItem: (oldIndex, newIndex) {
              if (oldIndex >= cards.length) return;
              ref
                  .read(dashboardRepositoryProvider)
                  .moveCard(cards[oldIndex].id, newIndex);
            },
            footer: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: _AddCardButton(
                emptyHint: cards.isEmpty ? l10n.emptyDashboard : null,
                usedTypes: usedTypes,
              ),
            ),
            children: [
              for (final card in cards)
                Padding(
                  key: ValueKey(card.id),
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 6, 6, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // La card si trascina con una pressione lunga
                              // ovunque; la maniglia lo suggerisce.
                              ExcludeSemantics(
                                child: Icon(
                                  Icons.drag_indicator,
                                  size: 18,
                                  color: palette.muted,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Semantics(
                                  header: true,
                                  child: Text(
                                    cardTitle(l10n, card.type),
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: MaterialLocalizations.of(
                                  context,
                                ).deleteButtonTooltip,
                                icon: Icon(
                                  Icons.close,
                                  size: 20,
                                  color: palette.muted,
                                ),
                                onPressed: () => ref
                                    .read(dashboardRepositoryProvider)
                                    .removeCard(card.id),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(right: 10, top: 4),
                            child: StatCardBody(type: card.type, month: month),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _AddCardButton extends ConsumerWidget {
  const _AddCardButton({this.emptyHint, required this.usedTypes});

  final String? emptyHint;
  final Set<String> usedTypes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final availableTypes = kCardTypes
        .where((t) => !usedTypes.contains(t))
        .toList();
    // Ogni tipo di card è unico in dashboard: se sono già tutti presenti
    // non c'è altro da aggiungere.
    if (availableTypes.isEmpty) return const SizedBox.shrink();
    final button = Semantics(
      button: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Theme.of(context).colorScheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const Key('addCardButton'),
          onTap: () async {
            final type = await showDialog<String>(
              context: context,
              builder: (dialogContext) => SimpleDialog(
                title: Text(l10n.addCard),
                children: [
                  for (final t in availableTypes)
                    SimpleDialogOption(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 14,
                      ),
                      onPressed: () => Navigator.of(dialogContext).pop(t),
                      child: Row(
                        children: [
                          Icon(_cardIcon(t), color: palette.muted),
                          const SizedBox(width: 16),
                          Expanded(child: Text(cardTitle(l10n, t))),
                        ],
                      ),
                    ),
                ],
              ),
            );
            final active = ref.read(activeWalletProvider);
            if (type != null && active != null) {
              await ref
                  .read(dashboardRepositoryProvider)
                  .addCard(walletId: active.id, type: type);
            }
          },
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 56),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.addCard,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    if (emptyHint == null) return button;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            EmptyState(
              icon: Icons.dashboard_customize_outlined,
              message: emptyHint!,
              padding: const EdgeInsets.fromLTRB(8, 28, 8, 20),
            ),
            button,
          ],
        ),
      ),
    );
  }
}

IconData _cardIcon(String type) => switch (type) {
  'categoryDonut' => Icons.donut_large,
  'trend' => Icons.bar_chart,
  'cashflow' => Icons.swap_vert,
  'budget' => Icons.savings_outlined,
  _ => Icons.dashboard_outlined,
};
