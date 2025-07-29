import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RoomBookingScreen extends StatefulWidget {
  const RoomBookingScreen({super.key});

  @override
  State<RoomBookingScreen> createState() => _RoomBookingScreenState();
}

class _RoomBookingScreenState extends State<RoomBookingScreen> {
  Map<String, String> _bookingStatuses = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadInitialData();
    });
  }

  Future<void> _loadInitialData() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.fetchAvailableRooms();
    await authProvider.fetchResidentBookings();
    _updateBookingStatuses();
  }

  void _updateBookingStatuses() {
    final bookings = Provider.of<AuthProvider>(context, listen: false).residentBookings;
        final Map<String, String> statuses = { for (var booking in bookings) booking['bed_id'].toString() : booking['status'] };
    if (mounted) {
      setState(() {
        _bookingStatuses = statuses;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Book a Room'),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          if (authProvider.isLoading && authProvider.availableRooms == null) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading available rooms...'),
                ],
              ),
            );
          }

          // Show error message if there's an error
          if (authProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading rooms',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Text(
                      authProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => authProvider.fetchAvailableRooms(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final rooms = authProvider.availableRooms;
          
          // Debug information
          print('DEBUG: rooms data: $rooms');
          print('DEBUG: rooms length: ${rooms?.length}');
          if (rooms != null && rooms.isNotEmpty) {
            print('DEBUG: first room structure: ${rooms[0]}');
            print('DEBUG: first room beds: ${rooms[0]['beds']}');
          }

          if (rooms == null || rooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_outlined,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No available rooms at the moment.',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please check back later or contact staff.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => authProvider.fetchAvailableRooms(),
                    child: const Text('Refresh'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _loadInitialData,
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                print('DEBUG: Processing room ${index}: ${room['room_number']}');
                print('DEBUG: Room beds raw: ${room['beds']}');
                
                final beds = (room['beds'] as List)
                    .where((bed) => bed['is_available'] == true)
                    .toList();
                
                print('DEBUG: Available beds after filtering: ${beds.length}');
                print('DEBUG: Available beds: $beds');

                if (beds.isEmpty) {
                  print('DEBUG: Room ${room['room_number']} hidden - no available beds');
                  return const SizedBox.shrink(); // Don't show rooms with no available beds
                }
                
                print('DEBUG: Room ${room['room_number']} will be displayed with ${beds.length} beds');

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  elevation: 4,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room Header
                        Row(
                          children: [
                            Icon(
                              Icons.home,
                              color: Theme.of(context).primaryColor,
                              size: 24,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Room ${room['room_number']} - ${room['room_type']}',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        
                        // Room Details
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.people, size: 16, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text('Capacity: ${room['capacity']}'),
                                  const Spacer(),
                                  const Icon(Icons.attach_money, size: 16, color: Colors.green),
                                  Text(
                                    'KSh ${room['rent_amount']}/month',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                              if (room['description'] != null && room['description'].isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  room['description'],
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ],
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 12),
                        
                        // Staff Information
                        if (room['profiles'] != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.person, color: Colors.blue),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Managed by: ${room['profiles']['full_name'] ?? 'Staff'}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                      if (room['profiles']['phone'] != null)
                                        Text(
                                          'Phone: ${room['profiles']['phone']}',
                                          style: TextStyle(color: Colors.grey[600]),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        
                        const Text(
                          'Available Beds:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        
                        ...beds.map((bed) {
                          final bedId = bed['id'].toString();
                          final bookingStatus = _bookingStatuses[bedId];
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                              color: bookingStatus != null ? Colors.grey[100] : null,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.bed,
                                  color: bookingStatus != null ? Colors.grey[400] : Colors.grey[600],
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Bed ${bed['bed_number']}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: bookingStatus != null ? Colors.grey[600] : Colors.black,
                                    ),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: bookingStatus != null ? null : () async {
                                    // Show confirmation dialog
                                    final confirmed = await showDialog<bool>(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title: const Text('Confirm Booking'),
                                        content: Text(
                                          'Do you want to book Bed ${bed['bed_number']} in Room ${room['room_number']}?\n\nRent: KSh ${room['rent_amount']}/month',
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(context, false),
                                            child: const Text('Cancel'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () => Navigator.pop(context, true),
                                            child: const Text('Confirm'),
                                          ),
                                        ],
                                      ),
                                    );
                                    
                                    if (confirmed == true) {
                                      try {
                                        await authProvider.bookRoom(
                                          roomId: room['id'].toString(),
                                          bedId: bed['id'].toString(),
                                        );
                                        
                                        if (mounted) {
                                          // Update the status locally for immediate feedback
                                          setState(() {
                                            _bookingStatuses[bedId] = 'pending';
                                          });

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Booking request sent! Your booking is pending approval.'),
                                              backgroundColor: Colors.orange,
                                            ),
                                          );

                                          // Refresh data to ensure consistency
                                          _loadInitialData();
                                        }
                                      } catch (e) {
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Booking failed: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      }
                                    }
                                  },
                                  icon: Icon(
                                    bookingStatus == 'approved' 
                                        ? Icons.check_circle 
                                        : bookingStatus == 'pending' 
                                            ? Icons.hourglass_empty
                                            : Icons.book_online,
                                    size: 16
                                  ),
                                  label: Text(
                                    bookingStatus == 'approved'
                                        ? 'Reserved'
                                        : bookingStatus == 'pending'
                                            ? 'Pending'
                                            : bookingStatus == 'rejected'
                                                ? 'Rejected'
                                                : 'Book'
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: bookingStatus == 'approved'
                                        ? Colors.blue
                                        : bookingStatus == 'pending'
                                            ? Colors.orange
                                            : bookingStatus == 'rejected'
                                                ? Colors.red
                                                : Colors.green,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ],
                    ),
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
