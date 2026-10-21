import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/attachment_files.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../l10n/app_localizations.dart';
import 'add_transaction_sheet.dart';

Future<void> showTransactionDetailSheet(
  BuildContext context,
  Transaction transaction,
) => showAppSheet<void>(
  context,
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
    final currency = ref.watch(activeWalletProvider)?.currency ?? 'EUR';
    final categories =
        ref.watch(categoriesProvider).valueOrNull ?? const <Category>[];
    final category = categories.where((c) => c.id == t.categoryId).firstOrNull;
    final attachments =
        ref.watch(attachmentsOfProvider(t.id)).valueOrNull ?? const [];
    final appDir = ref.watch(appDirProvider).valueOrNull;
    // Solo path di allegato generati dall'app (SECURITY_AUDIT NIP-18).
    final files = appDir == null
        ? const <File>[]
        : [
            for (final a in attachments)
              ?attachmentFile(appDir, a.relativePath),
          ];

    final (color, amountText, typeLabel) = switch (t.type) {
      TransactionType.expense => (
        palette.expense,
        formatCents(-t.amountCents, currency: currency),
        l10n.expense,
      ),
      TransactionType.income => (
        palette.income,
        formatCents(t.amountCents, currency: currency, signed: true),
        l10n.income,
      ),
      TransactionType.transfer => (
        palette.transfer,
        formatCents(t.amountCents, currency: currency),
        l10n.transfer,
      ),
    };

    return SheetScaffold(
      title: t.description.isEmpty
          ? (category?.displayName(l10n) ?? l10n.transactionDetail)
          : t.description,
      actions: [
        OutlinedButton.icon(
          icon: const Icon(Icons.delete_outline, size: 20),
          label: Text(l10n.delete),
          style: OutlinedButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () async {
            final confirmed = await confirmDeletion(
              context,
              title: l10n.deleteTransaction,
            );
            if (!confirmed) return;
            await ref.read(transactionRepositoryProvider).softDelete(t.id);
            if (context.mounted) Navigator.of(context).pop();
          },
        ),
        FilledButton.icon(
          key: const Key('editTransactionButton'),
          icon: const Icon(Icons.edit_outlined, size: 20),
          label: Text(l10n.edit),
          onPressed: () async {
            final entry = await ref
                .read(expenseReportRepositoryProvider)
                .dataOf(t.id);
            if (!context.mounted) return;
            Navigator.of(context).pop();
            await showAddTransactionSheet(
              context,
              existing: t,
              existingEntry: entry,
            );
          },
        ),
      ],
      children: [
        MergeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                typeLabel,
                style: Theme.of(
                  context,
                ).textTheme.labelMedium?.copyWith(color: palette.muted),
              ),
              const SizedBox(height: 2),
              Text(amountText, style: moneyStyle(size: 32, color: color)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: palette.line),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              if (category != null) ...[
                _DetailRow(
                  leading: IconBadge(
                    emoji: category.icon,
                    color: colorFromHex(category.colorHex),
                    size: 32,
                  ),
                  label: l10n.category,
                  value: category.displayName(l10n),
                ),
                const Divider(indent: 16, endIndent: 16),
              ],
              _DetailRow(
                leading: IconBadge(
                  icon: Icons.event_outlined,
                  color: palette.muted,
                  size: 32,
                ),
                label: l10n.date,
                value: MaterialLocalizations.of(context).formatFullDate(t.date),
              ),
            ],
          ),
        ),
        if (files.isNotEmpty) ...[
          FieldLabel(l10n.attachments),
          SizedBox(
            height: 96,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: files.length,
              separatorBuilder: (_, i) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final file = files[i];
                return Semantics(
                  button: true,
                  label: '${l10n.attachments} ${i + 1}',
                  excludeSemantics: true,
                  child: Material(
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => showDialog<void>(
                        context: context,
                        builder: (_) => Dialog(
                          clipBehavior: Clip.antiAlias,
                          child: InteractiveViewer(child: Image.file(file)),
                        ),
                      ),
                      child: Image.file(
                        file,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 96,
                          height: 96,
                          color: palette.surface2,
                          child: Icon(
                            Icons.broken_image_outlined,
                            color: palette.muted,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.leading,
    required this.label,
    required this.value,
  });

  final Widget leading;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => MergeSemantics(
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          leading,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: Theme.of(context).textTheme.bodySmall),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
