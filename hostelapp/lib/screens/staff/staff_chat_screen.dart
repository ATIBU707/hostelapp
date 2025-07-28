import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class StaffChatScreen extends StatefulWidget {
  const StaffChatScreen({super.key});

  @override
  State<StaffChatScreen> createState() => _StaffChatScreenState();
}

class _StaffChatScreenState extends State<StaffChatScreen> {
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
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadResidents() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final staffId = authProvider.userProfile?['id'];
      
      if (staffId == null) {
        throw Exception('Staff ID not found');
      }

      // TODO: Implement resident fetching in AuthProvider
      // Only fetch residents from rooms managed by this staff member
      // _residents = await authProvider.getStaffResidents(staffId);
      
      // Mock data for demonstration
      _residents = [
        {
          'id': '1',
          'name': 'John Doe',
          'email': 'john@example.com',
          'room_number': '101',
          'phone': '+1234567890',
          'last_message': 'Thank you for fixing the AC!',
          'last_message_time': '2024-01-25T14:30:00Z',
          'unread_count': 0,
          'avatar': null,
        },
        {
          'id': '2',
          'name': 'Jane Smith',
          'email': 'jane@example.com',
          'room_number': '102',
          'phone': '+1234567891',
          'last_message': 'Can you help with the WiFi issue?',
          'last_message_time': '2024-01-25T16:45:00Z',
          'unread_count': 2,
          'avatar': null,
        },
        {
          'id': '3',
          'name': 'Mike Johnson',
          'email': 'mike@example.com',
          'room_number': '104',
          'phone': '+1234567892',
          'last_message': 'Good morning!',
          'last_message_time': '2024-01-25T09:15:00Z',
          'unread_count': 1,
          'avatar': null,
        },
      ];
      
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
      setState(() => _isLoading = false);
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

      // TODO: Implement message fetching in AuthProvider
      // _messages = await authProvider.getChatMessages(staffId, residentId);
      
      // Mock data for demonstration
      _messages = [
        {
          'id': '1',
          'sender_id': residentId,
          'sender_type': 'resident',
          'message': 'Hi, I have an issue with my room AC',
          'timestamp': '2024-01-25T10:00:00Z',
          'read': true,
        },
        {
          'id': '2',
          'sender_id': staffId,
          'sender_type': 'staff',
          'message': 'Hello! I\'ll send someone to check it right away.',
          'timestamp': '2024-01-25T10:05:00Z',
          'read': true,
        },
        {
          'id': '3',
          'sender_id': residentId,
          'sender_type': 'resident',
          'message': 'Thank you for fixing the AC!',
          'timestamp': '2024-01-25T14:30:00Z',
          'read': true,
        },
      ];
      
      // Mark messages as read
      // TODO: Implement mark as read functionality
      
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
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _selectedResident == null) return;

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final staffId = authProvider.userProfile?['id'];
      
      if (staffId == null) {
        throw Exception('Staff ID not found');
      }

      // Add message to local state immediately for better UX
      final newMessage = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'sender_id': staffId,
        'sender_type': 'staff',
        'message': message,
        'timestamp': DateTime.now().toIso8601String(),
        'read': true,
      };

      setState(() {
        _messages.add(newMessage);
        _messageController.clear();
      });

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

      // TODO: Implement message sending in AuthProvider
      // await authProvider.sendMessage(staffId, _selectedResident!['id'], message);
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending message: $e'),
            backgroundColor: Colors.red,
          ),
        );
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
        title: Text(_selectedResident != null 
            ? 'Chat with ${_selectedResident!['name']}'
            : 'Resident Chat'),
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
                    border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.people, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        'Your Residents',
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
                          ? const Center(
                              child: Text('No residents found'),
                            )
                          : ListView.builder(
                              itemCount: _residents.length,
                              itemBuilder: (context, index) {
                                final resident = _residents[index];
                                final isSelected = _selectedResident?['id'] == resident['id'];
                                
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
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
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
                                            _formatTime(resident['last_message_time']),
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
                        Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'Select a resident to start chatting',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
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
                                ? const Center(
                                    child: Text('No messages yet'),
                                  )
                                : ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(16),
                                    itemCount: _messages.length,
                                    itemBuilder: (context, index) {
                                      final message = _messages[index];
                                      final isFromStaff = message['sender_type'] == 'staff';
                                      
                                      return _buildMessageBubble(message, isFromStaff);
                                    },
                                  ),
                      ),
                      
                      // Message Input Area
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: Colors.grey[300]!)),
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
                              child: const Icon(Icons.send, color: Colors.white),
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
