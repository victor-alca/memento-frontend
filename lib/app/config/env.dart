enum AppEnvironment { dev, staging, prod }

class Env {
  static const environment = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'dev',
  );

  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://ljymwvozzshiiwlgdgxc.supabase.co',
  );

  static const supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxqeW13dm96enNoaWl3bGdkZ3hjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDgxNzc2NzgsImV4cCI6MjA2Mzc1MzY3OH0.1bH3WSb-HDBHfEEET4l1qYzHL0DIlzHTAiZpUFS4Rlw',
  );
}
