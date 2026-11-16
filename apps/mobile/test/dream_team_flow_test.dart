import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleefy/game/dream_team_engine.dart';
import 'package:gleefy/state/dream_team.dart';
import 'package:gleefy/state/progress.dart';

import 'accessibility_test.dart' show checkGuidelines;
import 'premium_test.dart' show go;
import 'support/harness.dart';

Future<void> tapIt(WidgetTester tester, Finder f) async {
  if (f.evaluate().isEmpty) await tester.scrollUntilVisible(f, 300, scrollable: find.byType(Scrollable).first);
  await tester.ensureVisible(f.first);
  await tester.pumpAndSettle();
  await tester.tap(f.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a full Dream Team game: draft, pass, vote, verdict, XP', (tester) async {
    final h = await pumpApp(tester, content: realContent());
    await go(tester, h, '/dream-team');
    expect(find.text('Anime Archetypes'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Side 2'), 300, scrollable: find.byType(Scrollable).first);
    await tester.enterText(find.byType(TextField).at(0), 'Ana');
    await tester.enterText(find.byType(TextField).at(1), 'Ben');
    await tester.pumpAndSettle();
    await tapIt(tester, find.text('Start the draft'));

    // 10 picks: flip, lock into the first empty slot, hand the phone over.
    for (var pick = 0; pick < 10; pick++) {
      final game = h.container.read(dreamTeamProvider)!;
      expect(find.text("${game.sides[game.state.turn]}'s pick"), findsOneWidget);
      if (pick == 0) {
        // Placing before flipping does nothing.
        expect(find.byIcon(Icons.add_circle_outline_rounded), findsNothing);
      }
      await tapIt(tester, find.text('Tap to flip'));
      if (pick == 0) {
        final first = game.state.drawn;
        await tapIt(tester, find.text('Skip (1 left)'));
        expect(h.container.read(dreamTeamProvider)!.state.drawn, isNot(first));
        await tapIt(tester, find.text('Tap to flip'));
      }
      await tapIt(tester, find.byIcon(Icons.add_circle_outline_rounded));
      if (pick < 9) await tapIt(tester, find.textContaining("I'm "));
    }

    expect(h.container.read(dreamTeamProvider)!.state.status, DreamTeamStatus.voting);
    expect(find.text('Who wins Captain?'), findsOneWidget);
    for (var role = 0; role < 5; role++) {
      await tapIt(tester, find.text(role.isEven ? 'Ana' : 'Ben'));
    }
    await tapIt(tester, find.text('See the verdict'));
    expect(find.text('The room says: Ana wins 3–2'), findsOneWidget);
    expect(find.textContaining('The stats say'), findsOneWidget);
    expect(h.container.read(progressProvider).modesPlayed, contains('dream-team'));

    await tapIt(tester, find.text('Draft again'));
    expect(h.container.read(dreamTeamProvider)!.state.status, DreamTeamStatus.drafting);
  });

  for (final dark in [false, true]) {
    testWidgets('Dream Team screens meet the accessibility guidelines (${dark ? 'dark' : 'light'})', (tester) async {
      final h = await pumpApp(
        tester,
        content: realContent(),
        initialPrefs: {'settings.themeMode': dark ? 'dark' : 'light'},
      );
      await go(tester, h, '/dream-team');
      await checkGuidelines(tester);
      await tapIt(tester, find.text('Start the draft'));
      await tapIt(tester, find.text('Tap to flip'));
      await checkGuidelines(tester);
      // Every empty role is its own labelled button.
      expect(find.bySemanticsLabel(RegExp(r'^Captain')), findsWidgets);
      await go(tester, h, '/dream-team/decks/new');
      await checkGuidelines(tester);
    });
  }

  testWidgets('Myths & Legends and custom decks are Premium', (tester) async {
    final h = await pumpApp(tester, content: realContent());
    await go(tester, h, '/dream-team');
    expect(find.textContaining('Premium'), findsWidgets);
    await tapIt(tester, find.text('Myths & Legends'));
    expect(find.text('Gleefy Premium'), findsWidgets);
  });

  test('custom decks need enough cards and friendly names', () {
    final names = parseDeckNames('Hero\n  Rival \n\nhero\nMentor');
    expect(names, ['Hero', 'Rival', 'Mentor']);
    expect(checkDeck('', names, minCards: 3), DeckProblem.noTitle);
    expect(checkDeck('Mine', names, minCards: 12), DeckProblem.tooFew);
    expect(checkDeck('Mine', names, minCards: 3), isNull);
    expect(checkDeck('Mine', [...names, 'x' * 41], minCards: 3), DeckProblem.nameTooLong);
    final deck = const CustomDeck(id: 'mine-1', name: 'Mine', cards: ['A', 'B']).toCards();
    expect(deck.every((c) => c.stats == null), isTrue);
  });

  testWidgets('a game survives the app closing', (tester) async {
    final h = await pumpApp(tester, content: realContent());
    await go(tester, h, '/dream-team');
    await tapIt(tester, find.text('Start the draft'));
    await tapIt(tester, find.text('Tap to flip'));
    await tapIt(tester, find.byIcon(Icons.add_circle_outline_rounded));
    final saved = h.container.read(dreamTeamProvider)!;
    final again = await pumpApp(tester, content: realContent(), prefs: h.prefs);
    expect(again.container.read(dreamTeamProvider)!.placed, saved.placed);
  });
}
