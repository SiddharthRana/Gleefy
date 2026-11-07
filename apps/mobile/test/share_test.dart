import 'package:flutter_test/flutter_test.dart';
import 'package:gleefy/content/content.dart';
import 'package:gleefy/game/share.dart';

void main() {
  test('decodes links made by the website', () {
    // encodeShare({mode: 'trivia', categoryIds: ['science'], rounds: 5, seed: 42, timeLimitMs: 10000})
    final g = decodeShare('eyJtIjoyLCJjIjpbInNjaWVuY2UiXSwiciI6NSwicyI6NDIsInQiOjEwMDAwfQ')!;
    expect(g.mode, GameMode.trivia);
    expect(g.categoryIds, ['science']);
    expect(g.rounds, 5);
    expect(g.seed, 42);
    expect(g.timeLimitMs, 10000);
  });

  test('rejects broken links', () {
    for (final bad in ['', 'nope!', 'e30', 'eyJtIjo5fQ']) {
      expect(decodeShare(bad), isNull, reason: bad);
    }
  });
}
