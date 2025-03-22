import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'user_input_page.dart';
import 'server_communication.dart';

var logger = Logger();

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smartwatch Simulator',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/second': (context) => const SecondPage(),
      },
    );
  }
}

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('HealthSync'),
        backgroundColor: Colors.grey,
        actions: [
          Container(
            margin: const EdgeInsets.all(15),
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              // Use serverComm.isConnected for connection status
              color: serverComm.isConnected ? Colors.green : Colors.red,
            ),
          )
        ],
      ),
      body: Column(
        children: [
          Center(
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(context, '/second');
              },
              child: const Text('Go to second page'),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Server Status: ${serverComm.isConnected ? "Connected" : "Disconnected"}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: serverComm.isConnected
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                        Text(
                          'Data Stream: ${isGeneratingData ? "Active" : "Inactive"}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color:
                                isGeneratingData ? Colors.green : Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed:
                          serverComm.isConnected ? toggleDataGeneration : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isGeneratingData ? Colors.red : Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: Text(isGeneratingData
                          ? 'Stop Data Stream'
                          : 'Start Data Stream'),
                    ),
                    ElevatedButton(
                      onPressed:
                          serverComm.isConnected ? getSingleReading : null,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                      ),
                      child: const Text('Get Single Reading'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Health data display section (same as before)
                if (healthData.isNotEmpty) ...[
                  const Text(
                    'Health Metrics',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildMetricCard(
                        'Heart Rate',
                        '${healthData["heart_rate"] ?? "N/A"} BPM',
                        Icons.favorite,
                        Colors.red,
                      ),
                      _buildMetricCard(
                        'Blood Pressure',
                        healthData["blood_pressure"] != null
                            ? '${healthData["blood_pressure"]["systolic"]}/${healthData["blood_pressure"]["diastolic"]} mmHg'
                            : 'N/A',
                        Icons.trending_up,
                        Colors.purple,
                      ),
                      _buildMetricCard(
                        'Steps',
                        '${healthData["total_steps"] ?? healthData["steps"] ?? "N/A"}',
                        Icons.directions_walk,
                        Colors.blue,
                      ),
                      _buildMetricCard(
                        'Respiratory Rate',
                        '${healthData["respiratory_rate"] ?? "N/A"} br/min',
                        Icons.air,
                        Colors.cyan,
                      ),
                      _buildMetricCard(
                        'Oxygen Saturation',
                        '${healthData["oxygen_saturation"] ?? "N/A"}%',
                        Icons.opacity,
                        Colors.indigo,
                      ),
                      _buildMetricCard(
                        'Temperature',
                        '${healthData["temperature"] ?? "N/A"}°C',
                        Icons.thermostat,
                        Colors.orange,
                      ),
                      _buildMetricCard(
                        'Stress Level',
                        '${healthData["stress_level"] ?? "N/A"}/100',
                        Icons.psychology,
                        Colors.deepPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (healthData["sleep_data"] != null) ...[
                    const Text(
                      'Sleep Metrics',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Sleep: ${(healthData["sleep_data"]["total_sleep_minutes"] / 60).toStringAsFixed(1)} hours',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: Row(
                                children: [
                                  _buildSleepBar(
                                      'Deep',
                                      healthData["sleep_data"]
                                          ["deep_sleep_minutes"],
                                      Colors.indigo),
                                  _buildSleepBar(
                                      'REM',
                                      healthData["sleep_data"]
                                          ["rem_sleep_minutes"],
                                      Colors.blue),
                                  _buildSleepBar(
                                      'Light',
                                      healthData["sleep_data"]
                                          ["light_sleep_minutes"],
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
                        'No health data available.\nConnect to server and request data.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w500, color: color),
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
