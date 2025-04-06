import 'package:flutter/material.dart';
import 'db_controller.dart';

class UserInfoPage extends StatefulWidget {
  const UserInfoPage({super.key});

  @override
  _UserInfoPageState createState() => _UserInfoPageState();
}

class _UserInfoPageState extends State<UserInfoPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  int? _userId;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await DBHelper.instance.getUser();
    if (user != null) {
      setState(() {
        _userId = user['id'];
        _nameController.text = user['name'];
        _ageController.text = user['age'].toString();
        _weightController.text = user['weight'].toString();
        _heightController.text = user['height'].toString();
      });
    }
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final user = {
        'name': _nameController.text,
        'age': double.parse(_ageController.text),
        'weight': double.parse(_weightController.text),
        'height': double.parse(_heightController.text),
      };
      if (_userId == null) {
        await DBHelper.instance.insertUser(user);
      } else {
        user['id'] = _userId as Object;
        await DBHelper.instance.updateUser(user);
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User info saved')),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Info'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _ageController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Age'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your age';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _weightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your weight';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _heightController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Height (cm)'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your height';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveUser,
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
