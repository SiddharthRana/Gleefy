/// Build-time configuration, supplied with `--dart-define` (see apps/mobile/README.md).
/// Without these the app is fully playable; Premium just says it isn't available in this build.
abstract final class AppConfig {
  /// Gleefy API (apps/api), e.g. https://api.gleefy.party. Android emulator: http://10.0.2.2:4000.
  static const apiBaseUrl = String.fromEnvironment('API_BASE_URL');

  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// Where Supabase sends people back after "Continue with Google" (an Android deep link).
  static const authRedirectUrl = 'gleefy://auth-callback';

  /// Offer "Continue with Google": on once the Google provider is set up in Supabase
  /// (same switch as the website's NEXT_PUBLIC_AUTH_GOOGLE_ENABLED).
  static const googleSignInEnabled = bool.fromEnvironment('AUTH_GOOGLE_ENABLED');

  /// Website, where Premium can also be bought.
  static const siteUrl = String.fromEnvironment('SITE_URL', defaultValue: 'https://gleefy.party');

  static const packageName = 'com.gleefy.app';

  static const appVersion = String.fromEnvironment('APP_VERSION', defaultValue: '0.1.0');

  /// Optional, opt-in analytics (PostHog project key and host, e.g. https://eu.i.posthog.com).
  static const posthogKey = String.fromEnvironment('POSTHOG_KEY');
  static const posthogHost = String.fromEnvironment('POSTHOG_HOST', defaultValue: 'https://eu.i.posthog.com');

  static bool get accountsConfigured =>
      apiBaseUrl.isNotEmpty && supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
