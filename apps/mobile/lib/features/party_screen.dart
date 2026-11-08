import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../content/content.dart';
import '../game/wyr_engine.dart' show EmptyPoolException;
import '../l10n/app_localizations.dart';
import '../state/games.dart';
import '../state/providers.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import '../widgets/setup_parts.dart';
import 'modes.dart';
import 'setup_screen.dart';

/// Builds a custom party pack: several modes played back to back with their free categories.
class PartyScreen extends ConsumerStatefulWidget {
  const PartyScreen({super.key});

  @override
  ConsumerState<PartyScreen> createState() => _PartyScreenState();
}

class _PartyScreenState extends ConsumerState<PartyScreen> {
  final _modes = <GameMode>[GameMode.wouldYouRather, GameMode.trivia, GameMode.guess];
  int _rounds = 5;

  List<GameSetup> get _setups {
    final content = ref.read(contentProvider);
    return [
      for (final m in GameMode.values)
        if (_modes.contains(m))
          GameSetup(
            mode: m,
            categoryIds: content.packFor(m).categories.where((c) => c.tier == Tier.free).map((c) => c.id).toList(),
            rounds: _rounds,
          ),
    ];
  }

  void _start() {
    final String route;
    try {
      route = ref.read(partyProvider.notifier).start(_setups);
    } on EmptyPoolException {
      return;
    }
    context.pushReplacement(route);
  }

  Future<void> _save() async {
    final l = AppLocalizations.of(context);
    final name = await askName(context, initial: l.modeCustomName);
    if (name == null || !mounted) return;
    ref.read(favouritesProvider.notifier).add(SavedGame(name: name, setups: _setups));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.favouriteSaved)));
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ok = _modes.length >= 2;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.partyTitle),
        actions: [
          IconButton(
            tooltip: l.setupSaveFavourite,
            icon: const Icon(Icons.star_outline_rounded),
            onPressed: ok ? _save : null,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(GfSpace.s4, 0, GfSpace.s4, GfSpace.s6),
        children: [
          Card(
            color: GfPalette.of(context).surfaceMuted,
            child: Padding(padding: const EdgeInsets.all(GfSpace.s4), child: Text(l.modeCustomRules)),
          ),
          const SizedBox(height: GfSpace.s6),
          SectionTitle(l.partyGames, hint: ok ? null : l.partyNeedTwo),
          for (final m in GameMode.values)
            CheckboxListTile(
              value: _modes.contains(m),
              title: Text(modeName(l, m)),
              secondary: Icon(LibraryEntry.of(m).icon),
              onChanged: (on) => setState(() => on! ? _modes.add(m) : _modes.remove(m)),
            ),
          const SizedBox(height: GfSpace.s4),
          SectionTitle(l.partyRounds),
          SegmentedButton<int>(
            segments: [
              for (final r in const [3, 5, 10]) ButtonSegment(value: r, label: Text('$r')),
            ],
            selected: {_rounds},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _rounds = s.first),
          ),
          const SizedBox(height: GfSpace.s6),
          SectionTitle(l.setupPlayers),
          LineupCard(names: ref.watch(lineupProvider)),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(GfSpace.s4, GfSpace.s2, GfSpace.s4, GfSpace.s4),
          child: FilledButton.icon(
            onPressed: ok ? _start : null,
            icon: const Icon(Icons.celebration_rounded),
            label: Text(l.partyStart),
          ),
        ),
      ),
    );
  }
}
