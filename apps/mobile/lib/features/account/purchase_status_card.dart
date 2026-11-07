import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../billing/billing_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../state/settings.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/motion.dart';

/// The result of a Google Play purchase as an animated card (the same states as the website's
/// checkout result, as in Weblume): a spinning ring while the server confirms it, a check that draws
/// itself and a burst of confetti on success, a clock while Play waits for the payment, and a cross
/// that shakes once on failure. Still when Reduce motion is on.
class PurchaseStatusCard extends ConsumerWidget {
  const PurchaseStatusCard({super.key, required this.state, this.onRetry});

  final BillingState state;

  /// Shown as "Try again" on failures the person can retry.
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = MmPalette.of(context);
    final danger = theme.colorScheme.error;

    final (Widget badge, String title, String body, Color tone) = switch (state.phase) {
      PurchasePhase.verifying || PurchasePhase.purchasing => (
        _Spinner(color: theme.colorScheme.primary),
        l.purchaseVerifyingTitle,
        l.purchaseVerifyingBody,
        theme.colorScheme.primary,
      ),
      PurchasePhase.pending => (
        _Badge(color: palette.accent, child: const Icon(Icons.schedule_rounded)),
        l.purchasePendingTitle,
        l.premiumPending,
        palette.accent,
      ),
      PurchasePhase.success => (
        _Badge(
          color: palette.success,
          child: _DrawnMark(color: palette.success, cross: false),
        ),
        l.purchaseSuccessTitle,
        l.premiumSuccess,
        palette.success,
      ),
      _ => (
        Shake(
          shake: true,
          child: _Badge(
            color: danger,
            child: _DrawnMark(color: danger, cross: true),
          ),
        ),
        state.canRetryVerify ? l.purchaseDelayedTitle : l.purchaseFailedTitle,
        switch (state.error) {
          'store_unavailable' => l.premiumErrorStore,
          'account_mismatch' => l.premiumErrorMismatch,
          'verify_failed' => l.premiumErrorVerify,
          'network' => l.premiumErrorNetwork,
          _ => l.premiumErrorPurchase,
        },
        danger,
      ),
    };
    final busy = state.phase == PurchasePhase.verifying || state.phase == PurchasePhase.purchasing;
    final retry = state.phase == PurchasePhase.error && onRetry != null && state.error != 'account_mismatch';

    final card = Container(
      padding: const EdgeInsets.all(MmSpace.s4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(MmRadius.lg),
        border: Border.all(color: tone, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ExcludeSemantics(child: badge),
              const SizedBox(width: MmSpace.s4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: MmSpace.s1),
                    Text(body, style: theme.textTheme.bodyLarge),
                    if (state.phase == PurchasePhase.success && state.duplicateWarning) ...[
                      const SizedBox(height: MmSpace.s2),
                      Text(l.premiumDuplicate, style: theme.textTheme.bodyLarge),
                    ],
                    if (retry) ...[
                      const SizedBox(height: MmSpace.s3),
                      Pressable(
                        child: FilledButton(onPressed: onRetry, child: Text(l.tryAgain)),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (busy) ...[
            const SizedBox(height: MmSpace.s4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(minHeight: 4, color: tone, backgroundColor: tone.withValues(alpha: 0.15)),
            ),
          ],
        ],
      ),
    );

    return PopIn(
      key: ValueKey(state.phase),
      child: Semantics(
        liveRegion: true,
        child: state.phase == PurchasePhase.success
            ? Stack(
                clipBehavior: Clip.none,
                children: [
                  card,
                  const Positioned.fill(child: Confetti(seed: 7)),
                ],
              )
            : card,
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.color, required this.child});

  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => PopIn(
    delay: const Duration(milliseconds: 80),
    child: Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), shape: BoxShape.circle),
      child: IconTheme(
        data: IconThemeData(color: color, size: 28),
        child: Center(child: child),
      ),
    ),
  );
}

/// A ring that spins while the server confirms the purchase.
class _Spinner extends ConsumerStatefulWidget {
  const _Spinner({required this.color});
  final Color color;

  @override
  ConsumerState<_Spinner> createState() => _SpinnerState();
}

class _SpinnerState extends ConsumerState<_Spinner> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduceMotionOf(context, ref) ? _c.stop() : _c.repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 52,
    child: RotationTransition(
      turns: _c,
      child: CircularProgressIndicator(value: 0.7, strokeWidth: 5, color: widget.color, strokeCap: StrokeCap.round),
    ),
  );
}

/// A check or a cross whose strokes draw themselves.
class _DrawnMark extends ConsumerStatefulWidget {
  const _DrawnMark({required this.color, required this.cross});

  final Color color;
  final bool cross;

  @override
  ConsumerState<_DrawnMark> createState() => _DrawnMarkState();
}

class _DrawnMarkState extends ConsumerState<_DrawnMark> with SingleTickerProviderStateMixin {
  late final _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 450));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotionOf(context, ref)) {
      _c.value = 1;
    } else if (!_c.isAnimating && _c.value == 0) {
      Future.delayed(const Duration(milliseconds: 200), () => mounted ? _c.forward() : null);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 28,
    child: AnimatedBuilder(
      animation: _c,
      builder: (_, _) =>
          CustomPaint(painter: _MarkPainter(Curves.easeOut.transform(_c.value), widget.color, widget.cross)),
    ),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter(this.t, this.color, this.cross);

  final double t;
  final Color color;
  final bool cross;

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final strokes = cross
        ? [
            Path()
              ..moveTo(7 * s, 7 * s)
              ..lineTo(17 * s, 17 * s),
            Path()
              ..moveTo(17 * s, 7 * s)
              ..lineTo(7 * s, 17 * s),
          ]
        : [
            Path()
              ..moveTo(5 * s, 12.5 * s)
              ..lineTo(9.5 * s, 17 * s)
              ..lineTo(19 * s, 7.5 * s),
          ];
    // Strokes draw one after another.
    for (var i = 0; i < strokes.length; i++) {
      final part = ((t * strokes.length) - i).clamp(0.0, 1.0);
      if (part == 0) continue;
      for (final metric in strokes[i].computeMetrics()) {
        canvas.drawPath(metric.extractPath(0, metric.length * part), paint);
      }
    }
  }

  @override
  bool shouldRepaint(_MarkPainter old) => old.t != t || old.color != color;
}
