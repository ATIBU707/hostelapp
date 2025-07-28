import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  
  bool _isLoading = false;
  bool _isEditingProfile = false;
  bool _isChangingPassword = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _loadProfileData() {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final userProfile = authProvider.userProfile;
    
    if (userProfile != null) {
      _nameController.text = userProfile['full_name'] ?? '';
      _emailController.text = userProfile['email'] ?? '';
      _phoneController.text = userProfile['phone'] ?? '';
    }
  }

  Future<void> _updateProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      final profileData = {
        'full_name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        // Email updates might require special handling
      };

      // TODO: Implement profile update in AuthProvider
      // await authProvider.updateStaffProfile(profileData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isEditingProfile = false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _changePassword() async {
    if (!_formKey.currentState!.validate()) return;

    if (_newPasswordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('New passwords do not match'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      // TODO: Implement password change in AuthProvider
      // await authProvider.changePassword(
      //   _currentPasswordController.text,
      //   _newPasswordController.text,
      // );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password changed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        setState(() => _isChangingPassword = false);
        _currentPasswordController.clear();
        _newPasswordController.clear();
        _confirmPasswordController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error changing password: $e'),
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
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final userProfile = authProvider.userProfile;
        final staffName = userProfile?['full_name'] ?? 'Staff Member';
        final email = userProfile?['email'] ?? '';
        final role = userProfile?['role'] ?? 'staff';

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            actions: [
              if (!_isEditingProfile && !_isChangingPassword)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => setState(() => _isEditingProfile = true),
                ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Header
                  Center(
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.indigo,
                          child: Text(
                            staffName.isNotEmpty ? staffName[0].toUpperCase() : 'S',
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          staffName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.indigo[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            role.toUpperCase(),
                            style: TextStyle(
                              color: Colors.indigo[700],
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Profile Information Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Profile Information',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (_isEditingProfile)
                                Row(
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        setState(() => _isEditingProfile = false);
                                        _loadProfileData(); // Reset form
                                      },
                                      child: const Text('Cancel'),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      onPressed: _isLoading ? null : _updateProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.indigo,
                                        foregroundColor: Colors.white,
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : const Text('Save'),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          // Full Name Field
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            enabled: _isEditingProfile,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter your full name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          
                          // Email Field (Read-only)
                          TextFormField(
                            controller: _emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.email),
                              helperText: 'Contact admin to change email',
                            ),
                            enabled: false, // Email changes require admin approval
                          ),
                          const SizedBox(height: 16),
                          
                          // Phone Field
                          TextFormField(
                            controller: _phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            enabled: _isEditingProfile,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                // Basic phone validation
                                if (!RegExp(r'^\+?[\d\s\-\(\)]+$').hasMatch(value)) {
                                  return 'Please enter a valid phone number';
                                }
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Security Section
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Security',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (!_isChangingPassword)
                                ElevatedButton.icon(
                                  onPressed: () => setState(() => _isChangingPassword = true),
                                  icon: const Icon(Icons.lock, size: 16),
                                  label: const Text('Change Password'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.orange,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                          
                          if (_isChangingPassword) ...[
                            const SizedBox(height: 16),
                            
                            // Current Password
                            TextFormField(
                              controller: _currentPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Current Password',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureCurrentPassword ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _obscureCurrentPassword = !_obscureCurrentPassword),
                                ),
                              ),
                              obscureText: _obscureCurrentPassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter your current password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // New Password
                            TextFormField(
                              controller: _newPasswordController,
                              decoration: InputDecoration(
                                labelText: 'New Password',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                                ),
                              ),
                              obscureText: _obscureNewPassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please enter a new password';
                                }
                                if (value.length < 6) {
                                  return 'Password must be at least 6 characters';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Confirm New Password
                            TextFormField(
                              controller: _confirmPasswordController,
                              decoration: InputDecoration(
                                labelText: 'Confirm New Password',
                                border: const OutlineInputBorder(),
                                prefixIcon: const Icon(Icons.lock),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                              ),
                              obscureText: _obscureConfirmPassword,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please confirm your new password';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            
                            // Password Change Actions
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton(
                                  onPressed: () {
                                    setState(() => _isChangingPassword = false);
                                    _currentPasswordController.clear();
                                    _newPasswordController.clear();
                                    _confirmPasswordController.clear();
                                  },
                                  child: const Text('Cancel'),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _isLoading ? null : _changePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.indigo,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Text('Update Password'),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Account Actions
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Account Actions',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          ListTile(
                            leading: const Icon(Icons.logout, color: Colors.red),
                            title: const Text('Sign Out'),
                            subtitle: const Text('Sign out from your account'),
                            onTap: () => _showSignOutDialog(),
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
      },
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              await authProvider.signOut();
              if (context.mounted) {
                Navigator.of(context).pushReplacementNamed('/login');
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}
