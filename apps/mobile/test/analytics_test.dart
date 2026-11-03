import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirthmix/content/content.dart';
import 'package:mirthmix/game/wyr_engine.dart';
import 'package:mirthmix/router/router.dart';
import 'package:mirthmix/state/games.dart';
import 'package:mirthmix/state/sessions.dart';
import 'package:mirthmix/telemetry/analytics.dart';

import 'support/harness.dart';

class FakeSink implements AnalyticsSink {
  final events = <Map<String, Object?>>[];
  @override
  Future<void> send(Map<String, Object?> event) async => events.add(event);
}

Map<String, Object?> props(Map<String, Object?> e) => e['properties']! as Map<String, Object?>;

Future<void> openSettings(WidgetTester tester, Harness h) async {
  h.container.read(routerProvider).go('/settings');
  await tester.pumpAndSettle();
}

/// Plays a 5-round Would You Rather to the end through the real session controller.
void playShortGame(Harness h) {
  h.container
      .read(gameStarterProvider)
      .start(const GameSetup(mode: GameMode.wouldYouRather, categoryIds: ['casual'], rounds: 5));
  final c = h.container.read(wyrSessionProvider.notifier);
  for (var i = 0; i < 5; i++) {
    c.dispatch(const Reveal());
    c.dispatch(const Next());
  }
}

void main() {
  testWidgets('without a configured sink, nothing is offered or sent', (tester) async {
    final h = await pumpApp(tester, content: tinyContent(casual: 6));
    await openSettings(tester, h);
    expect(find.text('Share anonymous usage stats'), findsNothing);
    expect(h.container.read(analyticsProvider).enabled, isFalse);
  });

  testWidgets('a configured build still sends nothing until the person opts in', (tester) async {
    final sink = FakeSink();
    final h = await pumpApp(
      tester,
      content: tinyContent(casual: 6),
      overrides: [analyticsSinkProvider.overrideWithValue(sink)],
    );
    await openSettings(tester, h);
    final toggle = find.widgetWithText(SwitchListTile, 'Share anonymous usage stats');
    await tester.scrollUntilVisible(toggle, 150, scrollable: find.byType(Scrollable).first);
    expect(tester.widget<SwitchListTile>(toggle).value, isFalse);
    playShortGame(h);
    expect(sink.events, isEmpty);
    expect(h.prefs.getString('analytics.installId'), isNull);
  });

  testWidgets('after opting in, games are counted without names or content', (tester) async {
    final sink = FakeSink();
    final h = await pumpApp(
      tester,
      content: tinyContent(casual: 6),
      initialPrefs: {
        'settings.shareUsage': true,
        'lineup.names': <String>['Asha', 'Ben'],
      },
      overrides: [analyticsSinkProvider.overrideWithValue(sink)],
    );
    playShortGame(h);
    final names = sink.events.map((e) => e['event']).toList();
    expect(names, containsAllInOrder(['game_started', 'game_completed']));
    final started = sink.events.firstWhere((e) => e['event'] == 'game_started');
    expect(props(started), containsPair('mode', 'would-you-rather'));
    expect(props(started), containsPair('rounds', 5));
    expect(props(started), containsPair(r'$process_person_profile', false));
    final completed = sink.events.firstWhere((e) => e['event'] == 'game_completed');
    expect(props(completed), containsPair('rounds', 5));
    // One random id per install, and nothing personal anywhere in the payload.
    final ids = sink.events.map((e) => e['distinct_id']).toSet();
    expect(ids, hasLength(1));
    expect(ids.single, matches(RegExp(r'^[0-9a-f]{32}$')));
    final payload = sink.events.toString();
    for (final secret in ['Asha', 'Ben', 'Apple', 'Banana']) {
      expect(payload, isNot(contains(secret)));
    }
  });

  testWidgets('turning sharing off stops events and forgets the install id', (tester) async {
    final sink = FakeSink();
    final h = await pumpApp(
      tester,
      content: tinyContent(casual: 6),
      initialPrefs: {'settings.shareUsage': true},
      overrides: [analyticsSinkProvider.overrideWithValue(sink)],
    );
    playShortGame(h);
    expect(h.prefs.getString('analytics.installId'), isNotNull);
    await openSettings(tester, h);
    final toggle = find.widgetWithText(SwitchListTile, 'Share anonymous usage stats');
    await tester.scrollUntilVisible(toggle, 150, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(toggle);
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: toggle, matching: find.byType(Switch)));
    await tester.pumpAndSettle();
    expect(h.prefs.getBool('settings.shareUsage'), isFalse);
    expect(h.prefs.getString('analytics.installId'), isNull);
    final before = sink.events.length;
    playShortGame(h);
    expect(sink.events, hasLength(before));
  });

  testWidgets('error reports are capped and truncated', (tester) async {
    final sink = FakeSink();
    final h = await pumpApp(
      tester,
      initialPrefs: {'settings.shareUsage': true},
      overrides: [analyticsSinkProvider.overrideWithValue(sink)],
    );
    final analytics = h.container.read(analyticsProvider);
    for (var i = 0; i < 30; i++) {
      analytics.captureError(StateError('x' * 2000), StackTrace.current);
    }
    final errors = sink.events.where((e) => e['event'] == r'$exception').toList();
    expect(errors, hasLength(20));
    expect((props(errors.first)[r'$exception_message']! as String).length, 500);
  });
}
