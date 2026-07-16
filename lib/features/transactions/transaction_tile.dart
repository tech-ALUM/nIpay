import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import 'transaction_detail_sheet.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.nipay;
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final category = transaction.categoryId == null
        ? null
        : categories.where((c) => c.id == transaction.categoryId).firstOrNull;

    final (amountColor, amountText) = switch (transaction.type) {
      TransactionType.expense => (
        palette.expense,
        formatCents(-transaction.amountCents),
      ),
      TransactionType.income => (
        palette.income,
        formatCents(transaction.amountCents, signed: true),
      ),
      TransactionType.transfer => (
        palette.transfer,
        formatCents(transaction.amountCents),
      ),
    };

    final icon = switch (transaction.type) {
      TransactionType.transfer => '⇄',
      _ => category?.icon ?? '📦',
    };

    return ListTile(
      dense: true,
      onTap: () => showTransactionDetailSheet(context, transaction),
      leading: Container(
        width: 38,
        height: 38,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: amountColor.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(icon, style: const TextStyle(fontSize: 17)),
      ),
      title: Text(
        transaction.description.isEmpty
            ? (category?.name ?? '—')
            : transaction.description,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        '${category?.name ?? ''}${category != null ? ' · ' : ''}'
        '${transaction.date.day}/${transaction.date.month}',
        style: TextStyle(fontSize: 11, color: palette.muted),
      ),
      trailing: Text(
        amountText,
        style: moneyStyle(size: 13, color: amountColor),
      ),
    );
  }
}
