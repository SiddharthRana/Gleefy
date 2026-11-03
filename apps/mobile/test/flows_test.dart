import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirthmix/app.dart';
import 'package:mirthmix/state/sessions.dart';

import 'support/harness.dart';

/// Scrolls the first scrollable until [finder] is on screen (lists build lazily).
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

Future<void> vote(WidgetTester tester, String side) async {
  await tester.tap(find.textContaining(side == 'a' ? 'Apple' : 'Banana').first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('first launch shows onboarding once, then home', (tester) async {
    final h = await pumpApp(tester, onboarded: false);
    expect(find.text('Party games for one phone'), findsWidgets);
    expect(find.text('MirthMix is made for ages 13 and up.'), findsOneWidget);
    await tapText(tester, 'Next');
    await tapText(tester, 'Next');
    await tapText(tester, "Let's play");
    expect(find.text('Ready to play?'), findsOneWidget);
    expect(h.prefs.getBool('settings.onboarded'), isTrue);
  });

  testWidgets('onboarding can be skipped', (tester) async {
    await pumpApp(tester, onboarded: false);
    await tapText(tester, 'Skip');
    expect(find.text('Ready to play?'), findsOneWidget);
  });

  testWidgets('quick play runs a full game to results and replays', (tester) async {
    final h = await pumpApp(tester);
    await tapText(tester, 'Quick play');

    // Tiny pack: 3 free questions, so 10 rounds are capped at 3.
    expect(find.text('Round 1 of 3'), findsOneWidget);
    expect(h.awake.on, isTrue);
    await vote(tester, 'a');
    await vote(tester, 'b');
    await vote(tester, 'b');
    expect(find.text('3 votes'), findsOneWidget);
    await tapText(tester, 'Undo');
    expect(find.text('2 votes'), findsOneWidget);
    await tapText(tester, 'Reveal');
    expect(find.text('Perfect split!'), findsOneWidget);
    expect(find.text('Undo'), findsNothing);
    await tapText(tester, 'Next round');

    expect(find.text('Round 2 of 3'), findsOneWidget);
    await vote(tester, 'a');
    await vote(tester, 'a');
    await tapText(tester, 'Reveal');
    expect(find.text('Everyone agrees!'), findsOneWidget);
    await tapText(tester, 'Next round');

    expect(find.text('Round 3 of 3'), findsOneWidget);
    await tapText(tester, 'Reveal');
    expect(find.text('No votes this round.'), findsOneWidget);
    await tapText(tester, 'See results');

    expect(find.text('Results'), findsOneWidget);
    expect(find.text('3 rounds · 4 votes'), findsOneWidget);
    expect(find.text('Most divisive'), findsOneWidget);
    expect(find.text('Most unanimous'), findsOneWidget);
    expect(h.awake.on, isFalse);

    await tapText(tester, 'Play again');
    expect(find.text('Round 1 of 3'), findsOneWidget);
    expect(find.text('No votes'), findsOneWidget);
  });

  testWidgets('skip swaps the question, then spends the round when none are left', (tester) async {
    final h = await pumpApp(tester, content: tinyContent(casual: 2));
    await tapText(tester, 'Quick play');
    expect(find.text('Round 1 of 2'), findsOneWidget);
    final first = h.container.read(wyrSessionProvider)!.current!.questionId;
    await tapText(tester, 'Skip');
    expect(find.text('Round 1 of 2'), findsOneWidget);
    expect(h.container.read(wyrSessionProvider)!.current!.questionId, isNot(first));
    await tapText(tester, 'Skip');
    expect(find.text('Results'), findsOneWidget);
    expect(find.textContaining('Skipped'), findsOneWidget);
  });

  testWidgets('quitting asks for confirmation, from the close button and system back', (tester) async {
    final h = await pumpApp(tester);
    await tapText(tester, 'Quick play');

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Quit this game?'), findsOneWidget);
    await tapText(tester, 'Keep playing');
    expect(find.text('Round 1 of 3'), findsOneWidget);

    await tester.tap(find.byTooltip('Quit game'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Quit');
    expect(find.text('Ready to play?'), findsOneWidget);
    expect(find.text('Game in progress'), findsNothing);
    expect(h.container.read(wyrSessionProvider), isNull);
    expect(h.prefs.getString('session.wyr'), isNull);
  });

  testWidgets('a game survives the app being killed and relaunched', (tester) async {
    final h = await pumpApp(tester);
    await tapText(tester, 'Quick play');
    await vote(tester, 'a');
    await tapText(tester, 'Reveal');
    await tapText(tester, 'Next round');
    await vote(tester, 'b');
    final before = h.container.read(wyrSessionProvider)!.toJson();

    // Relaunch with the same storage but fresh providers.
    await tester.pumpWidget(const SizedBox());
    final relaunched = await pumpApp(tester, prefs: h.prefs);
    expect(find.text('Game in progress'), findsOneWidget);
    expect(find.text('Would You Rather · round 2 of 3'), findsOneWidget);
    expect(relaunched.container.read(wyrSessionProvider)!.toJson(), before);
    await tapText(tester, 'Resume');
    expect(find.text('Round 2 of 3'), findsOneWidget);
    expect(find.text('1 vote'), findsOneWidget);
  });

  testWidgets('a saved session pointing at removed content is discarded', (tester) async {
    final h = await pumpApp(tester, content: tinyContent(casual: 3));
    await tapText(tester, 'Quick play');
    await tester.pumpWidget(const SizedBox());
    await pumpApp(tester, prefs: h.prefs, content: tinyContent(casual: 1));
    expect(find.text('Game in progress'), findsNothing);
    expect(h.prefs.getString('session.wyr'), isNull);
  });

  testWidgets('setup: premium is locked, a category is required, group size caps votes', (tester) async {
    await pumpApp(tester);
    await tapText(tester, 'See all');
    await tapText(tester, 'Would You Rather');
    expect(find.text('Set up the game'), findsNothing);
    expect(find.text('How to play'), findsOneWidget);

    // Premium category is visible, labelled and can't be ticked.
    expect(find.textContaining('Unlock with Premium.'), findsOneWidget);
    expect(find.text('Serious topics'), findsOneWidget);
    final deep = tester.widget<CheckboxListTile>(find.widgetWithText(CheckboxListTile, 'Deep'));
    expect(deep.onChanged, isNull);

    // Fewer questions than rounds is explained.
    await reveal(tester, find.text("Only 3 questions in these categories, so you'll play 3 rounds."));
    expect(find.text("Only 3 questions in these categories, so you'll play 3 rounds."), findsOneWidget);

    // Deselecting the only free category disables Start.
    await tapText(tester, 'Casual');
    final start = find.widgetWithText(FilledButton, 'Start game');
    expect(tester.widget<FilledButton>(start).onPressed, isNull);
    await tapText(tester, 'Casual');

    await reveal(tester, find.byTooltip('More players'));
    await tester.tap(find.byTooltip('More players'));
    await tester.pumpAndSettle();
    expect(find.text('2 players'), findsOneWidget);
    await tapText(tester, 'Start game');

    await vote(tester, 'a');
    await vote(tester, 'b');
    await vote(tester, 'a');
    expect(find.text('2 of 2 votes'), findsOneWidget);
  });

  testWidgets('setup remembers the last configuration', (tester) async {
    final h = await pumpApp(tester);
    await tapText(tester, 'See all');
    await tapText(tester, 'Would You Rather');
    await tapText(tester, '5');
    await tapText(tester, 'Start game');
    expect(h.container.read(wyrSessionProvider)!.config.rounds, 5);
    await tester.tap(find.byTooltip('Quit game'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Quit');
    await tapText(tester, 'See all');
    await tapText(tester, 'Would You Rather');
    final rounds = tester.widget<SegmentedButton<int>>(find.byType(SegmentedButton<int>));
    expect(rounds.selected, {5});
  });

  testWidgets('settings persist and big text scales the app', (tester) async {
    final h = await pumpApp(tester);
    await tester.tap(find.byTooltip('Settings'));
    await tester.pumpAndSettle();
    await tapText(tester, 'Big text');
    await tapText(tester, 'Dark');
    expect(h.prefs.getBool('settings.bigText'), isTrue);
    expect(h.prefs.getString('settings.themeMode'), 'dark');
    final context = tester.element(find.text('Big text'));
    expect(MediaQuery.textScalerOf(context).scale(10), closeTo(12.5, 0.01));
    expect(Theme.of(context).brightness, Brightness.dark);
    await reveal(tester, find.textContaining('You can play without an account'));
    expect(find.textContaining('You can play without an account'), findsOneWidget);
  });

  testWidgets('the real starter content plays', (tester) async {
    await pumpApp(tester, content: realContent());
    await tapText(tester, 'Quick play');
    expect(find.text('Round 1 of 10'), findsOneWidget);
  });

  testWidgets('content error screen explains the problem', (tester) async {
    await tester.pumpWidget(const ContentErrorApp());
    await tester.pumpAndSettle();
    expect(find.text("Games couldn't load"), findsOneWidget);
  });

  testWidgets('game controls meet the touch target guidelines', (tester) async {
    await pumpApp(tester);
    await tapText(tester, 'Quick play');
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
    await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  });
}
