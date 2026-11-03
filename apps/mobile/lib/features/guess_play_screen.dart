import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../content/content.dart';
import '../game/guess_engine.dart';
import '../game/trivia_engine.dart' show SessionStatus;
import '../l10n/app_localizations.dart';
import '../state/games.dart';
import '../state/providers.dart';
import '../state/sessions.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import '../widgets/game_shell.dart';
import '../widgets/motion.dart';

/// Guess the Answer: the reader sees the answer and reads clues aloud one at a time.
class GuessPlayScreen extends ConsumerWidget {
  const GuessPlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = MmPalette.of(context);
    final session = ref.watch(guessSessionProvider);
    final cur = session?.current;
    final item = cur == null ? null : ref.watch(contentProvider).guess.item(cur.questionId);
    if (session == null || cur == null || item == null) return const NoGameScreen();

    final controller = ref.read(guessSessionProvider.notifier);
    void act(GuessAction action) {
      controller.dispatch(action);
      if (ref.read(guessSessionProvider)?.status == SessionStatus.finished) {
        context.pushReplacement(resultsRoute(GameMode.guess));
      }
    }

    final names = controller.names;
    final team = cur.team < names.length ? names[cur.team] : l.everyone;
    final decided = cur.outcome != null;

    String? outcome;
    if (cur.outcome == GuessOutcome.got) {
      outcome = l.guessScored(pointsFor(cur.cluesShown), team);
    } else if (cur.outcome == GuessOutcome.revealed) {
      outcome = l.guessNoPoints;
    }

    return GameShell(
      title: l.cardOf(session.roundNumber, session.totalRounds),
      progress: session.rounds.length / session.totalRounds,
      onQuit: controller.clear,
      actions: [
        if (!decided)
          TextButton(
            onPressed: () => act(GuessAction.skip),
            child: Tooltip(message: l.playSkipTooltip, child: Text(l.playSkip)),
          ),
      ],
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(MmSpace.s4),
            children: [
              Text(
                l.guessGuessing(team),
                style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: MmSpace.s3),
              Card(
                color: palette.surfaceMuted,
                child: Padding(
                  padding: const EdgeInsets.all(MmSpace.s4),
                  child: Column(
                    children: [
                      Text(l.guessReaderOnly, style: theme.textTheme.bodySmall),
                      const SizedBox(height: MmSpace.s1),
                      Text(item.answer, style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: MmSpace.s4),
              for (var i = 0; i < cur.cluesShown; i++) ...[
                // Each clue slides in as it's revealed.
                StaggerIn(
                  key: ValueKey('${cur.questionId}-clue-$i'),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(MmSpace.s4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l.guessClue(i + 1),
                            style: theme.textTheme.labelLarge?.copyWith(color: palette.textMuted),
                          ),
                          const SizedBox(height: MmSpace.s1),
                          Text(item.clues[i], style: theme.textTheme.titleLarge),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: MmSpace.s3),
              ],
              if (cur.outcome == GuessOutcome.got)
                PopIn(
                  key: ValueKey('${cur.questionId}-got'),
                  child: Text(outcome!, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
                )
              else
                // Bumps each time another clue lowers what the card is worth.
                Bump(
                  value: '${cur.questionId}-${cur.cluesShown}-${cur.outcome}',
                  amount: 0.15,
                  child: Text(
                    outcome ?? l.guessWorth(pointsFor(cur.cluesShown)),
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
          if (cur.outcome == GuessOutcome.got)
            Positioned.fill(child: Confetti(key: ValueKey('${cur.questionId}-confetti'), pieces: 36)),
        ],
      ),
      bottom: decided
          ? Pressable(
              child: FilledButton(
                onPressed: () => act(GuessAction.next),
                child: Text(session.isLastRound ? l.playFinish : l.playNext),
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Pressable(
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => act(GuessAction.got),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(l.guessGotIt),
                    ),
                  ),
                ),
                const SizedBox(height: MmSpace.s2),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: cur.cluesShown < cluesPerCard ? () => act(GuessAction.clue) : null,
                        child: Text(l.guessNextClue),
                      ),
                    ),
                    const SizedBox(width: MmSpace.s3),
                    Expanded(
                      child: OutlinedButton(onPressed: () => act(GuessAction.reveal), child: Text(l.guessGiveUp)),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}
