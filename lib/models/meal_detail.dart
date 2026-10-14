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
}