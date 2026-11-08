import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../account/entitlement.dart';
import '../l10n/app_localizations.dart';
import '../state/providers.dart';
import '../telemetry/analytics.dart';
import '../state/settings.dart';
import '../theme/app_theme.dart';
import '../theme/tokens.g.dart';
import '../widgets/insets.dart';

const appVersion = '0.1.0';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final palette = GfPalette.of(context);
    final s = ref.watch(settingsProvider);
    final c = ref.read(settingsProvider.notifier);

    Widget section(String title) => Padding(
      padding: const EdgeInsets.fromLTRB(GfSpace.s4, GfSpace.s6, GfSpace.s4, GfSpace.s2),
      child: Semantics(
        header: true,
        child: Text(title, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.primary)),
      ),
    );
    Widget note(String body) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: GfSpace.s4),
      child: Text(body, style: theme.textTheme.bodyMedium?.copyWith(color: palette.textMuted)),
    );

    return Scaffold(
      appBar: AppBar(title: Text(l.settings)),
      body: ListView(
        padding: listPadding(context, const EdgeInsets.only(bottom: GfSpace.s8)),
        children: [
          section(l.settingsTheme),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: GfSpace.s4),
            child: SegmentedButton<ThemeMode>(
              segments: [
                ButtonSegment(value: ThemeMode.system, label: Text(l.settingsThemeSystem)),
                ButtonSegment(value: ThemeMode.light, label: Text(l.settingsThemeLight)),
                ButtonSegment(value: ThemeMode.dark, label: Text(l.settingsThemeDark)),
              ],
              selected: {s.themeMode},
              showSelectedIcon: false,
              onSelectionChanged: (v) => c.update(s.copyWith(themeMode: v.first)),
            ),
          ),
          section(l.settingsPlay),
          ListTile(
            leading: const Icon(Icons.edit_note_rounded),
            title: Text(l.myQuestionsTitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/my-questions'),
          ),
          SwitchListTile(
            title: Text(l.settingsBigText),
            subtitle: Text(l.settingsBigTextBody),
            value: s.bigText,
            onChanged: (v) => c.update(s.copyWith(bigText: v)),
          ),
          SwitchListTile(
            title: Text(l.settingsReduceMotion),
            subtitle: Text(l.settingsReduceMotionBody),
            value: s.reduceMotion,
            onChanged: (v) => c.update(s.copyWith(reduceMotion: v)),
          ),
          SwitchListTile(
            title: Text(l.settingsHaptics),
            subtitle: Text(l.settingsHapticsBody),
            value: s.haptics,
            onChanged: (v) => c.update(s.copyWith(haptics: v)),
          ),
          ListTile(
            title: Text(l.settingsShowOnboarding),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/onboarding'),
          ),
          section(l.settingsPremium),
          ListTile(
            leading: Icon(ref.watch(premiumProvider) ? Icons.verified_rounded : Icons.lock_outline_rounded),
            title: Text(l.premiumTitle),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.push('/premium'),
          ),
          if (ref.watch(entitlementProvider).signedIn)
            ListTile(
              leading: const Icon(Icons.person_outline_rounded),
              title: Text(l.accountTitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/account'),
            )
          else if (ref.watch(authRepositoryProvider).configured)
            ListTile(
              leading: const Icon(Icons.login_rounded),
              title: Text(l.settingsSignIn),
              subtitle: Text(l.settingsSignInBody),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => context.push('/account/sign-in'),
            ),
          section(l.settingsPrivacy),
          note(l.settingsPrivacyBody),
          if (ref.watch(analyticsProvider).available)
            SwitchListTile(
              title: Text(l.settingsShareUsage),
              subtitle: Text(l.settingsShareUsageBody),
              value: s.shareUsage,
              onChanged: (v) {
                // Turning it off forgets the install id, so a later opt-in isn't linked to the past.
                if (!v) ref.read(analyticsProvider).reset();
                c.update(s.copyWith(shareUsage: v));
              },
            ),
          section(l.settingsAge),
          note(l.settingsAgeBody),
          section(l.settingsAbout),
          ListTile(title: Text(l.settingsVersion(appVersion))),
          ListTile(
            title: Text(l.settingsLicenses),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => showLicensePage(context: context, applicationName: l.appTitle, applicationVersion: appVersion),
          ),
        ],
      ),
    );
  }
}
