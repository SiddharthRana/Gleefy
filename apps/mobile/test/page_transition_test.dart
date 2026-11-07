import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirthmix/router/router.dart';

import 'support/harness.dart';

/// Scale of the new page's own transition (the outermost one inside its route).
double incomingScale(WidgetTester tester, Finder page) {
  final scales = find.ancestor(of: page, matching: find.byType(ScaleTransition));
  return tester.widgetList<ScaleTransition>(scales).map((t) => t.scale.value).reduce((a, b) => a < b ? a : b);
}

void main() {
  testWidgets('a new page springs in, overshooting slightly before it settles', (tester) async {
    final h = await pumpApp(tester);
    unawaited(h.container.read(routerProvider).push<void>('/settings'));
    // The router checks the destination first (onEnter), then adds the route.
    await tester.pump();
    await tester.pump(); // route added
    await tester.pump(const Duration(milliseconds: 60));
    final page = find.text('Theme');
    expect(incomingScale(tester, page), lessThan(1));
    // easeOutBack overshoots past full size before settling.
    var peak = 0.0;
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 20));
      final s = tester
          .widgetList<ScaleTransition>(find.ancestor(of: page, matching: find.byType(ScaleTransition)))
          .map((t) => t.scale.value)
          .reduce((a, b) => a > b ? a : b);
      if (s > peak) peak = s;
    }
    expect(peak, greaterThan(1));
    await tester.pumpAndSettle();
    expect(incomingScale(tester, page), 1);
  });

  testWidgets('the page underneath shrinks back while a new one comes in', (tester) async {
    final h = await pumpApp(tester);
    final home = find.text('Ready to play?');
    unawaited(h.container.read(routerProvider).push<void>('/settings'));
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 150));
    expect(incomingScale(tester, home), lessThan(1));
  });

  testWidgets('with Reduce motion on, pages appear without moving', (tester) async {
    final h = await pumpApp(tester, initialPrefs: {'settings.reduceMotion': true});
    unawaited(h.container.read(routerProvider).push<void>('/settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    final page = find.text('Theme');
    expect(find.ancestor(of: page, matching: find.byType(ScaleTransition)), findsNothing);
    expect(find.ancestor(of: page, matching: find.byType(SlideTransition)), findsNothing);
  });
}
