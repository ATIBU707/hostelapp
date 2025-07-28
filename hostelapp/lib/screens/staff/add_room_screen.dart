import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});

  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberController = TextEditingController();
  final _roomTypeController = TextEditingController();
  final _capacityController = TextEditingController();
  final _rentController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String _selectedRoomType = 'single';
  bool _isLoading = false;

  final List<String> _roomTypes = [
    'single',
    'double',
    'triple',
    'quad',
    'dormitory'
  ];

  @override
  void dispose() {
    _roomNumberController.dispose();
    _roomTypeController.dispose();
    _capacityController.dispose();
    _rentController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _addRoom() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // Use the new AuthProvider method to add room to Supabase
      await authProvider.addRoom(
        roomNumber: _roomNumberController.text.trim(),
        roomType: _selectedRoomType,
        capacity: int.parse(_capacityController.text),
        rentAmount: double.parse(_rentController.text),
        description: _descriptionController.text.trim().isEmpty 
            ? null 
            : _descriptionController.text.trim(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Room added successfully and is now available for booking!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding room: $e'),
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
        title: const Text('Add New Room'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Room Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),
              
              // Room Number
              TextFormField(
                controller: _roomNumberController,
                decoration: const InputDecoration(
                  labelText: 'Room Number',
                  hintText: 'e.g., 101, A-205',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.room),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter room number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Room Type Dropdown
              DropdownButtonFormField<String>(
                value: _selectedRoomType,
                decoration: const InputDecoration(
                  labelText: 'Room Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _roomTypes.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.toUpperCase()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() => _selectedRoomType = value!);
                },
              ),
              const SizedBox(height: 16),
              
              // Capacity
              TextFormField(
                controller: _capacityController,
                decoration: const InputDecoration(
                  labelText: 'Capacity',
                  hintText: 'Number of beds',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.people),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter capacity';
                  }
                  final capacity = int.tryParse(value);
                  if (capacity == null || capacity <= 0) {
                    return 'Please enter valid capacity';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Rent Amount
              TextFormField(
                controller: _rentController,
                decoration: const InputDecoration(
                  labelText: 'Rent Amount (per semester)',
                  hintText: 'e.g., 5000',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.attach_money),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter rent amount';
                  }
                  final rent = double.tryParse(value);
                  if (rent == null || rent <= 0) {
                    return 'Please enter valid rent amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (Optional)',
                  hintText: 'Room features, amenities, etc.',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              
              // Add Room Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _addRoom,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.indigo,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Add Room',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              
              // Info Card
              Card(
                color: Colors.blue[50],
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue[700]),
                          const SizedBox(width: 8),
                          Text(
                            'Important Note',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This room will be assigned to you and only you can manage its reservations and residents. Other staff members will not have access to this room.',
                        style: TextStyle(color: Colors.blue[700]),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
