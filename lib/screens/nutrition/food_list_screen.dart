import 'package:flutter/material.dart';

import '../../models/food.dart';
import 'food_detail_screen.dart';
import 'nutrition_store.dart';

class FoodListScreen extends StatelessWidget {
  const FoodListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = NutritionStore.instance;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách món ăn'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: store.foods.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, index) {
          final Food food = store.foods[index];

          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.restaurant),
              ),
              title: Text(
                food.name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${formatNutritionValue(food.calories)} kcal / khẩu phần',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push<void>(
                  context,
                  MaterialPageRoute<void>(
                    builder: (context) =>
                        FoodDetailScreen(food: food),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}