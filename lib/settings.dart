import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsPage extends StatefulWidget {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final TextEditingController _ipController = TextEditingController();
  final String _ipKey = 'simulator_ip';

  @override
  void initState() {
    super.initState();
    _loadIP();
  }

  bool isConnected = false;
  bool isChecking = false;

  Future<void> _checkConnection() async {
    setState(() {
      isChecking = true;
    });

    try {
      final ip = _ipController.text.trim();
      final response = await http
          .get(Uri.parse('http://$ip:5000/get_health_data'))
          .timeout(const Duration(seconds: 2));

      if (response.statusCode == 200) {
        setState(() {
          isConnected = true;
        });
      } else {
        setState(() {
          isConnected = false;
        });
      }
    } catch (e) {
      setState(() {
        isConnected = false;
      });
    }

    setState(() {
      isChecking = false;
    });
  }

  Future<void> _loadIP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString(_ipKey);
    if (ip != null) {
      _ipController.text = ip;
      await _checkConnection();
    }
  }

  Future<void> _saveIP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, _ipController.text.trim());
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("IP address saved")));
    await _checkConnection();
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text(
        "Wearable Device Settings",
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.deepPurple,
          letterSpacing: 1,
        ),
      )),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ✅ Connection status row
            Row(
              children: [
                Icon(Icons.watch_rounded),
                const SizedBox(width: 8),
                Text(
                  isChecking
                      ? "Checking..."
                      : (isConnected ? "Connected" : "Disconnected"),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4b4453),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isConnected ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text("Enter the IP address of your wearable simulator:"),
            const SizedBox(height: 16),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: "Simulator IP Address",
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveIP,
              child: const Text("Save Settings"),
            ),
          ],
        ),
      ),
    );
  }
}
