import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gleefy/content/content.dart';

import 'support/harness.dart';

String pack({List<Object?>? categories, List<Object?>? items, String mode = 'would-you-rather'}) => jsonEncode({
  'mode': mode,
  'version': 1,
  'categories':
      categories ??
      [
        {'id': 'casual', 'name': 'C', 'description': 'D', 'tier': 'free', 'ageRating': 'all', 'region': 'global'},
      ],
  'items':
      items ??
      [
        {'id': 'wyr-casual-001', 'category': 'casual', 'a': 'A', 'b': 'B'},
      ],
});

void main() {
  test('the bundled pack loads with every category populated', () {
    final wyr = realContent().wyr;
    expect(wyr.items.length, greaterThanOrEqualTo(100));
    for (final c in wyr.categories) {
      expect(wyr.countIn([c.id]), greaterThan(0), reason: c.id);
    }
    expect(wyr.categories.any((c) => c.tier == Tier.premium), isTrue);
  });

  test('parses a minimal valid pack', () {
    final p = parseWyrPack(pack());
    expect(p.item('wyr-casual-001')?.a, 'A');
    expect(p.category('casual')?.tier, Tier.free);
  });

  test('rejects broken packs with FormatException', () {
    final bad = <String>[
      '{not json',
      '[]',
      pack(mode: 'trivia'),
      pack(items: []),
      pack(categories: []),
      pack(
        items: [
          {'id': 'wyr-casual-001', 'category': 'missing', 'a': 'A', 'b': 'B'},
        ],
      ),
      pack(
        items: [
          {'id': 'wyr-casual-001', 'category': 'casual', 'a': 'A', 'b': 'B'},
          {'id': 'wyr-casual-001', 'category': 'casual', 'a': 'C', 'b': 'D'},
        ],
      ),
      pack(
        items: [
          {'id': 'wyr-casual-001', 'category': 'casual', 'a': ' ', 'b': 'B'},
        ],
      ),
      pack(
        items: [
          {'id': 'wyr-casual-001', 'category': 'casual', 'a': 3, 'b': 'B'},
        ],
      ),
      pack(
        categories: [
          {'id': 'casual', 'name': 'C', 'description': 'D', 'tier': 'gold', 'ageRating': 'all', 'region': 'global'},
        ],
      ),
    ];
    for (final source in bad) {
      expect(() => parseWyrPack(source), throwsFormatException, reason: source);
    }
  });
}
