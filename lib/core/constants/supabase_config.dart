/// Central Supabase Project Configuration
/// Values must be supplied at build time with --dart-define.
class SupabaseConfig {
  SupabaseConfig._();

  static const String projectUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  static bool get isConfigured =>
      projectUrl.isNotEmpty &&
      anonKey.isNotEmpty &&
      !projectUrl.contains('YOUR_PROJECT_URL') &&
      anonKey.isNotEmpty &&
      !anonKey.contains('YOUR_ANON_KEY');
}
