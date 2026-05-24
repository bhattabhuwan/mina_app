import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/provider/user_provider.dart';
import 'package:mina_app/screen/setting_page.dart';
import 'package:mina_app/screen/exercise_page.dart';
import 'package:mina_app/theme/theme_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// --------------------
// Profile Page
// --------------------
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ApiService _apiService = ApiService();
  int _appointmentCount = 0;
  bool _loadingCount = true;
  double healthScore = 87.5;

  @override
  void initState() {
    super.initState();
    _refreshUserData();
    _loadAppointmentCount();
    _loadHealthScore();
  }

  Future<void> _loadHealthScore() async {
    final prefs = await SharedPreferences.getInstance();
    final savedScore = prefs.getDouble('health_score');
    if (savedScore != null) setState(() => healthScore = savedScore);
  }

  Future<void> _saveHealthScore(double score) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('health_score', score);
    setState(() => healthScore = score);
  }

  Future<void> _refreshUserData() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    await userProvider.loadUserData();
    setState(() {});
  }

  Future<void> _loadAppointmentCount() async {
    try {
      final appointments = await _apiService.getUpcomingAppointments();
      setState(() {
        _appointmentCount = appointments.length;
        _loadingCount = false;
      });
    } catch (e) {
      debugPrint("Error loading appointments: $e");
      setState(() => _loadingCount = false);
    }
  }

  void _openAppointments(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppointmentsPage()),
    );
    if (result == true) _loadAppointmentCount();
  }

  void _openExercisePage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExercisePage()));
  }

  void _openHealthScorePage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HealthScorePage(
          onSave: (newScore) => _saveHealthScore(newScore),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDarkMode = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
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
                    color: isDarkMode ? Colors.black26 : Colors.blue.shade200.withOpacity(0.3),
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
                        userProvider.fullName,
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        userProvider.email,
                        style: const TextStyle(color: Colors.white70, fontSize: 16),
                      ),
                    ],
                  ),
                  CircleAvatar(
                    radius: 45,
                    backgroundColor: Colors.blue.shade300,
                    backgroundImage: userProvider.profileImagePath != null &&
                            File(userProvider.profileImagePath!).existsSync()
                        ? FileImage(File(userProvider.profileImagePath!))
                        : null,
                    child: userProvider.profileImagePath == null ||
                            !File(userProvider.profileImagePath!).existsSync()
                        ? const Icon(Icons.person, size: 45, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _openExercisePage,
                    child: _buildStatCard('Exercise', Colors.orange,
                        icon: Icons.fitness_center, isDarkMode: isDarkMode, value: ''),
                  ),
                  GestureDetector(
                    onTap: () => _openAppointments(context),
                    child: _buildStatCard('Appointments', Colors.green,
                        icon: Icons.calendar_month, isDarkMode: isDarkMode,
                        value: _loadingCount ? '...' : _appointmentCount.toString()),
                  ),
                  GestureDetector(
                    onTap: _openHealthScorePage,
                    child: _buildStatCard('Health Score', Colors.redAccent,
                        icon: Icons.favorite, isDarkMode: isDarkMode,
                        value: healthScore.toStringAsFixed(1)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildActionCard(Icons.settings, 'Settings', Colors.lightBlue, isDarkMode, () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
                  }),
                  const SizedBox(height: 15),
                  _buildActionCard(Icons.history, 'Activity History', Colors.purple, isDarkMode, () {}),
                  const SizedBox(height: 15),
                  _buildActionCard(Icons.logout, 'Logout', Colors.redAccent, isDarkMode, () async {
                    final userProvider = Provider.of<UserProvider>(context, listen: false);
                    await userProvider.clearUserData();
                    await ApiService().logout();
                    if (!mounted) return;
                    Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
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
      {required IconData icon, String? value, bool isDarkMode = false}) {
    return Container(
      width: 100,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.grey.withOpacity(isDarkMode ? 0.1 : 0.2), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          CircleAvatar(radius: 20, backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
          const SizedBox(height: 10),
          Text(value ?? '', style: TextStyle(color: isDarkMode ? Colors.white : Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 5),
          Text(title, style: TextStyle(color: isDarkMode ? Colors.grey.shade400 : Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String title, Color color, bool isDarkMode, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(25),
          boxShadow: [BoxShadow(color: color.withOpacity(isDarkMode ? 0.1 : 0.2), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Row(
          children: [
            CircleAvatar(radius: 25, backgroundColor: color.withOpacity(0.2), child: Icon(icon, color: color)),
            const SizedBox(width: 20),
            Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: isDarkMode ? Colors.white : Colors.black)),
          ],
        ),
      ),
    );
  }
}

// ===================== Health Score Page (Full Screen – No Dialog Layout Issues) =====================
class HealthScorePage extends StatefulWidget {
  final Function(double) onSave;
  const HealthScorePage({super.key, required this.onSave});

  @override
  State<HealthScorePage> createState() => _HealthScorePageState();
}

class _HealthScorePageState extends State<HealthScorePage> {
  int _sleepQuality = 70;
  int _exerciseFrequency = 60;
  int _stressLevel = 50;
  int _dietQuality = 70;
  int _hydration = 80;

  double get totalScore {
    final sum = (_sleepQuality + _exerciseFrequency + _stressLevel + _dietQuality + _hydration) / 5;
    return sum.clamp(0.0, 100.0);
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeManager>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Score Assessment'),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.lightBlue.shade700,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: () {
              widget.onSave(totalScore);
              Navigator.pop(context);
            },
            child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildQuestionSlider('Sleep Quality', 'How well did you sleep?', _sleepQuality, (v) => setState(() => _sleepQuality = v), isDarkMode),
            const SizedBox(height: 20),
            _buildQuestionSlider('Exercise Frequency', 'How often did you exercise this week?', _exerciseFrequency, (v) => setState(() => _exerciseFrequency = v), isDarkMode),
            const SizedBox(height: 20),
            _buildQuestionSlider('Stress Level', 'How stressed did you feel? (higher = less stress)', _stressLevel, (v) => setState(() => _stressLevel = v), isDarkMode),
            const SizedBox(height: 20),
            _buildQuestionSlider('Diet Quality', 'How healthy was your diet?', _dietQuality, (v) => setState(() => _dietQuality = v), isDarkMode),
            const SizedBox(height: 20),
            _buildQuestionSlider('Hydration', 'How well hydrated were you?', _hydration, (v) => setState(() => _hydration = v), isDarkMode),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Your Health Score:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  Text(
                    totalScore.toStringAsFixed(1),
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: _getScoreColor(totalScore)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionSlider(String title, String subtitle, int value, Function(int) onChanged, bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white70 : Colors.black54)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Text('0'),
            Expanded(
              child: Slider(
                value: value.toDouble(),
                min: 0,
                max: 100,
                divisions: 20,
                label: value.toString(),
                onChanged: (v) => onChanged(v.toInt()),
                activeColor: _getScoreColor(value.toDouble()),
              ),
            ),
            const Text('100'),
          ],
        ),
        Align(
          alignment: Alignment.centerRight,
          child: Text('${value.toStringAsFixed(0)}/100', style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.lightGreen;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }
}

// ===================== EditProfilePage (unchanged) =====================
class EditProfilePage extends StatefulWidget {
  final String currentName;
  final String currentEmail;
  final String? currentImagePath;
  const EditProfilePage({super.key, required this.currentName, required this.currentEmail, this.currentImagePath});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.currentName);
    emailController = TextEditingController(text: widget.currentEmail);
    _imagePath = widget.currentImagePath;
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        if (!await directory.exists()) await directory.create();
        final fileName = path.basename(pickedFile.path);
        final savedImage = await File(pickedFile.path).copy('${directory.path}/$fileName');
        setState(() => _imagePath = savedImage.path);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to pick image')));
    }
  }

  void _showImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(leading: const Icon(Icons.camera_alt), title: const Text('Take a photo'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); }),
              ListTile(leading: const Icon(Icons.photo_library), title: const Text('Choose from gallery'), onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); }),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProfile() async {
    if (nameController.text.trim().isEmpty || emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name and email cannot be empty')));
      return;
    }
    setState(() => _isSaving = true);
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateUser(
        fullName: nameController.text.trim(),
        email: emailController.text.trim(),
        profileImagePath: _imagePath,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully')));
        Navigator.pop(context, true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save profile')));
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeManager>(context).isDarkMode;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.lightBlue.shade700,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: Text('Save', style: TextStyle(color: _isSaving ? Colors.grey : Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: _showImagePickerDialog,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.blue.shade300,
                    backgroundImage: _imagePath != null && File(_imagePath!).existsSync() ? FileImage(File(_imagePath!)) : null,
                    child: _imagePath == null || !File(_imagePath!).existsSync() ? const Icon(Icons.person, size: 60, color: Colors.white) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                    child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TextField(controller: nameController, decoration: InputDecoration(labelText: 'Full Name', prefixIcon: const Icon(Icons.person), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 20),
            TextField(controller: emailController, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: 'Email', prefixIcon: const Icon(Icons.email), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
            const SizedBox(height: 30),
            ElevatedButton.icon(
              onPressed: _isSaving ? null : _showImagePickerDialog,
              icon: const Icon(Icons.photo_camera),
              label: const Text('Change Profile Picture'),
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            ),
          ],
        ),
      ),
    );
  }
}

// ===================== AppointmentsPage (unchanged) =====================
class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final ApiService _api = ApiService();
  List<dynamic> _appointments = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchAppointments();
  }

  Future<void> _fetchAppointments() async {
    try {
      final data = await _api.getUpcomingAppointments();
      setState(() {
        _appointments = data;
        _loading = false;
      });
    } catch (e) {
      debugPrint("Error fetching appointments: $e");
      setState(() => _loading = false);
    }
  }

  Future<void> _cancelAppointment(String id) async {
    try {
      await _api.cancelAppointment(id);
      _fetchAppointments();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Appointment cancelled')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to cancel: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeManager>(context).isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Appointments'),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.lightBlue.shade700,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _appointments.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No upcoming appointments'),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Book a doctor'),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _appointments.length,
                  itemBuilder: (context, index) {
                    final apt = _appointments[index];
                    final dateTime = DateTime.tryParse(apt['date_time'] ?? '');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.blue.shade100,
                          child: const Icon(Icons.medical_services, color: Colors.blue),
                        ),
                        title: Text(apt['doctor_name'] ?? 'Doctor'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(apt['specialty'] ?? 'General'),
                            if (dateTime != null)
                              Text('${dateTime.toLocal()}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          onPressed: () => _cancelAppointment(apt['id']),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
    );
  }
}