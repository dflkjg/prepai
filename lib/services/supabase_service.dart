import 'package:supabase_flutter/supabase_flutter.dart';

/// Single access point for the Supabase client.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient get client => Supabase.instance.client;

  static String? get currentUserId => client.auth.currentUser?.id;

  static bool get isLoggedIn => client.auth.currentSession != null;

  static Stream<AuthState> get authStateChanges =>
      client.auth.onAuthStateChange;
}
