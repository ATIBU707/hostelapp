import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/staff_service.dart';

class ReservationApprovalScreen extends StatefulWidget {
  const ReservationApprovalScreen({super.key});

  @override
  State<ReservationApprovalScreen> createState() => _ReservationApprovalScreenState();
}

class _ReservationApprovalScreenState extends State<ReservationApprovalScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _pendingReservations = [];
  String _selectedFilter = 'all';

  final List<String> _filterOptions = ['all', 'pending', 'approved', 'rejected'];

  @override
  void initState() {
    super.initState();
    _loadReservations();
  }

  Future<void> _loadReservations() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.fetchStaffBookings();

      final bookings = authProvider.staffBookings;
      
      // Transform data to match the UI widget's expected structure
      _pendingReservations = bookings.map((booking) {
        final resident = booking['residents'] ?? {};
        final room = booking['rooms'] ?? {};
        
        return {
          'id': booking['id'].toString(),
          'resident_name': resident['full_name'] ?? 'N/A',
          'resident_email': resident['email'] ?? 'N/A',
          'resident_phone': resident['phone'] ?? 'N/A',
          'room_number': room['room_number'] ?? 'N/A',
          'room_type': room['room_type'] ?? 'N/A',
          'check_in_date': booking['start_date'] ?? 'N/A',
          'check_out_date': booking['end_date'] ?? 'N/A',
          'rent_amount': room['rent_amount']?.toDouble() ?? 0.0,
          'status': booking['status'] ?? 'pending',
          'created_at': booking['created_at'] ?? 'N/A',
          'duration_months': booking['duration_months'] ?? 0,
        };
      }).toList();

    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading reservations: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _updateReservationStatus(String reservationId, String status, {String? reason}) async {
    try {
      await StaffService.updateBookingStatus(bookingId: reservationId, status: status);

      // Refresh the list after updating
      await _loadReservations();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Reservation ${status == 'approved' ? 'approved' : 'rejected'} successfully!'),
            backgroundColor: status == 'approved' ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating reservation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReservationDetails(Map<String, dynamic> reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reservation Details'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Resident', reservation['resident_name']),
              _buildDetailRow('Email', reservation['resident_email']),
              _buildDetailRow('Phone', reservation['resident_phone']),
              _buildDetailRow('Room', reservation['room_number']),
              _buildDetailRow('Room Type', reservation['room_type'].toString().toUpperCase()),
              _buildDetailRow('Check-in', reservation['check_in_date']),
              _buildDetailRow('Check-out', reservation['check_out_date']),
              _buildDetailRow('Duration', '${reservation['duration_months']} months'),
              _buildDetailRow('Rent Amount', 'UGX${reservation['rent_amount']}'),
              _buildDetailRow('Status', reservation['status'].toString().toUpperCase()),
              if (reservation['rejection_reason'] != null)
                _buildDetailRow('Rejection Reason', reservation['rejection_reason']),
            ],
          ),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
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

  void _showApprovalDialog(Map<String, dynamic> reservation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Reservation'),
        content: Text('Are you sure you want to approve this reservation for ${reservation['resident_name']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateReservationStatus(reservation['id'], 'approved');
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve'),
          ),
        ],
      ),
    );
  }

  void _showRejectionDialog(Map<String, dynamic> reservation) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Reservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to reject this reservation for ${reservation['resident_name']}?'),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Reason for rejection',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateReservationStatus(
                reservation['id'], 
                'rejected', 
                reason: reasonController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredReservations {
    if (_selectedFilter == 'all') return _pendingReservations;
    return _pendingReservations.where((r) => r['status'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reservation Approvals'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReservations,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Filter: ', style: TextStyle(fontWeight: FontWeight.bold)),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _filterOptions.map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter.toUpperCase()),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() => _selectedFilter = filter);
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
          
          // Reservations List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredReservations.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              'No ${_selectedFilter == 'all' ? '' : _selectedFilter} reservations found',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredReservations.length,
                        itemBuilder: (context, index) {
                          final reservation = _filteredReservations[index];
                          return _buildReservationCard(reservation);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationCard(Map<String, dynamic> reservation) {
    final status = reservation['status'] as String;
    final statusColor = status == 'approved' 
        ? Colors.green 
        : status == 'rejected' 
            ? Colors.red 
            : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    reservation['resident_name'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.room, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('Room ${reservation['room_number']} (${reservation['room_type']})'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('${reservation['check_in_date']} - ${reservation['check_out_date']}'),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.attach_money, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text('\$${reservation['rent_amount']}/month'),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => _showReservationDetails(reservation),
                  icon: const Icon(Icons.info_outline),
                  label: const Text('Details'),
                ),
                if (status == 'pending') ...[
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _showRejectionDialog(reservation),
                        icon: const Icon(Icons.close, size: 16),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: () => _showApprovalDialog(reservation),
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Approve'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
