/// Central Supabase Project Configuration
/// Project: dpjsecqjcfgytcdxaksy
class SupabaseConfig {
  SupabaseConfig._();

  static const String projectUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://dpjsecqjcfgytcdxaksy.supabase.co',
  );

  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwanNlY3FqY2ZneXRjZHhha3N5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODg5NDY1NzQsImV4cCI6MjEwNDUyMjU3NH0.RVGZAA_FemXXDh8Nxg3GkjM56MSe7GJ2Wf_F2DlGnd0',
  );

  static bool get isConfigured =>
      projectUrl.isNotEmpty &&
      anonKey.isNotEmpty &&
      !projectUrl.contains('YOUR_PROJECT_URL');
}
