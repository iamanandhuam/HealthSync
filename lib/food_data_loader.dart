import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:excel/excel.dart';

/// Loads food data from assets/food_data.xlsx and returns a map:
/// {
///   "Fruits": [ { "name": "Banana", "calories": 90 }, ... ],
///   "Dairy":  [ { "name": "Milk", "calories": 110 }, ... ]
/// }
Future<Map<String, List<Map<String, dynamic>>>> loadFoodDataFromExcel() async {
  final ByteData data = await rootBundle.load('assets/food_data.xlsx');
  final List<int> bytes = data.buffer.asUint8List();
  final Excel excel = Excel.decodeBytes(bytes);

  final Map<String, List<Map<String, dynamic>>> foodByCategory = {};

  final Sheet sheet = excel.tables.values.first;

  // Skip header
  for (var row in sheet.rows.skip(1)) {
    final category = row[0]?.value?.toString().trim();
    final foodName = row[1]?.value?.toString().trim();
    final unit = row[2]?.value?.toString().trim();
    final calories = double.tryParse(row[3]?.value?.toString() ?? '');

    if (category != null &&
        foodName != null &&
        unit != null &&
        calories != null) {
      foodByCategory.putIfAbsent(category, () => []);
      foodByCategory[category]!.add({
        'name': foodName,
        'unit': unit,
        'calories': calories,
        // Optionally add more fields here:
        'protein': double.tryParse(row[4]?.value?.toString() ?? '0'),
        'fat': double.tryParse(row[5]?.value?.toString() ?? '0'),
        'carbs': double.tryParse(row[6]?.value?.toString() ?? '0'),
        'fiber': double.tryParse(row[7]?.value?.toString() ?? '0'),
      });
    }
  }

  return foodByCategory;
}
