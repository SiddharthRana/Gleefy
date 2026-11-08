import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../content/content.dart';
import '../features/modes.dart';
import '../l10n/app_localizations.dart';
import '../state/games.dart';
import '../theme/tokens.g.dart';
import 'motion.dart';

/// Bottom actions on every results screen. In a party pack they move to the next game;
/// otherwise they offer a new setup or a replay with the same settings.
class ResultsActions extends ConsumerWidget {
  const ResultsActions({super.key, required this.mode, required this.onPlayAgain, required this.onClear});

  final GameMode mode;
  final VoidCallback onPlayAgain;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final party = ref.watch(partyProvider);
    final Widget child;
    if (party != null) {
      final next = party.next;
      child = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l.partyProgress(party.index + 1, party.setups.length)),
          const SizedBox(height: GfSpace.s2),
          SizedBox(
            width: double.infinity,
            child: Pressable(
              child: FilledButton(
                onPressed: () {
                  onClear();
                  final route = ref.read(partyProvider.notifier).advance();
                  if (route == null) {
                    context.go('/');
                  } else {
                    context.pushReplacement(route);
                  }
                },
                child: Text(next == null ? l.partyFinish : l.partyNext(modeName(l, next.mode))),
              ),
            ),
          ),
        ],
      );
    } else {
      child = Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                onClear();
                context.pushReplacement(setupRoute(mode));
              },
              child: Text(l.resultsChangeSetup),
            ),
          ),
          const SizedBox(width: GfSpace.s3),
          Expanded(
            child: Pressable(
              child: FilledButton(
                onPressed: () {
                  onPlayAgain();
                  context.pushReplacement(playRoute(mode));
                },
                child: Text(l.resultsPlayAgain),
              ),
            ),
          ),
        ],
      );
    }
    return SafeArea(
      child: Padding(padding: const EdgeInsets.fromLTRB(GfSpace.s4, GfSpace.s2, GfSpace.s4, GfSpace.s4), child: child),
    );
  }
}
