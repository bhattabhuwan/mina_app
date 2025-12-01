import 'package:flutter/material.dart';
import 'package:mina_app/helper/step_counter.dart';
import 'package:mina_app/screen/Counsult_page.dart';
import 'package:mina_app/screen/profile_page.dart';
import 'package:mina_app/screen/symptoms_page.dart';


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
      body: SafeArea(child: pages[selectedIndex]),
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
// Home Content
// --------------------
class HomeContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          // HEADER
          Container(
            height: 220,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.lightBlue.shade400, Colors.lightBlue.shade700],
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
                    const Text('Good Morning,',
                        style: TextStyle(color: Colors.white70, fontSize: 18)),
                    const SizedBox(height: 5),
                    const Text('John 👋',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        _buildStatCard('Steps', child: StepCounter()),
                        const SizedBox(width: 15),
                        _buildStatCard('Appointments', value: '2'),
                      ],
                    ),
                  ],
                ),
                const CircleAvatar(
                  radius: 30,
                  backgroundImage: AssetImage('lib/images/profile.jpeg'),
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
                    Colors.purple,
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ConsultPage()))),
                const SizedBox(width: 15),
                _buildActionCard(
                    context,
                    Icons.search,
                    'Symptoms Checker',
                    Colors.orange,
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => SymptomsCheckerPage()))),
                const SizedBox(width: 15),
                _buildActionCard(
                    context,
                    Icons.article,
                    'Health Tips',
                    Colors.green,
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => HealthTipsPage()))),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // DOCTOR LIST
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: const [
                Text('Top Doctors',
                    style:
                        TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
                _buildDoctorCard('Dr. Smith', 'Cardiologist', 4.8),
                const SizedBox(width: 15),
                _buildDoctorCard('Dr. Amy', 'Dermatologist', 4.6),
                const SizedBox(width: 15),
                _buildDoctorCard('Dr. John', 'Neurologist', 4.7),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // QUICK ACTIONS
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildQuickAction(context, Icons.chat, 'Chat', Colors.blue,
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => ChatPage()))),
                _buildQuickAction(
                    context,
                    Icons.local_hospital,
                    'Emergency',
                    Colors.red,
                    () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => EmergencyPage()))),
                _buildQuickAction(context, Icons.medication, 'Medicine',
                    Colors.green, () {
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => MedicinePage()));
                }),
              ],
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, {String? value, Widget? child}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.3),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          const Icon(Icons.directions_walk, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          child ?? Text(value ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildActionCard(BuildContext context, IconData icon, String title,
      Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color.withOpacity(0.6), color]),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard(String name, String specialty, double rating) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        children: [
          const CircleAvatar(
              radius: 35, backgroundImage: AssetImage('lib/images/profile.jpeg')),
          const SizedBox(height: 10),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(specialty, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 16),
              const SizedBox(width: 3),
              Text(rating.toString(),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(
      BuildContext context, IconData icon, String label, Color color, onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
              radius: 30,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white)),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}

// --------------------
// OTHER PAGES
// --------------------
class HealthTipsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final tips = [
      'Drink Water: Stay hydrated',
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

class ChatPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chat')),
      body: const Center(child: Text('Chat coming soon!')),
    );
  }
}

class EmergencyPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Emergency Contacts')),
      body: const Center(child: Text('Emergency contacts coming soon!')),
    );
  }
}

class MedicinePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Medicine Info')),
      body: const Center(child: Text('Medicine info coming soon!')),
    );
  }
}
