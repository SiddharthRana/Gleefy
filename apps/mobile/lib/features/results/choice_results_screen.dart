import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/content.dart';
import '../../game/wyr_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../state/providers.dart';
import '../../state/games.dart';
import '../../state/sessions.dart';
import '../../widgets/results_actions.dart';
import '../../widgets/motion.dart';
import '../../widgets/progress_widgets.dart';
import '../../widgets/usage_prompt.dart';
import '../modes.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/brand.dart';

/// Results for the two-choice modes (Would You Rather and This or That).
class ChoiceResultsScreen extends ConsumerWidget {
  const ChoiceResultsScreen({super.key, required this.mode});

  final GameMode mode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final provider = mode == GameMode.wouldYouRather ? wyrSessionProvider : totSessionProvider;
    final session = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final pack = ref.watch(contentProvider).packFor(mode) as Pack<WyrItem>;

    if (session == null || session.status != WyrStatus.finished) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: FilledButton(onPressed: () => context.go('/'), child: Text(l.goHome)),
        ),
      );
    }

    final results = wyrResults(session);
    final names = controller.names;
    final sync = names.length >= 2 ? bestAgreement(session.rounds, names.length) : null;
    WyrRound? roundFor(String? id) => id == null ? null : session.rounds.firstWhere((r) => r.questionId == id);

    return Scaffold(
      appBar: AppBar(
        title: Text(l.resultsTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: l.resultsHome,
            icon: const Icon(Icons.home_outlined),
            onPressed: () {
              controller.clear();
              ref.read(partyProvider.notifier).stop();
              context.go('/');
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(GfSpace.s4),
            children: [
              PopIn(
                child: GradientPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(modeName(l, mode), style: theme.textTheme.titleMedium?.copyWith(color: Colors.white)),
                      const SizedBox(height: GfSpace.s1),
                      Text(
                        l.resultsSummary(results.roundsPlayed, results.totalVotes),
                        style: theme.textTheme.headlineSmall?.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
              const RewardCard(),
              const UsagePrompt(),
              if (sync != null) ...[
                const SizedBox(height: GfSpace.s4),
                Card(
                  child: ListTile(
                    leading: Icon(Icons.favorite_rounded, color: theme.colorScheme.primary),
                    title: Text(l.totInSync(names[sync.players.$1], names[sync.players.$2])),
                    subtitle: Text(l.totInSyncBody(sync.matches, sync.rounds)),
                  ),
                ),
              ],
              if (results.mostDivisive case final id?) ...[
                const SizedBox(height: GfSpace.s4),
                _Highlight(
                  title: l.resultsDivisive,
                  icon: Icons.balance_rounded,
                  item: pack.item(id)!,
                  round: roundFor(id)!,
                ),
              ],
              if (results.mostUnanimous case final id?) ...[
                const SizedBox(height: GfSpace.s3),
                _Highlight(
                  title: l.resultsUnanimous,
                  icon: Icons.groups_rounded,
                  item: pack.item(id)!,
                  round: roundFor(id)!,
                ),
              ],
              const SizedBox(height: GfSpace.s6),
              Semantics(header: true, child: Text(l.resultsAllRounds, style: theme.textTheme.titleLarge)),
              const SizedBox(height: GfSpace.s2),
              for (final (i, r) in session.rounds.indexed)
                if (pack.item(r.questionId) case final item?) _RoundRow(index: i + 1, item: item, round: r),
            ],
          ),
          // A one-off celebration when the results appear.
          const Positioned.fill(child: Confetti()),
        ],
      ),
      bottomNavigationBar: ResultsActions(mode: mode, onPlayAgain: controller.restart, onClear: controller.clear),
    );
  }
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.title, required this.icon, required this.item, required this.round});

  final String title;
  final IconData icon;
  final WyrItem item;
  final WyrRound round;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(GfSpace.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary),
                const SizedBox(width: GfSpace.s2),
                Text(title, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
              ],
            ),
            const SizedBox(height: GfSpace.s3),
            _SplitBar(item: item, round: round),
          ],
        ),
      ),
    );
  }
}

class _RoundRow extends StatelessWidget {
  const _RoundRow({required this.index, required this.item, required this.round});

  final int index;
  final WyrItem item;
  final WyrRound round;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: GfSpace.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            child: Text('$index', style: theme.textTheme.titleMedium?.copyWith(color: palette.textMuted)),
          ),
          Expanded(
            child: round.skipped
                ? Text(
                    '${item.a} / ${item.b} — ${l.resultsSkipped}',
                    style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted),
                  )
                : _SplitBar(item: item, round: round),
          ),
        ],
      ),
    );
  }
}

/// Both options with their vote counts and a two-colour bar showing the split.
class _SplitBar extends StatelessWidget {
  const _SplitBar({required this.item, required this.round});

  final WyrItem item;
  final WyrRound round;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    return Semantics(
      label: '${item.a}: ${l.playVotes(round.a)}. ${item.b}: ${l.playVotes(round.b)}.',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(item.a, style: theme.textTheme.bodyMedium)),
              const SizedBox(width: GfSpace.s3),
              Text(l.resultsSplit(round.a, round.b), style: theme.textTheme.labelLarge),
              const SizedBox(width: GfSpace.s3),
              Expanded(
                child: Text(item.b, style: theme.textTheme.bodyMedium, textAlign: TextAlign.end),
              ),
            ],
          ),
          const SizedBox(height: GfSpace.s2),
          ClipRRect(
            borderRadius: BorderRadius.circular(GfRadius.pill),
            child: SizedBox(
              height: 10,
              child: round.total == 0
                  ? ColoredBox(color: palette.surfaceMuted)
                  : Row(
                      children: [
                        if (round.a > 0)
                          Expanded(
                            flex: round.a,
                            child: ColoredBox(color: palette.optionA),
                          ),
                        if (round.b > 0)
                          Expanded(
                            flex: round.b,
                            child: ColoredBox(color: palette.optionB),
                          ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
