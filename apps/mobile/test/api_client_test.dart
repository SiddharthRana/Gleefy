import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirthmix/account/api_client.dart';
import 'package:mirthmix/account/auth_repository.dart';

/// Answers requests from a table instead of the network, and records them.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.routes);
  final Map<String, (int, Object)> routes;
  final requests = <RequestOptions>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final route = routes['${options.method} ${options.path}'];
    if (route == null) throw DioException.connectionError(requestOptions: options, reason: 'offline');
    return ResponseBody.fromString(
      jsonEncode(route.$2),
      route.$1,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

/// Hands out a token, and a new one when asked to refresh (null when signed out).
class TokenAuth extends UnconfiguredAuthRepository {
  TokenAuth(this.token, {this.refreshed, this.offline = false});
  String? token;
  final String? refreshed;
  final bool offline;
  int refreshes = 0;

  @override
  Future<String?> accessToken() async {
    if (offline) throw AuthFailure('network');
    return token;
  }

  @override
  Future<String?> refreshAccessToken() async {
    refreshes++;
    return token = refreshed;
  }
}

/// Rejects the first token with 401, then accepts the refreshed one.
class ExpiringAdapter extends FakeAdapter {
  ExpiringAdapter(super.routes);

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) {
    if (options.headers['Authorization'] == 'Bearer old') {
      requests.add(options);
      return Future.value(ResponseBody.fromString('{"code":"invalid_token"}', 401));
    }
    return super.fetch(options, requestStream, cancelFuture);
  }
}

void main() {
  HttpAccountApi api(FakeAdapter adapter, {String? token = 'jwt', AuthRepository? auth}) => HttpAccountApi(
    Dio(BaseOptions(baseUrl: 'https://api.test'))..httpClientAdapter = adapter,
    auth ?? TokenAuth(token),
  );

  test('reads the account with the bearer token', () async {
    final adapter = FakeAdapter({
      'GET /v1/me': (
        200,
        {
          'id': 'u1',
          'email': 'a@b.test',
          'entitlements': {'premiumContent': true},
          'lifetime': true,
          'validUntil': null,
          'purchases': [
            {
              'provider': 'google_play',
              'planId': 'premium',
              'status': 'active',
              'purchasedAt': '2026-11-01T00:00:00.000Z',
            },
          ],
        },
      ),
    });
    final me = await api(adapter).me();
    expect(adapter.requests.single.headers['Authorization'], 'Bearer jwt');
    expect((me.premium, me.lifetime, me.validUntil), (true, true, null));
    final purchase = me.purchases.single;
    expect((purchase.isWeb, purchase.pending, purchase.purchasedAt), (false, false, DateTime.utc(2026, 11)));
  });

  test('billing config is public and parses availability', () async {
    final adapter = FakeAdapter({
      'GET /v1/billing/config': (
        200,
        {
          'enabled': true,
          'web': {'provider': 'dodo', 'available': true},
          'googlePlay': {'available': true, 'productId': 'mirthmix_premium_unlock'},
        },
      ),
    });
    final c = await api(adapter, token: null).billingConfig();
    expect(adapter.requests.single.headers.containsKey('Authorization'), isFalse);
    expect((c.playAvailable, c.productId, c.webAvailable), (true, 'mirthmix_premium_unlock', true));
  });

  test('sends the purchase token and maps API error codes', () async {
    final ok = FakeAdapter({
      'POST /v1/billing/google-play/verify': (
        200,
        {'planId': 'premium', 'status': 'active', 'duplicatePurchase': true},
      ),
    });
    final res = await api(ok).verifyPlayPurchase('tok');
    expect(ok.requests.single.data, {'purchaseToken': 'tok'});
    expect((res.premium, res.pending, res.duplicatePurchase), (true, false, true));

    final pending = FakeAdapter({
      'POST /v1/billing/google-play/verify': (
        200,
        {'planId': 'premium', 'status': 'on_hold', 'duplicatePurchase': false},
      ),
    });
    final waiting = await api(pending).verifyPlayPurchase('tok');
    expect((waiting.premium, waiting.pending), (false, true));

    final bad = FakeAdapter({
      'POST /v1/billing/google-play/verify': (403, {'code': 'purchase_account_mismatch'}),
    });
    await expectLater(
      api(bad).verifyPlayPurchase('tok'),
      throwsA(isA<ApiException>().having((e) => e.code, 'code', 'purchase_account_mismatch')),
    );
  });

  test('network failures and missing sessions are distinguishable', () async {
    await expectLater(
      api(FakeAdapter({})).me(),
      throwsA(isA<ApiException>().having((e) => e.isNetworkError, 'network', isTrue)),
    );
    await expectLater(
      api(FakeAdapter({}), token: null).me(),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
  });

  test('a rejected token is refreshed once and the request resent', () async {
    final adapter = ExpiringAdapter({
      'GET /v1/me': (200, {'id': 'u1'}),
    });
    final auth = TokenAuth('old', refreshed: 'new');
    await api(adapter, auth: auth).me();
    expect(adapter.requests.map((r) => r.headers['Authorization']), ['Bearer old', 'Bearer new']);
    expect(auth.refreshes, 1);

    final stuck = ExpiringAdapter({});
    final noRefresh = TokenAuth('old');
    await expectLater(
      api(stuck, auth: noRefresh).me(),
      throwsA(isA<ApiException>().having((e) => e.status, 'status', 401)),
    );
  });

  test('a token that can’t be refreshed while offline counts as a connection error', () async {
    final adapter = FakeAdapter({});
    await expectLater(
      api(adapter, auth: TokenAuth('jwt', offline: true)).me(),
      throwsA(isA<ApiException>().having((e) => e.isNetworkError, 'network', isTrue)),
    );
    expect(adapter.requests, isEmpty);
  });

  test('account deletion sends the confirmation the API requires', () async {
    final adapter = FakeAdapter({
      'DELETE /v1/me': (200, {'status': 'deleted'}),
    });
    await api(adapter).deleteAccount();
    expect(adapter.requests.single.data, {'confirm': 'DELETE'});
  });
}
