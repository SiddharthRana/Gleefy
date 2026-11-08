import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../account/auth_repository.dart';
import '../../account/entitlement.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/motion.dart';
import '../../widgets/insets.dart';

/// "Continue with Google", or email + one-time code. Only purchasers come here; guests never need
/// an account.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen> {
  final _email = TextEditingController();
  final _code = TextEditingController();
  String? _sentTo;
  String? _error;

  /// Accounts and purchases are 18+ (BUILD_PROMPT §0, India's DPDP Act); self-declared here.
  bool _adult = false;
  bool _busy = false;

  /// Google's page is open in the browser; the app is waiting for it to come back.
  bool _googleWaiting = false;
  StreamSubscription<AuthEvent>? _events;
  StreamSubscription<String>? _googleErrors;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authRepositoryProvider);
    // Google sign-in finishes in the browser and comes back through a deep link.
    _events = auth.events.listen((e) {
      if (e == AuthEvent.signedIn && _googleWaiting) unawaited(_done());
    });
    _googleErrors = auth.googleErrors.listen((code) {
      if (!mounted) return;
      final l = AppLocalizations.of(context);
      setState(() {
        _googleWaiting = false;
        _busy = false;
        _error = switch (code) {
          'google_cancelled' => l.signInGoogleCancelled,
          'google_signups_closed' => l.signInGoogleClosed,
          _ => l.signInGoogleFailed,
        };
      });
    });
  }

  @override
  void dispose() {
    _events?.cancel();
    _googleErrors?.cancel();
    _email.dispose();
    _code.dispose();
    super.dispose();
  }

  Future<void> _done() async {
    await ref.read(entitlementProvider.notifier).refresh();
    if (!mounted) return;
    context.canPop() ? context.pop() : context.go('/premium');
  }

  Future<void> _google() async {
    final l = AppLocalizations.of(context);
    if (!_adult) {
      setState(() => _error = l.signInAdultRequired);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      if (mounted) setState(() => _googleWaiting = true);
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = e.code == 'google_failed' ? l.signInGoogleFailed : _describe(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _describe(AppLocalizations l, AuthFailure e) => switch (e.code) {
    'invalid_code' => l.signInErrorCode,
    'rate_limited' => l.signInErrorRate,
    'network' => l.premiumErrorNetwork,
    'unavailable' => l.premiumUnavailableBuild,
    _ => l.signInErrorUnknown,
  };

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on AuthFailure catch (e) {
      if (mounted) setState(() => _error = _describe(AppLocalizations.of(context), e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final l = AppLocalizations.of(context);
    final email = _email.text.trim();
    if (!looksLikeEmail(email)) {
      setState(() => _error = l.signInBadEmail);
      return;
    }
    if (!_adult) {
      setState(() => _error = l.signInAdultRequired);
      return;
    }
    await _run(() async {
      await ref.read(authRepositoryProvider).sendCode(email);
      if (mounted) setState(() => _sentTo = email);
    });
  }

  Future<void> _verify() => _run(() async {
    await ref.read(authRepositoryProvider).verifyCode(email: _sentTo!, code: _code.text);
    await _done();
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sent = _sentTo != null;
    final google = !sent && ref.watch(authRepositoryProvider).googleEnabled;
    return Scaffold(
      appBar: AppBar(title: Text(l.signInTitle)),
      body: ListView(
        padding: listPadding(context, const EdgeInsets.all(GfSpace.s4)),
        children: [
          if (!sent)
            CheckboxListTile(
              value: _adult,
              onChanged: _busy ? null : (v) => setState(() => _adult = v ?? false),
              title: Text(l.signInAdult),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          if (google) ...[
            const SizedBox(height: GfSpace.s2),
            Pressable(
              enabled: !_busy,
              child: OutlinedButton.icon(
                onPressed: _busy ? null : _google,
                icon: const _GoogleMark(),
                label: Text(l.signInGoogle),
              ),
            ),
            if (_googleWaiting) ...[
              const SizedBox(height: GfSpace.s2),
              Semantics(liveRegion: true, child: Text(l.signInGoogleWaiting, textAlign: TextAlign.center)),
            ],
            const SizedBox(height: GfSpace.s4),
            Text(
              l.signInOr.toUpperCase(),
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(letterSpacing: 1.2),
            ),
            const SizedBox(height: GfSpace.s4),
          ],
          Text(sent ? l.signInCodeSent(_sentTo!) : l.signInBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: GfSpace.s4),
          if (!sent)
            TextField(
              controller: _email,
              enabled: !_busy,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              decoration: InputDecoration(labelText: l.signInEmail, border: const OutlineInputBorder()),
            )
          else
            TextField(
              controller: _code,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              maxLength: 6,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _verify(),
              decoration: InputDecoration(labelText: l.signInCode, border: const OutlineInputBorder()),
            ),
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(top: GfSpace.s2),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            ),
          const SizedBox(height: GfSpace.s4),
          Pressable(
            enabled: !_busy,
            child: FilledButton(
              onPressed: _busy ? null : (sent ? _verify : _send),
              child: Text(sent ? l.signInVerify : l.signInSendCode),
            ),
          ),
          if (sent)
            TextButton(
              onPressed: _busy
                  ? null
                  : () => setState(() {
                      _sentTo = null;
                      _code.clear();
                      _error = null;
                    }),
              child: Text(l.signInChangeEmail),
            ),
        ],
      ),
    );
  }
}

/// Google's "G" mark, as Google's sign-in branding asks for (drawn, so no image asset is needed).
class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) =>
      const SizedBox.square(dimension: 20, child: CustomPaint(painter: _GooglePainter()));
}

class _GooglePainter extends CustomPainter {
  const _GooglePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final stroke = size.width * 0.2;
    final rect = Rect.fromCircle(center: c, radius: r - stroke / 2);
    Paint arc(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    const deg = 3.14159265 / 180;
    canvas.drawArc(rect, -40 * deg, -100 * deg, false, arc(const Color(0xFFEA4335))); // red, top
    canvas.drawArc(rect, -140 * deg, -90 * deg, false, arc(const Color(0xFFFBBC05))); // yellow, left
    canvas.drawArc(rect, -230 * deg, -95 * deg, false, arc(const Color(0xFF34A853))); // green, bottom
    canvas.drawArc(rect, 35 * deg, -35 * deg, false, arc(const Color(0xFF4285F4))); // blue, right
    canvas.drawRect(Rect.fromLTWH(r, r - stroke / 2, r - stroke / 4, stroke), Paint()..color = const Color(0xFF4285F4));
  }

  @override
  bool shouldRepaint(_GooglePainter old) => false;
}
