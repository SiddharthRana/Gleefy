import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;

import '../game/dream_team_engine.dart';
import 'content.dart';

/// A set of role slots each side fills, e.g. Captain, Tank, Strategist, Healer, Wildcard.
@immutable
class RoleSet {
  const RoleSet({required this.id, required this.name, required this.roles});

  final String id;
  final String name;
  final List<DreamTeamRole> roles;
}

/// The Dream Team pack (packages/content/packs/dream-team.json): decks are its categories.
/// Mirrors packages/content/src/schema.ts; CI validates the pack, the app re-checks essentials.
@immutable
class DreamTeamPack {
  const DreamTeamPack({required this.decks, required this.roleSets, required this.cards});

  static const empty = DreamTeamPack(decks: [], roleSets: [], cards: []);

  final List<Category> decks;
  final List<RoleSet> roleSets;
  final List<DreamTeamCard> cards;

  bool get isEmpty => decks.isEmpty || roleSets.isEmpty;

  List<DreamTeamCard> cardsIn(String deckId) => cards.where((c) => c.category == deckId).toList();

  static DreamTeamPack parse(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException catch (e) {
      throw FormatException('Invalid JSON: ${e.message}');
    }
    if (json is! Map<String, dynamic> || json['mode'] != 'dream-team') {
      throw const FormatException('Not a dream-team pack');
    }
    try {
      final decks = [for (final c in json['categories'] as List<dynamic>) Category.fromJson(c as Map<String, dynamic>)];
      final roleSets = [
        for (final r in json['roleSets'] as List<dynamic>)
          RoleSet(
            id: (r as Map<String, dynamic>)['id'] as String,
            name: r['name'] as String,
            roles: [
              for (final role in r['roles'] as List<dynamic>) DreamTeamRole.fromJson(role as Map<String, dynamic>),
            ],
          ),
      ];
      final cards = [
        for (final i in json['items'] as List<dynamic>)
          DreamTeamCard(
            id: (i as Map<String, dynamic>)['id'] as String,
            name: i['name'] as String,
            blurb: i['blurb'] as String,
            category: i['category'] as String,
            stats: (i['stats'] as Map<String, dynamic>).cast<String, int>(),
          ),
      ];
      final deckIds = decks.map((d) => d.id).toSet();
      final seen = <String>{};
      for (final c in cards) {
        if (!deckIds.contains(c.category)) throw FormatException('${c.id}: unknown deck ${c.category}');
        if (!seen.add(c.id)) throw FormatException('duplicate id ${c.id}');
        if (!dreamTeamStats.every((s) => (c.stats![s] ?? 0) >= 1)) throw FormatException('${c.id}: missing stats');
      }
      for (final set in roleSets) {
        if (set.roles.isEmpty || set.roles.any((r) => !dreamTeamStats.contains(r.stat))) {
          throw FormatException('${set.id}: bad roles');
        }
      }
      if (decks.isEmpty || roleSets.isEmpty || cards.isEmpty) throw const FormatException('Pack is empty');
      return DreamTeamPack(decks: decks, roleSets: roleSets, cards: cards);
    } on TypeError catch (e) {
      throw FormatException('Malformed pack: $e');
    }
  }
}
