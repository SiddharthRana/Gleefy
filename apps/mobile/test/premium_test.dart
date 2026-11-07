import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:gleefy/account/api_client.dart';
import 'package:gleefy/account/auth_repository.dart';
import 'package:gleefy/account/entitlement.dart';
import 'package:gleefy/billing/billing_controller.dart';
import 'package:gleefy/billing/billing_gateway.dart';
import 'package:gleefy/router/router.dart';
import 'package:gleefy/state/providers.dart';

import 'support/harness.dart';

final now = DateTime.utc(2026, 11, 1, 12);
const user = AppUser(id: 'u-1', email: 'host@example.test');

class FakeAuth implements AuthRepository {
  FakeAuth({this.currentUser, this.googleEnabled = false});

  @override
  AppUser? currentUser;
  @override
  final bool googleEnabled;
  final _events = StreamController<AuthEvent>.broadcast();
  final _googleErrors = StreamController<String>.broadcast();
  final sentTo = <String>[];
  int googleStarts = 0;

  @override
  bool get configured => true;
  @override
  Future<String?> accessToken() async => currentUser == null ? null : 'token';
  @override
  Future<String?> refreshAccessToken() async => null;
  @override
  Stream<AuthEvent> get events => _events.stream;
  @override
  Stream<String> get googleErrors => _googleErrors.stream;

  @override
  Future<void> sendCode(String email) async => sentTo.add(email);

  @override
  Future<void> verifyCode({required String email, required String code}) async {
    if (code != '123456') throw AuthFailure('invalid_code');
    currentUser = AppUser(id: user.id, email: email);
  }

  @override
  Future<void> signInWithGoogle() async => googleStarts++;

  /// Google sent the person back to the app, signed in.
  void finishGoogle() {
    currentUser = user;
    _events.add(AuthEvent.signedIn);
  }

  /// Google sent the person back with an error.
  void failGoogle(String code) => _googleErrors.add(code);

  @override
  Future<void> signOut() async => currentUser = null;
}

class FakeApi implements AccountApi {
  /// What GET /v1/me returns; an [ApiException] is thrown instead when set.
  AccountInfo? account = const AccountInfo(id: 'u-1', premium: false);
  ApiException? meError;
  ApiException? verifyError;
  BillingConfig config = const BillingConfig(
    playAvailable: true,
    productId: 'gleefy_premium_unlock',
    webAvailable: false,
  );

  /// Play hasn't been paid yet (a cash or bank payment).
  bool paymentPending = false;
  final verified = <String>[];
  bool deleted = false;

  @override
  bool get configured => true;
  @override
  Future<BillingConfig> billingConfig() async => config;
  @override
  Future<AccountInfo> me() async {
    if (meError != null) throw meError!;
    return account!;
  }

  @override
  Future<String> playAccountRef() async => 'ref-u-1';

  @override
  Future<PlayVerifyResult> verifyPlayPurchase(String purchaseToken) async {
    if (verifyError != null) throw verifyError!;
    verified.add(purchaseToken);
    if (paymentPending) return const PlayVerifyResult(premium: false, pending: true, duplicatePurchase: false);
    account = premiumAccount();
    return const PlayVerifyResult(premium: true, duplicatePurchase: false);
  }

  @override
  Future<void> deleteAccount() async => deleted = true;
}

class FakeGateway implements BillingGateway {
  final _purchases = StreamController<StorePurchaseUpdate>.broadcast();
  final bought = <String>[];
  final completed = <StorePurchaseUpdate>[];

  void emit(StorePurchaseUpdate u) => _purchases.add(u);

  @override
  Future<bool> isAvailable() async => true;
  @override
  Future<StoreOffer?> loadOffer(String productId) async => StoreOffer(productId: productId, price: r'$2.99');
  @override
  Future<void> buy(StoreOffer offer, {required String accountRef}) async =>
      bought.add('${offer.productId}:$accountRef');
  @override
  Stream<StorePurchaseUpdate> get purchases => _purchases.stream;
  @override
  Future<void> complete(StorePurchaseUpdate update) async => completed.add(update);
  @override
  Future<void> restore() async {}
}

