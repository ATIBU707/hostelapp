import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'add_room_screen.dart';
import 'manage_rooms_screen.dart';
import 'reservation_approval_screen.dart';
import 'staff_reports_screen.dart';
import 'staff_chat_screen.dart';
import 'staff_profile_screen.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({super.key});

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    // Load staff data when screen initializes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      _loadStaffData(authProvider);
    });
  }

  void _loadStaffData(AuthProvider authProvider) {
    // Load all staff-specific data with access control
    authProvider.fetchStaffMaintenanceRequests();
    // TODO: Add other data loading methods
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, authProvider, child) {
      final userProfile = authProvider.userProfile;
      final staffName = userProfile?['full_name'] ?? 'Staff Member';
      final role = userProfile?['role'] ?? 'staff';

      return Scaffold(
        appBar: AppBar(
          title: Text('Staff Portal - ${role.toUpperCase()}'),
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () {
                _loadStaffData(authProvider);
              },
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.account_circle),
              onSelected: (value) async {
                if (value == 'profile') {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const StaffProfileScreen(),
                    ),
                  );
                } else if (value == 'logout') {
                  await authProvider.signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacementNamed('/login');
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'profile',
                  child: Row(
                    children: [
                      const Icon(Icons.person, size: 20),
                      const SizedBox(width: 8),
                      Text(staffName),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'logout',
                  child: Row(
                    children: [
                      const Icon(Icons.logout, size: 20),
                      const SizedBox(width: 8),
                      const Text('Logout'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: Column(
          children: [
            // Welcome Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.indigo, Colors.indigoAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, $staffName!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage hostel operations and assist residents',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            // Tab Navigation
            Container(
              color: Colors.grey[100],
              child: TabBar(
                controller: _tabController,
                onTap: (index) => setState(() => _selectedIndex = index),
                labelColor: Colors.indigo,
                unselectedLabelColor: Colors.grey[600],
                indicatorColor: Colors.indigo,
                isScrollable: true,
                tabs: const [
                  Tab(
                    icon: Icon(Icons.dashboard),
                    text: 'Overview',
                  ),
                  Tab(
                    icon: Icon(Icons.add_home),
                    text: 'Add Room',
                  ),
                  Tab(
                    icon: Icon(Icons.home_work),
                    text: 'My Rooms',
                  ),
                  Tab(
                    icon: Icon(Icons.approval),
                    text: 'Reservations',
                  ),
                  Tab(
                    icon: Icon(Icons.analytics),
                    text: 'Reports',
                  ),
                  Tab(
                    icon: Icon(Icons.chat),
                    text: 'Chat',
                  ),
                  Tab(
                    icon: Icon(Icons.person),
                    text: 'Profile',
                  ),
                ],
              ),
            ),
            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(authProvider),
                  const AddRoomScreen(),
                  const ManageRoomsScreen(),
                  const ReservationApprovalScreen(),
                  const StaffReportsScreen(),
                  const StaffChatScreen(),
                  const StaffProfileScreen(),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildOverviewTab(AuthProvider authProvider) {
    final maintenanceRequests = authProvider.staffMaintenanceRequests ?? [];
    final pendingRequests = maintenanceRequests.where((req) => req['status'] == 'pending').length;
    final inProgressRequests = maintenanceRequests.where((req) => req['status'] == 'in_progress').length;
    final completedRequests = maintenanceRequests.where((req) => req['status'] == 'completed').length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          // Statistics Cards
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Pending Requests',
                  pendingRequests.toString(),
                  Colors.orange,
                  Icons.pending_actions,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'In Progress',
                  inProgressRequests.toString(),
                  Colors.blue,
                  Icons.build,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Completed',
                  completedRequests.toString(),
                  Colors.green,
                  Icons.check_circle,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  'Total Requests',
                  maintenanceRequests.length.toString(),
                  Colors.indigo,
                  Icons.assignment,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Recent Activity
          const Text(
            'Recent Maintenance Requests',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          if (authProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (maintenanceRequests.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: Text(
                    'No maintenance requests found',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ...maintenanceRequests.take(5).map((request) => _buildRequestCard(request)),
        ],
      ),
    );
  }



  Widget _buildStatCard(String title, String value, Color color, IconData icon) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequestCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    final category = request['category'] ?? 'General';
    final description = request['description'] ?? 'No description';
    final createdAt = request['created_at'];

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.build;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(statusIcon, color: statusColor, size: 20),
        ),
        title: Text(
          category,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Chip(
          label: Text(
            status.toUpperCase(),
            style: const TextStyle(fontSize: 10),
          ),
          backgroundColor: statusColor.withOpacity(0.1),
          labelStyle: TextStyle(color: statusColor),
        ),
      ),
    );
  }

  Widget _buildDetailedRequestCard(Map<String, dynamic> request) {
    final status = request['status'] ?? 'pending';
    final category = request['category'] ?? 'General';
    final description = request['description'] ?? 'No description';
    final createdAt = request['created_at'];
    final residentName = request['resident_name'] ?? 'Unknown Resident';
    final roomNumber = request['room_number']?.toString() ?? 'N/A';

    Color statusColor;
    IconData statusIcon;
    switch (status) {
      case 'completed':
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case 'in_progress':
        statusColor = Colors.blue;
        statusIcon = Icons.build;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.pending_actions;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    category,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    status.toUpperCase(),
                    style: const TextStyle(fontSize: 10),
                  ),
                  backgroundColor: statusColor.withOpacity(0.1),
                  labelStyle: TextStyle(color: statusColor),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.person, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  residentName,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const SizedBox(width: 16),
                Icon(Icons.room, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  'Room $roomNumber',
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
            if (status == 'pending') ...[
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      // TODO: Implement status update
                    },
                    child: const Text('Mark In Progress'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      // TODO: Implement status update
                    },
                    child: const Text('Mark Complete'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
