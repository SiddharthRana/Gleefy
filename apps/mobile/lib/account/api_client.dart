import 'package:dio/dio.dart';

import 'auth_repository.dart';

class ApiException implements Exception {
  ApiException({this.status, this.code, this.isNetworkError = false});

  final int? status;

  /// Stable error code from the API (e.g. purchase_account_mismatch), when there is one.
  final String? code;
  final bool isNetworkError;

  @override
  String toString() => 'ApiException($status, $code)';
}

/// A Premium unlock on the account: one that gives access, or one whose payment is still pending.
class PurchaseInfo {
  const PurchaseInfo({required this.provider, required this.status, this.purchasedAt});

  factory PurchaseInfo.fromJson(Map<String, dynamic> j) => PurchaseInfo(
    provider: j['provider'] as String,
    status: j['status'] as String,
    purchasedAt: _date(j['purchasedAt']),
  );

  /// google_play or dodo (the website).
  final String provider;

  /// active, or on_hold while the payment is pending.
  final String status;
  final DateTime? purchasedAt;

  bool get isWeb => provider != 'google_play';
  bool get pending => status == 'on_hold';
}

/// GET /v1/me: what the server has verified for this purchaser.
class AccountInfo {
  const AccountInfo({
    required this.id,
    this.email,
    required this.premium,
    this.lifetime = false,
    this.validUntil,
    this.purchases = const [],
  });

  factory AccountInfo.fromJson(Map<String, dynamic> j) => AccountInfo(
    id: j['id'] as String,
    email: j['email'] as String?,
    premium: (j['entitlements'] as Map<String, dynamic>?)?['premiumContent'] == true,
    lifetime: j['lifetime'] == true,
    validUntil: _date(j['validUntil']),
    purchases: [
      for (final p in (j['purchases'] as List<dynamic>? ?? const [])) PurchaseInfo.fromJson(p as Map<String, dynamic>),
    ],
  );

  final String id;
  final String? email;
  final bool premium;

  /// Premium is a one-time unlock: it never runs out, only a refund ends it.
  final bool lifetime;
  final DateTime? validUntil;
  final List<PurchaseInfo> purchases;
}

/// GET /v1/billing/config (public).
class BillingConfig {
  const BillingConfig({required this.playAvailable, required this.productId, required this.webAvailable});

  factory BillingConfig.fromJson(Map<String, dynamic> j) {
    final play = j['googlePlay'] as Map<String, dynamic>? ?? const {};
    final web = j['web'] as Map<String, dynamic>? ?? const {};
    return BillingConfig(
      playAvailable: play['available'] == true,
      productId: play['productId'] as String? ?? '',
      webAvailable: web['available'] == true,
    );
  }

  static const unavailable = BillingConfig(playAvailable: false, productId: '', webAvailable: false);

  final bool playAvailable;

  /// Google Play one-time product id of the Premium unlock.
  final String productId;
  final bool webAvailable;
}

class PlayVerifyResult {
  const PlayVerifyResult({required this.premium, this.pending = false, required this.duplicatePurchase});
  final bool premium;

  /// Play says the payment isn't finished yet (cash or bank payments): nothing is unlocked yet.
  final bool pending;

  /// Premium was already bought on the website.
  final bool duplicatePurchase;
}

DateTime? _date(Object? v) => v is String ? DateTime.tryParse(v) : null;

/// The Gleefy API, as far as the app uses it. Tests use a fake.
abstract class AccountApi {
  bool get configured;
  Future<BillingConfig> billingConfig();
  Future<AccountInfo> me();
  Future<String> playAccountRef();
  Future<PlayVerifyResult> verifyPlayPurchase(String purchaseToken);
  Future<void> deleteAccount();
}

class HttpAccountApi implements AccountApi {
  HttpAccountApi(this._dio, this._auth);

  /// Base URL is the API origin; paths are versioned here.
  final Dio _dio;
  final AuthRepository _auth;

  @override
  bool get configured => true;

  /// Sends a request with a fresh access token. A token the API rejects is refreshed once and the
  /// request resent (same as Weblume); a token that can't be refreshed while offline is a network error.
  Future<Map<String, dynamic>> _send(String method, String path, {Object? data, bool auth = true}) async {
    String? token;
    if (auth) {
      try {
        token = await _auth.accessToken();
      } on AuthFailure {
        throw ApiException(isNetworkError: true);
      }
      if (token == null) throw ApiException(status: 401, code: 'signed_out');
    }
    try {
      return await _request(method, path, data, token);
    } on ApiException catch (e) {
      if (!auth || e.status != 401) rethrow;
      final fresh = await _auth.refreshAccessToken();
      if (fresh == null || fresh == token) rethrow;
      return _request(method, path, data, fresh);
    }
  }

  Future<Map<String, dynamic>> _request(String method, String path, Object? data, String? token) async {
    try {
      final res = await _dio.request<Map<String, dynamic>>(
        path,
        data: data,
        options: Options(method: method, headers: {if (token != null) 'Authorization': 'Bearer $token'}),
      );
      return res.data ?? const {};
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == null) throw ApiException(isNetworkError: true);
      final body = e.response?.data;
      throw ApiException(status: status, code: body is Map ? body['code'] as String? : null);
    }
  }

  @override
  Future<BillingConfig> billingConfig() async =>
      BillingConfig.fromJson(await _send('GET', '/v1/billing/config', auth: false));

  @override
  Future<AccountInfo> me() async => AccountInfo.fromJson(await _send('GET', '/v1/me'));

  @override
  Future<String> playAccountRef() async =>
      (await _send('GET', '/v1/billing/google-play/account-ref'))['accountRef'] as String;

  @override
  Future<PlayVerifyResult> verifyPlayPurchase(String purchaseToken) async {
    final j = await _send('POST', '/v1/billing/google-play/verify', data: {'purchaseToken': purchaseToken});
    return PlayVerifyResult(
      premium: j['planId'] == 'premium' && j['status'] == 'active',
      pending: j['status'] == 'on_hold',
      duplicatePurchase: j['duplicatePurchase'] == true,
    );
  }

  @override
  Future<void> deleteAccount() => _send('DELETE', '/v1/me', data: {'confirm': 'DELETE'});
}

class UnconfiguredAccountApi implements AccountApi {
  const UnconfiguredAccountApi();
  @override
  bool get configured => false;
  Never _fail() => throw ApiException(code: 'unavailable');
  @override
  Future<BillingConfig> billingConfig() async => BillingConfig.unavailable;
  @override
  Future<AccountInfo> me() async => _fail();
  @override
  Future<String> playAccountRef() async => _fail();
  @override
  Future<PlayVerifyResult> verifyPlayPurchase(String purchaseToken) async => _fail();
  @override
  Future<void> deleteAccount() async => _fail();
}
