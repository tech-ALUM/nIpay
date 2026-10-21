import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../data/db/app_database.dart';
import '../../l10n/app_localizations.dart';
import '../budgets/budget_progress_bar.dart';

/// Corpo di una card statistica, scelto in base al tipo persistito.
class StatCardBody extends ConsumerWidget {
  const StatCardBody({super.key, required this.type, required this.month});

  final String type;
  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (type) {
      'categoryDonut' => _CategoryDonut(month: month),
      'trend' => _TrendBars(month: month),
      'cashflow' => _CashflowKpis(month: month),
      'budget' => const _BudgetList(),
      _ => const SizedBox.shrink(),
    };
  }
}

/// Fette del donut: prima i colori brand (coral, teal), poi tinte ben
/// distinguibili tra loro; l'ultima (grigia) è sempre "altro".
const _sliceColors = [
  NipayColors.coral,
  Color(0xFF17A2AE),
  Color(0xFF8A68D6),
  NipayColors.warn,
  Color(0xFF2E9E6B),
  Color(0xFF8B93A1),
];

class _CategoryDonut extends ConsumerWidget {
  const _CategoryDonut({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(activeWalletProvider)?.currency ?? 'EUR';
    final rows =
        ref.watch(expensesByCategoryProvider(month)).valueOrNull ?? const [];
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    if (rows.isEmpty) return _NoData(l10n.noStatsData);

    final total = rows.fold(0, (s, r) => s + r.totalCents);
    // Le prime 5 categorie + "altro" aggregato.
    final top = rows.take(5).toList();
    final restCents = rows.skip(5).fold(0, (s, r) => s + r.totalCents);

    String nameOf(String? id) =>
        categories.where((c) => c.id == id).firstOrNull?.displayName(l10n) ??
        '—';

    return Row(
      children: [
        ExcludeSemantics(
          child: SizedBox(
            width: 120,
            height: 120,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 36,
                sections: [
                  for (final (i, r) in top.indexed)
                    PieChartSectionData(
                      value: r.totalCents.toDouble(),
                      color: _sliceColors[i % _sliceColors.length],
                      showTitle: false,
                      radius: 18,
                    ),
                  if (restCents > 0)
                    PieChartSectionData(
                      value: restCents.toDouble(),
                      color: _sliceColors.last,
                      showTitle: false,
                      radius: 18,
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatCents(total, currency: currency),
                style: moneyStyle(
                  size: 18,
                  weight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              for (final (i, r) in top.indexed)
                _LegendRow(
                  color: _sliceColors[i % _sliceColors.length],
                  label: nameOf(r.categoryId),
                  value: formatCents(r.totalCents, currency: currency),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TrendBars extends ConsumerWidget {
  const _TrendBars({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final series =
        ref.watch(monthlySeriesProvider(month)).valueOrNull ?? const [];
    if (series.isEmpty || series.every((m) => m.expenseCents == 0)) {
      return _NoData(l10n.noStatsData);
    }
    final currency = ref.watch(activeWalletProvider)?.currency ?? 'EUR';
    final scheme = Theme.of(context).colorScheme;

    return SizedBox(
      height: 140,
      child: BarChart(
        BarChartData(
          // Tocca una barra: importo formattato nella valuta del portafoglio.
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => scheme.inverseSurface,
              tooltipBorderRadius: BorderRadius.circular(8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) => BarTooltipItem(
                '${formatMonthShort(context, DateTime(series[group.x].year, series[group.x].month))}\n'
                '${formatCents(series[group.x].expenseCents, currency: currency)}',
                moneyStyle(size: 12.5, color: scheme.onInverseSurface),
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          gridData: const FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final m = series[v.toInt()];
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      formatMonthShort(context, DateTime(m.year, m.month)),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: [
            for (final (i, m) in series.indexed)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: m.expenseCents / 100,
                    width: 20,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(6),
                    ),
                    // Mese selezionato pieno, gli altri attenuati.
                    color: i == series.length - 1
                        ? NipayColors.coral
                        : NipayColors.coral.withValues(alpha: .4),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _CashflowKpis extends ConsumerWidget {
  const _CashflowKpis({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final currency = ref.watch(activeWalletProvider)?.currency ?? 'EUR';
    final totals = ref.watch(statsTotalsProvider(month)).valueOrNull;
    final income = totals?.incomeCents ?? 0;
    final expense = totals?.expenseCents ?? 0;

    Widget kpi(String label, int cents, Color color, {bool signed = true}) =>
        Expanded(
          child: MergeSemantics(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: palette.surface2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                  const SizedBox(height: 4),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      formatCents(cents, currency: currency, signed: signed),
                      style: moneyStyle(size: 16, color: color),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

    return Row(
      children: [
        kpi(l10n.income, income, palette.income),
        const SizedBox(width: 10),
        kpi(l10n.expense, -expense, palette.expense, signed: false),
        const SizedBox(width: 10),
        kpi(
          l10n.netLabel,
          income - expense,
          Theme.of(context).colorScheme.onSurface,
        ),
      ],
    );
  }
}

class _BudgetList extends ConsumerWidget {
  const _BudgetList();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final budgets = ref.watch(budgetsProvider).valueOrNull ?? const <Budget>[];
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    if (budgets.isEmpty) return _NoData(l10n.noItems);
    return Column(
      children: [
        for (final (i, b) in budgets.indexed) ...[
          if (i > 0) const SizedBox(height: 14),
          BudgetProgressBar(
            budget: b,
            category: categories.where((c) => c.id == b.categoryId).firstOrNull,
          ),
        ],
      ],
    );
  }
}

/// Messaggio "nessun dato" dentro una card statistica.
class _NoData extends StatelessWidget {
  const _NoData(this.message);

  final String message;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Icon(Icons.insights_outlined, size: 20, color: context.nipay.muted),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: context.nipay.muted),
          ),
        ),
      ],
    ),
  );
}

/// Voce di legenda del donut: pallino colore, categoria, importo.
class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            value,
            style: moneyStyle(
              size: 12.5,
              weight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    ),
  );
}
