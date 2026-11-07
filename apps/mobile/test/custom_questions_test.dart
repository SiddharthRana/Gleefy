import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleefy/content/content.dart';
import 'package:gleefy/content/profanity.dart';
import 'package:gleefy/router/router.dart';
import 'package:gleefy/state/custom_questions.dart';
import 'package:gleefy/state/sessions.dart';

import 'support/harness.dart';

const wyr = GameMode.wouldYouRather;
const tot = GameMode.thisOrThat;
const mine = WyrItem(id: 'wyr-mine-1', category: customCategoryId, a: 'Tea', b: 'Coffee');

Future<void> reveal(WidgetTester tester, Finder finder) async {
  if (finder.evaluate().isEmpty) {
    await tester.scrollUntilVisible(finder, 150, scrollable: find.byType(Scrollable).first);
  }
  await tester.pumpAndSettle();
}

Future<void> tapText(WidgetTester tester, String text) async {
  await reveal(tester, find.text(text));
  await tester.tap(find.text(text).hitTestable().first);
  await tester.pumpAndSettle();
}

void main() {
  group('profanity filter', () {
    test('blocks common swear words, slurs and Hinglish abuse', () {
      for (final bad in [
        'What the fuck',
        'Shit happens',
        'tu chutiya hai',
        'BITCHES',
        'f*ck this',
        'sh1t',
        'fuuuuck',
      ]) {
        expect(containsProfanity(bad), isTrue, reason: bad);
      }
    });

    test('allows ordinary words that contain blocked ones', () {
      for (final ok in [
        'Scunthorpe United',
        'A cocktail party',
        'Assassin or wizard',
        'Shitake mushrooms',
        'Pass the class',
      ]) {
        expect(containsProfanity(ok), isFalse, reason: ok);
      }
    });
  });

  group('saving rules', () {
    test('accepts a normal question', () => expect(checkCustom(wyr, 'Fly', 'Be invisible', const []), isNull));

    test('refuses empty, too long, identical, rude and duplicate questions', () {
      expect(checkCustom(wyr, '  ', 'b', const []), CustomProblem.empty);
      expect(checkCustom(tot, 'x' * 41, 'b', const []), CustomProblem.tooLong);
      expect(checkCustom(wyr, 'x' * 90, 'b', const []), isNull);
      expect(checkCustom(wyr, 'Tea', ' tea ', const []), CustomProblem.same);
      expect(checkCustom(wyr, 'Tea', 'Shit coffee', const []), CustomProblem.notAllowed);
      // Same pair in either order, any case.
      expect(checkCustom(wyr, 'coffee', 'TEA', const [mine]), CustomProblem.duplicate);
      expect(checkCustom(wyr, 'coffee', 'TEA', const [mine], editingId: 'wyr-mine-1'), isNull);
    });

    test('stops at the per-game limit', () {
      final full = [
        for (var i = 0; i < maxCustomQuestions; i++)
          WyrItem(id: 'wyr-mine-$i', category: customCategoryId, a: 'A$i', b: 'B$i'),
      ];
      expect(checkCustom(wyr, 'New', 'Question', full), CustomProblem.full);
    });
  });

  testWidgets('write a question from setup, then play only your own questions', (tester) async {
    final h = await pumpApp(tester);
    h.container.read(routerProvider).go('/play/would-you-rather/setup');
    await tester.pumpAndSettle();
    expect(find.text('My questions'), findsNothing);
    await tapText(tester, 'Write your own questions');
    expect(find.textContaining('No questions yet'), findsOneWidget);

    await tester.tap(find.text('Add question'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'First option'), 'Live by the sea');
    await tester.enterText(find.widgetWithText(TextField, 'Second option'), 'live by the SEA ');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('The two options need to be different.'), findsOneWidget);
    await tester.enterText(find.widgetWithText(TextField, 'Second option'), 'Live in the hills');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Live by the sea'), findsOneWidget);

    // Stored on the phone only.
    final saved = jsonDecode(h.prefs.getString('custom.would-you-rather')!) as List<dynamic>;
    expect(saved.single, containsPair('a', 'Live by the sea'));

    // Back in setup, "My questions" is offered but not ticked by default.
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    final tile = find.widgetWithText(CheckboxListTile, 'My questions');
    await reveal(tester, tile);
    expect(tester.widget<CheckboxListTile>(tile).value, isFalse);

    // Play only my questions.
    await tapText(tester, 'My questions');
    await tapText(tester, 'Casual');
    await tapText(tester, 'Start game');
    expect(find.text('Live by the sea'), findsOneWidget);
    expect(find.text('Live in the hills'), findsOneWidget);
    expect(h.container.read(wyrSessionProvider)!.order, everyElement(startsWith('wyr-mine-')));
  });

  testWidgets('quick play never mixes in your own questions', (tester) async {
    final h = await pumpApp(
      tester,
      initialPrefs: {
        'custom.would-you-rather': jsonEncode([
          {'id': 'wyr-mine-1', 'a': 'Mine A', 'b': 'Mine B'},
        ]),
      },
    );
    await tapText(tester, 'Quick play');
    expect(h.container.read(wyrSessionProvider)!.order.where((id) => id.startsWith('wyr-mine-')), isEmpty);
  });

  testWidgets('deleting a question can be undone', (tester) async {
    final h = await pumpApp(
      tester,
      initialPrefs: {
        'custom.this-or-that': jsonEncode([
          {'id': 'tot-mine-1', 'a': 'Rain', 'b': 'Snow'},
          {'id': 'tot-mine-2', 'a': 'Hills', 'b': 'Coast'},
        ]),
      },
    );
    h.container.read(routerProvider).go('/my-questions?mode=this-or-that');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Delete question').first);
    await tester.pumpAndSettle();
    expect(find.text('Rain'), findsNothing);
    expect(h.container.read(customQuestionsProvider).tot, hasLength(1));
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(h.container.read(customQuestionsProvider).tot.map((q) => q.a), ['Rain', 'Hills']);
  });

  testWidgets('a game with your own questions survives a relaunch', (tester) async {
    final first = await pumpApp(
      tester,
      initialPrefs: {
        'custom.would-you-rather': jsonEncode([
          {'id': 'wyr-mine-1', 'a': 'Mine A', 'b': 'Mine B'},
        ]),
      },
    );
    first.container.read(routerProvider).go('/play/would-you-rather/setup');
    await tester.pumpAndSettle();
    await tapText(tester, 'My questions');
    await tapText(tester, 'Casual');
    await tapText(tester, 'Start game');
    expect(find.text('Mine A'), findsOneWidget);

    await pumpApp(tester, prefs: first.prefs);
    await tapText(tester, 'Resume');
    expect(find.text('Mine A'), findsOneWidget);
  });
}
