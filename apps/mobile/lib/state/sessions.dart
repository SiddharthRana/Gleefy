import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/content.dart';
import '../game/guess_engine.dart';
import '../game/random.dart';
import '../game/trivia_engine.dart';
import '../game/wyr_engine.dart';
import '../telemetry/analytics.dart';
import 'providers.dart';

/// A game session persisted on every change, so it survives navigation, backgrounding and the
/// process being killed. The player/team names used for the game are stored alongside it.
abstract class PersistedSession<S> extends Notifier<S?> {
  String get storageKey;
  GameMode get mode;
  S decode(Map<String, dynamic> json);
  Map<String, Object?> encode(S state);

  /// Every question id the session can deal, to drop sessions whose content has since changed.
  List<String> questionIds(S state);
  bool isPlaying(S state);
  int roundNumber(S state);
  int totalRounds(S state);

  @override
  S? build() {
    final raw = ref.read(sharedPreferencesProvider).getString(storageKey);
    if (raw == null) return null;
    try {
      final restored = decode(jsonDecode(raw) as Map<String, dynamic>);
      final pack = ref.read(contentProvider).packFor(mode);
      if (questionIds(restored).any((id) => pack.item(id) == null)) return _discard();
      return restored;
    } on Object catch (e) {
      debugPrint('Discarding unreadable saved $storageKey: $e');
      return _discard();
    }
  }

  S? _discard() {
    clear();
    return null;
  }

  /// Names of the players or teams in this session (empty for an anonymous group).
  List<String> get names => ref.read(sharedPreferencesProvider).getStringList('$storageKey.names') ?? const [];

  @protected
  void begin(S session, List<String> names) {
    ref.read(sharedPreferencesProvider).setStringList('$storageKey.names', names);
    put(session);
  }

  @protected
  void put(S next) {
    final previous = state;
    if (previous != null && isPlaying(previous) && !isPlaying(next)) {
      ref.read(analyticsProvider).track('game_completed', {'mode': mode.id, 'rounds': totalRounds(next)});
    }
    state = next;
    ref.read(sharedPreferencesProvider).setString(storageKey, jsonEncode(encode(next)));
  }

  void clear() {
    state = null;
    final p = ref.read(sharedPreferencesProvider);
    p.remove(storageKey);
    p.remove('$storageKey.names');
  }

  /// Free categories always; premium only with a (server-verified, Phase 4) entitlement.
  @protected
  List<String> playable(List<String> categoryIds) {
    final pack = ref.read(contentProvider).packFor(mode);
    final premium = ref.read(premiumProvider);
    return categoryIds.where((id) {
      final c = pack.category(id);
      return c != null && (c.tier == Tier.free || premium);
    }).toList();
  }
}

/// Would You Rather and This or That share the two-choice engine.
class ChoiceSessionController extends PersistedSession<WyrState> {
  ChoiceSessionController(this.mode);

  @override
  final GameMode mode;

  @override
  String get storageKey => mode == GameMode.wouldYouRather ? 'session.wyr' : 'session.tot';
  @override
  WyrState decode(Map<String, dynamic> json) => WyrState.fromJson(json);
  @override
  Map<String, Object?> encode(WyrState s) => s.toJson();
  @override
  List<String> questionIds(WyrState s) => s.order;
  @override
  bool isPlaying(WyrState s) => s.status == WyrStatus.playing;
  @override
  int roundNumber(WyrState s) => s.roundNumber;
  @override
  int totalRounds(WyrState s) => s.totalRounds;

  /// Starts a new session. Throws [EmptyPoolException] when the categories have no questions.
  void start(WyrConfig config, {List<String> names = const []}) {
    final pack = ref.read(contentProvider).packFor(mode) as Pack<WyrItem>;
    begin(createWyrSession(buildPool(pack.items, playable(config.categoryIds)), config), names);
  }

  /// Same settings and players, fresh shuffle.
  void restart() {
    final s = state;
    if (s != null) start(s.config.withSeed(newSeed()), names: names);
  }

  void dispatch(WyrAction action) {
    final s = state;
    if (s == null) return;
    final next = reduceWyr(s, action);
    if (!identical(next, s)) put(next);
  }
}

final wyrSessionProvider = NotifierProvider<ChoiceSessionController, WyrState?>(
  () => ChoiceSessionController(GameMode.wouldYouRather),
);
final totSessionProvider = NotifierProvider<ChoiceSessionController, WyrState?>(
  () => ChoiceSessionController(GameMode.thisOrThat),
);

class TriviaSessionController extends PersistedSession<TriviaState> {
  @override
  GameMode get mode => GameMode.trivia;
  @override
  String get storageKey => 'session.trivia';
  @override
  TriviaState decode(Map<String, dynamic> json) => TriviaState.fromJson(json);
  @override
  Map<String, Object?> encode(TriviaState s) => s.toJson();
  @override
  List<String> questionIds(TriviaState s) => s.order;
  @override
  bool isPlaying(TriviaState s) => s.status == SessionStatus.playing;
  @override
  int roundNumber(TriviaState s) => s.roundNumber;
  @override
  int totalRounds(TriviaState s) => s.totalRounds;

  void start(TriviaConfig config, {List<String> names = const []}) {
    final pack = ref.read(contentProvider).trivia;
    begin(createTriviaSession(buildPool(pack.items, playable(config.categoryIds)), config), names);
  }

  void restart() {
    final s = state;
    if (s != null) start(s.config.withSeed(newSeed()), names: names);
  }

  void dispatch(TriviaAction action) {
    final s = state;
    if (s == null) return;
    final next = reduceTrivia(s, action);
    if (!identical(next, s)) put(next);
  }
}

final triviaSessionProvider = NotifierProvider<TriviaSessionController, TriviaState?>(TriviaSessionController.new);

class GuessSessionController extends PersistedSession<GuessState> {
  @override
  GameMode get mode => GameMode.guess;
  @override
  String get storageKey => 'session.guess';
  @override
  GuessState decode(Map<String, dynamic> json) => GuessState.fromJson(json);
  @override
  Map<String, Object?> encode(GuessState s) => s.toJson();
  @override
  List<String> questionIds(GuessState s) => s.order;
  @override
  bool isPlaying(GuessState s) => s.status == SessionStatus.playing;
  @override
  int roundNumber(GuessState s) => s.roundNumber;
  @override
  int totalRounds(GuessState s) => s.totalRounds;

  void start(GuessConfig config, {List<String> names = const []}) {
    final pack = ref.read(contentProvider).guess;
    begin(createGuessSession(buildPool(pack.items, playable(config.categoryIds)), config), names);
  }

  void restart() {
    final s = state;
    if (s != null) start(s.config.withSeed(newSeed()), names: names);
  }

  void dispatch(GuessAction action) {
    final s = state;
    if (s == null) return;
    final next = reduceGuess(s, action);
    if (!identical(next, s)) put(next);
  }
}

final guessSessionProvider = NotifierProvider<GuessSessionController, GuessState?>(GuessSessionController.new);
