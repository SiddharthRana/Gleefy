import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/content.dart';
import '../game/guess_engine.dart';
import '../game/random.dart';
import '../game/trivia_engine.dart';
import '../game/wyr_engine.dart';
import '../telemetry/analytics.dart';
import 'custom_questions.dart';
import 'providers.dart';
import 'sessions.dart';

const maxNames = 12;

/// Everything needed to start a game, without the seed. Used for favourites, recent games and
/// custom party packs.
@immutable
class GameSetup {
  const GameSetup({
    required this.mode,
    required this.categoryIds,
    required this.rounds,
    this.playerCount,
    this.timer = false,
    this.passThePhone = false,
    this.timeLimitMs = 20000,
  });

  final GameMode mode;
  final List<String> categoryIds;
  final int rounds;

  /// Would You Rather: cap on votes per round.
  final int? playerCount;

  /// This or That: 5-second timer per pair.
  final bool timer;

  /// This or That: each named player picks in turn.
  final bool passThePhone;

  /// Trivia: per-question limit, 0 for no timer.
  final int timeLimitMs;

  Map<String, Object?> toJson() => {
    'mode': mode.id,
    'categoryIds': categoryIds,
    'rounds': rounds,
    if (playerCount != null) 'playerCount': playerCount,
    'timer': timer,
    'passThePhone': passThePhone,
    'timeLimitMs': timeLimitMs,
  };

  factory GameSetup.fromJson(Map<String, dynamic> j) => GameSetup(
    mode: GameMode.fromId(j['mode'] as String) ?? (throw FormatException('unknown mode ${j['mode']}')),
    categoryIds: (j['categoryIds'] as List<dynamic>).cast<String>(),
    rounds: j['rounds'] as int,
    playerCount: j['playerCount'] as int?,
    timer: j['timer'] as bool? ?? false,
    passThePhone: j['passThePhone'] as bool? ?? false,
    timeLimitMs: j['timeLimitMs'] as int? ?? 20000,
  );

  /// The default setup for a mode: every free category, 10 rounds.
  static GameSetup defaults(GameMode mode, ContentLibrary content) => GameSetup(
    mode: mode,
    categoryIds: content.packFor(mode).categories.where((c) => c.tier == Tier.free).map((c) => c.id).toList(),
    rounds: 10,
  );
}

/// Play routes per mode.
String playRoute(GameMode mode) => '/play/${mode.id}';
String resultsRoute(GameMode mode) => '/play/${mode.id}/results';
String setupRoute(GameMode mode) => '/play/${mode.id}/setup';

/// The players or teams the group last entered. Stored only on this phone.
class LineupController extends Notifier<List<String>> {
  static const _key = 'lineup.names';

  @override
  List<String> build() => ref.read(sharedPreferencesProvider).getStringList(_key) ?? const [];

  void set(List<String> names) {
    final clean = [
      for (final n in names)
        if (n.trim().isNotEmpty) n.trim().substring(0, n.trim().length.clamp(0, 24)),
    ].take(maxNames).toList();
    state = clean;
    ref.read(sharedPreferencesProvider).setStringList(_key, clean);
  }
}

final lineupProvider = NotifierProvider<LineupController, List<String>>(LineupController.new);

/// Starts games from setups. Reached through [gameStarterProvider] so widgets and notifiers can
/// both use it.
class GameStarter {
  GameStarter(this.ref);

  final Ref ref;

  /// Starts a game and returns the route to open. Throws [EmptyPoolException] when the chosen
  /// categories have no playable questions.
  String start(GameSetup setup, {int? seed}) {
    final gameSeed = seed ?? newSeed();
    final names = ref.read(lineupProvider);
    final teams = names.isEmpty ? 1 : names.length;
    switch (setup.mode) {
      case GameMode.wouldYouRather:
        ref
            .read(wyrSessionProvider.notifier)
            .start(
              WyrConfig(
                categoryIds: setup.categoryIds,
                rounds: setup.rounds,
                seed: gameSeed,
                playerCount: setup.playerCount,
              ),
            );
      case GameMode.thisOrThat:
        final pass = setup.passThePhone && names.length >= 2;
        ref
            .read(totSessionProvider.notifier)
            .start(
              WyrConfig(
                categoryIds: setup.categoryIds,
                rounds: setup.rounds,
                seed: gameSeed,
                playerCount: pass ? names.length : null,
              ),
              names: pass ? names : const [],
            );
        ref.read(sharedPreferencesProvider).setBool('session.tot.timer', setup.timer);
      case GameMode.trivia:
        ref
            .read(triviaSessionProvider.notifier)
            .start(
              TriviaConfig(
                categoryIds: setup.categoryIds,
                rounds: setup.rounds,
                seed: gameSeed,
                teams: teams,
                timeLimitMs: setup.timeLimitMs,
              ),
              names: names,
            );
      case GameMode.guess:
        ref
            .read(guessSessionProvider.notifier)
            .start(
              GuessConfig(categoryIds: setup.categoryIds, rounds: setup.rounds, seed: gameSeed, teams: teams),
              names: names,
            );
    }
    final pack = ref.read(contentProvider).packFor(setup.mode);
    ref.read(analyticsProvider).track('game_started', {
      'mode': setup.mode.id,
      'rounds': setup.rounds,
      'categories': setup.categoryIds.length,
      'premium_category': setup.categoryIds.any((id) => pack.category(id)?.tier == Tier.premium),
      'custom_questions': setup.categoryIds.contains(customCategoryId),
      'players': names.length,
      'timer': setup.timer,
      'pass_the_phone': setup.passThePhone,
    });
    ref.read(recentsProvider.notifier).add(SavedGame(name: '', setups: [setup]));
    ref.read(sharedPreferencesProvider).setString('setup.${setup.mode.id}', jsonEncode(setup.toJson()));
    return playRoute(setup.mode);
  }

