import 'package:flutter/material.dart';
import 'server_communication.dart';
import 'package:logger/logger.dart';
import 'db_controller.dart';
import 'health_history_page.dart';

final logger = Logger();

class SmartWatchDashboard extends StatefulWidget {
  const SmartWatchDashboard({super.key});

  @override
  _SmartWatchDashboardState createState() => _SmartWatchDashboardState();
}

class _SmartWatchDashboardState extends State<SmartWatchDashboard> {
  late ServerCommunication serverComm;

  bool isGeneratingData = false;
  Map<String, dynamic> healthData = {};
  bool firstLoadDone = false;

  _SmartWatchDashboardState() {
    logger.i('SmartWatchDashboardState CONSTRUCTOR');
  }

  @override
  void initState() {
    logger.i('INSIDE INIT STATE');
    super.initState();
    serverComm = ServerCommunication();
    serverComm.init().then((_) => getSingleReading());
    _loadUserInfo();
  }

  void getSingleReading() {
    logger.i('GETTING SINGLE READING');
    serverComm.fetchHealthData().then((data) {
      if (data != null) {
        setState(() {
          healthData = data;
          logger.i('health data : ${healthData}');
        });
      }
    });
  }

  String? userName;

  Future<void> _loadUserInfo() async {
    final dbHelper = DBHelper.instance;
    final user = await dbHelper.getUser();
    if (user != null) {
      setState(() {
        userName = user['name'];
      });
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['SUN', 'MON', 'TUES', 'WED', 'THURS', 'FRI', 'SAT'];
    final months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEPT',
      'OCT',
      'NOV',
      'DEC'
    ];
    return '${weekdays[now.weekday % 7]}  ${now.day}  ${months[now.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    // Wrap everything in a ListView for scrolling.
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.wb_sunny, color: Colors.deepPurple),
                      const SizedBox(width: 8),
                      Text(
                        _getFormattedDate(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.deepPurple,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Hello ${userName ?? "there"} !',
                        style: const TextStyle(
                          fontSize: 27,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          if (healthData.isNotEmpty) ...[
            // const Text(
            //   'Health Metrics',
            //   style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            // ),
            const SizedBox(height: 16),
            // Vertical list of rectangular metric cards
            _buildMetricCardRectangular(
              'Heart Rate',
              '${healthData["heart_rate"] ?? "N/A"} BPM',
              Icons.favorite,
              Colors.red,
            ),
            _buildMetricCardRectangular(
              'Blood Pressure',
              healthData["blood_pressure"] != null
                  ? '${healthData["blood_pressure"]["systolic"]}/${healthData["blood_pressure"]["diastolic"]} mmHg'
                  : 'N/A',
              Icons.trending_up,
              Colors.purple,
            ),
            _buildMetricCardRectangular(
              'Steps',
              '${healthData["total_steps"] ?? healthData["steps"] ?? "N/A"}',
              Icons.directions_walk,
              Colors.blue,
            ),
            _buildMetricCardRectangular(
              'Respiratory Rate',
              '${healthData["respiratory_rate"] ?? "N/A"} br/min',
              Icons.air,
              Colors.cyan,
            ),
            _buildMetricCardRectangular(
              'Oxygen Saturation',
              '${healthData["oxygen_saturation"] ?? "N/A"}%',
              Icons.opacity,
              Colors.indigo,
            ),
            _buildMetricCardRectangular(
              'Temperature',
              '${healthData["temperature"] ?? "N/A"}°C',
              Icons.thermostat,
              Colors.orange,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HealthHistoryPage()),
                );
              },
              child: Text(
                "Show Health History",
                style: TextStyle(fontSize: 15),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: getSingleReading,
              child: Text("Get Your Health Info"),
            ),
          ] else ...[
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 32.0),
                child: Text(
                  'No health data available.\nConnect to your wearable device\nand request data.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Returns a rectangular card with curved edges for metric display.
  Widget _buildMetricCardRectangular(
      String title, String value, IconData icon, Color color) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Container(
        height: 60,
        padding: const EdgeInsets.all(10.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                //color: color.withOpacity(0.1),
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 10),
            // Metric name and value.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: color),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
