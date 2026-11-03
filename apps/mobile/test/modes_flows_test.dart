import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirthmix/router/router.dart';
import 'package:mirthmix/state/games.dart';
import 'package:mirthmix/state/sessions.dart';

import 'support/harness.dart';

Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 150, scrollable: find.byType(Scrollable).first);
  }
  if (finder.hitTestable().evaluate().isNotEmpty) return;
  final scrollable = find.ancestor(of: finder.first, matching: find.byType(Scrollable)).first;
  await tester.dragUntilVisible(finder.hitTestable(), scrollable, const Offset(0, -150));
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  await reveal(tester, find.text(text));
  await tester.tap(find.text(text).hitTestable().first);
  await tester.pumpAndSettle();
}

/// Taps without settling: a running countdown keeps scheduling frames.
Future<void> tapNow(WidgetTester tester, Finder finder) async {
  await tester.tap(finder.hitTestable().first);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> goBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Future<void> openSetup(WidgetTester tester, String mode) async {
  await tapText(tester, 'See all');
  await tapText(tester, mode);
}

Future<Harness> withPlayers(WidgetTester tester, List<String> names) async {
  final h = await pumpApp(tester);
  h.container.read(lineupProvider.notifier).set(names);
  await tester.pumpAndSettle();
  return h;
}

void main() {
  sharedLinkTests();
  testWidgets('players screen adds, removes and caps names', (tester) async {
    final h = await pumpApp(tester);
    await tester.tap(find.byTooltip('Players and teams'));
    await tester.pumpAndSettle();
    for (final name in ['Asha', 'Ben']) {
      await tester.enterText(find.byType(TextField), name);
      await tapText(tester, 'Add');
    }
    expect(h.container.read(lineupProvider), ['Asha', 'Ben']);
    await tester.tap(find.byTooltip('Remove Asha'));
    await tester.pumpAndSettle();
    expect(h.container.read(lineupProvider), ['Ben']);
    expect(h.prefs.getStringList('lineup.names'), ['Ben']);

    h.container.read(lineupProvider.notifier).set([for (var i = 0; i < 20; i++) 'P$i']);
    expect(h.container.read(lineupProvider).length, maxNames);
  });

  testWidgets('This or That: one tap per pair for the room', (tester) async {
    final h = await pumpApp(tester);
    await openSetup(tester, 'This or That');
    expect(find.text('Playing as one group'), findsOneWidget);
    await tapText(tester, 'Start game');
    expect(find.text('Round 1 of 3'), findsOneWidget);
    expect(find.text("Tap the room's pick"), findsOneWidget);
    await tester.tap(find.textContaining('Tea').first);
    await tester.pumpAndSettle();
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('Defend your pick in 10 seconds.'), findsOneWidget);
    await tapText(tester, 'Next round');
    await tester.tap(find.textContaining('Coffee').first);
    await tester.pumpAndSettle();
    await tapText(tester, 'Next round');
    await tester.tap(find.textContaining('Coffee').first);
    await tester.pumpAndSettle();
    await tapText(tester, 'See results');
    expect(find.text('Results'), findsOneWidget);
    expect(h.container.read(totSessionProvider)!.rounds.length, 3);
  });

  testWidgets('This or That: pass the phone shows each turn and who agreed most', (tester) async {
    await withPlayers(tester, ['Asha', 'Ben', 'Chen']);
    await openSetup(tester, 'This or That');
    await tapText(tester, 'Pass the phone');
    await tapText(tester, 'Start game');
    for (var round = 0; round < 3; round++) {
      expect(find.text("Asha's pick"), findsOneWidget);
      await tester.tap(find.textContaining('Tea').first);
      await tester.pumpAndSettle();
      expect(find.text("Ben's pick"), findsOneWidget);
      await tester.tap(find.textContaining('Tea').first);
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Coffee').first);
      await tester.pumpAndSettle();
      expect(find.text('Asha, Ben'), findsOneWidget);
      await tapText(tester, round == 2 ? 'See results' : 'Next round');
    }
    expect(find.text('Most in sync: Asha & Ben'), findsOneWidget);
    expect(find.text('Same pick 3 of 3 times'), findsOneWidget);
  });

  testWidgets('This or That: the 5-second timer reveals with no pick', (tester) async {
    await pumpApp(tester);
    await openSetup(tester, 'This or That');
    await tapText(tester, '5-second timer');
    await tapText(tester, 'Start game');
    expect(find.text('5s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
    expect(find.text("Time's up!"), findsOneWidget);
  });

  testWidgets('Trivia: teams take turns, score and see standings', (tester) async {
    await withPlayers(tester, ['Reds', 'Blues']);
    await openSetup(tester, 'Trivia Blitz');
    expect(find.text('Reds, Blues'), findsOneWidget);
    await tapText(tester, 'Off');
    await tapText(tester, 'Start game');

    expect(find.text('Question 1 of 3'), findsOneWidget);
    expect(find.text("Reds's turn"), findsOneWidget);
    await tester.tap(find.textContaining('Right').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.text('Correct! +100'), findsOneWidget);
    await reveal(tester, find.textContaining('Because'));
    expect(find.textContaining('Because'), findsOneWidget);
    await tapText(tester, 'Next round');

    expect(find.text("Blues's turn"), findsOneWidget);
    await tester.tap(find.textContaining('Wrong').hitTestable().first);
    await tester.pumpAndSettle();
    expect(find.text('Not quite.'), findsOneWidget);
    await reveal(tester, find.textContaining('Answer: Right'));
    expect(find.textContaining('Answer: Right'), findsOneWidget);
    await tapText(tester, 'Next round');

    expect(find.text("Reds's turn"), findsOneWidget);
    await tester.tap(find.textContaining('Right').hitTestable().first);
    await tester.pumpAndSettle();
    await tapText(tester, 'See results');

    expect(find.text('Reds wins!'), findsOneWidget);
    expect(find.text('200 pts'), findsOneWidget);
    expect(find.text('2 of 2 correct'), findsOneWidget);
    expect(find.text('0 of 1 correct'), findsOneWidget);
  });

  testWidgets('Trivia timer: fast answers earn a bonus, and time can run out', (tester) async {
    final h = await pumpApp(tester);
    await openSetup(tester, 'Trivia Blitz');
    await tapText(tester, '10s');
    await reveal(tester, find.text('Start game'));
    await tapNow(tester, find.text('Start game'));
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('9s'), findsOneWidget);
    await tapNow(tester, find.textContaining('Right'));
    final points = h.container.read(triviaSessionProvider)!.current!.points;
    expect(points, inInclusiveRange(140, 149));
    expect(find.text('Correct! +$points'), findsOneWidget);
    await tapNow(tester, find.text('Next round'));
    await tester.pump(const Duration(seconds: 11));
    expect(find.text("Time's up!"), findsOneWidget);
    expect(h.container.read(triviaSessionProvider)!.current!.timedOut, isTrue);
  });

  testWidgets('Trivia timer pauses while the app is in the background', (tester) async {
    final h = await pumpApp(tester);
    await openSetup(tester, 'Trivia Blitz');
    await tapText(tester, '10s');
    await reveal(tester, find.text('Start game'));
    await tapNow(tester, find.text('Start game'));
    await tester.pump(const Duration(seconds: 3));
    for (final s in [AppLifecycleState.inactive, AppLifecycleState.hidden, AppLifecycleState.paused]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump(const Duration(seconds: 30));
    for (final s in [AppLifecycleState.hidden, AppLifecycleState.inactive, AppLifecycleState.resumed]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await tester.pump(const Duration(milliseconds: 200));
    expect(h.container.read(triviaSessionProvider)!.current!.timedOut, isFalse);
    expect(find.text('7s'), findsOneWidget);
    await tester.pump(const Duration(seconds: 8));
    expect(h.container.read(triviaSessionProvider)!.current!.timedOut, isTrue);
  });

  testWidgets('Guess the Answer: clues cost points; giving up scores nothing', (tester) async {
    await withPlayers(tester, ['Asha', 'Ben']);
    await openSetup(tester, 'Guess the Answer');
    await tapText(tester, 'Start game');
    expect(find.text('Card 1 of 3'), findsOneWidget);
    expect(find.text('Asha guesses'), findsOneWidget);
    expect(find.text('Worth 3 points'), findsOneWidget);
    expect(find.textContaining('Hard'), findsOneWidget);
    expect(find.textContaining('Easy'), findsNothing);
    await tapText(tester, 'Next clue');
    expect(find.text('Worth 2 points'), findsOneWidget);
    await tapText(tester, 'Got it!');
    expect(find.text('+2 for Asha'), findsOneWidget);
    await tapText(tester, 'Next round');

    expect(find.text('Ben guesses'), findsOneWidget);
    await tapText(tester, 'Give up');
    expect(find.text('No points this time.'), findsOneWidget);
    await tapText(tester, 'Next round');
    await tapText(tester, 'Got it!');
    await tapText(tester, 'See results');
    expect(find.text('Asha wins!'), findsOneWidget);
    expect(find.text('5 pts'), findsOneWidget);
  });

  testWidgets('favourites are saved from setup and start from home', (tester) async {
    final h = await pumpApp(tester);
    await openSetup(tester, 'Guess the Answer');
    await tester.tap(find.byTooltip('Save as favourite'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Friday guesses');
    await tapText(tester, 'Save');
    expect(h.container.read(favouritesProvider).single.name, 'Friday guesses');
    await goBack(tester);
    await goBack(tester);
    await tapText(tester, 'Friday guesses');
    expect(find.text('Card 1 of 3'), findsOneWidget);
  });

  testWidgets('recent games appear on home for a quick replay', (tester) async {
    final h = await pumpApp(tester);
    await tapText(tester, 'Quick play');
    await tester.tap(find.byTooltip('Quit game'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Quit');
    expect(h.container.read(recentsProvider), hasLength(1));
    expect(find.text('Play again'), findsOneWidget);
    await tester.tap(find.widgetWithText(ActionChip, 'Would You Rather'));
    await tester.pumpAndSettle();
    expect(find.text('Round 1 of 3'), findsOneWidget);
  });

  testWidgets('custom party pack plays games back to back', (tester) async {
    final h = await pumpApp(tester);
    await openSetup(tester, 'Custom Party Pack');
    // Default: Would You Rather, Trivia and Guess. Keep two of them.
    await tapText(tester, 'Trivia Blitz');
    await tapText(tester, '3');
    await tapText(tester, 'Start party');

    expect(find.text('Round 1 of 3'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tapText(tester, 'Reveal');
      await tapText(tester, i == 2 ? 'See results' : 'Next round');
    }
    expect(find.text('Party game 1 of 2'), findsOneWidget);
    await tapText(tester, 'Next: Guess the Answer');
    expect(find.text('Card 1 of 3'), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tapText(tester, 'Got it!');
      await tapText(tester, i == 2 ? 'See results' : 'Next round');
    }
    expect(find.text('Party game 2 of 2'), findsOneWidget);
    await tapText(tester, 'Finish party');
    expect(find.text('Ready to play?'), findsOneWidget);
    expect(h.container.read(partyProvider), isNull);
  });

  testWidgets('a trivia game survives a relaunch', (tester) async {
    final h = await pumpApp(tester);
    await openSetup(tester, 'Trivia Blitz');
    await tapText(tester, 'Start game');
    await tapText(tester, (find.textContaining('Right').evaluate().first.widget as Text).data!);
    await tester.pumpAndSettle();
    await tapText(tester, 'Next round');
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, prefs: h.prefs);
    expect(find.text('Trivia Blitz · round 2 of 3'), findsOneWidget);
    await tapText(tester, 'Resume');
    expect(find.text('Question 2 of 3'), findsOneWidget);
  });

  testWidgets('premium categories are locked in every mode', (tester) async {
    await pumpApp(tester, content: realContent());
    for (final mode in ['This or That', 'Trivia Blitz', 'Guess the Answer']) {
      await openSetup(tester, mode);
      // Each mode now has several premium categories; scroll until the first one is built.
      final locked = find.textContaining('Unlock with Premium.');
      for (var i = 0; i < 20 && locked.evaluate().isEmpty; i++) {
        await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
        await tester.pumpAndSettle();
      }
      expect(locked, findsWidgets, reason: mode);
      await goBack(tester);
      await goBack(tester);
    }
  });
}

void sharedLinkTests() {
  testWidgets('a shared website link opens the same game in the app', (tester) async {
    final h = await pumpApp(tester);
    h.container.read(routerProvider).go('/play?c=eyJtIjozLCJjIjpbImNhc3VhbCJdLCJyIjozLCJzIjo0Mn0');
    await tester.pumpAndSettle();
    expect(find.text('Card 1 of 3'), findsOneWidget);
    expect(h.container.read(guessSessionProvider)!.config.seed, 42);
  });

  testWidgets('a broken shared link explains itself', (tester) async {
    final h = await pumpApp(tester);
    h.container.read(routerProvider).go('/play?c=broken');
    await tester.pumpAndSettle();
    expect(find.text('This game link is broken or out of date.'), findsOneWidget);
  });
}
