import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  static final _supabase = Supabase.instance.client;

  // Fetch messages between two users
  static Future<List<Map<String, dynamic>>> getMessages({
    required String senderId,
    required String receiverId,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*')
          .or('and(sender_id.eq.$senderId,receiver_id.eq.$receiverId),and(sender_id.eq.$receiverId,receiver_id.eq.$senderId)')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  // Send a new message
  static Future<void> sendMessage({
    required String senderId,
    required String receiverId,
    required String content,
  }) async {
    try {
      await _supabase.from('messages').insert({
        'sender_id': senderId,
        'receiver_id': receiverId,
        'content': content,
      });
    } catch (e) {
      print('Error sending message: $e');
      throw Exception('Failed to send message: $e');
    }
  }


}
