import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../game/share.dart';
import '../game/wyr_engine.dart' show EmptyPoolException;
import '../l10n/app_localizations.dart';
import '../state/games.dart';
import '../theme/tokens.g.dart';

/// Opens a shared `/play?c=…` link: starts the same game (same deal) and replaces this screen.
class SharedLinkScreen extends ConsumerStatefulWidget {
  const SharedLinkScreen({super.key, required this.code});

  final String? code;

  @override
  ConsumerState<SharedLinkScreen> createState() => _SharedLinkScreenState();
}

class _SharedLinkScreenState extends ConsumerState<SharedLinkScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _open());
  }

  void _open() {
    final game = widget.code == null ? null : decodeShare(widget.code!);
    if (game == null) {
      setState(() => _failed = true);
      return;
    }
    try {
      final route = ref
          .read(gameStarterProvider)
          .start(
            GameSetup(
              mode: game.mode,
              categoryIds: game.categoryIds,
              rounds: game.rounds,
              timeLimitMs: game.timeLimitMs,
            ),
            seed: game.seed,
          );
      context.go(route);
    } on EmptyPoolException {
      setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: _failed
            ? Padding(
                padding: const EdgeInsets.all(GfSpace.s6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l.shareBroken, textAlign: TextAlign.center),
                    const SizedBox(height: GfSpace.s4),
                    FilledButton(onPressed: () => context.go('/'), child: Text(l.goHome)),
                  ],
                ),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
