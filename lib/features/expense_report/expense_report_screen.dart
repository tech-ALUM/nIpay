import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/export/expense_report_pdf.dart';
import '../../data/repositories/expense_report_repository.dart';
import '../../l10n/app_localizations.dart';
import '../transactions/transaction_tile.dart';

/// Spese flaggate nel periodo selezionato.
final _flaggedProvider =
    FutureProvider.family<List<FlaggedExpense>, (DateTime, DateTime)>((
      ref,
      range,
    ) {
      ref.watch(recentTransactionsProvider);
      final active = ref.watch(activeWalletProvider);
      if (active == null) return Future.value(const <FlaggedExpense>[]);
      return ref
          .watch(expenseReportRepositoryProvider)
          .flaggedInRange(walletId: active.id, from: range.$1, to: range.$2);
    });

class ExpenseReportScreen extends ConsumerStatefulWidget {
  const ExpenseReportScreen({super.key});

  @override
  ConsumerState<ExpenseReportScreen> createState() =>
      _ExpenseReportScreenState();
}

class _ExpenseReportScreenState extends ConsumerState<ExpenseReportScreen> {
  late DateTime _from;
  late DateTime _to; // esclusivo

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month);
    _to = DateTime(now.year, now.month + 1);
  }

  String _d(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to.subtract(const Duration(days: 1)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (isFrom) {
        _from = DateTime(picked.year, picked.month, picked.day);
      } else {
        _to = DateTime(picked.year, picked.month, picked.day + 1);
      }
    });
  }

  Future<void> _exportPdf(List<FlaggedExpense> rows) async {
    final active = ref.read(activeWalletProvider);
    if (active == null || rows.isEmpty) return;
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final costCenters = ref.read(costCentersProvider).valueOrNull ?? [];
    final appDir = await ref.read(appDirProvider.future);
    final attachRepo = ref.read(attachmentRepositoryProvider);

    final attachmentsByTx = <String, List<Uint8List>>{};
    for (final r in rows) {
      final list = await attachRepo.listOf(r.transaction.id);
      final images = <Uint8List>[];
      for (final a in list) {
        final f = File('${appDir.path}/${a.relativePath}');
        if (await f.exists()) images.add(await f.readAsBytes());
      }
      if (images.isNotEmpty) attachmentsByTx[r.transaction.id] = images;
    }

    final bytes = await buildExpenseReportPdf(
      walletName: active.name,
      from: _from,
      to: _to,
      rows: rows,
      categoriesById: {for (final c in categories) c.id: c},
      costCentersById: {for (final c in costCenters) c.id: c},
      attachmentsByTx: attachmentsByTx,
    );
    final tmp = await getTemporaryDirectory();
    final out = File(
      '${tmp.path}/nota-spese-${_from.year}${_from.month.toString().padLeft(2, "0")}${_from.day.toString().padLeft(2, "0")}.pdf',
    );
    await out.writeAsBytes(bytes);
    await SharePlus.instance.share(ShareParams(files: [XFile(out.path)]));
  }

  Future<void> _createReport() async {
    final l10n = AppLocalizations.of(context)!;
    final active = ref.read(activeWalletProvider);
    if (active == null) return;
    final controller = TextEditingController(
      text: 'NS ${_d(_from)} - ${_d(_to.subtract(const Duration(days: 1)))}',
    );
    final name = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.createReport),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: InputDecoration(labelText: l10n.reportName),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;
    await ref
        .read(expenseReportRepositoryProvider)
        .createReport(walletId: active.id, name: name, from: _from, to: _to);
    ref.invalidate(expenseReportsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final rows =
        ref.watch(_flaggedProvider((_from, _to))).valueOrNull ??
        const <FlaggedExpense>[];
    final reports = ref.watch(expenseReportsProvider).valueOrNull ?? [];
    final total = rows.fold(0, (s, r) => s + r.transaction.amountCents);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.expenseReport)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event, size: 16),
                  label: Text(
                    '${l10n.fromDate} ${_d(_from)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.event, size: 16),
                  label: Text(
                    '${l10n.toDate} ${_d(_to.subtract(const Duration(days: 1)))}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  onPressed: () => _pickDate(false),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${l10n.flaggedExpenses}: ${rows.length}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                formatCents(total),
                style: moneyStyle(
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (rows.isEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  l10n.noStatsData,
                  style: TextStyle(color: palette.muted),
                ),
              ),
            )
          else
            Card(
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  for (final (i, r) in rows.indexed) ...[
                    if (i > 0) const Divider(),
                    TransactionTile(transaction: r.transaction),
                  ],
                ],
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  key: const Key('exportPdfButton'),
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: Text(l10n.exportPdf),
                  onPressed: rows.isEmpty ? null : () => _exportPdf(rows),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  key: const Key('createReportButton'),
                  icon: const Icon(Icons.assignment_add, size: 18),
                  label: Text(l10n.createReport),
                  onPressed: rows.isEmpty ? null : _createReport,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            l10n.reportArchive,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final r in reports)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                dense: true,
                title: Text(r.name, style: const TextStyle(fontSize: 13)),
                subtitle: Text(
                  '${_d(r.dateFrom)} - ${_d(r.dateTo.subtract(const Duration(days: 1)))} · ${_statusLabel(l10n, r.status)}',
                  style: TextStyle(fontSize: 11, color: palette.muted),
                ),
                trailing: _statusAction(context, r),
              ),
            ),
        ],
      ),
    );
  }

  String _statusLabel(AppLocalizations l10n, ExpenseReportStatus s) =>
      switch (s) {
        ExpenseReportStatus.draft => l10n.statusDraft,
        ExpenseReportStatus.sent => l10n.statusSent,
        ExpenseReportStatus.reimbursed => l10n.statusReimbursed,
      };

  Widget _statusAction(BuildContext context, ExpenseReport r) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(expenseReportRepositoryProvider);
    return switch (r.status) {
      ExpenseReportStatus.draft => TextButton(
        child: Text(l10n.markSent, style: const TextStyle(fontSize: 11)),
        onPressed: () async {
          await repo.setStatus(r.id, ExpenseReportStatus.sent);
          ref.invalidate(expenseReportsProvider);
        },
      ),
      ExpenseReportStatus.sent => TextButton(
        child: Text(l10n.markReimbursed, style: const TextStyle(fontSize: 11)),
        onPressed: () async {
          // Registra l'entrata di rimborso e collegala alla nota.
          final active = ref.read(activeWalletProvider);
          if (active == null) return;
          final flagged = await repo.flaggedInRange(
            walletId: active.id,
            from: r.dateFrom,
            to: r.dateTo,
          );
          final amount = flagged
              .where((f) => f.entry.reportId == r.id && f.entry.reimbursable)
              .fold(0, (s, f) => s + f.transaction.amountCents);
          final txId = await ref
              .read(transactionRepositoryProvider)
              .createIncome(
                walletId: active.id,
                amountCents: amount == 0 ? 1 : amount,
                date: DateTime.now(),
                description: 'Rimborso: ${r.name}',
              );
          await repo.linkReimbursement(r.id, txId);
          ref.invalidate(expenseReportsProvider);
        },
      ),
      ExpenseReportStatus.reimbursed => Icon(
        Icons.check_circle,
        size: 18,
        color: context.nipay.income,
      ),
    };
  }
}