AccountInfo premiumAccount({String provider = 'google_play'}) => AccountInfo(
  id: 'u-1',
  email: user.email,
  premium: true,
  lifetime: true,
  purchases: [PurchaseInfo(provider: provider, status: 'active', purchasedAt: DateTime.utc(2026, 10, 30))],
);

Map<String, Object> cached({
  String userId = 'u-1',
  bool premium = true,
  bool lifetime = false,
  DateTime? validUntil,
  DateTime? checkedAt,
}) => {
  'entitlement.v1': jsonEncode(
    EntitlementSnapshot(
      userId: userId,
      premium: premium,
      lifetime: lifetime,
      validUntil: validUntil,
      checkedAt: checkedAt ?? now,
    ).toJson(),
  ),
};

List<Override> fakes(FakeAuth auth, FakeApi api, [FakeGateway? gateway]) => [
  authRepositoryProvider.overrideWithValue(auth),
  accountApiProvider.overrideWithValue(api),
  clockProvider.overrideWithValue(() => now),
  if (gateway != null) billingGatewayProvider.overrideWithValue(gateway),
];

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

Future<void> go(WidgetTester tester, Harness h, String location) async {
  h.container.read(routerProvider).go(location);
  await tester.pumpAndSettle();
}

const locked = 'Unlock with Premium.';
const wyrSetup = '/play/would-you-rather/setup';

const unlock = r'Unlock Premium for $2.99';

