import 'package:flutter/material.dart';

import '../content/content.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';

const minPlayers = 2;
const maxPlayers = 12;

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key, this.hint});

  final String title;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: GfSpace.s3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: Text(title, style: theme.textTheme.titleLarge)),
          if (hint != null)
            Text(hint!, style: theme.textTheme.bodySmall?.copyWith(color: GfPalette.of(context).textMuted)),
        ],
      ),
    );
  }
}

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.count,
    required this.locked,
    required this.selected,
    required this.onChanged,
    this.onUnlock,
  });

  final Category category;
  final int count;
  final bool locked;
  final bool selected;
  final ValueChanged<bool> onChanged;

  /// Shown on locked premium categories: opens the Premium screen.
  final VoidCallback? onUnlock;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final tags = [
      l.setupQuestionsAvailable(count),
      if (category.ageRating == AgeRating.teen) l.ageTeen,
      if (category.region == 'in') l.regionIndia,
      if (locked) l.premiumLabel,
    ];
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(GfRadius.lg),
        side: BorderSide(
          color: selected ? theme.colorScheme.primary : theme.colorScheme.outline,
          width: selected ? 2 : 1,
        ),
      ),
      child: CheckboxListTile(
        value: selected && !locked,
        onChanged: locked ? null : (v) => onChanged(v ?? false),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(GfRadius.lg)),
        contentPadding: const EdgeInsets.symmetric(horizontal: GfSpace.s4, vertical: GfSpace.s1),
        secondary: locked ? Icon(Icons.lock_outline_rounded, color: palette.textMuted) : null,
        title: Text(category.name, style: theme.textTheme.titleMedium),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(category.description),
            if (category.contentNote != null) ...[
              const SizedBox(height: GfSpace.s1),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, size: 16, color: palette.textMuted),
                  const SizedBox(width: GfSpace.s1),
                  Expanded(child: Text(category.contentNote!, style: theme.textTheme.bodySmall)),
                ],
              ),
            ],
            const SizedBox(height: GfSpace.s1),
            Text(
              locked ? '${tags.join(' · ')} — ${l.premiumLocked}' : tags.join(' · '),
              style: theme.textTheme.labelMedium?.copyWith(color: palette.textMuted),
            ),
            if (locked && onUnlock != null)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton(onPressed: onUnlock, child: Text(l.premiumSee)),
              ),
          ],
        ),
      ),
    );
  }
}

class GroupSizeStepper extends StatelessWidget {
  const GroupSizeStepper({super.key, required this.value, required this.onChanged});

  final int? value;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final v = value;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: GfSpace.s2, vertical: GfSpace.s1),
        child: Row(
          children: [
            IconButton(
              tooltip: l.setupPlayersDecrease,
              icon: const Icon(Icons.remove_rounded),
              onPressed: v == null ? null : () => onChanged(v <= minPlayers ? null : v - 1),
            ),
            Expanded(
              child: Text(
                v == null ? l.setupGroupSizeAny : l.setupGroupSizeValue(v),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            IconButton(
              tooltip: l.setupPlayersIncrease,
              icon: const Icon(Icons.add_rounded),
              onPressed: v != null && v >= maxPlayers ? null : () => onChanged(v == null ? minPlayers : v + 1),
            ),
          ],
        ),
      ),
    );
  }
}
