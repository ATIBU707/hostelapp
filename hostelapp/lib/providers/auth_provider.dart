import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/resident_service.dart';
import '../services/staff_service.dart';

class AuthProvider extends ChangeNotifier {
  // Internal state
  User? _user;
  Map<String, dynamic>? _userProfile;
  Map<String, dynamic>? _activeBooking;
  List<Map<String, dynamic>>? _payments;
  List<Map<String, dynamic>>? _maintenanceRequests;
  List<Map<String, dynamic>>? _announcements;
  List<Map<String, dynamic>>? _availableRooms;
  List<Map<String, dynamic>>? _staffMembers;
  List<Map<String, dynamic>>? _staffMaintenanceRequests;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters for UI binding
  User? get user => _user;
  Map<String, dynamic>? get userProfile => _userProfile;
  Map<String, dynamic>? get activeBooking => _activeBooking;
  List<Map<String, dynamic>>? get payments => _payments;
  List<Map<String, dynamic>>? get maintenanceRequests => _maintenanceRequests;
  List<Map<String, dynamic>>? get announcements => _announcements;
  List<Map<String, dynamic>>? get availableRooms => _availableRooms;
  List<Map<String, dynamic>>? get staffMembers => _staffMembers;
  List<Map<String, dynamic>>? get staffMaintenanceRequests => _staffMaintenanceRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  String? get userRole => _userProfile?['role'];

  // Constructor
  AuthProvider() {
    _initializeAuth();
  }

  // Initialization
  void _initializeAuth() {
    _user = AuthService.currentUser;
    if (_user != null) {
      _loadUserProfile().then((_) => _loadInitialData());
    }

    AuthService.authStateChanges.listen((AuthState data) {
      final session = data.session;
      if (session != null && _user?.id != session.user.id) {
        _user = session.user;
        _loadUserProfile().then((_) => _loadInitialData());
      } else if (session == null && _user != null) {
        _clearAllData();
      }
    });
  }

  // Core Data Loading
  Future<void> _loadUserProfile() async {
    try {
      _userProfile = await AuthService.getUserProfile();
    } catch (e) {
      _setError('Failed to load user profile: ${_getErrorMessage(e)}');
    } finally {
      notifyListeners();
    }
  }

  Future<void> _loadInitialData() async {
    if (_userProfile == null) return;
    _setLoading(true);
    final role = _userProfile!['role'];
    if (role == 'resident') {
      await _loadResidentData();
    } else if (role == 'staff' || role == 'admin') {
      await _loadStaffData();
    }
    _setLoading(false);
  }

  Future<void> _loadResidentData() async {
    try {
      _activeBooking = await ResidentService.getActiveBooking();
      if (_activeBooking != null) {
        await _loadPayments();
        await _loadMaintenanceRequests();
      }
      await _loadAnnouncements();
    } catch (e) {
      _setError('Failed to load resident data: ${_getErrorMessage(e)}');
    } finally {
      notifyListeners();
    }
  }

  Future<void> _loadStaffData() async {
    await fetchStaffMaintenanceRequests();
  }

