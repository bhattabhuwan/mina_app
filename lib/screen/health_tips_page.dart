import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_manager.dart';

class HealthTipsPage extends StatelessWidget {
  const HealthTipsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDarkMode = themeManager.isDarkMode;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Tips'),
        backgroundColor: isDarkMode ? Colors.grey.shade800 : Colors.blue.shade700,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Daily Tip Card
          _buildDailyTipCard(isDarkMode),
          const SizedBox(height: 20),

          // Categories Section
          _buildSectionTitle('Categories', Icons.category),
          const SizedBox(height: 10),
          _buildCategoryGrid(),
          const SizedBox(height: 20),

          // All Tips List
          _buildSectionTitle('All Health Tips', Icons.list),
          const SizedBox(height: 10),
          ..._buildTipsList(),
        ],
      ),
    );
  }

  Widget _buildDailyTipCard(bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDarkMode
              ? [Colors.grey.shade800, Colors.grey.shade900]
              : [Colors.lightBlue.shade300, Colors.lightBlue.shade600],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.wb_sunny, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Text(
                'Daily Health Tip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Drink at least 8 glasses of water daily to stay hydrated and boost metabolism.',
            style: TextStyle(color: Colors.white, fontSize: 16, height: 1.4),
          ),
          const SizedBox(height: 15),
          Align(
            alignment: Alignment.bottomRight,
            child: TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.refresh, color: Colors.white, size: 18),
              label: const Text('New Tip', style: TextStyle(color: Colors.white)),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue.shade700, size: 24),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid() {
    final categories = [
      {'icon': Icons.fitness_center, 'name': 'Exercise', 'color': Colors.orange},
      {'icon': Icons.restaurant, 'name': 'Nutrition', 'color': Colors.green},
      {'icon': Icons.self_improvement, 'name': 'Mental Health', 'color': Colors.purple},
      {'icon': Icons.bedtime, 'name': 'Sleep', 'color': Colors.indigo},
      {'icon': Icons.water_drop, 'name': 'Hydration', 'color': Colors.cyan},
      {'icon': Icons.favorite, 'name': 'Wellness', 'color': Colors.red},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        final icon = cat['icon'] as IconData;   // explicit cast
        final color = cat['color'] as Color;     // explicit cast
        final name = cat['name'] as String;      // explicit cast
        return Card(
          elevation: 3,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: InkWell(
            borderRadius: BorderRadius.circular(15),
            onTap: () {
              _showCategoryTips(context, name);
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 40),
                const SizedBox(height: 8),
                Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Widget> _buildTipsList() {
    final tips = [
      {'title': 'Take Regular Breaks', 'description': 'Sitting for long periods can harm your posture. Stand up and stretch every 30 minutes.', 'category': 'Wellness'},
      {'title': 'Eat More Fiber', 'description': 'Fiber aids digestion and helps maintain a healthy weight. Include fruits, vegetables, and whole grains.', 'category': 'Nutrition'},
      {'title': 'Practice Deep Breathing', 'description': 'Deep breathing reduces stress and improves focus. Try 5 minutes of deep breathing daily.', 'category': 'Mental Health'},
      {'title': 'Get 7-9 Hours of Sleep', 'description': 'Quality sleep boosts immunity, memory, and mood. Maintain a consistent sleep schedule.', 'category': 'Sleep'},
      {'title': 'Stay Hydrated', 'description': 'Dehydration causes fatigue and headaches. Carry a water bottle and sip throughout the day.', 'category': 'Hydration'},
      {'title': 'Morning Stretch Routine', 'description': 'Gentle stretching in the morning improves flexibility and circulation.', 'category': 'Exercise'},
    ];

    return tips.map((tip) {
      final title = tip['title'] as String;
      final description = tip['description'] as String;
      final category = tip['category'] as String;
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        child: ExpansionTile(
          leading: Icon(Icons.lightbulb_outline, color: Colors.amber.shade700),
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          subtitle: Text('Category: $category', style: const TextStyle(fontSize: 12)),
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(description, style: const TextStyle(height: 1.4)),
            ),
          ],
        ),
      );
    }).toList();
  }

  void _showCategoryTips(BuildContext context, String category) {
    final tips = {
      'Exercise': ['Morning Stretch Routine', 'Take Regular Breaks'],
      'Nutrition': ['Eat More Fiber'],
      'Mental Health': ['Practice Deep Breathing'],
      'Sleep': ['Get 7-9 Hours of Sleep'],
      'Hydration': ['Stay Hydrated'],
      'Wellness': ['Take Regular Breaks'],
    };

    final categoryTips = tips[category] ?? ['No tips available'];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$category Tips'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: categoryTips.map((tip) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(tip)),
              ],
            ),
          )).toList(),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}