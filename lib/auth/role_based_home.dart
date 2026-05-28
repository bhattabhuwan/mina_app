import 'package:flutter/material.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/auth/auth_service.dart';
import 'package:mina_app/doctor/doctor_home.dart';
import 'package:mina_app/provider/user_provider.dart';
import 'package:mina_app/screen/home_page.dart';
import 'package:provider/provider.dart';

class RoleBasedHome extends StatefulWidget {
  const RoleBasedHome({super.key});

  @override
  State<RoleBasedHome> createState() => _RoleBasedHomeState();
}

class _RoleBasedHomeState extends State<RoleBasedHome> {
  bool _isLoading = true;
  String? _role;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchUserRole();
  }

  Future<void> _fetchUserRole() async {
    try {
      final api = ApiService();
      final userData = await api.getCurrentUser();
      // Extract role from possible nested structure
      String? role = userData['role'] as String?;
      if (role == null && userData['data'] != null) {
        role = userData['data']['role'] as String?;
      }
      role = role?.toLowerCase() ?? 'patient';

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateUser(
        fullName: userData['full_name'] ?? userData['data']?['full_name'] ?? '',
        email: userData['email'] ?? userData['data']?['email'] ?? '',
        profileImagePath:
            userData['profile_image_url'] ?? userData['data']?['profile_image_url'],
        role: role,
        userId: userData['id'] ?? userData['data']?['id'],
      );

      setState(() {
        _role = role;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $_error'),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // Direct navigation – no named routes needed
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AuthPage()),
                  );
                },
                child: const Text('Go to Login'),
              ),
            ],
          ),
        ),
      );
    }

    if (_role == 'doctor') {
      return const DoctorHome();
    } else {
      return const HomePage(); // patient home
    }
  }
}
