class Meal {
  final int id;
  final int userId;
  final String mealType;
  final DateTime mealDate;

  const Meal({
    required this.id,
    required this.userId,
    required this.mealType,
    required this.mealDate,
  });

  factory Meal.fromMap(Map<String, dynamic> map) {
    return Meal(
      id: (map['id'] as num).toInt(),
      userId: (map['user_id'] as num).toInt(),
      mealType: map['meal_type'] as String,
      mealDate: DateTime.parse(
        map['meal_date'] as String,
      ),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'meal_type': mealType,
      'meal_date': mealDate.toIso8601String(),
    };
  }
}