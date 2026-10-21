import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/app_localizations.dart';
import '../theme/app_theme.dart';

/// Titolo di una schermata principale (tab), annunciato come intestazione.
class PageHeader extends StatelessWidget {
  const PageHeader(this.title, {super.key, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 12),
    child: Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
        ?trailing,
      ],
    ),
  );
}

/// Titolo di sezione dentro una pagina, con un'azione opzionale a destra
/// (es. "Nuovo portafoglio").
class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.action,
    this.padding = const EdgeInsets.fromLTRB(4, 20, 0, 8),
  });

  final String title;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: ConstrainedBox(
      // Stessa altezza con o senza azione: le sezioni restano allineate.
      constraints: const BoxConstraints(minHeight: 32),
      child: Row(
        children: [
          // Tacca col gradiente del CTA: ritmo visivo tra le sezioni.
          ExcludeSemantics(
            child: Container(
              width: 4,
              height: 18,
              margin: const EdgeInsetsDirectional.only(end: 10),
              decoration: BoxDecoration(
                gradient: context.nipay.ctaGradient,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Expanded(
            child: Semantics(
              header: true,
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          ?action,
        ],
      ),
    ),
  );
}

/// Stato vuoto coerente in tutta l'app: icona, messaggio, azione opzionale.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.action,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
  });

  final IconData icon;
  final String message;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final palette = context.nipay;
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: palette.surface2,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 26, color: palette.muted),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: palette.muted),
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// Riquadro arrotondato con emoji o icona su fondo tinto (categorie,
/// voci di menu). Decorativo: il significato è sempre anche nel testo.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    this.emoji,
    this.icon,
    required this.color,
    this.size = 40,
  }) : assert(emoji != null || icon != null);

  final String? emoji;
  final IconData? icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: dark ? .22 : .14),
          borderRadius: BorderRadius.circular(size * .3),
        ),
        child: emoji != null
            ? Text(emoji!, style: TextStyle(fontSize: size * .45))
            : Icon(icon, size: size * .5, color: color),
      ),
    );
  }
}

/// Selettore mese ‹ ottobre 2026 ›, con nome del mese nella lingua attiva.
class MonthSwitcher extends StatelessWidget {
  const MonthSwitcher({
    super.key,
    required this.month,
    required this.onChanged,
  });

  final DateTime month;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.nipay.line),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: loc.previousMonthTooltip,
            icon: const Icon(Icons.chevron_left),
            onPressed: () => onChanged(DateTime(month.year, month.month - 1)),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 112),
            child: Semantics(
              liveRegion: true,
              child: Text(
                loc.formatMonthYear(month),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
          ),
          IconButton(
            tooltip: loc.nextMonthTooltip,
            icon: const Icon(Icons.chevron_right),
            onPressed: () => onChanged(DateTime(month.year, month.month + 1)),
          ),
        ],
      ),
    );
  }
}

/// Campo che apre un selettore (data, valuta…) con lo stesso aspetto degli
/// input di testo: tocca per scegliere. Raggiungibile e attivabile anche da
/// tastiera.
class PickerField extends StatelessWidget {
  const PickerField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.prefixIcon,
    this.errorText,
  });

  final String label;

  /// Valore già formattato; null = nessun valore (mostra solo l'etichetta).
  final String? value;
  final VoidCallback onTap;
  final IconData? prefixIcon;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return Semantics(
      button: true,
      child: Stack(
        children: [
          InputDecorator(
            isEmpty: value == null,
            decoration: InputDecoration(
              labelText: label,
              errorText: errorText,
              prefixIcon: prefixIcon == null ? null : Icon(prefixIcon),
              suffixIcon: const Icon(Icons.expand_more),
            ),
            child: Text(
              value ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
          // Sopra il riempimento del campo, altrimenti l'effetto al tocco
          // resterebbe nascosto sotto. Solo sul riquadro, non sul messaggio
          // d'errore sotto.
          Positioned.fill(
            bottom: errorText == null ? 0 : 22,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(borderRadius: radius, onTap: onTap),
            ),
          ),
        ],
      ),
    );
  }
}

/// Campo "data": tocca per aprire il calendario.
class DateField extends StatelessWidget {
  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;

  /// Data già formattata; null = nessun valore (mostra solo l'etichetta).
  final String? value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => PickerField(
    label: label,
    value: value,
    onTap: onTap,
    prefixIcon: Icons.event_outlined,
  );
}

/// Palette di colori a pallini (portafogli, categorie). Il pallino scelto
/// ha anello e spunta, non solo un bordo colorato.
class ColorChoiceRow extends StatelessWidget {
  const ColorChoiceRow({
    super.key,
    required this.colors,
    required this.selected,
    required this.onSelected,
  });

  /// Colori in formato `#RRGGBB`.
  final List<String> colors;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ring = Theme.of(context).colorScheme.onSurface;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final (i, hex) in colors.indexed)
          Semantics(
            label: '${l10n.color} ${i + 1}',
            selected: hex == selected,
            inMutuallyExclusiveGroup: true,
            button: true,
            excludeSemantics: true,
            child: Tooltip(
              message: '${l10n.color} ${i + 1}',
              excludeFromSemantics: true,
              child: InkResponse(
                onTap: () => onSelected(hex),
                radius: 26,
                child: Container(
                  width: 44,
                  height: 44,
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: hex == selected ? ring : Colors.transparent,
                      width: 2.5,
                    ),
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colorFromHex(hex),
                    ),
                    child: hex == selected
                        ? Icon(
                            Icons.check,
                            size: 20,
                            color: foregroundOn(colorFromHex(hex)),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Conferma per le eliminazioni non annullabili. Torna true se confermata.
Future<bool> confirmDeletion(
  BuildContext context, {
  required String title,
  String? message,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: Icon(
        Icons.delete_outline,
        color: Theme.of(dialogContext).colorScheme.error,
      ),
      title: Text(title),
      content: Text(message ?? l10n.deleteItemBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          style: destructiveButtonStyle(dialogContext),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(l10n.delete),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Campo "aggiungi" in cima ai gestori di elenchi semplici (tag, centri di
/// costo): testo + bottone, invio da tastiera incluso.
class AddItemField extends StatelessWidget {
  const AddItemField({
    super.key,
    required this.controller,
    required this.label,
    required this.onSubmit,
    this.error,
    this.onChanged,
    this.inputFormatters,
  });

  final TextEditingController controller;
  final String label;
  final String? error;
  final VoidCallback onSubmit;
  final ValueChanged<String>? onChanged;
  final List<TextInputFormatter>? inputFormatters;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              inputFormatters: inputFormatters,
              textInputAction: TextInputAction.done,
              onChanged: onChanged,
              onSubmitted: (_) => onSubmit(),
              decoration: InputDecoration(labelText: label, errorText: error),
            ),
          ),
          const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: IconButton.filled(
              tooltip: label,
              style: IconButton.styleFrom(
                backgroundColor: NipayColors.coral,
                foregroundColor: NipayColors.ink,
                minimumSize: const Size(48, 48),
              ),
              onPressed: onSubmit,
              icon: const Icon(Icons.add),
            ),
          ),
        ],
      ),
    ),
  );
}
