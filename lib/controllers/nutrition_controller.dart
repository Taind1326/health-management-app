import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/food.dart';
import '../models/meal.dart';
import '../models/meal_detail.dart';
import '../utils/database_helper.dart';

class NutritionController extends ChangeNotifier {
  NutritionController._();

  static final NutritionController instance = NutritionController._();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  int? _userId;
  bool _isLoading = false;
  String? _error;

  List<Food> _foods = [];
  List<Meal> _todayMeals = [];
  List<MealDetail> _mealDetails = [];

  String _selectedDietMode = 'Ăn uống cân bằng';

  int? get currentUserId => _userId;

  bool get isLoading => _isLoading;

  String? get error => _error;

  List<Food> get foods => List.unmodifiable(_foods);

  List<Meal> get todayMeals => List.unmodifiable(_todayMeals);

  List<MealDetail> get mealDetails => List.unmodifiable(_mealDetails);

  String get selectedDietMode => _selectedDietMode;

  void _validateUserId(int userId) {
    if (userId <= 0) {
      throw ArgumentError('User ID không hợp lệ.');
    }
  }

  int get _requiredUserId {
    final id = _userId;

    if (id == null) {
      throw StateError('NutritionController chưa được khởi tạo.');
    }

    return id;
  }

  // ============================================================
  // CHUYỂN ĐỔI LOẠI BỮA ĂN
  // ============================================================

  String _mealTypeToDatabase(String mealType) {
    switch (mealType.trim()) {
      case 'Bữa sáng':
      case 'breakfast':
        return 'breakfast';

      case 'Bữa trưa':
      case 'lunch':
        return 'lunch';

      case 'Bữa tối':
      case 'dinner':
        return 'dinner';

      case 'Bữa phụ':
      case 'snack':
        return 'snack';

      default:
        throw ArgumentError('Loại bữa ăn không hợp lệ.');
    }
  }

  String _mealTypeFromDatabase(String mealType) {
    switch (mealType) {
      case 'breakfast':
        return 'Bữa sáng';

      case 'lunch':
        return 'Bữa trưa';

      case 'dinner':
        return 'Bữa tối';

      case 'snack':
        return 'Bữa phụ';

      default:
        return mealType;
    }
  }

  // ============================================================
  // CHUYỂN ĐỔI CHẾ ĐỘ DINH DƯỠNG
  // ============================================================

  String _dietModeToDatabase(String mode) {
    switch (mode.trim()) {
      case 'Ăn uống cân bằng':
      case 'balanced':
        return 'balanced';

      case 'Giảm cân':
      case 'weight_loss':
        return 'weight_loss';

      case 'Tăng cơ':
      case 'muscle_gain':
        return 'muscle_gain';

      case 'Ăn chay':
      case 'vegetarian':
        return 'vegetarian';

      default:
        throw ArgumentError('Chế độ dinh dưỡng không hợp lệ.');
    }
  }

  String _dietModeFromDatabase(String mode) {
    switch (mode) {
      case 'balanced':
        return 'Ăn uống cân bằng';

      case 'weight_loss':
        return 'Giảm cân';

      case 'muscle_gain':
        return 'Tăng cơ';

      case 'vegetarian':
        return 'Ăn chay';

      default:
        return 'Ăn uống cân bằng';
    }
  }

  Meal _mealFromMap(Map<String, dynamic> map) {
    final meal = Meal.fromMap(map);

    return Meal(
      id: meal.id,
      userId: meal.userId,
      mealType: _mealTypeFromDatabase(meal.mealType),
      mealDate: meal.mealDate,
    );
  }

  // ============================================================
  // KIỂM TRA DỮ LIỆU MÓN ĂN
  // ============================================================

  void _validateFood(Food food) {
    if (food.name.trim().isEmpty) {
      throw ArgumentError('Tên món ăn không được để trống.');
    }

    final values = [food.calories, food.protein, food.carb, food.fat];

    if (values.any((value) => !value.isFinite || value < 0)) {
      throw ArgumentError('Thông tin dinh dưỡng không hợp lệ.');
    }

    if (food.portionGrams != null &&
        (!food.portionGrams!.isFinite || food.portionGrams! <= 0)) {
      throw ArgumentError('Khối lượng khẩu phần không hợp lệ.');
    }
  }

