import 'dart:async';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../state/providers.dart';
import '../state/settings.dart';

/// Where events go. Overridden in main() with PostHog when the build has a key; null = no analytics.
final analyticsSinkProvider = Provider<AnalyticsSink?>((ref) => null);

abstract interface class AnalyticsSink {
  Future<void> send(Map<String, Object?> event);
}

/// PostHog's plain HTTP capture API (no SDK, so nothing runs unless someone opts in).
class PostHogSink implements AnalyticsSink {
  PostHogSink(this._dio, this._apiKey);

  final Dio _dio;
  final String _apiKey;

  @override
  Future<void> send(Map<String, Object?> event) async {
    try {
      await _dio.post<void>('/capture/', data: {'api_key': _apiKey, ...event});
    } on Object {
      // Analytics must never affect play: offline or failed events are dropped.
    }
  }
}

/// Privacy-safe usage analytics and error reports (BUILD_PROMPT §13). Sends nothing unless the build
/// is configured **and** the person turned on "Share anonymous usage stats" in Settings. Events
/// carry a random install id (for retention), the app version and small, non-identifying
/// properties: never player names, questions, answers, email or account ids.
class Analytics {
  Analytics(this.ref);

  final Ref ref;
  static const _idKey = 'analytics.installId';
  static const _maxErrorsPerRun = 20;
  int _errors = 0;

  /// The build can send analytics at all (a PostHog key was supplied).
  bool get available => ref.read(analyticsSinkProvider) != null;

  bool get enabled => available && ref.read(settingsProvider).shareUsage;

  /// Random, resettable id for this install; created only after opting in.
  String _installId() {
    final prefs = ref.read(sharedPreferencesProvider);
    final existing = prefs.getString(_idKey);
    if (existing != null) return existing;
    final r = Random.secure();
    final id = List.generate(16, (_) => r.nextInt(256).toRadixString(16).padLeft(2, '0')).join();
    prefs.setString(_idKey, id);
    return id;
  }

  /// Forgets the install id, so turning sharing back on starts a new, unlinked id.
  void reset() => ref.read(sharedPreferencesProvider).remove(_idKey);

  void track(String event, [Map<String, Object?> properties = const {}]) {
    if (!enabled) return;
    unawaited(
      ref.read(analyticsSinkProvider)!.send({
        'event': event,
        'distinct_id': _installId(),
        'timestamp': ref.read(clockProvider)().toUtc().toIso8601String(),
        'properties': {
          ...properties,
          'app_version': AppConfig.appVersion,
          'platform': defaultTargetPlatform.name,
          // Anonymous events: no person profiles.
          r'$process_person_profile': false,
        },
      }),
    );
  }

  /// Uncaught errors, as PostHog exception events. Messages are truncated; no app state is attached.
  void captureError(Object error, StackTrace? stack) {
    if (!enabled || _errors >= _maxErrorsPerRun) return;
    _errors++;
    final message = error.toString();
    track(r'$exception', {
      r'$exception_type': error.runtimeType.toString(),
      r'$exception_message': message.length > 500 ? message.substring(0, 500) : message,
      if (stack != null) r'$exception_stack_trace_raw': stack.toString().split('\n').take(40).join('\n'),
    });
  }
}

final analyticsProvider = Provider<Analytics>(Analytics.new);
