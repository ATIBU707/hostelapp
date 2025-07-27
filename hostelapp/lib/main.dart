import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:provider/provider.dart';

import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/resident/resident_dashboard_screen.dart';
import 'screens/resident/edit_profile_screen.dart';
import 'screens/resident/announcements_screen.dart';
import 'screens/resident/room_booking_screen.dart';
import 'screens/resident/staff_list_screen.dart';
import 'screens/staff/staff_dashboard_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://oqluvwbcltmasmqtuvbm.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im9xbHV2d2JjbHRtYXNtcXR1dmJtIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTM1MDU5MzUsImV4cCI6MjA2OTA4MTkzNX0.L-V1hromigxU7VHS-Lezav_Vg6ct0S2ts5s0HxopXx4',
  );
  
  runApp(const HostelManagerApp());
}

class HostelManagerApp extends StatelessWidget {
  const HostelManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthProvider(),
      child: MaterialApp(
      title: 'Hostel Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF2196F3),
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black87,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF2196F3)),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        // TODO: Add dashboard routes based on user roles
        // '/admin-dashboard': (context) => const AdminDashboard(),
        // '/manager-dashboard': (context) => const ManagerDashboard(),
        // '/staff-dashboard': (context) => const StaffDashboard(),
        '/resident-dashboard': (context) => const ResidentDashboardScreen(),
        '/edit-profile': (context) => const EditProfileScreen(),
        '/announcements': (context) => const AnnouncementsScreen(),
        '/book-room': (context) => const RoomBookingScreen(),
        '/staff-list': (context) => const StaffListScreen(),
        '/staff-dashboard': (context) => const StaffDashboardScreen(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        );
      },
      ),
    );
  }
}
