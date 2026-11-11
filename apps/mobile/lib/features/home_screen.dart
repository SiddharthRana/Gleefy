import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../content/content.dart';
import '../game/wyr_engine.dart' show EmptyPoolException;
import '../l10n/app_localizations.dart';
import '../state/games.dart';
import '../state/providers.dart';
import '../state/sessions.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import '../widgets/progress_widgets.dart';
import '../widgets/brand.dart';
import '../widgets/mode_tile.dart';
import '../widgets/motion.dart';
import 'modes.dart';
import '../widgets/insets.dart';

/// A game in progress that Home can offer to resume.
typedef _InProgress = ({GameMode mode, int round, int total, VoidCallback discard});

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  void _quickPlay(BuildContext context, WidgetRef ref) {
    final pack = ref.read(contentProvider).wyr;
    final free = pack.categories.where((c) => c.tier == Tier.free && c.region == 'global').map((c) => c.id).toList();
    final route = ref
        .read(gameStarterProvider)
        .start(GameSetup(mode: GameMode.wouldYouRather, categoryIds: free, rounds: 10));
    context.push(route);
  }

  void _play(BuildContext context, WidgetRef ref, SavedGame game) {
    try {
      final route = game.isParty
          ? ref.read(partyProvider.notifier).start(game.setups)
          : ref.read(gameStarterProvider).start(game.setups.first);
      context.push(route);
    } on EmptyPoolException {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).errorEmptyCategories)));
    }
  }

  _InProgress? _inProgress(WidgetRef ref) {
    _InProgress? check<S>(NotifierProvider<PersistedSession<S>, S?> p) {
      final s = ref.watch(p);
      final c = ref.read(p.notifier);
      if (s == null || !c.isPlaying(s)) return null;
      return (mode: c.mode, round: c.roundNumber(s), total: c.totalRounds(s), discard: c.clear);
    }

    return check(wyrSessionProvider) ??
        check(totSessionProvider) ??
        check(triviaSessionProvider) ??
        check(guessSessionProvider);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final game = _inProgress(ref);
    final favourites = ref.watch(favouritesProvider);
    final recents = ref.watch(recentsProvider);

    String describe(SavedGame g) => g.isParty ? l.partyLabel(g.setups.length) : modeName(l, g.setups.first.mode);

    return Scaffold(
      appBar: AppBar(
        title: GleefyWordmark(size: 22, premium: ref.watch(premiumProvider)),
        actions: [
          IconButton(
            tooltip: l.playersTitle,
            icon: const Icon(Icons.groups_outlined),
            onPressed: () => context.push('/players'),
          ),
          IconButton(
            tooltip: l.settings,
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: listPadding(context, const EdgeInsets.fromLTRB(GfSpace.s4, GfSpace.s2, GfSpace.s4, GfSpace.s8)),
        children: [
          Text(l.homeGreeting, style: theme.textTheme.headlineMedium),
          const SizedBox(height: GfSpace.s4),
          if (game != null) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(GfSpace.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.homeResumeTitle, style: theme.textTheme.titleMedium),
                    const SizedBox(height: GfSpace.s1),
                    Text(
                      l.homeResumeBody(modeName(l, game.mode), game.round, game.total),
                      style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted),
                    ),
                    const SizedBox(height: GfSpace.s3),
                    Row(
                      children: [
                        FilledButton(onPressed: () => context.push(playRoute(game.mode)), child: Text(l.homeResume)),
                        const SizedBox(width: GfSpace.s2),
                        TextButton(
                          onPressed: () {
                            game.discard();
                            ref.read(partyProvider.notifier).stop();
                          },
                          child: Text(l.homeDiscard),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: GfSpace.s4),
          ],
          const ProgressCard(),
          const SizedBox(height: GfSpace.s4),
          Pressable(
            scale: 0.97,
            child: GradientPanel(
              onTap: () => _quickPlay(context, ref),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l.homeQuickPlay, style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white)),
                        const SizedBox(height: GfSpace.s2),
                        Text(l.homeQuickPlayBody, style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white)),
                      ],
                    ),
                  ),
                  const SizedBox(width: GfSpace.s4),
                  const PopIn(
                    delay: Duration(milliseconds: 200),
                    child: Icon(Icons.play_circle_fill_rounded, size: 56),
                  ),
                ],
              ),
            ),
          ),
          if (favourites.isNotEmpty) ...[
            const SizedBox(height: GfSpace.s8),
            Semantics(header: true, child: Text(l.homeFavourites, style: theme.textTheme.titleLarge)),
            const SizedBox(height: GfSpace.s2),
            for (final f in favourites)
              Card(
                margin: const EdgeInsets.only(bottom: GfSpace.s2),
                child: ListTile(
                  leading: Icon(Icons.star_rounded, color: palette.accent),
                  title: Text(f.name),
                  subtitle: Text(describe(f)),
                  onTap: () => _play(context, ref, f),
                  trailing: IconButton(
                    tooltip: l.homeRemove(f.name),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => ref.read(favouritesProvider.notifier).remove(f),
                  ),
                ),
              ),
          ],
          if (recents.isNotEmpty) ...[
            const SizedBox(height: GfSpace.s6),
            Semantics(header: true, child: Text(l.homeRecent, style: theme.textTheme.titleLarge)),
            const SizedBox(height: GfSpace.s2),
            Wrap(
              spacing: GfSpace.s2,
              runSpacing: GfSpace.s2,
              children: [
                for (final r in recents)
                  ActionChip(
                    avatar: const Icon(Icons.replay_rounded, size: 18),
                    label: Text(describe(r)),
                    onPressed: () => _play(context, ref, r),
                  ),
              ],
            ),
          ],
          const SizedBox(height: GfSpace.s8),
          Row(
            children: [
              Expanded(child: Text(l.homeAllGames, style: theme.textTheme.titleLarge)),
              TextButton(onPressed: () => context.push('/games'), child: Text(l.homeSeeAll)),
            ],
          ),
          const SizedBox(height: GfSpace.s2),
          for (final (i, entry) in LibraryEntry.values.take(3).indexed) ...[
            StaggerIn(
              index: i,
              child: ModeTile(entry: entry),
            ),
            const SizedBox(height: GfSpace.s3),
          ],
        ],
      ),
    );
  }
}
