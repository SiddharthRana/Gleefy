import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../game/dream_team_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../state/dream_team.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/insets.dart';
import '../../widgets/motion.dart';

/// Cards the biggest bundled role set needs, so any custom deck works with every role set.
int minCustomCards(WidgetRef ref) {
  final sets = ref.read(contentProvider).dreamTeam.roleSets;
  final most = sets.isEmpty ? 5 : sets.map((s) => s.roles.length).reduce((a, b) => a > b ? a : b);
  return cardsNeeded(most, dreamTeamSkips);
}

/// Premium: the person's own Dream Team decks, kept on this phone.
class DreamTeamDecksScreen extends ConsumerWidget {
  const DreamTeamDecksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final palette = GfPalette.of(context);
    final decks = ref.watch(customDecksProvider);
    final premium = ref.watch(premiumProvider);
    return Scaffold(
      appBar: AppBar(title: Text(l.dtDecksTitle)),
      body: ListView(
        padding: listPadding(context, const EdgeInsets.all(GfSpace.s4)),
        children: [
          if (!premium)
            Card(
              child: ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: Text(l.dtPremiumDecks),
                trailing: TextButton(onPressed: () => context.push('/premium'), child: Text(l.premiumSee)),
              ),
            ),
          if (decks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: GfSpace.s6),
              child: Text(
                l.dtDeckEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: palette.textMuted),
              ),
            ),
          for (final d in decks)
            Card(
              child: ListTile(
                title: Text(d.name),
                subtitle: Text(l.dtCustomDeckInfo(d.cards.length)),
                trailing: const Icon(Icons.edit_outlined),
                onTap: () => context.push('/dream-team/decks/${d.id}'),
              ),
            ),
          const SizedBox(height: GfSpace.s2),
          Text(
            l.dtDeckStaysHere,
            textAlign: TextAlign.center,
            style: TextStyle(color: palette.textMuted),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(GfSpace.s4),
        child: Pressable(
          child: FilledButton.icon(
            onPressed: premium ? () => context.push('/dream-team/decks/new') : () => context.push('/premium'),
            icon: const Icon(Icons.add_rounded),
            label: Text(l.dtNewDeck),
          ),
        ),
      ),
    );
  }
}

/// Make or edit a custom deck: a name and one card per line.
class DreamTeamDeckEditor extends ConsumerStatefulWidget {
  const DreamTeamDeckEditor({super.key, this.deckId});

  /// Null for a new deck.
  final String? deckId;

  @override
  ConsumerState<DreamTeamDeckEditor> createState() => _DreamTeamDeckEditorState();
}

class _DreamTeamDeckEditorState extends ConsumerState<DreamTeamDeckEditor> {
  final _title = TextEditingController();
  final _names = TextEditingController();
  String? _error;

  CustomDeck? get _existing => ref.read(customDecksProvider).where((d) => d.id == widget.deckId).firstOrNull;

  @override
  void initState() {
    super.initState();
    final d = _existing;
    if (d != null) {
      _title.text = d.name;
      _names.text = d.cards.join('\n');
    }
    _names.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _names.dispose();
    super.dispose();
  }

  String _describe(AppLocalizations l, DeckProblem p, int min) => switch (p) {
    DeckProblem.noTitle => l.dtProblemNoTitle,
    DeckProblem.titleTooLong => l.dtProblemTitleTooLong(customDeckTitleMax),
    DeckProblem.tooFew => l.dtProblemTooFew(min),
    DeckProblem.tooMany => l.dtProblemTooMany(customDeckMax),
    DeckProblem.nameTooLong => l.dtProblemNameTooLong(customNameMax),
    DeckProblem.notAllowed => l.dtProblemNotAllowed,
  };

  void _save() {
    final l = AppLocalizations.of(context);
    if (!ref.read(premiumProvider)) {
      context.push('/premium');
      return;
    }
    final min = minCustomCards(ref);
    final names = parseDeckNames(_names.text);
    final problem = checkDeck(_title.text, names, minCards: min);
    if (problem != null) {
      setState(() => _error = _describe(l, problem, min));
      return;
    }
    ref.read(customDecksProvider.notifier).save(id: widget.deckId, name: _title.text, cards: names);
    context.pop();
  }

  Future<void> _delete() async {
    final l = AppLocalizations.of(context);
    final d = _existing;
    if (d == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(l.dtDeckDeleteConfirm(d.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.playKeepPlaying)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l.dtDeckDelete)),
        ],
      ),
    );
    if (ok == true && mounted) {
      ref.read(customDecksProvider.notifier).remove(d.id);
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final min = minCustomCards(ref);
    final count = parseDeckNames(_names.text).length;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.deckId == null ? l.dtNewDeck : l.dtEditDeck),
        actions: [
          if (_existing != null)
            IconButton(tooltip: l.dtDeckDelete, icon: const Icon(Icons.delete_outline_rounded), onPressed: _delete),
        ],
      ),
      body: ListView(
        padding: listPadding(context, const EdgeInsets.all(GfSpace.s4)),
        children: [
          TextField(
            controller: _title,
            maxLength: customDeckTitleMax,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(labelText: l.dtDeckTitle, border: const OutlineInputBorder()),
          ),
          const SizedBox(height: GfSpace.s2),
          TextField(
            controller: _names,
            minLines: 8,
            maxLines: 16,
            keyboardType: TextInputType.multiline,
            textCapitalization: TextCapitalization.words,
            decoration: InputDecoration(
              labelText: l.dtDeckNames,
              helperText: l.dtDeckNamesHint,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: GfSpace.s2),
          Text(
            l.dtDeckCount(count, min, customDeckMax),
            style: TextStyle(color: count < min || count > customDeckMax ? theme.colorScheme.error : palette.textMuted),
          ),
          if (_error != null)
            Semantics(
              liveRegion: true,
              child: Padding(
                padding: const EdgeInsets.only(top: GfSpace.s2),
                child: Text(_error!, style: TextStyle(color: theme.colorScheme.error)),
              ),
            ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(GfSpace.s4),
        child: Pressable(
          child: FilledButton(onPressed: _save, child: Text(l.dtDeckSave)),
        ),
      ),
    );
  }
}
