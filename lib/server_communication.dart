import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'db_controller.dart';
import 'package:logger/logger.dart';

final logger = Logger();

class ServerCommunication {
  static final ServerCommunication _instance = ServerCommunication._internal();
  factory ServerCommunication() => _instance;

  ServerCommunication._internal();

  String ipAddress = "127.0.0.1"; // Default

  Future<void> init() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString('simulator_ip');
    if (ip != null && ip.isNotEmpty) {
      ipAddress = ip;
    }
  }

  Future<Map<String, dynamic>?> fetchHealthData() async {
    final url = Uri.parse('http://$ipAddress:5000/get_health_data');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final now = DateTime.now().toIso8601String();
        final dbHelper = DBHelper.instance;
        await dbHelper.insertHealthData({
          'heart_rate': data['heart_rate'],
          'steps': data['total_steps'] ?? data['steps'],
          'systolic': data['blood_pressure']?['systolic'],
          'diastolic': data['blood_pressure']?['diastolic'],
          'temperature': data['temperature'],
          'respiratory_rate': data['respiratory_rate'],
          'oxygen_saturation': data['oxygen_saturation'],
          'recorded_at': now,
        });

        return data;
      } else {
        print("Error fetching data: ${response.statusCode}");
      }
    } catch (e) {
      print("HTTP error: $e");
    }
    return null;
  }
}
