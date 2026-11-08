import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../l10n/app_localizations.dart';
import '../state/games.dart';
import '../state/providers.dart';
import '../theme/tokens.g.dart';

/// The frame around every game: keeps the screen on, shows progress, and asks before quitting
/// (from the close button or system back). [onQuit] clears the session.
class GameShell extends ConsumerStatefulWidget {
  const GameShell({
    super.key,
    required this.title,
    required this.progress,
    required this.onQuit,
    required this.body,
    required this.bottom,
    this.actions = const [],
  });

  final String title;
  final double progress;
  final VoidCallback onQuit;
  final Widget body;
  final Widget bottom;
  final List<Widget> actions;

  @override
  ConsumerState<GameShell> createState() => _GameShellState();
}

class _GameShellState extends ConsumerState<GameShell> {
  late final ScreenAwake _awake;

  @override
  void initState() {
    super.initState();
    _awake = ref.read(screenAwakeProvider);
    unawaited(_awake.enable());
  }

  @override
  void dispose() {
    unawaited(_awake.disable());
    super.dispose();
  }

  Future<void> _confirmQuit() async {
    final l = AppLocalizations.of(context);
    final quit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l.playQuitTitle),
        content: Text(l.playQuitBody),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l.playKeepPlaying)),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text(l.playQuitConfirm)),
        ],
      ),
    );
    if (quit == true && mounted) {
      widget.onQuit();
      ref.read(partyProvider.notifier).stop();
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _confirmQuit();
      },
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(tooltip: l.playQuit, icon: const Icon(Icons.close_rounded), onPressed: _confirmQuit),
          title: Text(widget.title),
          centerTitle: true,
          actions: widget.actions,
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(4),
            child: LinearProgressIndicator(value: widget.progress, minHeight: 4, semanticsLabel: widget.title),
          ),
        ),
        body: SafeArea(child: widget.body),
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(GfSpace.s4, GfSpace.s2, GfSpace.s4, GfSpace.s4),
            child: widget.bottom,
          ),
        ),
      ),
    );
  }
}

/// Shown when a play or results route has no session (e.g. after quitting).
class NoGameScreen extends StatelessWidget {
  const NoGameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l.errorNotFound),
            const SizedBox(height: GfSpace.s4),
            FilledButton(onPressed: () => context.go('/'), child: Text(l.goHome)),
          ],
        ),
      ),
    );
  }
}
