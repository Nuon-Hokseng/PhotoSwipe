// NEVER use the service_role key here. Flutter uses anon key only.
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClientWrapper {
  SupabaseClientWrapper._();

  static SupabaseClientWrapper? _instance;
  static bool _initialized = false;

  static SupabaseClientWrapper get instance {
    _instance ??= SupabaseClientWrapper._();
    return _instance!;
  }

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
    _initialized = true;
  }

  SupabaseClient get client {
    if (!_initialized) {
      throw StateError(
        'SupabaseClientWrapper.initialize() must be called before accessing client.',
      );
    }
    return Supabase.instance.client;
  }
}
