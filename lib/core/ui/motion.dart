import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

// Movimento "Ink Aurora": ingressi a cascata, feedback alla pressione,
// numeri che scorrono, bagliori di sfondo. Tutto si spegne con "Riduci
// movimento" del sistema e nessuna animazione è infinita, così i widget
// test con `pumpAndSettle` restano deterministici.

/// True se il sistema chiede di ridurre il movimento (accessibilità).
bool reduceMotion(BuildContext context) =>
    MediaQuery.maybeDisableAnimationsOf(context) ?? false;

/// Durate e curve condivise: le stesse in tutta l'app.
abstract final class Motion {
  static const fast = Duration(milliseconds: 140);
  static const medium = Duration(milliseconds: 280);
  static const entrance = Duration(milliseconds: 520);
  static const count = Duration(milliseconds: 900);
  static const emphasized = Curves.easeOutCubic;
}

/// Ritardo d'ingresso dell'elemento in posizione [index] di una cascata
/// (0 = primo). [FadeSlideIn] lo somma alla durata dell'ingresso.
///
/// Passo lineare di 60 ms con un tetto a 360 ms: i primi blocchi entrano in
/// sequenza, quelli lontani (costruiti dalla ListView solo quando si scorre
/// fin lì) non restano mai vuoti più di un istante.
Duration staggerDelay(int index) =>
    Duration(milliseconds: math.min(index, 6) * 60);

/// Ingresso morbido: dissolvenza + salita di [offset] px, dopo il ritardo
/// di [staggerDelay]. Parte una volta sola: lo stato resta vivo anche
/// quando una ListView scorre l'elemento fuori schermo, così tornando su
/// non si rianima.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.index = 0,
    this.offset = 24,
  });

  final Widget child;
  final int index;
  final double offset;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _controller;
  late final Animation<double> _progress;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Un solo controller per ritardo + ingresso: niente Timer pendenti a
    // fine test se il widget viene smontato prima di partire.
    final delay = staggerDelay(widget.index);
    final total = delay + Motion.entrance;
    _controller = AnimationController(vsync: this, duration: total);
    _progress = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay.inMicroseconds / total.inMicroseconds,
        1,
        curve: Motion.emphasized,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_controller.isDismissed) return;
    if (reduceMotion(context)) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FadeTransition(
      opacity: _progress,
      child: AnimatedBuilder(
        animation: _progress,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - _progress.value) * widget.offset),
          child: child,
        ),
      ),
    );
  }
}

/// Feedback visivo al tocco: premendo il contenuto si "abbassa" (scala
/// 0.97), col mouse sopra si solleva con un'ombra più ampia. Usa un
/// Listener, non un GestureDetector: non entra nell'arena dei gesti, quindi
/// tap, pressione lunga e trascinamento del figlio restano identici.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.shadow,
  });

  final Widget child;
  final BorderRadius borderRadius;

  /// Ombra a riposo; di default quella delle card del tema.
  final List<BoxShadow>? shadow;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _pressed = false;
  bool _hovered = false;
  Offset? _downAt;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final palette = context.nipay;
    final lifted = _hovered && !_pressed;
    final still = reduceMotion(context);
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Listener(
        onPointerDown: (e) {
          _downAt = e.position;
          _setPressed(true);
        },
        // Se il dito si muove è uno scroll, non una pressione.
        onPointerMove: (e) {
          if (_downAt != null &&
              (e.position - _downAt!).distance > kTouchSlop) {
            _setPressed(false);
          }
        },
        onPointerUp: (_) => _setPressed(false),
        onPointerCancel: (_) => _setPressed(false),
        child: AnimatedScale(
          scale: _pressed && !still ? .97 : 1,
          duration: Motion.fast,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: Motion.medium,
            curve: Motion.emphasized,
            transform: Matrix4.translationValues(
              0,
              lifted && !still ? -2 : 0,
              0,
            ),
            decoration: BoxDecoration(
              borderRadius: widget.borderRadius,
              boxShadow: lifted
                  ? palette.raisedShadow
                  : (widget.shadow ?? palette.cardShadow),
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// Intero che scorre fino a [value] (es. il saldo in centesimi): al primo
/// montaggio parte da zero, ai cambi successivi dal valore mostrato.
class AnimatedCount extends StatelessWidget {
  const AnimatedCount({super.key, required this.value, required this.builder});

  final int value;
  final Widget Function(BuildContext context, int value) builder;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
    tween: Tween(begin: 0, end: value.toDouble()),
    duration: reduceMotion(context) ? Duration.zero : Motion.count,
    curve: Curves.easeOutExpo,
    builder: (context, v, _) => builder(context, v.round()),
  );
}

/// Bagliori sfumati coral e teal dietro la parte alta di una schermata: la
/// profondità di Ink Aurora. Decorativi, fuori da tocchi e screen reader.
class AuroraBackdrop extends StatelessWidget {
  const AuroraBackdrop({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.nipay;
    Widget glow(Color color, double size) => Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
      ),
    );
    return Stack(
      children: [
        Positioned(
          top: -160,
          left: -120,
          child: IgnorePointer(
            child: ExcludeSemantics(child: glow(palette.glowPrimary, 380)),
          ),
        ),
        Positioned(
          top: -80,
          right: -140,
          child: IgnorePointer(
            child: ExcludeSemantics(child: glow(palette.glowSecondary, 360)),
          ),
        ),
        child,
      ],
    );
  }
}

/// IndexedStack che a ogni cambio di indice fa entrare la vista con una
/// dissolvenza e una lieve salita. Le viste restano tutte montate, quindi
/// conservano il loro stato (ricerca, filtri, mese) come prima.
class FadeIndexedStack extends StatefulWidget {
  const FadeIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  State<FadeIndexedStack> createState() => _FadeIndexedStackState();
}

class _FadeIndexedStackState extends State<FadeIndexedStack>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: Motion.medium,
    value: 1,
  );
  late final Animation<double> _progress = CurvedAnimation(
    parent: _controller,
    curve: Motion.emphasized,
  );
  late final Animation<double> _opacity = Tween<double>(
    begin: .2,
    end: 1,
  ).animate(_progress);

  @override
  void didUpdateWidget(FadeIndexedStack oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index && !reduceMotion(context)) {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
    opacity: _opacity,
    child: AnimatedBuilder(
      animation: _progress,
      child: IndexedStack(index: widget.index, children: widget.children),
      builder: (context, child) => Transform.translate(
        offset: Offset(0, (1 - _progress.value) * 12),
        child: child,
      ),
    ),
  );
}
