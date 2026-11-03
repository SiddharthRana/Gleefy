import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../content/content.dart';
import '../game/wyr_engine.dart' show EmptyPoolException;
import '../l10n/app_localizations.dart';
import '../state/custom_questions.dart';
import '../state/games.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import '../widgets/setup_parts.dart';
import 'modes.dart';

const roundOptions = [5, 10, 15, 20];
const triviaTimers = [0, 10000, 20000, 30000];

/// Setup for any of the four modes: categories, rounds and the options that mode has.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key, required this.mode});

  final GameMode mode;

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  late Set<String> _selected;
  late int _rounds;
  int? _players;
  bool _timer = false;
  bool _pass = false;
  int _timeLimitMs = 20000;

  Pack<PoolItem> get _pack => ref.read(contentProvider).packFor(widget.mode);

  @override
  void initState() {
    super.initState();
    final premium = ref.read(premiumProvider);
    final playable = _pack.categories.where((c) => _playable(c, premium)).map((c) => c.id).toSet();
    final last = ref.read(gameStarterProvider).lastSetup(widget.mode);
    final remembered = last?.categoryIds.where(playable.contains).toSet() ?? {};
    _selected = remembered.isNotEmpty
        ? remembered
        : _pack.categories.where((c) => _playable(c, premium) && c.region == 'global').map((c) => c.id).toSet();
    _rounds = roundOptions.contains(last?.rounds) ? last!.rounds : 10;
    _players = last?.playerCount;
    _timer = last?.timer ?? false;
    _pass = last?.passThePhone ?? false;
    _timeLimitMs = triviaTimers.contains(last?.timeLimitMs) ? last!.timeLimitMs : 20000;
  }

  bool _playable(Category c, bool premium) => c.tier == Tier.free || premium;

  GameSetup get _setup => GameSetup(
    mode: widget.mode,
    categoryIds: _selected.toList()..sort(),
    rounds: _rounds,
    playerCount: widget.mode == GameMode.wouldYouRather ? _players : null,
    timer: _timer,
    passThePhone: _pass,
    timeLimitMs: _timeLimitMs,
  );

  void _start() {
    final String route;
    try {
      route = ref.read(gameStarterProvider).start(_setup);
    } on EmptyPoolException {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context).errorEmptyCategories)));
      return;
    }
    context.pushReplacement(route);
  }

  Future<void> _saveFavourite() async {
    final l = AppLocalizations.of(context);
    final name = await askName(context, initial: LibraryEntry.of(widget.mode).name(l));
    if (name == null || !mounted) return;
    ref.read(favouritesProvider.notifier).add(SavedGame(name: name, setups: [_setup]));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.favouriteSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = MmPalette.of(context);
    // Watched, so questions written from here appear when the person comes back.
    final pack = ref.watch(contentProvider).packFor(widget.mode);
    final premium = ref.watch(premiumProvider);
    final available = pack.countIn(_selected);
    final entry = LibraryEntry.of(widget.mode);
    final names = ref.watch(lineupProvider);
    final usesLineup = widget.mode != GameMode.wouldYouRather;

    return Scaffold(
      appBar: AppBar(
        title: Text(entry.name(l)),
        actions: [
          IconButton(
            tooltip: l.setupSaveFavourite,
            icon: const Icon(Icons.star_outline_rounded),
            onPressed: _selected.isEmpty ? null : _saveFavourite,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(MmSpace.s4, 0, MmSpace.s4, MmSpace.s6),
        children: [
          Card(
            color: palette.surfaceMuted,
            child: Padding(
              padding: const EdgeInsets.all(MmSpace.s4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.setupHowToPlay, style: theme.textTheme.titleMedium),
                  const SizedBox(height: MmSpace.s1),
                  Text(entry.rules(l)),
                ],
              ),
            ),
          ),
          if (usesLineup) ...[
            const SizedBox(height: MmSpace.s6),
            SectionTitle(l.setupPlayers),
            LineupCard(names: names),
          ],
          const SizedBox(height: MmSpace.s6),
          SectionTitle(l.setupCategories, hint: l.setupCategoriesHint),
          for (final c in pack.categories) ...[
            CategoryTile(
              category: c,
              count: pack.countIn([c.id]),
              locked: !_playable(c, premium),
              selected: _selected.contains(c.id),
              onChanged: (on) => setState(() => on ? _selected.add(c.id) : _selected.remove(c.id)),
              onUnlock: () => context.push('/premium'),
            ),
            const SizedBox(height: MmSpace.s2),
          ],
          if (customLimits.containsKey(widget.mode))
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(l.setupWriteOwn),
                onPressed: () => context.push('/my-questions?mode=${widget.mode.id}'),
              ),
            ),
          const SizedBox(height: MmSpace.s4),
          SectionTitle(l.setupRounds),
          SegmentedButton<int>(
            segments: [for (final r in roundOptions) ButtonSegment(value: r, label: Text('$r'))],
            selected: {_rounds},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _rounds = s.first),
          ),
          if (_selected.isNotEmpty && available < _rounds) ...[
            const SizedBox(height: MmSpace.s2),
            Text(
              l.setupFewerQuestions(available),
              style: theme.textTheme.bodySmall?.copyWith(color: palette.textMuted),
            ),
          ],
          const SizedBox(height: MmSpace.s6),
          ...switch (widget.mode) {
            GameMode.wouldYouRather => [
              SectionTitle(l.setupGroupSize, hint: l.setupGroupSizeHint),
              GroupSizeStepper(value: _players, onChanged: (v) => setState(() => _players = v)),
            ],
            GameMode.thisOrThat => [
              Card(
                child: Column(
                  children: [
                    SwitchListTile(
                      title: Text(l.setupPassPhone),
                      subtitle: Text(l.setupPassPhoneBody),
                      value: _pass && names.length >= 2,
                      onChanged: names.length < 2 ? null : (v) => setState(() => _pass = v),
                    ),
                    SwitchListTile(
                      title: Text(l.setupTimer),
                      subtitle: Text(l.setupTimerBody),
                      value: _timer,
                      onChanged: (v) => setState(() => _timer = v),
                    ),
                  ],
                ),
              ),
            ],
            GameMode.trivia => [
              SectionTitle(l.setupTriviaTimer),
              SegmentedButton<int>(
                segments: [
                  for (final t in triviaTimers)
                    ButtonSegment(value: t, label: Text(t == 0 ? l.setupTimerOff : l.setupSeconds(t ~/ 1000))),
                ],
                selected: {_timeLimitMs},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _timeLimitMs = s.first),
              ),
            ],
            GameMode.guess => const <Widget>[],
          },
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(MmSpace.s4, MmSpace.s2, MmSpace.s4, MmSpace.s4),
          child: FilledButton.icon(
            onPressed: _selected.isEmpty ? null : _start,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(l.setupStart),
          ),
        ),
      ),
    );
  }
}

/// Shows who is playing, with a link to edit the names.
class LineupCard extends StatelessWidget {
  const LineupCard({super.key, required this.names});

  final List<String> names;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Card(
      child: ListTile(
        leading: const Icon(Icons.groups_rounded),
        title: Text(names.isEmpty ? l.setupPlayersNone : names.join(', ')),
        trailing: TextButton(onPressed: () => context.push('/players'), child: Text(l.setupPlayersEdit)),
      ),
    );
  }
}

/// Asks for a name (for favourites). Returns null when cancelled or empty.
Future<String?> askName(BuildContext context, {String initial = ''}) async {
  final name = await showDialog<String>(
    context: context,
    builder: (_) => _NameDialog(initial: initial),
  );
  final trimmed = name?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.initial});

  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  // Owned by the dialog so it outlives the closing animation.
  late final _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l.setupSaveFavourite),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        decoration: InputDecoration(labelText: l.favouriteName),
        onSubmitted: (v) => Navigator.pop(context, v),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
        TextButton(onPressed: () => Navigator.pop(context, _controller.text), child: Text(l.save)),
      ],
    );
  }
}
