import 'package:flutter/material.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';
import 'package:intl/intl.dart';
import 'db_controller.dart';
import 'gemini_service.dart';

class GoalDashboardPage extends StatefulWidget {
  const GoalDashboardPage({super.key});

  @override
  State<GoalDashboardPage> createState() => _GoalDashboardPageState();
}

class _GoalDashboardPageState extends State<GoalDashboardPage> {
  double calories = 0;
  double protein = 0;
  double fat = 0;
  int steps = 0;

  String _aiTip = "";
  final GeminiService _geminiService = GeminiService();

  @override
  void initState() {
    super.initState();
    _loadTodaySummary();
  }

  Future<void> _loadTodaySummary() async {
    final db = await DBHelper.instance.database;
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Food summary
    final foodData = await db.query(
      'consumed_food',
      where: "added_at LIKE ?",
      whereArgs: ['$today%'],
    );

    double totalCalories = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (var food in foodData) {
      int count = (food['count'] ?? 1) as int;
      totalCalories += ((food['calories'] ?? 0) as num).toDouble() * count;
      totalProtein += ((food['protein'] ?? 0) as num).toDouble() * count;
      totalFat += ((food['fat'] ?? 0) as num).toDouble() * count;
    }

    // Steps (from latest health record today)
    final healthData = await db.query(
      'health_data',
      where: "recorded_at LIKE ?",
      whereArgs: ['$today%'],
      orderBy: 'recorded_at DESC',
      limit: 1,
    );

    int stepCount = 0;
    if (healthData.isNotEmpty) {
      stepCount = (healthData.first['steps'] ?? 0) as int;
    }

    setState(() {
      calories = totalCalories;
      protein = totalProtein;
      fat = totalFat;
      steps = stepCount;
    });

    // Fetch Gemini AI suggestions
    final geminiText = await getGeminiSuggestions();
    if (mounted) {
      setState(() {
        _aiTip = geminiText;
      });
    }
  }

  Future<String> getGeminiSuggestions() async {
    final db = await DBHelper.instance.database;
    final today = DateTime.now().toIso8601String().split("T")[0];

    final user = await db.query('user', limit: 1);
    final health = await db.query(
      'health_data',
      where: "recorded_at LIKE ?",
      whereArgs: ['$today%'],
      orderBy: 'recorded_at DESC',
      limit: 1,
    );
    final food = await db.query(
      'consumed_food',
      where: "added_at LIKE ?",
      whereArgs: ['$today%'],
    );

    if (user.isEmpty) return "No user profile found.";

    // Calculate food totals
    double calories = 0, protein = 0, fat = 0;
    for (var f in food) {
      int count = (f['count'] ?? 1) as int;
      calories += ((f['calories'] ?? 0) as num).toDouble() * count;
      protein += ((f['protein'] ?? 0) as num).toDouble() * count;
      fat += ((f['fat'] ?? 0) as num).toDouble() * count;
    }

    final userData = user.first;
    final healthData = health.isNotEmpty ? health.first : {};

    final prompt = """
My name is ${userData['name']}.
I'm a ${userData['age']} year old ${userData['gender']} with weight ${userData['weight']}kg and height ${userData['height']}cm.

Today's food summary:
- Calories consumed: ${calories.toStringAsFixed(0)} kcal
- Protein: ${protein.toStringAsFixed(1)} g
- Fat: ${fat.toStringAsFixed(1)} g

Today's health vitals:
- Steps: ${healthData['steps'] ?? 'N/A'}
- Heart Rate: ${healthData['heart_rate'] ?? 'N/A'} BPM
- BP: ${healthData['systolic'] ?? '--'}/${healthData['diastolic'] ?? '--'}
- SpO2: ${healthData['oxygen_saturation'] ?? 'N/A'}%
- Temperature: ${healthData['temperature'] ?? 'N/A'}°C

As a health assistant, please give 3 short, friendly suggestions based on this data. Keep it simple and actionable.
""";

    return await _geminiService.getResponse(prompt);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
        "Goal Dashboard",
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.deepPurple,
          letterSpacing: 1,
        ),
      )),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildProgressBar(
                "Calories", calories, 2200, Colors.orange, "kcal"),
            _buildProgressBar("Protein", protein, 60, Colors.green, "g"),
            _buildProgressBar("Fat", fat, 70, Colors.purple, "g"),
            _buildProgressBar(
                "Steps", steps.toDouble(), 8000, Colors.blue, "steps"),
            const SizedBox(height: 24),
            const Text(
              "AI Coach Tips:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _aiTip.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(_aiTip,
                          style: const TextStyle(fontSize: 15, height: 1.4)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
      String label, double value, double goal, Color color, String unit) {
    double percent = (value / goal).clamp(0.0, 1.0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              "$label: ${value.toStringAsFixed(0)} / ${goal.toStringAsFixed(0)} $unit"),
          const SizedBox(height: 4),
          LinearPercentIndicator(
            lineHeight: 14.0,
            percent: percent,
            backgroundColor: color.withOpacity(0.2),
            progressColor: color,
            barRadius: const Radius.circular(10),
          ),
        ],
      ),
    );
  }
}
