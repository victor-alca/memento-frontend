import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseProvider {
  SupabaseClient get client => Supabase.instance.client;
}

final supabase = SupabaseProvider();
