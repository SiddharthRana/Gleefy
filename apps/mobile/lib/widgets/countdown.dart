import 'dart:async';

import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/tokens.g.dart';

/// A per-question countdown that pauses while the app is in the background.
///
/// Time is counted in ticks rather than wall-clock time, so a phone call or a locked screen
/// never eats into a player's turn.
class Countdown extends ChangeNotifier {
  Countdown({this.tick = const Duration(milliseconds: 100)});

  final Duration tick;
  Timer? _timer;
  int _limitMs = 0;
  int _elapsedMs = 0;
  bool _paused = false;
  VoidCallback? _onTimeout;
  AppLifecycleListener? _lifecycle;

  int get elapsedMs => _elapsedMs;
  int get remainingMs => (_limitMs - _elapsedMs).clamp(0, _limitMs);
  double get fraction => _limitMs == 0 ? 0 : remainingMs / _limitMs;
  bool get running => _timer != null;

  void start(int limitMs, VoidCallback onTimeout) {
    stop();
    _limitMs = limitMs;
    _elapsedMs = 0;
    _onTimeout = onTimeout;
    _lifecycle ??= AppLifecycleListener(onHide: () => _paused = true, onShow: () => _paused = false);
    _timer = Timer.periodic(tick, (_) {
      if (_paused) return;
      _elapsedMs += tick.inMilliseconds;
      notifyListeners();
      if (_elapsedMs >= _limitMs) {
        stop();
        _onTimeout?.call();
      }
    });
    notifyListeners();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    stop();
    _lifecycle?.dispose();
    super.dispose();
  }
}

/// A slim bar plus seconds left, announced to screen readers only every few seconds.
class CountdownBar extends StatelessWidget {
  const CountdownBar({super.key, required this.countdown});

  final Countdown countdown;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: countdown,
      builder: (context, _) {
        final seconds = (countdown.remainingMs / 1000).ceil();
        final low = countdown.fraction < 0.25;
        return Semantics(
          label: l.secondsLeft(seconds),
          excludeSemantics: true,
          child: Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(GfRadius.pill),
                  child: LinearProgressIndicator(
                    value: countdown.fraction,
                    minHeight: 10,
                    color: low ? theme.colorScheme.error : theme.colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: GfSpace.s3),
              SizedBox(
                width: 40,
                child: Text('${seconds}s', textAlign: TextAlign.end, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
        );
      },
    );
  }
}
