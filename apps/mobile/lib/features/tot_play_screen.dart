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
import '../widgets/countdown.dart';
import '../widgets/game_shell.dart';
import '../widgets/motion.dart';
import '../widgets/option_card.dart';

const totTimeLimitMs = 5000;

/// This or That: one tap per pair for the room, or one tap per player when passing the phone.
class TotPlayScreen extends ConsumerStatefulWidget {
  const TotPlayScreen({super.key});

  @override
  ConsumerState<TotPlayScreen> createState() => _TotPlayScreenState();
}

class _TotPlayScreenState extends ConsumerState<TotPlayScreen> {
  final _countdown = Countdown();
  String? _timedTurn;
  bool _timedOut = false;

  @override
  void dispose() {
    _countdown.dispose();
    super.dispose();
  }

  bool get _timerOn => ref.read(sharedPreferencesProvider).getBool('session.tot.timer') ?? false;

  void _act(WyrAction action) {
    final controller = ref.read(totSessionProvider.notifier);
    if (action is Vote && ref.read(settingsProvider).haptics) HapticFeedback.selectionClick();
    controller.dispatch(action);
    final s = ref.read(totSessionProvider);
    if (s == null) return;
    if (s.status == WyrStatus.finished) {
      _countdown.stop();
      context.pushReplacement(resultsRoute(GameMode.thisOrThat));
      return;
    }
    final cur = s.current!;
    final players = s.config.playerCount;
    // Reveal as soon as the room (one tap) or every player (pass the phone) has picked.
    if (action is Vote && !cur.revealed && cur.votes.length >= (players ?? 1)) {
      controller.dispatch(const Reveal());
    }
    if (action is Next || action is SkipQuestion) _timedOut = false;
  }

  /// Starts a fresh countdown for each turn (each pair, or each player's pick).
  void _syncTimer(WyrCurrent cur) {
    if (!_timerOn) return;
    final turn = '${cur.questionId}/${cur.votes.length}';
    if (cur.revealed) {
      _countdown.stop();
      _timedTurn = null;
      return;
    }
    if (turn == _timedTurn) return;
    _timedTurn = turn;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _countdown.start(totTimeLimitMs, () {
        setState(() => _timedOut = true);
        ref.read(totSessionProvider.notifier).dispatch(const Reveal());
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final session = ref.watch(totSessionProvider);
    final cur = session?.current;
    final item = cur == null ? null : ref.watch(contentProvider).tot.item(cur.questionId);
    if (session == null || cur == null || item == null) return const NoGameScreen();
    _syncTimer(cur);

    final names = ref.read(totSessionProvider.notifier).names;
    final pass = session.config.playerCount != null && names.isNotEmpty;
    final turn = pass && cur.votes.length < names.length ? names[cur.votes.length] : null;
    final reduceMotion = reduceMotionOf(context, ref);
    final prompts = [l.totDiscuss1, l.totDiscuss2, l.totDiscuss3];
    final a = cur.count(Side.a);
    final b = cur.count(Side.b);

    String header;
    if (cur.revealed) {
      header = _timedOut && cur.votes.isEmpty ? l.totTimeUp : prompts[session.rounds.length % prompts.length];
    } else {
      header = turn != null ? l.totPickFor(turn) : l.totGroupPick;
    }

    Widget option(Side side) {
      final pickers = pass
          ? [
              for (final (i, v) in cur.votes.indexed)
                if (v == side && i < names.length) names[i],
            ]
          : const <String>[];
      return Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: OptionCard(
                text: side == Side.a ? item.a : item.b,
                color: side == Side.a ? palette.optionA : palette.optionB,
                onColor: palette.onOption,
                votes: side == Side.a ? a : b,
                total: a + b,
                revealed: cur.revealed,
                enabled: !cur.revealed,
                reduceMotion: reduceMotion,
                onTap: () => _act(Vote(side)),
              ),
            ),
            if (cur.revealed && pickers.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: GfSpace.s1),
                child: Text(pickers.join(', '), textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
              ),
          ],
        ),
      );
    }

    return GameShell(
      title: l.playRound(session.roundNumber, session.totalRounds),
      progress: session.rounds.length / session.totalRounds,
      onQuit: ref.read(totSessionProvider.notifier).clear,
      actions: [
        if (!cur.revealed && cur.votes.isEmpty)
          TextButton(
            onPressed: () => _act(const SkipQuestion()),
            child: Tooltip(message: l.playSkipTooltip, child: Text(l.playSkip)),
          ),
      ],
      body: Padding(
        padding: const EdgeInsets.fromLTRB(GfSpace.s4, GfSpace.s4, GfSpace.s4, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.totPrompt, style: theme.textTheme.headlineSmall, textAlign: TextAlign.center),
            const SizedBox(height: GfSpace.s1),
            Text(
              header,
              style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary),
              textAlign: TextAlign.center,
            ),
            if (_timerOn && !cur.revealed) ...[const SizedBox(height: GfSpace.s3), CountdownBar(countdown: _countdown)],
            const SizedBox(height: GfSpace.s4),
            option(Side.a),
            const SizedBox(height: GfSpace.s3),
            option(Side.b),
            const SizedBox(height: GfSpace.s2),
          ],
        ),
      ),
      bottom: Pressable(
        child: FilledButton(
          onPressed: cur.revealed ? () => _act(const Next()) : null,
          child: Text(session.isLastRound ? l.playFinish : l.playNext),
        ),
      ),
    );
  }
}
