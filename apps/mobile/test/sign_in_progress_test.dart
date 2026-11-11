import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gleefy/account/auth_repository.dart';

import 'premium_test.dart' show FakeApi, FakeAuth, fakes, go;
import 'support/harness.dart';

/// Sign-in whose server answers only when the test says so, to see what shows meanwhile.
class SlowAuth extends FakeAuth {
  SlowAuth() : super(googleEnabled: true);
  Completer<void>? pending;
  String? lastCode;

  Future<void> _wait() {
    pending = Completer<void>();
    return pending!.future;
  }

  @override
  Future<void> sendCode(String email) => _wait();

  @override
  Future<void> verifyCode({required String email, required String code}) async {
    lastCode = code;
    await _wait();
    currentUser = AppUser(id: 'u-1', email: email);
  }

  @override
  Future<void> signInWithGoogle() => _wait();
}

void main() {
  testWidgets('sending and checking the code show a spinner, and six digits check themselves', (tester) async {
    final auth = SlowAuth();
    final h = await pumpSignIn(tester, auth);
    await tester.tap(find.text('I’m 18 or older'));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'host@example.test');
    await tester.tap(find.text('Send code'));
    await tester.pump();
    expect(find.text('Sending code…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    auth.pending!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Sending code…'), findsNothing);

    await tester.enterText(find.byType(TextField), '123456'); // no tap: the sixth digit submits
    await tester.pump();
    expect(auth.lastCode, '123456');
    expect(find.text('Checking code…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    auth.pending!.complete();
    await tester.pumpAndSettle();
    expect(h, isNotNull);
  });

  testWidgets('Continue with Google shows it is opening Google', (tester) async {
    final auth = SlowAuth();
    await pumpSignIn(tester, auth);
    await tester.tap(find.text('I’m 18 or older'));
    await tester.pump();
    await tester.tap(find.text('Continue with Google'));
    await tester.pump();
    expect(find.text('Opening Google…'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    auth.pending!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Opening Google…'), findsNothing);
    // Now waiting for the browser to come back: still a spinner, with the waiting message.
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}

Future<Harness> pumpSignIn(WidgetTester tester, FakeAuth auth) async {
  final h = await pumpApp(tester, overrides: fakes(auth, FakeApi()));
  await go(tester, h, '/account/sign-in');
  return h;
}
