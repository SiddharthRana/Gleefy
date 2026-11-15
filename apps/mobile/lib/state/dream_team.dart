import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/profanity.dart';
import '../game/dream_team_engine.dart';
import '../game/random.dart';
import 'card_photos.dart';
import 'progress.dart';
import 'providers.dart';

/// Dream Team progress id (packages/game-engine/src/progress.ts).
const dreamTeamMode = 'dream-team';

/// Skips each side gets per game.
const dreamTeamSkips = 1;

// ---------------------------------------------------------------------------------------------
// Custom decks (Premium): names people type themselves, e.g. their favourite anime characters.
// Stored only on this phone, never uploaded or put in share links.

/// Most names a custom deck can hold, and the longest name (same as a pack card name).
const customDeckMax = 60;
const customNameMax = 40;
const customDeckTitleMax = 30;

@immutable
class CustomDeck {
  const CustomDeck({required this.id, required this.name, required this.cards, this.photos = const {}});

  final String id;
  final String name;
  final List<String> cards;

  /// Photo file names (in the card photos folder), keyed by [photoKey] of the card's name.
  final Map<String, String> photos;

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'cards': cards, 'photos': photos};

  factory CustomDeck.fromJson(Map<String, dynamic> j) => CustomDeck(
    id: j['id'] as String,
    name: j['name'] as String,
    cards: (j['cards'] as List<dynamic>).cast<String>(),
    photos: (j['photos'] as Map<String, dynamic>?)?.cast<String, String>() ?? const {},
  );

  /// Cards for the engine: no stats, so the room's vote decides. [photosDir] adds their photos.
  List<DreamTeamCard> toCards([String? photosDir]) => [
    for (var i = 0; i < cards.length; i++)
      DreamTeamCard(id: '$id-$i', name: cards[i], photo: cardPhotoPath(photosDir, photos[photoKey(cards[i])])),
  ];
}

/// Photos follow a card's name, so editing the list keeps them on the right cards.
String photoKey(String name) => name.trim().toLowerCase();

enum DeckProblem { noTitle, titleTooLong, tooFew, tooMany, nameTooLong, notAllowed }

