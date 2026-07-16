import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
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

const _sliceColors = [
  Color(0xFFFF6F61),
  Color(0xFF17A2AE),
  Color(0xFF8A68D6),
  Color(0xFFE0A800),
  Color(0xFF2E9E6B),
  Color(0xFF8B93A1),
];

class _CategoryDonut extends ConsumerWidget {
  const _CategoryDonut({required this.month});

  final DateTime month;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final rows =
        ref.watch(expensesByCategoryProvider(month)).valueOrNull ?? const [];
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    if (rows.isEmpty) {
      return Text(
        l10n.noStatsData,
        style: TextStyle(color: palette.muted, fontSize: 12),
      );
    }

    final total = rows.fold(0, (s, r) => s + r.totalCents);
    // Le prime 5 categorie + "altro" aggregato.
    final top = rows.take(5).toList();
    final restCents = rows.skip(5).fold(0, (s, r) => s + r.totalCents);

    String nameOf(String? id) =>
        categories.where((c) => c.id == id).firstOrNull?.name ?? '—';

    return Row(
      children: [
        SizedBox(
          width: 110,
          height: 110,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 34,
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
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                formatCents(total),
                style: moneyStyle(
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 6),
              for (final (i, r) in top.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _sliceColors[i % _sliceColors.length],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          nameOf(r.categoryId),
                          style: TextStyle(fontSize: 11, color: palette.muted),
                        ),
                      ),
                      Text(
                        formatCents(r.totalCents),
                        style: moneyStyle(
                          size: 11,
                          weight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
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
    final palette = context.nipay;
    final series =
        ref.watch(monthlySeriesProvider(month)).valueOrNull ?? const [];
    if (series.isEmpty || series.every((m) => m.expenseCents == 0)) {
      return Text(
        l10n.noStatsData,
        style: TextStyle(color: palette.muted, fontSize: 12),
      );
    }

    return SizedBox(
      height: 120,
      child: BarChart(
        BarChartData(
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
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      _monthShort[m.month - 1],
                      style: TextStyle(fontSize: 9, color: palette.muted),
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
                    width: 18,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(5),
                    ),
                    color: i == series.length - 1
                        ? NipayColors.coral
                        : NipayColors.coral.withValues(alpha: .35),
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
    final totals = ref.watch(statsTotalsProvider(month)).valueOrNull;
    final income = totals?.incomeCents ?? 0;
    final expense = totals?.expenseCents ?? 0;

    Widget kpi(String label, int cents, Color color, {bool signed = true}) =>
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: palette.surface2,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 10, color: palette.muted),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  child: Text(
                    formatCents(cents, signed: signed),
                    style: moneyStyle(size: 14, color: color),
                  ),
                ),
              ],
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
    final palette = context.nipay;
    final budgets = ref.watch(budgetsProvider).valueOrNull ?? const <Budget>[];
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    if (budgets.isEmpty) {
      return Text(
        l10n.noItems,
        style: TextStyle(color: palette.muted, fontSize: 12),
      );
    }
    return Column(
      children: [
        for (final (i, b) in budgets.indexed) ...[
          if (i > 0) const SizedBox(height: 10),
          BudgetProgressBar(
            budget: b,
            category: categories.where((c) => c.id == b.categoryId).firstOrNull,
          ),
        ],
      ],
    );
  }
}

const _monthShort = [
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
