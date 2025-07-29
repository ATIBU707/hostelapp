import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class HomeTab extends StatelessWidget {
  final Function(int) onNavigateToTab;
  final VoidCallback onCreateNewRequest;

  const HomeTab({
    super.key,
    required this.onNavigateToTab,
    required this.onCreateNewRequest,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final residentName = authProvider.userProfile?['full_name'] ?? 'Resident';

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Welcome Message
            Text(
              'Welcome, $residentName!',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),

            // Room Information Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Room', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    if (authProvider.activeBooking != null)
                      ListTile(
                        leading: const Icon(Icons.king_bed_outlined),
                        title: Text(
                            'Room ${authProvider.activeBooking!['room']?['room_number'] ?? 'N/A'} - Bed ${authProvider.activeBooking!['bed']?['bed_number'] ?? 'N/A'}'),
                        subtitle: Text(authProvider.activeBooking!['room']?['room_type'] ?? 'No room details'),
                      )
                    else
                      const ListTile(
                        leading: Icon(Icons.info_outline),
                        title: Text('No Active Booking'),
                        subtitle: Text('Please contact administration.'),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Quick Actions
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                if (authProvider.activeBooking == null)
                  _buildActionCard(
                    context,
                    Icons.king_bed_outlined,
                    'Book a Room',
                    () => Navigator.pushNamed(context, '/book-room'),
                  ),
                if (authProvider.activeBooking != null)
                  _buildActionCard(context, Icons.payment, 'Pay Rent', () {}),
                if (authProvider.activeBooking != null)
                  _buildActionCard(context, Icons.build, 'New Request', onCreateNewRequest),
                // _buildActionCard(
                //   context,
                //   Icons.campaign,
                //   'Announcements',
                //   () => Navigator.pushNamed(context, '/announcements'),
                // ),
                _buildActionCard(
                  context,
                  Icons.contact_support_outlined,
                  'Contact Admin',
                  () => Navigator.pushNamed(context, '/staff-list'),
                ),
                if (authProvider.activeBooking != null)
                  _buildActionCard(
                    context,
                    Icons.receipt_long,
                    'Payment History',
                    () => onNavigateToTab(2),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

    Widget _buildActionCard(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: Theme.of(context).primaryColor),
            const SizedBox(height: 8),
            Text(label, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
