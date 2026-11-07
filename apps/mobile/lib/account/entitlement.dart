import 'dart:async';
import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/providers.dart';
import 'api_client.dart';
import 'auth_repository.dart';

/// Overridden in main() with Supabase when the build is configured.
final authRepositoryProvider = Provider<AuthRepository>((ref) => const UnconfiguredAuthRepository());

/// Overridden in main() with the HTTP client when the build is configured.
final accountApiProvider = Provider<AccountApi>((ref) => const UnconfiguredAccountApi());

/// How long a cached timed entitlement outlives its paid period when the phone can't reach the
/// server, so Premium doesn't vanish at a party with bad signal (BUILD_PROMPT §11). A one-time
/// unlock doesn't run out at all.
const offlineGrace = Duration(days: 3);

/// The last entitlement the server verified for the signed-in purchaser, as cached on the phone.
class EntitlementSnapshot {
  const EntitlementSnapshot({
    required this.userId,
    required this.premium,
    this.lifetime = false,
    this.validUntil,
    required this.checkedAt,
  });

  factory EntitlementSnapshot.fromJson(Map<String, dynamic> j) => EntitlementSnapshot(
    userId: j['userId'] as String,
    premium: j['premium'] == true,
    lifetime: j['lifetime'] == true,
    validUntil: j['validUntil'] == null ? null : DateTime.parse(j['validUntil'] as String),
    checkedAt: DateTime.parse(j['checkedAt'] as String),
  );

  final String userId;
  final bool premium;

  /// Premium is a one-time unlock: it stays on offline for good.
  final bool lifetime;

  /// End of the paid period the server reported (none for a one-time unlock).
  final DateTime? validUntil;
  final DateTime checkedAt;

  /// Premium for good when it was a one-time unlock, otherwise until the end of the verified period
  /// plus [offlineGrace]. A refresh replaces this, so a refund takes effect as soon as the phone is
  /// back online.
  bool grantsPremiumAt(DateTime now) =>
      premium && (lifetime || now.isBefore((validUntil ?? checkedAt).add(offlineGrace)));

  Map<String, Object?> toJson() => {
    'userId': userId,
    'premium': premium,
    'lifetime': lifetime,
    'validUntil': validUntil?.toUtc().toIso8601String(),
    'checkedAt': checkedAt.toUtc().toIso8601String(),
  };
}

class EntitlementState {
  const EntitlementState({this.user, this.snapshot, this.account, this.refreshing = false, this.offline = false});

  final AppUser? user;
  final EntitlementSnapshot? snapshot;

  /// Full account details from the last successful refresh in this run (null when offline).
  final AccountInfo? account;
  final bool refreshing;

  /// The last refresh couldn't reach the server; the cached entitlement is in use.
  final bool offline;

  bool get signedIn => user != null;
}

/// Holds the purchaser's verified entitlement. Premium comes only from the server (or its cached
/// answer), never from a local flag the app sets itself.
class EntitlementController extends Notifier<EntitlementState> {
  static const _storageKey = 'entitlement.v1';
  StreamSubscription<AuthEvent>? _events;
  AppLifecycleListener? _lifecycle;

  @override
  EntitlementState build() {
    final auth = ref.watch(authRepositoryProvider);
    _events = auth.events.listen((e) {
      if (e == AuthEvent.signedIn) unawaited(refresh());
      if (e == AuthEvent.signedOut) _forget();
    });
    _lifecycle = AppLifecycleListener(onResume: () => unawaited(refresh()));
    ref.onDispose(() {
      _events?.cancel();
      _lifecycle?.dispose();
    });
    final user = auth.currentUser;
    final cached = _readCache();
    return EntitlementState(user: user, snapshot: cached != null && cached.userId == user?.id ? cached : null);
  }

  EntitlementSnapshot? _readCache() {
    final raw = ref.read(sharedPreferencesProvider).getString(_storageKey);
    if (raw == null) return null;
    try {
      return EntitlementSnapshot.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  /// Asks the server what this account may use and caches the answer. Keeps the cache when offline.
  Future<void> refresh() async {
    final user = ref.read(authRepositoryProvider).currentUser;
    final api = ref.read(accountApiProvider);
    if (user == null || !api.configured) {
      if (state.snapshot != null || state.user != null) _forget();
      return;
    }
    state = EntitlementState(user: user, snapshot: state.snapshot, account: state.account, refreshing: true);
    try {
      final account = await api.me();
      final snapshot = EntitlementSnapshot(
        userId: user.id,
        premium: account.premium,
        lifetime: account.lifetime,
        validUntil: account.validUntil,
        checkedAt: ref.read(clockProvider)(),
      );
      await ref.read(sharedPreferencesProvider).setString(_storageKey, jsonEncode(snapshot.toJson()));
      state = EntitlementState(user: user, snapshot: snapshot, account: account);
    } on ApiException catch (e) {
      if (e.status == 401 || e.status == 403) {
        // Session expired or account deleted: the cached entitlement no longer applies.
        await ref.read(authRepositoryProvider).signOut();
        _forget();
        return;
      }
      state = EntitlementState(user: user, snapshot: state.snapshot, account: state.account, offline: true);
    }
  }

  void _forget() {
    ref.read(sharedPreferencesProvider).remove(_storageKey);
    state = EntitlementState(user: ref.read(authRepositoryProvider).currentUser);
  }

  Future<void> signOut() async {
    await ref.read(authRepositoryProvider).signOut();
    _forget();
  }

  /// Deletes the account on the server, then signs out locally.
  Future<void> deleteAccount() async {
    await ref.read(accountApiProvider).deleteAccount();
    await signOut();
  }
}

final entitlementProvider = NotifierProvider<EntitlementController, EntitlementState>(EntitlementController.new);