String _clean(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

/// One name per line, tidied, blank lines and repeats dropped.
List<String> parseDeckNames(String text) {
  final seen = <String>{};
  return [
    for (final line in text.split('\n'))
      if (_clean(line).isNotEmpty && seen.add(_clean(line).toLowerCase())) _clean(line),
  ];
}

/// Checks a deck before saving. [minCards] is what the biggest role set needs.
DeckProblem? checkDeck(String title, List<String> names, {required int minCards}) {
  final t = _clean(title);
  if (t.isEmpty) return DeckProblem.noTitle;
  if (t.length > customDeckTitleMax) return DeckProblem.titleTooLong;
  if (names.length < minCards) return DeckProblem.tooFew;
  if (names.length > customDeckMax) return DeckProblem.tooMany;
  if (names.any((n) => n.length > customNameMax)) return DeckProblem.nameTooLong;
  if (containsProfanity(t) || names.any(containsProfanity)) return DeckProblem.notAllowed;
  return null;
}

class CustomDecksController extends Notifier<List<CustomDeck>> {
  static const storageKey = 'dreamteam.decks.v1';
  final _random = Random();

  @override
  List<CustomDeck> build() {
    final raw = ref.read(sharedPreferencesProvider).getString(storageKey);
    if (raw == null) return const [];
    try {
      return [for (final d in jsonDecode(raw) as List<dynamic>) CustomDeck.fromJson(d as Map<String, dynamic>)];
    } on Object {
      return const [];
    }
  }

  void _save(List<CustomDeck> decks) {
    state = decks;
    ref.read(sharedPreferencesProvider).setString(storageKey, jsonEncode([for (final d in decks) d.toJson()]));
  }

  /// Adds or replaces a deck (by id) and returns its id. Photos for cards no longer in the deck
  /// are dropped, and files nothing uses any more are deleted.
  String save({String? id, required String name, required List<String> cards, Map<String, String> photos = const {}}) {
    final deckId = id ?? 'mine-${_random.nextInt(1 << 31).toRadixString(36)}';
    final keys = cards.map(photoKey).toSet();
    final kept = {
      for (final e in photos.entries)
        if (keys.contains(e.key)) e.key: e.value,
    };
    final before = state.where((d) => d.id == deckId).firstOrNull;
    if (before != null) {
      deleteCardPhotos(ref.read(cardPhotosDirProvider), before.photos.values.where((f) => !kept.containsValue(f)));
    }
    final deck = CustomDeck(id: deckId, name: _clean(name), cards: cards, photos: kept);
    _save(before != null ? [for (final d in state) d.id == deckId ? deck : d] : [...state, deck]);
    return deckId;
  }

  void remove(String id) {
    final deck = state.where((d) => d.id == id).firstOrNull;
    if (deck != null) deleteCardPhotos(ref.read(cardPhotosDirProvider), deck.photos.values);
    _save([
      for (final d in state)
        if (d.id != id) d,
    ]);
  }
}

final customDecksProvider = NotifierProvider<CustomDecksController, List<CustomDeck>>(CustomDecksController.new);

// ---------------------------------------------------------------------------------------------
// The game in progress. Saved so it survives a phone call or the app closing.

@immutable
class DreamTeamGame {
  const DreamTeamGame({
    required this.deckId,
    required this.deckName,
    required this.roleSetName,
    required this.sides,
    required this.cards,
    required this.state,
  });

  final String deckId;
  final String deckName;
  final String roleSetName;

  /// The two players' or teams' names.
  final List<String> sides;

  /// Every card in the deck, kept with the game so a custom deck can change without breaking it.
  final List<DreamTeamCard> cards;
  final DreamTeamState state;

  Map<String, DreamTeamCard> get cardsById => {for (final c in cards) c.id: c};
  DreamTeamCard? card(String? id) => id == null ? null : cardsById[id];

  /// Cards placed so far, for the progress bar and XP.
  int get placed => state.teams.fold(0, (t, team) => t + team.where((c) => c != null).length);
  int get slots => state.config.roles.length * 2;

  DreamTeamGame withState(DreamTeamState s) =>
      DreamTeamGame(deckId: deckId, deckName: deckName, roleSetName: roleSetName, sides: sides, cards: cards, state: s);

  Map<String, Object?> toJson() => {
    'deckId': deckId,
    'deckName': deckName,
    'roleSetName': roleSetName,
    'sides': sides,
    'cards': [
      for (final c in cards) {'id': c.id, 'name': c.name, 'blurb': c.blurb, 'stats': c.stats, 'photo': c.photo},
    ],
    'config': state.config.toJson(),
    'state': state.toJson(),
  };

  factory DreamTeamGame.fromJson(Map<String, dynamic> j) {
    final config = DreamTeamConfig.fromJson(j['config'] as Map<String, dynamic>);
    return DreamTeamGame(
      deckId: j['deckId'] as String,
      deckName: j['deckName'] as String,
      roleSetName: j['roleSetName'] as String,
      sides: (j['sides'] as List<dynamic>).cast<String>(),
      cards: [
        for (final c in j['cards'] as List<dynamic>)
          DreamTeamCard(
            id: (c as Map<String, dynamic>)['id'] as String,
            name: c['name'] as String,
            blurb: c['blurb'] as String?,
            stats: (c['stats'] as Map<String, dynamic>?)?.cast<String, int>(),
            photo: c['photo'] as String?,
          ),
      ],
      state: DreamTeamState.fromJson(j['state'] as Map<String, dynamic>, config),
    );
  }
}

class DreamTeamController extends Notifier<DreamTeamGame?> {
  static const storageKey = 'dreamteam.session.v1';

  @override
  DreamTeamGame? build() {
    final raw = ref.read(sharedPreferencesProvider).getString(storageKey);
    if (raw == null) return null;
    try {
      return DreamTeamGame.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object {
      return null;
    }
  }

  void _set(DreamTeamGame? game) {
    state = game;
    final prefs = ref.read(sharedPreferencesProvider);
    if (game == null) {
      prefs.remove(storageKey);
    } else {
      prefs.setString(storageKey, jsonEncode(game.toJson()));
    }
  }

  /// Starts a game. Throws [DeckTooSmallException] if the deck can't fill both teams.
  void start({
    required String deckId,
    required String deckName,
    required String roleSetName,
    required List<DreamTeamRole> roles,
    required List<String> sides,
    required List<DreamTeamCard> cards,
    int? seed,
  }) {
    final config = DreamTeamConfig(roles: roles, seed: seed ?? newSeed(), skips: dreamTeamSkips);
    _set(
      DreamTeamGame(
        deckId: deckId,
        deckName: deckName,
        roleSetName: roleSetName,
        sides: sides,
        cards: cards,
        state: createDreamTeam([for (final c in cards) c.id], config),
      ),
    );
  }

  void dispatch(DreamTeamAction action) {
    final game = state;
    if (game == null) return;
    final next = reduceDreamTeam(game.state, action);
    if (identical(next, game.state)) return;
    if (next.status == DreamTeamStatus.finished && game.state.status != DreamTeamStatus.finished) {
      ref.read(progressProvider.notifier).record(mode: dreamTeamMode, rounds: game.slots);
    }
    _set(game.withState(next));
  }

  /// Same deck, roles and names; a fresh shuffle.
  void restart() {
    final g = state;
    if (g == null) return;
    start(
      deckId: g.deckId,
      deckName: g.deckName,
      roleSetName: g.roleSetName,
      roles: g.state.config.roles,
      sides: g.sides,
      cards: g.cards,
    );
  }

  void clear() => _set(null);
}

final dreamTeamProvider = NotifierProvider<DreamTeamController, DreamTeamGame?>(DreamTeamController.new);