void main() {
  group('EntitlementSnapshot', () {
    final until = DateTime.utc(2026, 12, 1);
    final snap = EntitlementSnapshot(userId: 'u', premium: true, validUntil: until, checkedAt: now);

    test('a timed entitlement lasts through its period plus the offline grace window', () {
      expect(snap.grantsPremiumAt(until.subtract(const Duration(days: 1))), isTrue);
      expect(snap.grantsPremiumAt(until.add(const Duration(days: 2))), isTrue);
      expect(snap.grantsPremiumAt(until.add(offlineGrace + const Duration(minutes: 1))), isFalse);
    });

    test('a one-time unlock never runs out offline', () {
      final forever = EntitlementSnapshot(userId: 'u', premium: true, lifetime: true, checkedAt: now);
      expect(forever.grantsPremiumAt(now.add(const Duration(days: 3650))), isTrue);
    });

    test('never grants premium for a free answer', () {
      final free = EntitlementSnapshot(userId: 'u', premium: false, lifetime: true, checkedAt: now);
      expect(free.grantsPremiumAt(now), isFalse);
    });

    test('round-trips through JSON', () {
      final lifetime = EntitlementSnapshot(userId: 'u', premium: true, lifetime: true, checkedAt: now);
      final back = EntitlementSnapshot.fromJson(jsonDecode(jsonEncode(lifetime.toJson())) as Map<String, dynamic>);
      expect((back.premium, back.lifetime, back.validUntil), (true, true, null));
    });
  });

  testWidgets('a build without accounts says Premium is unavailable and keeps it locked', (tester) async {
    final h = await pumpApp(tester);
    await go(tester, h, '/premium');
    expect(find.text('Premium isn’t available in this version of the app yet.'), findsOneWidget);
    expect(find.text('Deep'), findsOneWidget); // listed as included
    await go(tester, h, '/settings');
    expect(find.text('To buy Premium, or use it on this phone'), findsNothing);
    await go(tester, h, wyrSetup);
    await reveal(tester, find.textContaining(locked));
    expect(find.textContaining(locked), findsOneWidget);
  });

  testWidgets('Settings has a Sign in row while signed out', (tester) async {
    final h = await pumpApp(tester, overrides: fakes(FakeAuth(), FakeApi()));
    await go(tester, h, '/settings');
    await tapText(tester, 'To buy Premium, or use it on this phone');
    expect(find.text('Send code'), findsOneWidget);
  });

  testWidgets('a guest signs in with an email code and the verified entitlement unlocks premium', (tester) async {
    final auth = FakeAuth();
    final api = FakeApi()..account = premiumAccount();
    final h = await pumpApp(tester, overrides: fakes(auth, api));
    await go(tester, h, wyrSetup);
    await reveal(tester, find.text('See Premium'));
    await tapText(tester, 'See Premium');
    await tapText(tester, 'Sign in');
    expect(find.text('Continue with Google'), findsNothing); // not switched on in this build

    await tester.enterText(find.byType(TextField), 'not-an-email');
    await tapText(tester, 'Send code');
    expect(find.text('Enter a valid email address.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'host@example.test');
    await tapText(tester, 'Send code');
    expect(find.textContaining('aged 18 or over'), findsOneWidget);
    expect(auth.sentTo, isEmpty);
    await tapText(tester, 'I’m 18 or older');
    await tapText(tester, 'Send code');
    expect(auth.sentTo, ['host@example.test']);

    await tester.enterText(find.byType(TextField), '000000');
    await tapText(tester, 'Sign in');
    expect(find.text('That code is wrong or has expired.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '123456');
    await tapText(tester, 'Sign in');

    // Back on the Premium screen, now verified by the (fake) server.
    expect(find.text('Premium is unlocked'), findsOneWidget);
    expect(find.textContaining('through Google Play. Yours to keep.'), findsOneWidget);
    expect(h.container.read(premiumProvider), isTrue);
    expect(h.prefs.getString('entitlement.v1'), contains('"lifetime":true'));
    await go(tester, h, wyrSetup);
    expect(find.textContaining(locked), findsNothing);
  });

  testWidgets('Continue with Google needs 18+, then signs in when Google sends the person back', (tester) async {
    final auth = FakeAuth(googleEnabled: true);
    final api = FakeApi()..account = premiumAccount();
    final h = await pumpApp(tester, overrides: fakes(auth, api));
    await go(tester, h, '/premium');
    await tapText(tester, 'Sign in');
    await tapText(tester, 'Continue with Google');
    expect(find.textContaining('aged 18 or over'), findsOneWidget);
    expect(auth.googleStarts, 0);

    await tapText(tester, 'I’m 18 or older');
    await tapText(tester, 'Continue with Google');
    expect(auth.googleStarts, 1);
    expect(find.textContaining('Finish signing in with Google'), findsOneWidget);

    auth.failGoogle('google_cancelled');
    await tester.pumpAndSettle();
    expect(find.text('Google sign-in was cancelled.'), findsOneWidget);

    await tapText(tester, 'Continue with Google');
    auth.finishGoogle();
    await tester.pumpAndSettle();
    expect(find.text('Premium is unlocked'), findsOneWidget);
    expect(h.container.read(premiumProvider), isTrue);
  });

  testWidgets('the Google sign-in link back into the app doesn’t change the screen', (tester) async {
    expect(isAuthCallback(Uri.parse('gleefy://auth-callback?code=abc')), isTrue);
    expect(isAuthCallback(Uri.parse('/auth-callback?code=abc')), isTrue);
    expect(isAuthCallback(Uri.parse('https://gleefy.party/play?c=x')), isFalse);
    final h = await pumpApp(tester, overrides: fakes(FakeAuth(), FakeApi()));
    await go(tester, h, '/settings');
    h.container.read(routerProvider).go('/auth-callback?code=abc');
    await tester.pumpAndSettle();
    expect(h.container.read(routerProvider).state.matchedLocation, '/settings');
  });

  testWidgets('offline, a one-time unlock stays on however long ago it was checked', (tester) async {
    final api = FakeApi()..meError = ApiException(isNetworkError: true);
    final h = await pumpApp(
      tester,
      initialPrefs: cached(lifetime: true, checkedAt: now.subtract(const Duration(days: 400))),
      overrides: fakes(FakeAuth(currentUser: user), api),
    );
    await go(tester, h, '/premium');
    expect(h.container.read(premiumProvider), isTrue);
    expect(find.text('Premium is unlocked'), findsOneWidget);
  });

  testWidgets('offline past the grace window, a timed entitlement locks again', (tester) async {
    final api = FakeApi()..meError = ApiException(isNetworkError: true);
    final h = await pumpApp(
      tester,
      initialPrefs: cached(validUntil: now.subtract(offlineGrace + const Duration(hours: 1))),
      overrides: fakes(FakeAuth(currentUser: user), api),
    );
    expect(h.container.read(premiumProvider), isFalse);
    await go(tester, h, wyrSetup);
    await reveal(tester, find.textContaining(locked));
    expect(find.textContaining(locked), findsOneWidget);
  });

  testWidgets('a cached entitlement never carries over to another account or a signed-out phone', (tester) async {
    final other = await pumpApp(
      tester,
      initialPrefs: cached(userId: 'someone-else', lifetime: true),
      overrides: fakes(FakeAuth(currentUser: user), FakeApi()..meError = ApiException(isNetworkError: true)),
    );
    expect(other.container.read(premiumProvider), isFalse);
  });

  testWidgets('the server has the final word: a refund or kill switch removes cached premium', (tester) async {
    final api = FakeApi()..account = const AccountInfo(id: 'u-1', premium: false);
    final h = await pumpApp(
      tester,
      initialPrefs: cached(lifetime: true),
      overrides: fakes(FakeAuth(currentUser: user), api),
    );
    expect(h.container.read(premiumProvider), isTrue);
    await go(tester, h, '/premium');
    expect(h.container.read(premiumProvider), isFalse);
    expect(h.prefs.getString('entitlement.v1'), contains('"premium":false'));
  });

  testWidgets('an expired session or deleted account signs out and drops the cache', (tester) async {
    final auth = FakeAuth(currentUser: user);
    final api = FakeApi()..meError = ApiException(status: 403, code: 'account_deleted');
    final h = await pumpApp(tester, initialPrefs: cached(lifetime: true), overrides: fakes(auth, api));
    await go(tester, h, '/premium');
    expect(auth.currentUser, isNull);
    expect(h.container.read(premiumProvider), isFalse);
    expect(h.prefs.getString('entitlement.v1'), isNull);
    expect(find.widgetWithText(FilledButton, 'Sign in'), findsOneWidget);
  });

  testWidgets('buying on Google Play: one price, verified by the server before it is completed', (tester) async {
    final api = FakeApi();
    final gateway = FakeGateway();
    final h = await pumpApp(tester, overrides: fakes(FakeAuth(currentUser: user), api, gateway));
    await go(tester, h, '/premium');
    expect(find.text('One payment. Yours to keep, on this phone and the website.'), findsOneWidget);
    // While the store sheet is open a spinner turns, so pump instead of settling.
    await tester.tap(find.text(unlock));
    await tester.pump(const Duration(milliseconds: 100));
    expect(gateway.bought, ['gleefy_premium_unlock:ref-u-1']);
    expect(find.text('Confirming your purchase'), findsOneWidget);

    gateway.emit(const StorePurchaseUpdate(status: StorePurchaseStatus.pending));
    await tester.pumpAndSettle();
    expect(find.text('Waiting for your payment'), findsOneWidget);

    gateway.emit(const StorePurchaseUpdate(status: StorePurchaseStatus.purchased, purchaseToken: 'tok-1'));
    await tester.pumpAndSettle();
    expect(api.verified, ['tok-1']);
    expect(gateway.completed.single.purchaseToken, 'tok-1');
    expect(find.text('Premium is unlocked!'), findsOneWidget);
    expect(find.text(unlock), findsNothing);
    expect(h.container.read(premiumProvider), isTrue);
  });

  testWidgets('a payment Play hasn’t received yet unlocks nothing and isn’t completed', (tester) async {
    final api = FakeApi()..paymentPending = true;
    final gateway = FakeGateway();
    final h = await pumpApp(tester, overrides: fakes(FakeAuth(currentUser: user), api, gateway));
    await go(tester, h, '/premium');
    gateway.emit(const StorePurchaseUpdate(status: StorePurchaseStatus.purchased, purchaseToken: 'tok-p'));
    await tester.pumpAndSettle();
    expect(find.text('Waiting for your payment'), findsOneWidget);
    expect(gateway.completed, isEmpty);
    expect(h.container.read(premiumProvider), isFalse);
  });

  testWidgets('a purchase the server rejects is not completed; an unconfirmed one can be retried', (tester) async {
    final api = FakeApi()..verifyError = ApiException(status: 403, code: 'purchase_account_mismatch');
    final gateway = FakeGateway();
    final h = await pumpApp(tester, overrides: fakes(FakeAuth(currentUser: user), api, gateway));
    await go(tester, h, '/premium');
    gateway.emit(const StorePurchaseUpdate(status: StorePurchaseStatus.restored, purchaseToken: 'tok-2'));
    await tester.pumpAndSettle();
    expect(gateway.completed, isEmpty);
    expect(find.text('The purchase didn’t go through'), findsOneWidget);
    expect(find.textContaining('belongs to a different Gleefy account'), findsOneWidget);
    expect(find.text('Try again'), findsNothing);
    expect(h.container.read(premiumProvider), isFalse);

    api.verifyError = ApiException(isNetworkError: true);
    gateway.emit(const StorePurchaseUpdate(status: StorePurchaseStatus.purchased, purchaseToken: 'tok-3'));
    await tester.pumpAndSettle();
    expect(gateway.completed, isEmpty);
    expect(find.text('Still confirming your purchase'), findsOneWidget);

    api.verifyError = null;
    await tapText(tester, 'Try again');
    expect(api.verified, ['tok-3']);
    expect(gateway.completed.single.purchaseToken, 'tok-3');
    expect(find.text('Premium is unlocked!'), findsOneWidget);
  });

  testWidgets('a cancelled purchase is finished without granting anything', (tester) async {
    final api = FakeApi();
    final gateway = FakeGateway();
    final h = await pumpApp(tester, overrides: fakes(FakeAuth(currentUser: user), api, gateway));
    await go(tester, h, '/premium');
    gateway.emit(const StorePurchaseUpdate(status: StorePurchaseStatus.canceled));
    await tester.pumpAndSettle();
    expect(gateway.completed, hasLength(1));
    expect(api.verified, isEmpty);
    expect(find.text(unlock), findsOneWidget);
  });

  testWidgets('Premium bought on the website shows as unlocked, with nothing to buy', (tester) async {
    final api = FakeApi()..account = premiumAccount(provider: 'dodo');
    final gateway = FakeGateway();
    final h = await pumpApp(tester, overrides: fakes(FakeAuth(currentUser: user), api, gateway));
    await go(tester, h, '/premium');
    expect(find.text('Premium is unlocked'), findsOneWidget);
    expect(find.textContaining('through the website. Yours to keep.'), findsOneWidget);
    expect(find.text(unlock), findsNothing);
  });

  testWidgets('deleting the account needs DELETE typed, then signs out', (tester) async {
    final auth = FakeAuth(currentUser: user);
    final api = FakeApi();
    final h = await pumpApp(tester, overrides: fakes(auth, api));
    await go(tester, h, '/account');
    await tapText(tester, 'Delete account');
    final delete = find.widgetWithText(TextButton, 'Delete');
    expect(tester.widget<TextButton>(delete).onPressed, isNull);
    await tester.enterText(find.byType(TextField), 'DELETE');
    await tester.pump();
    await tester.tap(delete);
    await tester.pumpAndSettle();
    expect(api.deleted, isTrue);
    expect(auth.currentUser, isNull);
    expect(find.text('Your account was deleted.'), findsOneWidget);
  });
}
