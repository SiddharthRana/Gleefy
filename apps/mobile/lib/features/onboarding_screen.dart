import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import '../widgets/brand.dart';
import '../widgets/motion.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final settings = ref.read(settingsProvider);
    await ref.read(settingsProvider.notifier).update(settings.copyWith(onboarded: true));
    if (mounted) context.go('/');
  }

  void _next() {
    if (_page == 2) {
      _finish();
      return;
    }
    final reduce = reduceMotionOf(context, ref);
    if (reduce) {
      _controller.jumpToPage(_page + 1);
    } else {
      _controller.nextPage(duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final pages = [
      (null, l.onboarding1Title, l.onboarding1Body),
      (Icons.record_voice_over_rounded, l.onboarding2Title, l.onboarding2Body),
      (Icons.bolt_rounded, l.onboarding3Title, l.onboarding3Body),
    ];

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(GfSpace.s6, GfSpace.s4, GfSpace.s2, 0),
              child: Row(
                children: [
                  const GleefyWordmark(size: 22),
                  const Spacer(),
                  if (_page < 2) TextButton(onPressed: _finish, child: Text(l.onboardingSkip)),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (p) => setState(() => _page = p),
                children: [
                  for (final (icon, title, body) in pages)
                    SingleChildScrollView(
                      padding: const EdgeInsets.all(GfSpace.s6),
                      child: Column(
                        children: [
                          const SizedBox(height: GfSpace.s8),
                          // The first page shows the app icon itself; the others an illustration.
                          if (icon == null)
                            PopIn(
                              child: ExcludeSemantics(
                                child: Image.asset('assets/brand/icon.png', width: 176, height: 176),
                              ),
                            )
                          else
                            GradientPanel(padding: const EdgeInsets.all(GfSpace.s10), child: Icon(icon, size: 72)),
                          const SizedBox(height: GfSpace.s8),
                          Text(title, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                          const SizedBox(height: GfSpace.s4),
                          Text(
                            body,
                            style: theme.textTheme.bodyLarge?.copyWith(color: palette.textMuted),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Semantics(
              label: '${_page + 1} / 3',
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < 3; i++)
                    AnimatedContainer(
                      duration: reduceMotionOf(context, ref) ? Duration.zero : const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: GfSpace.s1),
                      width: i == _page ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _page ? theme.colorScheme.primary : theme.colorScheme.outline,
                        borderRadius: BorderRadius.circular(GfRadius.pill),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(GfSpace.s6),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _next,
                      child: Text(_page == 2 ? l.onboardingStart : l.onboardingNext),
                    ),
                  ),
                  const SizedBox(height: GfSpace.s3),
                  Text(l.onboardingAge, style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
