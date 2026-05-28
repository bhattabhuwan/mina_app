import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/provider/user_provider.dart';
import 'package:mina_app/screen/privacy_security_page.dart';
import 'package:mina_app/screen/help_support_page.dart';
import 'package:mina_app/screen/profile_page.dart'; // EditProfilePage is inside profile_page.dart
import 'package:mina_app/theme/theme_manager.dart';
import 'package:mina_app/widgets/profile_avatar.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool notificationsEnabled = true;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadNotificationSetting();
  }

  Future<void> _loadNotificationSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _saveNotificationSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', value);
    setState(() {
      notificationsEnabled = value;
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile != null) {
        // Show loading indicator
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading profile picture...')),
          );
        }

        final apiService = ApiService();
        final updatedUser = await apiService.uploadProfilePicture(pickedFile.path);
        final data = updatedUser['data'] ?? updatedUser;
        final imageUrl = data['profile_image_url'] as String?;
        if (imageUrl == null || imageUrl.isEmpty) {
          throw Exception('Profile image URL missing from server response');
        }

        if (!mounted) return;
        final userProvider = Provider.of<UserProvider>(context, listen: false);
        await userProvider.updateUser(
          fullName: data['full_name'] ?? userProvider.fullName,
          email: data['email'] ?? userProvider.email,
          profileImagePath: imageUrl,
          role: data['role'] ?? userProvider.role,
          userId: data['id'] ?? userProvider.userId,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile picture updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload profile picture: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 2,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: themeManager.isDarkMode
                    ? [Colors.grey.shade900, Colors.grey.shade800]
                    : [Colors.lightBlue.shade400, Colors.lightBlue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: themeManager.isDarkMode
                      ? Colors.black26
                      : Colors.blue.shade200.withOpacity(0.5),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _showImagePickerDialog,
                  child: ProfileAvatar(
                    imagePathOrUrl: userProvider.profileImageUrl,
                    radius: 40,
                    iconSize: 40,
                    backgroundColor: Colors.blue.shade300,
                    showCameraBadge: true,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        userProvider.fullName,
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        userProvider.email,
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: () async {
                          // ✅ Updated to use the new EditProfilePage (no parameters)
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const EditProfilePage(),
                            ),
                          );
                          // Reload user data after returning
                          await userProvider.loadUserData();
                          setState(() {}); // refresh UI
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 14),
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

          const Text(
            'App Settings',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _buildSwitchTile(
            title: 'Enable Notifications',
            icon: Icons.notifications,
            value: notificationsEnabled,
            onChanged: _saveNotificationSetting,
            activeColor: Colors.lightBlue.shade600,
          ),
          _buildSwitchTile(
            title: 'Dark Mode',
            icon: Icons.dark_mode,
            value: themeManager.isDarkMode,
            onChanged: (value) => themeManager.toggleTheme(value),
            activeColor: Colors.indigo.shade700,
          ),

          const SizedBox(height: 20),

          const Text(
            'Support',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _buildCardTile(
            icon: Icons.lock,
            title: 'Privacy & Security',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrivacySecurityPage()),
              );
            },
          ),
          _buildCardTile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpSupportPage()),
              );
            },
          ),

          const SizedBox(height: 20),

          const Text(
            'About',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          _buildInfoTile(
            icon: Icons.info_outline,
            title: 'Version',
            subtitle: '1.0.0',
          ),
          _buildInfoTile(
            icon: Icons.copyright,
            title: 'License',
            subtitle: '© 2026 Mina Health App',
          ),

          const SizedBox(height: 30),

          ElevatedButton.icon(
            icon: const Icon(Icons.logout, color: Colors.white),
            label: const Text('Logout', style: TextStyle(color: Colors.white, fontSize: 16)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color.fromARGB(255, 206, 11, 11),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 4,
              shadowColor: const Color.fromARGB(255, 219, 2, 2).withOpacity(0.5),
            ),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Logout'),
                  content: const Text('Are you sure you want to logout?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Logout', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );
              if (confirm == true) {
                final apiService = ApiService();
                await apiService.logout();
                final userProvider = Provider.of<UserProvider>(context, listen: false);
                await userProvider.clearUserData();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                }
              }
            },
          ),
        ],
      ),
    );
  }

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
        activeThumbColor: activeColor,
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

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      child: ListTile(
        leading: Icon(icon, color: Colors.lightBlue.shade700),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
