import 'package:flutter/material.dart';

import '../../models/food.dart';
import 'nutrition_store.dart';

class DietPlanScreen extends StatefulWidget {
  const DietPlanScreen({super.key});

  @override
  State<DietPlanScreen> createState() =>
      _DietPlanScreenState();
}

class _DietPlanScreenState extends State<DietPlanScreen> {
  final NutritionStore store = NutritionStore.instance;

  String _period = 'Ngày';

  final List<String> _modes = [
    'Giảm cân',
    'Tăng cơ',
    'Ăn uống cân bằng',
    'Ăn chay',
  ];

  final List<String> _periods = [
    'Ngày',
    'Tuần',
    'Tháng',
  ];

  _MenuCatalog get _catalog {
    switch (store.selectedDietMode) {
      case 'Giảm cân':
        return const _MenuCatalog(
          breakfast: [
            _FoodOption('Yến mạch, sữa chua và chuối', 300, 320, 16, 48, 7),
            _FoodOption('Bánh mì nguyên cám và trứng', 250, 350, 18, 40, 12),
            _FoodOption('Sữa chua và trái cây', 250, 280, 20, 35, 5),
            _FoodOption('Khoai lang và trứng luộc', 280, 330, 18, 38, 9),
            _FoodOption('Sinh tố sữa và yến mạch', 300, 340, 15, 52, 8),
            _FoodOption('Bánh cuốn nhân thịt nạc', 300, 360, 18, 48, 9),
            _FoodOption('Phở gà tô nhỏ', 350, 380, 25, 48, 8),
            _FoodOption('Cháo thịt nạc', 300, 310, 18, 45, 6),
          ],
          lunch: [
            _FoodOption('Cơm, ức gà và rau luộc', 450, 500, 40, 55, 12),
            _FoodOption('Cơm cá hấp và rau xanh', 450, 480, 35, 55, 10),
            _FoodOption('Cơm thịt nạc và canh rau', 450, 520, 35, 60, 15),
            _FoodOption('Bún gà và rau sống', 400, 460, 32, 60, 9),
            _FoodOption('Cơm tôm và rau củ', 420, 470, 32, 58, 8),
            _FoodOption('Cơm đậu phụ và rau củ', 450, 450, 22, 62, 12),
            _FoodOption('Phở gà và rau thơm', 400, 460, 30, 58, 9),
            _FoodOption('Bún thịt nạc và rau', 420, 500, 32, 62, 12),
          ],
          dinner: [
            _FoodOption('Cá hấp, khoai lang và rau', 420, 450, 32, 48, 12),
            _FoodOption('Ức gà áp chảo và salad', 400, 430, 40, 30, 14),
            _FoodOption('Canh chua cá và cơm', 430, 460, 30, 58, 10),
            _FoodOption('Đậu phụ sốt cà và cơm', 420, 430, 22, 60, 11),
            _FoodOption('Tôm hấp và khoai lang', 380, 390, 30, 45, 7),
            _FoodOption('Thịt nạc và rau củ luộc', 400, 440, 35, 38, 14),
            _FoodOption('Bún cá và rau xanh', 420, 450, 30, 58, 9),
            _FoodOption('Trứng, khoai tây và salad', 400, 420, 22, 45, 14),
          ],
          snack: [
            _FoodOption('Sữa chua không đường', 150, 100, 8, 12, 2),
            _FoodOption('Táo và hạnh nhân', 150, 180, 4, 25, 8),
            _FoodOption('Sữa ít béo', 200, 100, 7, 10, 3),
            _FoodOption('Ổi tươi', 200, 130, 4, 28, 1),
            _FoodOption('Trứng luộc', 100, 155, 13, 1, 11),
            _FoodOption('Chuối nhỏ', 100, 90, 1, 23, 0),
            _FoodOption('Đậu nành luộc', 100, 170, 17, 10, 9),
            _FoodOption('Phô mai tươi và dâu', 150, 150, 10, 18, 4),
          ],
        );

      case 'Tăng cơ':
        return const _MenuCatalog(
          breakfast: [
            _FoodOption('Yến mạch, sữa và trứng', 350, 500, 28, 60, 16),
            _FoodOption('Bánh mì nguyên cám và trứng', 350, 480, 25, 58, 15),
            _FoodOption('Cơm và ức gà xé', 400, 520, 35, 65, 10),
            _FoodOption('Khoai lang, trứng và sữa', 400, 480, 25, 60, 14),
            _FoodOption('Phở bò tô vừa', 500, 550, 30, 70, 16),
            _FoodOption('Bún thịt nạc', 450, 520, 30, 70, 12),
            _FoodOption('Sinh tố chuối, sữa và yến mạch', 400, 500, 24, 75, 12),
            _FoodOption('Bánh mì gà và sữa đậu nành', 400, 530, 32, 68, 12),
          ],
          lunch: [
            _FoodOption('Cơm, ức gà và rau củ', 500, 650, 45, 75, 15),
            _FoodOption('Cơm bò nạc và rau', 500, 680, 42, 75, 20),
            _FoodOption('Cơm cá hồi và rau', 500, 670, 38, 70, 23),
            _FoodOption('Bún bò và rau', 500, 650, 35, 80, 18),
            _FoodOption('Cơm thịt nạc và trứng', 500, 700, 42, 78, 20),
            _FoodOption('Mì gà và rau củ', 500, 620, 38, 78, 14),
            _FoodOption('Cơm tôm và trứng', 500, 640, 38, 80, 14),
            _FoodOption('Cơm gà và đậu phụ', 520, 690, 45, 80, 17),
          ],
          dinner: [
            _FoodOption('Thịt bò, cơm và rau xanh', 500, 600, 40, 65, 18),
            _FoodOption('Cá hồi, khoai tây và rau', 500, 620, 38, 60, 23),
            _FoodOption('Cơm gà và trứng', 500, 650, 45, 72, 16),
            _FoodOption('Thịt nạc và mì gạo', 500, 630, 38, 78, 16),
            _FoodOption('Cơm cá và canh rau', 500, 580, 35, 72, 14),
            _FoodOption('Bò xào mì và rau', 500, 650, 40, 75, 20),
            _FoodOption('Cơm tôm và rau củ', 500, 590, 38, 75, 12),
            _FoodOption('Ức gà, khoai lang và salad', 500, 580, 45, 60, 14),
          ],
          snack: [
            _FoodOption('Sữa chua và chuối', 250, 300, 18, 40, 5),
            _FoodOption('Sữa và bánh mì nguyên cám', 300, 320, 16, 45, 9),
            _FoodOption('Sinh tố sữa, chuối và yến mạch', 350, 350, 18, 55, 8),
            _FoodOption('Trứng luộc và khoai lang', 250, 280, 16, 38, 8),
            _FoodOption('Đậu nành và trái cây', 250, 300, 18, 35, 10),
            _FoodOption('Bánh mì bơ đậu phộng', 200, 330, 13, 40, 14),
            _FoodOption('Phô mai và bánh mì', 220, 300, 16, 35, 10),
            _FoodOption('Sữa chua yến mạch', 250, 290, 18, 40, 6),
          ],
        );

      case 'Ăn chay':
        return const _MenuCatalog(
          breakfast: [
            _FoodOption('Yến mạch và sữa đậu nành', 300, 380, 20, 55, 10),
            _FoodOption('Bánh mì bơ đậu phộng', 250, 350, 14, 42, 14),
            _FoodOption('Khoai lang và sữa đậu nành', 300, 330, 14, 52, 7),
            _FoodOption('Bún riêu chay', 400, 400, 18, 62, 10),
            _FoodOption('Cháo nấm và đậu phụ', 350, 320, 16, 50, 7),
            _FoodOption('Bánh cuốn nhân nấm chay', 300, 350, 12, 58, 8),
            _FoodOption('Miến nấm và rau củ', 350, 340, 14, 55, 8),
            _FoodOption('Sinh tố chuối, đậu nành và yến mạch', 350, 380, 18, 58, 9),
          ],
          lunch: [
            _FoodOption('Cơm, đậu phụ và rau củ', 450, 550, 25, 75, 14),
            _FoodOption('Bún nấm chay', 450, 500, 20, 78, 12),
            _FoodOption('Cơm gạo lứt và đậu hũ', 450, 530, 25, 72, 15),
            _FoodOption('Miến xào nấm và đậu phụ', 400, 500, 22, 70, 14),
            _FoodOption('Bánh mì chay và sữa đậu nành', 400, 520, 22, 75, 14),
            _FoodOption('Cơm đậu lăng và rau xanh', 450, 560, 26, 82, 12),
            _FoodOption('Bún đậu phụ và rau thơm', 450, 510, 23, 72, 14),
            _FoodOption('Cơm nấm kho và canh rau', 450, 500, 20, 75, 12),
          ],
          dinner: [
            _FoodOption('Cơm, nấm và các loại đậu', 450, 520, 24, 70, 13),
            _FoodOption('Đậu phụ sốt cà và cơm', 450, 500, 23, 68, 13),
            _FoodOption('Bún chay và đậu phụ', 450, 480, 20, 72, 10),
            _FoodOption('Cơm gạo lứt và tempeh', 450, 540, 28, 70, 16),
            _FoodOption('Canh nấm, cơm và đậu hũ', 450, 490, 22, 70, 11),
            _FoodOption('Miến trộn rau củ và đậu', 400, 470, 20, 68, 12),
            _FoodOption('Cơm cà ri rau củ và đậu', 450, 530, 22, 78, 14),
            _FoodOption('Cháo đậu xanh và nấm', 400, 450, 18, 72, 8),
          ],
          snack: [
            _FoodOption('Đậu nành luộc', 100, 170, 17, 10, 9),
            _FoodOption('Chuối và hạnh nhân', 150, 220, 5, 30, 10),
            _FoodOption('Sữa chua đậu nành', 150, 120, 6, 16, 4),
            _FoodOption('Trái cây tươi', 200, 120, 2, 28, 1),
            _FoodOption('Đậu phụ non', 150, 120, 12, 4, 7),
            _FoodOption('Bánh gạo và bơ đậu phộng', 120, 220, 7, 30, 8),
            _FoodOption('Sữa đậu nành', 200, 100, 7, 10, 4),
            _FoodOption('Khoai lang hấp', 150, 135, 2, 32, 0),
          ],
        );

      default:
        return const _MenuCatalog(
          breakfast: [
            _FoodOption('Bánh mì trứng và sữa', 300, 400, 20, 55, 10),
            _FoodOption('Yến mạch, sữa chua và trái cây', 300, 380, 18, 55, 9),
            _FoodOption('Phở gà tô vừa', 400, 450, 28, 60, 10),
            _FoodOption('Bún thịt nạc', 400, 430, 25, 60, 10),
            _FoodOption('Khoai lang và trứng', 300, 350, 18, 45, 10),
            _FoodOption('Bánh cuốn và sữa đậu nành', 350, 420, 18, 62, 10),
            _FoodOption('Cơm gà xé và rau', 350, 450, 30, 60, 9),
            _FoodOption('Cháo thịt và trứng', 350, 390, 22, 55, 9),
          ],
          lunch: [
            _FoodOption('Cơm, cá và rau xanh', 450, 600, 35, 70, 18),
            _FoodOption('Cơm, thịt nạc và canh rau', 450, 580, 35, 68, 16),
            _FoodOption('Bún gà và rau sống', 420, 520, 32, 65, 12),
            _FoodOption('Cơm tôm và rau củ', 450, 550, 32, 72, 12),
            _FoodOption('Cơm bò nạc và rau', 450, 620, 38, 70, 18),
            _FoodOption('Phở bò tô vừa', 450, 580, 32, 72, 14),
            _FoodOption('Cơm gà và rau luộc', 450, 590, 35, 70, 15),
            _FoodOption('Bún cá và rau', 430, 530, 30, 68, 12),
          ],
          dinner: [
            _FoodOption('Thịt nạc, cơm và rau củ', 450, 550, 35, 55, 18),
            _FoodOption('Cá hấp, cơm và rau xanh', 450, 520, 34, 58, 13),
            _FoodOption('Đậu phụ sốt cà và cơm', 450, 500, 23, 68, 13),
            _FoodOption('Gà áp chảo và khoai tây', 450, 540, 38, 52, 16),
            _FoodOption('Canh chua cá và cơm', 450, 510, 30, 65, 12),
            _FoodOption('Bún thịt nạc và rau', 430, 530, 32, 65, 14),
            _FoodOption('Cơm trứng và rau củ', 420, 490, 22, 68, 13),
            _FoodOption('Tôm hấp, cơm và rau', 450, 520, 34, 66, 10),
          ],
          snack: [
            _FoodOption('Sữa chua và trái cây', 200, 200, 10, 28, 5),
            _FoodOption('Táo và hạnh nhân', 150, 180, 4, 25, 8),
            _FoodOption('Sữa ít béo và chuối', 250, 210, 10, 35, 5),
            _FoodOption('Trứng luộc', 100, 155, 13, 1, 11),
            _FoodOption('Đậu nành luộc', 100, 170, 17, 10, 9),
            _FoodOption('Ổi và sữa chua', 250, 180, 10, 30, 3),
            _FoodOption('Khoai lang hấp', 150, 135, 2, 32, 0),
            _FoodOption('Bánh mì nguyên cám', 100, 250, 10, 42, 5),
          ],
        );
    }
  }

