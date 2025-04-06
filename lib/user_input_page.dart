import 'package:flutter/material.dart';
import 'db_controller.dart';

class UserFoodInputPage extends StatefulWidget {
  const UserFoodInputPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UserFoodInputPageState createState() => _UserFoodInputPageState();
}

class _UserFoodInputPageState extends State<UserFoodInputPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _quantityController =
      TextEditingController(text: '1');

  // Predefined list of foods with calories.
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
  double? weight;
  double? height;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    // Fetch user info from the local database.
    final user = await DBHelper.instance.getUser();
    if (user != null) {
      setState(() {
        userName = user['name'];
        weight = user['weight'];
        height = user['height'];
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
      // Add a 'count' field to the food map.
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

  void _submit() {
    if (consumedFoods.isEmpty) return;

    // Calculate total calories from consumed foods.
    int totalCalories =
        consumedFoods.fold(0, (sum, food) => sum + (food['calories'] as int));

    // Use the weight from DB to calculate suggestions.
    // For example, a dummy BMR calculation: BMR = weight * 25.
    double bmr = (weight ?? 70) * 25;
    double caloriesToBurn = bmr - totalCalories;

    // Calculate protein requirement: weight * 1.2 (dummy value)
    double proteinRequired = (weight ?? 70) * 1.2;

    // Create food suggestion based on a simple logic.
    String foodSuggestion =
        'Consider adding lean protein sources and fiber-rich foods.';

    // Build suggestions text.
    String suggestions = '''
      Total Calories Consumed: $totalCalories kcal
      Calories to Burn: ${caloriesToBurn.toStringAsFixed(0)} kcal
      Protein Requirement: ${proteinRequired.toStringAsFixed(0)} g/day
      Food Suggestions: $foodSuggestion
          ''';

    // Show suggestions in a dialog.
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Your Health Suggestions'),
        content: Text(suggestions),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 16),
              if (userName != null)
                Text(
                  "Hello, $userName \nLet's capture today.",
                  style: const TextStyle(fontSize: 20),
                  textAlign: TextAlign.left,
                ),
              const SizedBox(height: 16),
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
              // Display the list of added foods.
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
                onPressed: _submit,
                child: const Text('Submit and Get Suggestions'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
