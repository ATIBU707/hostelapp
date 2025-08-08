import 'package:flutter/material.dart';
import 'package:hostelapp/providers/auth_provider.dart';
import 'package:hostelapp/services/chat_service.dart';
import 'package:hostelapp/services/staff_service.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// A type-safe data class for chat contacts
class ChatContact {
  final String id;
  final String name;
  final String email;
  final String phone;

  ChatContact({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  // Factory constructor to create a ChatContact from a map, with null safety
  factory ChatContact.fromMap(Map<String, dynamic> map) {
    return ChatContact(
      id: map['id'] as String? ?? '', // Should not be null, but good to be safe
      name: map['full_name'] as String? ?? 'Unnamed Resident',
      email: map['email'] as String? ?? 'No Email',
      phone: map['phone'] as String? ?? 'No Phone',
    );
  }
}

class StaffChatScreen extends StatefulWidget {
  const StaffChatScreen({super.key});

  @override
  State<StaffChatScreen> createState() => _StaffChatScreenState();
}

class _StaffChatScreenState extends State<StaffChatScreen> {
  List<ChatContact> _residents = [];
  ChatContact? _selectedResident;
  bool _isLoading = true;
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Stream<List<Map<String, dynamic>>>? _messageStream;
  String? _staffId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _staffId = authProvider.userProfile?['id'];
      _loadResidents();
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadResidents() async {
    if (_staffId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not authenticate staff. Please restart.')),
        );
      }
      return;
    }

    setState(() => _isLoading = true);
    try {
      final residentsData = await StaffService.getStaffChatContacts(_staffId!);
      if (mounted) {
        setState(() {
          _residents = residentsData
              .where((data) => data['id'] != null)
              .map((data) => ChatContact.fromMap(data))
              .toList();
          if (_residents.isNotEmpty) {
            _selectResident(_residents.first);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading residents: $e')),
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
    if (message.isEmpty || _selectedResident == null || _staffId == null) {
      return;
    }

    final residentId = _selectedResident!.id;
    _messageController.clear();

    try {
      await ChatService.sendMessage(
        senderId: _staffId!,
        receiverId: residentId,
        content: message,
      );
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

  void _selectResident(ChatContact resident) {
    if (_staffId == null) return;
    setState(() {
      _selectedResident = resident;
      _messageStream = ChatService.getMessagesPolling(_staffId!, resident.id);
    });
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
        title: Text(_selectedResident != null ? 'Chat with ${_selectedResident!.name}' : 'Resident Chat'),
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
            onPressed: _loadResidents,
          ),
        ],
      ),
      body: Row(
        children: [
          // Residents List (Left Panel)
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.35,
            child: Column(
              children: [
                _buildResidentListHeader(),
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _residents.isEmpty
                          ? const Center(child: Text('No residents found'))
                          : _buildResidentListView(),
                ),
              ],
            ),
          ),

          // Chat Area (Right Panel)
          Expanded(
            child: _selectedResident == null
                ? _buildEmptyChatView()
                : _buildChatView(),
          ),
        ],
      ),
    );
  }

  Widget _buildResidentListHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: const Row(
        children: [
          Icon(Icons.people, color: Colors.indigo),
          SizedBox(width: 8),
          Text('All Residents', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildResidentListView() {
    return ListView.builder(
      itemCount: _residents.length,
      itemBuilder: (context, index) {
        final resident = _residents[index];
        final isSelected = _selectedResident?.id == resident.id;

        return Material(
          color: isSelected ? Colors.indigo.withOpacity(0.1) : Colors.transparent,
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.indigo,
              child: Text(
                resident.name.isNotEmpty ? resident.name[0].toUpperCase() : 'N',
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text(resident.name),
            subtitle: const Text('Chat', maxLines: 1, overflow: TextOverflow.ellipsis),
            onTap: () => _selectResident(resident),
          ),
        );
      },
    );
  }

  Widget _buildEmptyChatView() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text('Select a resident to start chatting', style: TextStyle(fontSize: 16, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildChatView() {
    return Column(
      children: [
        Expanded(
          child: StreamBuilder<List<Map<String, dynamic>>>(
            stream: _messageStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('No messages yet. Start the conversation!', style: TextStyle(color: Colors.grey)),
                );
              }

              final messages = snapshot.data!;

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (_scrollController.hasClients) {
                  _scrollController.animateTo(
                    _scrollController.position.maxScrollExtent,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOut,
                  );
                }
              });

              return ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isFromStaff = message['sender_id'] == _staffId;
                  return _buildMessageBubble(message, isFromStaff);
                },
              );
            },
          ),
        ),
        _buildMessageInputArea(),
      ],
    );
  }

  Widget _buildMessageInputArea() {
    return Container(
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
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message, bool isFromStaff) {
    final content = message['content'] as String? ?? '[empty message]';
    final timestamp = message['created_at'] as String? ?? DateTime.now().toIso8601String();

    return Align(
      alignment: isFromStaff ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isFromStaff ? Colors.indigo : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content, style: TextStyle(color: isFromStaff ? Colors.white : Colors.black87, fontSize: 14)),
            const SizedBox(height: 4),
            Text(_formatTime(timestamp), style: TextStyle(color: isFromStaff ? Colors.white70 : Colors.grey[600], fontSize: 10)),
          ],
        ),
      ),
    );
  }

  void _showResidentInfo(ChatContact resident) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(resident.name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${resident.email}'),
            const SizedBox(height: 8),
            Text('Phone: ${resident.phone}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
