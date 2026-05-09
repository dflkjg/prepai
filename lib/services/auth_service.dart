import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';

class AuthService {
  final _client = SupabaseService.client;

  /// Register a new user and create their profile.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String name,
  }) async {
    return await _client.auth.signUp(
      email: email,
      password: password,
      data: {'name': name},
    );
  }

  /// Sign in with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  /// Send a password reset email.
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  /// Sign the current user out.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Current signed-in user (nullable).
  User? get currentUser => _client.auth.currentUser;

  /// Auth state stream.
  Stream<AuthState> get authStateChanges =>
      _client.auth.onAuthStateChange;
}
