import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_manager.dart';
 
// ─────────────────────────────────────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────────────────────────────────────
 
class HealthTip {
  final String title;
  final String description;
  final String category;
  final IconData icon;
 
  const HealthTip({
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
  });
}
 
const List<HealthTip> kAllTips = [
  // ── Exercise ─────────────────────────────────────────────────────────────
  HealthTip(
    title: 'Morning Stretch Routine',
    description:
        'Spend 5–10 minutes stretching after waking up. It improves flexibility, boosts circulation, and sets a positive tone for the day.',
    category: 'Exercise',
    icon: Icons.self_improvement,
  ),
  HealthTip(
    title: 'Walk 10,000 Steps Daily',
    description:
        'Aim for 10,000 steps a day to improve cardiovascular health, burn calories, and lift your mood naturally.',
    category: 'Exercise',
    icon: Icons.directions_walk,
  ),
  HealthTip(
    title: 'Strength Train Twice a Week',
    description:
        'Resistance training preserves muscle mass, strengthens bones, and boosts your resting metabolism significantly.',
    category: 'Exercise',
    icon: Icons.fitness_center,
  ),
  HealthTip(
    title: 'Take Active Breaks',
    description:
        'Stand up and move for 2 minutes every 30 minutes of sitting. It counteracts the negative effects of a sedentary lifestyle.',
    category: 'Exercise',
    icon: Icons.accessibility_new,
  ),
  HealthTip(
    title: 'Try HIIT Workouts',
    description:
        'High-Intensity Interval Training burns more fat in less time and keeps your metabolism elevated for hours after exercise.',
    category: 'Exercise',
    icon: Icons.bolt,
  ),
  HealthTip(
    title: 'Prioritize Warm-Up & Cool-Down',
    description:
        'Always warm up before and cool down after exercise to prevent injuries and reduce muscle soreness.',
    category: 'Exercise',
    icon: Icons.local_fire_department,
  ),
  HealthTip(
    title: 'Try Yoga or Pilates',
    description:
        'These mind-body practices improve posture, core strength, and mental clarity — all at once.',
    category: 'Exercise',
    icon: Icons.spa,
  ),
 
  // ── Nutrition ─────────────────────────────────────────────────────────────
  HealthTip(
    title: 'Eat a Rainbow of Vegetables',
    description:
        'Different colored vegetables provide distinct phytonutrients. Aim for 5 different colors on your plate every day.',
    category: 'Nutrition',
    icon: Icons.eco,
  ),
  HealthTip(
    title: 'Reduce Added Sugar',
    description:
        'Excess sugar contributes to weight gain, inflammation, and energy crashes. Swap sugary snacks for fruit or nuts.',
    category: 'Nutrition',
    icon: Icons.no_food,
  ),
  HealthTip(
    title: 'Eat More Fiber',
    description:
        'Fiber aids digestion and helps maintain a healthy weight. Include fruits, vegetables, and whole grains daily.',
    category: 'Nutrition',
    icon: Icons.grass,
  ),
  HealthTip(
    title: 'Choose Healthy Fats',
    description:
        'Avocados, nuts, olive oil, and fatty fish provide healthy fats that support brain function and heart health.',
    category: 'Nutrition',
    icon: Icons.restaurant,
  ),
  HealthTip(
    title: 'Eat Mindfully',
    description:
        'Slow down, chew thoroughly, and savor your meals. Mindful eating prevents overeating and improves digestion.',
    category: 'Nutrition',
    icon: Icons.food_bank,
  ),
  HealthTip(
    title: 'Don\'t Skip Breakfast',
    description:
        'A nutritious breakfast kick-starts your metabolism, stabilizes blood sugar, and improves concentration.',
    category: 'Nutrition',
    icon: Icons.free_breakfast,
  ),
  HealthTip(
    title: 'Limit Processed Foods',
    description:
        'Processed foods are high in sodium, unhealthy fats, and additives. Cook whole-food meals as often as possible.',
    category: 'Nutrition',
    icon: Icons.dangerous,
  ),
 
  // ── Mental Health ─────────────────────────────────────────────────────────
  HealthTip(
    title: 'Practice Deep Breathing',
    description:
        'Deep breathing activates the parasympathetic nervous system, reducing stress and improving focus instantly.',
    category: 'Mental Health',
    icon: Icons.air,
  ),
  HealthTip(
    title: 'Keep a Gratitude Journal',
    description:
        'Writing 3 things you\'re grateful for each day rewires the brain toward positivity and improves mental resilience.',
    category: 'Mental Health',
    icon: Icons.menu_book,
  ),
  HealthTip(
    title: 'Limit Social Media',
    description:
        'Set daily limits on social media usage. Excessive scrolling has been linked to anxiety, depression, and poor sleep.',
    category: 'Mental Health',
    icon: Icons.phone_disabled,
  ),
  HealthTip(
    title: 'Connect with Loved Ones',
    description:
        'Strong social bonds are one of the greatest predictors of long-term health and happiness. Call a friend today.',
    category: 'Mental Health',
    icon: Icons.group,
  ),
  HealthTip(
    title: 'Meditate Daily',
    description:
        'Even 10 minutes of daily meditation reduces cortisol, improves emotional regulation, and sharpens focus.',
    category: 'Mental Health',
    icon: Icons.self_improvement,
  ),
  HealthTip(
    title: 'Spend Time in Nature',
    description:
        'Green environments lower blood pressure, reduce anxiety, and restore mental energy. Aim for 20 minutes outdoors daily.',
    category: 'Mental Health',
    icon: Icons.park,
  ),
  HealthTip(
    title: 'Set Healthy Boundaries',
    description:
        'Learning to say no protects your energy and mental health. Prioritize commitments that align with your values.',
    category: 'Mental Health',
    icon: Icons.shield,
  ),
 
  // ── Sleep ─────────────────────────────────────────────────────────────────
  HealthTip(
    title: 'Get 7–9 Hours of Sleep',
    description:
        'Quality sleep boosts immunity, memory consolidation, and emotional regulation. Maintain a consistent schedule.',
    category: 'Sleep',
    icon: Icons.bedtime,
  ),
  HealthTip(
    title: 'Avoid Screens Before Bed',
    description:
        'Blue light from screens suppresses melatonin. Switch off devices 1 hour before bedtime for better sleep quality.',
    category: 'Sleep',
    icon: Icons.tv_off,
  ),
  HealthTip(
    title: 'Keep a Cool, Dark Room',
    description:
        'The optimal sleep temperature is 16–19°C (60–67°F). Darkness signals your brain to produce melatonin.',
    category: 'Sleep',
    icon: Icons.nightlight,
  ),
  HealthTip(
    title: 'Limit Caffeine After Noon',
    description:
        'Caffeine has a half-life of ~5 hours. Afternoon coffee can delay sleep onset and reduce sleep quality.',
    category: 'Sleep',
    icon: Icons.coffee_maker,
  ),
  HealthTip(
    title: 'Create a Wind-Down Ritual',
    description:
        'A 30-minute pre-sleep routine — reading, light stretching, or journaling — signals your body it\'s time to rest.',
    category: 'Sleep',
    icon: Icons.nights_stay,
  ),
  HealthTip(
    title: 'Avoid Large Meals Before Bed',
    description:
        'Heavy meals close to bedtime can cause discomfort and interrupt sleep. Finish eating 2–3 hours before sleeping.',
    category: 'Sleep',
    icon: Icons.no_meals,
  ),
 
  // ── Hydration ─────────────────────────────────────────────────────────────
  HealthTip(
    title: 'Drink Water First Thing',
    description:
        'Start your day with a glass of water to rehydrate after sleep, wake up your metabolism, and improve alertness.',
    category: 'Hydration',
    icon: Icons.water_drop,
  ),
  HealthTip(
    title: 'Carry a Reusable Water Bottle',
    description:
        'Keeping water visible increases how much you drink. Aim to finish one large bottle before lunch.',
    category: 'Hydration',
    icon: Icons.sports_bar,
  ),
  HealthTip(
    title: 'Eat Water-Rich Foods',
    description:
        'Cucumbers, watermelon, oranges, and celery are 90%+ water. They contribute to your daily hydration goals.',
    category: 'Hydration',
    icon: Icons.local_dining,
  ),
  HealthTip(
    title: 'Monitor Urine Color',
    description:
        'Pale yellow urine indicates good hydration. Dark yellow or amber means you need to drink more water immediately.',
    category: 'Hydration',
    icon: Icons.colorize,
  ),
  HealthTip(
    title: 'Hydrate Before Exercise',
    description:
        'Drink 500ml of water 2 hours before working out. Proper pre-exercise hydration improves performance and endurance.',
    category: 'Hydration',
    icon: Icons.local_drink,
  ),
  HealthTip(
    title: 'Replace Sodas with Infused Water',
    description:
        'Add slices of lemon, cucumber, or mint to water for a refreshing, sugar-free alternative to sugary drinks.',
    category: 'Hydration',
    icon: Icons.emoji_food_beverage,
  ),
 
  // ── Wellness ─────────────────────────────────────────────────────────────
  HealthTip(
    title: 'Get Regular Health Check-Ups',
    description:
        'Annual check-ups help detect health issues early when they\'re most treatable. Don\'t wait until you feel sick.',
    category: 'Wellness',
    icon: Icons.medical_services,
  ),
  HealthTip(
    title: 'Practice Good Posture',
    description:
        'Good posture reduces back and neck pain, improves breathing, and even boosts confidence and mood.',
    category: 'Wellness',
    icon: Icons.accessibility,
  ),
  HealthTip(
    title: 'Laugh More Often',
    description:
        'Laughter releases endorphins, reduces stress hormones, and even boosts immune function. Watch something funny today.',
    category: 'Wellness',
    icon: Icons.sentiment_very_satisfied,
  ),
  HealthTip(
    title: 'Maintain Good Hand Hygiene',
    description:
        'Washing hands for 20 seconds with soap is one of the most effective ways to prevent illness and infection.',
    category: 'Wellness',
    icon: Icons.clean_hands,
  ),
  HealthTip(
    title: 'Protect Your Skin from Sun',
    description:
        'Apply SPF 30+ sunscreen daily, even in cloudy weather. UV exposure is the leading cause of premature skin aging.',
    category: 'Wellness',
    icon: Icons.wb_sunny,
  ),
  HealthTip(
    title: 'Floss and Brush Daily',
    description:
        'Oral health is directly linked to heart health. Brush twice and floss once daily to prevent gum disease.',
    category: 'Wellness',
    icon: Icons.health_and_safety,
  ),
  HealthTip(
    title: 'Take Breaks from Screens',
    description:
        'Follow the 20-20-20 rule: every 20 minutes, look at something 20 feet away for 20 seconds to reduce eye strain.',
    category: 'Wellness',
    icon: Icons.remove_red_eye,
  ),
  HealthTip(
    title: 'Practice Intermittent Fasting',
    description:
        'Time-restricted eating (e.g., 16:8) can improve metabolism, reduce inflammation, and support healthy weight management.',
    category: 'Wellness',
    icon: Icons.timer,
  ),
];
 
