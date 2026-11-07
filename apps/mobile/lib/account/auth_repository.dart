import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../config/app_config.dart';

class AppUser {
  const AppUser({required this.id, this.email});
  final String id;
  final String? email;
}

enum AuthEvent { signedIn, signedOut, other }

class AuthFailure implements Exception {
  AuthFailure(this.code);

  /// invalid_code, rate_limited, network, unavailable, google_failed, unknown.
  final String code;
  @override
  String toString() => 'AuthFailure($code)';
}

/// Sign-in boundary. Only people who buy or restore Premium sign in; guests never need to.
/// "Continue with Google", or email + one-time code (no password). Tests use a fake.
abstract class AuthRepository {
  bool get configured;
  AppUser? get currentUser;

  /// The access token for API calls, refreshed first if it has expired (as it has when Android
  /// reopens the app after closing it in the background). Throws [AuthFailure] ('network') when it
  /// has expired and can't be refreshed right now, for example while offline.
  Future<String?> accessToken();

  /// A new access token after the API rejected the current one, or null if there's none.
  Future<String?> refreshAccessToken();
  Stream<AuthEvent> get events;

  /// Emails a 6-digit code; creates the account on first use.
  Future<void> sendCode(String email);
  Future<void> verifyCode({required String email, required String code});

  /// Whether "Continue with Google" is offered.
  bool get googleEnabled;

  /// Opens Google's sign-in page in the browser. It returns to the app through the
  /// mirthmix://auth-callback deep link, and [events] reports signedIn when it's done.
  Future<void> signInWithGoogle();

  /// Why a Google sign-in failed after Google sent the person back to the app: an error code for
  /// the sign-in screen (google_cancelled, google_signups_closed, google_failed).
  Stream<String> get googleErrors;
  Future<void> signOut();
}

/// Supabase Auth with PKCE (the session lives in the Android Keystore, see main.dart).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth) {
    // Supabase reports a failed return from Google as an error on the auth stream. Only errors that
    // arrive while a Google sign-in is under way are shown: the stream also carries token-refresh
    // failures, which aren't the person's to act on (same as Weblume).
    _auth.onAuthStateChange.listen(
      (s) {
        if (s.event == sb.AuthChangeEvent.signedIn) _googlePending = false;
      },
      onError: (Object e) {
        if (!_googlePending || e is! sb.AuthException) return;
        _googlePending = false;
        _googleErrors.add(describeGoogleError(e.code, e.message));
      },
    );
  }

  final sb.GoTrueClient _auth;
  final _googleErrors = StreamController<String>.broadcast();
  bool _googlePending = false;

  @override
  bool get configured => true;

  @override
  AppUser? get currentUser {
    final u = _auth.currentUser;
    return u == null ? null : AppUser(id: u.id, email: u.email);
  }

  @override
  Future<String?> accessToken() async {
    try {
      return (await _auth.getSession())?.accessToken;
    } on sb.AuthException {
      throw AuthFailure('network');
    }
  }

  @override
  Future<String?> refreshAccessToken() async {
    if (_auth.currentSession == null) return null;
    try {
      return (await _auth.refreshSession()).session?.accessToken;
    } on sb.AuthException {
      return null;
    }
  }

  @override
  Stream<AuthEvent> get events => _auth.onAuthStateChange
      .handleError((Object _) {})
      .map(
        (s) => switch (s.event) {
          sb.AuthChangeEvent.signedIn => AuthEvent.signedIn,
          sb.AuthChangeEvent.signedOut => AuthEvent.signedOut,
          _ => AuthEvent.other,
        },
      );

  Future<void> _guard(Future<void> Function() fn) async {
    try {
      await fn();
    } on AuthFailure {
      rethrow;
    } on sb.AuthException catch (e) {
      final code = e.code ?? '';
      if (code == 'otp_expired' || code == 'invalid_credentials') throw AuthFailure('invalid_code');
      if (code.startsWith('over_') || e.statusCode == '429') throw AuthFailure('rate_limited');
      throw AuthFailure('unknown');
    } on Object {
      throw AuthFailure('network');
    }
  }

  @override
  Future<void> sendCode(String email) => _guard(() => _auth.signInWithOtp(email: email.trim()));

  @override
  Future<void> verifyCode({required String email, required String code}) =>
      _guard(() => _auth.verifyOTP(email: email.trim(), token: code.trim(), type: sb.OtpType.email));

  @override
  bool get googleEnabled => AppConfig.googleSignInEnabled;

  @override
  Stream<String> get googleErrors => _googleErrors.stream;

  @override
  Future<void> signInWithGoogle() => _guard(() async {
    _googlePending = true;
    final opened = await _auth.signInWithOAuth(
      sb.OAuthProvider.google,
      redirectTo: AppConfig.authRedirectUrl,
      authScreenLaunchMode: sb.LaunchMode.externalApplication,
    );
    if (!opened) {
      _googlePending = false;
      throw AuthFailure('google_failed');
    }
  });

  @override
  Future<void> signOut() => _guard(() => _auth.signOut());
}

/// Used when the build has no Supabase configuration.
class UnconfiguredAuthRepository implements AuthRepository {
  const UnconfiguredAuthRepository();
  @override
  bool get configured => false;
  @override
  AppUser? get currentUser => null;
  @override
  Future<String?> accessToken() async => null;
  @override
  Future<String?> refreshAccessToken() async => null;
  @override
  Stream<AuthEvent> get events => const Stream.empty();
  @override
  Future<void> sendCode(String email) async => throw AuthFailure('unavailable');
  @override
  Future<void> verifyCode({required String email, required String code}) async => throw AuthFailure('unavailable');
  @override
  bool get googleEnabled => false;
  @override
  Future<void> signInWithGoogle() async => throw AuthFailure('unavailable');
  @override
  Stream<String> get googleErrors => const Stream.empty();
  @override
  Future<void> signOut() async {}
}

/// A light check before asking the server; the server is the real judge.
bool looksLikeEmail(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());

/// Error codes for a Google sign-in that came back with an error ([code] is the OAuth error, such
/// as access_denied when the person cancels on Google's page).
String describeGoogleError(String? code, String message) {
  if (RegExp('signups? not allowed', caseSensitive: false).hasMatch(message)) return 'google_signups_closed';
  if (code == 'access_denied') return 'google_cancelled';
  return 'google_failed';
}
