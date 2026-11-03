import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mirthmix/account/api_client.dart';
import 'package:mirthmix/account/auth_repository.dart';
import 'package:mirthmix/account/entitlement.dart';
import 'package:mirthmix/billing/billing_controller.dart';
import 'package:mirthmix/billing/billing_gateway.dart';
import 'package:mirthmix/router/router.dart';
import 'package:mirthmix/state/providers.dart';

import 'support/harness.dart';

final now = DateTime.utc(2026, 11, 1, 12);
const user = AppUser(id: 'u-1', email: 'host@example.test');

class FakeAuth implements AuthRepository {
  FakeAuth({this.currentUser});

  @override
  AppUser? currentUser;
  final _events = StreamController<AuthEvent>.broadcast();
  final sentTo = <String>[];

  @override
  bool get configured => true;
  @override
  String? get accessToken => currentUser == null ? null : 'token';
  @override
  Stream<AuthEvent> get events => _events.stream;

  @override
  Future<void> sendCode(String email) async => sentTo.add(email);

  @override
  Future<void> verifyCode({required String email, required String code}) async {
    if (code != '123456') throw AuthFailure('invalid_code');
    currentUser = AppUser(id: user.id, email: email);
  }

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
    subscriptionId: 'mirthmix_premium',
    webAvailable: false,
  );
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
    account = premiumAccount(now.add(const Duration(days: 30)));
    return const PlayVerifyResult(premium: true, duplicateSubscription: false);
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
  Future<List<StoreOffer>> loadOffers(String productId) async => const [
    StoreOffer(basePlanId: 'monthly', interval: StoreInterval.monthly, price: '₹99'),
    StoreOffer(basePlanId: 'annual', interval: StoreInterval.annual, price: '₹699'),
  ];
  @override
  Future<void> buy(StoreOffer offer, {required String accountRef}) async =>
      bought.add('${offer.basePlanId}:$accountRef');
  @override
  Stream<StorePurchaseUpdate> get purchases => _purchases.stream;
  @override
  Future<void> complete(StorePurchaseUpdate update) async => completed.add(update);
  @override
  Future<void> restore() async {}
}

AccountInfo premiumAccount(DateTime until) => AccountInfo(
  id: 'u-1',
  email: user.email,
  premium: true,
  validUntil: until,
  subscriptions: [
    SubscriptionInfo(
      provider: 'google_play',
      status: 'active',
      interval: 'monthly',
      currentPeriodEnd: until,
      cancelAtPeriodEnd: false,
    ),
  ],
);

