import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/account_screen.dart';
import '../features/account/premium_screen.dart';
import '../features/account/sign_in_screen.dart';
import '../features/home_screen.dart';
import '../features/my_questions_screen.dart';
import '../features/library_screen.dart';
import '../features/onboarding_screen.dart';
import '../features/settings_screen.dart';
import '../content/content.dart';
import '../features/guess_play_screen.dart';
import '../features/party_screen.dart';
import '../features/players_screen.dart';
import '../features/results/choice_results_screen.dart';
import '../features/results/score_results_screen.dart';
import '../features/setup_screen.dart';
import '../features/shared_link_screen.dart';
import '../features/tot_play_screen.dart';
import '../features/trivia_play_screen.dart';
import '../features/wyr_play_screen.dart';
import '../l10n/app_localizations.dart';
import '../state/settings.dart';
import 'game_page.dart';

final routerProvider = Provider<GoRouter>((ref) {
  // Every page is dealt in like a card (still when Reduce motion is on).
  Page<void> page(GoRouterState state, Widget child) =>
      GamePage<void>(key: state.pageKey, still: ref.read(settingsProvider).reduceMotion, child: child);

  return GoRouter(
    initialLocation: '/',
    // "Continue with Google" comes back through mirthmix://auth-callback. Supabase finishes the
    // sign-in from that link itself, so the router stays on the current screen.
    onEnter: (context, current, next, router) => isAuthCallback(next.uri) ? const Block.stop() : const Allow(),
    redirect: (context, state) {
      // First launch goes through the short introduction; it never blocks later visits.
      final onboarded = ref.read(settingsProvider).onboarded;
      if (!onboarded && state.matchedLocation != '/onboarding') return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(path: '/', pageBuilder: (_, state) => page(state, const HomeScreen())),
      GoRoute(path: '/onboarding', pageBuilder: (_, state) => page(state, const OnboardingScreen())),
      GoRoute(path: '/games', pageBuilder: (_, state) => page(state, const LibraryScreen())),
      GoRoute(path: '/settings', pageBuilder: (_, state) => page(state, const SettingsScreen())),
      GoRoute(path: '/players', pageBuilder: (_, state) => page(state, const PlayersScreen())),
      GoRoute(path: '/party', pageBuilder: (_, state) => page(state, const PartyScreen())),
      GoRoute(path: '/premium', pageBuilder: (_, state) => page(state, const PremiumScreen())),
      GoRoute(
        path: '/my-questions',
        pageBuilder: (_, state) => page(
          state,
          MyQuestionsScreen(
            initialMode: GameMode.fromId(state.uri.queryParameters['mode'] ?? '') ?? GameMode.wouldYouRather,
          ),
        ),
      ),
      GoRoute(path: '/account', pageBuilder: (_, state) => page(state, const AccountScreen())),
      GoRoute(path: '/account/sign-in', pageBuilder: (_, state) => page(state, const SignInScreen())),
      // Shared links from the website: https://<domain>/play?c=…
      GoRoute(
        path: '/play',
        pageBuilder: (_, state) => page(state, SharedLinkScreen(code: state.uri.queryParameters['c'])),
      ),
      for (final mode in GameMode.values) ...[
        GoRoute(
          path: '/play/${mode.id}/setup',
          pageBuilder: (_, state) => page(state, SetupScreen(mode: mode)),
        ),
        GoRoute(
          path: '/play/${mode.id}',
          pageBuilder: (_, state) => page(state, switch (mode) {
            GameMode.wouldYouRather => const WyrPlayScreen(),
            GameMode.thisOrThat => const TotPlayScreen(),
            GameMode.trivia => const TriviaPlayScreen(),
            GameMode.guess => const GuessPlayScreen(),
          }),
        ),
        GoRoute(
          path: '/play/${mode.id}/results',
          pageBuilder: (_, state) => page(state, switch (mode) {
            GameMode.wouldYouRather || GameMode.thisOrThat => ChoiceResultsScreen(mode: mode),
            GameMode.trivia || GameMode.guess => ScoreResultsScreen(mode: mode),
          }),
        ),
      ],
    ],
    errorBuilder: (context, state) => Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(AppLocalizations.of(context).errorNotFound),
            const SizedBox(height: 16),
            FilledButton(onPressed: () => context.go('/'), child: Text(AppLocalizations.of(context).goHome)),
          ],
        ),
      ),
    ),
  );
});

/// The deep link Supabase Auth returns to after "Continue with Google".
bool isAuthCallback(Uri uri) =>
    uri.scheme == 'mirthmix' || uri.host == 'auth-callback' || uri.path.startsWith('/auth-callback');
