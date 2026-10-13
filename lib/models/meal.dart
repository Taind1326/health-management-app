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
}