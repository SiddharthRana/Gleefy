import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleefy/state/providers.dart';
import 'package:gleefy/theme/app_theme.dart';
import 'package:gleefy/widgets/motion.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> pumpMotion(WidgetTester tester, Widget child, {bool reduceMotion = false}) async {
  SharedPreferences.setMockInitialValues({'settings.reduceMotion': reduceMotion});
  final prefs = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: MaterialApp(
        theme: buildTheme(Brightness.light),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}

double scaleOf(WidgetTester tester) => tester.widget<AnimatedScale>(find.byType(AnimatedScale)).scale;

void main() {
  testWidgets('Pressable squishes while pressed and still lets the tap through', (tester) async {
    var taps = 0;
    await pumpMotion(
      tester,
      Pressable(
        child: ElevatedButton(onPressed: () => taps++, child: const Text('Go')),
      ),
    );
    final gesture = await tester.startGesture(tester.getCenter(find.text('Go')));
    await tester.pump();
    expect(scaleOf(tester), 0.95);
    await gesture.up();
    await tester.pumpAndSettle();
    expect(scaleOf(tester), 1);
    expect(taps, 1);
  });

  testWidgets('with Reduce motion on, nothing moves', (tester) async {
    await pumpMotion(
      tester,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Pressable(child: Text('Press')),
          StaggerIn(child: Text('Stagger')),
          PopIn(child: Text('Pop')),
          SizedBox(width: 200, height: 200, child: Confetti()),
        ],
      ),
      reduceMotion: true,
    );
    expect(find.byType(AnimatedScale), findsNothing);
    expect(
      find
          .byType(CustomPaint)
          .evaluate()
          .where(
            (e) =>
                e.widget is CustomPaint &&
                (e.widget as CustomPaint).painter != null &&
                e.widget.runtimeType == CustomPaint,
          ),
      isEmpty,
    );
    // Everything is visible immediately: no fade-in in progress.
    expect(find.byType(Opacity), findsNothing);
  });

  testWidgets('confetti is a one-off and hidden from screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await pumpMotion(tester, const SizedBox(width: 300, height: 300, child: Confetti()));
    expect(find.byType(ExcludeSemantics), findsWidgets);
    await tester.pumpAndSettle(); // finishes on its own
    handle.dispose();
  });

  testWidgets('Bump replays when its value changes', (tester) async {
    var value = 1;
    late StateSetter setValue;
    await pumpMotion(
      tester,
      StatefulBuilder(
        builder: (_, set) {
          setValue = set;
          return Bump(value: value, child: Text('$value'));
        },
      ),
    );
    double scale() => tester
        .widget<ScaleTransition>(find.descendant(of: find.byType(Bump), matching: find.byType(ScaleTransition)))
        .scale
        .value;
    expect(scale(), 1);
    setValue(() => value = 2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(scale(), greaterThan(1));
    await tester.pumpAndSettle();
    expect(scale(), 1);
  });
}
