import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../content/content.dart';
import '../game/wyr_engine.dart';
import '../l10n/app_localizations.dart';
import '../state/games.dart';
import '../state/providers.dart';
import '../state/sessions.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import '../widgets/game_shell.dart';
import '../widgets/motion.dart';
import '../widgets/option_card.dart';

/// Would You Rather: the host taps once per raised hand, then reveals the split.
class WyrPlayScreen extends ConsumerWidget {
  const WyrPlayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final session = ref.watch(wyrSessionProvider);
    final current = session?.current;
    final item = current == null ? null : ref.watch(contentProvider).wyr.item(current.questionId);
    if (session == null || current == null || item == null) return const NoGameScreen();

    final controller = ref.read(wyrSessionProvider.notifier);
    void act(WyrAction action) {
      if (action is Vote && ref.read(settingsProvider).haptics) HapticFeedback.selectionClick();
      controller.dispatch(action);
      if (ref.read(wyrSessionProvider)?.status == WyrStatus.finished) {
        context.pushReplacement(resultsRoute(GameMode.wouldYouRather));
      }
    }

    final reduceMotion = reduceMotionOf(context, ref);
    final cap = session.config.playerCount;
    final votes = current.votes.length;
    final full = cap != null && votes >= cap;
    final title = l.playRound(session.roundNumber, session.totalRounds);

    return GameShell(
      title: title,
      progress: session.rounds.length / session.totalRounds,
      onQuit: controller.clear,
      actions: [
        if (!current.revealed)
          TextButton(
            onPressed: () => act(const SkipQuestion()),
            child: Tooltip(message: l.playSkipTooltip, child: Text(l.playSkip)),
          ),
      ],
      body: AnimatedSwitcher(
        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
        child: _Question(
          key: ValueKey(item.id),
          item: item,
          current: current,
          full: full,
          reduceMotion: reduceMotion,
          onVote: (side) => act(Vote(side)),
        ),
      ),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            cap != null ? l.playVotesOfPlayers(votes, cap) : l.playVotes(votes),
            style: Theme.of(context).textTheme.labelLarge,
          ),
          const SizedBox(height: GfSpace.s2),
          Row(
            children: [
              if (!current.revealed) ...[
                OutlinedButton.icon(
                  onPressed: votes == 0 ? null : () => act(const Undo()),
                  icon: const Icon(Icons.undo_rounded),
                  label: Text(l.playUndo),
                ),
                const SizedBox(width: GfSpace.s3),
              ],
              Expanded(
                child: current.revealed
                    ? Pressable(
                        child: FilledButton(
                          onPressed: () => act(const Next()),
                          child: Text(session.isLastRound ? l.playFinish : l.playNext),
                        ),
                      )
                    : Pressable(
                        child: FilledButton(onPressed: () => act(const Reveal()), child: Text(l.playReveal)),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The verdict line shown after a reveal, or null when there's nothing special to say.
String? verdictFor(AppLocalizations l, int a, int b) {
  final total = a + b;
  if (total == 0) return l.playNoVotes;
  if (a == b) return l.playTie;
  if ((a == 0 || b == 0) && total > 1) return l.playUnanimous;
  return null;
}

class _Question extends StatelessWidget {
  const _Question({
    super.key,
    required this.item,
    required this.current,
    required this.full,
    required this.reduceMotion,
    required this.onVote,
  });

  final WyrItem item;
  final WyrCurrent current;
  final bool full;
  final bool reduceMotion;
  final ValueChanged<Side> onVote;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final a = current.count(Side.a);
    final b = current.count(Side.b);
    final verdict = current.revealed ? verdictFor(l, a, b) : null;

    Widget option(Side side) => Expanded(
      child: OptionCard(
        text: side == Side.a ? item.a : item.b,
        color: side == Side.a ? palette.optionA : palette.optionB,
        onColor: palette.onOption,
        votes: side == Side.a ? a : b,
        total: a + b,
        revealed: current.revealed,
        enabled: !current.revealed && !full,
        reduceMotion: reduceMotion,
        onTap: () => onVote(side),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(GfSpace.s4, GfSpace.s4, GfSpace.s4, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l.playPrompt, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: GfSpace.s1),
          Text(
            current.revealed ? (verdict ?? '') : l.playHint,
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: GfSpace.s4),
          option(Side.a),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: GfSpace.s2),
            child: Center(
              child: Text(l.playOr, style: theme.textTheme.titleLarge?.copyWith(color: palette.textMuted)),
            ),
          ),
          option(Side.b),
          const SizedBox(height: GfSpace.s2),
        ],
      ),
    );
  }
}
