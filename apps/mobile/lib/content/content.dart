import 'dart:convert';

import 'package:flutter/services.dart';

import 'dream_team_content.dart';

/// Mirrors packages/content/src/schema.ts. The packs are validated there in CI; the app
/// re-checks the essentials so a damaged asset becomes an error screen, not a crash.
enum Tier { free, premium }

enum AgeRating { all, teen }

enum GameMode {
  wouldYouRather('would-you-rather'),
  thisOrThat('this-or-that'),
  trivia('trivia'),
  guess('guess');

  const GameMode(this.id);

  /// Pack `mode` value and URL segment.
  final String id;

  static GameMode? fromId(String id) => values.where((m) => m.id == id).firstOrNull;
}

class Category {
  const Category({
    required this.id,
    required this.name,
    required this.description,
    required this.tier,
    required this.ageRating,
    required this.region,
    this.contentNote,
  });

  final String id;
  final String name;
  final String description;
  final Tier tier;
  final AgeRating ageRating;
  final String region;
  final String? contentNote;

  factory Category.fromJson(Map<String, dynamic> j) => Category(
    id: j['id'] as String,
    name: j['name'] as String,
    description: j['description'] as String,
    tier: Tier.values.byName(j['tier'] as String),
    ageRating: j['ageRating'] == '13+' ? AgeRating.teen : AgeRating.all,
    region: j['region'] as String,
    contentNote: j['contentNote'] as String?,
  );
}

/// Anything dealt from a pack: only the id and category matter to the engines.
abstract interface class PoolItem {
  String get id;
  String get category;
}

/// Two options: used by Would You Rather and This or That.
class WyrItem implements PoolItem {
  const WyrItem({required this.id, required this.category, required this.a, required this.b});

  @override
  final String id;
  @override
  final String category;
  final String a;
  final String b;

  factory WyrItem.fromJson(Map<String, dynamic> j) {
    final item = WyrItem(
      id: j['id'] as String,
      category: j['category'] as String,
      a: j['a'] as String,
      b: j['b'] as String,
    );
    if (item.a.trim().isEmpty || item.b.trim().isEmpty) throw FormatException('${item.id}: empty option');
    return item;
  }
}

class TriviaItem implements PoolItem {
  const TriviaItem({
    required this.id,
    required this.category,
    required this.question,
    required this.choices,
    required this.answer,
    required this.explanation,
    this.reviewStatus = 'verified',
  });

  @override
  final String id;
  @override
  final String category;
  final String question;
  final List<String> choices;
  final int answer;
  final String explanation;
  final String reviewStatus;

  factory TriviaItem.fromJson(Map<String, dynamic> j) {
    final item = TriviaItem(
      id: j['id'] as String,
      category: j['category'] as String,
      question: j['question'] as String,
      choices: (j['choices'] as List<dynamic>).cast<String>(),
      answer: j['answer'] as int,
      explanation: j['explanation'] as String,
      reviewStatus: j['reviewStatus'] as String,
    );
    if (item.choices.length != 4 || item.answer < 0 || item.answer > 3) {
      throw FormatException('${item.id}: needs 4 choices and a valid answer');
    }
    return item;
  }
}

class GuessItem implements PoolItem {
  const GuessItem({required this.id, required this.category, required this.answer, required this.clues});

  @override
  final String id;
  @override
  final String category;
  final String answer;
  final List<String> clues;

  factory GuessItem.fromJson(Map<String, dynamic> j) {
    final item = GuessItem(
      id: j['id'] as String,
      category: j['category'] as String,
      answer: j['answer'] as String,
      clues: (j['clues'] as List<dynamic>).cast<String>(),
    );
    if (item.clues.length != 3) throw FormatException('${item.id}: needs 3 clues');
    return item;
  }
}

class Pack<T extends PoolItem> {
  Pack({required this.categories, required this.items}) : _byId = {for (final i in items) i.id: i};

  final List<Category> categories;
  final List<T> items;
  final Map<String, T> _byId;

