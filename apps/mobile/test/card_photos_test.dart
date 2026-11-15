import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleefy/state/card_photos.dart';
import 'package:gleefy/state/dream_team.dart';
import 'package:gleefy/state/providers.dart';

import 'premium_test.dart' show go;
import 'support/harness.dart';

/// A 1×1 PNG, standing in for a gallery photo.
const _png = [
  0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52, //
  0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01, 0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
  0x89, 0x00, 0x00, 0x00, 0x0D, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0xF8, 0xCF, 0xC0, 0xF0,
  0x1F, 0x00, 0x05, 0x00, 0x01, 0xFF, 0x89, 0x99, 0x3D, 0x1D, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
  0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
];

class FakePicker implements PhotoPicker {
  int picks = 0;
  @override
  Future<String?> pick(String dir) async {
    Directory(dir).createSync(recursive: true);
    final name = 'fake-${picks++}.png';
    File('$dir/$name').writeAsBytesSync(_png);
    return name;
  }
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('gleefy-photos'));
  tearDown(() => dir.deleteSync(recursive: true));

  testWidgets('add photos to a custom deck; they show on the flipped card', (tester) async {
    final picker = FakePicker();
    final h = await pumpApp(
      tester,
      content: realContent(),
      overrides: [
        premiumProvider.overrideWithValue(true),
        cardPhotosDirProvider.overrideWithValue(dir.path),
        photoPickerProvider.overrideWithValue(picker),
      ],
    );
    await go(tester, h, '/dream-team/decks/new');
    await tester.enterText(find.byType(TextField).at(0), 'Office');
    await tester.enterText(find.byType(TextField).at(1), List.generate(12, (i) => 'Mate ${i + 1}').join('\n'));
    await tester.pumpAndSettle();

    Future<void> addPhoto() async {
      await tester.scrollUntilVisible(find.text('Add photo').first, 200, scrollable: find.byType(Scrollable).first);
      await tester.runAsync(() async {
        await tester.tap(find.text('Add photo').first);
        await Future<void>.delayed(const Duration(milliseconds: 50));
      });
      await tester.pumpAndSettle();
    }

    await addPhoto(); // Mate 1
    await addPhoto(); // Mate 2
    expect(find.text('Change'), findsNWidgets(2));
    // Remove Mate 1's photo again: its file is deleted on save.
    await tester.tap(find.byTooltip('Remove the photo of Mate 1'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Save deck'), 200, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Save deck'));
    await tester.pumpAndSettle();

    final deck = h.container.read(customDecksProvider).single;
    expect(deck.photos.keys, ['mate 2']);
    expect(File('${dir.path}/fake-0.png').existsSync(), isFalse);
    final cards = deck.toCards(dir.path);
    expect(cards.where((c) => c.photo != null).map((c) => c.name), ['Mate 2']);

    // Deleting the deck deletes its photos.
    h.container.read(customDecksProvider.notifier).remove(deck.id);
    expect(dir.listSync(), isEmpty);
  });

  testWidgets('a game with photos shows them when a card is flipped', (tester) async {
    final h = await pumpApp(
      tester,
      content: realContent(),
      overrides: [premiumProvider.overrideWithValue(true), cardPhotosDirProvider.overrideWithValue(dir.path)],
    );
    File('${dir.path}/p.png').writeAsBytesSync(_png);
    final names = List.generate(12, (i) => 'Mate ${i + 1}');
    h.container
        .read(customDecksProvider.notifier)
        .save(name: 'Office', cards: names, photos: {for (final n in names) photoKey(n): 'p.png'});
    await go(tester, h, '/dream-team');
    await tester.tap(find.text('Office'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Start the draft'));
    await tester.tap(find.text('Start the draft'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tap to flip'));
    await tester.pumpAndSettle();
    expect(find.byType(Image), findsWidgets);
  });
}
