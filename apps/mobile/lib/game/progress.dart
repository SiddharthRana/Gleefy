// Player progress: XP, levels, a daily streak and trophies, earned by finishing games. Stored only on
// the phone. Port of packages/game-engine/src/progress.ts; tests replay test-vectors/progress.json.

const progressModes = ['would-you-rather', 'this-or-that', 'trivia', 'guess'];

class Progress {
  const Progress({
    this.xp = 0,
    this.gamesPlayed = 0,
    this.modesPlayed = const [],
    this.streak = 0,
    this.bestStreak = 0,
    this.lastPlayedDay,
    this.trophies = const [],
  });

  /// Reads stored progress defensively: anything missing or malformed falls back to empty.
  factory Progress.fromJson(Object? value) {
    if (value is! Map) return const Progress();
    int number(Object? x) => x is num && x.isFinite && x >= 0 ? x.toInt() : 0;
    List<String> strings(Object? x) => x is List ? x.whereType<String>().toList() : const [];
    final day = value['lastPlayedDay'];
    return Progress(
      xp: number(value['xp']),
      gamesPlayed: number(value['gamesPlayed']),
      modesPlayed: strings(value['modesPlayed']).where(progressModes.contains).toList(),
      streak: number(value['streak']),
      bestStreak: number(value['bestStreak']),
      lastPlayedDay: day is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day) ? day : null,
      trophies: strings(value['trophies']).where((t) => allTrophies.any((x) => x.id == t)).toList(),
    );
  }

  final int xp;
  final int gamesPlayed;

  /// Modes finished at least once, in the order they were first finished.
  final List<String> modesPlayed;

  /// Days in a row (up to [lastPlayedDay]) with at least one finished game.
  final int streak;
  final int bestStreak;

  /// Local calendar day of the last finished game, YYYY-MM-DD.
  final String? lastPlayedDay;

  /// Trophy ids, in the order they were earned.
  final List<String> trophies;

  int get level => levelFor(xp);

  Map<String, Object?> toJson() => {
    'xp': xp,
    'gamesPlayed': gamesPlayed,
    'modesPlayed': modesPlayed,
    'streak': streak,
    'bestStreak': bestStreak,
    'lastPlayedDay': lastPlayedDay,
    'trophies': trophies,
  };
}

class FinishedGame {
  const FinishedGame({required this.mode, required this.rounds, required this.day, this.perfect});

  /// A progress mode id, e.g. 'trivia'.
  final String mode;

  /// Rounds actually played.
  final int rounds;

  /// Local calendar day the game finished, YYYY-MM-DD.
  final String day;

  /// Trivia only: every question was answered correctly.
  final bool? perfect;
}

abstract final class XpRules {
  static const perGame = 10;
  static const perRound = 2;

  /// Rounds beyond this earn no extra XP, so a 100-round marathon can't farm levels.
  static const maxRounds = 30;
  static const firstGameOfDay = 5;
  static const perfectTrivia = 15;
}

/// Total XP needed to reach a level: 0, 50, 150, 300, 500, … (25 × L × (L − 1)).
int xpForLevel(int level) => 25 * level * (level - 1);

int levelFor(int xp) {
  var level = 1;
  while (xpForLevel(level + 1) <= xp) {
    level++;
  }
  return level;
}

/// Progress through the current level, for the XP bar.
({int level, int into, int needed}) levelProgress(int xp) {
  final level = levelFor(xp);
  final start = xpForLevel(level);
  return (level: level, into: xp - start, needed: xpForLevel(level + 1) - start);
}

class Trophy {
  const Trophy(this.id, this.earned);
  final String id;
  final bool Function(Progress after, FinishedGame game) earned;
}

/// Trophy ids and rules. Names and descriptions live in the app's copy.
final allTrophies = <Trophy>[
  Trophy('first-game', (p, _) => p.gamesPlayed >= 1),
  Trophy('regular', (p, _) => p.gamesPlayed >= 5),
  Trophy('party-animal', (p, _) => p.gamesPlayed >= 25),
  Trophy('all-modes', (p, _) => progressModes.every(p.modesPlayed.contains)),
  Trophy('streak-3', (p, _) => p.streak >= 3),
  Trophy('streak-7', (p, _) => p.streak >= 7),
  Trophy('marathon', (_, g) => g.rounds >= 20),
  Trophy('know-it-all', (_, g) => g.mode == 'trivia' && g.perfect == true),
  Trophy('rising-star', (p, _) => levelFor(p.xp) >= 5),
];

/// Whole days from one YYYY-MM-DD to another.
int daysBetween(String from, String to) =>
    DateTime.parse('${to}T00:00:00Z').difference(DateTime.parse('${from}T00:00:00Z')).inHours ~/ 24;

/// A time's local calendar day as YYYY-MM-DD.
String localDay(DateTime d) {
  final l = d.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${l.year}-${two(l.month)}-${two(l.day)}';
}

/// The streak to show today: it lapses once a whole day passes without a game.
int currentStreak(Progress p, String today) {
  final last = p.lastPlayedDay;
  if (last == null) return 0;
  return daysBetween(last, today) <= 1 ? p.streak : 0;
}

class GameReward {
  const GameReward({
    required this.progress,
    required this.xpGained,
    required this.levelBefore,
    required this.levelAfter,
    required this.newTrophies,
  });

  final Progress progress;
  final int xpGained;
  final int levelBefore;
  final int levelAfter;

  /// Trophy ids earned by this game.
  final List<String> newTrophies;

  bool get leveledUp => levelAfter > levelBefore;
}

/// Records a finished game: XP, streak, modes and any trophies it earns.
GameReward recordGame(Progress before, FinishedGame game) {
  final last = before.lastPlayedDay;
  final gap = last == null ? null : daysBetween(last, game.day);
  final firstToday = gap == null || gap > 0;
  // A clock moved backwards (gap < 0) keeps the streak as it was.
  final streak = gap == null || gap > 1
      ? 1
      : gap == 1
      ? before.streak + 1
      : before.streak;
  final rounds = game.rounds.clamp(0, XpRules.maxRounds);
  final xpGained =
      XpRules.perGame +
      XpRules.perRound * rounds +
      (firstToday ? XpRules.firstGameOfDay : 0) +
      (game.mode == 'trivia' && game.perfect == true ? XpRules.perfectTrivia : 0);
  var after = Progress(
    xp: before.xp + xpGained,
    gamesPlayed: before.gamesPlayed + 1,
    modesPlayed: before.modesPlayed.contains(game.mode) ? before.modesPlayed : [...before.modesPlayed, game.mode],
    streak: streak,
    bestStreak: streak > before.bestStreak ? streak : before.bestStreak,
    lastPlayedDay: gap != null && gap < 0 ? before.lastPlayedDay : game.day,
    trophies: before.trophies,
  );
  final newTrophies = [
    for (final t in allTrophies)
      if (!before.trophies.contains(t.id) && t.earned(after, game)) t.id,
  ];
  after = Progress(
    xp: after.xp,
    gamesPlayed: after.gamesPlayed,
    modesPlayed: after.modesPlayed,
    streak: after.streak,
    bestStreak: after.bestStreak,
    lastPlayedDay: after.lastPlayedDay,
    trophies: [...before.trophies, ...newTrophies],
  );
  return GameReward(
    progress: after,
    xpGained: xpGained,
    levelBefore: levelFor(before.xp),
    levelAfter: levelFor(after.xp),
    newTrophies: newTrophies,
  );
}
