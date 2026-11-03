import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';
import 'motion.dart';

/// A big, full-colour answer button that can show a vote count and, once revealed, its share.
class OptionCard extends StatelessWidget {
  const OptionCard({
    super.key,
    required this.text,
    required this.color,
    required this.onColor,
    required this.votes,
    required this.total,
    required this.revealed,
    required this.enabled,
    required this.reduceMotion,
    required this.onTap,
  });

  final String text;
  final Color color;
  final Color onColor;
  final int votes;
  final int total;
  final bool revealed;
  final bool enabled;
  final bool reduceMotion;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final share = total == 0 ? 0.0 : votes / total;
    final percent = (share * 100).round();
    final style = theme.textTheme.headlineSmall?.copyWith(color: onColor, fontWeight: FontWeight.w600);

    return Semantics(
      button: enabled,
      label: revealed ? '$text. ${l.playVotes(votes)}, ${l.playSplit(percent)}' : l.playVoteFor(text),
      value: revealed ? null : l.playVotes(votes),
      excludeSemantics: true,
      child: Pressable(
        enabled: enabled,
        child: Material(
          color: color,
          borderRadius: BorderRadius.circular(MmRadius.xl),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: Stack(
              children: [
                if (revealed)
                  Positioned.fill(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: share),
                        duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => FractionallySizedBox(
                          widthFactor: v,
                          heightFactor: 1,
                          child: ColoredBox(color: Colors.black.withValues(alpha: 0.18)),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(MmSpace.s5),
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width - 80),
                        child: Text(text, style: style, textAlign: TextAlign.center),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: MmSpace.s3,
                  top: MmSpace.s3,
                  // Bumps with every vote, and again when the split is revealed.
                  child: Bump(
                    value: revealed ? 'split' : votes,
                    child: VoteBadge(text: revealed ? l.playSplit(percent) : '$votes', color: onColor, onColor: color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class VoteBadge extends StatelessWidget {
  const VoteBadge({super.key, required this.text, required this.color, required this.onColor});

  final String text;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 40),
      padding: const EdgeInsets.symmetric(horizontal: MmSpace.s3, vertical: MmSpace.s1),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(MmRadius.pill)),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: onColor, fontWeight: FontWeight.w800, fontSize: MmFontSize.lg),
      ),
    );
  }
}
