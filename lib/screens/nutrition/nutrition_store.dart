import '../../models/food.dart';
import '../../models/meal.dart';
import '../../models/meal_detail.dart';
import '../../models/water_record.dart';

class NutritionStore {
  NutritionStore._internal() {
    resetForTesting();
  }

  static final NutritionStore instance =
      NutritionStore._internal();

  static const int currentUserId = 1;

  final List<Food> foods = [];
  final List<Meal> meals = [];
  final List<MealDetail> mealDetails = [];
  final List<WaterRecord> waterRecords = [];

  int waterGoalMl = 2000;

  int _nextMealId = 1;
  int _nextMealDetailId = 1;
  int _nextWaterRecordId = 1;

  void resetForTesting() {
    foods.clear();
    meals.clear();
    mealDetails.clear();
    waterRecords.clear();

    _nextMealId = 1;
    _nextMealDetailId = 1;
    _nextWaterRecordId = 1;
    waterGoalMl = 2000;

    foods.addAll([
      const Food(
        id: 1,
        userId: currentUserId,
        name: 'Bánh mì trứng',
        calories: 350,
        protein: 20,
        carb: 40,
        fat: 12,
      ),
      const Food(
        id: 2,
        userId: currentUserId,
        name: 'Cơm gà',
        calories: 600,
        protein: 30,
        carb: 65,
        fat: 18,
      ),
      const Food(
        id: 3,
        userId: currentUserId,
        name: 'Cơm cá',
        calories: 400,
        protein: 25,
        carb: 50,
        fat: 10,
      ),
      const Food(
        id: 4,
        userId: currentUserId,
        name: 'Salad',
        calories: 180,
        protein: 8,
        carb: 20,
        fat: 7,
      ),
    ]);

    final now = DateTime.now();

    addMeal(
      mealType: 'Bữa sáng',
      foodId: 1,
      quantity: 1,
      mealDate: _todayAt(7, 30, now),
    );

    addMeal(
      mealType: 'Bữa trưa',
      foodId: 2,
      quantity: 1,
      mealDate: _todayAt(12, 0, now),
    );

    addMeal(
      mealType: 'Bữa tối',
      foodId: 3,
      quantity: 1,
      mealDate: _todayAt(19, 0, now),
    );

    waterRecords.addAll([
      WaterRecord(
        id: _nextWaterRecordId++,
        userId: currentUserId,
        amountMl: 250,
        recordedAt: _todayAt(8, 0, now),
      ),
      WaterRecord(
        id: _nextWaterRecordId++,
        userId: currentUserId,
        amountMl: 250,
        recordedAt: _todayAt(10, 30, now),
      ),
      WaterRecord(
        id: _nextWaterRecordId++,
        userId: currentUserId,
        amountMl: 500,
        recordedAt: _todayAt(13, 0, now),
      ),
    ]);
  }

  DateTime _todayAt(
    int hour,
    int minute,
    DateTime now,
  ) {
    return DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  Food? foodById(int id) {
    for (final food in foods) {
      if (food.id == id) {
        return food;
      }
    }

    return null;
  }

  List<Meal> get todayMeals {
    final now = DateTime.now();

    final result = meals
        .where((meal) => _isSameDay(meal.mealDate, now))
        .toList();

    result.sort(
      (a, b) => a.mealDate.compareTo(b.mealDate),
    );

    return result;
  }

  List<MealDetail> detailsForMeal(int mealId) {
    return mealDetails
        .where((detail) => detail.mealId == mealId)
        .toList();
  }

  double caloriesForMeal(Meal meal) {
    return _nutrientForMeal(
      meal,
      (food) => food.calories,
    );
  }

  double _nutrientForMeal(
    Meal meal,
    double Function(Food food) selector,
  ) {
    double total = 0;

    for (final detail in detailsForMeal(meal.id)) {
      final food = foodById(detail.foodId);

      if (food != null) {
        total += selector(food) * detail.quantity;
      }
    }

    return total;
  }

  double get totalCaloriesToday {
    return _totalToday((food) => food.calories);
  }

  double get totalProteinToday {
    return _totalToday((food) => food.protein);
  }

  double get totalCarbToday {
    return _totalToday((food) => food.carb);
  }

  double get totalFatToday {
    return _totalToday((food) => food.fat);
  }

  double _totalToday(
    double Function(Food food) selector,
  ) {
    double total = 0;

    for (final meal in todayMeals) {
      total += _nutrientForMeal(meal, selector);
    }

    return total;
  }

  Meal addMeal({
    required String mealType,
    required int foodId,
    required double quantity,
    DateTime? mealDate,
  }) {
    if (quantity <= 0 || !quantity.isFinite) {
      throw ArgumentError(
        'Số khẩu phần phải lớn hơn 0.',
      );
    }

    if (foodById(foodId) == null) {
      throw ArgumentError('Không tìm thấy món ăn.');
    }

    final meal = Meal(
      id: _nextMealId++,
      userId: currentUserId,
      mealType: mealType,
      mealDate: mealDate ?? DateTime.now(),
    );

    meals.add(meal);

    mealDetails.add(
      MealDetail(
        id: _nextMealDetailId++,
        userId: currentUserId,
        mealId: meal.id,
        foodId: foodId,
        quantity: quantity,
      ),
    );

    return meal;
  }

  int get todayWaterTotalMl {
    final now = DateTime.now();

    return waterRecords
        .where(
          (record) =>
              _isSameDay(record.recordedAt, now),
        )
        .fold<int>(
          0,
          (total, record) => total + record.amountMl,
        );
  }

  List<WaterRecord> get waterHistory {
    final result = List<WaterRecord>.from(waterRecords);

    result.sort(
      (a, b) => b.recordedAt.compareTo(a.recordedAt),
    );

    return result;
  }

  void addWater(int amountMl) {
    if (amountMl <= 0) {
      throw ArgumentError(
        'Lượng nước phải lớn hơn 0.',
      );
    }

    waterRecords.add(
      WaterRecord(
        id: _nextWaterRecordId++,
        userId: currentUserId,
        amountMl: amountMl,
        recordedAt: DateTime.now(),
      ),
    );
  }

  void updateWaterGoal(int goalMl) {
    if (goalMl <= 0) {
      throw ArgumentError(
        'Mục tiêu nước phải lớn hơn 0.',
      );
    }

    waterGoalMl = goalMl;
  }
}

String formatNutritionValue(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(1);
}