  List<_MealSuggestion> _menuForDate(DateTime date) {
    final catalog = _catalog;
    final dayIndex = date.difference(DateTime(2024, 1, 1)).inDays;

    _MealSuggestion convert(
      String type,
      List<_FoodOption> options,
      int offset,
    ) {
      final index = (dayIndex + offset) % options.length;
      final option = options[index];

      return _MealSuggestion(
        type: type,
        name: option.name,
        portion: option.portion,
        calories: option.calories,
        protein: option.protein,
        carbs: option.carbs,
        fat: option.fat,
      );
    }

    return [
      convert('Bữa sáng', catalog.breakfast, 0),
      convert('Bữa trưa', catalog.lunch, 2),
      convert('Bữa tối', catalog.dinner, 4),
      convert('Bữa phụ', catalog.snack, 6),
    ];
  }

  DateTime get _today => DateUtils.dateOnly(DateTime.now());

  List<DateTime> get _weekDates {
    final monday = _today.subtract(
      Duration(days: _today.weekday - 1),
    );

    return List.generate(
      7,
      (index) => monday.add(Duration(days: index)),
    );
  }

  List<DateTime> get _monthDates {
    final first = DateTime(_today.year, _today.month, 1);
    final count = DateTime(
      _today.year,
      _today.month + 1,
      0,
    ).day;

    return List.generate(
      count,
      (index) => first.add(Duration(days: index)),
    );
  }

