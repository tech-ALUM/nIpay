import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/currencies.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/db/app_database.dart';
import '../../data/db/tables.dart';
import '../../data/services/exchange_rate_service.dart';
import '../../l10n/app_localizations.dart';

Future<String?> _promptNewTag(
  BuildContext context,
  AppLocalizations l10n,
  List<Tag> existingTags,
) {
  final controller = TextEditingController();
  String? error;
  return showDialog<String>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (dialogContext, setState) {
        return AlertDialog(
          title: Text(l10n.newTag),
          content: TextField(
            key: const Key('newTagField'),
            controller: controller,
            autofocus: true,
            onChanged: (_) {
              if (error != null) setState(() => error = null);
            },
            decoration: InputDecoration(
              labelText: l10n.tagName,
              errorText: error,
            ),
            onSubmitted: (v) {
              final name = v.trim();
              if (name.isEmpty) {
                setState(() => error = l10n.tagNameRequired);
                return;
              }
              if (existingTags.any(
                (t) => t.name.toLowerCase() == name.toLowerCase(),
              )) {
                setState(() => error = l10n.tagNameDuplicate);
                return;
              }
              Navigator.of(dialogContext).pop(name);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              key: const Key('tagSaveButton'),
              onPressed: () {
                final name = controller.text.trim();
                if (name.isEmpty) {
                  setState(() => error = l10n.tagNameRequired);
                  return;
                }
                if (existingTags.any(
                  (t) => t.name.toLowerCase() == name.toLowerCase(),
                )) {
                  setState(() => error = l10n.tagNameDuplicate);
                  return;
                }
                Navigator.of(dialogContext).pop(name);
              },
              child: Text(l10n.save),
            ),
          ],
        );
      },
    ),
  );
}

