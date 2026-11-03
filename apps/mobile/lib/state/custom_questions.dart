import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../content/content.dart';
import '../content/profanity.dart';
import 'providers.dart';

/// Questions people write themselves, for the two-choice games. Stored only on this phone and
/// never shared, uploaded or put in share links (BUILD_PROMPT §7).
const customCategoryId = 'mine';

/// Two-choice games that support custom questions, with their per-option length limits
/// (the same limits as packages/content/src/schema.ts).
const customLimits = {GameMode.wouldYouRather: 90, GameMode.thisOrThat: 40};

/// Most questions kept per game, so the list stays manageable.
const maxCustomQuestions = 200;

enum CustomProblem { empty, tooLong, same, duplicate, notAllowed, full }

@immutable
class CustomQuestions {
  const CustomQuestions({this.wyr = const [], this.tot = const []});

  final List<WyrItem> wyr;
  final List<WyrItem> tot;

  List<WyrItem> of(GameMode mode) => mode == GameMode.wouldYouRather ? wyr : tot;

  CustomQuestions copyWith(GameMode mode, List<WyrItem> items) =>
      mode == GameMode.wouldYouRather ? CustomQuestions(wyr: items, tot: tot) : CustomQuestions(wyr: wyr, tot: items);
}

String _clean(String s) => s.trim().replaceAll(RegExp(r'\s+'), ' ');

/// Checks a question before saving. [editingId] skips the question being edited in duplicate checks.
CustomProblem? checkCustom(GameMode mode, String a, String b, List<WyrItem> existing, {String? editingId}) {
  final ca = _clean(a), cb = _clean(b);
  if (ca.isEmpty || cb.isEmpty) return CustomProblem.empty;
  final max = customLimits[mode]!;
  if (ca.length > max || cb.length > max) return CustomProblem.tooLong;
  if (ca.toLowerCase() == cb.toLowerCase()) return CustomProblem.same;
  if (containsProfanity(ca) || containsProfanity(cb)) return CustomProblem.notAllowed;
  final key = {ca.toLowerCase(), cb.toLowerCase()};
  final others = existing.where((q) => q.id != editingId);
  if (others.any((q) => {q.a.toLowerCase(), q.b.toLowerCase()}.containsAll(key))) return CustomProblem.duplicate;
  if (editingId == null && existing.length >= maxCustomQuestions) return CustomProblem.full;
  return null;
}

class CustomQuestionsController extends Notifier<CustomQuestions> {
  static String _key(GameMode m) => 'custom.${m.id}';
  final _random = Random();

  @override
  CustomQuestions build() {
    final prefs = ref.read(sharedPreferencesProvider);
    List<WyrItem> load(GameMode m) {
      final raw = prefs.getString(_key(m));
      if (raw == null) return const [];
      try {
        return [
          for (final j in jsonDecode(raw) as List<dynamic>)
            WyrItem(
              id: (j as Map<String, dynamic>)['id'] as String,
              category: customCategoryId,
              a: j['a'] as String,
              b: j['b'] as String,
            ),
        ];
      } on Object {
        return const [];
      }
    }

    return CustomQuestions(wyr: load(GameMode.wouldYouRather), tot: load(GameMode.thisOrThat));
  }

  void _save(GameMode mode, List<WyrItem> items) {
    state = state.copyWith(mode, List.unmodifiable(items));
    ref
        .read(sharedPreferencesProvider)
        .setString(
          _key(mode),
          jsonEncode([
            for (final q in items) {'id': q.id, 'a': q.a, 'b': q.b},
          ]),
        );
  }

  String _newId(GameMode mode) {
    final prefix = mode == GameMode.wouldYouRather ? 'wyr' : 'tot';
    final stamp = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
    return '$prefix-$customCategoryId-$stamp${_random.nextInt(1296).toRadixString(36)}';
  }

  /// Adds a question, or returns why it can't be saved.
  CustomProblem? add(GameMode mode, String a, String b) {
    final problem = checkCustom(mode, a, b, state.of(mode));
    if (problem != null) return problem;
    _save(mode, [...state.of(mode), WyrItem(id: _newId(mode), category: customCategoryId, a: _clean(a), b: _clean(b))]);
    return null;
  }

  CustomProblem? edit(GameMode mode, String id, String a, String b) {
    final problem = checkCustom(mode, a, b, state.of(mode), editingId: id);
    if (problem != null) return problem;
    _save(mode, [
      for (final q in state.of(mode))
        if (q.id == id) WyrItem(id: id, category: customCategoryId, a: _clean(a), b: _clean(b)) else q,
    ]);
    return null;
  }

  void remove(GameMode mode, String id) => _save(mode, state.of(mode).where((q) => q.id != id).toList());

  /// Puts a removed question back where it was (for "Undo").
  void restore(GameMode mode, WyrItem item, int index) {
    final list = [...state.of(mode)]..insert(min(index, state.of(mode).length), item);
    _save(mode, list);
  }
}

final customQuestionsProvider = NotifierProvider<CustomQuestionsController, CustomQuestions>(
  CustomQuestionsController.new,
);

/// The bundled packs plus the person's own questions as a free "My questions" category.
ContentLibrary withCustomQuestions(ContentLibrary base, CustomQuestions custom) {
  WyrPack extend(WyrPack pack, List<WyrItem> mine) => mine.isEmpty
      ? pack
      : Pack<WyrItem>(categories: [...pack.categories, myQuestionsCategory], items: [...pack.items, ...mine]);
  if (custom.wyr.isEmpty && custom.tot.isEmpty) return base;
  return ContentLibrary(
    wyr: extend(base.wyr, custom.wyr),
    tot: extend(base.tot, custom.tot),
    trivia: base.trivia,
    guess: base.guess,
  );
}

/// Region `mine` keeps it out of Quick play and default selections until someone ticks it.
const myQuestionsCategory = Category(
  id: customCategoryId,
  name: 'My questions',
  description: 'Questions you wrote. They stay on this phone.',
  tier: Tier.free,
  ageRating: AgeRating.all,
  region: 'mine',
);
