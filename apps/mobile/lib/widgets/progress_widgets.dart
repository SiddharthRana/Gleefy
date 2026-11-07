import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../game/progress.dart';
import '../l10n/app_localizations.dart';
import '../state/progress.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import 'motion.dart';

/// Name, description and icon for each trophy id from lib/game/progress.dart (same as the website).
({String name, String body, String icon}) trophyText(AppLocalizations l, String id) => switch (id) {
  'first-game' => (name: l.trophyFirstGame, body: l.trophyFirstGameBody, icon: '🎉'),
  'regular' => (name: l.trophyRegular, body: l.trophyRegularBody, icon: '⭐'),
  'party-animal' => (name: l.trophyPartyAnimal, body: l.trophyPartyAnimalBody, icon: '🦄'),
  'all-modes' => (name: l.trophyAllModes, body: l.trophyAllModesBody, icon: '🧭'),
  'streak-3' => (name: l.trophyStreak3, body: l.trophyStreak3Body, icon: '🔥'),
  'streak-7' => (name: l.trophyStreak7, body: l.trophyStreak7Body, icon: '📅'),
  'marathon' => (name: l.trophyMarathon, body: l.trophyMarathonBody, icon: '🏃'),
  'know-it-all' => (name: l.trophyKnowItAll, body: l.trophyKnowItAllBody, icon: '🧠'),
  _ => (name: l.trophyRisingStar, body: l.trophyRisingStarBody, icon: '🚀'),
};

/// A round "LV n" badge, like a game's level counter.
class LevelBadge extends StatelessWidget {
  const LevelBadge({super.key, required this.level, this.size = 56});

  final int level;
  final double size;

