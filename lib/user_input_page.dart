import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db_controller.dart';
import 'gemini_service.dart';
import 'food_data_loader.dart';
import 'meal_history_page.dart';

class UserInputPage extends StatefulWidget {
  const UserInputPage({Key? key}) : super(key: key);

  @override
  State<UserInputPage> createState() => _UserInputPageState();
}

class _UserInputPageState extends State<UserInputPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  Map<String, List<Map<String, dynamic>>> foodData = {};
  List<Map<String, dynamic>> consumedFoods = [];

  // Variables to hold user info from the DB.
  String? userName;
  double? userAge;
  double? weight;
  double? height;
  String? gender;

  final GeminiService _geminiService = GeminiService();
  String _response = "";

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    loadFoodDataFromExcel().then((data) {
      setState(() {
        foodData = data;
      });
      print("Loaded categories: ${foodData.keys}");
    });
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

  Widget _buildCategoryGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: foodData.keys.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 3,
      ),
      itemBuilder: (context, index) {
        String category = foodData.keys.elementAt(index);
        return ElevatedButton(
          onPressed: () => _showFoodPopup(category),
          child: Text(category, style: const TextStyle(fontSize: 16)),
        );
      },
    );
  }

  void _showFoodPopup(String category) {
    showDialog(
      context: context,
      builder: (_) {
        final foods = foodData[category]!;
        return AlertDialog(
          title: Text("Select Food - $category"),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: foods.length,
              itemBuilder: (context, index) {
                final food = foods[index];
                return ListTile(
                  title: Text("${food['name']} (${food['unit']})"),
                  subtitle: Text("Calories: ${food['calories']}"),
                  onTap: () {
                    Navigator.pop(context);
                    _showQuantityDialog(category, food);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _showQuantityDialog(String category, Map<String, dynamic> food) {
    final TextEditingController quantityController =
        TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("How many ${food['unit']} of ${food['name']}?"),
        content: TextField(
          controller: quantityController,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Quantity',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              final count = int.tryParse(quantityController.text) ?? 1;
              Navigator.pop(context);
              _addFoodSelection(category, food, count);
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  void _addFoodSelection(
      String category, Map<String, dynamic> food, int count) {
    final now = DateFormat('yyyy-MM-dd HH:mm:ss').format(DateTime.now());
    final selected = {
      'category': category,
      'name': food['name'],
      'calories': food['calories'],
      'unit': food['unit'],
      'protein': food['protein'],
      'fat': food['fat'],
      'count': count,
      'added_at': now,
    };

    setState(() {
      consumedFoods.add(selected);
    });
  }

  Widget _buildFloatingSummary() {
    int totalCalories = 0;
    double totalProtein = 0;
    double totalFat = 0;

    for (var food in consumedFoods) {
      int count = food['count'] ?? 1;
      totalCalories += (food['calories'] as num).toInt() * count;
      totalProtein += (food['protein'] as num).toDouble() * count;
      totalFat += (food['fat'] as num).toDouble() * count;
    }

    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Card(
        color: Colors.deepPurple.withOpacity(0.9),
        elevation: 6,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Calories: $totalCalories kcal",
                  style: TextStyle(color: Colors.white)),
              Text("Protein: ${totalProtein.toStringAsFixed(1)} g",
                  style: TextStyle(color: Colors.white)),
              Text("Fat: ${totalFat.toStringAsFixed(1)} g",
                  style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Hello ${userName ?? ""}!\nSelect Your Meals",
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w600,
            color: Colors.deepPurple,
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MealHistoryPage()),
              );
            },
          )
        ],
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Select Food Category:"),
                  const SizedBox(height: 10),
                  _buildCategoryGrid(),
                  const SizedBox(height: 16),
                  if (consumedFoods.isNotEmpty) _buildFloatingSummary(),
                  const SizedBox(height: 24),
                  const Text(
                      "Selected Foods Today:"), // space for floating summary
                  ...consumedFoods.map((food) => ListTile(
                        title: Text('${food['name']} (${food['unit']})'),
                        subtitle: Text(
                            'Category: ${food['category']} | Calories: ${food['calories']} | Quantity: ${food['count']}'),
                        trailing: Text('🕒 ${food['added_at']}'),
                      )),
                  const SizedBox(height: 100),
                  // Center(
                  //   child: ElevatedButton(
                  //     onPressed: () {},
                  //     child: const Text('Submit and Get AI Suggestions'),
                  //   ),
                  // ),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: consumedFoods.isEmpty
                              ? null
                              : () {
                                  setState(() {
                                    consumedFoods.clear();
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text("Selection cleared")),
                                  );
                                },
                          icon: const Icon(Icons.clear),
                          label: const Text("Clear Selection"),
                        ),
                        ElevatedButton.icon(
                          onPressed: consumedFoods.isEmpty
                              ? null
                              : () async {
                                  final dbHelper = DBHelper.instance;
                                  for (var food in consumedFoods) {
                                    await dbHelper.insertConsumedFood(food);
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content:
                                            Text("Meals saved successfully!")),
                                  );

                                  setState(() {
                                    consumedFoods.clear();
                                  });
                                },
                          icon: const Icon(Icons.save),
                          label: const Text("Save Meals"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          //if (consumedFoods.isNotEmpty) _buildFloatingSummary(),
        ],
      ),
    );
  }
}
