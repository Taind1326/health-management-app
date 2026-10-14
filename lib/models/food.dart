class Food {
  final int id;
  final int userId;
  final String name;

  final double calories;
  final double protein;
  final double carb;
  final double fat;

  const Food({
    required this.id,
    required this.userId,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carb,
    required this.fat,
  });
}