import 'package:flutter/material.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/provider/user_provider.dart';
import 'package:mina_app/screen/Counsult_page.dart';
import 'package:mina_app/screen/chat_page.dart';
import 'package:mina_app/screen/exercise_page.dart';
import 'package:mina_app/screen/health_tips_page.dart';
import 'package:mina_app/screen/profile_page.dart';
import 'package:mina_app/screen/symptoms_page.dart';
import 'package:mina_app/screen/video_call_page.dart';
import 'package:mina_app/theme/theme_manager.dart';
import 'package:mina_app/utils/doctor_utils.dart';
import 'package:mina_app/widgets/profile_avatar.dart';
import 'package:provider/provider.dart';

// --------------------
// Home Page
// --------------------
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int selectedIndex = 0;

  final List<Widget> pages = [
    const HomeContent(),
    const ProfilePage(),
    const ConsultPage(),
    const SymptomsCheckerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor: isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
      body: SafeArea(child: pages[selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => setState(() => selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.white,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(
              icon: Icon(Icons.medical_services), label: 'Consult'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search), label: 'Symptoms'),
        ],
      ),
    );
  }
}

// --------------------
// Home Content
// --------------------
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final ApiService _apiService = ApiService();
  int _appointmentCount = 0;
  bool _loadingCount = true;
  List<Map<String, dynamic>> _topDoctors = [];
  bool _loadingDoctors = true;
  String? _doctorError;
  bool _startingCall = false;

  @override
  void initState() {
    super.initState();
    // Load user data first, then fetch doctors and appointments
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await Provider.of<UserProvider>(context, listen: false).loadUserData();
      _loadAppointmentCount();
      _loadTopDoctors();
    });
  }

  // ✅ FIXED: Use getPatientDashboard() – same as ConsultPage
  Future<void> _loadTopDoctors() async {
    setState(() {
      _loadingDoctors = true;
      _doctorError = null;
    });
    try {
      final dashboard = await _apiService.getPatientDashboard();
      final dashboardData = dashboard['data'] is Map ? dashboard['data'] as Map : dashboard;
      var doctorsList = dashboardData['doctors'] as List? ?? [];
      if (doctorsList.isEmpty) {
        doctorsList = await _apiService.getDoctors();
      }
      final mappedDoctors = doctorsList
          .whereType<Map>()
          .map<Map<String, dynamic>>((doc) => _doctorFromApi(doc))
          .toList();
      final enrichedDoctors = await Future.wait(mappedDoctors.map(_withDoctorRating));
      enrichedDoctors.sort((a, b) {
        final ratingCompare = (b['rating'] as double).compareTo(a['rating'] as double);
        if (ratingCompare != 0) return ratingCompare;
        final bCount = b['ratingCount'] is num ? (b['ratingCount'] as num).toInt() : 0;
        final aCount = a['ratingCount'] is num ? (a['ratingCount'] as num).toInt() : 0;
        return bCount.compareTo(aCount);
      });
      setState(() {
        _topDoctors = enrichedDoctors.take(4).toList();
        _loadingDoctors = false;
      });
    } catch (e) {
      print("Error loading doctors: $e");
      setState(() {
        _doctorError = e.toString();
        _loadingDoctors = false;
      });
    }
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

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    ).then((_) {
      Provider.of<UserProvider>(context, listen: false).loadUserData();
    });
  }

  void _openAppointments(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AppointmentsPage()),
    );
    if (result == true) {
      _loadAppointmentCount();
    }
  }

  void _openExercisePage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExercisePage()),
    );
  }

  Future<void> _startDoctorCall(Map<String, dynamic> doctor) async {
    final appointmentId = doctor['nextAppointmentId'] ??
        await _apiService.findAppointmentIdWithParticipant(doctor['id'].toString());
    if (!mounted) return;
    if (appointmentId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Book an appointment before starting a call.')),
      );
      return;
    }

    setState(() => _startingCall = true);
    try {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VideoCallPage(
            appointmentId: appointmentId,
            title: 'Call with ${doctor['name'] ?? 'Doctor'}',
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

  Map<String, dynamic> _doctorFromApi(Map<dynamic, dynamic> doc) {
    final map = Map<String, dynamic>.from(doc);
    final rating = doc['rating'];
    return {
      'id': doc['id'] ?? doc['user_id'] ?? doc['doctor_id'],
      'name': doc['full_name'] ?? doc['name'] ?? 'Dr. Unknown',
      'specialty': parseSpecialty(map),
      'rating': rating is num ? rating.toDouble() : double.tryParse('$rating') ?? 4.5,
      'ratingCount': doc['rating_count'] ?? 0,
      'email': doc['email'] ?? '',
      'phone': doc['phone'] ?? '',
      'experience': doc['years_of_experience'] ?? 0,
      'fee': doc['consultation_fee'] ?? 0,
      'profileImageUrl': doc['profile_image_url'],
      'canChat': doc['can_chat'] ?? true,
      'canCall': doc['can_call'] ?? false,
      'nextAppointmentId': doc['next_appointment_id'],
      'nextAppointmentAt': doc['next_appointment_at'],
    };
  }

  Future<Map<String, dynamic>> _withDoctorRating(Map<String, dynamic> doctor) async {
    final doctorId = doctor['id'];
    if (doctorId == null) return doctor;
    try {
      final ratingData = await _apiService.getDoctorRating(doctorId);
      final rating = ratingData['rating'];
      return {
        ...doctor,
        'rating': rating is num ? rating.toDouble() : double.tryParse('$rating') ?? doctor['rating'],
        'ratingCount': ratingData['rating_count'] ?? doctor['ratingCount'],
      };
    } catch (_) {
      return doctor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDarkMode = themeManager.isDarkMode;
    final greeting = _getGreeting();

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          // HEADER
          Container(
            height: 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDarkMode
                    ? [Colors.grey.shade700, Colors.grey.shade800]
                    : [Colors.blue.shade300, Colors.blue.shade500],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(35),
                bottomRight: Radius.circular(35),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$greeting,',
                      style: const TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    GestureDetector(
                      onTap: () => _openProfile(context),
                      child: Text(
                        '${userProvider.fullName} 👋',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: _openExercisePage,
                          child: _buildStatCard('Exercise', isDarkMode,
                              icon: Icons.fitness_center, showValue: false),
                        ),
                        const SizedBox(width: 15),
                        GestureDetector(
                          onTap: () => _openAppointments(context),
                          child: _buildStatCard('Appointments', isDarkMode,
                              icon: Icons.calendar_month,
                              value: _loadingCount ? '...' : _appointmentCount.toString()),
                        ),
                      ],
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () => _openProfile(context),
                  child: ProfileAvatar(
                    imagePathOrUrl: userProvider.profileImageUrl,
                    radius: 45,
                    iconSize: 45,
                    backgroundColor: Colors.blue.shade300,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ACTION CARDS
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildActionCard(
                  context,
                  Icons.medical_services,
                  'Consult a Doctor',
                  Colors.blue.shade300,
                  Colors.blue.shade500,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ConsultPage()),
                  ).then((_) => _loadAppointmentCount()),
                ),
                const SizedBox(width: 15),
                _buildActionCard(
                  context,
                  Icons.search,
                  'Symptoms Checker',
                  Colors.lightBlue.shade300,
                  Colors.lightBlue.shade500,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SymptomsCheckerPage()),
                  ),
                ),
                const SizedBox(width: 15),
                _buildActionCard(
                  context,
                  Icons.article,
                  'Health Tips',
                  Colors.blue.shade100,
                  Colors.blue.shade300,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HealthTipsPage()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // TOP DOCTORS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Top Doctors',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode ? Colors.white : Colors.black)),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ConsultPage()),
                    );
                  },
                  child: Text('See all',
                      style: TextStyle(
                          color: isDarkMode ? Colors.blue.shade300 : Colors.blue)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 15),
          if (_loadingDoctors)
            const Center(child: CircularProgressIndicator())
          else if (_doctorError != null)
            Center(
              child: Column(
                children: [
                  const Icon(Icons.error_outline, color: Colors.red),
                  const SizedBox(height: 8),
                  Text('Failed to load doctors: $_doctorError'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _loadTopDoctors,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          else if (_topDoctors.isEmpty)
            const Center(child: Text('No doctors available'))
          else
            SizedBox(
              height: 180,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: _topDoctors.map((doctor) {
                  return _buildDoctorCard(doctor, isDarkMode);
                }).toList(),
              ),
            ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, bool isDarkMode,
      {String? value, Widget? child, IconData? icon, bool showValue = true}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(
            icon ?? Icons.directions_walk,
            color: isDarkMode ? Colors.lightBlue.shade300 : Colors.blue.shade700,
            size: 20,
          ),
          if (showValue) ...[
            const SizedBox(width: 8),
            child ??
                Text(value ?? '',
                    style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.blue.shade700,
                        fontWeight: FontWeight.bold)),
          ],
        ],
      ),
    );
  }

  Widget _buildActionCard(
      BuildContext context,
      IconData icon,
      String title,
      Color startColor,
      Color endColor,
      VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [startColor, endColor]),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(Map<String, dynamic> doctor, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        // Show doctor details and options
        _showDoctorOptionsDialog(doctor);
      },
      child: Container(
        width: 160,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey.shade800 : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade100.withOpacity(isDarkMode ? 0.1 : 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                ProfileAvatar(
                  imagePathOrUrl: doctor['profileImageUrl'],
                  radius: 35,
                  backgroundColor: Colors.blue,
                  iconSize: 30,
                ),
                const SizedBox(height: 10),
                Text(
                  doctor['name'] ?? 'Dr. Unknown',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 14,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  doctor['specialty'].toString().trim().isNotEmpty
                      ? doctor['specialty'].toString()
                      : 'General Physician',
                  style: TextStyle(
                    color: isDarkMode ? Colors.blue.shade300 : Colors.blue.shade700,
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 4),
                Text(
                  (doctor['rating'] ?? 4.5).toStringAsFixed(1),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? Colors.white : Colors.black,
                    fontSize: 12,
                  ),
                ),
                Text(
                  ' (${doctor['ratingCount'] ?? 0})',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showDoctorOptionsDialog(Map<String, dynamic> doctor) {
    final isDoctor = Provider.of<UserProvider>(context, listen: false).role.toLowerCase() == 'doctor';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ProfileAvatar(
                  imagePathOrUrl: doctor['profileImageUrl'],
                  radius: 40,
                  backgroundColor: Colors.blue,
                  iconSize: 35,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctor['name'] ?? 'Dr. Unknown',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        doctor['specialty'].toString().trim().isNotEmpty
                            ? doctor['specialty'].toString()
                            : 'General Physician',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            (doctor['rating'] ?? 4.5).toStringAsFixed(1),
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            ' (${doctor['ratingCount'] ?? 0})',
                            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            if (doctor['experience'] != null && doctor['experience'] > 0)
              ListTile(
                leading: const Icon(Icons.work, color: Colors.blue),
                title: const Text('Experience'),
                subtitle: Text('${doctor['experience']} years'),
              ),
            if (doctor['fee'] != null && doctor['fee'] > 0)
              ListTile(
                leading: const Icon(Icons.attach_money, color: Colors.green),
                title: const Text('Consultation Fee'),
                subtitle: Text('\$${doctor['fee']}'),
              ),
            if (doctor['phone'] != null && doctor['phone'].isNotEmpty)
              ListTile(
                leading: const Icon(Icons.phone, color: Colors.orange),
                title: const Text('Phone'),
                subtitle: Text(doctor['phone']),
              ),
            if (doctor['nextAppointmentAt'] != null)
              ListTile(
                leading: const Icon(Icons.event_available, color: Colors.green),
                title: const Text('Next Appointment'),
                subtitle: Text(doctor['nextAppointmentAt']),
              ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 150,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.message),
                    label: const Text('Message'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade300,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: doctor['canChat'] == false ? null : () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatPage(
                            participantId: doctor['id'].toString(),
                            participantName: doctor['name'] ?? 'Dr. Unknown',
                            participantRole: 'doctor',
                            participantAvatar: doctor['name']?[0] ?? '?',
                            appointmentId: doctor['nextAppointmentId'],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (isDoctor)
                  SizedBox(
                    width: 150,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.videocam),
                      label: const Text('Call'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _startingCall
                          ? null
                          : () {
                              Navigator.pop(context);
                              _startDoctorCall(doctor);
                            },
                    ),
                  ),
                SizedBox(
                  width: 150,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Book'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5C5FFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ConsultPage()),
                      ).then((_) => _loadAppointmentCount());
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------
// Appointments Page (unchanged)
// --------------------
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
      final data = await _api.getAppointments();
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel: $e')),
      );
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

  String _formatDateTime(String? isoString) {
    if (isoString == null) return 'Date not set';
    try {
      final dateTime = DateTime.parse(isoString).toLocal();
      return '${dateTime.year}-${dateTime.month}-${dateTime.day} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
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
                        onPressed: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ConsultPage()),
                          ).then((_) => _fetchAppointments());
                        },
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
                    final doctorName = apt['doctor_name'] ?? 'Doctor';
                    final specialty = specialtyOrFallback(Map<String, dynamic>.from(apt));
                    final scheduledAt = apt['scheduled_at'];
                    final status = apt['status'] ?? 'scheduled';
                    final statusColor = status == 'confirmed' ? Colors.green : Colors.orange;
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
                            title: Text(doctorName),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(specialty, style: const TextStyle(fontWeight: FontWeight.w500)),
                                const SizedBox(height: 4),
                                Text(_formatDateTime(scheduledAt), style: const TextStyle(fontSize: 12)),
                                const SizedBox(height: 4),
                                Chip(
                                  label: Text(status),
                                  backgroundColor: statusColor,
                                  labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
                                  padding: EdgeInsets.zero,
                                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
