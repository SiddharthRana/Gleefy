import 'package:flutter/foundation.dart';

import 'random.dart';

/// Port of packages/game-engine/src/dream-team.ts. Keep the two in step: the shared test vectors
/// (test-vectors/dream-team.json) run against both.
///
/// A blind draft for two sides: each turn a side flips a random card and must lock it into one of
/// its empty role slots, with one skip per side. When both teams are full the room votes role by
/// role, and the cards' hidden stats give a second, "stats" verdict.
const dreamTeamStats = ['lead', 'power', 'smarts', 'heart', 'chaos'];

@immutable
class DreamTeamCard {
  const DreamTeamCard({required this.id, required this.name, this.blurb, this.stats, this.category, this.photo});

  final String id;
  final String name;
  final String? blurb;
  final String? category;

  /// A photo the person added to a custom card (a file on this phone). Display only.
  final String? photo;

  /// 1–10 per stat in [dreamTeamStats]. Custom decks have none, so the room alone decides.
  final Map<String, int>? stats;
}

@immutable
class DreamTeamRole {
  const DreamTeamRole({required this.id, required this.stat, this.name = ''});

  final String id;
  final String name;

  /// The stat the stats verdict compares for this slot.
  final String stat;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'stat': stat};

  factory DreamTeamRole.fromJson(Map<String, dynamic> j) =>
      DreamTeamRole(id: j['id'] as String, name: (j['name'] as String?) ?? '', stat: j['stat'] as String);
}

@immutable
class DreamTeamConfig {
  const DreamTeamConfig({required this.roles, required this.seed, required this.skips});

  final List<DreamTeamRole> roles;
  final int seed;

  /// Skips per side.
  final int skips;

  Map<String, Object?> toJson() => {
    'roles': [for (final r in roles) r.toJson()],
    'seed': seed,
    'skips': skips,
  };

  factory DreamTeamConfig.fromJson(Map<String, dynamic> j) => DreamTeamConfig(
    roles: [for (final r in j['roles'] as List<dynamic>) DreamTeamRole.fromJson(r as Map<String, dynamic>)],
    seed: j['seed'] as int,
    skips: j['skips'] as int,
  );
}

enum DreamTeamStatus { drafting, voting, finished }

class DeckTooSmallException implements Exception {
  const DeckTooSmallException(this.needed);
  final int needed;

  @override
  String toString() => 'A Dream Team deck needs at least $needed cards';
}

/// Cards a deck needs for a setup: every slot on both sides, plus every skip.
int cardsNeeded(int roles, int skips) => 2 * roles + 2 * skips;

@immutable
class DreamTeamState {
  const DreamTeamState({
    required this.config,
    required this.order,
    required this.cursor,
    required this.turn,
    required this.drawn,
    required this.teams,
    required this.skipsLeft,
    required this.votes,
    required this.status,
  });

  final DreamTeamConfig config;

  /// The deck, shuffled by the seed.
  final List<String> order;

  /// Next card to draw from [order].
  final int cursor;

  /// The side on turn: 0 or 1.
  final int turn;

  /// The card the side on turn must place (null once drafting ends).
  final String? drawn;

  /// Card id per role slot, for each side.
  final List<List<String?>> teams;
  final List<int> skipsLeft;

  /// The room's pick per role slot: 0, 1 or null.
  final List<int?> votes;
  final DreamTeamStatus status;

  DreamTeamState copyWith({
    int? cursor,
    int? turn,
    String? drawn,
    bool clearDrawn = false,
    List<List<String?>>? teams,
    List<int>? skipsLeft,
    List<int?>? votes,
    DreamTeamStatus? status,
  }) => DreamTeamState(
    config: config,
    order: order,
    cursor: cursor ?? this.cursor,
    turn: turn ?? this.turn,
    drawn: clearDrawn ? null : (drawn ?? this.drawn),
    teams: teams ?? this.teams,
    skipsLeft: skipsLeft ?? this.skipsLeft,
    votes: votes ?? this.votes,
    status: status ?? this.status,
  );

  /// Same shape as the TypeScript state (minus config), for the shared vectors and saving.
  Map<String, Object?> toJson() => {
    'order': order,
    'cursor': cursor,
    'turn': turn,
    'drawn': drawn,
    'teams': teams,
    'skipsLeft': skipsLeft,
    'votes': votes,
    'status': status.name,
  };

  factory DreamTeamState.fromJson(Map<String, dynamic> j, DreamTeamConfig config) => DreamTeamState(
    config: config,
    order: (j['order'] as List<dynamic>).cast<String>(),
    cursor: j['cursor'] as int,
    turn: j['turn'] as int,
    drawn: j['drawn'] as String?,
    teams: [for (final t in j['teams'] as List<dynamic>) (t as List<dynamic>).cast<String?>()],
    skipsLeft: (j['skipsLeft'] as List<dynamic>).cast<int>(),
    votes: (j['votes'] as List<dynamic>).cast<int?>(),
    status: DreamTeamStatus.values.byName(j['status'] as String),
  );
}

