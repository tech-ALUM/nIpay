import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Soglie responsive (Material 3 window size classes): sotto [medium] la
/// navigazione è in basso, da [medium] in su diventa una rail laterale.
abstract final class Breakpoints {
  static const double medium = 600;
  static const double expanded = 840;
}

/// Margine laterale minimo dei contenuti su telefono.
const double kGutter = 20;

/// Larghezza massima dei contenuti: su tablet le liste restano leggibili
/// invece di stirarsi da bordo a bordo.
const double kMaxContentWidth = 720;

/// Spazio in fondo alle liste perché il FAB non copra l'ultima riga.
const double kFabClearance = 96;

/// Padding che centra una colonna di larghezza massima [maxWidth] dentro
/// [availableWidth], senza mai scendere sotto [kGutter] ai lati. Da usare
/// come padding delle liste scrollabili, così tutta la larghezza resta
/// trascinabile anche su schermi larghi.
EdgeInsets centeredPadding(
  double availableWidth, {
  double top = 0,
  double bottom = 0,
  double maxWidth = kMaxContentWidth,
}) {
  final side = math.max(kGutter, (availableWidth - maxWidth) / 2);
  return EdgeInsets.fromLTRB(side, top, side, bottom);
}

/// Centra [child] con larghezza massima [maxWidth] (per contenuti non
/// scrollabili: intestazioni, form).
class MaxWidth extends StatelessWidget {
  const MaxWidth({
    super.key,
    required this.child,
    this.maxWidth = kMaxContentWidth,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: child,
    ),
  );
}

/// Due elementi affiancati a metà larghezza se lo spazio basta, altrimenti
/// uno sotto l'altro a tutta larghezza (es. le date "Dal"/"Al": su
/// telefono, affiancate, troncherebbero la data).
class AdaptivePair extends StatelessWidget {
  const AdaptivePair({
    super.key,
    required this.first,
    required this.second,
    this.minSideBySideWidth = 440,
    this.gap = 10,
  });

  final Widget first;
  final Widget second;
  final double minSideBySideWidth;
  final double gap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) =>
        constraints.maxWidth >= minSideBySideWidth
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: first),
              SizedBox(width: gap),
              Expanded(child: second),
            ],
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              first,
              SizedBox(height: gap),
              second,
            ],
          ),
  );
}

/// ListView con contenuto centrato e margini responsive.
class CenteredListView extends StatelessWidget {
  const CenteredListView({
    super.key,
    required this.children,
    this.top = 8,
    this.bottom = kFabClearance,
    this.maxWidth = kMaxContentWidth,
  });

  final List<Widget> children;
  final double top;
  final double bottom;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => ListView(
      padding: centeredPadding(
        constraints.maxWidth,
        top: top,
        bottom: bottom,
        maxWidth: maxWidth,
      ),
      children: children,
    ),
  );
}
