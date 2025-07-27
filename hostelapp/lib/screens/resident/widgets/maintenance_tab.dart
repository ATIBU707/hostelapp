import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../providers/auth_provider.dart';

class MaintenanceTab extends StatelessWidget {
  final VoidCallback onCreateNewRequest;

  const MaintenanceTab({super.key, required this.onCreateNewRequest});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading && authProvider.maintenanceRequests == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final requests = authProvider.maintenanceRequests;

          if (requests == null || requests.isEmpty) {
            return const Center(
              child: Text(
                'No maintenance requests found.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: requests.length,
            itemBuilder: (context, index) {
              final request = requests[index];
              final requestDate = DateTime.parse(request['created_at']);
              final formattedDate = DateFormat.yMMMd().format(requestDate);

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(_getCategoryIcon(request['category'])),
                  title: Text(
                    request['category'],
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Reported on $formattedDate'),
                  trailing: Chip(
                    label: Text(
                      request['status'] ?? 'Pending',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: _getStatusColor(request['status']),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: onCreateNewRequest,
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'plumbing':
        return Icons.water_damage_outlined;
      case 'electrical':
        return Icons.electrical_services_outlined;
      case 'general':
      default:
        return Icons.build_outlined;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.orange;
      case 'pending':
      default:
        return Colors.blue;
    }
  }


}
