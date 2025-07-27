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

  // Methods for staff-specific actions will be added here.
  // For example:
  // - Fetch all maintenance requests
  // - Update maintenance request status
  // - Create announcements
  // - Get chat conversations
}
