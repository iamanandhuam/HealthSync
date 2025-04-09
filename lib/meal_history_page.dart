import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_controller.dart';
import 'package:fl_chart/fl_chart.dart';

class MealHistoryPage extends StatefulWidget {
  const MealHistoryPage({super.key});

  @override
  State<MealHistoryPage> createState() => _MealHistoryPageState();
}

enum DateFilter { all, today, last7days }

class _MealHistoryPageState extends State<MealHistoryPage> {
  Map<String, List<Map<String, dynamic>>> mealsByDate = {};
  DateFilter _selectedFilter = DateFilter.all;

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

      if (_shouldIncludeDate(date)) {
        grouped.putIfAbsent(date, () => []);
        grouped[date]!.add(meal);
      }
    }

    setState(() {
      mealsByDate = grouped;
    });
  }

  bool _shouldIncludeDate(String dateStr) {
    final parsed = DateTime.parse(dateStr);
    final now = DateTime.now();

    switch (_selectedFilter) {
      case DateFilter.today:
        return parsed.year == now.year &&
            parsed.month == now.month &&
            parsed.day == now.day;
      case DateFilter.last7days:
        return parsed.isAfter(now.subtract(const Duration(days: 7)));
      case DateFilter.all:
      default:
        return true;
    }
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Filter:", style: TextStyle(fontSize: 16)),
                DropdownButton<DateFilter>(
                  value: _selectedFilter,
                  onChanged: (value) {
                    setState(() {
                      _selectedFilter = value!;
                    });
                    _loadMeals(); // reload data with new filter
                  },
                  items: const [
                    DropdownMenuItem(value: DateFilter.all, child: Text("All")),
                    DropdownMenuItem(
                        value: DateFilter.today, child: Text("Today")),
                    DropdownMenuItem(
                        value: DateFilter.last7days,
                        child: Text("Last 7 Days")),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: mealsByDate.isEmpty
                ? const Center(child: Text("No saved meals found."))
                : ListView(
                    children: mealsByDate.entries.map((entry) {
                      final dateLabel = _formatDateLabel(entry.key);
                      final meals = entry.value;

                      final totalCalories = meals.fold<double>(0, (sum, item) {
                        return sum +
                            (item['calories'] as num) * (item['count'] ?? 1);
                      });

                      return ExpansionTile(
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              dateLabel,
                              style: const TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '🔥 ${totalCalories.toStringAsFixed(0)} kcal',
                              style: const TextStyle(
                                  color: Colors.deepOrange,
                                  fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        children: meals.map((meal) {
                          return ListTile(
                            title: Text('${meal['name']} (${meal['unit']})'),
                            subtitle: Text(
                                'Category: ${meal['category']} | Quantity: ${meal['count']}'),
                            trailing: Text(
                              '${meal['calories']} kcal',
                              style: const TextStyle(color: Colors.deepPurple),
                            ),
                          );
                        }).toList(),
                      );
                    }).toList(),
                  ),
          ),
          //if (mealsByDate.isNotEmpty) _buildCalorieChart(),
        ],
      ),
    );
  }

  Widget _buildCalorieChart() {
    // Get last 7 dates (sorted)
    final List<String> sortedDates = mealsByDate.keys.toList()
      ..sort((a, b) => a.compareTo(b));

    final List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < sortedDates.length; i++) {
      final date = sortedDates[i];
      final meals = mealsByDate[date]!;

      final totalCalories = meals.fold<double>(0, (sum, item) {
        return sum + (item['calories'] as num) * (item['count'] ?? 1);
      });

      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: totalCalories,
              width: 16,
              color: Colors.deepPurple,
              borderRadius: BorderRadius.circular(4),
            )
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Calories Trend",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          AspectRatio(
            aspectRatio: 1.8,
            child: BarChart(
              BarChartData(
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      interval: 100,
                      getTitlesWidget: (value, _) => Text(
                          '${value.toInt()} kcal',
                          style: TextStyle(fontSize: 10)),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        if (value.toInt() >= sortedDates.length)
                          return const Text('');
                        final date = sortedDates[value.toInt()];
                        return Text(
                            DateFormat('MM/dd').format(DateTime.parse(date)),
                            style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                ),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
