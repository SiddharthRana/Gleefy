import 'package:go_router/go_router.dart';

import '../theme/page_transitions.dart';

/// Every route's page: the "dealt card" transition from [GamePageTransitionsBuilder], set here
/// explicitly so it doesn't depend on go_router detecting the app type. [still] (Reduce motion)
/// makes pages appear instantly.
class GamePage<T> extends CustomTransitionPage<T> {
  GamePage({required super.child, super.key, bool still = false})
    : super(
        transitionDuration: still ? Duration.zero : const Duration(milliseconds: 420),
        reverseTransitionDuration: still ? Duration.zero : const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            GamePageTransitionsBuilder.wrap(context, animation, secondaryAnimation, child, still: still),
      );
}
