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
        gender = user['gender']; // Add this line
      });
    }
  }

  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      final user = {
        'name': _nameController.text,
        'gender': gender,
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

  Future<void> _showGenderPicker() async {
    // Define the gender options.
    final List<String> genders = [
      "Male",
      "Female",
      "Other",
      "Prefer not to say"
    ];
    // Determine the default index based on current gender, defaulting to 0.
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
              title: const Text(
                'Select Gender',
                textAlign: TextAlign.center,
                style: TextStyle(color: primaryPurple),
              ),
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
                            color: isSelected ? primaryPurple : Colors.black,
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
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 20),
                  ),
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
    int selectedAge = int.tryParse(_ageController.text) ?? 25; // default age
    int currentIndex = selectedAge - 15; // Range: 15 to 100
    final scrollController =
        FixedExtentScrollController(initialItem: currentIndex);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                'Select Age',
                textAlign: TextAlign.center,
                style: TextStyle(color: primaryPurple),
              ),
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
                            color: isSelected ? primaryPurple : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                    childCount: 86, // Ages 15 to 100
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _ageController.text = (currentIndex + 15).toString();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    // After dialog is closed, call parent's setState to rebuild the widget
    setState(() {});
  }

  Future<void> _showWeightPicker() async {
    int selectedWeight =
        int.tryParse(_weightController.text) ?? 70; // default weight
    int currentIndex = selectedWeight - 20; // Range: 20 to 150
    final scrollController =
        FixedExtentScrollController(initialItem: currentIndex);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                'Select Weight (kg)',
                textAlign: TextAlign.center,
                style: TextStyle(color: primaryPurple),
              ),
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
                            color: isSelected ? primaryPurple : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                    childCount: 131, // Weights 20 to 150
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _weightController.text = (currentIndex + 20).toString();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 20),
                  ),
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
    int selectedHeight =
        int.tryParse(_heightController.text) ?? 170; // default height
    int currentIndex = selectedHeight - 70; // Range: 70 to 200
    final scrollController =
        FixedExtentScrollController(initialItem: currentIndex);

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text(
                'Select Height (cm)',
                textAlign: TextAlign.center,
                style: TextStyle(color: primaryPurple),
              ),
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
                            color: isSelected ? primaryPurple : Colors.black,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                      );
                    },
                    childCount: 131, // Heights 70 to 200
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _heightController.text = (currentIndex + 70).toString();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'OK',
                    style: TextStyle(fontSize: 20),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
    setState(() {});
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
              ListTile(
                title: const Text('Gender'),
                subtitle: Text(gender == null ? 'Not set' : gender!),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showGenderPicker,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Age'),
                subtitle: Text(_ageController.text.isEmpty
                    ? 'Not set'
                    : _ageController.text),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showAgePicker,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Weight (kg)'),
                subtitle: Text(_weightController.text.isEmpty
                    ? 'Not set'
                    : _weightController.text),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showWeightPicker,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                title: const Text('Height (cm)'),
                subtitle: Text(_heightController.text.isEmpty
                    ? 'Not set'
                    : _heightController.text),
                trailing: IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: _showHeightPicker,
                ),
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
