import 'package:flutter_test/flutter_test.dart';
import 'package:mirthmix/billing/billing_gateway.dart';
import 'package:mirthmix/content/content.dart';
import 'package:mirthmix/router/router.dart';
import 'package:mirthmix/telemetry/analytics.dart';

import 'premium_test.dart' show FakeApi, FakeAuth, FakeGateway, fakes, premiumAccount, user;
import 'analytics_test.dart' show playShortGame;
import 'support/harness.dart';

class _NullSink implements AnalyticsSink {
  @override
  Future<void> send(Map<String, Object?> event) async {}
}

Future<void> checkGuidelines(WidgetTester tester) async {
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
  await expectLater(tester, meetsGuideline(textContrastGuideline));
}

/// Android accessibility guidelines (48 dp tap targets, labels, text contrast) on every screen added
/// since the game screens were checked, in light and dark themes.
void main() {
  for (final dark in [false, true]) {
    final theme = dark ? 'dark' : 'light';
    final prefs = <String, Object>{'settings.themeMode': dark ? 'dark' : 'light'};

    for (final route in ['/', '/games', '/settings', '/players', '/party', '/play/trivia/setup', '/trophies']) {
      testWidgets('$route meets the guidelines ($theme)', (tester) async {
        final h = await pumpApp(
          tester,
          content: realContent(),
          initialPrefs: prefs,
          overrides: [analyticsSinkProvider.overrideWithValue(_NullSink())],
        );
        h.container.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        await checkGuidelines(tester);
      });
    }

    testWidgets('Premium with store prices meets the guidelines ($theme)', (tester) async {
      final h = await pumpApp(
        tester,
        initialPrefs: prefs,
        overrides: fakes(FakeAuth(currentUser: user), FakeApi(), FakeGateway()),
      );
      h.container.read(routerProvider).go('/premium');
      await tester.pumpAndSettle();
      expect(find.text(r'Unlock Premium for $2.99'), findsOneWidget);
      await checkGuidelines(tester);
    });

    testWidgets('Premium when active, and Account, meet the guidelines ($theme)', (tester) async {
      final api = FakeApi()..account = premiumAccount();
      final h = await pumpApp(
        tester,
        initialPrefs: prefs,
        overrides: fakes(FakeAuth(currentUser: user), api),
      );
      h.container.read(routerProvider).go('/premium');
      await tester.pumpAndSettle();
      expect(find.text('Premium is unlocked'), findsOneWidget);
      await checkGuidelines(tester);
      h.container.read(routerProvider).go('/account');
      await tester.pumpAndSettle();
      await checkGuidelines(tester);
    });

    testWidgets('The purchase result card meets the guidelines ($theme)', (tester) async {
      final gateway = FakeGateway();
      final h = await pumpApp(
        tester,
        initialPrefs: prefs,
        overrides: fakes(FakeAuth(currentUser: user), FakeApi(), gateway),
      );
      h.container.read(routerProvider).go('/premium');
      await tester.pumpAndSettle();
      gateway.emit(const StorePurchaseUpdate(status: StorePurchaseStatus.purchased, purchaseToken: 'tok'));
      await tester.pumpAndSettle();
      expect(find.text('Premium is unlocked!'), findsOneWidget);
      await checkGuidelines(tester);
    });

    testWidgets('Results with a reward meet the guidelines ($theme)', (tester) async {
      final h = await pumpApp(tester, content: tinyContent(casual: 6), initialPrefs: prefs);
      playShortGame(h);
      h.container.read(routerProvider).go('/play/would-you-rather/results');
      await tester.pumpAndSettle();
      expect(find.text('+25 XP'), findsOneWidget);
      await checkGuidelines(tester);
    });

    testWidgets('Sign-in meets the guidelines ($theme)', (tester) async {
      final h = await pumpApp(tester, initialPrefs: prefs, overrides: fakes(FakeAuth(googleEnabled: true), FakeApi()));
      h.container.read(routerProvider).go('/account/sign-in');
      await tester.pumpAndSettle();
      await checkGuidelines(tester);
    });
  }

  test('the real content has premium categories in every mode', () {
    final content = realContent();
    for (final mode in GameMode.values) {
      expect(content.packFor(mode).categories.where((c) => c.tier == Tier.premium), isNotEmpty, reason: mode.id);
    }
  });
}
