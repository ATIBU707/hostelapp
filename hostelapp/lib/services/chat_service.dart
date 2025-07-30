import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  static final _supabase = Supabase.instance.client;

  // Fetch messages between two users
  static Future<List<Map<String, dynamic>>> getMessages({
    required String userId1,
    required String userId2,
  }) async {
    try {
      final response = await _supabase
          .from('messages')
          .select('*')
          .or('and(sender_id.eq.$userId1,receiver_id.eq.$userId2),and(sender_id.eq.$userId2,receiver_id.eq.$userId1)')
          .order('created_at', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      print('Error fetching messages: $e');
      return [];
    }
  }

  // Get a real-time stream of messages between two users
  static Stream<List<Map<String, dynamic>>> getMessagesStream(
    String userId1,
    String userId2,
  ) {
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: true)
        .map((maps) => maps
            .where((map) =>
                (map['sender_id'] == userId1 && map['receiver_id'] == userId2) ||
                (map['sender_id'] == userId2 && map['receiver_id'] == userId1))
            .toList());
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

  // Get a polling stream of messages between two users
  static Stream<List<Map<String, dynamic>>> getMessagesPolling(
    String userId1,
    String userId2,
  ) {
    late StreamController<List<Map<String, dynamic>>> controller;
    Timer? timer;

    Future<void> fetchMessages() async {
      try {
        final messages = await getMessages(userId1: userId1, userId2: userId2);
        if (!controller.isClosed) {
          controller.add(messages);
        }
      } catch (e) {
        if (!controller.isClosed) {
          controller.addError(e);
        }
      }
    }

    void startTimer() {
      // Fetch immediately on listen
      fetchMessages();
      // Then fetch periodically every second
      timer = Timer.periodic(const Duration(seconds: 1), (_) => fetchMessages());
    }

    void stopTimer() {
      timer?.cancel();
      controller.close();
    }

    controller = StreamController<List<Map<String, dynamic>>>(
      onListen: startTimer,
      onCancel: stopTimer,
    );

    return controller.stream;
  }
}
