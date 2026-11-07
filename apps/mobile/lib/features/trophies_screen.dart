import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../game/progress.dart';
import '../l10n/app_localizations.dart';
import '../state/progress.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import '../widgets/motion.dart';
import '../widgets/progress_widgets.dart';
import '../widgets/insets.dart';

/// The trophy room: level, stats and every trophy, earned or still locked.
class TrophiesScreen extends ConsumerWidget {
  const TrophiesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = MmPalette.of(context);
    final progress = ref.watch(progressProvider);
    final streak = ref.watch(streakProvider);
    final lp = levelProgress(progress.xp);
    final stats = [
      (l.statTotalXp, progress.xp),
      (l.statGames, progress.gamesPlayed),
      (l.statStreak, streak),
      (l.statBestStreak, progress.bestStreak),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l.trophiesTitle)),
      body: ListView(
        padding: listPadding(context, const EdgeInsets.all(MmSpace.s4)),
        children: [
          Text(l.trophiesIntro, style: theme.textTheme.bodyLarge?.copyWith(color: palette.textMuted)),
          const SizedBox(height: MmSpace.s4),
          PopIn(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(MmSpace.s4),
                child: Row(
                  children: [
                    LevelBadge(level: lp.level, size: 64),
                    const SizedBox(width: MmSpace.s4),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.progressLevel(lp.level), style: theme.textTheme.headlineSmall),
                          const SizedBox(height: MmSpace.s2),
                          XpBar(into: lp.into, needed: lp.needed, height: 14),
                          const SizedBox(height: MmSpace.s1),
                          Text(l.rewardToNext(lp.needed - lp.into, lp.level + 1)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: MmSpace.s3),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: MmSpace.s2,
            crossAxisSpacing: MmSpace.s2,
            childAspectRatio: 2,
            children: [
              for (final (label, value) in stats)
                Card(
                  margin: EdgeInsets.zero,
                  child: Semantics(
                    label: '$label: $value',
                    excludeSemantics: true,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('$value', style: theme.textTheme.headlineSmall),
                        Text(label, style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted)),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: MmSpace.s6),
          Semantics(
            header: true,
            child: Text(
              l.trophiesCount(progress.trophies.length, allTrophies.length),
              style: theme.textTheme.titleLarge,
            ),
          ),
          const SizedBox(height: MmSpace.s2),
          for (final (i, t) in allTrophies.indexed)
            StaggerIn(
              index: i,
              child: TrophyTile(id: t.id, earned: progress.trophies.contains(t.id)),
            ),
        ],
      ),
    );
  }
}
