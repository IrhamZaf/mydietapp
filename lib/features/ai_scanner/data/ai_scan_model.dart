class FoodItemModel {
  final String foodName;
  final int grams;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;

  FoodItemModel({
    required this.foodName,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory FoodItemModel.fromJson(Map<String, dynamic> json) {
    return FoodItemModel(
      foodName: json['food_name'] as String? ?? 'Food Item',
      grams: (json['grams'] as num?)?.toInt() ?? 100,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
    );
  }
}

class AiScanModel {
  final String foodName;
  final String portionSize;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final String confidence;
  final List<FoodItemModel> items;

  AiScanModel({
    required this.foodName,
    required this.portionSize,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.confidence,
    required this.items,
  });

  factory AiScanModel.fromJson(Map<String, dynamic> json) {
    List<FoodItemModel> itemList = [];

    if (json.containsKey('foods') && json['foods'] is List && (json['foods'] as List).isNotEmpty) {
      itemList = (json['foods'] as List)
          .map((item) => FoodItemModel.fromJson(item as Map<String, dynamic>))
          .toList();

      final totalCalories = itemList.fold<int>(0, (sum, i) => sum + i.calories);
      final totalProtein = itemList.fold<int>(0, (sum, i) => sum + i.protein);
      final totalCarbs = itemList.fold<int>(0, (sum, i) => sum + i.carbs);
      final totalFat = itemList.fold<int>(0, (sum, i) => sum + i.fat);
      final totalGrams = itemList.fold<int>(0, (sum, i) => sum + i.grams);

      final mainName = itemList.length == 1
          ? itemList.first.foodName
          : '${itemList.first.foodName} + ${itemList.length - 1} items';

      return AiScanModel(
        foodName: mainName,
        portionSize: '~${totalGrams}g total',
        calories: totalCalories,
        protein: totalProtein,
        carbs: totalCarbs,
        fat: totalFat,
        confidence: 'high',
        items: itemList,
      );
    }

    return AiScanModel(
      foodName: json['food_name'] as String? ?? 'Scanned Meal',
      portionSize: json['portion_size'] as String? ?? '1 serving',
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      carbs: (json['carbs'] as num?)?.toInt() ?? 0,
      fat: (json['fat'] as num?)?.toInt() ?? 0,
      confidence: json['confidence'] as String? ?? 'high',
      items: [],
    );
  }
}
