import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://hnvjhtkghflprqjlpqtr.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImhudmpodGtnaGZscHJxamxwcXRyIiwicm9sZSI6ImFub24iLCJpYXQiOjE3MjE5MDU0MDgsImV4cCI6MjAzNzQ4MTQwOH0.hBq29C0cKqB0pvv3n_Gk2q-2v3f12h3Kj2p3i_1Rj_E';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // Set to false in production
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
  static GoTrueClient get auth => Supabase.instance.client.auth;
}