  // ============================================================
  // DỮ LIỆU MÓN ĂN MẶC ĐỊNH
  // ============================================================

  Future<void> _ensureDefaultFoods(
    DatabaseExecutor executor,
    int userId,
  ) async {
    // Giá trị tham khảo ước tính trên mỗi khẩu phần.
    // Chỉ thêm món còn thiếu, không ghi đè món người dùng đã nhập.
    final defaultFoods = <Map<String, Object?>>[
      {
        'name': 'Bánh mì trứng',
        'calories': 350.0,
        'protein': 20.0,
        'carb': 40.0,
        'fat': 12.0,
        'portion_grams': 150.0,
      },
      {
        'name': 'Bún thịt nướng',
        'calories': 550.0,
        'protein': 25.0,
        'carb': 70.0,
        'fat': 18.0,
        'portion_grams': 350.0,
      },
      {
        'name': 'Chuối',
        'calories': 105.0,
        'protein': 1.3,
        'carb': 27.0,
        'fat': 0.4,
        'portion_grams': 118.0,
      },
      {
        'name': 'Cơm cá',
        'calories': 400.0,
        'protein': 25.0,
        'carb': 50.0,
        'fat': 10.0,
        'portion_grams': 350.0,
      },
      {
        'name': 'Cơm gà',
        'calories': 600.0,
        'protein': 30.0,
        'carb': 65.0,
        'fat': 18.0,
        'portion_grams': 400.0,
      },
      {
        'name': 'Cơm trắng',
        'calories': 260.0,
        'protein': 5.0,
        'carb': 57.0,
        'fat': 0.6,
        'portion_grams': 200.0,
      },
      {
        'name': 'Khoai lang luộc',
        'calories': 130.0,
        'protein': 2.4,
        'carb': 30.0,
        'fat': 0.2,
        'portion_grams': 150.0,
      },
      {
        'name': 'Phở bò',
        'calories': 450.0,
        'protein': 30.0,
        'carb': 55.0,
        'fat': 12.0,
        'portion_grams': 400.0,
      },
      {
        'name': 'Salad rau củ',
        'calories': 180.0,
        'protein': 8.0,
        'carb': 20.0,
        'fat': 7.0,
        'portion_grams': 200.0,
      },
      {
        'name': 'Sữa chua',
        'calories': 100.0,
        'protein': 5.0,
        'carb': 12.0,
        'fat': 3.0,
        'portion_grams': 100.0,
      },
      {
        'name': 'Trứng gà luộc',
        'calories': 78.0,
        'protein': 6.3,
        'carb': 0.6,
        'fat': 5.3,
        'portion_grams': 50.0,
      },
      {
        'name': 'Ức gà luộc',
        'calories': 165.0,
        'protein': 31.0,
        'carb': 0.0,
        'fat': 3.6,
        'portion_grams': 100.0,
      },
    ];

    for (final food in defaultFoods) {
      final existing = await executor.query(
        'foods',
        columns: ['id'],
        where: 'user_id = ? AND name = ? COLLATE NOCASE',
        whereArgs: [userId, food['name']],
        limit: 1,
      );

      if (existing.isEmpty) {
        await executor.insert('foods', {'user_id': userId, ...food});
      }
    }
  }

  // ============================================================
  // KHỞI TẠO VÀ TẢI DỮ LIỆU
  // ============================================================

