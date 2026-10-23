import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../l10n/app_localizations.dart';
import 'transaction_detail_sheet.dart';

class TransactionTile extends ConsumerWidget {
  const TransactionTile({super.key, required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = context.nipay;
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(activeWalletProvider)?.currency ?? 'EUR';
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final category = transaction.categoryId == null
        ? null
        : categories.where((c) => c.id == transaction.categoryId).firstOrNull;

    final (amountColor, amountText) = switch (transaction.type) {
      TransactionType.expense => (
        palette.expense,
        formatCents(
          -transaction.amountCents,
          currency: currency,
          symbolOnly: true,
        ),
      ),
      TransactionType.income => (
        palette.income,
        formatCents(
          transaction.amountCents,
          currency: currency,
          signed: true,
          symbolOnly: true,
        ),
      ),
      TransactionType.transfer => (
        palette.transfer,
        formatCents(
          transaction.amountCents,
          currency: currency,
          symbolOnly: true,
        ),
      ),
      TransactionType.friendOut => (
        palette.transfer,
        formatCents(
          -transaction.amountCents,
          currency: currency,
          symbolOnly: true,
        ),
      ),
      TransactionType.friendIn => (
        palette.transfer,
        formatCents(
          transaction.amountCents,
          currency: currency,
          signed: true,
          symbolOnly: true,
        ),
      ),
    };

    final badge = switch (transaction.type) {
      TransactionType.transfer => IconBadge(
        icon: Icons.swap_horiz_rounded,
        color: palette.transfer,
      ),
      TransactionType.friendOut || TransactionType.friendIn => IconBadge(
        icon: Icons.group_outlined,
        color: palette.transfer,
      ),
      _ => IconBadge(
        emoji: category?.icon ?? '📦',
        color: category == null
            ? palette.muted
            : colorFromHex(category.colorHex),
      ),
    };
    final date = MaterialLocalizations.of(
      context,
    ).formatShortMonthDay(transaction.date);

    return ListTile(
      onTap: () => showTransactionDetailSheet(context, transaction),
      leading: badge,
      title: Text(
        transaction.description.isEmpty
            ? (category?.displayName(l10n) ?? '—')
            : transaction.description,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${category?.displayName(l10n) ?? ''}${category != null ? ' · ' : ''}$date',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        amountText,
        style: moneyStyle(size: 15, color: amountColor),
      ),
    );
  }
}
