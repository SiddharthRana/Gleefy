import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleefy/widgets/brand.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required bool premium}) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: GleefyWordmark(premium: premium)),
    ),
  );

  testWidgets('the wordmark shows a PREMIUM tag only with Premium', (tester) async {
    await pump(tester, premium: false);
    expect(find.text('PREMIUM'), findsNothing);
    expect(find.bySemanticsLabel('Gleefy'), findsOneWidget);

    await pump(tester, premium: true);
    expect(find.text('PREMIUM'), findsOneWidget);
    expect(find.bySemanticsLabel('Gleefy Premium'), findsOneWidget);
  });
}
