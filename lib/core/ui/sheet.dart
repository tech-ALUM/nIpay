import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Apre un bottom sheet con le impostazioni comuni dell'app: altezza libera
/// (serve con la tastiera aperta), fuori dalla status bar, maniglia di
/// trascinamento e larghezza massima dal tema.
Future<T?> showAppSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: builder,
);

/// Struttura comune dei bottom sheet: titolo, contenuto scrollabile e
/// azioni sempre visibili in fondo, anche con la tastiera aperta — non
/// serve scorrere fino in fondo per salvare.
class SheetScaffold extends StatelessWidget {
  const SheetScaffold({
    super.key,
    required this.title,
    required this.children,
    this.actions = const [],
    this.heightFactor,
    this.header,
  });

  final String title;

  /// Contenuto opzionale sotto il titolo e fuori dallo scroll (es. il
  /// selettore spesa/entrata/trasferimento).
  final Widget? header;
  final List<Widget> children;

  /// Bottoni in fondo, affiancati a parità di larghezza.
  final List<Widget> actions;

  /// Altezza fissa in frazione dello schermo; null = si adatta al contenuto.
  final double? heightFactor;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottom = math.max(media.viewInsets.bottom, media.viewPadding.bottom);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 4),
          child: Semantics(
            header: true,
            child: Text(title, style: Theme.of(context).textTheme.titleLarge),
          ),
        ),
        if (header != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: header,
          ),
        Flexible(
          fit: heightFactor == null ? FlexFit.loose : FlexFit.tight,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
        if (actions.isNotEmpty)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: context.nipay.line)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              child: Row(
                children: [
                  for (final (i, action) in actions.indexed) ...[
                    if (i > 0) const SizedBox(width: 12),
                    Expanded(child: action),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: heightFactor == null
          ? content
          : SizedBox(height: media.size.height * heightFactor!, child: content),
    );
  }
}

/// Etichetta di un gruppo di campi in un form (es. "Categoria", "Tag").
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 10),
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

/// Spazio verticale standard tra due campi di un form.
const kFieldGap = SizedBox(height: 14);
