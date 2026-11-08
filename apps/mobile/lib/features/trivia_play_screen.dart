import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../content/content.dart';
import '../game/trivia_engine.dart';
import '../l10n/app_localizations.dart';
import '../state/games.dart';
import '../state/providers.dart';
import '../state/sessions.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import '../widgets/countdown.dart';
import '../widgets/game_shell.dart';
import '../widgets/motion.dart';

const _letters = ['A', 'B', 'C', 'D'];

class TriviaPlayScreen extends ConsumerStatefulWidget {
  const TriviaPlayScreen({super.key});

  @override
  ConsumerState<TriviaPlayScreen> createState() => _TriviaPlayScreenState();
}

class _TriviaPlayScreenState extends ConsumerState<TriviaPlayScreen> {
  final _countdown = Countdown();
  String? _timedQuestion;

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }

  void _act(TriviaAction action) {
    ref.read(triviaSessionProvider.notifier).dispatch(action);
    if (action is Answer || action is TimeUp) _countdown.stop();
    if (ref.read(triviaSessionProvider)?.status == SessionStatus.finished) {
      context.pushReplacement(resultsRoute(GameMode.trivia));
    }
  }

  void _syncTimer(TriviaState s, TriviaCurrent cur) {
    if (s.config.timeLimitMs <= 0) return;
    if (cur.answered) {
      _countdown.stop();
      return;
    }
    if (_timedQuestion == cur.questionId) return;
    _timedQuestion = cur.questionId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _countdown.start(s.config.timeLimitMs, () => _act(const TimeUp()));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final session = ref.watch(triviaSessionProvider);
    final cur = session?.current;
    final item = cur == null ? null : ref.watch(contentProvider).trivia.item(cur.questionId);
    if (session == null || cur == null || item == null) return const NoGameScreen();
    _syncTimer(session, cur);

    final names = ref.read(triviaSessionProvider.notifier).names;
    final player = cur.team < names.length ? names[cur.team] : l.everyone;
    final correctText = item.choices[cur.answer];

    String? feedback;
    if (cur.timedOut) {
      feedback = l.triviaTimeUp;
    } else if (cur.picked != null) {
      feedback = cur.picked == cur.answer ? l.triviaCorrect(cur.points) : l.triviaWrong;
    }

    return GameShell(
      title: l.questionOf(session.roundNumber, session.totalRounds),
      progress: session.rounds.length / session.totalRounds,
      onQuit: ref.read(triviaSessionProvider.notifier).clear,
      actions: [
        if (!cur.answered)
          TextButton(
            onPressed: () => _act(const SkipTrivia()),
            child: Tooltip(message: l.playSkipTooltip, child: Text(l.playSkip)),
          ),
      ],
      body: ListView(
        padding: const EdgeInsets.all(GfSpace.s4),
        children: [
          Text(
            names.isEmpty ? l.everyone : l.turnOf(player),
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
            textAlign: TextAlign.center,
          ),
          if (session.config.timeLimitMs > 0 && !cur.answered) ...[
            const SizedBox(height: GfSpace.s3),
            CountdownBar(countdown: _countdown),
          ],
          const SizedBox(height: GfSpace.s4),
          Text(item.question, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
          const SizedBox(height: GfSpace.s6),
          for (final (pos, index) in cur.choiceOrder.indexed) ...[
            // Choices deal in one by one for each question; the right one pops, a wrong pick shakes.
            StaggerIn(
              key: ValueKey('${cur.questionId}-$pos'),
              index: pos,
              child: Shake(
                shake: cur.answered && index == cur.picked && index != cur.answer,
                child: Bump(
                  value: cur.answered && index == cur.answer,
                  amount: 0.06,
                  child: Pressable(
                    enabled: !cur.answered,
                    scale: 0.97,
                    child: _Choice(
                      letter: _letters[pos],
                      text: item.choices[index],
                      state: !cur.answered
                          ? _ChoiceState.open
                          : index == cur.answer
                          ? _ChoiceState.correct
                          : index == cur.picked
                          ? _ChoiceState.wrong
                          : _ChoiceState.dimmed,
                      onTap: () {
                        if (ref.read(settingsProvider).haptics) HapticFeedback.selectionClick();
                        _act(Answer(pos, _countdown.elapsedMs));
                      },
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: GfSpace.s3),
          ],
          if (feedback != null) ...[
            const SizedBox(height: GfSpace.s2),
            Semantics(
              liveRegion: true,
              child: PopIn(
                child: Text(feedback, style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
              ),
            ),
            if (cur.picked != cur.answer) ...[
              const SizedBox(height: GfSpace.s1),
              Text(l.triviaAnswerWas(correctText), textAlign: TextAlign.center, style: theme.textTheme.titleMedium),
            ],
            const SizedBox(height: GfSpace.s2),
            Text(
              item.explanation,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted),
            ),
          ],
        ],
      ),
      bottom: Pressable(
        child: FilledButton(
          onPressed: cur.answered ? () => _act(const NextQuestion()) : null,
          child: Text(session.isLastRound ? l.playFinish : l.playNext),
        ),
      ),
    );
  }
}

enum _ChoiceState { open, correct, wrong, dimmed }

class _Choice extends StatelessWidget {
  const _Choice({required this.letter, required this.text, required this.state, required this.onTap});

  final String letter;
  final String text;
  final _ChoiceState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final (border, icon) = switch (state) {
      _ChoiceState.correct => (palette.success, Icons.check_circle_rounded),
      _ChoiceState.wrong => (theme.colorScheme.error, Icons.cancel_rounded),
      _ => (theme.colorScheme.outline, null),
    };
    return Semantics(
      button: state == _ChoiceState.open,
      label: l.triviaChoice(letter, text),
      excludeSemantics: true,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GfRadius.lg),
          side: BorderSide(color: border, width: state == _ChoiceState.open || state == _ChoiceState.dimmed ? 1.5 : 3),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: state == _ChoiceState.open ? onTap : null,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: GfTouch.game + 8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: GfSpace.s4, vertical: GfSpace.s3),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    child: Text(letter, style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: GfSpace.s3),
                  Expanded(child: Text(text, style: theme.textTheme.titleMedium)),
                  if (icon != null) Icon(icon, color: border),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
