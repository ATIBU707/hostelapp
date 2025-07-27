import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class RoomBookingScreen extends StatefulWidget {
  const RoomBookingScreen({super.key});

  @override
  State<RoomBookingScreen> createState() => _RoomBookingScreenState();
}

class _RoomBookingScreenState extends State<RoomBookingScreen> {
  @override
  void initState() {
    super.initState();
    // Fetch available rooms when the screen is first loaded
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AuthProvider>(context, listen: false).fetchAvailableRooms();
    });
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
            return const Center(child: CircularProgressIndicator());
          }

          final rooms = authProvider.availableRooms;

          if (rooms == null || rooms.isEmpty) {
            return const Center(
              child: Text(
                'No available rooms at the moment.',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => authProvider.fetchAvailableRooms(),
            child: ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final beds = (room['beds'] as List)
                    .where((bed) => bed['is_available'] == true)
                    .toList();

                if (beds.isEmpty) {
                  return const SizedBox.shrink(); // Don't show rooms with no available beds
                }

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Room ${room['room_number']} - ${room['room_type']}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        const Text(
                          'Available Beds:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...beds.map((bed) {
                          return ListTile(
                            title: Text('Bed ${bed['bed_number']}'),
                            trailing: ElevatedButton(
                              onPressed: () async {
                                await authProvider.bookRoom(
                                  roomId: room['id'],
                                  bedId: bed['id'],
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Booking successful!')),
                                  );
                                  Navigator.pop(context); // Go back after booking
                                }
                              },
                              child: const Text('Book Now'),
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
