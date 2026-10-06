import 'package:flutter/material.dart';
import 'add_meal_screen.dart';
import 'food_list_screen.dart';
import 'water_screen.dart';
import 'water_history_screen.dart';

class NutritionScreen extends StatelessWidget {
  const NutritionScreen({super.key});

  @override
  Widget build(BuildContext context) {
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
            const Text(
              'Hôm nay',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                children: [
                  Text(
                    '1.350 kcal',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tổng năng lượng trong ngày - dữ liệu mẫu',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _NutritionCard(
                    title: 'Protein',
                    value: '65 g',
                    icon: Icons.fitness_center,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NutritionCard(
                    title: 'Carb',
                    value: '150 g',
                    icon: Icons.grain,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _NutritionCard(
                    title: 'Fat',
                    value: '45 g',
                    icon: Icons.opacity,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Bữa ăn',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _MealCard(
              title: 'Bữa sáng',
              food: 'Bánh mì trứng',
              calories: '350 kcal',
            ),
            const SizedBox(height: 10),
            _MealCard(
              title: 'Bữa trưa',
              food: 'Cơm gà',
              calories: '600 kcal',
            ),
            const SizedBox(height: 10),
            _MealCard(
              title: 'Bữa tối',
              food: 'Cơm cá',
              calories: '400 kcal',
            ),
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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddMealScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _ActionButton(
              icon: Icons.restaurant_menu,
              title: 'Danh sách món ăn',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FoodListScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _ActionButton(
              icon: Icons.water_drop,
              title: 'Theo dõi nước',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WaterScreen(),
                  ),
                );
              },
            ),
            const SizedBox(height: 10),
            _ActionButton(
              icon: Icons.history,
              title: 'Lịch sử nước',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WaterHistoryScreen(),
                  ),
                );
              },
            ),
          ],
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: Colors.green,
          ),
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

class _MealCard extends StatelessWidget {
  final String title;
  final String food;
  final String calories;

  const _MealCard({
    required this.title,
    required this.food,
    required this.calories,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          child: Icon(Icons.restaurant),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(food),
        trailing: Text(calories),
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
      child: OutlinedButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Text(title),
        ),
      ),
    );
  }
}