  /// The setup last used for a mode, to prefill its setup screen.
  GameSetup? lastSetup(GameMode mode) {
    final raw = ref.read(sharedPreferencesProvider).getString('setup.${mode.id}');
    if (raw == null) return null;
    try {
      return GameSetup.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }
}

final gameStarterProvider = Provider<GameStarter>(GameStarter.new);

/// A named list of games: one game for a favourite, several for a custom party pack.
@immutable
class SavedGame {
  const SavedGame({required this.name, required this.setups});

  final String name;
  final List<GameSetup> setups;

  bool get isParty => setups.length > 1;

  Map<String, Object?> toJson() => {'name': name, 'setups': setups.map((s) => s.toJson()).toList()};

  factory SavedGame.fromJson(Map<String, dynamic> j) => SavedGame(
    name: j['name'] as String,
    setups: (j['setups'] as List<dynamic>).map((s) => GameSetup.fromJson(s as Map<String, dynamic>)).toList(),
  );

  String get _identity => jsonEncode(setups.map((s) => s.toJson()).toList());
}

abstract class _SavedList extends Notifier<List<SavedGame>> {
  String get key;
  int get limit;

  @override
  List<SavedGame> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List<dynamic>).map((g) => SavedGame.fromJson(g as Map<String, dynamic>)).toList();
    } on Object {
      return const [];
    }
  }

  void _save(List<SavedGame> next) {
    state = next.take(limit).toList();
    ref.read(sharedPreferencesProvider).setString(key, jsonEncode(state.map((g) => g.toJson()).toList()));
  }

  void remove(SavedGame game) => _save(state.where((g) => !identical(g, game)).toList());
}

/// Favourite games and party packs the group saved by name.
class FavouritesController extends _SavedList {
  @override
  String get key => 'favourites';
  @override
  int get limit => 20;

  void add(SavedGame game) => _save([game, ...state]);
}

final favouritesProvider = NotifierProvider<FavouritesController, List<SavedGame>>(FavouritesController.new);

/// The last few games started, newest first, without duplicates.
class RecentsController extends _SavedList {
  @override
  String get key => 'recents';
  @override
  int get limit => 5;

  void add(SavedGame game) => _save([game, ...state.where((g) => g._identity != game._identity)]);
}

final recentsProvider = NotifierProvider<RecentsController, List<SavedGame>>(RecentsController.new);

/// A custom party pack in progress: which game of the pack is being played.
@immutable
class PartyState {
  const PartyState({required this.setups, required this.index});

  final List<GameSetup> setups;
  final int index;

  bool get hasNext => index + 1 < setups.length;
  GameSetup? get next => hasNext ? setups[index + 1] : null;

  Map<String, Object?> toJson() => {'setups': setups.map((s) => s.toJson()).toList(), 'index': index};

  factory PartyState.fromJson(Map<String, dynamic> j) => PartyState(
    setups: (j['setups'] as List<dynamic>).map((s) => GameSetup.fromJson(s as Map<String, dynamic>)).toList(),
    index: j['index'] as int,
  );
}

class PartyController extends Notifier<PartyState?> {
  static const _key = 'party';

  @override
  PartyState? build() {
    final raw = ref.read(sharedPreferencesProvider).getString(_key);
    if (raw == null) return null;
    try {
      return PartyState.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  void _put(PartyState? next) {
    state = next;
    final p = ref.read(sharedPreferencesProvider);
    if (next == null) {
      p.remove(_key);
    } else {
      p.setString(_key, jsonEncode(next.toJson()));
    }
  }

  /// Starts the first game of the pack and returns its route.
  String start(List<GameSetup> setups) {
    final route = ref.read(gameStarterProvider).start(setups.first);
    _put(PartyState(setups: setups, index: 0));
    return route;
  }

  /// Starts the next game and returns its route, or null when the pack is finished.
  String? advance() {
    final s = state;
    if (s == null || !s.hasNext) {
      _put(null);
      return null;
    }
    final route = ref.read(gameStarterProvider).start(s.setups[s.index + 1]);
    _put(PartyState(setups: s.setups, index: s.index + 1));
    return route;
  }

  void stop() => _put(null);
}

final partyProvider = NotifierProvider<PartyController, PartyState?>(PartyController.new);
