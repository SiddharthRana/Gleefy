import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../account/entitlement.dart';
import '../content/content.dart';
import 'custom_questions.dart';

/// Overridden in main() (and tests) with the instance loaded at startup.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) => throw UnimplementedError());

/// Overridden in main() (and tests) with the content loaded and checked at startup.
final bundledContentProvider = Provider<ContentLibrary>((ref) => throw UnimplementedError());

/// Everything playable: the bundled packs plus the person's own questions.
final contentProvider = Provider<ContentLibrary>(
  (ref) => withCustomQuestions(ref.watch(bundledContentProvider), ref.watch(customQuestionsProvider)),
);

/// Current time; overridden in tests.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Whether premium content is unlocked: only from the server-verified entitlement (or its cached
/// copy within the offline grace window), never from a client-side flag.
final premiumProvider = Provider<bool>((ref) {
  final snapshot = ref.watch(entitlementProvider.select((s) => s.snapshot));
  return snapshot?.grantsPremiumAt(ref.watch(clockProvider)()) ?? false;
});

/// Keeps the screen on during play. Behind an interface so tests don't need the platform plugin.
abstract interface class ScreenAwake {
  Future<void> enable();
  Future<void> disable();
}

class WakelockScreenAwake implements ScreenAwake {
  const WakelockScreenAwake();
  @override
  Future<void> enable() => WakelockPlus.enable();
  @override
  Future<void> disable() => WakelockPlus.disable();
}

final screenAwakeProvider = Provider<ScreenAwake>((ref) => const WakelockScreenAwake());
