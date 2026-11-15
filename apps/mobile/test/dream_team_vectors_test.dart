import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gleefy/game/dream_team_engine.dart';

List<Map<String, dynamic>> listOf(Object? v) => (v as List<dynamic>).cast<Map<String, dynamic>>();

/// Replays the TypeScript engine's Dream Team vectors (packages/game-engine) against the Dart port.
void main() {
  final v = jsonDecode(
    File('../../packages/game-engine/test-vectors/dream-team.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final withStats = [
    for (final c in listOf(v['cards']))
      DreamTeamCard(
        id: c['id'] as String,
        name: c['name'] as String,
        stats: (c['stats'] as Map<String, dynamic>).cast<String, int>(),
      ),
  ];
  final custom = [for (final c in withStats) DreamTeamCard(id: c.id, name: c.name)];

  for (final s in listOf(v['scenarios'])) {
    test('dream team: ${s['name']}', () {
      final cards = s['custom'] == true ? custom : withStats;
      final config = DreamTeamConfig.fromJson(s['config'] as Map<String, dynamic>);
      var state = createDreamTeam([for (final c in cards) c.id], config);
      for (final a in listOf(s['actions'])) {
        state = reduceDreamTeam(state, switch (a['type']) {
          'place' => PlaceCard(a['slot'] as int),
          'skip' => const SkipCard(),
          'vote' => VoteSlot(a['slot'] as int, a['side'] as int),
          'finish' => const FinishVoting(),
          _ => throw StateError('unknown action'),
        });
      }
      final results = dreamTeamResults(state, {for (final c in cards) c.id: c});
      final actual = jsonDecode(jsonEncode({...state.toJson(), 'results': results.toJson()}));
      expect(actual, s['expected']);
    });
  }

  test('a deck that is too small is refused', () {
    const roles = [DreamTeamRole(id: 'a', stat: 'lead'), DreamTeamRole(id: 'b', stat: 'power')];
    expect(
      () => createDreamTeam(['1', '2', '3', '4', '5'], const DreamTeamConfig(roles: roles, seed: 1, skips: 1)),
      throwsA(isA<DeckTooSmallException>()),
    );
  });
}
