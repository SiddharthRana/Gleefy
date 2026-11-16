import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../content/content.dart';
import '../../content/dream_team_content.dart';
import '../../game/dream_team_engine.dart';
import '../../l10n/app_localizations.dart';
import '../../state/card_photos.dart';
import '../../state/dream_team.dart';
import '../../state/providers.dart';
import '../../theme/app_theme.dart';
import '../../theme/tokens.g.dart';
import '../../widgets/insets.dart';
import '../../widgets/motion.dart';
import '../../widgets/setup_parts.dart';

/// Dream Team setup: pick a deck (a bundled one or your own), a role set and the two sides.
class DreamTeamSetupScreen extends ConsumerStatefulWidget {
  const DreamTeamSetupScreen({super.key});

  @override
  ConsumerState<DreamTeamSetupScreen> createState() => _DreamTeamSetupScreenState();
}

class _DreamTeamSetupScreenState extends ConsumerState<DreamTeamSetupScreen> {
  late String _deckId;
  late String _roleSetId;
  final _sides = [TextEditingController(), TextEditingController()];

  DreamTeamPack get _pack => ref.read(contentProvider).dreamTeam;

  @override
  void initState() {
    super.initState();
    _deckId = _pack.decks.firstWhere((d) => d.tier == Tier.free, orElse: () => _pack.decks.first).id;
    _roleSetId = _pack.roleSets.first.id;
  }

  @override
  void dispose() {
    for (final c in _sides) {
      c.dispose();
    }
    super.dispose();
  }

  void _start() {
    final l = AppLocalizations.of(context);
    final premium = ref.read(premiumProvider);
    final roleSet = _pack.roleSets.firstWhere((r) => r.id == _roleSetId);
    final custom = ref.read(customDecksProvider).where((d) => d.id == _deckId).firstOrNull;
    final bundled = _pack.decks.where((d) => d.id == _deckId).firstOrNull;
    // Locked decks can't be picked, but check again in case Premium lapsed.
    if ((custom != null || bundled?.tier == Tier.premium) && !premium) {
      context.push('/premium');
      return;
    }
    final cards = custom?.toCards(ref.read(cardPhotosDirProvider)) ?? _pack.cardsIn(_deckId);
    final names = [
      for (var i = 0; i < 2; i++) _sides[i].text.trim().isEmpty ? l.dtSideDefault(i + 1) : _sides[i].text.trim(),
    ];
    try {
      ref
          .read(dreamTeamProvider.notifier)
          .start(
            deckId: _deckId,
            deckName: custom?.name ?? bundled!.name,
            roleSetName: roleSet.name,
            roles: roleSet.roles,
            sides: names,
            cards: cards,
          );
    } on DeckTooSmallException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l.dtProblemTooFew(e.needed))));
      return;
    }
    context.pushReplacement('/dream-team/play');
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final premium = ref.watch(premiumProvider);
    final mine = ref.watch(customDecksProvider);
    final pack = ref.watch(contentProvider).dreamTeam;

    Widget deckTile({required String id, required String title, required String subtitle, required bool locked}) {
      final selected = _deckId == id;
      return Card(
        margin: const EdgeInsets.only(bottom: GfSpace.s2),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(GfRadius.lg),
          side: BorderSide(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: GfSpace.s4, vertical: GfSpace.s1),
          leading: Icon(
            locked
                ? Icons.lock_outline_rounded
                : selected
                ? Icons.radio_button_checked_rounded
                : Icons.radio_button_off_rounded,
            color: selected ? theme.colorScheme.primary : palette.textMuted,
          ),
          title: Text(title, style: theme.textTheme.titleMedium),
          subtitle: Text(locked ? '$subtitle · ${l.premiumLabel}' : subtitle),
          trailing: locked ? TextButton(onPressed: () => context.push('/premium'), child: Text(l.premiumSee)) : null,
          onTap: locked ? () => context.push('/premium') : () => setState(() => _deckId = id),
          selected: selected,
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text(l.modeDreamTeamName)),
      body: ListView(
        padding: listPadding(context, const EdgeInsets.fromLTRB(GfSpace.s4, GfSpace.s2, GfSpace.s4, GfSpace.s4)),
        children: [
          Text(l.modeDreamTeamRules, style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted)),
          const SizedBox(height: GfSpace.s4),
          SectionTitle(l.dtDeck),
          for (final d in pack.decks)
            deckTile(
              id: d.id,
              title: d.name,
              subtitle: '${d.description} · ${l.dtDeckCards(pack.cardsIn(d.id).length)}',
              locked: d.tier == Tier.premium && !premium,
            ),
          for (final d in mine)
            deckTile(id: d.id, title: d.name, subtitle: l.dtCustomDeckInfo(d.cards.length), locked: !premium),
          Card(
            margin: const EdgeInsets.only(bottom: GfSpace.s2),
            child: ListTile(
              leading: const Icon(Icons.add_circle_outline_rounded),
              title: Text(mine.isEmpty ? l.dtMakeDeck : l.dtMyDecks),
              subtitle: Text(premium ? l.dtDeckStaysHere : l.dtMakeDeckBody),
              trailing: premium ? const Icon(Icons.chevron_right_rounded) : const Icon(Icons.lock_outline_rounded),
              onTap: () => context.push(premium ? '/dream-team/decks' : '/premium'),
            ),
          ),
          const SizedBox(height: GfSpace.s4),
          SectionTitle(l.dtRoles),
          Wrap(
            spacing: GfSpace.s2,
            runSpacing: GfSpace.s2,
            children: [
              for (final r in pack.roleSets)
                ChoiceChip(
                  label: Text(r.name),
                  selected: _roleSetId == r.id,
                  onSelected: (_) => setState(() => _roleSetId = r.id),
                ),
            ],
          ),
          const SizedBox(height: GfSpace.s2),
          Text(
            pack.roleSets.firstWhere((r) => r.id == _roleSetId).roles.map((r) => r.name).join(' · '),
            style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted),
          ),
          const SizedBox(height: GfSpace.s4),
          SectionTitle(l.dtSides),
          for (var i = 0; i < 2; i++) ...[
            TextField(
              controller: _sides[i],
              maxLength: 20,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: l.dtSideLabel(i + 1),
                hintText: l.dtSideDefault(i + 1),
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: GfSpace.s2),
          ],
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(GfSpace.s4),
        child: Pressable(
          child: FilledButton(onPressed: _start, child: Text(l.dtStart)),
        ),
      ),
    );
  }
}