  @override
  Widget build(BuildContext context) {
    final palette = MmPalette.of(context);
    return ExcludeSemantics(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: palette.gradient,
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), offset: const Offset(0, 3))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'LV',
              style: TextStyle(color: Colors.white, fontSize: size * 0.18, fontWeight: FontWeight.w800, height: 1),
            ),
            Text(
              '$level',
              style: TextStyle(
                color: Colors.white,
                fontFamily: 'Fredoka',
                fontSize: size * 0.4,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The XP bar towards the next level; it fills up when it first appears.
class XpBar extends ConsumerWidget {
  const XpBar({super.key, required this.into, required this.needed, this.height = 12});

  final int into;
  final int needed;
  final double height;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = MmPalette.of(context);
    final target = needed == 0 ? 0.0 : (into / needed).clamp(0.0, 1.0);
    final still = reduceMotionOf(context, ref);
    return ExcludeSemantics(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: Container(
          height: height,
          color: palette.surfaceMuted,
          alignment: Alignment.centerLeft,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: still ? target : 0, end: target),
            duration: still ? Duration.zero : const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => FractionallySizedBox(
              widthFactor: v,
              child: DecoratedBox(
                decoration: BoxDecoration(gradient: palette.gradient),
                child: const SizedBox.expand(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Level, XP, streak and trophies on Home. Tapping it opens the trophy room.
class ProgressCard extends ConsumerWidget {
  const ProgressCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = MmPalette.of(context);
    final progress = ref.watch(progressProvider);
    final streak = ref.watch(streakProvider);
    final lp = levelProgress(progress.xp);
    final fresh = progress.gamesPlayed == 0;
    return Pressable(
      scale: 0.97,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push('/trophies'),
          child: Semantics(
            button: true,
            label: l.progressSemantics(lp.level, lp.into, lp.needed, streak),
            excludeSemantics: true,
            child: Padding(
              padding: const EdgeInsets.all(MmSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      LevelBadge(level: lp.level),
                      const SizedBox(width: MmSpace.s4),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fresh ? l.progressStartTitle : l.progressLevel(lp.level),
                              style: theme.textTheme.titleLarge,
                            ),
                            const SizedBox(height: MmSpace.s2),
                            XpBar(into: lp.into, needed: lp.needed),
                            const SizedBox(height: MmSpace.s1),
                            Text(
                              l.progressXp(lp.into, lp.needed),
                              style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: MmSpace.s3),
                      Column(
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 24)),
                          Text('$streak', style: theme.textTheme.titleLarge),
                          Text(l.progressStreak, style: theme.textTheme.labelSmall?.copyWith(color: palette.textMuted)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: MmSpace.s3),
                  Text(
                    fresh
                        ? l.progressStartBody
                        : l.progressSummary(progress.trophies.length, allTrophies.length, progress.gamesPlayed),
                    style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// What the game that just finished earned: XP counting up, the level bar, level-ups and trophies.
class RewardCard extends ConsumerWidget {
  const RewardCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reward = ref.watch(lastRewardProvider);
    if (reward == null) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = MmPalette.of(context);
    final lp = levelProgress(reward.progress.xp);
    final still = reduceMotionOf(context, ref);
    return Padding(
      padding: const EdgeInsets.only(top: MmSpace.s4),
      child: PopIn(
        delay: const Duration(milliseconds: 250),
        child: Container(
          padding: const EdgeInsets.all(MmSpace.s4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(MmRadius.lg),
            border: Border.all(color: palette.accent, width: 2),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Semantics(
                      label: l.rewardXp(reward.xpGained),
                      excludeSemantics: true,
                      child: TweenAnimationBuilder<int>(
                        tween: IntTween(begin: still ? reward.xpGained : 0, end: reward.xpGained),
                        duration: still ? Duration.zero : const Duration(milliseconds: 800),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => Text(
                          l.rewardXp(v),
                          style: theme.textTheme.headlineMedium?.copyWith(color: theme.colorScheme.primary),
                        ),
                      ),
                    ),
                  ),
                  Bump(
                    value: lp.level,
                    child: LevelBadge(level: lp.level, size: 52),
                  ),
                ],
              ),
              const SizedBox(height: MmSpace.s3),
              XpBar(into: lp.into, needed: lp.needed, height: 14),
              const SizedBox(height: MmSpace.s1),
              Text(
                l.rewardToNext(lp.needed - lp.into, lp.level + 1),
                style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
              ),
              if (reward.leveledUp) ...[
                const SizedBox(height: MmSpace.s3),
                PopIn(
                  delay: const Duration(milliseconds: 600),
                  child: Container(
                    padding: const EdgeInsets.all(MmSpace.s3),
                    decoration: BoxDecoration(
                      gradient: palette.gradient,
                      borderRadius: BorderRadius.circular(MmRadius.md),
                    ),
                    child: Text(
                      l.rewardLevelUp(reward.levelAfter),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleLarge?.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ],
              if (reward.newTrophies.isNotEmpty) ...[
                const SizedBox(height: MmSpace.s3),
                Text(l.rewardNewTrophies(reward.newTrophies.length), style: theme.textTheme.titleMedium),
                const SizedBox(height: MmSpace.s2),
                for (final (i, id) in reward.newTrophies.indexed)
                  StaggerIn(
                    index: i + 4,
                    child: TrophyTile(id: id, earned: true),
                  ),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(onPressed: () => context.push('/trophies'), child: Text(l.trophiesSee)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// One trophy: its icon, name and what earns it; locked ones are greyed out.
class TrophyTile extends StatelessWidget {
  const TrophyTile({super.key, required this.id, required this.earned});

  final String id;
  final bool earned;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final palette = MmPalette.of(context);
    final t = trophyText(l, id);
    return Card(
      margin: const EdgeInsets.only(bottom: MmSpace.s2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MmRadius.md),
        side: BorderSide(color: earned ? palette.accent : palette.surfaceMuted, width: 2),
      ),
      child: ListTile(
        leading: CircleAvatar(
          radius: 24,
          backgroundColor: palette.surfaceMuted,
          child: Opacity(
            opacity: earned ? 1 : 0.5,
            child: Text(earned ? t.icon : '🔒', style: const TextStyle(fontSize: 24)),
          ),
        ),
        title: Text(t.name),
        subtitle: Text(earned ? t.body : '${t.body} ${l.trophyLocked}.'),
      ),
    );
  }
}
