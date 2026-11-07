import 'package:flutter/material.dart';

import '../../controllers/nutrition_controller.dart';
import '../../models/food.dart';
import 'add_food_screen.dart';
import 'food_detail_screen.dart';

class FoodListScreen extends StatelessWidget {
  const FoodListScreen({super.key});

  Future<void> _openAddFood(BuildContext context) async {
    await Navigator.push<Food>(
      context,
      MaterialPageRoute<Food>(builder: (context) => const AddFoodScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = NutritionController.instance;

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách món ăn')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddFood(context),
        icon: const Icon(Icons.add),
        label: const Text('Thêm món ăn'),
      ),
      body: AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          if (controller.isLoading && controller.foods.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          final foods = controller.foods;

          if (foods.isEmpty) {
            return const Center(child: Text('Chưa có món ăn trong danh sách.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
            itemCount: foods.length,
            separatorBuilder: (context, index) {
              return const SizedBox(height: 10);
            },
            itemBuilder: (context, index) {
              final Food food = foods[index];

              return Card(
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.restaurant)),
                  title: Text(
                    food.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '${formatNutritionValue(food.calories)} kcal / khẩu phần',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push<void>(
                      context,
                      MaterialPageRoute<void>(
                        builder: (context) {
                          return FoodDetailScreen(food: food);
                        },
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
