import 'package:supabase_flutter/supabase_flutter.dart';

class ResidentService {
  static final _supabase = Supabase.instance.client;

  // Fetch the active booking for the current resident
  static Future<Map<String, dynamic>?> getActiveBooking() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final response = await _supabase
          .from('bookings')
          .select('''
            id,
            monthly_rent,
            room:rooms ( room_number, room_type ),
            bed:beds ( bed_number )
          ''')
          .eq('resident_id', userId)
          .eq('status', 'active')
          .maybeSingle();

      return response;
    } catch (e) {
      // This will throw an error if no active booking is found, which is expected.
      // We can ignore it and return null.
      print('Error fetching active booking: $e');
      return null;
    }
  }

  // Fetch all payments for a given booking
  static Future<List<Map<String, dynamic>>> getPaymentsForBooking(String bookingId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('booking_id', bookingId)
          .order('payment_date', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching payments: $e');
      return [];
    }
  }

  // Fetch all maintenance requests for a given booking
  static Future<List<Map<String, dynamic>>> getMaintenanceRequests(String bookingId) async {
    try {
      final response = await _supabase
          .from('maintenance_requests')
          .select()
          .eq('booking_id', bookingId)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching maintenance requests: $e');
      return [];
    }
  }

  // Create a new maintenance request
  static Future<void> createMaintenanceRequest({
    required String bookingId,
    required String category,
    required String description,
  }) async {
    try {
      await _supabase.from('maintenance_requests').insert({
        'booking_id': bookingId,
        'category': category,
        'description': description,
        'status': 'pending',
      });
    } catch (e) {
      print('Error creating maintenance request: $e');
      rethrow;
    }
  }

  // Fetch all announcements
  static Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final response = await _supabase
          .from('announcements')
          .select()
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching announcements: $e');
      return [];
    }
  }

  // Fetch all rooms with available beds from all staff members
  static Future<List<Map<String, dynamic>>> getAvailableRooms() async {
    try {
      print('Fetching available rooms...');
      
      // Let's try the most basic query first to get all rooms
      final allRoomsResponse = await _supabase
          .from('rooms')
          .select('*')
          .eq('is_available', true);
      
      print('All available rooms count: ${allRoomsResponse.length}');
      
      // Now get rooms with beds
      final response = await _supabase
          .from('rooms')
          .select('''
            *,
            beds(
              id,
              bed_number,
              is_available
            ),
            profiles!rooms_staff_id_fkey(
              id,
              full_name,
              phone,
              role
            )
          ''')
          .eq('is_available', true)
          .order('created_at', ascending: false);

      print('Rooms with beds fetched: ${response.length} rooms found');
      
      // Filter rooms that have at least one available bed
      final roomsWithAvailableBeds = response.where((room) {
        final beds = room['beds'] as List?;
        if (beds == null || beds.isEmpty) {
          print('Room ${room['room_number']} has no beds');
          return false;
        }
        
        final availableBeds = beds.where((bed) => bed['is_available'] == true).toList();
        print('Room ${room['room_number']} has ${availableBeds.length} available beds out of ${beds.length} total beds');
        
        return availableBeds.isNotEmpty;
      }).toList();
      
      print('Final rooms with available beds: ${roomsWithAvailableBeds.length}');
      return roomsWithAvailableBeds;
      
    } catch (e) {
      print('Error fetching available rooms: $e');
      print('Error type: ${e.runtimeType}');
      
      // Try a very basic fallback
      try {
        print('Trying basic fallback query...');
        final fallbackResponse = await _supabase
            .from('rooms')
            .select('*')
            .eq('is_available', true);
        
        print('Basic fallback successful: ${fallbackResponse.length} rooms found');
        
        // Add empty beds array for compatibility
        final roomsWithEmptyBeds = fallbackResponse.map((room) {
          return {
            ...room,
            'beds': [],
            'profiles': null,
          };
        }).toList();
        
        return roomsWithEmptyBeds;
      } catch (fallbackError) {
        print('All queries failed: $fallbackError');
        return [];
      }
    }
  }

  // Create a new booking
  static Future<void> createBooking({
    required String residentId,
    required String roomId,
    required String bedId,
  }) async {
    try {
      print('Creating booking with params: residentId=$residentId, roomId=$roomId, bedId=$bedId');
      
      // Call the stored procedure to create booking and update bed availability
      final result = await _supabase.rpc('create_booking_and_update_bed', params: {
        'p_resident_id': residentId,
        'p_room_id': roomId,
        'p_bed_id': bedId,
      });
      
      print('Booking created successfully: $result');
      
      // Verify the booking was created by fetching it
      final verification = await _supabase
          .from('bookings')
          .select('id, status, monthly_rent')
          .eq('resident_id', residentId)
          .eq('room_id', roomId)
          .eq('bed_id', bedId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      
      if (verification != null) {
        print('Booking verification successful: ${verification['id']}');
      } else {
        print('Warning: Could not verify booking creation');
      }
      
    } catch (e) {
      print('Error creating booking: $e');
      print('Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        print('PostgrestException details: ${e.message}, code: ${e.code}');
      }
      rethrow;
    }
  }

  // Fetch all bookings for the current resident
  static Future<List<Map<String, dynamic>>> getResidentBookings() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase
          .from('bookings')
          .select('bed_id, status')
          .eq('resident_id', userId);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching resident bookings: $e');
      return [];
    }
  }


  // Fetch all staff and admin members
  static Future<List<Map<String, dynamic>>> getStaffMembers() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final response = await _supabase.rpc(
        'get_staff_members',
        params: {'p_user_id': userId},
      );
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching staff members: $e');
      return [];
    }
  }

  // Fetch chat messages between two users
  static Stream<List<Map<String, dynamic>>> getChatMessages(String receiverId) {
    final senderId = _supabase.auth.currentUser!.id;
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((maps) => maps.where((map) => 
            (map['sender_id'] == senderId && map['receiver_id'] == receiverId) || 
            (map['sender_id'] == receiverId && map['receiver_id'] == senderId)
        ).toList());
  }

  // Send a new message
  static Future<void> sendMessage({
    required String receiverId,
    required String content,
  }) async {
    final senderId = _supabase.auth.currentUser?.id;
    if (senderId == null) return;

    try {
      await _supabase.from('messages').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
      });
    } catch (e) {
      print('Error sending message: $e');
      rethrow;
    }
  }
}
