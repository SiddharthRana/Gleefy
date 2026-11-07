import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mirthmix/game/progress.dart';

/// Replays packages/game-engine/test-vectors/progress.json, generated from the TypeScript engine.
void main() {
  final vectors = jsonDecode(
    File('../../packages/game-engine/test-vectors/progress.json').readAsStringSync(),
  ) as Map<String, dynamic>;

  test('levels and thresholds match the TypeScript engine', () {
    for (final v in (vectors['levels'] as List).cast<Map<String, dynamic>>()) {
      final p = levelProgress(v['xp'] as int);
      expect((p.level, p.into, p.needed), (v['level'], v['into'], v['needed']), reason: 'xp ${v['xp']}');
    }
    for (final v in (vectors['thresholds'] as List).cast<Map<String, dynamic>>()) {
      expect(xpForLevel(v['level'] as int), v['xp']);
    }
  });

  for (final scenario in (vectors['scenarios'] as List).cast<Map<String, dynamic>>()) {
    test('scenario: ${scenario['name']}', () {
      var progress = const Progress();
      for (final step in (scenario['steps'] as List).cast<Map<String, dynamic>>()) {
        final g = step['game'] as Map<String, dynamic>;
        final reward = recordGame(
          progress,
          FinishedGame(
            mode: g['mode'] as String,
            rounds: g['rounds'] as int,
            day: g['day'] as String,
            perfect: g['perfect'] as bool?,
          ),
        );
        final expected = step['reward'] as Map<String, dynamic>;
        expect(reward.progress.toJson(), expected['progress'], reason: 'after ${g['day']} ${g['mode']}');
        expect(
          (reward.xpGained, reward.levelBefore, reward.levelAfter),
          (expected['xpGained'], expected['levelBefore'], expected['levelAfter']),
        );
        expect(reward.newTrophies, expected['newTrophies']);
        progress = reward.progress;
      }
    });
  }

  test('stored progress is read defensively', () {
    final p = Progress.fromJson({
      'xp': 120,
      'gamesPlayed': -3,
      'modesPlayed': ['trivia', 'chess'],
      'lastPlayedDay': 'yesterday',
      'trophies': ['first-game', 'made-up'],
    });
    expect(p.toJson(), {
      'xp': 120,
      'gamesPlayed': 0,
      'modesPlayed': ['trivia'],
      'streak': 0,
      'bestStreak': 0,
      'lastPlayedDay': null,
      'trophies': ['first-game'],
    });
    expect(Progress.fromJson('nonsense').xp, 0);
  });

  test('the streak lapses after a whole day without a game', () {
    const p = Progress(streak: 4, lastPlayedDay: '2026-11-01');
    expect(
      [
        for (final d in ['2026-11-01', '2026-11-02', '2026-11-03']) currentStreak(p, d),
      ],
      [4, 4, 0],
    );
  });
}
