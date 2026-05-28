import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/provider/user_provider.dart';
import 'package:mina_app/screen/chat_page.dart';
import 'package:mina_app/screen/setting_page.dart';
import 'package:mina_app/screen/exercise_page.dart';
import 'package:mina_app/screen/video_call_page.dart';
import 'package:mina_app/theme/theme_manager.dart';
import 'package:mina_app/utils/doctor_utils.dart';
import 'package:mina_app/widgets/profile_avatar.dart';
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

  Future<void> _pickProfileImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(
        source: source,
        imageQuality: 80,
      );
      if (pickedFile == null) return;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading profile picture...')),
        );
      }

      final updatedUser = await _apiService.uploadProfilePicture(pickedFile.path);
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
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile picture updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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

  void _showProfileImagePickerDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickProfileImage(ImageSource.gallery);
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
                  GestureDetector(
                    onTap: _showProfileImagePickerDialog,
                    child: ProfileAvatar(
                      imagePathOrUrl: userProvider.profileImageUrl,
                      radius: 45,
                      iconSize: 45,
                      backgroundColor: Colors.blue.shade300,
                      showCameraBadge: true,
                    ),
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

// ===================== Health Score Page =====================
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

// ===================== EditProfilePage (fully integrated with backend) =====================
class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _genderController;
  late TextEditingController _addressController;
  late TextEditingController _emergencyContactController;
  late TextEditingController _medicalConditionsController;
  late TextEditingController _allergiesController;
  late TextEditingController _currentMedicationsController;

  String? _profileImagePath;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    try {
      final userData = await _api.getCurrentUser();
      final data = userData['data'] ?? userData;

      _fullNameController = TextEditingController(text: data['full_name'] ?? '');
      _emailController = TextEditingController(text: data['email'] ?? '');
      _phoneController = TextEditingController(text: data['phone'] ?? '');
      _dateOfBirthController = TextEditingController(text: data['date_of_birth']?.split('T')[0] ?? '');
      _genderController = TextEditingController(text: data['gender'] ?? '');
      _addressController = TextEditingController(text: data['address'] ?? '');
      _emergencyContactController = TextEditingController(text: data['emergency_contact'] ?? '');
      _medicalConditionsController = TextEditingController(text: (data['medical_conditions'] as List?)?.join(', ') ?? '');
      _allergiesController = TextEditingController(text: (data['allergies'] as List?)?.join(', ') ?? '');
      _currentMedicationsController = TextEditingController(text: (data['current_medications'] as List?)?.join(', ') ?? '');
      _profileImagePath = data['profile_image_url'];
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      // Convert date of birth to ISO 8601 datetime
      String? formattedDate;
      if (_dateOfBirthController.text.trim().isNotEmpty) {
        try {
          final parsed = DateTime.parse(_dateOfBirthController.text.trim());
          formattedDate = parsed.toIso8601String(); // e.g., "2001-01-04T00:00:00.000"
        } catch (e) {
          // invalid date – will send null (field omitted)
        }
      }

      final Map<String, dynamic> updatedData = {
        'full_name': _fullNameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'date_of_birth': formattedDate,
        'gender': _genderController.text.trim(),
        'address': _addressController.text.trim(),
        'emergency_contact': _emergencyContactController.text.trim(),
        'medical_conditions': _medicalConditionsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'allergies': _allergiesController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
        'current_medications': _currentMedicationsController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList(),
      };
      await _api.updateUserProfile(updatedData);

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      await userProvider.updateUser(
        fullName: updatedData['full_name'],
        email: _emailController.text.trim(),
        profileImagePath: _profileImagePath,
      );
      await userProvider.loadUserData();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully'), backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => _isSaving = false);
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
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  await _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await ImagePicker().pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Uploading profile picture...')),
          );
        }

        final updatedUser = await _api.uploadProfilePicture(pickedFile.path);
        final data = updatedUser['data'] ?? updatedUser;
        final imageUrl = data['profile_image_url'] as String?;
        if (imageUrl == null || imageUrl.isEmpty) {
          throw Exception('Profile image URL missing from server response');
        }

        if (!mounted) return;
        setState(() => _profileImagePath = imageUrl);

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

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeManager>(context).isDarkMode;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Profile')),
        body: Center(child: Text('Error: $_error')),
      );
    }

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
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Profile picture
              GestureDetector(
                onTap: _showImagePickerDialog,
                child: ProfileAvatar(
                  imagePathOrUrl: _profileImagePath,
                  radius: 60,
                  iconSize: 60,
                  backgroundColor: Colors.blue.shade300,
                  showCameraBadge: true,
                ),
              ),
              const SizedBox(height: 30),

              TextFormField(
                controller: _fullNameController,
                decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.email)),
                enabled: false,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(labelText: 'Phone', prefixIcon: Icon(Icons.phone)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _dateOfBirthController,
                decoration: const InputDecoration(labelText: 'Date of Birth (YYYY-MM-DD)', prefixIcon: Icon(Icons.cake)),
                keyboardType: TextInputType.datetime,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _genderController,
                decoration: const InputDecoration(labelText: 'Gender', prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home)),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _emergencyContactController,
                decoration: const InputDecoration(labelText: 'Emergency Contact', prefixIcon: Icon(Icons.emergency)),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _medicalConditionsController,
                decoration: const InputDecoration(labelText: 'Medical Conditions (comma separated)', prefixIcon: Icon(Icons.medical_information)),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _allergiesController,
                decoration: const InputDecoration(labelText: 'Allergies (comma separated)', prefixIcon: Icon(Icons.coronavirus)),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _currentMedicationsController,
                decoration: const InputDecoration(labelText: 'Current Medications (comma separated)', prefixIcon: Icon(Icons.medication)),
              ),
              const SizedBox(height: 30),

              ElevatedButton.icon(
                onPressed: _isSaving ? null : _showImagePickerDialog,
                icon: const Icon(Icons.photo_camera),
                label: const Text('Change Profile Picture'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===================== AppointmentsPage =====================
class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({super.key});

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final ApiService _api = ApiService();
  List<dynamic> _appointments = [];
  bool _loading = true;
  bool _startingCall = false;

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

  Future<void> _startAppointmentCall(Map<String, dynamic> appointment) async {
    setState(() => _startingCall = true);
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallPage(
            appointmentId: appointment['id'],
            title: 'Call with ${appointment['doctor_name'] ?? 'Doctor'}',
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Call failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _startingCall = false);
    }
  }

  void _messageDoctor(Map<String, dynamic> appointment) {
    final doctorId = appointment['doctor_id'];
    if (doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Doctor ID not found for this appointment.')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatPage(
          participantId: doctorId.toString(),
          participantName: appointment['doctor_name'] ?? 'Doctor',
          participantRole: 'doctor',
          appointmentId: appointment['id'],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeManager>(context).isDarkMode;
    final isDoctor = Provider.of<UserProvider>(context).role.toLowerCase() == 'doctor';

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
                    final dateTime = DateTime.tryParse(apt['scheduled_at'] ?? '');
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Column(
                        children: [
                          ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue.shade100,
                              child: const Icon(Icons.medical_services, color: Colors.blue),
                            ),
                            title: Text(apt['doctor_name'] ?? 'Doctor'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(specialtyOrFallback(Map<String, dynamic>.from(apt))),
                                if (dateTime != null)
                                  Text(
                                    '${dateTime.toLocal()}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => _cancelAppointment(apt['id'].toString()),
                            ),
                            isThreeLine: true,
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                            child: Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _messageDoctor(apt),
                                    icon: const Icon(Icons.message, size: 18),
                                    label: const Text('Message'),
                                  ),
                                ),
                                if (isDoctor) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _startingCall ? null : () => _startAppointmentCall(apt),
                                      icon: const Icon(Icons.videocam, size: 18),
                                      label: const Text('Call'),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
