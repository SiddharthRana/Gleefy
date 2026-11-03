import 'package:flutter/material.dart';

/// Page changes that feel like dealing a card: the new page springs up into place (a small rise,
/// growing from 92% with a slight overshoot, fading in) while the page underneath shrinks back.
/// Going back plays it in reverse. With [still] (the in-app Reduce motion switch) or the system
/// "remove animations" setting, pages simply appear.
class GamePageTransitionsBuilder extends PageTransitionsBuilder {
  const GamePageTransitionsBuilder({this.still = false});

  final bool still;

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return wrap(context, animation, secondaryAnimation, child, still: still);
  }

  /// The transition itself, shared with go_router pages (see GamePage in router/game_page.dart).
  static Widget wrap(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child, {
    bool still = false,
  }) {
    if (still || MediaQuery.disableAnimationsOf(context)) return child;
    return _GamePageTransition(animation: animation, secondaryAnimation: secondaryAnimation, child: child);
  }
}

class _GamePageTransition extends StatelessWidget {
  const _GamePageTransition({required this.animation, required this.secondaryAnimation, required this.child});

  final Animation<double> animation;
  final Animation<double> secondaryAnimation;
  final Widget child;

  static final _rise = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero);
  static final _grow = Tween<double>(begin: 0.92, end: 1);
  static final _shrinkBack = Tween<double>(begin: 1, end: 0.94);

  @override
  Widget build(BuildContext context) {
    final spring = CurvedAnimation(parent: animation, curve: Curves.easeOutBack, reverseCurve: Curves.easeInCubic);
    final fade = CurvedAnimation(
      parent: animation,
      curve: const Interval(0, 0.55, curve: Curves.easeOut),
      reverseCurve: const Interval(0.3, 1, curve: Curves.easeIn),
    );
    final behind = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(
      opacity: fade,
      child: SlideTransition(
        position: _rise.animate(spring),
        child: ScaleTransition(
          scale: _grow.animate(spring),
          // The page's own background fills the edges while it shrinks back under a new page.
          child: ColoredBox(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: ScaleTransition(scale: _shrinkBack.animate(behind), child: child),
          ),
        ),
      ),
    );
  }
}