  String _dateLabel(DateTime date) {
    const weekdays = [
      'Thứ Hai',
      'Thứ Ba',
      'Thứ Tư',
      'Thứ Năm',
      'Thứ Sáu',
      'Thứ Bảy',
      'Chủ Nhật',
    ];

    return '${weekdays[date.weekday - 1]}, '
        '${date.day}/${date.month}/${date.year}';
  }

  String _mealTypeNow() {
    final hour = DateTime.now().hour;

    if (hour < 10) return 'Bữa sáng';
    if (hour < 14) return 'Bữa trưa';
    if (hour < 18) return 'Bữa tối';

    return 'Bữa phụ';
  }

  _MealSuggestion get _nextSuggestion {
    final menu = _menuForDate(_today);
    final type = _mealTypeNow();

    return menu.firstWhere(
      (meal) => meal.type == type,
      orElse: () => menu.last,
    );
  }

  bool _alreadyLoggedToday(_MealSuggestion suggestion) {
    for (final meal in store.todayMeals) {
      if (meal.mealType != suggestion.type) {
        continue;
      }

      for (final detail in store.detailsForMeal(meal.id)) {
        final food = store.foodById(detail.foodId);

        if (food?.name == suggestion.name) {
          return true;
        }
      }
    }

    return false;
  }