// ─────────────────────────────────────────────────────────────────────────────
// CATEGORY METADATA
// ─────────────────────────────────────────────────────────────────────────────
 
class _CategoryMeta {
  final String name;
  final IconData icon;
  final Color color;
  final Color lightBg;
 
  const _CategoryMeta({
    required this.name,
    required this.icon,
    required this.color,
    required this.lightBg,
  });
}
 
const List<_CategoryMeta> kCategories = [
  _CategoryMeta(
    name: 'Exercise',
    icon: Icons.fitness_center,
    color: Color(0xFFFF6B35),
    lightBg: Color(0xFFFFF0EB),
  ),
  _CategoryMeta(
    name: 'Nutrition',
    icon: Icons.restaurant,
    color: Color(0xFF2ECC71),
    lightBg: Color(0xFFEAFAF1),
  ),
  _CategoryMeta(
    name: 'Mental Health',
    icon: Icons.self_improvement,
    color: Color(0xFF9B59B6),
    lightBg: Color(0xFFF5EEF8),
  ),
  _CategoryMeta(
    name: 'Sleep',
    icon: Icons.bedtime,
    color: Color(0xFF3498DB),
    lightBg: Color(0xFFEBF5FB),
  ),
  _CategoryMeta(
    name: 'Hydration',
    icon: Icons.water_drop,
    color: Color(0xFF1ABC9C),
    lightBg: Color(0xFFE8F8F5),
  ),
  _CategoryMeta(
    name: 'Wellness',
    icon: Icons.favorite,
    color: Color(0xFFE74C3C),
    lightBg: Color(0xFFFDEDEC),
  ),
];
 