Map<String, Object> cached({String userId = 'u-1', bool premium = true, required DateTime validUntil}) => {
  'entitlement.v1': jsonEncode(
    EntitlementSnapshot(userId: userId, premium: premium, validUntil: validUntil, checkedAt: now).toJson(),
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

void main() {
  group('EntitlementSnapshot', () {
    final until = DateTime.utc(2026, 12, 1);
    final snap = EntitlementSnapshot(userId: 'u', premium: true, validUntil: until, checkedAt: now);

    test('grants premium through the paid period plus the offline grace window', () {
      expect(snap.grantsPremiumAt(until.subtract(const Duration(days: 1))), isTrue);
      expect(snap.grantsPremiumAt(until.add(const Duration(days: 2))), isTrue);
      expect(snap.grantsPremiumAt(until.add(offlineGrace + const Duration(minutes: 1))), isFalse);
    });

    test('never grants premium for a free answer', () {
      final free = EntitlementSnapshot(userId: 'u', premium: false, validUntil: until, checkedAt: now);
      expect(free.grantsPremiumAt(now), isFalse);
    });

    test('round-trips through JSON', () {
      final back = EntitlementSnapshot.fromJson(jsonDecode(jsonEncode(snap.toJson())) as Map<String, dynamic>);
      expect(back.validUntil, until);
      expect(back.premium, isTrue);
    });
  });

  testWidgets('a build without accounts says Premium is unavailable and keeps it locked', (tester) async {
    final h = await pumpApp(tester);
    await go(tester, h, '/premium');
    expect(find.text('Premium isn’t available in this version of the app yet.'), findsOneWidget);
    expect(find.text('Deep'), findsOneWidget); // listed as included
    await go(tester, h, wyrSetup);
    await reveal(tester, find.textContaining(locked));
    expect(find.textContaining(locked), findsOneWidget);
  });

  testWidgets('a guest signs in with an email code and the verified entitlement unlocks premium', (tester) async {
    final auth = FakeAuth();
    final api = FakeApi()..account = premiumAccount(now.add(const Duration(days: 30)));
    final h = await pumpApp(tester, overrides: fakes(auth, api));
    await go(tester, h, wyrSetup);
    await reveal(tester, find.text('See Premium'));
    await tapText(tester, 'See Premium');
    await tapText(tester, 'Sign in to continue');

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
    expect(find.text('Premium is on'), findsOneWidget);
    expect(h.container.read(premiumProvider), isTrue);
    expect(h.prefs.getString('entitlement.v1'), contains('"premium":true'));
    await go(tester, h, wyrSetup);
    expect(find.textContaining(locked), findsNothing);
  });

  testWidgets('offline: the cached entitlement lasts until the period end plus the grace window', (tester) async {
    final api = FakeApi()..meError = ApiException(isNetworkError: true);
    // Paid period ended yesterday; still inside the 3-day grace window.
    final h = await pumpApp(
      tester,
      initialPrefs: cached(validUntil: now.subtract(const Duration(days: 1))),
      overrides: fakes(FakeAuth(currentUser: user), api),
    );
    await go(tester, h, '/premium');
    expect(h.container.read(premiumProvider), isTrue);
    expect(find.textContaining('You’re offline. Premium stays on until'), findsOneWidget);
  });

  testWidgets('offline past the grace window, premium locks again', (tester) async {
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
      initialPrefs: cached(userId: 'someone-else', validUntil: now.add(const Duration(days: 30))),
      overrides: fakes(FakeAuth(currentUser: user), FakeApi()..meError = ApiException(isNetworkError: true)),
    );
    expect(other.container.read(premiumProvider), isFalse);
  });

  testWidgets('the server has the final word: a refund or kill switch removes cached premium', (tester) async {
    final api = FakeApi()..account = const AccountInfo(id: 'u-1', premium: false);
    final h = await pumpApp(
      tester,
      initialPrefs: cached(validUntil: now.add(const Duration(days: 30))),
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
    final h = await pumpApp(
      tester,
      initialPrefs: cached(validUntil: now.add(const Duration(days: 30))),
      overrides: fakes(auth, api),
    );
    await go(tester, h, '/premium');
    expect(auth.currentUser, isNull);
    expect(h.container.read(premiumProvider), isFalse);
    expect(h.prefs.getString('entitlement.v1'), isNull);
    expect(find.text('Sign in to continue'), findsOneWidget);
  });

  testWidgets('buying on Google Play: server verifies before the purchase is completed', (tester) async {
    final api = FakeApi();
    final gateway = FakeGateway();
    final h = await pumpApp(tester, overrides: fakes(FakeAuth(currentUser: user), api, gateway));
    await go(tester, h, '/premium');
    expect(find.text('₹99 per month'), findsOneWidget);
    // While the store sheet is open a progress bar animates, so pump instead of settling.
    await tester.tap(find.text('₹699 per year'));
    await tester.pump(const Duration(milliseconds: 100));
    expect(gateway.bought, ['annual:ref-u-1']);

    gateway.emit(const StorePurchaseUpdate(status: StorePurchaseStatus.pending));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Waiting for Google Play to confirm the payment…'), findsOneWidget);

    gateway.emit(const StorePurchaseUpdate(status: StorePurchaseStatus.purchased, purchaseToken: 'tok-1'));
    await tester.pumpAndSettle();
    expect(api.verified, ['tok-1']);
    expect(gateway.completed.single.purchaseToken, 'tok-1');
    expect(find.text('Premium is on'), findsOneWidget);
    expect(h.container.read(premiumProvider), isTrue);
  });

  testWidgets('a purchase the server rejects is not completed on the device', (tester) async {
    final api = FakeApi()..verifyError = ApiException(status: 403, code: 'purchase_account_mismatch');
    final gateway = FakeGateway();
    final h = await pumpApp(tester, overrides: fakes(FakeAuth(currentUser: user), api, gateway));
    await go(tester, h, '/premium');
    gateway.emit(const StorePurchaseUpdate(status: StorePurchaseStatus.restored, purchaseToken: 'tok-2'));
    await tester.pumpAndSettle();
    expect(gateway.completed, isEmpty);
    expect(find.textContaining('belongs to a different MirthMix account'), findsOneWidget);
    expect(h.container.read(premiumProvider), isFalse);

    api.verifyError = ApiException(isNetworkError: true);
    gateway.emit(const StorePurchaseUpdate(status: StorePurchaseStatus.purchased, purchaseToken: 'tok-3'));
    await tester.pumpAndSettle();
    expect(gateway.completed, isEmpty);
    expect(find.textContaining('couldn’t reach the server'), findsOneWidget);
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
    expect(find.text('₹99 per month'), findsOneWidget);
  });

  testWidgets('a web subscriber is pointed to the website instead of being sold a second plan', (tester) async {
    final api = FakeApi()
      ..account = AccountInfo(
        id: 'u-1',
        email: user.email,
        premium: true,
        validUntil: now.add(const Duration(days: 10)),
        subscriptions: [
          SubscriptionInfo(
            provider: 'paddle',
            status: 'canceled',
            currentPeriodEnd: now.add(const Duration(days: 10)),
            cancelAtPeriodEnd: true,
          ),
        ],
      );
    final gateway = FakeGateway();
    final h = await pumpApp(tester, overrides: fakes(FakeAuth(currentUser: user), api, gateway));
    await go(tester, h, '/premium');
    expect(find.textContaining('subscribed on the website'), findsOneWidget);
    expect(find.textContaining('Ends on'), findsOneWidget);
    expect(find.text('₹99 per month'), findsNothing);
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