DreamTeamState createDreamTeam(List<String> cardIds, DreamTeamConfig config) {
  final roles = config.roles.length;
  if (roles < 1) throw RangeError('at least one role is needed');
  if (config.skips < 0) throw RangeError('skips must be a whole number');
  final unique = <String>{...cardIds}.toList();
  final needed = cardsNeeded(roles, config.skips);
  if (unique.length < needed) throw DeckTooSmallException(needed);
  final order = seededShuffle(unique, config.seed);
  return DreamTeamState(
    config: config,
    order: order,
    cursor: 1,
    turn: 0,
    drawn: order.first,
    teams: [List<String?>.filled(roles, null), List<String?>.filled(roles, null)],
    skipsLeft: [config.skips, config.skips],
    votes: List<int?>.filled(roles, null),
    status: DreamTeamStatus.drafting,
  );
}

sealed class DreamTeamAction {
  const DreamTeamAction();
}

class PlaceCard extends DreamTeamAction {
  const PlaceCard(this.slot);
  final int slot;
}

class SkipCard extends DreamTeamAction {
  const SkipCard();
}

class VoteSlot extends DreamTeamAction {
  const VoteSlot(this.slot, this.side);
  final int slot;
  final int side;
}

class FinishVoting extends DreamTeamAction {
  const FinishVoting();
}

DreamTeamState reduceDreamTeam(DreamTeamState s, DreamTeamAction action) {
  switch (action) {
    case PlaceCard(:final slot):
      final team = s.teams[s.turn];
      if (s.status != DreamTeamStatus.drafting || s.drawn == null) return s;
      if (slot < 0 || slot >= team.length || team[slot] != null) return s;
      final placed = [for (var i = 0; i < team.length; i++) i == slot ? s.drawn : team[i]];
      final teams = s.turn == 0 ? [placed, s.teams[1]] : [s.teams[0], placed];
      if (teams.every((t) => t.every((c) => c != null))) {
        return s.copyWith(teams: teams, clearDrawn: true, status: DreamTeamStatus.voting);
      }
      // Turns alternate; a side that's already full is passed over.
      final other = s.turn == 0 ? 1 : 0;
      final turn = teams[other].any((c) => c == null) ? other : s.turn;
      return s.copyWith(teams: teams, turn: turn, drawn: s.order[s.cursor], cursor: s.cursor + 1);
    case SkipCard():
      if (s.status != DreamTeamStatus.drafting || s.skipsLeft[s.turn] < 1) return s;
      if (s.cursor >= s.order.length) return s;
      final skipsLeft = [...s.skipsLeft];
      skipsLeft[s.turn] -= 1;
      return s.copyWith(skipsLeft: skipsLeft, drawn: s.order[s.cursor], cursor: s.cursor + 1);
    case VoteSlot(:final slot, :final side):
      if (s.status != DreamTeamStatus.voting || slot < 0 || slot >= s.votes.length) return s;
      return s.copyWith(votes: [for (var i = 0; i < s.votes.length; i++) i == slot ? side : s.votes[i]]);
    case FinishVoting():
      if (s.status != DreamTeamStatus.voting || s.votes.any((v) => v == null)) return s;
      return s.copyWith(status: DreamTeamStatus.finished);
  }
}

@immutable
class DreamTeamVerdict {
  const DreamTeamVerdict(this.scores);

  /// Points per side.
  final List<int> scores;

  /// The winning side, or null for a tie.
  int? get winner => scores[0] == scores[1] ? null : (scores[0] > scores[1] ? 0 : 1);

  Map<String, Object?> toJson() => {'scores': scores, 'winner': winner};
}

@immutable
class DreamTeamResults {
  const DreamTeamResults({required this.room, required this.stats, required this.slotStats});

  /// Role slots each side won in the room's vote.
  final DreamTeamVerdict room;

  /// Sum of each card's stat for its role; null when any card has no stats (custom decks).
  final DreamTeamVerdict? stats;

  /// Per slot: each side's stat for that role (null without stats).
  final List<List<int>?> slotStats;

  Map<String, Object?> toJson() => {'room': room.toJson(), 'stats': stats?.toJson(), 'slotStats': slotStats};
}

DreamTeamResults dreamTeamResults(DreamTeamState s, Map<String, DreamTeamCard> cards) {
  final room = [0, 0];
  for (final v in s.votes) {
    if (v != null) room[v] += 1;
  }
  final slotStats = <List<int>?>[
    for (var i = 0; i < s.config.roles.length; i++)
      () {
        final stat = s.config.roles[i].stat;
        final a = cards[s.teams[0][i]]?.stats?[stat];
        final b = cards[s.teams[1][i]]?.stats?[stat];
        return a != null && b != null ? [a, b] : null;
      }(),
  ];
  final stats = slotStats.every((p) => p != null)
      ? DreamTeamVerdict([slotStats.fold(0, (t, p) => t + p![0]), slotStats.fold(0, (t, p) => t + p![1])])
      : null;
  return DreamTeamResults(room: DreamTeamVerdict(room), stats: stats, slotStats: slotStats);
}