_CategoryMeta _metaFor(String category) =>
    kCategories.firstWhere((c) => c.name == category,
        orElse: () => const _CategoryMeta(
              name: 'Wellness',
              icon: Icons.favorite,
              color: Color(0xFFE74C3C),
              lightBg: Color(0xFFFDEDEC),
            ));
 
// ─────────────────────────────────────────────────────────────────────────────
// PAGE
// ─────────────────────────────────────────────────────────────────────────────
 
class HealthTipsPage extends StatefulWidget {
  const HealthTipsPage({super.key});
 
  @override
  State<HealthTipsPage> createState() => _HealthTipsPageState();
}
 
class _HealthTipsPageState extends State<HealthTipsPage>
    with TickerProviderStateMixin {
  late HealthTip _dailyTip;
  String? _selectedCategory;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  late AnimationController _cardCtrl;
  late Animation<Offset> _cardSlide;
  late Animation<double> _cardFade;
  final TextEditingController _searchCtrl = TextEditingController();
  String _searchQuery = '';
 
  @override
  void initState() {
    super.initState();
    _dailyTip = _randomTip();
 
    _fadeCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeIn);
    _fadeCtrl.forward();
 
    _cardCtrl =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeIn);
    _cardCtrl.forward();
  }
 
  @override
  void dispose() {
    _fadeCtrl.dispose();
    _cardCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }
 
  HealthTip _randomTip() =>
      kAllTips[Random().nextInt(kAllTips.length)];
 
  void _refreshTip() {
    _cardCtrl.reverse().then((_) {
      setState(() => _dailyTip = _randomTip());
      _cardCtrl.forward();
    });
  }
 
  List<HealthTip> get _filteredTips {
    final base = _selectedCategory == null
        ? kAllTips
        : kAllTips.where((t) => t.category == _selectedCategory).toList();
    if (_searchQuery.isEmpty) return base;
    final q = _searchQuery.toLowerCase();
    return base
        .where((t) =>
            t.title.toLowerCase().contains(q) ||
            t.description.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q))
        .toList();
  }
 
  // ── Build ──────────────────────────────────────────────────────────────────
 
  @override
  Widget build(BuildContext context) {
    final themeManager = Provider.of<ThemeManager>(context);
    final isDark = themeManager.isDarkMode;
    final theme = Theme.of(context);
 
    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF0F1117) : const Color(0xFFF4F7FE),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildAppBar(isDark, theme),
            SliverToBoxAdapter(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDailyTipCard(isDark),
                    const SizedBox(height: 28),
                    _buildSearchBar(isDark),
                    const SizedBox(height: 24),
                    _buildCategorySection(isDark),
                    const SizedBox(height: 28),
                    _buildTipsHeader(isDark),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),
            _buildTipsList(isDark),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
 
  // ── App Bar ────────────────────────────────────────────────────────────────
 
  SliverAppBar _buildAppBar(bool isDark, ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 110,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor:
          isDark ? const Color(0xFF161B27) : const Color(0xFF1A56DB),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding:
            const EdgeInsets.only(left: 20, bottom: 14),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Health Tips',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              '${kAllTips.length} curated tips',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E2A45), const Color(0xFF161B27)]
                  : [const Color(0xFF1A56DB), const Color(0xFF1E40AF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.only(right: 20),
              child: Opacity(
                opacity: 0.12,
                child: Icon(Icons.health_and_safety,
                    size: 110, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
 
  // ── Daily Tip Card ─────────────────────────────────────────────────────────
 
  Widget _buildDailyTipCard(bool isDark) {
    final meta = _metaFor(_dailyTip.category);
    return SlideTransition(
      position: _cardSlide,
      child: FadeTransition(
        opacity: _cardFade,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isDark
                  ? [const Color(0xFF1E2A45), const Color(0xFF162035)]
                  : [const Color(0xFF1A56DB), const Color(0xFF2563EB)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: (isDark
                        ? const Color(0xFF1A56DB)
                        : const Color(0xFF1A56DB))
                    .withOpacity(isDark ? 0.15 : 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: Colors.white, size: 14),
                        const SizedBox(width: 5),
                        const Text(
                          'Tip of the Day',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: meta.color.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2), width: 1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(meta.icon, color: Colors.white, size: 13),
                        const SizedBox(width: 5),
                        Text(
                          _dailyTip.category,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                _dailyTip.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _dailyTip.description,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  height: 1.55,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: _refreshTip,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.3), width: 1),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shuffle_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 6),
                          Text(
                            'New Tip',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
 
  // ── Search Bar ─────────────────────────────────────────────────────────────
 
  Widget _buildSearchBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2535) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) => setState(() => _searchQuery = v.trim()),
        style: TextStyle(
            color: isDark ? Colors.white : const Color(0xFF1E293B),
            fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Search health tips…',
          hintStyle: TextStyle(
              color: isDark ? Colors.white38 : Colors.grey.shade400,
              fontSize: 15),
          prefixIcon: Icon(Icons.search_rounded,
              color: isDark ? Colors.white38 : Colors.grey.shade400),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                      size: 18),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }
 
  // ── Category Section ───────────────────────────────────────────────────────
 
  Widget _buildCategorySection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('Categories', Icons.grid_view_rounded, isDark),
        const SizedBox(height: 14),
        SizedBox(
          height: 48,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: kCategories.length + 1,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              if (i == 0) {
                final isAll = _selectedCategory == null;
                return _CategoryChip(
                  label: 'All',
                  icon: Icons.apps_rounded,
                  color: const Color(0xFF1A56DB),
                  isSelected: isAll,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedCategory = null),
                );
              }
              final cat = kCategories[i - 1];
              final isSelected = _selectedCategory == cat.name;
              return _CategoryChip(
                label: cat.name,
                icon: cat.icon,
                color: cat.color,
                isSelected: isSelected,
                isDark: isDark,
                onTap: () => setState(() => _selectedCategory =
                    isSelected ? null : cat.name),
              );
            },
          ),
        ),
      ],
    );
  }
 
  // ── Tips Header ───────────────────────────────────────────────────────────
 
  Widget _buildTipsHeader(bool isDark) {
    final count = _filteredTips.length;
    final label = _selectedCategory ?? 'All Tips';
    return Row(
      children: [
        _buildSectionTitle(label, Icons.format_list_bulleted_rounded, isDark),
        const Spacer(),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF1A56DB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count tips',
            style: const TextStyle(
              color: Color(0xFF1A56DB),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
 
  // ── Tips List ─────────────────────────────────────────────────────────────
 
  SliverList _buildTipsList(bool isDark) {
    final tips = _filteredTips;
    if (tips.isEmpty) {
      return SliverList(
        delegate: SliverChildListDelegate([
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 60),
            child: Column(
              children: [
                Icon(Icons.search_off_rounded,
                    size: 60,
                    color: isDark ? Colors.white24 : Colors.grey.shade300),
                const SizedBox(height: 16),
                Text(
                  'No tips found',
                  style: TextStyle(
                      color: isDark ? Colors.white38 : Colors.grey.shade400,
                      fontSize: 16,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ]),
      );
    }
 
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (ctx, i) {
          final tip = tips[i];
          return Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
            child: _TipCard(tip: tip, isDark: isDark),
          );
        },
        childCount: tips.length,
      ),
    );
  }
 
  // ── Helpers ────────────────────────────────────────────────────────────────
 
  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: const Color(0xFF1A56DB).withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon,
              color: const Color(0xFF1A56DB), size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE WIDGETS
// ─────────────────────────────────────────────────────────────────────────────
 
class _CategoryChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;
 
  const _CategoryChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? color
              : (isDark ? const Color(0xFF1E2535) : Colors.white),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected
                ? color
                : (isDark
                    ? Colors.white12
                    : Colors.grey.shade200),
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.35),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 16,
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white54 : Colors.grey.shade600)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark
                        ? Colors.white70
                        : const Color(0xFF374151)),
                fontSize: 13,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ─────────────────────────────────────────────────────────────────────────────
 
class _TipCard extends StatefulWidget {
  final HealthTip tip;
  final bool isDark;
 
  const _TipCard({required this.tip, required this.isDark});
 
  @override
  State<_TipCard> createState() => _TipCardState();
}
 
class _TipCardState extends State<_TipCard> {
  bool _expanded = false;
 
  @override
  Widget build(BuildContext context) {
    final meta = _metaFor(widget.tip.category);
    final isDark = widget.isDark;
 
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2236) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _expanded
              ? meta.color.withOpacity(0.35)
              : (isDark ? Colors.white.withOpacity(0.06) : Colors.grey.shade100),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => setState(() => _expanded = !_expanded),
          splashColor: meta.color.withOpacity(0.05),
          highlightColor: meta.color.withOpacity(0.03),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDark
                            ? meta.color.withOpacity(0.15)
                            : meta.lightBg,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child:
                          Icon(widget.tip.icon, color: meta.color, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.tip.title,
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: meta.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                widget.tip.category,
                                style: TextStyle(
                                    color: meta.color,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: isDark ? Colors.white38 : Colors.grey.shade400,
                        size: 22,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Column(
                      children: [
                        Divider(
                          color: isDark
                              ? Colors.white10
                              : Colors.grey.shade100,
                          height: 1,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.tip.description,
                          style: TextStyle(
                            color: isDark
                                ? Colors.white70
                                : const Color(0xFF475569),
                            fontSize: 14,
                            height: 1.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: _expanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}