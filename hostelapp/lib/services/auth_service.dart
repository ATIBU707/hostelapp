import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/supabase_config.dart';

class AuthService {
  static final SupabaseClient _client = SupabaseConfig.client;
  static final GoTrueClient _auth = SupabaseConfig.auth;

  // Get current user
  static User? get currentUser => _auth.currentUser;

  // Check if user is logged in
  static bool get isLoggedIn => currentUser != null;

  // Sign up with email and password
  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    try {
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'role': role,
        },
      );

      // If signup is successful, create profile in profiles table
      if (response.user != null) {
        await _createUserProfile(
          userId: response.user!.id,
          fullName: fullName,
          email: email,
          phone: phone,
          role: role,
        );
      }

      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign in with email and password
  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      rethrow;
    }
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } catch (e) {
      rethrow;
    }
  }

  // Get user profile from profiles table
  static Future<Map<String, dynamic>?> getUserProfile() async {
    try {
      if (currentUser == null) return null;

      final response = await _client
          .from('profiles')
          .select()
          .eq('id', currentUser!.id)
          .single();

      return response;
    } catch (e) {
      print('Error fetching user profile: $e');
      return null;
    }
  }

  // Update user profile
  static Future<void> updateUserProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      if (currentUser == null) throw Exception('User not logged in');

      await _client.from('profiles').update({
        'full_name': fullName,
        'phone': phone,
        'avatar_url': avatarUrl,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', currentUser!.id);
    } catch (e) {
      rethrow;
    }
  }

  // Create user profile in profiles table
  static Future<void> _createUserProfile({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    required String role,
  }) async {
    try {
      await _client.from('profiles').insert({
        'id': userId,
        'full_name': fullName,
        'email': email,
        'phone': phone,
        'role': role,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error creating user profile: $e');
      rethrow;
    }
  }

  // Get user role
  static Future<String?> getUserRole() async {
    try {
      final profile = await getUserProfile();
      return profile?['role'];
    } catch (e) {
      print('Error getting user role: $e');
      return null;
    }
  }

  // Check if user has specific role
  static Future<bool> hasRole(String role) async {
    try {
      final userRole = await getUserRole();
      return userRole == role;
    } catch (e) {
      return false;
    }
  }

  // Listen to auth state changes
  static Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  // Verify email (for email confirmation)
  static Future<void> verifyEmail(String token) async {
    try {
      await _auth.verifyOTP(
        token: token,
        type: OtpType.email,
      );
    } catch (e) {
      rethrow;
    }
  }

  // Resend email confirmation
  static Future<void> resendEmailConfirmation(String email) async {
    try {
      await _auth.resend(
        type: OtpType.signup,
        email: email,
      );
    } catch (e) {
      rethrow;
    }
  }
}
