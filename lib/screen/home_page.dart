import 'package:flutter/material.dart';
import 'package:mina_app/auth/ApiService.dart';
import 'package:mina_app/helper/step_counter.dart';
import 'package:mina_app/screen/Counsult_page.dart';
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
    HomeContent(),
    ProfilePage(),
    ConsultPage(),
    SymptomsCheckerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.isDarkMode;

    return Scaffold(
      backgroundColor:
          isDarkMode ? Colors.grey.shade900 : Colors.grey.shade100,
      body: SafeArea(child: pages[selectedIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => setState(() => selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor:
            isDarkMode ? Colors.grey.shade800 : Colors.white,
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
// Home Content (FIXED CURRENT USER)
// --------------------
class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  final ApiService apiService = ApiService();

  String userName = 'User';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    try {
      final response = await apiService.getCurrentUser();

      setState(() {
        userName = response['full_name'] ?? 'User';
        isLoading = false;
      });
    } catch (e) {
      debugPrint("Fetch user error: $e");
      setState(() {
        userName = 'User';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.isDarkMode;

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          // HEADER
          Container(
            height: 220,
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
            padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Good Morning,',
                      style:
                          TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            '$userName 👋',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _buildStatCard('Steps', isDarkMode,
                            child: StepCounter()),
                        const SizedBox(width: 15),
                        _buildStatCard('Appointments', isDarkMode,
                            value: '2'),
                      ],
                    ),
                  ],
                ),
                const CircleAvatar(
                  radius: 30,
                  backgroundImage:
                      AssetImage('lib/images/profile.jpeg'),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildActionCard(
                  context,
                  Icons.medical_services,
                  'Consult a Doctor',
                  Colors.blue.shade300,
                  Colors.blue.shade500,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => ConsultPage()),
                  ),
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
                    MaterialPageRoute(
                        builder: (_) =>
                            SymptomsCheckerPage()),
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
                    MaterialPageRoute(
                        builder: (_) => HealthTipsPage()),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // DOCTORS
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
              children: [
                Text('Top Doctors',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDarkMode
                            ? Colors.white
                            : Colors.black)),
                Text('See all',
                    style: TextStyle(
                        color: isDarkMode
                            ? Colors.blue.shade300
                            : Colors.blue)),
              ],
            ),
          ),

          const SizedBox(height: 15),

          SizedBox(
            height: 180,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildDoctorCard(
                    'Dr. Smith', 'Cardiologist', 4.8,
                    isDarkMode),
                const SizedBox(width: 15),
                _buildDoctorCard(
                    'Dr. Amy', 'Dermatologist', 4.6,
                    isDarkMode),
                const SizedBox(width: 15),
                _buildDoctorCard(
                    'Dr. John', 'Neurologist', 4.7,
                    isDarkMode),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, bool isDarkMode,
      {String? value, Widget? child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isDarkMode ? 0.1 : 0.9),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(Icons.directions_walk,
              color: isDarkMode ? Colors.lightBlue.shade300 : Colors.blue.shade700,
              size: 20),
          const SizedBox(width: 8),
          child ??
              Text(value ?? '',
                  style: TextStyle(
                      color: isDarkMode ? Colors.white : Colors.blue.shade700,
                      fontWeight: FontWeight.bold)),
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
        padding: const EdgeInsets.symmetric(
            vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          gradient:
              LinearGradient(colors: [startColor, endColor]),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 8),
            Text(title,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(String name, String specialty,
      double rating, bool isDarkMode) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey.shade800 : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.blue.shade100.withOpacity(
                  isDarkMode ? 0.1 : 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
            radius: 35,
            backgroundImage:
                AssetImage('lib/images/profile.jpeg'),
          ),
          const SizedBox(height: 10),
          Text(name,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color:
                      isDarkMode ? Colors.white : Colors.black)),
          Text(specialty,
              style: TextStyle(
                  color: isDarkMode
                      ? Colors.blue.shade300
                      : Colors.blue.shade700)),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star,
                  color: Colors.amber, size: 16),
              Text(rating.toString(),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? Colors.white
                          : Colors.black)),
            ],
          )
        ],
      ),
    );
  }
}

// --------------------
// EXTRA PAGES (UNCHANGED)
// --------------------
class HealthTipsPage extends StatelessWidget {
  const HealthTipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text('Health Tips'),
          backgroundColor: Colors.blue.shade500),
      body: const Center(child: Text('Health tips coming soon')),
    );
  }
}
