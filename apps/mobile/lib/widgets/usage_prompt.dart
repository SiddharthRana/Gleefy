import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import '../state/settings.dart';
import '../telemetry/analytics.dart';
import '../theme/tokens.g.dart';

/// Asks once, after a finished game, whether to share anonymous usage stats. Shown only in builds
/// with analytics configured, only while sharing is off, and never again once answered.
class UsagePrompt extends ConsumerStatefulWidget {
  const UsagePrompt({super.key});

  static const askedKey = 'analytics.asked';

  @override
  ConsumerState<UsagePrompt> createState() => _UsagePromptState();
}

class _UsagePromptState extends ConsumerState<UsagePrompt> {
  bool _answered = false;

  void _answer(bool share) {
    ref.read(sharedPreferencesProvider).setBool(UsagePrompt.askedKey, true);
    if (share) {
      final settings = ref.read(settingsProvider);
      ref.read(settingsProvider.notifier).update(settings.copyWith(shareUsage: true));
    }
    setState(() => _answered = true);
  }

  @override
  Widget build(BuildContext context) {
    final show =
        !_answered &&
        ref.watch(analyticsProvider).available &&
        !ref.watch(settingsProvider.select((s) => s.shareUsage)) &&
        !(ref.read(sharedPreferencesProvider).getBool(UsagePrompt.askedKey) ?? false);
    if (!show) return const SizedBox.shrink();
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: MmSpace.s4),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(MmSpace.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l.usagePromptTitle, style: theme.textTheme.titleMedium),
              const SizedBox(height: MmSpace.s1),
              Text(l.settingsShareUsageBody),
              const SizedBox(height: MmSpace.s3),
              Wrap(
                spacing: MmSpace.s2,
                runSpacing: MmSpace.s2,
                children: [
                  FilledButton(onPressed: () => _answer(true), child: Text(l.usagePromptYes)),
                  TextButton(onPressed: () => _answer(false), child: Text(l.usagePromptNo)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
