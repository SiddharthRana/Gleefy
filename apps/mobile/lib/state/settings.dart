import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.onboarded = false,
    this.themeMode = ThemeMode.system,
    this.bigText = false,
    this.reduceMotion = false,
    this.haptics = true,
    this.shareUsage = false,
  });

  final bool onboarded;
  final ThemeMode themeMode;
  final bool bigText;

  /// App-level switch; the system "remove animations" setting is honoured regardless.
  final bool reduceMotion;
  final bool haptics;

  /// Opt-in anonymous usage stats and error reports. Off unless the person turns it on.
  final bool shareUsage;

  AppSettings copyWith({
    bool? onboarded,
    ThemeMode? themeMode,
    bool? bigText,
    bool? reduceMotion,
    bool? haptics,
    bool? shareUsage,
  }) => AppSettings(
    onboarded: onboarded ?? this.onboarded,
    themeMode: themeMode ?? this.themeMode,
    bigText: bigText ?? this.bigText,
    reduceMotion: reduceMotion ?? this.reduceMotion,
    haptics: haptics ?? this.haptics,
    shareUsage: shareUsage ?? this.shareUsage,
  );
}

class SettingsController extends Notifier<AppSettings> {
  static const _prefix = 'settings.';

  @override
  AppSettings build() {
    final p = ref.read(sharedPreferencesProvider);
    return AppSettings(
      onboarded: p.getBool('${_prefix}onboarded') ?? false,
      themeMode: ThemeMode.values.asNameMap()[p.getString('${_prefix}themeMode')] ?? ThemeMode.system,
      bigText: p.getBool('${_prefix}bigText') ?? false,
      reduceMotion: p.getBool('${_prefix}reduceMotion') ?? false,
      haptics: p.getBool('${_prefix}haptics') ?? true,
      shareUsage: p.getBool('${_prefix}shareUsage') ?? false,
    );
  }

  Future<void> update(AppSettings next) async {
    state = next;
    final p = ref.read(sharedPreferencesProvider);
    await Future.wait([
      p.setBool('${_prefix}onboarded', next.onboarded),
      p.setString('${_prefix}themeMode', next.themeMode.name),
      p.setBool('${_prefix}bigText', next.bigText),
      p.setBool('${_prefix}reduceMotion', next.reduceMotion),
      p.setBool('${_prefix}haptics', next.haptics),
      p.setBool('${_prefix}shareUsage', next.shareUsage),
    ]);
  }
}

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(SettingsController.new);

/// True when animations should be skipped: the system setting or the in-app switch.
bool reduceMotionOf(BuildContext context, WidgetRef ref) =>
    MediaQuery.disableAnimationsOf(context) || ref.watch(settingsProvider.select((s) => s.reduceMotion));
