import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  Future<void> _loadIP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? ip = prefs.getString(_ipKey);
    if (ip != null) {
      _ipController.text = ip;
    }
  }

  Future<void> _saveIP() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, _ipController.text.trim());
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("IP address saved")));
  }

  @override
  void dispose() {
    _ipController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
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
