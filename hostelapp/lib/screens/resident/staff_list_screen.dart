import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'chat_screen.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchStaffMembers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contact Staff'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading && authProvider.staffMembers == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final staff = authProvider.staffMembers;

          if (staff == null || staff.isEmpty) {
            return const Center(
              child: Text(
                'No staff members available to contact.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => authProvider.fetchStaffMembers(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: staff.length,
              itemBuilder: (context, index) {
                final member = staff[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16.0),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blue[100],
                      child: Icon(
                        Icons.person,
                        color: Colors.blue[700],
                      ),
                    ),
                    title: Text(
                      member['full_name'] ?? 'N/A',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.badge,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              member['role']?.toUpperCase() ?? 'N/A',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (member['phone'] != null) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.phone,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                member['phone'],
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Call button (if phone available)
                        if (member['phone'] != null)
                          IconButton(
                            onPressed: () {
                              // You can implement phone calling functionality here
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Call ${member['phone']}'),
                                  action: SnackBarAction(
                                    label: 'OK',
                                    onPressed: () {},
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.phone, color: Colors.green),
                            tooltip: 'Call',
                          ),
                        // Chat button
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ChatScreen(
                                  receiverId: member['id'],
                                  receiverName: member['full_name'] ?? 'Staff',
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.chat, color: Colors.blue),
                          tooltip: 'Chat',
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            receiverId: member['id'],
                            receiverName: member['full_name'] ?? 'Staff',
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