  // Authentication Methods
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
        return true;
      } else {
        _setError('Registration failed. Please try again.');
        return false;
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await AuthService.signIn(email: email, password: password);
      await _loadUserProfile();
      if (_userProfile == null) {
        throw Exception('User profile not found.');
      }
      final role = _userProfile!['role'];
      await _loadInitialData();

      if (role == 'staff' || role == 'admin') {
        return '/staff-dashboard';
      } else if (role == 'resident') {
        return '/resident-dashboard';
      } else {
        throw Exception('Unknown user role.');
      }
    } catch (e) {
      _setError(_getErrorMessage(e));
      return null;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    _setLoading(true);
    try {
      await AuthService.signOut();
      _clearAllData();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resetPassword(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await AuthService.resetPassword(email);
      return true;
    } catch (e) {
      _setError(_getErrorMessage(e));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // Resident-Specific Methods
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
      await _loadMaintenanceRequests();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadPayments() async {
    if (_activeBooking == null) return;
    try {
      final bookingId = _activeBooking!['id'];
      _payments = await ResidentService.getPaymentsForBooking(bookingId);
    } catch (e) {
      _setError('Failed to load payments: ${_getErrorMessage(e)}');
    }
  }

  Future<void> _loadMaintenanceRequests() async {
    if (_activeBooking == null) return;
    try {
      final bookingId = _activeBooking!['id'];
      _maintenanceRequests = await ResidentService.getMaintenanceRequests(bookingId);
    } catch (e) {
      _setError('Failed to load maintenance requests: ${_getErrorMessage(e)}');
    }
  }

  Future<void> _loadAnnouncements() async {
    try {
      _announcements = await ResidentService.getAnnouncements();
    } catch (e) {
      _setError('Failed to load announcements: ${_getErrorMessage(e)}');
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
      notifyListeners();
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
      await _loadInitialData();
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
      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    try {
      await ResidentService.sendMessage(
        receiverId: receiverId,
        content: content,
      );
    } catch (e) {
      _setError(_getErrorMessage(e));
    }
  }

  // Staff-Specific Methods
  Future<void> fetchStaffMaintenanceRequests() async {
    _setLoading(true);
    try {
      _staffMaintenanceRequests = await StaffService.getMaintenanceRequests();
    } catch (e) {
      _setError('Failed to load staff maintenance requests: ${_getErrorMessage(e)}');
    } finally {
      _setLoading(false);
      notifyListeners();
    }
  }

  // Room Management (Staff Only)
  Future<void> addRoom({
    required String roomNumber,
    required String roomType,
    required int capacity,
    required double rentAmount,
    String? description,
  }) async {
    if (_user == null || userRole != 'staff') {
      throw Exception('Only staff members can add rooms');
    }
    
    _setLoading(true);
    _clearError();
    
    try {
      // Insert room into Supabase
      final response = await Supabase.instance.client
          .from('rooms')
          .insert({
            'room_number': roomNumber,
            'room_type': roomType,
            'capacity': capacity,
            // 'price_per_night': rentAmount,
            'description': description,
            'staff_id': _user!.id, // Associate room with staff member
            'status': 'available',
            'created_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      
      // Create beds for the room based on capacity
      final roomId = response['id'];
      final List<Map<String, dynamic>> beds = [];
      
      for (int i = 1; i <= capacity; i++) {
        beds.add({
          'room_id': roomId,
          'bed_number': i.toString(),
          'is_available': true,
        });
      }
      
      // Insert beds into Supabase
      if (beds.isNotEmpty) {
        await Supabase.instance.client
            .from('beds')
            .insert(beds);
      }
      
      // Refresh available rooms data
      await fetchAvailableRooms();
      
    } catch (e) {
      _setError('Failed to add room: ${_getErrorMessage(e)}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }
  
  // Fetch available rooms for residents
  // Future<void> fetchAvailableRooms() async {
  //   _setLoading(true);
  //   _clearError();
    
  //   try {
  //     final response = await Supabase.instance.client
  //         .from('rooms')
  //         .select('''
  //           *,
  //           beds!inner(
  //             id,
  //             bed_number,
  //             is_available
  //           )
  //         ''')
  //         .eq('status', 'available');
      
  //     _availableRooms = List<Map<String, dynamic>>.from(response);
      
  //   } catch (e) {
  //     _setError('Failed to load available rooms: ${_getErrorMessage(e)}');
  //   } finally {
  //     _setLoading(false);
  //     notifyListeners();
  //   }
  // }
  
  // Fetch rooms managed by current staff member
  Future<List<Map<String, dynamic>>> fetchStaffRooms() async {
    if (_user == null || userRole != 'staff') {
      throw Exception('Only staff members can access this data');
    }
    
    try {
      final response = await Supabase.instance.client
          .from('rooms')
          .select('''
            *,
            beds(
              id,
              bed_number,
              is_available
            ),
            bookings(
              id,
              resident_id,
              check_in_date,
              check_out_date,
              status,
              profiles!bookings_resident_id_fkey(
                full_name,
                phone
              )
            )
          ''')
          .eq('staff_id', _user!.id)
          .order('created_at', ascending: false);
      
      return List<Map<String, dynamic>>.from(response);
      
    } catch (e) {
      _setError('Failed to load staff rooms: ${_getErrorMessage(e)}');
      rethrow;
    }
  }

  // Profile Management
  Future<void> updateProfile({
    required String fullName,
    String? phone,
    String? avatarUrl,
  }) async {
    if (_user == null) return;
    _setLoading(true);
    _clearError();
    try {
      await AuthService.updateUserProfile(
        fullName: fullName,
        phone: phone,
        avatarUrl: avatarUrl,
      );
      await _loadUserProfile();
    } catch (e) {
      _setError(_getErrorMessage(e));
    } finally {
      _setLoading(false);
    }
  }

  // State Management Helpers
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void _clearAllData() {
    _user = null;
    _userProfile = null;
    _activeBooking = null;
    _payments = null;
    _maintenanceRequests = null;
    _announcements = null;
    _availableRooms = null;
    _staffMembers = null;
    _staffMaintenanceRequests = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  String _getErrorMessage(dynamic error) {
    if (error is AuthException) {
      return error.message;
    } else if (error is PostgrestException) {
      return error.message;
    } else {
      return error.toString();
    }
  }
}
