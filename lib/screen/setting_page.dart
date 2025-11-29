import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue.shade50,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.lightBlue.shade700,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --------------------
          // Profile Card
          // --------------------
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlue.shade400, Colors.lightBlue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.shade200.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 40,
                  backgroundImage: AssetImage('lib/images/profile.jpg'),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'John Doe',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                      ),
                      const SizedBox(height: 5),
                      const Text(
                        'john.doe@example.com',
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          // Add edit profile functionality
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // --------------------
          // App Settings Section
          // --------------------
          const Text(
            'App Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _buildSwitchTile(
            title: 'Enable Notifications',
            icon: Icons.notifications,
            value: notificationsEnabled,
            onChanged: (value) => setState(() => notificationsEnabled = value),
            activeColor: Colors.lightBlue.shade600,
          ),
          _buildSwitchTile(
            title: 'Dark Mode',
            icon: Icons.dark_mode,
            value: darkModeEnabled,
            onChanged: (value) => setState(() => darkModeEnabled = value),
            activeColor: Colors.indigo.shade700,
          ),

          const SizedBox(height: 20),

          _buildCardTile(
            icon: Icons.lock,
            title: 'Privacy & Security',
            onTap: () {
              // Add Privacy settings functionality
            },
          ),
          _buildCardTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              // Add help functionality
            },
          ),

          const SizedBox(height: 30),

          // --------------------
          // Logout Button
          // --------------------
          ElevatedButton.icon(
            icon: const Icon(color:Colors.white,Icons.logout),
            label: const Text('Logout', style: TextStyle( color: Colors.white, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 206, 11, 11),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
              shadowColor: const Color.fromARGB(255, 219, 2, 2).withOpacity(0.5),
            ),
            onPressed: () {
              // Add logout functionality
            },
          ),
        ],
      ),
    );
  }

  // --------------------
  // Helper Widgets
  // --------------------
  Widget _buildSwitchTile({
    required String title,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color activeColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeColor: activeColor,
        title: Text(title),
        secondary: Icon(icon, color: activeColor),
      ),
    );
  }

  Widget _buildCardTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: Colors.lightBlue.shade700),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward_ios, size: 18),
        onTap: onTap,
      ),
    );
  }
}
