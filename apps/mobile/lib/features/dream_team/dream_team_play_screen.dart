import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/dream_team_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../state/dream_team.dart';
import '../../state/progress.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/game_shell.dart';
import '../../widgets/insets.dart';
import '../../widgets/motion.dart';
import '../../widgets/progress_widgets.dart';
import 'card_photo.dart';

/// Dream Team: the draft, the pass-the-phone handover, the room's vote and the verdict.
class DreamTeamPlayScreen extends ConsumerStatefulWidget {
  const DreamTeamPlayScreen({super.key});

  @override
  ConsumerState<DreamTeamPlayScreen> createState() => _DreamTeamPlayScreenState();
}

class _DreamTeamPlayScreenState extends ConsumerState<DreamTeamPlayScreen> {
  /// The drawn card has been flipped face up by the side on turn.
  bool _flipped = false;

  /// Waiting for the phone to reach the other side before their card can be flipped.
  bool _handover = false;

  void _act(DreamTeamAction action) {
    final before = ref.read(dreamTeamProvider)?.state;
    ref.read(dreamTeamProvider.notifier).dispatch(action);
    final after = ref.read(dreamTeamProvider)?.state;
    if (after == null || before == null) return;
    setState(() {
      if (action is PlaceCard && after.status == DreamTeamStatus.drafting) {
        _flipped = false;
        // Only hand over when the turn actually moved to the other side.
        _handover = after.turn != before.turn;
      } else if (action is SkipCard) {
        _flipped = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final game = ref.watch(dreamTeamProvider);
    if (game == null) return const NoGameScreen();
    return switch (game.state.status) {
      DreamTeamStatus.drafting => _draft(context, game),
      DreamTeamStatus.voting => _vote(context, game),
      DreamTeamStatus.finished => _DreamTeamResults(game: game),
    };
  }

  Widget _draft(BuildContext context, DreamTeamGame game) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final s = game.state;
    final side = s.turn;
    final name = game.sides[side];
    final other = game.sides[1 - side];
    final card = game.card(s.drawn);
    final controller = ref.read(dreamTeamProvider.notifier);

    if (_handover) {
      return GameShell(
        title: l.dtDraftProgress(game.placed, game.slots),
        progress: game.placed / game.slots,
        onQuit: controller.clear,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(GfSpace.s6),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.sync_alt_rounded, size: 64, color: theme.colorScheme.primary),
                const SizedBox(height: GfSpace.s4),
                Text(l.dtPassTo(name), textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                const SizedBox(height: GfSpace.s2),
                Text(
                  l.dtPassBody,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: palette.textMuted),
                ),
              ],
            ),
          ),
        ),
        bottom: Pressable(
          child: FilledButton(onPressed: () => setState(() => _handover = false), child: Text(l.dtReady(name))),
        ),
      );
    }

    return GameShell(
      title: l.dtDraftProgress(game.placed, game.slots),
      progress: game.placed / game.slots,
      onQuit: controller.clear,
      body: ListView(
        padding: listPadding(context, const EdgeInsets.fromLTRB(GfSpace.s4, GfSpace.s2, GfSpace.s4, GfSpace.s4)),
        children: [
          Text(l.dtTurn(name), textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
          const SizedBox(height: GfSpace.s3),
          if (card != null)
            _FlipCard(
              key: ValueKey(card.id),
              card: card,
              flipped: _flipped,
              onFlip: () => setState(() => _flipped = true),
            ),
          const SizedBox(height: GfSpace.s2),
          Text(
            _flipped ? l.dtPlaceHint : l.dtFlipFirst,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted),
          ),
          const SizedBox(height: GfSpace.s3),
          _TeamSlots(
            title: l.dtYourTeam,
            game: game,
            side: side,
            onTapEmpty: _flipped ? (slot) => _act(PlaceCard(slot)) : null,
          ),
          const SizedBox(height: GfSpace.s3),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(l.dtTheirTeam(other)),
            children: [_TeamSlots(game: game, side: 1 - side, compact: true)],
          ),
        ],
      ),
      bottom: Pressable(
        enabled: _flipped && s.skipsLeft[side] > 0,
        child: OutlinedButton(
          onPressed: _flipped && s.skipsLeft[side] > 0 ? () => _act(const SkipCard()) : null,
          child: Text(s.skipsLeft[side] > 0 ? l.dtSkip(s.skipsLeft[side]) : l.dtNoSkips),
        ),
      ),
    );
  }

  Widget _vote(BuildContext context, DreamTeamGame game) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final s = game.state;
    final roles = s.config.roles;
    final controller = ref.read(dreamTeamProvider.notifier);
    final slot = s.votes.indexWhere((v) => v == null);
    final done = slot == -1;
    final shown = done ? roles.length - 1 : slot;
    final role = roles[shown];

    return GameShell(
      title: l.dtVoteProgress(shown + 1, roles.length),
      progress: s.votes.where((v) => v != null).length / roles.length,
      onQuit: controller.clear,
      body: ListView(
        padding: listPadding(context, const EdgeInsets.fromLTRB(GfSpace.s4, GfSpace.s2, GfSpace.s4, GfSpace.s4)),
        children: [
          Text(l.dtVoteTitle(role.name), textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
          const SizedBox(height: GfSpace.s1),
          Text(
            l.dtVoteHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted),
          ),
          const SizedBox(height: GfSpace.s4),
          for (var side = 0; side < 2; side++) ...[
            _VoteCard(
              key: ValueKey('vote-$shown-$side'),
              sideName: game.sides[side],
              card: game.card(s.teams[side][shown])!,
              color: side == 0 ? palette.optionA : palette.optionB,
              picked: s.votes[shown] == side,
              onTap: () => _act(VoteSlot(shown, side)),
            ),
            if (side == 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: GfSpace.s2),
                child: Text('vs', textAlign: TextAlign.center, style: theme.textTheme.titleLarge),
              ),
          ],
        ],
      ),
      bottom: Pressable(
        enabled: done,
        child: FilledButton(onPressed: done ? () => _act(const FinishVoting()) : null, child: Text(l.dtSeeVerdict)),
      ),
    );
  }
}

