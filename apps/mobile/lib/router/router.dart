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

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      // First launch goes through the short introduction; it never blocks later visits.
      final onboarded = ref.read(settingsProvider).onboarded;
      if (!onboarded && state.matchedLocation != '/onboarding') return '/onboarding';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
      GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
      GoRoute(path: '/games', builder: (_, _) => const LibraryScreen()),
      GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
      GoRoute(path: '/players', builder: (_, _) => const PlayersScreen()),
      GoRoute(path: '/party', builder: (_, _) => const PartyScreen()),
      GoRoute(path: '/premium', builder: (_, _) => const PremiumScreen()),
      GoRoute(
        path: '/my-questions',
        builder: (_, state) => MyQuestionsScreen(
          initialMode: GameMode.fromId(state.uri.queryParameters['mode'] ?? '') ?? GameMode.wouldYouRather,
        ),
      ),
      GoRoute(path: '/account', builder: (_, _) => const AccountScreen()),
      GoRoute(path: '/account/sign-in', builder: (_, _) => const SignInScreen()),
      // Shared links from the website: https://<domain>/play?c=…
      GoRoute(
        path: '/play',
        builder: (_, state) => SharedLinkScreen(code: state.uri.queryParameters['c']),
      ),
      for (final mode in GameMode.values) ...[
        GoRoute(
          path: '/play/${mode.id}/setup',
          builder: (_, _) => SetupScreen(mode: mode),
        ),
        GoRoute(
          path: '/play/${mode.id}',
          builder: (_, _) => switch (mode) {
            GameMode.wouldYouRather => const WyrPlayScreen(),
            GameMode.thisOrThat => const TotPlayScreen(),
            GameMode.trivia => const TriviaPlayScreen(),
            GameMode.guess => const GuessPlayScreen(),
          },
        ),
        GoRoute(
          path: '/play/${mode.id}/results',
          builder: (_, _) => switch (mode) {
            GameMode.wouldYouRather || GameMode.thisOrThat => ChoiceResultsScreen(mode: mode),
            GameMode.trivia || GameMode.guess => ScoreResultsScreen(mode: mode),
          },
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
