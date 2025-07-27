import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';

class ProfileTab extends StatelessWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final profile = authProvider.userProfile;
        if (profile == null) {
          return const Center(child: CircularProgressIndicator());
        }

        return ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            const SizedBox(height: 20),
            // Avatar
            Center(
              child: CircleAvatar(
                radius: 50,
                backgroundImage: profile['avatar_url'] != null
                    ? NetworkImage(profile['avatar_url'])
                    : null,
                child: profile['avatar_url'] == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            // Full Name
            Center(
              child: Text(
                profile['full_name'] ?? 'N/A',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            // Role
            Center(
              child: Chip(
                label: Text(profile['role'] ?? 'resident'),
              ),
            ),
            const SizedBox(height: 30),
            const Divider(),
            // Profile Details
            _buildProfileDetail(Icons.email_outlined, 'Email', profile['email'] ?? 'N/A'),
            _buildProfileDetail(Icons.phone_outlined, 'Phone', profile['phone'] ?? 'N/A'),
            const Divider(),
            const SizedBox(height: 20),
            // Edit Profile Button
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/edit-profile');
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Edit Profile'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildProfileDetail(IconData icon, String title, String value) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }
}
