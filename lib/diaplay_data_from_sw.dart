import 'package:flutter/material.dart';
import 'server_communication.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return SmartWatchDashboard();
  }
}

class SmartWatchDashboard extends StatefulWidget {
  const SmartWatchDashboard({super.key});

  @override
  SmartWatchDashboardState createState() => SmartWatchDashboardState();
}

class SmartWatchDashboardState extends State<SmartWatchDashboard> {
  late ServerCommunication serverComm;
  bool isGeneratingData = false;
  Map<String, dynamic> healthData = {};

  @override
  void initState() {
    super.initState();
    serverComm = ServerCommunication();

    // Listen for incoming health data
    serverComm.onHealthData((data) {
      setState(() {
        healthData = data;
      });
    });
  }

  void toggleDataGeneration() {
    serverComm.toggleDataGeneration(isGeneratingData);
    setState(() {
      isGeneratingData = !isGeneratingData;
    });
  }

  void getSingleReading() {
    serverComm.getSingleReading((data) {
      setState(() {
        healthData = data;
      });
    });
  }

  @override
  void dispose() {
    serverComm.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Wrap everything in a ListView for scrolling.
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Icon(Icons.watch_rounded),
                      Text(
                        ' ${serverComm.isConnected ? "Connected" : "Disconnected"}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          //color: serverComm.isConnected ? Colors.green : Colors.red,
                          color: const Color(0xFF4b4453),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.all(15),
                    width: 15,
                    height: 15,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: serverComm.isConnected ? Colors.green : Colors.red,
                    ),
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          if (healthData.isNotEmpty) ...[
            const Text(
              'Health Metrics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
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
            _buildMetricCardRectangular(
              'Stress Level',
              '${healthData["stress_level"] ?? "N/A"}/100',
              Icons.psychology,
              Colors.deepPurple,
            ),
            const SizedBox(height: 24),
            if (healthData["sleep_data"] != null) ...[
              const Text(
                'Sleep Metrics',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Sleep: ${(healthData["sleep_data"]["total_sleep_minutes"] / 60).toStringAsFixed(1)} hours',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            _buildSleepBar(
                                'Deep',
                                healthData["sleep_data"]["deep_sleep_minutes"],
                                Colors.indigo),
                            _buildSleepBar(
                                'REM',
                                healthData["sleep_data"]["rem_sleep_minutes"],
                                Colors.blue),
                            _buildSleepBar(
                                'Light',
                                healthData["sleep_data"]["light_sleep_minutes"],
                                Colors.lightBlue),
                            _buildSleepBar(
                                'Awake',
                                healthData["sleep_data"]["awake_minutes"],
                                Colors.grey),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        children: [
                          _buildLegendItem('Deep', Colors.indigo),
                          _buildLegendItem('REM', Colors.blue),
                          _buildLegendItem('Light', Colors.lightBlue),
                          _buildLegendItem('Awake', Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildSleepBar(String label, int minutes, Color color) {
    final totalMinutes = healthData["sleep_data"]["total_sleep_minutes"];
    final percentage = totalMinutes > 0 ? minutes / totalMinutes : 0;

    return Expanded(
      flex: (percentage * 100).toInt(),
      child: Container(
        height: 24,
        color: color,
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 4),
        Text(label),
      ],
    );
  }
}
