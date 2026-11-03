import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/modes.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import 'motion.dart';

class ModeTile extends StatelessWidget {
  const ModeTile({super.key, required this.entry});

  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = MmPalette.of(context);
    return Pressable(
      scale: 0.97,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => context.push(entry.route),
          child: Padding(
            padding: const EdgeInsets.all(MmSpace.s4),
            child: Row(
              children: [
                Container(
                  width: MmTouch.game,
                  height: MmTouch.game,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(MmRadius.md),
                  ),
                  child: Icon(entry.icon, color: theme.colorScheme.onPrimary, size: 28),
                ),
                const SizedBox(width: MmSpace.s4),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entry.name(l), style: theme.textTheme.titleMedium),
                      const SizedBox(height: MmSpace.s1),
                      Text(entry.blurb(l), style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: MmSpace.s2),
                Icon(Icons.chevron_right_rounded, color: palette.textMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
