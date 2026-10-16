import 'package:flutter/material.dart';

import '../../models/meal.dart';
import 'add_meal_screen.dart';
import 'food_list_screen.dart';
import 'nutrition_store.dart';
import 'water_history_screen.dart';
import 'water_screen.dart';

class NutritionScreen extends StatefulWidget {
  const NutritionScreen({super.key});

  @override
  State<NutritionScreen> createState() =>
      _NutritionScreenState();
}

class _NutritionScreenState extends State<NutritionScreen> {
  final NutritionStore store = NutritionStore.instance;

  Future<void> _openScreen(Widget screen) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => screen,
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final todayMeals = store.todayMeals;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dinh dưỡng & Nước'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Dinh dưỡng hôm nay',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text('Tổng hợp các bữa ăn trong ngày'),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    '${formatNutritionValue(store.totalCaloriesToday)} kcal',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Tổng năng lượng hôm nay'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _NutritionCard(
                    title: 'Protein',
                    value:
                        '${formatNutritionValue(store.totalProteinToday)} g',
                    icon: Icons.fitness_center,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NutritionCard(
                    title: 'Carb',
                    value:
                        '${formatNutritionValue(store.totalCarbToday)} g',
                    icon: Icons.grain,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NutritionCard(
                    title: 'Fat',
                    value:
                        '${formatNutritionValue(store.totalFatToday)} g',
                    icon: Icons.opacity,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Các bữa ăn',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            if (todayMeals.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Bạn chưa ghi nhận bữa ăn nào hôm nay.',
                  ),
                ),
              )
            else
              ...todayMeals.map(_buildMealCard),
            const SizedBox(height: 24),
            const Text(
              'Chức năng',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _ActionButton(
              icon: Icons.add_circle_outline,
              title: 'Thêm bữa ăn',
              onTap: () => _openScreen(
                const AddMealScreen(),
              ),
            ),
            _ActionButton(
              icon: Icons.restaurant_menu,
              title: 'Danh sách món ăn',
              onTap: () => _openScreen(
                const FoodListScreen(),
              ),
            ),
            _ActionButton(
              icon: Icons.water_drop,
              title: 'Theo dõi nước',
              onTap: () => _openScreen(
                const WaterScreen(),
              ),
            ),
            _ActionButton(
              icon: Icons.history,
              title: 'Lịch sử nước',
              onTap: () => _openScreen(
                const WaterHistoryScreen(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMealCard(Meal meal) {
    final details = store.detailsForMeal(meal.id);

    final foods = details.map((detail) {
      final food = store.foodById(detail.foodId);

      if (food == null) {
        return 'Không tìm thấy món ăn';
      }

      return '${food.name} × '
          '${formatNutritionValue(detail.quantity)}';
    }).join(', ');

    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.restaurant),
        ),
        title: Text(
          meal.mealType,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(foods),
        trailing: Text(
          '${formatNutritionValue(store.caloriesForMeal(meal))} kcal',
        ),
      ),
    );
  }
}

class _NutritionCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _NutritionCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(value),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon),
          label: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(title),
          ),
        ),
      ),
    );
  }
}