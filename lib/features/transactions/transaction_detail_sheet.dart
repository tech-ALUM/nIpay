import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../l10n/app_localizations.dart';

Future<void> showTransactionDetailSheet(
  BuildContext context,
  Transaction transaction,
) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) => _TransactionDetailSheet(transaction: transaction),
);

class _TransactionDetailSheet extends ConsumerWidget {
  const _TransactionDetailSheet({required this.transaction});

  final Transaction transaction;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final t = transaction;
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final category = categories.where((c) => c.id == t.categoryId).firstOrNull;
    final attachments =
        ref.watch(attachmentsOfProvider(t.id)).valueOrNull ?? const [];
    final appDir = ref.watch(appDirProvider).valueOrNull;

    final (color, amountText) = switch (t.type) {
      TransactionType.expense => (palette.expense, formatCents(-t.amountCents)),
      TransactionType.income => (
        palette.income,
        formatCents(t.amountCents, signed: true),
      ),
      TransactionType.transfer => (
        palette.transfer,
        formatCents(t.amountCents),
      ),
    };

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.description.isEmpty
                ? (category?.name ?? l10n.transactionDetail)
                : t.description,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 6),
          Text(amountText, style: moneyStyle(size: 30, color: color)),
          const SizedBox(height: 4),
          Text(
            '${category != null ? '${category.icon} ${category.name} · ' : ''}'
            '${t.date.day}/${t.date.month}/${t.date.year}',
            style: TextStyle(fontSize: 12, color: palette.muted),
          ),
          if (attachments.isNotEmpty && appDir != null) ...[
            const SizedBox(height: 16),
            Text(
              l10n.attachments,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 90,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: attachments.length,
                separatorBuilder: (_, i) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  final file = File(
                    '${appDir.path}/${attachments[i].relativePath}',
                  );
                  return GestureDetector(
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => Dialog(
                        child: InteractiveViewer(child: Image.file(file)),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        file,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 90,
                          height: 90,
                          color: palette.surface2,
                          child: const Icon(Icons.broken_image, size: 20),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.delete_outline, size: 18),
              label: Text(l10n.deleteTransaction),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              onPressed: () async {
                await ref.read(transactionRepositoryProvider).softDelete(t.id);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }
}
