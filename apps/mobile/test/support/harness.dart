import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:mirthmix/app.dart';
import 'package:mirthmix/content/content.dart';
import 'package:mirthmix/state/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeScreenAwake implements ScreenAwake {
  bool on = false;
  @override
  Future<void> enable() async => on = true;
  @override
  Future<void> disable() async => on = false;
}

String _asset(String mode) => File('assets/content/$mode.json').readAsStringSync();

ContentLibrary realContent() => ContentLibrary(
  wyr: parseWyrPack(_asset('would-you-rather')),
  tot: parseTotPack(_asset('this-or-that')),
  trivia: parseTriviaPack(_asset('trivia')),
  guess: parseGuessPack(_asset('guess')),
);

const _free = Category(
  id: 'casual',
  name: 'Casual',
  description: 'Easy ones',
  tier: Tier.free,
  ageRating: AgeRating.all,
  region: 'global',
);

/// A small, predictable pack for flow tests.
ContentLibrary tinyContent({int casual = 3}) => ContentLibrary(
  tot: TotPack(
    categories: const [_free],
    items: [
      for (var i = 1; i <= 3; i++) WyrItem(id: 'tot-casual-00$i', category: 'casual', a: 'Tea $i', b: 'Coffee $i'),
    ],
  ),
  trivia: TriviaPack(
    categories: const [_free],
    items: [
      for (var i = 1; i <= 3; i++)
        TriviaItem(
          id: 'triv-casual-00$i',
          category: 'casual',
          question: 'Question $i?',
          choices: ['Right $i', 'Wrong A$i', 'Wrong B$i', 'Wrong C$i'],
          answer: 0,
          explanation: 'Because $i.',
        ),
    ],
  ),
  guess: GuessPack(
    categories: const [_free],
    items: [
      for (var i = 1; i <= 3; i++)
        GuessItem(
          id: 'gta-casual-00$i',
          category: 'casual',
          answer: 'Thing $i',
          clues: ['Hard $i', 'Medium $i', 'Easy $i'],
        ),
    ],
  ),
  wyr: WyrPack(
    categories: const [
      Category(
        id: 'casual',
        name: 'Casual',
        description: 'Easy ones',
        tier: Tier.free,
        ageRating: AgeRating.all,
        region: 'global',
      ),
      Category(
        id: 'deep',
        name: 'Deep',
        description: 'Premium ones',
        tier: Tier.premium,
        ageRating: AgeRating.teen,
        region: 'global',
        contentNote: 'Serious topics',
      ),
    ],
    items: [
      for (var i = 1; i <= casual; i++)
        WyrItem(id: 'wyr-casual-00$i', category: 'casual', a: 'Apple $i', b: 'Banana $i'),
      const WyrItem(id: 'wyr-deep-001', category: 'deep', a: 'Deep A', b: 'Deep B'),
    ],
  ),
);

class Harness {
  Harness(this.prefs, this.container, this.awake);
  final SharedPreferences prefs;
  final ProviderContainer container;
  final FakeScreenAwake awake;
}

/// Pumps the whole app. Pass [prefs] to simulate a relaunch with saved state.
Future<Harness> pumpApp(
  WidgetTester tester, {
  ContentLibrary? content,
  bool onboarded = true,
  SharedPreferences? prefs,
  Map<String, Object> initialPrefs = const {},
  List<Override> overrides = const [],
}) async {
  if (prefs == null) {
    SharedPreferences.setMockInitialValues({
      'settings.onboarded': onboarded,
      'settings.haptics': false,
      ...initialPrefs,
    });
    prefs = await SharedPreferences.getInstance();
  }
  tester.view.physicalSize = const Size(1080, 2280);
  tester.view.devicePixelRatio = 2.75;
  addTearDown(tester.view.reset);

  final awake = FakeScreenAwake();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      bundledContentProvider.overrideWithValue(content ?? tinyContent()),
      screenAwakeProvider.overrideWithValue(awake),
      ...overrides,
    ],
  );
  addTearDown(container.dispose);
  await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const MirthMixApp()));
  await tester.pumpAndSettle();
  return Harness(prefs, container, awake);
}
