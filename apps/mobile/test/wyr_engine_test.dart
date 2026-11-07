import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gleefy/content/content.dart';
import 'package:gleefy/game/wyr_engine.dart';

void main() {
  final pool = [for (var i = 1; i <= 4; i++) WyrItem(id: 'wyr-casual-00$i', category: 'casual', a: 'a$i', b: 'b$i')];
  const config = WyrConfig(categoryIds: ['casual'], rounds: 3, seed: 5, playerCount: 4);

  test('rejects empty pools and bad round counts', () {
    expect(() => createWyrSession([], config), throwsA(isA<EmptyPoolException>()));
    expect(
      () => createWyrSession(pool, const WyrConfig(categoryIds: ['casual'], rounds: 0, seed: 1)),
      throwsRangeError,
    );
  });

  test('state survives a JSON round trip mid-round', () {
    var s = createWyrSession(pool, config);
    for (final a in const <WyrAction>[
      Vote(Side.a),
      Next(),
      Vote(Side.b),
      Vote(Side.a),
      SkipQuestion(),
      Vote(Side.b),
      Reveal(),
    ]) {
      s = reduceWyr(s, a);
    }
    final restored = WyrState.fromJson(jsonDecode(jsonEncode(s.toJson())) as Map<String, dynamic>);
    expect(restored.toJson(), s.toJson());
    expect(reduceWyr(restored, const Next()).toJson(), reduceWyr(s, const Next()).toJson());
  });

  test('round number and last-round flag', () {
    var s = createWyrSession(pool, config);
    expect(s.roundNumber, 1);
    expect(s.isLastRound, isFalse);
    s = reduceWyr(reduceWyr(s, const Next()), const Next());
    expect(s.roundNumber, 3);
    expect(s.isLastRound, isTrue);
    s = reduceWyr(s, const Next());
    expect(s.status, WyrStatus.finished);
    expect(s.roundNumber, 3);
  });

  test('unchanged actions return the identical state', () {
    final s = createWyrSession(pool, config);
    expect(identical(reduceWyr(s, const Undo()), s), isTrue);
  });
}
