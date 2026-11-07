import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleefy/router/router.dart';

import 'support/harness.dart';

/// Android draws apps edge to edge, under the navigation bar. Lists must leave room for it so the
/// last item can scroll fully into view (it used to stay hidden behind the bar on Home).
void main() {
  for (final route in ['/', '/settings', '/games', '/trophies']) {
    testWidgets('$route scrolls its last item clear of the navigation bar', (tester) async {
      const bar = 48.0; // logical pixels
      tester.view.padding = FakeViewPadding(bottom: bar * tester.view.devicePixelRatio);
      addTearDown(tester.view.resetPadding);
      final h = await pumpApp(tester, content: realContent());
      h.container.read(routerProvider).go(route);
      await tester.pumpAndSettle();

      final list = find.byType(Scrollable).first;
      final position = tester.state<ScrollableState>(list).position;
      // A lazy list only knows its full length once the last items are built, so jump until it stops growing.
      for (var i = 0; i < 5; i++) {
        position.jumpTo(position.maxScrollExtent);
        await tester.pumpAndSettle();
      }

      final screenBottom = tester.view.physicalSize.height / tester.view.devicePixelRatio;
      final items = find.descendant(of: list, matching: find.byWidgetPredicate((w) => w is Card || w is ListTile));
      final lowest = items
          .evaluate()
          .map((e) => tester.getRect(find.byWidget(e.widget).first).bottom)
          .reduce((a, b) => a > b ? a : b);
      expect(lowest, lessThanOrEqualTo(screenBottom - bar));
    });
  }
}
