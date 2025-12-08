import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://hukprbgcrjfmrwrxlyif.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imh1a3ByYmdjcmpmbXJ3cnhseWlmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjUwMzE0ODAsImV4cCI6MjA4MDYwNzQ4MH0.XgigJw55p9KUsGYouUzeWtqQNi1RydWdk-SG7v9T5B8';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
