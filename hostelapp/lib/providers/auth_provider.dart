import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/resident_service.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _activeBooking;
  List<Map<String, dynamic>>? _payments;
  List<Map<String, dynamic>>? _maintenanceRequests;
  List<Map<String, dynamic>>? _announcements;
  List<Map<String, dynamic>>? _availableRooms;
  List<Map<String, dynamic>>? _staffMembers;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;
  Map<String, dynamic>? get activeBooking => _activeBooking;
  List<Map<String, dynamic>>? get payments => _payments;
  List<Map<String, dynamic>>? get maintenanceRequests => _maintenanceRequests;
  List<Map<String, dynamic>>? get announcements => _announcements;
  List<Map<String, dynamic>>? get availableRooms => _availableRooms;
  List<Map<String, dynamic>>? get staffMembers => _staffMembers;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  String? get userRole => _userProfile?['role'];

  AuthProvider() {
    _initializeAuth();
  }

  void _initializeAuth() {
    _user = AuthService.currentUser;
    if (_user != null) {
      _loadUserProfile().then((_) => _loadActiveBooking());
    }

    // Listen to auth state changes
    AuthService.authStateChanges.listen((AuthState data) {
      _user = data.session?.user;
      if (_user != null) {
        _loadUserProfile().then((_) => _loadActiveBooking());
      } else {
        _userProfile = null;
        _activeBooking = null;
        _payments = null;
        _maintenanceRequests = null;
        _announcements = null;
        _availableRooms = null;
        _staffMembers = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await AuthService.getUserProfile();
      notifyListeners();
    } catch (e) {
      print('Error loading user profile: $e');
    }
  }

  Future<void> _loadActiveBooking() async {
    if (userRole == 'resident') {
      try {
        _activeBooking = await ResidentService.getActiveBooking();
        if (_activeBooking != null) {
          await _loadPayments();
          await _loadMaintenanceRequests();
        }
        await _loadAnnouncements();
        notifyListeners();
      } catch (e) {
        print('Error loading active booking: $e');
      }
    }
  }

  Future<void> _loadPayments() async {
    if (_activeBooking == null) return;
    try {
      final bookingId = _activeBooking!['id'];
      _payments = await ResidentService.getPaymentsForBooking(bookingId);
    } catch (e) {
      print('Error loading payments: $e');
    }
  }

  Future<void> _loadMaintenanceRequests() async {
    if (_activeBooking == null) return;
    try {
      final bookingId = _activeBooking!['id'];
      _maintenanceRequests = await ResidentService.getMaintenanceRequests(bookingId);
    } catch (e) {
      print('Error loading maintenance requests: $e');
    }
  }

  Future<void> _loadAnnouncements() async {
    try {
      _announcements = await ResidentService.getAnnouncements();
    } catch (e) {
      print('Error loading announcements: $e');
    }
  }

  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    required String role,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await AuthService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        role: role,
      );

      if (response.user != null) {
        _user = response.user;
        await _loadUserProfile();
        _setLoading(false);
        return true;
      } else {
        _setError('Registration failed. Please try again.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await AuthService.signIn(
        email: email,
        password: password,
      );

      if (response.user != null) {
        _user = response.user;
        await _loadUserProfile();
        await _loadActiveBooking();
        _setLoading(false);
        return true;
      } else {
        _setError('Login failed. Please check your credentials.');
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.signOut();
      _user = null;
      _userProfile = null;
      _activeBooking = null;
      _payments = null;
      _maintenanceRequests = null;
      _announcements = null;
      _availableRooms = null;
      _staffMembers = null;
      _setLoading(false);
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.resetPassword(email);
      _setLoading(false);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
      return false;
    }
  }

  Future<void> createMaintenanceRequest({
    required String category,
    required String description,
  }) async {
    if (_activeBooking == null) return;
    _setLoading(true);
    _clearError();

    try {
      await ResidentService.createMaintenanceRequest(
        bookingId: _activeBooking!['id'],
        category: category,
        description: description,
      );
      await _loadMaintenanceRequests(); // Refresh the list
      _setLoading(false);
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
    }
  }

  Future<void> fetchAvailableRooms() async {
    _setLoading(true);
    try {
      _availableRooms = await ResidentService.getAvailableRooms();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> bookRoom({required int roomId, required int bedId}) async {
    if (_user == null) return;
    _setLoading(true);
    _clearError();
    try {
      await ResidentService.createBooking(
        residentId: _user!.id,
        roomId: roomId,
        bedId: bedId,
      );
      // Refresh user's booking status
      await _loadActiveBooking();
      notifyListeners();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchStaffMembers() async {
    _setLoading(true);
    try {
      _staffMembers = await ResidentService.getStaffMembers();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    // No loading indicator for sending a message, as it should feel instant.
    try {
      await ResidentService.sendMessage(
        receiverId: receiverId,
        content: content,
      );
    } catch (e) {
      // Optionally, set an error message if sending fails
      _setError(_getErrorMessage(e));
    }
  }

  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      await AuthService.updateUserProfile(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      await _loadUserProfile();
      _setLoading(false);
    } catch (e) {
      _setError(_getErrorMessage(e));
      _setLoading(false);
    }
  }

  String getDashboardRoute() {
    switch (userRole) {
      case 'admin':
        return '/admin-dashboard';
      case 'manager':
        return '/manager-dashboard';
      case 'staff':
        return '/staff-dashboard';
      case 'resident':
        return '/resident-dashboard';
      default:
        return '/login';
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      switch (error.message) {
        case 'Invalid login credentials':
          return 'Invalid email or password. Please try again.';
        case 'Email not confirmed':
          return 'Please check your email and confirm your account.';
        case 'User already registered':
          return 'An account with this email already exists.';
        case 'Password should be at least 6 characters':
          return 'Password must be at least 6 characters long.';
        default:
          return error.message;
      }
    }
    return error.toString();
  }

  void clearError() {
    _clearError();
  }
}
