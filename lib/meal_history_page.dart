import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'db_controller.dart';

class MealHistoryPage extends StatefulWidget {
  const MealHistoryPage({super.key});

  @override
  State<MealHistoryPage> createState() => _MealHistoryPageState();
}

class _MealHistoryPageState extends State<MealHistoryPage> {
  Map<String, List<Map<String, dynamic>>> mealsByDate = {};

  @override
  void initState() {
    super.initState();
    _loadMeals();
  }

  Future<void> _loadMeals() async {
    final db = await DBHelper.instance.database;
    final result = await db.query('consumed_food', orderBy: 'added_at DESC');

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var meal in result) {
      final date = meal['added_at'].toString().split(' ')[0]; // yyyy-MM-dd
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(meal);
    }

    setState(() {
      mealsByDate = grouped;
    });
  }

  String _formatDateLabel(String dateStr) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final yesterday = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(const Duration(days: 1)));

    if (dateStr == today) return 'Today';
    if (dateStr == yesterday) return 'Yesterday';

    final parsed = DateFormat('yyyy-MM-dd').parse(dateStr);
    return DateFormat('MMM dd, yyyy').format(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Meal History")),
      body: mealsByDate.isEmpty
          ? const Center(child: Text("No saved meals found."))
          : ListView(
              padding: const EdgeInsets.all(12.0),
              children: mealsByDate.entries.map((entry) {
                final dateLabel = _formatDateLabel(entry.key);
                final meals = entry.value;

                final totalCalories = meals.fold<double>(
                    0,
                    (sum, item) =>
                        sum + (item['calories'] ?? 0) * (item['count'] ?? 1));
                final totalProtein = meals.fold<double>(
                    0,
                    (sum, item) =>
                        sum + (item['protein'] ?? 0) * (item['count'] ?? 1));
                final totalFat = meals.fold<double>(
                    0,
                    (sum, item) =>
                        sum + (item['fat'] ?? 0) * (item['count'] ?? 1));

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildSummaryCard(totalCalories, totalProtein, totalFat),
                    const SizedBox(height: 8),
                    ...meals.map((meal) => ListTile(
                          title: Text("${meal['name']} (${meal['unit']})"),
                          subtitle: Text("Category: ${meal['category']}"),
                          trailing: Text("x${meal['count']}"),
                        )),
                    const Divider(thickness: 1.2),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildSummaryCard(double cal, double protein, double fat) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _nutrientCircle("Calories", cal, 2500, "kcal", Colors.orange),
            _nutrientCircle("Protein", protein, 100, "g", Colors.green),
            _nutrientCircle("Fat", fat, 70, "g", Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _nutrientCircle(
      String label, double value, double max, String unit, Color color) {
    double percent = (value / max).clamp(0.0, 1.0);

    return Column(
      children: [
        CircularPercentIndicator(
          radius: 45.0,
          lineWidth: 8.0,
          percent: percent,
          center: Text("${value.toInt()} $unit",
              style:
                  const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          progressColor: color,
          backgroundColor: color.withOpacity(0.1),
          circularStrokeCap: CircularStrokeCap.round,
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
