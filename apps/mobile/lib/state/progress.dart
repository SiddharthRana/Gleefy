import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/progress.dart';
import 'providers.dart';

/// XP, level, streak and trophies. Kept only on this phone (shared preferences), never uploaded.
class ProgressController extends Notifier<Progress> {
  static const storageKey = 'progress.v1';

  @override
  Progress build() {
    final raw = ref.read(sharedPreferencesProvider).getString(storageKey);
    if (raw == null) return const Progress();
    try {
      return Progress.fromJson(jsonDecode(raw));
    } on FormatException {
      return const Progress();
    }
  }

  /// Records a finished game and remembers the reward for the results screen.
  GameReward record({required String mode, required int rounds, bool? perfect}) {
    final today = localDay(ref.read(clockProvider)());
    final reward = recordGame(state, FinishedGame(mode: mode, rounds: rounds, day: today, perfect: perfect));
    state = reward.progress;
    ref.read(sharedPreferencesProvider).setString(storageKey, jsonEncode(reward.progress.toJson()));
    ref.read(lastRewardProvider.notifier).set(reward);
    return reward;
  }
}

final progressProvider = NotifierProvider<ProgressController, Progress>(ProgressController.new);

/// The reward from the game that just finished, shown once on its results screen.
class LastRewardController extends Notifier<GameReward?> {
  @override
  GameReward? build() => null;

  void set(GameReward reward) => state = reward;
  void clear() => state = null;
}

final lastRewardProvider = NotifierProvider<LastRewardController, GameReward?>(LastRewardController.new);

/// Today's streak, which lapses once a whole day passes without a game.
final streakProvider = Provider<int>(
  (ref) => currentStreak(ref.watch(progressProvider), localDay(ref.watch(clockProvider)())),
);
