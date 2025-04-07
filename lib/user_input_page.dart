import 'package:flutter/material.dart';
import 'db_controller.dart';
import 'gemini_service.dart';

class UserInputPage extends StatefulWidget {
  const UserInputPage({Key? key}) : super(key: key);

  @override
  State<UserInputPage> createState() => _UserInputPageState();
}

class _UserInputPageState extends State<UserInputPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController =
      TextEditingController(text: '1');
  final List<Map<String, dynamic>> predefinedFoods = [
    {'name': 'Oatmeal', 'calories': 150},
    {'name': 'Eggs', 'calories': 200},
    {'name': 'Toast', 'calories': 100},
    {'name': 'Banana', 'calories': 90},
    {'name': 'Yogurt', 'calories': 120},
  ];

  String? selectedFood;
  List<Map<String, dynamic>> consumedFoods = [];

  // Variables to hold user info from the DB.
  String? userName;
  double? userAge;
  double? weight;
  double? height;
  String? gender;

  final GeminiService _geminiService = GeminiService();
  //UserInfoPage? _userInfo;
  String _response = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final dbHelper = DBHelper.instance;
    final user = await dbHelper.getUser();
    if (user != null) {
      setState(() {
        userName = user['name'];
        userAge = user['age'];
        weight = user['weight'];
        height = user['height'];
        gender = user['gender'];
      });
    }
  }

  void _addFood() {
    if (selectedFood != null && _quantityController.text.isNotEmpty) {
      final food = predefinedFoods.firstWhere(
        (element) => element['name'] == selectedFood,
        orElse: () => {},
      );
      int count = int.tryParse(_quantityController.text) ?? 1;
      final foodEntry = {
        'name': food['name'],
        'calories': food['calories'],
        'count': count,
      };
      setState(() {
        consumedFoods.add(foodEntry);
      });
    }
  }

  Future<void> _submitAndGenerateAI() async {
    if (consumedFoods.isEmpty ||
        userAge == null ||
        weight == null ||
        height == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please complete your profile and add food items.")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    int totalCalories = consumedFoods.fold(
        0,
        (sum, food) =>
            sum + (food['calories'] as int) * (food['count'] as int));
    String foodDetails = consumedFoods
        .map((food) =>
            "${food['count']} x ${food['name']} (${food['calories']} kcal each)")
        .join(', ');

    final prompt =
        '''The user has eaten: $foodDetails (total: $totalCalories calories).
        The user is $userAge years old, weighs $weight kg, and is $height cm tall.Gender: $gender.
        Provide suggestions on:
        - How many more calories to burn
        - Protein efficiency or deficiency
        - Food recommendations
        - Any other health advice
        ''';

    String userInput = prompt.toString();

    String aiResponse = await _geminiService.getResponse(userInput);

    Navigator.of(context).pop();

    setState(() {
      _response = aiResponse;
    });

    if (_response.startsWith("Error")) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("AI response failed: $_response")),
      );
    } else {
      showDialog(
        // ignore: use_build_context_synchronously
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Your Health Suggestions'),
          content: Text(_response),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            )
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('User Input')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Select Food Consumed',
                  border: OutlineInputBorder(),
                ),
                value: selectedFood,
                items: predefinedFoods.map((food) {
                  return DropdownMenuItem<String>(
                    value: food['name'],
                    child: Text('${food['name']} (${food['calories']} kcal)'),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    selectedFood = val;
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please select a food';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Quantity (count)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter quantity';
                  }
                  if (int.tryParse(value) == null) {
                    return 'Enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _addFood,
                child: const Text('Add Food'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: consumedFoods.length,
                  itemBuilder: (context, index) {
                    final food = consumedFoods[index];
                    return ListTile(
                      title: Text('${food['name']} (${food['calories']} kcal)'),
                      subtitle: Text('Quantity: ${food['count']}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () {
                          setState(() {
                            consumedFoods.removeAt(index);
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              ElevatedButton(
                onPressed: _submitAndGenerateAI,
                child: const Text('Submit and Get AI Suggestions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
