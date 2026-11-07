import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/content.dart';
import '../../game/guess_engine.dart';
import '../../game/trivia_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../state/games.dart';
import '../../state/sessions.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/brand.dart';
import '../../widgets/results_actions.dart';
import '../../widgets/motion.dart';
import '../../widgets/progress_widgets.dart';
import '../../widgets/usage_prompt.dart';
import '../modes.dart';

typedef _Row = ({int team, int score, String detail});

/// Scoreboard results for Trivia Blitz and Guess the Answer.
class ScoreResultsScreen extends ConsumerWidget {
  const ScoreResultsScreen({super.key, required this.mode});

  final GameMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = MmPalette.of(context);

    final List<_Row> rows;
    final List<int> winners;
    final List<String> names;
    final VoidCallback clear;
    final VoidCallback restart;
    if (mode == GameMode.trivia) {
      final s = ref.watch(triviaSessionProvider);
      final c = ref.read(triviaSessionProvider.notifier);
      if (s == null || s.status != SessionStatus.finished) return const _NoResults();
      final r = triviaResults(s);
      rows = [
        for (final t in r.standings) (team: t.team, score: t.score, detail: l.resultsCorrectOf(t.correct, t.answered)),
      ];
      winners = r.winners;
      (names, clear, restart) = (c.names, c.clear, c.restart);
    } else {
      final s = ref.watch(guessSessionProvider);
      final c = ref.read(guessSessionProvider.notifier);
      if (s == null || s.status != SessionStatus.finished) return const _NoResults();
      final r = guessResults(s);
      rows = [
        for (final t in r.ranking)
          (
            team: t,
            score: s.scores[t],
            detail: l.resultsSolvedOf(
              s.rounds.where((x) => x.team == t && x.outcome == GuessOutcome.got).length,
              s.rounds.where((x) => x.team == t && x.outcome != GuessOutcome.skipped).length,
            ),
          ),
      ];
      winners = r.winners;
      (names, clear, restart) = (c.names, c.clear, c.restart);
    }

    String nameOf(int team) => team < names.length ? names[team] : l.everyone;
    final headline = winners.isEmpty
        ? l.resultsNoWinner
        : winners.length == 1
        ? (names.isEmpty ? l.resultsPoints(rows.first.score) : l.resultsWinner(nameOf(winners.first)))
        : l.resultsTie(winners.map(nameOf).join(', '));

    return Scaffold(
      appBar: AppBar(
        title: Text(l.resultsTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: l.resultsHome,
            icon: const Icon(Icons.home_outlined),
            onPressed: () {
              clear();
              ref.read(partyProvider.notifier).stop();
              context.go('/');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(MmSpace.s4),
            children: [
              PopIn(
                child: GradientPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(modeName(l, mode), style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                      const SizedBox(height: MmSpace.s1),
                      Text(headline, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                    ],
                  ),
                ),
              ),
              const RewardCard(),
              const UsagePrompt(),
              const SizedBox(height: MmSpace.s4),
              for (final (i, row) in rows.indexed)
                StaggerIn(
                  index: i + 2,
                  child: Card(
                    margin: const EdgeInsets.only(bottom: MmSpace.s2),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: winners.contains(row.team) ? palette.accent : palette.surfaceMuted,
                        foregroundColor: winners.contains(row.team) ? palette.onAccent : theme.colorScheme.onSurface,
                        child: Text('${i + 1}'),
                      ),
                      title: Text(nameOf(row.team), style: theme.textTheme.titleMedium),
                      subtitle: Text(row.detail),
                      trailing: Text(l.resultsPoints(row.score), style: theme.textTheme.titleMedium),
                    ),
                  ),
                ),
            ],
          ),
          // A one-off celebration when the results appear.
          const Positioned.fill(child: Confetti()),
        ],
      ),
      bottomNavigationBar: ResultsActions(mode: mode, onPlayAgain: restart, onClear: clear),
    );
  }
}

class _NoResults extends StatelessWidget {
  const _NoResults();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(
      child: FilledButton(onPressed: () => context.go('/'), child: Text(AppLocalizations.of(context).goHome)),
    ),
  );
}
