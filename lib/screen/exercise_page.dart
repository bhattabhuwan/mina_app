import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:accurate_step_counter/accurate_step_counter.dart';
import 'package:mina_app/theme/theme_manager.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class ExercisePage extends StatefulWidget {
  const ExercisePage({super.key});

  @override
  State<ExercisePage> createState() => _ExercisePageState();
}

class _ExercisePageState extends State<ExercisePage>
    with WidgetsBindingObserver {
  final AccurateStepCounter _stepCounter = AccurateStepCounter();

  late Stream<int> _stepStream;

  int _currentSteps = 0;
  bool _isInitialized = false;

  Map<String, int> _stepHistory = {};

  int _moveGoal = 8000;
  int _exerciseGoal = 30;
  int _standGoal = 12;

  final List<int> _hourlySteps = [400, 1200, 3200, 4500];
  final List<String> _hourLabels = ['12 AM', '6 AM', '12 PM', '6 PM'];

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    _initStepCounter();
    _loadHistory();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _stepCounter.stopLogging();
    _stepCounter.stop();

    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveTodaySteps();
    }
  }

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();

    final Map<String, int> loaded = {};

    for (int i = 0; i < 7; i++) {
      final date = DateTime.now().subtract(Duration(days: i));

      final key = DateFormat('yyyy-MM-dd').format(date);

      loaded[key] = prefs.getInt(key) ?? 0;
    }

    setState(() {
      _stepHistory = loaded;
    });
  }

  Future<void> _saveTodaySteps() async {
    if (_currentSteps == 0) return;

    final prefs = await SharedPreferences.getInstance();

    final today =
        DateFormat('yyyy-MM-dd').format(DateTime.now());

    await prefs.setInt(today, _currentSteps);

    await _loadHistory();
  }

  Future<void> _initStepCounter() async {
    try {
      await _stepCounter.initializeLogging();

      await _stepCounter.start(
        config: StepDetectorConfig.walking(),
      );

      await _stepCounter.startLogging();

      final todaySteps =
          await _stepCounter.getTodaySteps();

      setState(() {
        _currentSteps = todaySteps;
        _isInitialized = true;
      });

      _stepStream = _stepCounter.watchTodaySteps();

      _stepStream.listen((steps) {
        if (mounted) {
          setState(() {
            _currentSteps = steps;
          });

          _saveTodaySteps();
        }
      });
    } catch (e) {
      debugPrint(e.toString());

      setState(() {
        _isInitialized = true;
      });
    }
  }

  double getDistanceKm() => _currentSteps * 0.0008;

  double getCalories() => _currentSteps * 0.04;

  int getExerciseMinutes() =>
      (_currentSteps / 100).clamp(0, _exerciseGoal).toInt();

  int getStandHours() =>
      (DateTime.now().hour / 2).clamp(0, _standGoal).toInt();

  List<FlSpot> getHistorySpots() {
    final spots = <FlSpot>[];

    final now = DateTime.now();

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));

      final key = DateFormat('yyyy-MM-dd').format(date);

      final steps = _stepHistory[key] ?? 0;

      spots.add(
        FlSpot(i.toDouble(), steps.toDouble()),
      );
    }

    return spots;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode =
        Provider.of<ThemeManager>(context).isDarkMode;

    final now = DateTime.now();

    final dateString =
        '${_getDayName(now.weekday)}, ${_getMonthAbbr(now.month)} ${now.day}';

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor:
            isDarkMode ? Colors.black : Colors.grey.shade50,

        appBar: AppBar(
          elevation: 0,
          centerTitle: true,

          backgroundColor:
              isDarkMode ? Colors.black : Colors.white,

          foregroundColor:
              isDarkMode ? Colors.white : Colors.black,

          title: const Text(
            "Activity",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          bottom: TabBar(
            indicatorColor: Colors.blue,
            labelColor: Colors.blue,

            unselectedLabelColor:
                isDarkMode ? Colors.white54 : Colors.black54,

            tabs: const [
              Tab(
                icon: Icon(Icons.today),
                text: 'Today',
              ),
              Tab(
                icon: Icon(Icons.history),
                text: 'History',
              ),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            _buildTodayTab(isDarkMode, dateString),
            _buildHistoryTab(isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayTab(
      bool isDarkMode,
      String dateString,
      ) {
    final progress =
        (_currentSteps / _moveGoal).clamp(0.0, 1.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,

        children: [
          Text(
            dateString,

            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color:
                  isDarkMode ? Colors.white : Colors.black,
            ),
          ),

          const SizedBox(height: 4),

          Text(
            _getMotivationalMessage(progress),

            style: TextStyle(
              color: Colors.blue.shade600,
              fontSize: 14,
            ),
          ),

          const SizedBox(height: 28),

          // MAIN CARD
          Container(
            padding: const EdgeInsets.all(24),

            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),

              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,

                colors: isDarkMode
                    ? [
                        const Color(0xFF1E1E1E),
                        const Color(0xFF2C2C2C),
                      ]
                    : [
                        Colors.blue.shade50,
                        Colors.white,
                      ],
              ),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),

            child: Column(
              children: [
                // BIG STEPS
                Text(
                  NumberFormat.decimalPattern()
                      .format(_currentSteps),

                  style: TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.bold,
                    color: isDarkMode
                        ? Colors.white
                        : Colors.black,
                  ),
                ),

                const SizedBox(height: 6),

                Text(
                  'Steps Today',

                  style: TextStyle(
                    fontSize: 16,
                    color: isDarkMode
                        ? Colors.white70
                        : Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 24),

                // PROGRESS
                ClipRRect(
                  borderRadius:
                      BorderRadius.circular(20),

                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,

                    backgroundColor:
                        Colors.grey.withOpacity(0.2),

                    valueColor:
                        const AlwaysStoppedAnimation(
                      Colors.blue,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                Align(
                  alignment: Alignment.centerRight,

                  child: Text(
                    '${(progress * 100).toStringAsFixed(0)}% of goal',

                    style: TextStyle(
                      fontSize: 12,
                      color: isDarkMode
                          ? Colors.white60
                          : Colors.grey.shade600,
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                // MINI STATS
                Row(
                  children: [
                    _buildMiniStat(
                      'Distance',
                      '${getDistanceKm().toStringAsFixed(2)} km',
                      Icons.straighten,
                      Colors.green,
                      isDarkMode,
                    ),

                    _buildMiniStat(
                      'Calories',
                      '${getCalories().toStringAsFixed(0)}',
                      Icons.local_fire_department,
                      Colors.orange,
                      isDarkMode,
                    ),

                    _buildMiniStat(
                      'Active',
                      '${getExerciseMinutes()}m',
                      Icons.directions_run,
                      Colors.purple,
                      isDarkMode,
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // RINGS
          Row(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween,

            children: [
              _buildRing(
                'Move',
                _currentSteps,
                _moveGoal,
                Colors.red,
                isDarkMode,
              ),

              _buildRing(
                'Exercise',
                getExerciseMinutes(),
                _exerciseGoal,
                Colors.green,
                isDarkMode,
              ),

              _buildRing(
                'Stand',
                getStandHours(),
                _standGoal,
                Colors.blue,
                isDarkMode,
              ),
            ],
          ),

          const SizedBox(height: 32),

          Text(
            "Hourly Activity",

            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color:
                  isDarkMode ? Colors.white : Colors.black,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            height: 220,

            padding: const EdgeInsets.all(16),

            decoration: BoxDecoration(
              color: isDarkMode
                  ? const Color(0xFF1E1E1E)
                  : Colors.white,

              borderRadius: BorderRadius.circular(28),

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                ),
              ],
            ),

            child: BarChart(
              BarChartData(
                maxY: 5000,

                borderData:
                    FlBorderData(show: false),

                gridData:
                    const FlGridData(show: false),

                titlesData: FlTitlesData(
                  topTitles:
                      const AxisTitles(
                          sideTitles:
                              SideTitles(
                                  showTitles:
                                      false)),

                  rightTitles:
                      const AxisTitles(
                          sideTitles:
                              SideTitles(
                                  showTitles:
                                      false)),

                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,

                      getTitlesWidget:
                          (value, meta) {
                        return Text(
                          '${(value / 1000).toStringAsFixed(0)}k',
                          style: const TextStyle(
                              fontSize: 10),
                        );
                      },
                    ),
                  ),

                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,

                      getTitlesWidget:
                          (value, meta) {
                        return Padding(
                          padding:
                              const EdgeInsets.only(
                                  top: 8),

                          child: Text(
                            _hourLabels[
                                value.toInt()],
                            style:
                                const TextStyle(
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                barGroups: List.generate(
                  _hourlySteps.length,
                  (index) {
                    return BarChartGroupData(
                      x: index,

                      barRods: [
                        BarChartRodData(
                          toY: _hourlySteps[index]
                              .toDouble(),

                          width: 24,

                          borderRadius:
                              BorderRadius.circular(
                                  8),

                          gradient:
                              const LinearGradient(
                            colors: [
                              Colors.blue,
                              Colors.lightBlueAccent,
                            ],
                            begin:
                                Alignment.bottomCenter,
                            end: Alignment.topCenter,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),

          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(bool isDarkMode) {
    final spots = getHistorySpots();

    return Padding(
      padding: const EdgeInsets.all(20),

      child: Container(
        padding: const EdgeInsets.all(20),

        decoration: BoxDecoration(
          color: isDarkMode
              ? const Color(0xFF1E1E1E)
              : Colors.white,

          borderRadius: BorderRadius.circular(28),

          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Text(
              "Last 7 Days",

              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color:
                    isDarkMode ? Colors.white : Colors.black,
              ),
            ),

            const SizedBox(height: 20),

            Expanded(
              child: LineChart(
                LineChartData(
                  borderData:
                      FlBorderData(show: false),

                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),

                  titlesData: FlTitlesData(
                    topTitles:
                        const AxisTitles(
                            sideTitles:
                                SideTitles(
                                    showTitles:
                                        false)),

                    rightTitles:
                        const AxisTitles(
                            sideTitles:
                                SideTitles(
                                    showTitles:
                                        false)),

                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,

                        getTitlesWidget:
                            (value, meta) {
                          return Text(
                            '${(value / 1000).toStringAsFixed(0)}k',
                            style:
                                const TextStyle(
                                    fontSize: 10),
                          );
                        },
                      ),
                    ),

                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,

                        getTitlesWidget:
                            (value, meta) {
                          final date =
                              DateTime.now()
                                  .subtract(
                            Duration(
                              days:
                                  (6 -
                                      value
                                          .toInt()),
                            ),
                          );

                          return Text(
                            DateFormat('E')
                                .format(date),
                          );
                        },
                      ),
                    ),
                  ),

                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,

                      isCurved: true,

                      barWidth: 4,

                      color: Colors.blue,

                      dotData:
                          const FlDotData(
                              show: true),

                      belowBarData:
                          BarAreaData(
                        show: true,
                        color: Colors.blue
                            .withOpacity(0.2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRing(
    String title,
    int current,
    int goal,
    Color color,
    bool isDarkMode,
  ) {
    final progress =
        (current / goal).clamp(0.0, 1.0);

    return Column(
      children: [
        SizedBox(
          width: 90,
          height: 90,

          child: Stack(
            alignment: Alignment.center,

            children: [
              SizedBox(
                width: 90,
                height: 90,

                child: CircularProgressIndicator(
                  value: progress,

                  strokeWidth: 9,

                  backgroundColor:
                      Colors.grey.withOpacity(0.2),

                  valueColor:
                      AlwaysStoppedAnimation(color),
                ),
              ),

              Column(
                mainAxisAlignment:
                    MainAxisAlignment.center,

                children: [
                  Text(
                    '$current',

                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDarkMode
                          ? Colors.white
                          : Colors.black,
                    ),
                  ),

                  Text(
                    title,

                    style: TextStyle(
                      fontSize: 11,
                      color: isDarkMode
                          ? Colors.white60
                          : Colors.black54,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStat(
    String title,
    String value,
    IconData icon,
    Color color,
    bool isDarkMode,
  ) {
    return Expanded(
      child: Container(
        margin:
            const EdgeInsets.symmetric(horizontal: 4),

        padding:
            const EdgeInsets.symmetric(vertical: 14),

        decoration: BoxDecoration(
          color: isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.white,

          borderRadius: BorderRadius.circular(22),
        ),

        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),

              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),

              child: Icon(
                icon,
                size: 18,
                color: color,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              value,

              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color:
                    isDarkMode ? Colors.white : Colors.black,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              title,

              style: TextStyle(
                fontSize: 11,
                color: isDarkMode
                    ? Colors.white60
                    : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMotivationalMessage(double progress) {
    if (progress >= 1) {
      return '🔥 Goal achieved!';
    } else if (progress >= 0.7) {
      return '💪 Almost there!';
    } else if (progress >= 0.4) {
      return '🚶 Keep moving!';
    }

    return '🌟 Every step matters!';
  }

  String _getDayName(int weekday) {
    return const [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ][weekday - 1];
  }

  String _getMonthAbbr(int month) {
    return const [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ][month - 1];
  }
}