/// [existing] apre il form in modalità modifica (retroattiva).
Future<void> showAddTransactionSheet(
  BuildContext context, {
  Transaction? existing,
  ExpenseReportEntry? existingEntry,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  builder: (_) =>
      _AddTransactionSheet(existing: existing, existingEntry: existingEntry),
);

class _AddTransactionSheet extends ConsumerStatefulWidget {
  const _AddTransactionSheet({this.existing, this.existingEntry});

  final Transaction? existing;
  final ExpenseReportEntry? existingEntry;

  @override
  ConsumerState<_AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<_AddTransactionSheet> {
  final _amount = TextEditingController();
  final _description = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String? _walletToId;
  String? _categoryId;
  DateTime _date = DateTime.now();
  String? _error;
  final Set<String> _selectedTagIds = {};
  Set<String> _originalTagIds = const {};
  final Map<String, String> _fieldValues = {};
  final Map<String, TextEditingController> _fieldControllers = {};
  final List<XFile> _pendingImages = [];
  bool _isExpenseReport = false;
  String? _costCenterId;
  bool _reimbursable = true;
  bool _eInvoice = false;
  String? _currency;
  double? _rate;
  bool _fetchingRate = false;
  String? _rateError;

  bool get _editing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _amount.text = (e.amountCents / 100)
          .toStringAsFixed(2)
          .replaceAll('.', ',');
      _description.text = e.description;
      _type = e.type;
      _categoryId = e.categoryId;
      _date = e.date;
      _currency = e.entryCurrency;
      _loadExistingTags(e.id);
      _loadExistingFieldValues(e.id);
    }
    final entry = widget.existingEntry;
    if (entry != null) {
      _isExpenseReport = true;
      _costCenterId = entry.costCenterId;
      _reimbursable = entry.reimbursable;
      _eInvoice = entry.eInvoice;
    }
    if (_currency != null) _maybeFetchRate();
  }

  /// In modifica, i tag già assegnati non sono altrimenti mai caricati nello
  /// stato: le chip risulterebbero tutte deselezionate anche se la
  /// transazione li ha davvero, dando l'impressione che si siano persi.
  Future<void> _loadExistingTags(String transactionId) async {
    final tags = await ref.read(tagRepositoryProvider).tagsOf(transactionId);
    if (!mounted) return;
    final ids = tags.map((t) => t.id).toSet();
    setState(() {
      _selectedTagIds.addAll(ids);
      _originalTagIds = ids;
    });
  }

  /// Stesso problema dei tag: i valori dei campi custom già impostati non
  /// sono altrimenti mai caricati nello stato in modifica.
  Future<void> _loadExistingFieldValues(String transactionId) async {
    final values = await ref
        .read(customFieldRepositoryProvider)
        .valuesOf(transactionId);
    if (!mounted) return;
    setState(() {
      for (final v in values) {
        _fieldValues[v.fieldId] = v.value;
        // Se il campo (testo/numero) è già stato disegnato prima che questo
        // caricamento asincrono finisse, il controller esiste già e va
        // aggiornato esplicitamente: riassegnare initialValue non basta.
        _fieldControllers[v.fieldId]?.text = v.value;
      }
    });
  }

  @override
  void dispose() {
    _amount.dispose();
    _description.dispose();
    for (final c in _fieldControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Un controller per campo, creato una volta sola (mai dentro build): se
  /// ricreato a ogni rebuild perde la posizione del cursore a ogni tasto.
  TextEditingController _controllerFor(String fieldId) => _fieldControllers
      .putIfAbsent(fieldId, () => TextEditingController(text: _fieldValues[fieldId]));

  /// Recupera il tasso [_currency] → valuta del portafoglio attivo, UNA
  /// volta per cambio di valuta (non ad ogni tasto premuto sull'importo).
  Future<void> _maybeFetchRate() async {
    final target = ref.read(activeWalletProvider)?.currency ?? 'EUR';
    final entry = _currency ?? target;
    if (entry == target) {
      setState(() {
        _rate = null;
        _rateError = null;
      });
      return;
    }
    setState(() {
      _fetchingRate = true;
      _rateError = null;
    });
    try {
      final rate = await ref
          .read(exchangeRateServiceProvider)
          .getRate(from: entry, to: target);
      if (!mounted) return;
      setState(() {
        _rate = rate;
        _fetchingRate = false;
      });
    } on ExchangeRateException catch (e) {
      if (!mounted) return;
      setState(() {
        _rate = null;
        _fetchingRate = false;
        _rateError = e.message;
      });
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    final cents = parseCents(_amount.text);
    final wallets = ref.read(walletsProvider).valueOrNull ?? [];
    final wallet = ref.read(activeWalletProvider);
    final walletId = wallet?.id;
    if (cents == null || cents <= 0 || walletId == null) {
      setState(() => _error = l10n.invalidAmount);
      return;
    }

    // Conversione entry currency → valuta del portafoglio, se diverse.
    final entryCurrency = _currency ?? wallet!.currency;
    var amountCentsToSave = cents;
    String? persistedEntryCurrency;
    int? persistedEntryAmountCents;
    if (entryCurrency != wallet!.currency) {
      double rate;
      try {
        rate =
            _rate ??
            await ref
                .read(exchangeRateServiceProvider)
                .getRate(from: entryCurrency, to: wallet.currency);
      } on ExchangeRateException catch (e) {
        setState(() => _error = e.message);
        return;
      }
      amountCentsToSave = (cents * rate).round();
      persistedEntryCurrency = entryCurrency;
      persistedEntryAmountCents = cents;
      // Importo minimo convertito a un tasso molto basso può arrotondare a
      // zero (es. 0,01 di una valuta debole → 0,00 nella valuta forte): il
      // repository richiede amountCents > 0, quindi blocchiamo qui con lo
      // stesso errore di importo non valido invece di far fallire l'insert.
      if (amountCentsToSave <= 0) {
        setState(() => _error = l10n.invalidAmount);
        return;
      }
    }

    final repo = ref.read(transactionRepositoryProvider);
    final String txId;
    if (_editing) {
      txId = widget.existing!.id;
      await repo.updateTransaction(
        txId,
        amountCents: amountCentsToSave,
        date: _date,
        categoryId: _categoryId,
        description: _description.text.trim(),
      );
    } else {
      switch (_type) {
        case TransactionType.expense:
          txId = await repo.createExpense(
            walletId: walletId,
            amountCents: amountCentsToSave,
            date: _date,
            categoryId: _categoryId,
            description: _description.text.trim(),
            entryCurrency: persistedEntryCurrency,
            entryAmountCents: persistedEntryAmountCents,
          );
        case TransactionType.income:
          txId = await repo.createIncome(
            walletId: walletId,
            amountCents: amountCentsToSave,
            date: _date,
            categoryId: _categoryId,
            description: _description.text.trim(),
            entryCurrency: persistedEntryCurrency,
            entryAmountCents: persistedEntryAmountCents,
          );
        case TransactionType.transfer:
          final toId =
              _walletToId ??
              wallets.where((w) => w.id != walletId).firstOrNull?.id;
          if (toId == null) {
            setState(() => _error = l10n.invalidAmount);
            return;
          }
          final toWallet = wallets.firstWhere((w) => w.id == toId);
          // Cross-valuta: converte ANCHE l'importo addebitato (valuta del
          // portafoglio "Da") nella valuta del portafoglio "A", per il credito.
          int? amountCentsTo;
          if (toWallet.currency != wallet.currency) {
            try {
              final rateTo = await ref
                  .read(exchangeRateServiceProvider)
                  .getRate(from: wallet.currency, to: toWallet.currency);
              amountCentsTo = (amountCentsToSave * rateTo).round();
              // Come sopra: un accredito arrotondato a zero significherebbe
              // addebitare "Da" senza accreditare nulla su "A" — soldi persi
              // silenziosamente. Blocchiamo prima di salvare.
              if (amountCentsTo <= 0) {
                setState(() => _error = l10n.invalidAmount);
                return;
              }
            } on ExchangeRateException catch (e) {
              setState(() => _error = e.message);
              return;
            }
          }
          txId = await repo.createTransfer(
            fromWalletId: walletId,
            toWalletId: toId,
            amountCents: amountCentsToSave,
            date: _date,
            description: _description.text.trim(),
            entryCurrency: persistedEntryCurrency,
            entryAmountCents: persistedEntryAmountCents,
            amountCentsTo: amountCentsTo,
          );
      }
    }

    // Dati nota spese: upsert se flaggata, clear se il flag è stato tolto.
    final expRepo = ref.read(expenseReportRepositoryProvider);
    if (_type == TransactionType.expense && _isExpenseReport) {
      await expRepo.setExpenseData(
        transactionId: txId,
        costCenterId: _costCenterId,
        reimbursable: _reimbursable,
        eInvoice: _eInvoice,
      );
    } else if (_editing && widget.existingEntry != null) {
      await expRepo.clearExpenseData(txId);
    }

    final tagRepo = ref.read(tagRepositoryProvider);
    for (final tagId in _selectedTagIds.difference(_originalTagIds)) {
      await tagRepo.tagTransaction(txId, tagId);
    }
    for (final tagId in _originalTagIds.difference(_selectedTagIds)) {
      await tagRepo.untagTransaction(txId, tagId);
    }
    // txIdsWithTagProvider si aggiorna da solo solo quando cambiano le
    // transazioni, non quando cambia solo l'associazione tag↔transazione:
    // invalidarlo esplicitamente per i tag toccati, altrimenti il filtro
    // per tag in transactions_screen.dart resta con dati stantii.
    for (final tagId in _selectedTagIds.union(_originalTagIds)) {
      ref.invalidate(txIdsWithTagProvider(tagId));
    }
    // Salva ogni campo toccato, anche se svuotato: altrimenti cancellare il
    // testo in modifica non rimuoverebbe mai il vecchio valore dal DB.
    final fieldRepo = ref.read(customFieldRepositoryProvider);
    for (final entry in _fieldValues.entries) {
      await fieldRepo.setValue(
        transactionId: txId,
        fieldId: entry.key,
        value: entry.value.trim(),
      );
    }

    // Copia le foto nella dir dell'app e registra gli allegati.
    if (_pendingImages.isNotEmpty) {
      final dir = await ref.read(appDirProvider.future);
      final attachDir = Directory('${dir.path}/attachments');
      await attachDir.create(recursive: true);
      final attachRepo = ref.read(attachmentRepositoryProvider);
      for (final img in _pendingImages) {
        final ext = img.path.split('.').last;
        final rel = 'attachments/${const Uuid().v4()}.$ext';
        await File(img.path).copy('${dir.path}/$rel');
        await attachRepo.add(
          transactionId: txId,
          relativePath: rel,
          mimeType: img.mimeType ?? 'image/$ext',
        );
      }
    }

    // Avviso budget: se la spesa porta la categoria oltre l'80% o il 100%.
    if (_type == TransactionType.expense && _categoryId != null && mounted) {
      final messenger = ScaffoldMessenger.of(context);
      final budgets = await ref.read(budgetRepositoryProvider).getAll(walletId);
      if (budgets.any((b) => b.categoryId == _categoryId)) {
        final p = await ref
            .read(budgetRepositoryProvider)
            .progressFor(categoryId: _categoryId!, month: DateTime.now());
        final ratio = p.limitCents == 0 ? 0.0 : p.spentCents / p.limitCents;
        if (ratio >= .8 && mounted) {
          final name =
              (ref.read(categoriesProvider).valueOrNull ?? [])
                  .where((c) => c.id == _categoryId)
                  .firstOrNull
                  ?.name ??
              '';
          messenger.showSnackBar(
            SnackBar(
              content: Text(
                ratio >= 1
                    ? l10n.budgetExceeded(name)
                    : l10n.budgetNear(name, (ratio * 100).round()),
              ),
              backgroundColor: ratio >= 1 ? NipayColors.over : NipayColors.warn,
            ),
          );
        }
      }
    }

    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final img = await ImagePicker().pickImage(
        source: source,
        maxWidth: 2000,
        imageQuality: 85,
      );
      if (img != null) setState(() => _pendingImages.add(img));
    } catch (_) {
      // Sorgente non disponibile (es. niente camera su Waydroid): ignora.
    }
  }

  /// Input per ogni campo custom definito, in base al tipo.
  List<Widget> _buildCustomFields(AppLocalizations l10n) {
    final all = ref.watch(customFieldDefsProvider).valueOrNull ?? const [];
    final defs = [
      for (final d in all)
        if (!d.expenseReportOnly ||
            (_isExpenseReport && _type == TransactionType.expense))
          d,
    ];
    if (defs.isEmpty) return const [];
    return [
      const SizedBox(height: 16),
      Text(l10n.customFields, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 8),
      for (final d in defs) ...[
        switch (d.type) {
          CustomFieldType.choice => DropdownButtonFormField<String>(
            initialValue: _fieldValues[d.id],
            decoration: InputDecoration(labelText: d.name, isDense: true),
            items: [
              for (final o in d.options ?? const <String>[])
                DropdownMenuItem(value: o, child: Text(o)),
            ],
            onChanged: (v) => setState(() => _fieldValues[d.id] = v ?? ''),
          ),
          CustomFieldType.date => ListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            leading: const Icon(Icons.event, size: 18),
            title: Text(
              _fieldValues[d.id] ?? d.name,
              style: const TextStyle(fontSize: 13),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2000),
                lastDate: DateTime(2100),
              );
              if (picked != null) {
                setState(
                  () => _fieldValues[d.id] =
                      '${picked.year}-${picked.month.toString().padLeft(2, "0")}-${picked.day.toString().padLeft(2, "0")}',
                );
              }
            },
          ),
          _ => TextField(
            key: ValueKey('customField_${d.id}'),
            controller: _controllerFor(d.id),
            keyboardType: d.type == CustomFieldType.number
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            decoration: InputDecoration(labelText: d.name, isDense: true),
            onChanged: (v) => _fieldValues[d.id] = v,
          ),
        },
        const SizedBox(height: 8),
      ],
    ];
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final wallets = ref.watch(walletsProvider).valueOrNull ?? [];
    final categories = (ref.watch(categoriesProvider).valueOrNull ?? [])
        .where(
          (c) => switch (_type) {
            TransactionType.expense => c.kind != CategoryKind.income,
            TransactionType.income => c.kind != CategoryKind.expense,
            TransactionType.transfer => false,
          },
        )
        .toList();
    final walletId = ref.watch(activeWalletProvider)?.id;
    final activeCurrency = ref.watch(activeWalletProvider)?.currency ?? 'EUR';
    final effectiveCurrency = _currency ?? activeCurrency;
    final tags = ref.watch(tagsProvider).valueOrNull ?? const <Tag>[];

    // Altezza fissa indipendente dal tipo selezionato: "trasferimento" ha
    // molti meno campi di "spesa"/"entrata" e altrimenti il popup si
    // ridimensionerebbe cambiando segmento.
    final sheetHeight = MediaQuery.sizeOf(context).height * 0.88;

    return SizedBox(
      height: sheetHeight,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _editing ? l10n.editTransaction : l10n.newTransaction,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (!_editing)
                SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<TransactionType>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: TransactionType.expense,
                        label: Text(l10n.expense),
                      ),
                      ButtonSegment(
                        value: TransactionType.income,
                        label: Text(l10n.income),
                      ),
                      ButtonSegment(
                        value: TransactionType.transfer,
                        label: Text(l10n.transfer),
                      ),
                    ],
                    selected: {_type},
                    onSelectionChanged: (s) => setState(() => _type = s.first),
                  ),
                ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const Key('amountField'),
                      controller: _amount,
                      autofocus: true,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: moneyInputFormatters,
                      style: moneyStyle(size: 28),
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: l10n.amount,
                        errorText: _error,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 132,
                    child: DropdownButtonFormField<String>(
                      key: const Key('transactionCurrencyDropdown'),
                      initialValue: effectiveCurrency,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: l10n.currency),
                      items: currencyMenuItems(),
                      onChanged: (v) {
                        setState(() => _currency = v);
                        _maybeFetchRate();
                      },
                    ),
                  ),
                ],
              ),
              if (effectiveCurrency != activeCurrency) ...[
                const SizedBox(height: 4),
                if (_fetchingRate)
                  const SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else if (_rateError != null)
                  Text(
                    _rateError!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 12,
                    ),
                  )
                else if (_rate != null && parseCents(_amount.text) != null)
                  Text(
                    l10n.convertedPreview(
                      formatCents(
                        (parseCents(_amount.text)! * _rate!).round(),
                        currency: activeCurrency,
                      ),
                    ),
                    style: TextStyle(color: palette.muted, fontSize: 12),
                  ),
              ],
              const SizedBox(height: 12),
              TextField(
                key: const Key('descriptionField'),
                controller: _description,
                decoration: InputDecoration(labelText: l10n.description),
              ),
              const SizedBox(height: 12),
              if (_type == TransactionType.transfer && wallets.length > 1) ...[
                const SizedBox(height: 12),
                InputDecorator(
                  decoration: InputDecoration(labelText: l10n.fromWallet),
                  child: Text(
                    wallets.where((w) => w.id == walletId).firstOrNull?.name ??
                        '',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  key: const Key('walletToDropdown'),
                  initialValue:
                      _walletToId ??
                      wallets.where((w) => w.id != walletId).firstOrNull?.id,
                  decoration: InputDecoration(labelText: l10n.toWallet),
                  items: [
                    for (final w in wallets.where((w) => w.id != walletId))
                      DropdownMenuItem(value: w.id, child: Text(w.name)),
                  ],
                  onChanged: (v) => setState(() => _walletToId = v),
                ),
              ],
              if (_type != TransactionType.transfer) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.category,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final c in categories)
                      ChoiceChip(
                        label: Text(
                          '${c.icon} ${c.name}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: _categoryId == c.id,
                        onSelected: (sel) =>
                            setState(() => _categoryId = sel ? c.id : null),
                      ),
                  ],
                ),
              ],
              if (_type != TransactionType.transfer) ...[
                const SizedBox(height: 16),
                Text(l10n.tags, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final t in tags)
                      FilterChip(
                        label: Text(
                          '#${t.name}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        selected: _selectedTagIds.contains(t.id),
                        onSelected: (sel) => setState(
                          () => sel
                              ? _selectedTagIds.add(t.id)
                              : _selectedTagIds.remove(t.id),
                        ),
                      ),
                    ActionChip(
                      key: const Key('addTagChip'),
                      label: const Text('＋', style: TextStyle(fontSize: 12)),
                      onPressed: () async {
                        final name = await _promptNewTag(context, l10n, tags);
                        if (name == null || name.isEmpty) return;
                        final active = ref.read(activeWalletProvider);
                        if (active == null) return;
                        final id = await ref
                            .read(tagRepositoryProvider)
                            .create(name, walletId: active.id);
                        ref.invalidate(tagsProvider);
                        setState(() => _selectedTagIds.add(id));
                      },
                    ),
                  ],
                ),
                ..._buildCustomFields(l10n),
                if (_type == TransactionType.expense) ...[
                  const SizedBox(height: 8),
                  SwitchListTile(
                    key: const Key('expenseReportSwitch'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(
                      '📋 ${l10n.expenseReportFlag}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    value: _isExpenseReport,
                    onChanged: (v) => setState(() => _isExpenseReport = v),
                  ),
                  if (_isExpenseReport) ...[
                    DropdownButtonFormField<String?>(
                      key: const Key('costCenterDropdown'),
                      initialValue: _costCenterId,
                      decoration: InputDecoration(
                        labelText: l10n.costCenter,
                        isDense: true,
                      ),
                      items: [
                        DropdownMenuItem(value: null, child: Text(l10n.none)),
                        for (final cc
                            in ref.watch(costCentersProvider).valueOrNull ??
                                const <CostCenter>[])
                          DropdownMenuItem(value: cc.id, child: Text(cc.name)),
                      ],
                      onChanged: (v) => setState(() => _costCenterId = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        l10n.reimbursable,
                        style: const TextStyle(fontSize: 13),
                      ),
                      value: _reimbursable,
                      onChanged: (v) => setState(() => _reimbursable = v),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(
                        l10n.eInvoice,
                        style: const TextStyle(fontSize: 13),
                      ),
                      value: _eInvoice,
                      onChanged: (v) => setState(() => _eInvoice = v),
                    ),
                  ],
                ],
                const SizedBox(height: 16),
                Text(
                  l10n.receipt,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.photo_camera_outlined, size: 16),
                      label: Text(
                        l10n.fromCamera,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _pickImage(ImageSource.camera),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.photo_library_outlined, size: 16),
                      label: Text(
                        l10n.fromGallery,
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _pickImage(ImageSource.gallery),
                    ),
                    if (_pendingImages.isNotEmpty) ...[
                      const SizedBox(width: 10),
                      Text(
                        '📎 ${_pendingImages.length}',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ],
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.event, color: palette.muted),
                title: Text(
                  '${_date.day}/${_date.month}/${_date.year}',
                  style: const TextStyle(fontSize: 14),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) setState(() => _date = picked);
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const Key('txSaveButton'),
                  onPressed: _save,
                  child: Text(l10n.save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
