import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleefy/router/router.dart';
import 'package:gleefy/state/progress.dart';

import 'analytics_test.dart' show playShortGame;
import 'support/harness.dart';

Future<void> go(WidgetTester tester, Harness h, String location) async {
  h.container.read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a finished game earns XP and a trophy, shown on the results and kept on the phone', (tester) async {
    final h = await pumpApp(tester, content: tinyContent(casual: 6));
    expect(find.text('Start your party level'), findsOneWidget);

    playShortGame(h);
    await go(tester, h, '/play/would-you-rather/results');
    // 10 per game + 2 per round × 5 + 5 for the first game of the day.
    expect(find.text('+25 XP'), findsOneWidget);
    expect(find.text('25 XP to level 2'), findsOneWidget);
    await tester.ensureVisible(find.text('Ice Breaker'));
    expect(find.text('Ice Breaker'), findsOneWidget);
    expect(h.prefs.getString(ProgressController.storageKey), contains('"xp":25'));

    await go(tester, h, '/');
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('25 / 50 XP'), findsOneWidget);
  });

  testWidgets('enough XP levels up, and a new game starts without the last reward', (tester) async {
    final h = await pumpApp(tester, content: tinyContent(casual: 6));
    playShortGame(h);
    playShortGame(h);
    expect(h.container.read(lastRewardProvider)?.leveledUp, isFalse);
    playShortGame(h);
    await go(tester, h, '/play/would-you-rather/results');
    expect(find.text('Level up! You’re now level 2'), findsOneWidget);
    expect(h.container.read(progressProvider).gamesPlayed, 3);
    expect(h.container.read(streakProvider), 1);
  });

  testWidgets('the trophy room shows stats and earned and locked trophies', (tester) async {
    final h = await pumpApp(
      tester,
      initialPrefs: {
        ProgressController.storageKey:
            '{"xp":160,"gamesPlayed":6,"modesPlayed":["trivia"],"streak":3,"bestStreak":3,'
            '"lastPlayedDay":"${_today(h0)}","trophies":["first-game","regular","streak-3"]}',
      },
    );
    await go(tester, h, '/');
    await tester.tap(find.bySemanticsLabel(RegExp('^Level 3')));
    await tester.pumpAndSettle();
    expect(find.text('Trophies'), findsOneWidget);
    expect(find.text('Level 3'), findsOneWidget);
    expect(find.text('3 of 9 trophies'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('On a Roll'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('On a Roll'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Rising Star'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.textContaining('Not earned yet'), findsWidgets);
  });
}

/// The harness clock, so the stored streak counts as current.
final h0 = DateTime.now();
String _today(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
