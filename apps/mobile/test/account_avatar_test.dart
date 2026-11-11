import 'package:flutter_test/flutter_test.dart';
import 'package:gleefy/account/entitlement.dart';
import 'package:gleefy/widgets/brand.dart';

import 'premium_test.dart' show FakeApi, FakeAuth, fakes, premiumAccount, user;
import 'support/harness.dart';

void main() {
  test('the avatar shows the first letter of the email', () {
    expect(AccountAvatarButton.initialOf('host@example.test'), 'H');
    expect(AccountAvatarButton.initialOf(null), '?');
  });

  testWidgets('signed out, the home screen has no account button', (tester) async {
    await pumpApp(tester, overrides: fakes(FakeAuth(), FakeApi()));
    expect(find.byType(AccountAvatarButton), findsNothing);
  });

  testWidgets('signed in, the avatar on the home screen opens Account', (tester) async {
    final api = FakeApi()..account = premiumAccount();
    final h = await pumpApp(tester, overrides: fakes(FakeAuth(currentUser: user), api));
    await h.container.read(entitlementProvider.notifier).refresh();
    await tester.pumpAndSettle();
    final avatar = find.byType(AccountAvatarButton);
    expect(avatar, findsOneWidget);
    expect(find.descendant(of: avatar, matching: find.text('H')), findsOneWidget);
    expect(tester.widget<AccountAvatarButton>(avatar).premium, isTrue);
    expect(find.text('PREMIUM'), findsOneWidget);
    await tester.tap(avatar);
    await tester.pumpAndSettle();
    expect(find.text('Account'), findsWidgets);
    expect(find.byType(AccountAvatarButton), findsNothing);
  });
}
