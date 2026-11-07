import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'account/api_client.dart';
import 'account/auth_repository.dart';
import 'account/entitlement.dart';
import 'account/secure_session_storage.dart';
import 'billing/billing_controller.dart';
import 'billing/billing_gateway.dart';
import 'config/app_config.dart';

import 'app.dart';
import 'content/content.dart';
import 'state/providers.dart';
import 'telemetry/analytics.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Fredoka', 'Nunito'], ofl);
  });

  final prefs = await SharedPreferences.getInstance();
  final ContentLibrary content;
  try {
    content = await ContentLibrary.load(rootBundle);
  } on Object catch (e) {
    debugPrint('Content failed to load: $e');
    runApp(const ContentErrorApp());
    return;
  }

  // Accounts and billing are optional: without configuration everything free still works.
  final overrides = [
    sharedPreferencesProvider.overrideWithValue(prefs),
    bundledContentProvider.overrideWithValue(content),
  ];
  if (AppConfig.accountsConfigured) {
    await Supabase.initialize(
      url: AppConfig.supabaseUrl,
      publishableKey: AppConfig.supabasePublishableKey,
      authOptions: FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
        // Tokens live in the Android Keystore, not plain SharedPreferences (as in Weblume).
        localStorage: SecureSessionStorage(persistSessionKey: supabaseSessionKey(AppConfig.supabaseUrl)),
        pkceAsyncStorage: SecurePkceStorage(),
      ),
    );
    final auth = SupabaseAuthRepository(Supabase.instance.client.auth);
    final dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );
    overrides.addAll([
      authRepositoryProvider.overrideWithValue(auth),
      accountApiProvider.overrideWithValue(HttpAccountApi(dio, auth)),
      if (defaultTargetPlatform == TargetPlatform.android)
        billingGatewayProvider.overrideWithValue(PlayBillingGateway(InAppPurchase.instance)),
    ]);
  }

  if (AppConfig.posthogKey.isNotEmpty) {
    final dio = Dio(BaseOptions(baseUrl: AppConfig.posthogHost, connectTimeout: const Duration(seconds: 10)));
    overrides.add(analyticsSinkProvider.overrideWithValue(PostHogSink(dio, AppConfig.posthogKey)));
  }

  final container = ProviderContainer(overrides: overrides);
  // Uncaught errors go to the opt-in error reports (dropped when sharing is off).
  final analytics = container.read(analyticsProvider);
  final previousOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    analytics.captureError(details.exception, details.stack);
    previousOnError?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    analytics.captureError(error, stack);
    return false;
  };
  analytics.track('app_opened');
  if (AppConfig.accountsConfigured) {
    // Listen for purchases Play redelivers (interrupted flows) and refresh the entitlement.
    container.read(billingControllerProvider);
    unawaited(container.read(entitlementProvider.notifier).refresh());
  }
  runApp(UncontrolledProviderScope(container: container, child: const MirthMixApp()));
}
