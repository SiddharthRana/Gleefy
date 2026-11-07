import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'l10n/app_localizations.dart';
import 'router/router.dart';
import 'state/settings.dart';
import 'theme/app_theme.dart';

const _localizationsDelegates = [
  AppLocalizations.delegate,
  GlobalMaterialLocalizations.delegate,
  GlobalWidgetsLocalizations.delegate,
  GlobalCupertinoLocalizations.delegate,
];

class GleefyApp extends ConsumerWidget {
  const GleefyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light, reduceMotion: settings.reduceMotion),
      darkTheme: buildTheme(Brightness.dark, reduceMotion: settings.reduceMotion),
      themeMode: settings.themeMode,
      themeAnimationDuration: settings.reduceMotion ? Duration.zero : kThemeAnimationDuration,
      localizationsDelegates: _localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: ref.watch(routerProvider),
      builder: (context, child) {
        if (!settings.bigText) return child!;
        // Big text multiplies the system text scale rather than replacing it.
        final mq = MediaQuery.of(context);
        final scale = mq.textScaler.scale(1) * 1.25;
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
    );
  }
}

/// Shown instead of the app when the bundled content can't be loaded.
class ContentErrorApp extends StatelessWidget {
  const ContentErrorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      localizationsDelegates: _localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          final l = AppLocalizations.of(context);
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48),
                    const SizedBox(height: 16),
                    Text(l.errorContentTitle, style: Theme.of(context).textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(l.errorContentBody, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
