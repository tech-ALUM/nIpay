import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../currencies.dart';
import 'widgets.dart';

/// Etichetta di una valuta nei campi e nel selettore: codice ISO (univoco)
/// affiancato al simbolo, es. "USD $".
String currencyLabel(String code) => '$code ${currencySymbol(code)}';

/// Campo valuta: mostra la valuta scelta e apre un riquadro compatto,
/// scorrevole e con ricerca (al posto di un menu a tendina lungo quanto lo
/// schermo).
class CurrencyField extends StatelessWidget {
  const CurrencyField({
    super.key,
    required this.value,
    required this.onChanged,
    this.prefixIcon,
    this.errorText,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final IconData? prefixIcon;
  final String? errorText;

  @override
  Widget build(BuildContext context) => PickerField(
    label: AppLocalizations.of(context)!.currency,
    value: currencyLabel(value),
    prefixIcon: prefixIcon,
    errorText: errorText,
    onTap: () async {
      final picked = await showCurrencyPicker(context, selected: value);
      if (picked != null && picked != value) onChanged(picked);
    },
  );
}

/// Variante compatta di [CurrencyField] da affiancare a un importo grande
/// ("42,50 [EUR € ▾]"): stessa scelta con ricerca, ingombro di una pillola.
/// Annunciata come "Valuta: EUR €".
class CurrencyChip extends StatelessWidget {
  const CurrencyChip({
    super.key,
    required this.value,
    required this.onChanged,
    this.color,
  });

  final String value;
  final ValueChanged<String> onChanged;

  /// Colore di testo e bordo; di default quello del testo del tema.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final fg = color ?? scheme.onSurface;
    Future<void> pick() async {
      final picked = await showCurrencyPicker(context, selected: value);
      if (picked != null && picked != value) onChanged(picked);
    }

    return Semantics(
      button: true,
      label: '${l10n.currency}: ${currencyLabel(value)}',
      excludeSemantics: true,
      onTap: pick,
      child: Material(
        color: fg.withValues(alpha: .10),
        shape: StadiumBorder(
          side: BorderSide(color: fg.withValues(alpha: .35)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: pick,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(14, 8, 8, 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    currencyLabel(value),
                    style: Theme.of(
                      context,
                    ).textTheme.labelLarge?.copyWith(color: fg),
                  ),
                  const SizedBox(width: 2),
                  Icon(Icons.expand_more, size: 20, color: fg),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Riquadro di scelta valuta; null se chiuso senza scegliere.
Future<String?> showCurrencyPicker(
  BuildContext context, {
  required String selected,
}) => showDialog<String>(
  context: context,
  builder: (_) => _CurrencyPickerDialog(selected: selected),
);

class _CurrencyPickerDialog extends StatefulWidget {
  const _CurrencyPickerDialog({required this.selected});

  final String selected;

  @override
  State<_CurrencyPickerDialog> createState() => _CurrencyPickerDialogState();
}

class _CurrencyPickerDialogState extends State<_CurrencyPickerDialog> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  /// Cerca per codice ("chf") o simbolo ("£").
  bool _matches(String code) {
    final q = _query.trim().toLowerCase();
    return q.isEmpty ||
        code.toLowerCase().contains(q) ||
        currencySymbol(code).toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final loc = MaterialLocalizations.of(context);
    final top = kTopCurrencies.where(_matches).toList();
    final others = kOtherCurrencies.where(_matches).toList();

    Widget tile(String code) {
      final selected = code == widget.selected;
      return ListTile(
        // Righe compatte (48 px, ancora comode al tocco): più valute a vista.
        dense: true,
        minVerticalPadding: 0,
        minTileHeight: 48,
        selected: selected,
        title: Text(currencyLabel(code)),
        trailing: selected ? const Icon(Icons.check) : null,
        onTap: () => Navigator.of(context).pop(code),
      );
    }

    return Dialog(
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360, maxHeight: 460),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Semantics(
                      header: true,
                      child: Text(
                        l10n.currency,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: loc.closeButtonTooltip,
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                key: const Key('currencySearchField'),
                controller: _search,
                textInputAction: TextInputAction.search,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: loc.searchFieldLabel,
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _query.isEmpty
                      ? null
                      : IconButton(
                          tooltip: loc.clearButtonTooltip,
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            _search.clear();
                            setState(() => _query = '');
                          },
                        ),
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
            const SizedBox(height: 8),
            Flexible(
              child: top.isEmpty && others.isEmpty
                  ? EmptyState(icon: Icons.search_off, message: l10n.noItems)
                  : ListView(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 12),
                      children: [
                        ...top.map(tile),
                        // Le più usate in cima, separate dalle altre.
                        if (top.isNotEmpty && others.isNotEmpty)
                          const Divider(indent: 16, endIndent: 16),
                        ...others.map(tile),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
