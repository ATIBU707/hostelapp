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
              itemCount: staff.length,
              itemBuilder: (context, index) {
                final member = staff[index];
                return ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(member['full_name'] ?? 'N/A'),
                  subtitle: Text(member['role'] ?? 'N/A'),
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
                );
              },
            ),
          );
        },
      ),
    );
  }
}
