import 'package:flutter/material.dart';
import 'package:pedometer/pedometer.dart';

void main() {
  runApp(MyApp());
}

// --------------------
// Main App
// --------------------
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Health App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: HomePage(),
    );
  }
}

// --------------------
// Home Page
// --------------------
class HomePage extends StatefulWidget {
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
    return Scaffold(
      body: pages[selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: selectedIndex,
        onTap: (index) => setState(() => selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
          BottomNavigationBarItem(icon: Icon(Icons.medical_services), label: 'Consult'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Symptoms'),
        ],
      ),
    );
  }
}

// --------------------
// Home Content with Pedometer
// --------------------
class HomeContent extends StatefulWidget {
  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  late Stream<StepCount> _stepCountStream;
  int steps = 0;

  @override
  void initState() {
    super.initState();
    _initPedometer();
  }

  void _initPedometer() {
    _stepCountStream = Pedometer.stepCountStream;
    _stepCountStream.listen(_onStepCount).onError(_onStepError);
  }

  void _onStepCount(StepCount event) {
    setState(() {
      steps = event.steps;
    });
  }

  void _onStepError(error) {
    print('Step Count Error: $error');
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    return SingleChildScrollView(
      child: Column(
        children: [
          // Header with Gradient
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlue.shade400, Colors.lightBlue.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
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
                      style: TextStyle(color: Colors.white70, fontSize: 18),
                    ),
                    const SizedBox(height: 5),
                    const Text(
                      'John 👋',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _buildStatCard('Steps', steps.toString(), Icons.directions_walk),
                        const SizedBox(width: 15),
                        _buildStatCard('Appointments', '2', Icons.calendar_today),
                      ],
                    ),
                  ],
                ),
                CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('lib/images/profile.jpg'),
                )
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Cards
          SizedBox(
            height: 120,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _buildActionCard(context, Icons.medical_services, 'Consult a Doctor', Colors.purple, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => ConsultPage()));
                }),
                const SizedBox(width: 15),
                _buildActionCard(context, Icons.search, 'Symptoms Checker', Colors.orange, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => SymptomsCheckerPage()));
                }),
                const SizedBox(width: 15),
                _buildActionCard(context, Icons.article, 'Health Tips', Colors.green, () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => HealthTipsPage()));
                }),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Top Doctors
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Top Doctors', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                Text('See all', style: TextStyle(color: Colors.blue)),
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
                _buildDoctorCard(context, 'Dr. Smith', 'Cardiologist', 4.8),
                const SizedBox(width: 15),
                _buildDoctorCard(context, 'Dr. Amy', 'Dermatologist', 4.6),
                const SizedBox(width: 15),
                _buildDoctorCard(context, 'Dr. John', 'Neurologist', 4.7),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Quick Actions Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(context, Icons.chat, 'Chat', Colors.blue, () => Navigator.push(context, MaterialPageRoute(builder: (_) => ChatPage()))),
                _buildQuickAction(context, Icons.local_hospital, 'Emergency', Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (_) => EmergencyPage()))),
                _buildQuickAction(context, Icons.medication, 'Medicine', Colors.green, () => Navigator.push(context, MaterialPageRoute(builder: (_) => MedicinePage()))),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70)),
              Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.7), color]),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 5),
            )
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 40),
            const SizedBox(height: 10),
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(BuildContext context, String name, String specialty, double rating) {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: 140,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            const CircleAvatar(radius: 35, backgroundImage: AssetImage('lib/images/profile.jpg')),
            const SizedBox(height: 10),
            Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(specialty, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 16),
                const SizedBox(width: 3),
                Text(rating.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(radius: 30, backgroundColor: color, child: Icon(icon, color: Colors.white)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --------------------
// Profile Page
// --------------------
class ProfilePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.person, size: 100, color: Colors.grey),
          SizedBox(height: 20),
          Text('Profile Page', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --------------------
// Consult Page
// --------------------
class ConsultPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Consult a Doctor')),
      body: const Center(child: Text('Consult functionality coming soon!')),
    );
  }
}

// --------------------
// Symptoms Checker Page
// --------------------
class SymptomsCheckerPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Symptoms Checker')),
      body: const Center(child: Text('Symptoms Checker functionality coming soon!')),
    );
  }
}

// --------------------
// Health Tips Page
// --------------------
class HealthTipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tips = [
      'Drink Water: Stay hydrated for better health',
      'Morning Walk: Boost your immunity',
      'Healthy Diet: Eat fresh vegetables',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Health Tips')),
      body: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: tips.length,
        itemBuilder: (context, index) {
          return Card(
            margin: const EdgeInsets.only(bottom: 15),
            child: ListTile(
              leading: const Icon(Icons.health_and_safety),
              title: Text(tips[index]),
            ),
          );
        },
      ),
    );
  }
}

// --------------------
// Chat, Emergency, Medicine Pages
// --------------------
class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: const Center(child: Text('Chat functionality coming soon!')),
    );
  }
}

class EmergencyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: const Center(child: Text('Emergency contacts functionality coming soon!')),
    );
  }
}

class MedicinePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Info')),
      body: const Center(child: Text('Medicine info functionality coming soon!')),
    );
  }
}
