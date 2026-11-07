class Food {
  final int id;
  final int userId;
  final String name;
  final double calories;
  final double protein;
  final double carb;
  final double fat;
  final double? portionGrams;

  const Food({
    required this.id,
    required this.userId,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carb,
    required this.fat,
    this.portionGrams,
  });

  factory Food.fromMap(Map<String, dynamic> map) {
    return Food(
      id: (map['id'] as num).toInt(),
      userId: (map['user_id'] as num).toInt(),
      name: map['name'] as String,
      calories: (map['calories'] as num).toDouble(),
      protein: (map['protein'] as num).toDouble(),
      carb: (map['carb'] as num).toDouble(),
      fat: (map['fat'] as num).toDouble(),
      portionGrams:
          (map['portion_grams'] as num?)?.toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carb': carb,
      'fat': fat,
      'portion_grams': portionGrams,
    };
  }
}