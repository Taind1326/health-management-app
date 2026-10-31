import 'package:flutter/material.dart';

import '../../models/food.dart';
import 'nutrition_store.dart';

class FoodDetailScreen extends StatelessWidget {
  final Food food;

  const FoodDetailScreen({
    super.key,
    required this.food,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết món ăn'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.restaurant,
                size: 80,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              food.name,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Giá trị dinh dưỡng trên một khẩu phần'),
            const SizedBox(height: 20),
            _InfoRow(
              title: 'Calo',
              value:
                  '${formatNutritionValue(food.calories)} kcal',
            ),
            _InfoRow(
              title: 'Protein',
              value:
                  '${formatNutritionValue(food.protein)} g',
            ),
            _InfoRow(
              title: 'Carb',
              value:
                  '${formatNutritionValue(food.carb)} g',
            ),
            _InfoRow(
              title: 'Fat',
              value:
                  '${formatNutritionValue(food.fat)} g',
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String title;
  final String value;

  const _InfoRow({
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}