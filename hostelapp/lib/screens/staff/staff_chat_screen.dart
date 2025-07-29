import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/staff_service.dart';
import '../../services/chat_service.dart';

class StaffChatScreen extends StatefulWidget {
  const StaffChatScreen({super.key});

  @override
  State<StaffChatScreen> createState() => _StaffChatScreenState();
}

class _StaffChatScreenState extends State<StaffChatScreen> {
  RealtimeChannel? _messageChannel;
  bool _isLoading = false;
  List<Map<String, dynamic>> _residents = [];
  Map<String, dynamic>? _selectedResident;
  List<Map<String, dynamic>> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadResidents();
    _setupMessageSubscription();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _messageChannel?.unsubscribe();
    super.dispose();
  }

  void _setupMessageSubscription() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final staffId = authProvider.userProfile?['id'];
    if (staffId == null) return;

    _messageChannel = Supabase.instance.client
        .channel('public:messages')
        .onPostgresChanges(event: PostgresChangeEvent.insert, schema: 'public', table: 'messages', callback: (payload) {

      final newMessage = payload.newRecord;

      if (_selectedResident != null &&
          ((newMessage['sender_id'] == staffId &&
                  newMessage['receiver_id'] == _selectedResident!['id']) ||
              (newMessage['sender_id'] == _selectedResident!['id'] &&
                  newMessage['receiver_id'] == staffId))) {
        final formattedMessage = {
          'id': newMessage['id'].toString(),
          'sender_id': newMessage['sender_id'],
          'sender_type':
              newMessage['sender_id'] == staffId ? 'staff' : 'resident',
          'message': newMessage['content'],
          'timestamp': newMessage['created_at'],
        };

        if (mounted) {
          setState(() {
            _messages.add(formattedMessage);
          });

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_scrollController.hasClients) {
              _scrollController.animateTo(
                _scrollController.position.maxScrollExtent,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
              );
            }
          });
        }
      }
    });
    _messageChannel?.subscribe();
  }

  Future<void> _loadResidents() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final staffId = authProvider.userProfile?['id'];
      if (staffId == null) {
        throw Exception('Staff ID not found');
      }

      final residents = await StaffService.getStaffChatContacts(staffId);

      // Transform data to match the UI widget's expected structure
      _residents = residents.map((resident) {
        return {
          'id': resident['id'],
          'name': resident['full_name'] ?? 'N/A',
          'email': resident['email'] ?? 'N/A',
          'room_number': 'N/A', // Room info not available in universal chat
          'phone': resident['phone'] ?? 'N/A',
          'last_message': 'Tap to start chatting...', // Placeholder
          'last_message_time': DateTime.now().toIso8601String(), // Placeholder
          'unread_count': 0, // Placeholder
          'avatar': null, // Placeholder
        };
      }).toList();

      if (_residents.isNotEmpty) {
        _selectResident(_residents.first);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading residents: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadMessages(String residentId) async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final staffId = authProvider.userProfile?['id'];
      if (staffId == null) {
        throw Exception('Staff ID not found');
      }

      final fetchedMessages = await ChatService.getMessages(
        senderId: staffId,
        receiverId: residentId,
      );

      // Transform data
      _messages = fetchedMessages.map((msg) {
        return {
          'id': msg['id'].toString(),
          'sender_id': msg['sender_id'],
          'sender_type': msg['sender_id'] == staffId ? 'staff' : 'resident',
          'message': msg['content'],
          'timestamp': msg['created_at'],
        };
      }).toList();

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading messages: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _selectedResident == null) {
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final staffId = authProvider.userProfile?['id'];
    if (staffId == null) return;

    final residentId = _selectedResident!['id'];

    // Add message to local list immediately for better UX
    final tempMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'sender_id': staffId,
      'sender_type': 'staff',
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };

    setState(() {
      _messages.add(tempMessage);
    });
    _messageController.clear();

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      await ChatService.sendMessage(
        senderId: staffId,
        receiverId: residentId,
        content: message,
      );
      // Optionally, refresh messages from server to get real ID and timestamp
      // await _loadMessages(residentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
        // Remove the message if sending failed
        setState(() {
          _messages.remove(tempMessage);
        });
      }
    }
  }

  void _selectResident(Map<String, dynamic> resident) {
    setState(() {
      _selectedResident = resident;
      _messages.clear();
    });
    _loadMessages(resident['id']);
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedResident != null
              ? 'Chat with ${_selectedResident!['name']}'
              : 'Resident Chat',
        ),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          if (_selectedResident != null)
            IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () => _showResidentInfo(_selectedResident!),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _selectedResident != null
                ? () => _loadMessages(_selectedResident!['id'])
                : _loadResidents,
          ),
        ],
      ),
      body: Row(
        children: [
          // Residents List (Left Panel)
          Container(
            width: MediaQuery.of(context).size.width * 0.35,
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: Border(
                      bottom: BorderSide(color: Colors.grey[300]!),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.people, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        'All Residents',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _isLoading && _residents.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : _residents.isEmpty
                      ? const Center(child: Text('No residents found'))
                      : ListView.builder(
                          itemCount: _residents.length,
                          itemBuilder: (context, index) {
                            final resident = _residents[index];
                            final isSelected =
                                _selectedResident?['id'] == resident['id'];

                            return Container(
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.indigo[50] : null,
                                border: Border(
                                  bottom: BorderSide(color: Colors.grey[200]!),
                                ),
                              ),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.indigo,
                                  child: Text(
                                    resident['name'][0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                title: Text(
                                  resident['name'],
                                  style: TextStyle(
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Room ${resident['room_number']}'),
                                    if (resident['last_message'] != null)
                                      Text(
                                        resident['last_message'],
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (resident['unread_count'] > 0)
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          resident['unread_count'].toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    if (resident['last_message_time'] != null)
                                      Text(
                                        _formatTime(
                                          resident['last_message_time'],
                                        ),
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () => _selectResident(resident),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),

          // Chat Area (Right Panel)
          Expanded(
            child: _selectedResident == null
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'Select a resident to start chatting',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // Messages Area
                      Expanded(
                        child: _isLoading && _messages.isEmpty
                            ? const Center(child: CircularProgressIndicator())
                            : _messages.isEmpty
                            ? const Center(child: Text('No messages yet'))
                            : ListView.builder(
                                controller: _scrollController,
                                padding: const EdgeInsets.all(16),
                                itemCount: _messages.length,
                                itemBuilder: (context, index) {
                                  final message = _messages[index];
                                  final isFromStaff =
                                      message['sender_type'] == 'staff';

                                  return _buildMessageBubble(
                                    message,
                                    isFromStaff,
                                  );
                                },
                              ),
                      ),

                      // Message Input Area
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _messageController,
                                decoration: const InputDecoration(
                                  hintText: 'Type a message...',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                ),
                                maxLines: null,
                                onSubmitted: (_) => _sendMessage(),
                              ),
                            ),
                            const SizedBox(width: 8),
                            FloatingActionButton(
                              onPressed: _sendMessage,
                              backgroundColor: Colors.indigo,
                              mini: true,
                              child: const Icon(
                                Icons.send,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isFromStaff) {
    return Align(
      alignment: isFromStaff ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isFromStaff ? Colors.indigo : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message['message'],
              style: TextStyle(
                color: isFromStaff ? Colors.white : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message['timestamp']),
              style: TextStyle(
                color: isFromStaff ? Colors.white70 : Colors.grey[600],
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResidentInfo(Map<String, dynamic> resident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Resident Information'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Name', resident['name']),
            _buildInfoRow('Email', resident['email']),
            _buildInfoRow('Phone', resident['phone']),
            _buildInfoRow('Room', resident['room_number']),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 60,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
