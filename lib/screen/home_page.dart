import 'dart:io';
import 'package:flutter/material.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/provider/user_provider.dart';
import 'package:mina_app/screen/Counsult_page.dart';
import 'package:mina_app/screen/exercise_page.dart';
import 'package:mina_app/screen/health_tips_page.dart';
import 'package:mina_app/screen/profile_page.dart';
import 'package:mina_app/screen/symptoms_page.dart';
import 'package:mina_app/theme/theme_manager.dart';
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

  @override
  void initState() {
    super.initState();
    _loadAppointmentCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadUserData();
    });
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
      MaterialPageRoute(builder: (_) => const ExercisePage()), // no parameter needed
    );
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
                        // Exercise card – only icon
                        GestureDetector(
                          onTap: _openExercisePage,
                          child: _buildStatCard('Exercise', isDarkMode,
                              icon: Icons.fitness_center,
                              showValue: false),
                        ),
                        const SizedBox(width: 15),
                        // Appointments card – shows count
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
                  child: CircleAvatar(
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

          // DOCTORS
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
                Text('See all',
                    style: TextStyle(
                        color: isDarkMode ? Colors.blue.shade300 : Colors.blue)),
              ],
            ),
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildDoctorCard('Dr. Smith', 'Cardiologist', 4.8, isDarkMode),
                const SizedBox(width: 15),
                _buildDoctorCard('Dr. Amy', 'Dermatologist', 4.6, isDarkMode),
                const SizedBox(width: 15),
                _buildDoctorCard('Dr. John', 'Neurologist', 4.7, isDarkMode),
              ],
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

  Widget _buildDoctorCard(
      String name, String specialty, double rating, bool isDarkMode) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.shade100.withOpacity(isDarkMode ? 0.1 : 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundColor: Colors.blue,
            child: Icon(
              Icons.medical_services,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(height: 10),
          Text(name,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black)),
          Text(specialty,
              style: TextStyle(
                  color: isDarkMode
                      ? Colors.blue.shade300
                      : Colors.blue.shade700)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              Text(rating.toString(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode ? Colors.white : Colors.black)),
            ],
          )
        ],
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Appointment cancelled')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to cancel: $e')),
      );
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
                              Text(
                                '${dateTime.toLocal()}',
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              ),
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