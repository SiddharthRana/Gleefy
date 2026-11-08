import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/settings.dart';
import '../theme/app_theme.dart';

/// Game-feel motion: squishy presses, bumps, staggered entrances, pops, shakes and confetti.
/// Every widget here renders its child still when the system "remove animations" setting or the
/// in-app Reduce motion switch is on.

/// Wraps a tappable widget and squishes it while a finger is down, springing back on release.
/// Uses a [Listener], so the child's own gestures and semantics are untouched.
class Pressable extends ConsumerStatefulWidget {
  const Pressable({super.key, required this.child, this.enabled = true, this.scale = 0.95});

  final Widget child;
  final bool enabled;

  /// Scale while pressed.
  final double scale;

  @override
  ConsumerState<Pressable> createState() => _PressableState();
}

class _PressableState extends ConsumerState<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotionOf(context, ref) || !widget.enabled) return widget.child;
    return Listener(
      onPointerDown: (_) => _set(true),
      onPointerUp: (_) => _set(false),
      onPointerCancel: (_) => _set(false),
      child: AnimatedScale(
        scale: _down ? widget.scale : 1,
        duration: Duration(milliseconds: _down ? 90 : 260),
        curve: _down ? Curves.easeOut : Curves.elasticOut,
        child: widget.child,
      ),
    );
  }
}

/// Pops its child (grows then settles) every time [value] changes: vote counts, scores.
class Bump extends ConsumerStatefulWidget {
  const Bump({super.key, required this.value, required this.child, this.amount = 0.35});

  final Object? value;
  final Widget child;
  final double amount;

  @override
  ConsumerState<Bump> createState() => _BumpState();
}

class _BumpState extends ConsumerState<Bump> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

  @override
  void didUpdateWidget(Bump old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value && !reduceMotionOf(context, ref)) _c.forward(from: 0);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 1, end: 1 + widget.amount), weight: 35),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1 + widget.amount, end: 1).chain(CurveTween(curve: Curves.elasticOut)),
        weight: 65,
      ),
    ]).animate(_c);
    return ScaleTransition(scale: scale, child: widget.child);
  }
}

/// Fades and slides its child up when first shown; [index] staggers items in a list.
class StaggerIn extends ConsumerStatefulWidget {
  const StaggerIn({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  ConsumerState<StaggerIn> createState() => _StaggerInState();
}

class _StaggerInState extends ConsumerState<StaggerIn> with SingleTickerProviderStateMixin {
  static const _step = 55;
  static const _length = 340;
  late final AnimationController _c;
  late final Animation<double> _t;

  @override
  void initState() {
    super.initState();
    final delay = min(widget.index, 8) * _step;
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: delay + _length),
    );
    _t = CurvedAnimation(
      parent: _c,
      curve: Interval(delay / (delay + _length), 1, curve: Curves.easeOutBack),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotionOf(context, ref)) return widget.child;
    return AnimatedBuilder(
      animation: _t,
      builder: (_, child) => Opacity(
        opacity: _t.value.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, (1 - _t.value) * 24), child: child),
      ),
      child: widget.child,
    );
  }
}

/// Springs its child in from small when first shown: points, verdicts, headlines.
class PopIn extends ConsumerStatefulWidget {
  const PopIn({super.key, required this.child, this.delay = Duration.zero});

  final Widget child;
  final Duration delay;

  @override
  ConsumerState<PopIn> createState() => _PopInState();
}

class _PopInState extends ConsumerState<PopIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    const length = 560;
    final delay = widget.delay.inMilliseconds;
    _c = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: delay + length),
    );
    _scale = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(
        parent: _c,
        curve: Interval(delay / (delay + length), 1, curve: Curves.elasticOut),
      ),
    );
    _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotionOf(context, ref)) return widget.child;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) => Opacity(
        opacity: (_c.value * 3).clamp(0, 1),
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}

/// Shakes its child side to side once when [shake] turns true: a wrong answer.
class Shake extends ConsumerStatefulWidget {
  const Shake({super.key, required this.shake, required this.child});

  final bool shake;
  final Widget child;

  @override
  ConsumerState<Shake> createState() => _ShakeState();
}

class _ShakeState extends ConsumerState<Shake> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));

  @override
  void initState() {
    super.initState();
    if (widget.shake) WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  void _start() {
    if (mounted && !reduceMotionOf(context, ref)) _c.forward(from: 0);
  }

  @override
  void didUpdateWidget(Shake old) {
    super.didUpdateWidget(old);
    if (widget.shake && !old.shake) _start();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, child) => Transform.translate(
      // Three decaying swings.
      offset: Offset(sin(_c.value * pi * 6) * 9 * (1 - _c.value), 0),
      child: child,
    ),
    child: widget.child,
  );
}

/// A one-shot burst of confetti over its area. Decorative: ignores touches and screen readers.
class Confetti extends ConsumerStatefulWidget {
  const Confetti({super.key, this.pieces = 48, this.seed = 1});

  final int pieces;
  final int seed;

  @override
  ConsumerState<Confetti> createState() => _ConfettiState();
}

class _ConfettiState extends ConsumerState<Confetti> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1700))..forward();
  late final List<_Piece> _pieces;

  @override
  void initState() {
    super.initState();
    final r = Random(widget.seed);
    _pieces = List.generate(widget.pieces, (i) {
      final angle = -pi / 2 + (r.nextDouble() - 0.5) * pi * 1.3;
      return _Piece(
        dx: cos(angle) * (0.35 + r.nextDouble() * 0.6),
        dy: sin(angle) * (0.5 + r.nextDouble() * 0.7),
        spin: (r.nextDouble() - 0.5) * 14,
        size: 6 + r.nextDouble() * 6,
        colorIndex: i % 5,
        round: r.nextBool(),
      );
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (reduceMotionOf(context, ref)) return const SizedBox.shrink();
    final palette = GfPalette.of(context);
    final scheme = Theme.of(context).colorScheme;
    final colors = [palette.optionA, palette.optionB, palette.accent, scheme.primary, palette.success];
    return IgnorePointer(
      child: ExcludeSemantics(
        child: AnimatedBuilder(
          animation: _c,
          builder: (_, _) => CustomPaint(size: Size.infinite, painter: _ConfettiPainter(_pieces, colors, _c.value)),
        ),
      ),
    );
  }
}

class _Piece {
  const _Piece({
    required this.dx,
    required this.dy,
    required this.spin,
    required this.size,
    required this.colorIndex,
    required this.round,
  });
  final double dx, dy, spin, size;
  final int colorIndex;
  final bool round;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter(this.pieces, this.colors, this.t);

  final List<_Piece> pieces;
  final List<Color> colors;
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    if (t <= 0 || t >= 1) return;
    final origin = Offset(size.width / 2, size.height * 0.35);
    final eased = Curves.easeOutCubic.transform(t);
    final opacity = t < 0.7 ? 1.0 : (1 - (t - 0.7) / 0.3);
    final paint = Paint();
    for (final p in pieces) {
      // Thrown outwards, then pulled down by gravity.
      final x = origin.dx + p.dx * size.width * 0.6 * eased;
      final y = origin.dy + p.dy * size.height * 0.5 * eased + 0.9 * size.height * t * t;
      paint.color = colors[p.colorIndex].withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(p.spin * t);
      if (p.round) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromCenter(center: Offset.zero, width: p.size, height: p.size * 0.6),
            const Radius.circular(1.5),
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_ConfettiPainter old) => old.t != t;
}
