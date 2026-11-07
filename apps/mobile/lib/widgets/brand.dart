import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';

/// The Gleefy mark: a grinning party face in a gold hat (same drawing as scripts/brand-icons.mjs).
class GleefyMark extends StatelessWidget {
  const GleefyMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: const _MarkPainter()),
  );
}

class _MarkPainter extends CustomPainter {
  const _MarkPainter();

  static const _ink = Color(0xFF1D1530);
  static const _cream = Color(0xFFFFF6E5);

  @override
  void paint(Canvas canvas, Size size) {
    // The drawing lives in the box (150, 30)–(850, 900) of a 1024 canvas; fit it, centred.
    final scale = size.height / 870;
    canvas
      ..save()
      ..translate((size.width - 700 * scale) / 2, 0)
      ..scale(scale)
      ..translate(-150, -30);
    Paint fill(Color c) => Paint()..color = c;
    Paint stroke(double w, [Color c = _ink]) => Paint()
      ..color = c
      ..style = PaintingStyle.stroke
      ..strokeWidth = w
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    const head = Offset(512, 580);
    canvas
      ..drawCircle(head, 300, fill(_cream))
      ..drawCircle(head, 300, stroke(30))
      ..drawCircle(const Offset(372, 650), 40, fill(const Color(0xBFFF8FAB)))
      ..drawCircle(const Offset(652, 650), 40, fill(const Color(0xBFFF8FAB)));
    final eyes = Path()
      ..moveTo(370, 548)
      ..relativeQuadraticBezierTo(50, -62, 100, 0)
      ..moveTo(554, 548)
      ..relativeQuadraticBezierTo(50, -62, 100, 0);
    canvas.drawPath(eyes, stroke(34));
    final mouth = Path()
      ..moveTo(384, 628)
      ..quadraticBezierTo(512, 820, 640, 628)
      ..close();
    canvas
      ..drawPath(mouth, fill(_ink))
      ..drawPath(mouth, stroke(22));
    final tongue = Path()
      ..moveTo(458, 684)
      ..relativeQuadraticBezierTo(54, 30, 108, 0)
      ..relativeQuadraticBezierTo(-10, 34, -54, 36)
      ..relativeQuadraticBezierTo(-44, -2, -54, -36)
      ..close();
    canvas.drawPath(tongue, fill(const Color(0xFFFF5C8A)));
    final hat = Path()
      ..moveTo(548, 292)
      ..lineTo(742, 72)
      ..lineTo(790, 350)
      ..close();
    canvas
      ..drawPath(hat, fill(const Color(0xFFFFB020)))
      ..drawPath(hat, stroke(26));
    final stripes = Path()
      ..moveTo(622, 232)
      ..lineTo(754, 196)
      ..moveTo(650, 290)
      ..lineTo(770, 262);
    canvas
      ..drawPath(stripes, stroke(22, const Color(0xFFC42654)))
      ..drawCircle(const Offset(742, 72), 44, fill(_cream))
      ..drawCircle(const Offset(742, 72), 44, stroke(22))
      ..restore();
  }

  @override
  bool shouldRepaint(_MarkPainter old) => false;
}

class GleefyWordmark extends StatelessWidget {
  const GleefyWordmark({super.key, this.size = 28});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      label: 'Gleefy',
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            GleefyMark(size: size * 1.2),
            const SizedBox(width: MmSpace.s2),
            Text(
              'Gleefy',
              style: TextStyle(fontFamily: MmFont.display, fontWeight: FontWeight.w700, fontSize: size),
            ),
          ],
        ),
      ),
    );
  }
}

/// A rounded card filled with the brand gradient. Text on it is white (contrast tested in tokens).
class GradientPanel extends StatelessWidget {
  const GradientPanel({super.key, required this.child, this.onTap, this.padding = const EdgeInsets.all(MmSpace.s6)});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: MmPalette.of(context).gradient,
        borderRadius: BorderRadius.circular(MmRadius.xl),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          borderRadius: BorderRadius.circular(MmRadius.xl),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: DefaultTextStyle.merge(
              style: const TextStyle(color: Colors.white),
              child: IconTheme.merge(
                data: const IconThemeData(color: Colors.white),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
