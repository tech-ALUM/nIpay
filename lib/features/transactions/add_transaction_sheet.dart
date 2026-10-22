import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../core/image_sanitizer.dart';
import '../../core/money.dart';
import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/ui/ui.dart';
import '../../core/validation.dart';
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
            inputFormatters: [LengthLimitingTextInputFormatter(kMaxNameLength)],
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
}) => showAppSheet<void>(
  context,
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

  /// Foto già ripulite dai metadati (EXIF/GPS) al momento della scelta.
  final List<SanitizedImage> _pendingImages = [];
  bool _attachmentRejected = false;
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
  TextEditingController _controllerFor(String fieldId) =>
      _fieldControllers.putIfAbsent(
        fieldId,
        () => TextEditingController(text: _fieldValues[fieldId]),
      );

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
        // Path, estensione e tipo li decide l'app (dai magic bytes), mai il
        // nome del file scelto (SECURITY_AUDIT NIP-24).
        final rel = 'attachments/${const Uuid().v4()}.${img.extension}';
        await File('${dir.path}/$rel').writeAsBytes(img.bytes, flush: true);
        await attachRepo.add(
          transactionId: txId,
          relativePath: rel,
          mimeType: img.mimeType,
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
                  ?.displayName(l10n) ??
              '';
          // Giallo con testo ink (≥ 80%) o rosso errore (≥ 100%), sempre
          // con icona: lo stato non passa dal solo colore.
          final exceeded = ratio >= 1;
          final scheme = Theme.of(context).colorScheme;
          final (bg, fg) = exceeded
              ? (scheme.error, scheme.onError)
              : (NipayColors.warn, NipayColors.ink);
          messenger.showSnackBar(
            SnackBar(
              backgroundColor: bg,
              content: Row(
                children: [
                  Icon(
                    exceeded
                        ? Icons.error_outline
                        : Icons.warning_amber_rounded,
                    color: fg,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      exceeded
                          ? l10n.budgetExceeded(name)
                          : l10n.budgetNear(name, (ratio * 100).round()),
                      style: TextStyle(color: fg, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
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
      if (img == null) return;
      // Via EXIF (posizione GPS, modello del telefono), XMP e commenti
      // prima di salvare la foto (SECURITY_AUDIT NIP-16).
      final SanitizedImage clean;
      try {
        clean = sanitizeImage(await img.readAsBytes());
      } on UnsupportedImageException {
        if (mounted) setState(() => _attachmentRejected = true);
        return;
      }
      if (mounted) {
        setState(() {
          _pendingImages.add(clean);
          _attachmentRejected = false;
        });
      }
    } catch (_) {
      // Sorgente non disponibile (es. niente camera su Waydroid): ignora.
    }
  }

  /// Input per un campo custom, in base al tipo.
  Widget _customFieldInput(CustomFieldDef d) => switch (d.type) {
    CustomFieldType.choice => DropdownButtonFormField<String>(
      initialValue: _fieldValues[d.id],
      isExpanded: true,
      decoration: InputDecoration(labelText: d.name),
      items: [
        for (final o in d.options ?? const <String>[])
          DropdownMenuItem(value: o, child: Text(o)),
      ],
      onChanged: (v) => setState(() => _fieldValues[d.id] = v ?? ''),
    ),
    CustomFieldType.date => DateField(
      label: d.name,
      value: switch (DateTime.tryParse(_fieldValues[d.id] ?? '')) {
        final date? => formatDate(context, date),
        null => null,
      },
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate:
              DateTime.tryParse(_fieldValues[d.id] ?? '') ?? DateTime.now(),
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
      inputFormatters: [
        LengthLimitingTextInputFormatter(kMaxCustomValueLength),
      ],
      keyboardType: d.type == CustomFieldType.number
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.text,
      decoration: InputDecoration(labelText: d.name),
      onChanged: (v) => _fieldValues[d.id] = v,
    ),
  };

  List<Widget> _fieldList(Iterable<CustomFieldDef> defs) => [
    for (final (i, d) in defs.indexed) ...[
      if (i > 0) kFieldGap,
      _customFieldInput(d),
    ],
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final scheme = Theme.of(context).colorScheme;
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
    final fieldDefs =
        ref.watch(customFieldDefsProvider).valueOrNull ?? const [];
    // I campi "solo nota spese" stanno nel riquadro della nota spese.
    final generalFields = fieldDefs.where((d) => !d.expenseReportOnly);
    final reportFields = fieldDefs.where((d) => d.expenseReportOnly);
    final isExpense = _type == TransactionType.expense;
    // Colore che accompagna il tipo nel riquadro importo e nella categoria
    // scelta: coral per le spese, teal per le entrate, neutro per i
    // trasferimenti (come gli importi in lista).
    final typeColor = switch (_type) {
      TransactionType.expense => palette.expense,
      TransactionType.income => palette.income,
      TransactionType.transfer => scheme.onSurface,
    };
    Future<void> pickDate() async {
      final picked = await showDatePicker(
        context: context,
        initialDate: _date,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked != null) setState(() => _date = picked);
    }

    // Colore del segmento selezionato: coral per le spese, teal per le
    // entrate, neutro per i trasferimenti (come gli importi in lista).
    final (typeBg, typeFg) = switch (_type) {
      TransactionType.expense => (
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      TransactionType.income => (
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
      ),
      TransactionType.transfer => (
        scheme.surfaceContainerHighest,
        scheme.onSurface,
      ),
    };

    return SheetScaffold(
      title: _editing ? l10n.editTransaction : l10n.newTransaction,
      // Altezza fissa indipendente dal tipo selezionato: "trasferimento" ha
      // molti meno campi di "spesa"/"entrata" e altrimenti il popup si
      // ridimensionerebbe cambiando segmento.
      heightFactor: 0.88,
      header: _editing
          ? null
          : SegmentedButton<TransactionType>(
              showSelectedIcon: false,
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected) ? typeBg : null,
                ),
                foregroundColor: WidgetStateProperty.resolveWith(
                  (s) => s.contains(WidgetState.selected) ? typeFg : null,
                ),
              ),
              segments: [
                ButtonSegment(
                  value: TransactionType.expense,
                  icon: const Icon(Icons.north_east_rounded, size: 18),
                  label: Text(l10n.expense),
                ),
                ButtonSegment(
                  value: TransactionType.income,
                  icon: const Icon(Icons.south_west_rounded, size: 18),
                  label: Text(l10n.income),
                ),
                ButtonSegment(
                  value: TransactionType.transfer,
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text(l10n.transfer),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
      actions: [
        FilledButton(
          key: const Key('txSaveButton'),
          onPressed: _save,
          child: Text(l10n.save),
        ),
      ],
      // Ordine: prima ciò che serve sempre (importo, categoria), poi
      // descrizione e data, lo scontrino e i dettagli raggruppati in card.
      children: [
        _AmountHero(
          color: typeColor,
          children: [
            // Valuta affiancata all'importo: si leggono come un'unità sola
            // ("42,50 EUR €").
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                    textAlign: TextAlign.end,
                    style: moneyStyle(size: 40, color: typeColor),
                    cursorColor: typeColor,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: l10n.amount,
                      errorText: _error,
                      filled: false,
                      floatingLabelAlignment: FloatingLabelAlignment.start,
                      floatingLabelStyle: Theme.of(context).textTheme.labelLarge
                          ?.copyWith(
                            color: _error != null ? scheme.error : typeColor,
                          ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: palette.line),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: typeColor, width: 2),
                      ),
                      errorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: scheme.error),
                      ),
                      focusedErrorBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: scheme.error, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                CurrencyChip(
                  key: const Key('transactionCurrencyDropdown'),
                  value: effectiveCurrency,
                  color: typeColor,
                  onChanged: (v) {
                    setState(() => _currency = v);
                    _maybeFetchRate();
                  },
                ),
              ],
            ),
            if (effectiveCurrency != activeCurrency)
              Padding(
                padding: const EdgeInsets.only(top: 10, left: 4),
                child: _fetchingRate
                    ? const Center(
                        child: SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : _rateError != null
                    ? _InlineMessage(
                        icon: Icons.error_outline,
                        text: _rateError!,
                        color: scheme.error,
                      )
                    : (_rate != null && parseCents(_amount.text) != null)
                    ? _InlineMessage(
                        icon: Icons.currency_exchange,
                        text: l10n.convertedPreview(
                          formatCents(
                            (parseCents(_amount.text)! * _rate!).round(),
                            currency: activeCurrency,
                          ),
                        ),
                        color: palette.muted,
                      )
                    : const SizedBox.shrink(),
              ),
          ],
        ),
        if (_type != TransactionType.transfer) ...[
          FieldLabel(l10n.category),
          _CategoryGrid(
            categories: categories,
            selectedId: _categoryId,
            accent: typeColor,
            // Come la chip di prima: toccare la categoria scelta la toglie.
            onSelected: (id) =>
                setState(() => _categoryId = _categoryId == id ? null : id),
          ),
        ],
        const SizedBox(height: 20),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                key: const Key('descriptionField'),
                controller: _description,
                textCapitalization: TextCapitalization.sentences,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(kMaxDescriptionLength),
                ],
                decoration: InputDecoration(labelText: l10n.description),
              ),
            ),
            const SizedBox(width: 10),
            // Larghezza naturale (allineata al bordo destro), con un tetto
            // perché col testo ingrandito la descrizione resti usabile.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 190),
              child: _DatePill(
                label: l10n.date,
                value: formatDate(context, _date),
                onTap: pickDate,
              ),
            ),
          ],
        ),
        if (_type == TransactionType.transfer && wallets.length > 1) ...[
          kFieldGap,
          InputDecorator(
            decoration: InputDecoration(
              labelText: l10n.fromWallet,
              prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
            ),
            child: Text(
              wallets.where((w) => w.id == walletId).firstOrNull?.name ?? '',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          kFieldGap,
          DropdownButtonFormField<String>(
            key: const Key('walletToDropdown'),
            initialValue:
                _walletToId ??
                wallets.where((w) => w.id != walletId).firstOrNull?.id,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l10n.toWallet,
              prefixIcon: const Icon(Icons.south_rounded),
            ),
            items: [
              for (final w in wallets.where((w) => w.id != walletId))
                DropdownMenuItem(value: w.id, child: Text(w.name)),
            ],
            onChanged: (v) => setState(() => _walletToId = v),
          ),
        ],
        if (_type != TransactionType.transfer) ...[
          FieldLabel(l10n.receipt),
          Row(
            children: [
              Expanded(
                child: _ReceiptButton(
                  icon: Icons.photo_camera_outlined,
                  label: l10n.fromCamera,
                  onPressed: () => _pickImage(ImageSource.camera),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ReceiptButton(
                  icon: Icons.photo_library_outlined,
                  label: l10n.fromGallery,
                  onPressed: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
          if (_pendingImages.isNotEmpty) ...[
            const SizedBox(height: 12),
            Semantics(
              label: '${l10n.attachments}: ${_pendingImages.length}',
              excludeSemantics: true,
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final img in _pendingImages)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.memory(
                        img.bytes,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        cacheWidth: 192,
                        errorBuilder: (_, _, _) => Container(
                          width: 64,
                          height: 64,
                          color: palette.surface2,
                          child: Icon(
                            Icons.image_outlined,
                            color: palette.muted,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          if (_attachmentRejected)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: _InlineMessage(
                icon: Icons.error_outline,
                text: l10n.attachmentUnsupported,
                color: scheme.error,
              ),
            ),
          const SizedBox(height: 20),
          _DetailsCard(
            children: [
              _CardLabel(l10n.tags),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final t in tags)
                    FilterChip(
                      label: Text('#${t.name}'),
                      selected: _selectedTagIds.contains(t.id),
                      onSelected: (sel) => setState(
                        () => sel
                            ? _selectedTagIds.add(t.id)
                            : _selectedTagIds.remove(t.id),
                      ),
                    ),
                  ActionChip(
                    key: const Key('addTagChip'),
                    avatar: const Icon(Icons.add, size: 18),
                    label: Text(l10n.newTag),
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
              if (generalFields.isNotEmpty) ...[
                const SizedBox(height: 8),
                FieldLabel(l10n.customFields),
                ..._fieldList(generalFields),
              ],
            ],
          ),
          if (isExpense) ...[
            const SizedBox(height: 12),
            // Material (non Container colorato): gli switch disegnano
            // l'effetto al tocco sul Material più vicino.
            Material(
              color: _isExpenseReport ? palette.surface2 : scheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: palette.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: AnimatedSize(
                duration: Motion.medium,
                curve: Motion.emphasized,
                alignment: Alignment.topCenter,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SwitchListTile(
                      key: const Key('expenseReportSwitch'),
                      secondary: const Icon(Icons.receipt_long_outlined),
                      title: Text(
                        l10n.expenseReportFlag,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      value: _isExpenseReport,
                      onChanged: (v) => setState(() => _isExpenseReport = v),
                    ),
                    if (_isExpenseReport)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            DropdownButtonFormField<String?>(
                              key: const Key('costCenterDropdown'),
                              initialValue: _costCenterId,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: l10n.costCenter,
                              ),
                              items: [
                                DropdownMenuItem(
                                  value: null,
                                  child: Text(l10n.none),
                                ),
                                for (final cc
                                    in ref
                                            .watch(costCentersProvider)
                                            .valueOrNull ??
                                        const <CostCenter>[])
                                  DropdownMenuItem(
                                    value: cc.id,
                                    child: Text(cc.name),
                                  ),
                              ],
                              onChanged: (v) =>
                                  setState(() => _costCenterId = v),
                            ),
                            const SizedBox(height: 4),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(l10n.reimbursable),
                              value: _reimbursable,
                              onChanged: (v) =>
                                  setState(() => _reimbursable = v),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(l10n.eInvoice),
                              value: _eInvoice,
                              onChanged: (v) => setState(() => _eInvoice = v),
                            ),
                            if (reportFields.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              ..._fieldList(reportFields),
                              const SizedBox(height: 8),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// Riga di stato sotto un campo: icona + testo, così l'errore non è
/// comunicato dal solo colore.
class _InlineMessage extends StatelessWidget {
  const _InlineMessage({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ),
    ],
  );
}

/// Riquadro dell'importo: tinta leggera del colore del tipo, che cambia
/// con un'animazione passando da spesa a entrata a trasferimento.
class _AmountHero extends StatelessWidget {
  const _AmountHero({required this.color, required this.children});

  final Color color;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: Motion.medium,
    curve: Motion.emphasized,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
    decoration: BoxDecoration(
      color: color.withValues(alpha: .07),
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: color.withValues(alpha: .22)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

/// Griglia di tessere categoria: almeno 4 colonne, di più su schermi
/// larghi. Le tessere hanno la stessa larghezza, le righe vanno a capo.
class _CategoryGrid extends StatelessWidget {
  const _CategoryGrid({
    required this.categories,
    required this.selectedId,
    required this.accent,
    required this.onSelected,
  });

  final List<Category> categories;
  final String? selectedId;
  final Color accent;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 8.0;
      final columns = math.max(4, constraints.maxWidth ~/ 110);
      final width = (constraints.maxWidth - gap * (columns - 1)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final c in categories)
            SizedBox(
              width: width,
              child: _CategoryTile(
                category: c,
                selected: c.id == selectedId,
                accent: accent,
                onTap: () => onSelected(c.id),
              ),
            ),
        ],
      );
    },
  );
}

/// Tessera di una categoria: emoji su fondo del colore della categoria e
/// nome sotto. Scelta = bordo e tinta del colore del tipo, più la spunta
/// (lo stato non è affidato al solo colore).
class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.accent,
    required this.onTap,
  });

  final Category category;
  final bool selected;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = context.nipay;
    final radius = BorderRadius.circular(16);
    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: selected,
        child: Pressable(
          borderRadius: radius,
          shadow: const [],
          child: AnimatedContainer(
            duration: Motion.fast,
            decoration: BoxDecoration(
              color: selected
                  ? accent.withValues(alpha: .10)
                  : Theme.of(context).colorScheme.surface,
              borderRadius: radius,
              border: Border.all(
                color: selected ? accent : palette.line,
                width: selected ? 2 : 1,
              ),
            ),
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                borderRadius: radius,
                onTap: onTap,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 10, 4, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconBadge(
                            emoji: category.icon,
                            color: colorFromHex(category.colorHex),
                          ),
                          if (selected)
                            PositionedDirectional(
                              top: -6,
                              end: -6,
                              child: ExcludeSemantics(
                                child: Icon(
                                  Icons.check_circle,
                                  size: 18,
                                  color: accent,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Nomi lunghi ("Restaurants") si rimpiccioliscono un
                      // po' invece di troncarsi: righe tutte alte uguali.
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          category.displayName(l10n),
                          maxLines: 1,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Data compatta accanto alla descrizione: stessa altezza del campo, tocca
/// per aprire il calendario. Annunciata come "Data: 21 ott 2026".
class _DatePill extends StatelessWidget {
  const _DatePill({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      label: '$label: $value',
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: scheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(color: scheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 52),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_outlined, size: 20, color: scheme.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Bottone scontrino: alto, icona sopra l'etichetta, bordo tratteggiato
/// "da riempire" reso con un contorno leggero.
class _ReceiptButton extends StatelessWidget {
  const _ReceiptButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => OutlinedButton(
    style: OutlinedButton.styleFrom(
      minimumSize: const Size(0, 64),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    onPressed: onPressed,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 22),
        const SizedBox(height: 4),
        Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ],
    ),
  );
}

/// Card che raggruppa i dettagli facoltativi (tag, campi personalizzati).
class _DetailsCard extends StatelessWidget {
  const _DetailsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: context.nipay.line),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    ),
  );
}

/// Etichetta del primo gruppo dentro una card (senza lo spazio sopra di
/// [FieldLabel], che lì farebbe doppio col padding della card).
class _CardLabel extends StatelessWidget {
  const _CardLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: context.nipay.muted),
      ),
    ),
  );
}
