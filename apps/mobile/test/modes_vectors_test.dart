import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gleefy/content/content.dart';
import 'package:gleefy/game/guess_engine.dart';
import 'package:gleefy/game/trivia_engine.dart';
import 'package:gleefy/game/wyr_engine.dart';

Map<String, dynamic> load(String name) =>
    jsonDecode(File('../../packages/game-engine/test-vectors/$name').readAsStringSync()) as Map<String, dynamic>;

List<Map<String, dynamic>> listOf(Object? v) => (v as List<dynamic>).cast<Map<String, dynamic>>();

/// Replays the TypeScript engine's vectors (packages/game-engine) against the Dart ports.
void main() {
  group('trivia vectors', () {
    final v = load('trivia.json');
    final items = [
      for (final i in listOf(v['items']))
        TriviaItem(
          id: i['id'] as String,
          category: i['category'] as String,
          question: 'q',
          choices: const ['a', 'b', 'c', 'd'],
          answer: i['answer'] as int,
          explanation: '',
        ),
    ];
    for (final s in listOf(v['scenarios'])) {
      test(s['name'] as String, () {
        final config = TriviaConfig.fromJson(s['config'] as Map<String, dynamic>);
        var state = createTriviaSession(buildPool(items, config.categoryIds), config);
        for (final a in listOf(s['actions'])) {
          state = reduceTrivia(state, switch (a['type']) {
            'answer' => Answer(a['choice'] as int, a['elapsedMs'] as int),
            'timeout' => const TimeUp(),
            'next' => const NextQuestion(),
            'skip' => const SkipTrivia(),
            _ => throw StateError('unknown action'),
          });
        }
        expect({...state.stateJson(), 'results': triviaResults(state).toJson()}, s['expected']);
      });
    }
  });

  group('guess vectors', () {
    final v = load('guess.json');
    final items = [
      for (final i in listOf(v['items']))
        GuessItem(id: i['id'] as String, category: i['category'] as String, answer: 'x', clues: const ['1', '2', '3']),
    ];
    for (final s in listOf(v['scenarios'])) {
      test(s['name'] as String, () {
        final config = GuessConfig.fromJson(s['config'] as Map<String, dynamic>);
        var state = createGuessSession(buildPool(items, config.categoryIds), config);
        for (final a in listOf(s['actions'])) {
          state = reduceGuess(state, GuessAction.values.byName(a['type'] as String));
        }
        expect({...state.stateJson(), 'results': guessResults(state).toJson()}, s['expected']);
      });
    }
  });

  group('agreement vectors', () {
    for (final s in listOf(load('would-you-rather.json')['agreement'])) {
      test(s['name'] as String, () {
        final rounds = listOf(s['rounds']).map(WyrRound.fromJson).toList();
        expect(bestAgreement(rounds, s['playerCount'] as int)?.toJson(), s['expected']);
      });
    }
  });

  test('sessions survive a JSON round trip', () {
    final items = [
      for (var i = 0; i < 5; i++)
        TriviaItem(
          id: 't$i',
          category: 'x',
          question: 'q',
          choices: const ['a', 'b', 'c', 'd'],
          answer: i % 4,
          explanation: '',
        ),
    ];
    var t = createTriviaSession(
      items,
      const TriviaConfig(categoryIds: ['x'], rounds: 3, seed: 3, teams: 2, timeLimitMs: 20000),
    );
    t = reduceTrivia(reduceTrivia(t, const Answer(1, 900)), const NextQuestion());
    expect(TriviaState.fromJson(jsonDecode(jsonEncode(t.toJson())) as Map<String, dynamic>).toJson(), t.toJson());

    var g = createGuessSession(items, const GuessConfig(categoryIds: ['x'], rounds: 3, seed: 3, teams: 2));
    g = reduceGuess(reduceGuess(g, GuessAction.clue), GuessAction.got);
    expect(GuessState.fromJson(jsonDecode(jsonEncode(g.toJson())) as Map<String, dynamic>).toJson(), g.toJson());
  });
}