/// The drawn card: face down until tapped, then flips to show the character.
class _FlipCard extends StatelessWidget {
  const _FlipCard({super.key, required this.card, required this.flipped, required this.onFlip});

  final DreamTeamCard card;
  final bool flipped;
  final VoidCallback onFlip;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final reduce = MediaQuery.of(context).disableAnimations;

    Widget face(bool up) => Container(
      key: ValueKey(up),
      constraints: const BoxConstraints(minHeight: 170),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(GfSpace.s4),
      decoration: BoxDecoration(
        gradient: up ? null : palette.gradient,
        color: up ? theme.colorScheme.surface : null,
        borderRadius: BorderRadius.circular(GfRadius.xl),
        border: Border.all(color: up ? theme.colorScheme.primary : Colors.transparent, width: 3),
      ),
      child: up
          ? Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (card.photo != null) ...[
                  CardPhoto(path: card.photo, name: card.name, size: 140, radius: GfRadius.lg),
                  const SizedBox(height: GfSpace.s3),
                ],
                Text(card.name, textAlign: TextAlign.center, style: theme.textTheme.headlineSmall),
                if (card.blurb != null) ...[
                  const SizedBox(height: GfSpace.s2),
                  Text(
                    card.blurb!,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: palette.textMuted),
                  ),
                ],
              ],
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '?',
                  style: TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.w800),
                ),
                Text(
                  l.dtTapToFlip,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ],
            ),
    );

    return Semantics(
      button: !flipped,
      label: flipped ? null : l.dtTapToFlip,
      child: GestureDetector(
        onTap: flipped ? null : onFlip,
        child: AnimatedSwitcher(
          duration: reduce ? Duration.zero : const Duration(milliseconds: 380),
          transitionBuilder: (child, anim) => AnimatedBuilder(
            animation: anim,
            child: child,
            builder: (context, child) {
              final angle = (1 - anim.value) * pi / 2;
              return Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateY(angle),
                child: child,
              );
            },
          ),
          child: face(flipped),
        ),
      ),
    );
  }
}

