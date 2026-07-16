import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../l10n/app_localizations.dart';
import 'transaction_tile.dart';

class TransactionsScreen extends ConsumerStatefulWidget {
  const TransactionsScreen({super.key});

  @override
  ConsumerState<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends ConsumerState<TransactionsScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  String _query = '';
  String? _walletId;
  String? _categoryId;

  void _shiftMonth(int delta) =>
      setState(() => _month = DateTime(_month.year, _month.month + delta));

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    // MVP: filtro client-side sulle ultime transazioni; query dedicata in M6.
    final all =
        ref.watch(recentTransactionsProvider).valueOrNull ??
        const <Transaction>[];
    final inMonth = all.where(
      (t) =>
          t.date.year == _month.year &&
          t.date.month == _month.month &&
          (_walletId == null ||
              t.walletId == _walletId ||
              t.walletToId == _walletId) &&
          (_categoryId == null || t.categoryId == _categoryId) &&
          (_query.isEmpty ||
              t.description.toLowerCase().contains(_query.toLowerCase())),
    );

    // Raggruppa per giorno, più recente prima.
    final byDay = <DateTime, List<Transaction>>{};
    for (final t in inMonth) {
      final day = DateTime(t.date.year, t.date.month, t.date.day);
      byDay.putIfAbsent(day, () => []).add(t);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    final monthLabel = '${_monthNames[_month.month - 1]} ${_month.year}';

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.transactionsTab,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                TextField(
                  decoration: InputDecoration(
                    hintText: l10n.searchTransactions,
                    prefixIcon: const Icon(Icons.search, size: 20),
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _FilterDropdown<String>(
                        value: _walletId,
                        nullLabel: l10n.allWallets,
                        items: [
                          for (final w
                              in ref.watch(walletsProvider).valueOrNull ??
                                  const <Wallet>[])
                            (w.id, w.name),
                        ],
                        onChanged: (v) => setState(() => _walletId = v),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _FilterDropdown<String>(
                        value: _categoryId,
                        nullLabel: l10n.allCategories,
                        items: [
                          for (final c
                              in ref.watch(categoriesProvider).valueOrNull ??
                                  const <Category>[])
                            (c.id, '${c.icon} ${c.name}'),
                        ],
                        onChanged: (v) => setState(() => _categoryId = v),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _shiftMonth(-1),
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          monthLabel,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _shiftMonth(1),
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: days.isEmpty
                ? Center(
                    child: Text(
                      l10n.noTransactions,
                      style: TextStyle(color: palette.muted),
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                    children: [
                      for (final day in days) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(2, 14, 2, 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${day.day} ${_monthNames[day.month - 1]}',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontSize: 13),
                                ),
                              ),
                              Text(
                                formatCents(_dayNet(byDay[day]!), signed: true),
                                style: moneyStyle(
                                  size: 11,
                                  weight: FontWeight.w500,
                                  color: palette.muted,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            children: [
                              for (final (i, t) in byDay[day]!.indexed) ...[
                                if (i > 0) const Divider(),
                                TransactionTile(transaction: t),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

/// Dropdown compatto per i filtri: la voce null è "tutti".
class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.value,
    required this.nullLabel,
    required this.items,
    required this.onChanged,
  });

  final T? value;
  final String nullLabel;
  final List<(T, String)> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T?>(
      initialValue: value,
      isDense: true,
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      style: TextStyle(
        fontSize: 12,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      items: [
        DropdownMenuItem<T?>(value: null, child: Text(nullLabel)),
        for (final (v, label) in items)
          DropdownMenuItem<T?>(
            value: v,
            child: Text(label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

int _dayNet(List<Transaction> txs) {
  var net = 0;
  for (final t in txs) {
    if (t.type == TransactionType.expense) net -= t.amountCents;
    if (t.type == TransactionType.income) net += t.amountCents;
  }
  return net;
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
