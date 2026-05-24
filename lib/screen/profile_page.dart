// lib/screen/profile_page.dart
import 'package:flutter/material.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/helper/step_counter.dart';
import 'package:mina_app/screen/setting_page.dart';
import 'package:mina_app/theme/theme_manager.dart';
import 'package:provider/provider.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService apiService = ApiService();

  String fullName = 'User';
  String email = 'user@example.com';
  int steps = 0;
  int appointments = 2;
  double healthScore = 87.5;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    try {
      final user = await apiService.getCurrentUser();
      setState(() {
        fullName = user['full_name'] ?? 'User';
        email = user['email'] ?? 'user@example.com';
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching user: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Gradient Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [Colors.grey.shade700, Colors.grey.shade800]
                            : [Colors.lightBlue.shade400, Colors.lightBlue.shade700],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(35),
                        bottomRight: Radius.circular(35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDarkMode
                              ? Colors.black26
                              : Colors.blue.shade200.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              email,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 15),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.edit, size: 18),
                              label: const Text('Edit Profile'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: isDarkMode
                                    ? Colors.grey.shade800
                                    : Colors.lightBlue.shade700,
                                elevation: 3,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20)),
                              ),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 45,
                          backgroundImage:
                              const AssetImage('lib/images/profile.jpeg'),
                          backgroundColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Health Stats Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStatCard('Steps', Colors.orange,
                            isDarkMode: isDarkMode,
                            child: StepCounter(
                          onStepChanged: (value) {
                            setState(() {
                              steps = value;
                            });
                          },
                        )),
                        _buildStatCard('Appointments', Colors.green,
                            isDarkMode: isDarkMode,
                            value: appointments.toString()),
                        _buildStatCard('Health Score', Colors.redAccent,
                            isDarkMode: isDarkMode,
                            value: healthScore.toStringAsFixed(1)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // Action Cards
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        _buildActionCard(Icons.settings, 'Settings',
                            Colors.lightBlue, isDarkMode, () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const SettingsPage()),
                          );
                        }),
                        const SizedBox(height: 15),
                        _buildActionCard(Icons.history, 'Activity History',
                            Colors.purple, isDarkMode, () {}),
                        const SizedBox(height: 15),
                        _buildActionCard(Icons.logout, 'Logout', Colors.redAccent,
                            isDarkMode, () async {
                          await apiService.logout();
                          if (!mounted) return;
                          Navigator.of(context)
                              .pushNamedAndRemoveUntil('/', (route) => false);
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(String title, Color color,
      {String? value, Widget? child, bool isDarkMode = false}) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(isDarkMode ? 0.1 : 0.2),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: color.withOpacity(0.2),
            child: Icon(
              Icons.directions_walk,
              color: color,
            ),
          ),
          const SizedBox(height: 10),
          child ??
              Text(value ?? '',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16)),
          const SizedBox(height: 5),
          Text(title,
              style: TextStyle(
                  color: isDarkMode ? Colors.grey.shade400 : Colors.grey,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, Color color,
      bool isDarkMode, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(isDarkMode ? 0.1 : 0.2),
                blurRadius: 12,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
                radius: 25,
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color)),
            const SizedBox(width: 20),
            Text(title,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }
}