  T? item(String id) => _byId[id];
  Category? category(String id) => categories.where((c) => c.id == id).firstOrNull;
  int countIn(Iterable<String> categoryIds) {
    final wanted = categoryIds.toSet();
    return items.where((i) => wanted.contains(i.category)).length;
  }

  /// Parses and checks a pack. Throws [FormatException] on anything the game can't use.
  /// [keep] drops items that must not ship (e.g. draft trivia).
  static Pack<T> parse<T extends PoolItem>(
    String source,
    GameMode mode,
    T Function(Map<String, dynamic>) itemFromJson, {
    bool Function(T)? keep,
  }) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException catch (e) {
      throw FormatException('Invalid JSON: ${e.message}');
    }
    if (json is! Map<String, dynamic> || json['mode'] != mode.id) {
      throw FormatException('Not a ${mode.id} pack');
    }
    try {
      final categories = (json['categories'] as List<dynamic>)
          .map((c) => Category.fromJson(c as Map<String, dynamic>))
          .toList();
      final items = (json['items'] as List<dynamic>)
          .map((i) => itemFromJson(i as Map<String, dynamic>))
          .where(keep ?? (_) => true)
          .toList();
      final ids = categories.map((c) => c.id).toSet();
      final seen = <String>{};
      for (final i in items) {
        if (!ids.contains(i.category)) throw FormatException('${i.id}: unknown category ${i.category}');
        if (!seen.add(i.id)) throw FormatException('duplicate id ${i.id}');
      }
      if (categories.isEmpty || items.isEmpty) throw const FormatException('Pack is empty');
      // A category left empty (e.g. all drafts) isn't offered.
      categories.removeWhere((c) => !items.any((i) => i.category == c.id));
      return Pack<T>(categories: categories, items: items);
    } on TypeError catch (e) {
      throw FormatException('Malformed pack: $e');
    } on ArgumentError catch (e) {
      throw FormatException('Malformed pack: ${e.message}');
    }
  }
}

typedef WyrPack = Pack<WyrItem>;
typedef TotPack = Pack<WyrItem>;
typedef TriviaPack = Pack<TriviaItem>;
typedef GuessPack = Pack<GuessItem>;

WyrPack parseWyrPack(String s) => Pack.parse(s, GameMode.wouldYouRather, WyrItem.fromJson);
TotPack parseTotPack(String s) => Pack.parse(s, GameMode.thisOrThat, WyrItem.fromJson);
TriviaPack parseTriviaPack(String s) =>
    Pack.parse(s, GameMode.trivia, TriviaItem.fromJson, keep: (i) => i.reviewStatus != 'draft');
GuessPack parseGuessPack(String s) => Pack.parse(s, GameMode.guess, GuessItem.fromJson);

/// Everything the app can play. Loaded once at startup.
class ContentLibrary {
  const ContentLibrary({
    required this.wyr,
    required this.tot,
    required this.trivia,
    required this.guess,
    this.dreamTeam = DreamTeamPack.empty,
  });

  final WyrPack wyr;
  final TotPack tot;
  final TriviaPack trivia;
  final GuessPack guess;

  /// Dream Team decks and role sets (its own pack shape; not one of the [GameMode]s).
  final DreamTeamPack dreamTeam;

  Pack<PoolItem> packFor(GameMode mode) => switch (mode) {
    GameMode.wouldYouRather => wyr,
    GameMode.thisOrThat => tot,
    GameMode.trivia => trivia,
    GameMode.guess => guess,
  };

  static Future<ContentLibrary> load(AssetBundle bundle) async {
    Future<String> read(GameMode m) => bundle.loadString('assets/content/${m.id}.json');
    return ContentLibrary(
      wyr: parseWyrPack(await read(GameMode.wouldYouRather)),
      tot: parseTotPack(await read(GameMode.thisOrThat)),
      trivia: parseTriviaPack(await read(GameMode.trivia)),
      guess: parseGuessPack(await read(GameMode.guess)),
      dreamTeam: DreamTeamPack.parse(await bundle.loadString('assets/content/dream-team.json')),
    );
  }
}
