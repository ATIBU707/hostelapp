import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class StaffReportsScreen extends StatefulWidget {
  const StaffReportsScreen({super.key});

  @override
  State<StaffReportsScreen> createState() => _StaffReportsScreenState();
}

class _StaffReportsScreenState extends State<StaffReportsScreen> {
  bool _isLoading = false;
  String _selectedPeriod = 'month';
  Map<String, dynamic> _reportData = {};

  final List<String> _periodOptions = ['week', 'month', 'quarter', 'year'];

  @override
  void initState() {
    super.initState();
    _loadReports();
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final staffId = authProvider.userProfile?['id'];
      
      if (staffId == null) {
        throw Exception('Staff ID not found');
      }

      // TODO: Implement report data fetching in AuthProvider
      // Only fetch data for rooms/residents managed by this staff member
      // _reportData = await authProvider.getStaffReports(staffId, _selectedPeriod);
      
      // Mock data for demonstration
      _reportData = {
        'occupancy': {
          'total_rooms': 8,
          'occupied_rooms': 6,
          'available_rooms': 2,
          'occupancy_rate': 75.0,
        },
        'revenue': {
          'total_revenue': 42000.0,
          'expected_revenue': 48000.0,
          'collection_rate': 87.5,
        },
        'residents': {
          'total_residents': 12,
          'new_residents': 3,
          'departing_residents': 1,
          'pending_applications': 4,
        },
        'maintenance': {
          'total_requests': 15,
          'completed_requests': 12,
          'pending_requests': 3,
          'average_resolution_time': 2.5,
        },
        'room_breakdown': [
          {'room_number': '101', 'type': 'single', 'status': 'occupied', 'rent': 5000, 'resident': 'John Doe'},
          {'room_number': '102', 'type': 'double', 'status': 'occupied', 'rent': 7000, 'resident': 'Jane Smith'},
          {'room_number': '103', 'type': 'single', 'status': 'available', 'rent': 5000, 'resident': null},
          {'room_number': '104', 'type': 'triple', 'status': 'occupied', 'rent': 9000, 'resident': 'Mike Johnson'},
        ],
        'recent_activities': [
          {'date': '2024-01-25', 'activity': 'New resident check-in', 'details': 'John Doe - Room 101'},
          {'date': '2024-01-24', 'activity': 'Maintenance completed', 'details': 'Fixed AC in Room 102'},
          {'date': '2024-01-23', 'activity': 'Reservation approved', 'details': 'Jane Smith - Room 102'},
          {'date': '2024-01-22', 'activity': 'Room added', 'details': 'Room 105 - Single type'},
        ],
      };
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reports: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff Reports'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: Column(
        children: [
          // Period Selection
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Period: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _periodOptions.map((period) {
                        final isSelected = _selectedPeriod == period;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(period.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedPeriod = period);
                              _loadReports();
                            },
                            selectedColor: Colors.indigo[100],
                            checkmarkColor: Colors.indigo,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Reports Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reportData.isEmpty
                    ? const Center(
                        child: Text('No report data available'),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOverviewSection(),
                            const SizedBox(height: 24),
                            _buildRoomBreakdownSection(),
                            const SizedBox(height: 24),
                            _buildRecentActivitiesSection(),
                          ],
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewSection() {
    final occupancy = _reportData['occupancy'] as Map<String, dynamic>? ?? {};
    final revenue = _reportData['revenue'] as Map<String, dynamic>? ?? {};
    final residents = _reportData['residents'] as Map<String, dynamic>? ?? {};
    final maintenance = _reportData['maintenance'] as Map<String, dynamic>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        // Occupancy Stats
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Occupancy Rate',
                '${occupancy['occupancy_rate']?.toStringAsFixed(1) ?? '0'}%',
                Colors.blue,
                Icons.home,
                subtitle: '${occupancy['occupied_rooms'] ?? 0}/${occupancy['total_rooms'] ?? 0} rooms',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Total Revenue',
                '\$${revenue['total_revenue']?.toStringAsFixed(0) ?? '0'}',
                Colors.green,
                Icons.attach_money,
                subtitle: '${revenue['collection_rate']?.toStringAsFixed(1) ?? '0'}% collected',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                'Total Residents',
                '${residents['total_residents'] ?? 0}',
                Colors.purple,
                Icons.people,
                subtitle: '${residents['new_residents'] ?? 0} new this $_selectedPeriod',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Maintenance',
                '${maintenance['pending_requests'] ?? 0} pending',
                Colors.orange,
                Icons.build,
                subtitle: '${maintenance['completed_requests'] ?? 0} completed',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color, IconData icon, {String? subtitle}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRoomBreakdownSection() {
    final roomBreakdown = _reportData['room_breakdown'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Room Breakdown',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        if (roomBreakdown.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No rooms found')),
            ),
          )
        else
          ...roomBreakdown.map((room) => _buildRoomCard(room as Map<String, dynamic>)),
      ],
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final status = room['status'] as String;
    final statusColor = status == 'occupied' ? Colors.green : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor),
              ),
              child: Center(
                child: Text(
                  room['room_number'],
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${room['type'].toString().toUpperCase()} Room',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    status == 'occupied' 
                        ? 'Resident: ${room['resident'] ?? 'Unknown'}'
                        : 'Available for booking',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rent: \$${room['rent']}/month',
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor),
              ),
              child: Text(
                status.toUpperCase(),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitiesSection() {
    final activities = _reportData['recent_activities'] as List<dynamic>? ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activities',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        
        if (activities.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: Text('No recent activities')),
            ),
          )
        else
          Card(
            child: Column(
              children: activities.asMap().entries.map((entry) {
                final index = entry.key;
                final activity = entry.value as Map<String, dynamic>;
                final isLast = index == activities.length - 1;
                
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: Colors.indigo,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activity['activity'] ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activity['details'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  activity['date'] ?? '',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!isLast) const Divider(height: 1),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}
