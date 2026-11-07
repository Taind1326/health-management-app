class MealDetail {
  final int id;
  final int userId;
  final int mealId;
  final int foodId;
  final double quantity;

  const MealDetail({
    required this.id,
    required this.userId,
    required this.mealId,
    required this.foodId,
    required this.quantity,
  });

  factory MealDetail.fromMap(
    Map<String, dynamic> map, {
    required int userId,
  }) {
    return MealDetail(
      id: (map['id'] as num).toInt(),
      userId: userId,
      mealId: (map['meal_id'] as num).toInt(),
      foodId: (map['food_id'] as num).toInt(),
      quantity: (map['quantity'] as num).toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'meal_id': mealId,
      'food_id': foodId,
      'quantity': quantity,
    };
  }
}