/// One side's role slots. Empty slots are tappable while placing.
class _TeamSlots extends StatelessWidget {
  const _TeamSlots({required this.game, required this.side, this.title, this.onTapEmpty, this.compact = false});

  final DreamTeamGame game;
  final int side;
  final String? title;
  final void Function(int slot)? onTapEmpty;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final roles = game.state.config.roles;
    final team = game.state.teams[side];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (title != null)
          Padding(
            padding: const EdgeInsets.only(bottom: GfSpace.s2),
            child: Text(title!, style: theme.textTheme.titleMedium),
          ),
        for (var i = 0; i < roles.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: GfSpace.s2),
            // Each role is its own item for screen readers ("Healer: Empty", a button while placing).
            child: Semantics(
              container: true,
              button: team[i] == null && onTapEmpty != null,
              child: Material(
                color: team[i] == null && onTapEmpty != null
                    ? theme.colorScheme.primary.withValues(alpha: 0.08)
                    : palette.surfaceMuted,
                borderRadius: BorderRadius.circular(GfRadius.md),
                child: InkWell(
                  borderRadius: BorderRadius.circular(GfRadius.md),
                  onTap: team[i] == null && onTapEmpty != null ? () => onTapEmpty!(i) : null,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: GfSpace.s3, vertical: compact ? GfSpace.s2 : GfSpace.s3),
                    child: Row(
                      children: [
                        SizedBox(width: 110, child: Text(roles[i].name, style: theme.textTheme.labelLarge)),
                        Expanded(
                          child: team[i] == null
                              ? Text(l.dtEmptySlot, style: TextStyle(color: palette.textMuted))
                              : PopIn(
                                  child: Row(
                                    children: [
                                      if (game.card(team[i])!.photo != null) ...[
                                        CardPhoto(
                                          path: game.card(team[i])!.photo,
                                          name: game.card(team[i])!.name,
                                          size: 32,
                                        ),
                                        const SizedBox(width: GfSpace.s2),
                                      ],
                                      Flexible(
                                        child: Text(
                                          game.card(team[i])!.name,
                                          style: const TextStyle(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                        if (team[i] == null && onTapEmpty != null)
                          Icon(Icons.add_circle_outline_rounded, color: theme.colorScheme.primary),
                        if (team[i] != null) Icon(Icons.lock_rounded, size: 16, color: palette.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _VoteCard extends StatelessWidget {
  const _VoteCard({
    super.key,
    required this.sideName,
    required this.card,
    required this.color,
    required this.picked,
    required this.onTap,
  });

  final String sideName;
  final DreamTeamCard card;
  final Color color;
  final bool picked;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = GfPalette.of(context);
    final theme = Theme.of(context);
    return Pressable(
      child: Material(
        color: color,
        borderRadius: BorderRadius.circular(GfRadius.xl),
        child: InkWell(
          borderRadius: BorderRadius.circular(GfRadius.xl),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(GfSpace.s4),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: palette.onOption),
              child: Column(
                children: [
                  Text(
                    sideName,
                    style: TextStyle(color: palette.onOption, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: GfSpace.s1),
                  if (card.photo != null) ...[
                    CardPhoto(path: card.photo, name: card.name, size: 96, radius: GfRadius.md),
                    const SizedBox(height: GfSpace.s2),
                  ],
                  Text(
                    card.name,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall?.copyWith(color: palette.onOption),
                  ),
                  if (card.blurb != null)
                    Text(
                      card.blurb!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: palette.onOption),
                    ),
                  if (picked) ...[
                    const SizedBox(height: GfSpace.s1),
                    Icon(Icons.check_circle_rounded, color: palette.onOption),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The verdict: the room's vote, then what the hidden stats say.
class _DreamTeamResults extends ConsumerWidget {
  const _DreamTeamResults({required this.game});

  final DreamTeamGame game;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final r = dreamTeamResults(game.state, game.cardsById);
    final roles = game.state.config.roles;
    final controller = ref.read(dreamTeamProvider.notifier);

    String verdict(DreamTeamVerdict v, String Function(String, int, int) win, String Function(int, int) tie) {
      final w = v.winner;
      return w == null ? tie(v.scores[0], v.scores[1]) : win(game.sides[w], v.scores[w], v.scores[1 - w]);
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text(l.dtResultsTitle),
        actions: [
          IconButton(
            tooltip: l.resultsHome,
            icon: const Icon(Icons.home_outlined),
            onPressed: () {
              ref.read(lastRewardProvider.notifier).clear();
              controller.clear();
              context.go('/');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: listPadding(context, const EdgeInsets.all(GfSpace.s4)),
            children: [
              Text(
                verdict(r.room, l.dtRoomWins, l.dtRoomTie),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: GfSpace.s3),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(GfSpace.s4),
                  child: r.stats == null
                      ? Text(l.dtNoStats, textAlign: TextAlign.center)
                      : Column(
                          children: [
                            Text(
                              verdict(r.stats!, l.dtStatsWins, l.dtStatsTie),
                              textAlign: TextAlign.center,
                              style: theme.textTheme.titleMedium,
                            ),
                            const SizedBox(height: GfSpace.s1),
                            Text(
                              r.stats!.winner == r.room.winner ? l.dtStatsAgree : l.dtStatsDisagree,
                              textAlign: TextAlign.center,
                              style: TextStyle(color: palette.textMuted),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: GfSpace.s3),
              for (var i = 0; i < roles.length; i++)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: GfSpace.s4, vertical: GfSpace.s3),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(roles[i].name, style: theme.textTheme.labelLarge?.copyWith(color: palette.textMuted)),
                        const SizedBox(height: GfSpace.s1),
                        for (var side = 0; side < 2; side++)
                          Row(
                            children: [
                              Icon(
                                game.state.votes[i] == side ? Icons.emoji_events_rounded : Icons.circle_outlined,
                                size: 18,
                                color: game.state.votes[i] == side ? palette.accent : palette.textMuted,
                              ),
                              const SizedBox(width: GfSpace.s2),
                              if (game.card(game.state.teams[side][i])!.photo != null) ...[
                                CardPhoto(
                                  path: game.card(game.state.teams[side][i])!.photo,
                                  name: game.card(game.state.teams[side][i])!.name,
                                  size: 28,
                                ),
                                const SizedBox(width: GfSpace.s2),
                              ],
                              Expanded(
                                child: Text(
                                  '${game.sides[side]}: ${game.card(game.state.teams[side][i])!.name}',
                                  style: TextStyle(fontWeight: game.state.votes[i] == side ? FontWeight.w700 : null),
                                ),
                              ),
                              if (r.slotStats[i] != null)
                                Text('${r.slotStats[i]![side]}', style: theme.textTheme.titleMedium),
                            ],
                          ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: GfSpace.s3),
              const RewardCard(),
              const SizedBox(height: GfSpace.s4),
              Pressable(
                child: FilledButton(
                  onPressed: () {
                    ref.read(lastRewardProvider.notifier).clear();
                    controller.restart();
                  },
                  child: Text(l.dtPlayAgain),
                ),
              ),
            ],
          ),
          const Positioned.fill(child: IgnorePointer(child: Confetti())),
        ],
      ),
    );
  }
}