  void _saveNextSuggestion() {
    final suggestion = _nextSuggestion;

    if (_alreadyLoggedToday(suggestion)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Món này đã được ghi nhận hôm nay.'),
        ),
      );
      return;
    }

    try {
      store.addRecognizedMeal(
        mealType: suggestion.type,
        recognizedFoods: [
          Food(
            id: 0,
            userId: NutritionStore.currentUserId,
            name: suggestion.name,
            calories: suggestion.calories,
            protein: suggestion.protein,
            carb: suggestion.carbs,
            fat: suggestion.fat,
            portionGrams: suggestion.portion,
          ),
        ],
      );

      setState(() {});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã ghi nhận món ăn vào nhật ký hôm nay.'),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lưu món ăn: $e'),
        ),
      );
    }
  }

  Widget _overLimitWarning() {
    final exceeded = store.exceededNutritionToday;

    if (exceeded.isEmpty) {
      return const SizedBox.shrink();
    }

    final targets = store.dailyNutritionTargets;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade300),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.red.shade700,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Đã vượt mục tiêu dinh dưỡng',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...exceeded.entries.map((entry) {
            final unit = entry.key == 'Calo' ? 'kcal' : 'g';

            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                '${entry.key}: '
                '${formatNutritionValue(entry.value)} / '
                '${formatNutritionValue(targets[entry.key]!)} '
                '$unit',
                style: TextStyle(
                  color: Colors.red.shade800,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _targetCard(
    String label,
    IconData icon,
  ) {
    final target = store.dailyNutritionTargets[label] ?? 0;
    final unit = label == 'Calo' ? 'kcal' : 'g';

    return SizedBox(
      width: 155,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: Colors.green),
              const SizedBox(height: 8),
              Text(label),
              const SizedBox(height: 4),
              Text(
                '${formatNutritionValue(target)} $unit/ngày',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mealCard(_MealSuggestion meal) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              meal.type,
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              meal.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Khẩu phần tham khảo: ${meal.portion} g',
            ),
            const SizedBox(height: 5),
            Text(
              '${formatNutritionValue(meal.calories)} kcal',
            ),
            const SizedBox(height: 4),
            Text(
              'Protein: ${formatNutritionValue(meal.protein)} g  •  '
              'Carb: ${formatNutritionValue(meal.carbs)} g  •  '
              'Fat: ${formatNutritionValue(meal.fat)} g',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDayExpansion(DateTime date) {
    final menu = _menuForDate(date);

    final totalCalories = menu.fold<double>(
      0,
      (total, meal) => total + meal.calories,
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          _dateLabel(date),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          'Thực đơn mẫu • '
          '${formatNutritionValue(totalCalories)} kcal',
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: Column(
              children: menu.map(_mealCard).toList(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final todayMenu = _menuForDate(_today);
    final next = _nextSuggestion;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chế độ dinh dưỡng'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Chọn chế độ ăn',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _modes.map((mode) {
              return ChoiceChip(
                label: Text(mode),
                selected: store.selectedDietMode == mode,
                onSelected: (_) {
                  setState(() {
                    store.updateDietMode(mode);
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          Text(
            'Mục tiêu tham khảo • ${store.selectedDietMode}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _targetCard('Calo', Icons.local_fire_department),
              _targetCard('Protein', Icons.fitness_center),
              _targetCard('Carb', Icons.grain),
              _targetCard('Chất béo', Icons.opacity),
            ],
          ),

          const SizedBox(height: 16),

          _overLimitWarning(),

          const Text(
            'Dinh dưỡng đã ghi nhận hôm nay',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Calo: '
                    '${formatNutritionValue(store.totalCaloriesToday)} kcal',
                  ),
                  Text(
                    'Protein: '
                    '${formatNutritionValue(store.totalProteinToday)} g',
                  ),
                  Text(
                    'Carb: '
                    '${formatNutritionValue(store.totalCarbToday)} g',
                  ),
                  Text(
                    'Chất béo: '
                    '${formatNutritionValue(store.totalFatToday)} g',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          const Text(
            'Gợi ý món tiếp theo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          _mealCard(next),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _alreadyLoggedToday(next)
                  ? null
                  : _saveNextSuggestion,
              icon: const Icon(Icons.add_task),
              label: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                ),
                child: Text(
                  _alreadyLoggedToday(next)
                      ? 'Đã ghi nhận hôm nay'
                      : 'Tôi đã ăn món này hôm nay',
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Xem thực đơn theo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            children: _periods.map((period) {
              return ChoiceChip(
                label: Text(period),
                selected: _period == period,
                onSelected: (_) {
                  setState(() {
                    _period = period;
                  });
                },
              );
            }).toList(),
          ),

          const SizedBox(height: 16),

          if (_period == 'Ngày') ...[
            Text(
              'Thực đơn hôm nay • ${_dateLabel(_today)}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ...todayMenu.map(_mealCard),
          ] else if (_period == 'Tuần') ...[
            const Text(
              'Thực đơn trong tuần',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._weekDates.map(_buildDayExpansion),
          ] else ...[
            Text(
              'Thực đơn tháng ${_today.month}/${_today.year}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            ..._monthDates.map(_buildDayExpansion),
          ],

          const SizedBox(height: 16),

          Text(
            'Thực đơn và mục tiêu dinh dưỡng là số liệu '
            'tham khảo. Món ăn được luân phiên từ danh mục '
            'mẫu; khẩu phần và cách chế biến thực tế có thể '
            'làm thay đổi đáng kể lượng dinh dưỡng. '
            'Các ngưỡng hiện tại chưa được cá nhân hóa '
            'theo hồ sơ sức khỏe.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuCatalog {
  final List<_FoodOption> breakfast;
  final List<_FoodOption> lunch;
  final List<_FoodOption> dinner;
  final List<_FoodOption> snack;

  const _MenuCatalog({
    required this.breakfast,
    required this.lunch,
    required this.dinner,
    required this.snack,
  });
}

class _FoodOption {
  final String name;
  final double portion;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const _FoodOption(
    this.name,
    this.portion,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
  );
}

class _MealSuggestion {
  final String type;
  final String name;
  final double portion;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const _MealSuggestion({
    required this.type,
    required this.name,
    required this.portion,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });
}