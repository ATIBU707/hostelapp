import 'package:supabase_flutter/supabase_flutter.dart';

class StaffService {
  static final _supabase = Supabase.instance.client;

  static Future<List<Map<String, dynamic>>> getMaintenanceRequests() async {
    try {
      final response = await _supabase
          .from('maintenance_requests')
          .select('*, resident:profiles(full_name, phone)');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching maintenance requests: $e');
      return [];
    }
  }

  // Room Management Methods
  static Future<void> addRoom({
    required String staffId,
    required String roomNumber,
    required String roomType,
    required int capacity,
    required double rentAmount,
    String? description,
  }) async {
    try {
      await _supabase.from('rooms').insert({
        'room_number': roomNumber,
        'room_type': roomType,
        'capacity': capacity,
        'rent_amount': rentAmount,
        'description': description,
        'staff_id': staffId,
        'is_available': true,
        'occupied_beds': 0,
      });
    } catch (e) {
      throw Exception('Failed to add room: $e');
    }
  }

  static Future<List<Map<String, dynamic>>> getStaffRooms(String staffId) async {
    try {
      final response = await _supabase
          .from('rooms')
          .select('*')
          .eq('staff_id', staffId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw Exception('Failed to fetch staff rooms: $e');
    }
  }

  static Future<void> updateRoom({
    required String roomId,
    required String roomNumber,
    required String roomType,
    required int capacity,
    required double rentAmount,
    String? description,
    required bool isAvailable,
  }) async {
    try {
      await _supabase.from('rooms').update({
        'room_number': roomNumber,
        'room_type': roomType,
        'capacity': capacity,
        'rent_amount': rentAmount,
        'description': description,
        'is_available': isAvailable,
      }).eq('id', roomId);
    } catch (e) {
      throw Exception('Failed to update room: $e');
    }
  }

  static Future<void> deleteRoom(String roomId) async {
    try {
      // First check if room has any active reservations
      final reservations = await _supabase
          .from('reservations')
          .select('id')
          .eq('room_id', roomId)
          .eq('status', 'approved');
      
      if (reservations.isNotEmpty) {
        throw Exception('Cannot delete room with active reservations');
      }
      
      await _supabase.from('rooms').delete().eq('id', roomId);
    } catch (e) {
      throw Exception('Failed to delete room: $e');
    }
  }

  // Booking/Reservation Management Methods
  static Future<List<Map<String, dynamic>>> getStaffBookings(String staffId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            *,
            room:rooms!inner(
              id,
              room_number,
              room_type,
              rent_amount
            ),
            bed:beds(
              id,
              bed_number
            ),
            resident:profiles!bookings_resident_id_fkey(
              id,
              full_name,
              phone,
              email
            )
          ''')
          .eq('rooms.staff_id', staffId)
          .order('created_at', ascending: false);
      
      print('Staff bookings fetched: ${response.length} bookings found for staff $staffId');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching staff bookings: $e');
      return [];
    }
  }

  static Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) async {
    try {
      await _supabase
          .from('bookings')
          .update({'status': status})
          .eq('id', bookingId);
      
      print('Booking $bookingId status updated to $status');
    } catch (e) {
      print('Error updating booking status: $e');
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Chat functionality for staff
  static Future<List<Map<String, dynamic>>> getStaffChatContacts(String staffId) async {
    try {
      // Get all residents - staff can chat with any resident
      final response = await _supabase
          .from('profiles')
          .select('''
            id,
            full_name,
            phone,
            email
          ''')
          .eq('role', 'resident')
          .order('full_name', ascending: true);
      
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching staff chat contacts: $e');
      return [];
    }
  }

  // Other staff methods
  // - Update maintenance request status
  // - Create announcements
}
