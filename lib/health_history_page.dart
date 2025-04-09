import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'db_controller.dart';

class HealthHistoryPage extends StatefulWidget {
  const HealthHistoryPage({super.key});

  @override
  State<HealthHistoryPage> createState() => _HealthHistoryPageState();
}

class _HealthHistoryPageState extends State<HealthHistoryPage> {
  Map<String, List<Map<String, dynamic>>> healthByDate = {};

  @override
  void initState() {
    super.initState();
    _loadHealthData();
  }

  Future<void> _loadHealthData() async {
    final db = await DBHelper.instance.database;
    final result = await db.query('health_data', orderBy: 'recorded_at DESC');

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var row in result) {
      final date = row['recorded_at'].toString().split('T')[0]; // yyyy-MM-dd
      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(row);
    }

    setState(() {
      healthByDate = grouped;
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
      appBar: AppBar(title: const Text("Health History")),
      body: healthByDate.isEmpty
          ? const Center(child: Text("No health data recorded."))
          : ListView(
              padding: const EdgeInsets.all(12.0),
              children: healthByDate.entries.map((entry) {
                final dateLabel = _formatDateLabel(entry.key);
                final items = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...items.map((row) => _buildHealthCard(row)),
                    const SizedBox(height: 20),
                  ],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildHealthCard(Map<String, dynamic> data) {
    final recordedAt = data['recorded_at'] ?? '';
    final steps = (data['steps'] ?? 0) as int;
    final hr = (data['heart_rate'] ?? 0) as int;
    final spo2 = (data['oxygen_saturation'] ?? 0).toDouble();
    final temp = (data['temperature'] ?? 0).toDouble();
    final sys = data['systolic'];
    final dia = data['diastolic'];
    final resp = data['respiratory_rate'];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🕒 $recordedAt",
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey)),

            const SizedBox(height: 12),

            // Radial metrics
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _circularIndicator(
                    "Heart Rate", hr.toDouble(), 200, "BPM", Colors.red),
                _circularIndicator("SpO₂", spo2, 100, "%", Colors.blue),
                _circularIndicator(
                    "Steps", steps.toDouble(), 10000, "", Colors.green),
                _circularIndicator("Temp", temp, 45, "°C", Colors.orange),
              ],
            ),

            const SizedBox(height: 12),

            // Other values
            Wrap(
              spacing: 10,
              runSpacing: 4,
              children: [
                if (sys != null && dia != null)
                  _tagTile(
                      "BP: $sys/$dia mmHg", Icons.bloodtype, Colors.purple),
                if (resp != null)
                  _tagTile("Resp: $resp br/min", Icons.air, Colors.cyan),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _circularIndicator(
      String label, double value, double max, String unit, Color color) {
    double percent = (value / max).clamp(0.0, 1.0);

    return Column(
      children: [
        CircularPercentIndicator(
          radius: 40.0,
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

  Widget _tagTile(String text, IconData icon, Color color) {
    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      avatar: Icon(icon, size: 16, color: color),
      backgroundColor: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    );
  }
}
