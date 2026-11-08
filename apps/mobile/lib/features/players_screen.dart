import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state/games.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import '../widgets/motion.dart';
import '../widgets/insets.dart';

class PlayersScreen extends ConsumerStatefulWidget {
  const PlayersScreen({super.key});

  @override
  ConsumerState<PlayersScreen> createState() => _PlayersScreenState();
}

class _PlayersScreenState extends ConsumerState<PlayersScreen> {
  /// Height of a Material outlined text field, so the Add button matches it.
  static const _fieldHeight = 56.0;

  final _field = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _field.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _add() {
    final name = _field.text.trim();
    if (name.isEmpty) return;
    final names = ref.read(lineupProvider);
    if (names.length >= maxNames) return;
    ref.read(lineupProvider.notifier).set([...names, name]);
    _field.clear();
    // Keep the keyboard up so a whole group can be typed in one go.
    if (names.length + 1 < maxNames) _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final names = ref.watch(lineupProvider);
    final full = names.length >= maxNames;
    return Scaffold(
      appBar: AppBar(
        title: Text(l.playersTitle),
        actions: [
          if (names.isNotEmpty)
            TextButton(onPressed: () => ref.read(lineupProvider.notifier).set(const []), child: Text(l.playersClear)),
          const SizedBox(width: GfSpace.s2),
        ],
      ),
      body: ListView(
        padding: listPadding(context, const EdgeInsets.all(GfSpace.s4)),
        children: [
          Text(l.playersBody, style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted)),
          const SizedBox(height: GfSpace.s4),
          // Field and button share a height and top edge, so they line up whether or not the
          // field shows its "maximum reached" note underneath.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _field,
                  focusNode: _focus,
                  enabled: !full,
                  maxLength: 24,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: InputDecoration(
                    labelText: l.playersName,
                    helperText: full ? l.playersFull(maxNames) : null,
                    counterText: '',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(GfRadius.md)),
                  ),
                  onSubmitted: (_) => _add(),
                ),
              ),
              const SizedBox(width: GfSpace.s2),
              Pressable(
                enabled: !full,
                child: SizedBox(
                  height: _fieldHeight,
                  child: FilledButton.icon(
                    onPressed: full ? null : _add,
                    icon: const Icon(Icons.add_rounded),
                    label: Text(l.playersAdd),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: GfSpace.s4),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GfRadius.md)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: GfSpace.s4),
          if (names.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: GfSpace.s8),
              child: Column(
                children: [
                  Icon(Icons.groups_rounded, size: 56, color: palette.textMuted),
                  const SizedBox(height: GfSpace.s2),
                  Text(l.playersEmpty, style: theme.textTheme.titleMedium),
                  const SizedBox(height: GfSpace.s1),
                  Text(
                    l.playersEmptyBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted),
                  ),
                ],
              ),
            )
          else ...[
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Text(
                l.playersCount(names.length, maxNames),
                style: theme.textTheme.labelLarge?.copyWith(color: palette.textMuted),
              ),
            ),
            const SizedBox(height: GfSpace.s2),
            for (final (i, name) in names.indexed)
              StaggerIn(
                key: ValueKey('$i-$name'),
                child: Card(
                  margin: const EdgeInsets.only(bottom: GfSpace.s2),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      child: Text('${i + 1}', style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    title: Text(name, style: theme.textTheme.titleMedium),
                    trailing: IconButton(
                      tooltip: l.playersRemove(name),
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => ref.read(lineupProvider.notifier).set([...names]..removeAt(i)),
                    ),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}
