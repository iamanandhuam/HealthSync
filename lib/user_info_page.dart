import 'package:flutter/material.dart';
import 'package:health_sync/style.dart';
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
  String? gender;

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
        gender = user['gender'];
      });
    }
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final name = _nameController.text.trim();
      final ageText = _ageController.text.trim();
      final weightText = _weightController.text.trim();
      final heightText = _heightController.text.trim();

      if (name.isEmpty ||
          ageText.isEmpty ||
          weightText.isEmpty ||
          heightText.isEmpty ||
          gender == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please fill in all fields")),
        );
        return;
      }

      final user = {
        'name': name,
        'gender': gender,
        'age': double.tryParse(ageText) ?? 0.0,
        'weight': double.tryParse(weightText) ?? 0.0,
        'height': double.tryParse(heightText) ?? 0.0,
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
        title: const Text(" "),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              const SizedBox(height: 10),
              const Center(
                child: CircleAvatar(
                  radius: 45,
                  backgroundColor: primaryPurple,
                  child: Icon(Icons.person, size: 45, color: Colors.white),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Personal Information",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: primaryPurple,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Name',
                  prefixIcon: const Icon(Icons.account_circle_outlined),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Please enter your name'
                    : null,
              ),
              const SizedBox(height: 16),
              _infoCard(
                icon: Icons.person_outline,
                label: 'Gender',
                value: gender ?? 'Not set',
                onTap: _showGenderPicker,
              ),
              _infoCard(
                icon: Icons.cake_outlined,
                label: 'Age',
                value: _ageController.text.isEmpty
                    ? 'Not set'
                    : '${_ageController.text} years',
                onTap: _showAgePicker,
              ),
              _infoCard(
                icon: Icons.monitor_weight_outlined,
                label: 'Weight',
                value: _weightController.text.isEmpty
                    ? 'Not set'
                    : '${_weightController.text} kg',
                onTap: _showWeightPicker,
              ),
              _infoCard(
                icon: Icons.height_outlined,
                label: 'Height',
                value: _heightController.text.isEmpty
                    ? 'Not set'
                    : '${_heightController.text} cm',
                onTap: _showHeightPicker,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _saveUser,
                icon: const Icon(Icons.save),
                label: const Text("Save Info"),
                style: ElevatedButton.styleFrom(
                  //backgroundColor: Colors.deepPurple,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  textStyle: const TextStyle(fontSize: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoCard({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, color: Colors.deepPurple),
        title: Text(label),
        subtitle: Text(value),
        trailing: const Icon(Icons.edit, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  // === Picker dialogs below ===

  Future<void> _showGenderPicker() async {
    final List<String> genders = [
      "Male",
      "Female",
      "Other",
      "Prefer not to say"
    ];
    int currentIndex = genders.indexOf(gender ?? "Male");
    if (currentIndex < 0) currentIndex = 0;
    final scrollController =
        FixedExtentScrollController(initialItem: currentIndex);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Gender',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.deepPurple)),
              content: SizedBox(
                height: 200,
                child: ListWheelScrollView.useDelegate(
                  controller: scrollController,
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    setStateDialog(() {
                      currentIndex = index;
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      bool isSelected = index == currentIndex;
                      return Center(
                        child: Text(
                          genders[index],
                          style: TextStyle(
                            fontSize: isSelected ? 24 : 16,
                            color:
                                isSelected ? Colors.deepPurple : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                    childCount: genders.length,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    setState(() {
                      gender = genders[currentIndex];
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('OK', style: TextStyle(fontSize: 20)),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {});
  }

  Future<void> _showAgePicker() async {
    int selectedAge = int.tryParse(_ageController.text) ?? 25;
    int currentIndex = selectedAge - 15;
    final scrollController =
        FixedExtentScrollController(initialItem: currentIndex);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Age',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.deepPurple)),
              content: SizedBox(
                height: 200,
                child: ListWheelScrollView.useDelegate(
                  controller: scrollController,
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    setStateDialog(() {
                      currentIndex = index;
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      bool isSelected = index == currentIndex;
                      return Center(
                        child: Text(
                          '${index + 15}',
                          style: TextStyle(
                            fontSize: isSelected ? 24 : 16,
                            color:
                                isSelected ? Colors.deepPurple : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                    childCount: 86,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _ageController.text = (currentIndex + 15).toString();
                    Navigator.pop(context);
                  },
                  child: const Text('OK', style: TextStyle(fontSize: 20)),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {});
  }

  Future<void> _showWeightPicker() async {
    int selectedWeight = int.tryParse(_weightController.text) ?? 70;
    int currentIndex = selectedWeight - 20;
    final scrollController =
        FixedExtentScrollController(initialItem: currentIndex);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Weight (kg)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.deepPurple)),
              content: SizedBox(
                height: 200,
                child: ListWheelScrollView.useDelegate(
                  controller: scrollController,
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    setStateDialog(() {
                      currentIndex = index;
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      bool isSelected = index == currentIndex;
                      return Center(
                        child: Text(
                          '${index + 20}',
                          style: TextStyle(
                            fontSize: isSelected ? 24 : 16,
                            color:
                                isSelected ? Colors.deepPurple : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                    childCount: 131,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _weightController.text = (currentIndex + 20).toString();
                    Navigator.pop(context);
                  },
                  child: const Text('OK', style: TextStyle(fontSize: 20)),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {});
  }

  Future<void> _showHeightPicker() async {
    int selectedHeight = int.tryParse(_heightController.text) ?? 170;
    int currentIndex = selectedHeight - 70;
    final scrollController =
        FixedExtentScrollController(initialItem: currentIndex);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Select Height (cm)',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.deepPurple)),
              content: SizedBox(
                height: 200,
                child: ListWheelScrollView.useDelegate(
                  controller: scrollController,
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    setStateDialog(() {
                      currentIndex = index;
                    });
                  },
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      bool isSelected = index == currentIndex;
                      return Center(
                        child: Text(
                          '${index + 70}',
                          style: TextStyle(
                            fontSize: isSelected ? 24 : 16,
                            color:
                                isSelected ? Colors.deepPurple : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                    childCount: 131,
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _heightController.text = (currentIndex + 70).toString();
                    Navigator.pop(context);
                  },
                  child: const Text('OK', style: TextStyle(fontSize: 20)),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {});
  }
}
