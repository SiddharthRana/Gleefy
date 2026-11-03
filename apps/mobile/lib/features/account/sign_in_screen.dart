import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../account/auth_repository.dart';
import '../../account/entitlement.dart';
import '../../l10n/app_localizations.dart';
import '../../theme/tokens.g.dart';

/// Email + one-time code. Only purchasers come here; guests never need an account.
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

  @override
  void dispose() {
    _email.dispose();
    _code.dispose();
    super.dispose();
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
    await ref.read(entitlementProvider.notifier).refresh();
    if (!mounted) return;
    context.canPop() ? context.pop() : context.go('/premium');
  });

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final sent = _sentTo != null;
    return Scaffold(
      appBar: AppBar(title: Text(l.signInTitle)),
      body: ListView(
        padding: const EdgeInsets.all(MmSpace.s4),
        children: [
          Text(sent ? l.signInCodeSent(_sentTo!) : l.signInBody, style: theme.textTheme.bodyLarge),
          const SizedBox(height: MmSpace.s4),
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
          if (!sent)
            CheckboxListTile(
              value: _adult,
              onChanged: _busy ? null : (v) => setState(() => _adult = v ?? false),
              title: Text(l.signInAdult),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
            ),
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(top: MmSpace.s2),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            ),
          const SizedBox(height: MmSpace.s4),
          FilledButton(
            onPressed: _busy ? null : (sent ? _verify : _send),
            child: Text(sent ? l.signInVerify : l.signInSendCode),
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