  Future<void> initialize(int userId) async {
    _validateUserId(userId);

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = await _databaseHelper.database;

      final userRows = await db.query(
        'users',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (userRows.isEmpty) {
        throw StateError(
          'Tài khoản chưa được đồng bộ với SQLite. '
          'Cần tích hợp phần đăng nhập trước khi lưu dữ liệu.',
        );
      }

      await db.transaction((txn) async {
        await DatabaseHelper.ensureUserSettings(txn, userId);

        await _ensureDefaultFoods(txn, userId);
      });

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = start.add(const Duration(days: 1));

      final foodRows = await db.query(
        'foods',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'name COLLATE NOCASE ASC',
      );

      final mealRows = await db.query(
        'meals',
        where: 'user_id = ? AND meal_date >= ? AND meal_date < ?',
        whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
        orderBy: 'meal_date ASC',
      );

      final detailRows = await db.rawQuery(
        '''
        SELECT d.*
        FROM meal_details d
        INNER JOIN meals m ON m.id = d.meal_id
        WHERE m.user_id = ?
          AND m.meal_date >= ?
          AND m.meal_date < ?
        ORDER BY d.id ASC
        ''',
        [userId, start.toIso8601String(), end.toIso8601String()],
      );

      final settingRows = await db.query(
        'user_settings',
        columns: ['diet_mode'],
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      _userId = userId;

      _foods = foodRows.map((row) => Food.fromMap(row)).toList();

      _todayMeals = mealRows.map((row) => _mealFromMap(row)).toList();

      _mealDetails = detailRows
          .map((row) => MealDetail.fromMap(row, userId: userId))
          .toList();

      _selectedDietMode = settingRows.isEmpty
          ? 'Ăn uống cân bằng'
          : _dietModeFromDatabase(settingRows.first['diet_mode'] as String);
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ============================================================
  // TRUY XUẤT DỮ LIỆU
  // ============================================================

  Food? foodById(int id) {
    for (final food in _foods) {
      if (food.id == id) return food;
    }

    return null;
  }

  List<MealDetail> detailsForMeal(int mealId) {
    return _mealDetails.where((detail) => detail.mealId == mealId).toList();
  }

  // ============================================================
  // MỤC TIÊU DINH DƯỠNG
  // ============================================================

  List<Map<String, double>> get _targets {
    switch (_selectedDietMode) {
      case 'Giảm cân':
        return [
          {'Calo': 1800, 'Protein': 100, 'Carb': 200, 'Chất béo': 60},
        ];

      case 'Tăng cơ':
        return [
          {'Calo': 2500, 'Protein': 130, 'Carb': 300, 'Chất béo': 80},
        ];

      case 'Ăn chay':
        return [
          {'Calo': 2000, 'Protein': 75, 'Carb': 275, 'Chất béo': 65},
        ];

      default:
        return [
          {'Calo': 2000, 'Protein': 75, 'Carb': 275, 'Chất béo': 65},
        ];
    }
  }

  Map<String, double> get dailyNutritionTargets => _targets.first;

  // ============================================================
  // TÍNH TOÁN DINH DƯỠNG
  // ============================================================

  double _nutrientForMeal(Meal meal, double Function(Food food) selector) {
    double total = 0;

    for (final detail in detailsForMeal(meal.id)) {
      final food = foodById(detail.foodId);

      if (food != null) {
        total += selector(food) * detail.quantity;
      }
    }

    return total;
  }

  double caloriesForMeal(Meal meal) {
    return _nutrientForMeal(meal, (food) => food.calories);
  }

  double _totalToday(double Function(Food food) selector) {
    double total = 0;

    for (final meal in _todayMeals) {
      total += _nutrientForMeal(meal, selector);
    }

    return total;
  }

  double get totalCaloriesToday => _totalToday((food) => food.calories);

  double get totalProteinToday => _totalToday((food) => food.protein);

  double get totalCarbToday => _totalToday((food) => food.carb);

  double get totalFatToday => _totalToday((food) => food.fat);

  Map<String, double> get todayNutritionValues {
    return {
      'Calo': totalCaloriesToday,
      'Protein': totalProteinToday,
      'Carb': totalCarbToday,
      'Chất béo': totalFatToday,
    };
  }

  Map<String, double> get exceededNutritionToday {
    final targets = dailyNutritionTargets;
    final actual = todayNutritionValues;

    return {
      for (final entry in actual.entries)
        if (entry.value > targets[entry.key]!) entry.key: entry.value,
    };
  }

  // ============================================================
  // THÊM MÓN ĂN THỦ CÔNG
  // ============================================================

  Future<Food> addFood({
    required String name,
    required double calories,
    required double protein,
    required double carb,
    required double fat,
    double? portionGrams,
  }) async {
    final userId = _requiredUserId;

    final food = Food(
      id: 0,
      userId: userId,
      name: name.trim(),
      calories: calories,
      protein: protein,
      carb: carb,
      fat: fat,
      portionGrams: portionGrams,
    );

    _validateFood(food);

    final db = await _databaseHelper.database;

    final existing = await db.query(
      'foods',
      columns: ['id'],
      where: 'user_id = ? AND name = ? COLLATE NOCASE',
      whereArgs: [userId, food.name],
      limit: 1,
    );

    if (existing.isNotEmpty) {
      throw StateError('Món ăn này đã có trong danh sách.');
    }

    final foodId = await db.insert('foods', {
  'user_id': userId,
  'name': food.name,
  'calories': food.calories,
  'protein': food.protein,
  'carb': food.carb,
  'fat': food.fat,
  'portion_grams': food.portionGrams,
});

    await initialize(userId);

    final savedFood = foodById(foodId);

    if (savedFood == null) {
      throw StateError('Đã lưu món ăn nhưng không tải lại được dữ liệu.');
    }

    return savedFood;
  }

  // ============================================================
  // THÊM BỮA ĂN
  // ============================================================

  Future<Meal> addMeal({
    required String mealType,
    required int foodId,
    required double quantity,
    DateTime? mealDate,
  }) async {
    final userId = _requiredUserId;

    if (!quantity.isFinite || quantity <= 0) {
      throw ArgumentError('Số khẩu phần phải lớn hơn 0.');
    }

    final databaseMealType = _mealTypeToDatabase(mealType);
    final date = mealDate ?? DateTime.now();

    final db = await _databaseHelper.database;

    final meal = await db.transaction((txn) async {
      final foodRows = await txn.query(
        'foods',
        columns: ['id'],
        where: 'id = ? AND user_id = ?',
        whereArgs: [foodId, userId],
        limit: 1,
      );

      if (foodRows.isEmpty) {
        throw StateError('Không tìm thấy món ăn thuộc tài khoản này.');
      }

      final mealId = await txn.insert('meals', {
        'user_id': userId,
        'meal_type': databaseMealType,
        'meal_date': date.toIso8601String(),
      });

      await txn.insert('meal_details', {
        'meal_id': mealId,
        'food_id': foodId,
        'quantity': quantity,
      });

      return Meal(
        id: mealId,
        userId: userId,
        mealType: mealType,
        mealDate: date,
      );
    });

    await initialize(userId);

    return meal;
  }

  // ============================================================
  // LƯU MÓN ĂN ĐƯỢC NHẬN DIỆN BẰNG AI
  // ============================================================

  Future<Meal> addRecognizedMeal({
    required String mealType,
    required List<Food> recognizedFoods,
    DateTime? mealDate,
  }) async {
    final userId = _requiredUserId;

    if (recognizedFoods.isEmpty) {
      throw ArgumentError('Không có món ăn để lưu.');
    }

    for (final food in recognizedFoods) {
      _validateFood(food);
    }

    final databaseMealType = _mealTypeToDatabase(mealType);
    final date = mealDate ?? DateTime.now();

    final db = await _databaseHelper.database;

    final mealId = await db.transaction((txn) async {
      final id = await txn.insert('meals', {
        'user_id': userId,
        'meal_type': databaseMealType,
        'meal_date': date.toIso8601String(),
      });

      for (final item in recognizedFoods) {
        final foodId = await txn.insert(
          'foods',
          Food(
            id: 0,
            userId: userId,
            name: item.name.trim(),
            calories: item.calories,
            protein: item.protein,
            carb: item.carb,
            fat: item.fat,
            portionGrams: item.portionGrams,
          ).toMap(),
        );

        await txn.insert('meal_details', {
          'meal_id': id,
          'food_id': foodId,
          'quantity': 1.0,
        });
      }

      return id;
    });

    await initialize(userId);

    return Meal(id: mealId, userId: userId, mealType: mealType, mealDate: date);
  }

  // ============================================================
  // CẬP NHẬT CHẾ ĐỘ DINH DƯỠNG
  // ============================================================

  Future<void> updateDietMode(String mode) async {
    final userId = _requiredUserId;
    final databaseMode = _dietModeToDatabase(mode);

    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      await DatabaseHelper.ensureUserSettings(txn, userId);

      await txn.update(
        'user_settings',
        {'diet_mode': databaseMode},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    });

    _selectedDietMode = _dietModeFromDatabase(databaseMode);
    notifyListeners();
  }
}

String formatNutritionValue(double value) {
  if (value == value.roundToDouble()) {
    return value.toInt().toString();
  }

  return value.toStringAsFixed(1);
}
