import 'package:flutter/material.dart';
import 'food_detail_screen.dart';

class FoodListScreen extends StatelessWidget {
  const FoodListScreen({super.key});

  final List<Map<String, dynamic>> foods = const [
    {
      'name': 'Bánh mì trứng',
      'calories': 350,
      'protein': 20,
      'carb': 40,
      'fat': 12,
    },
    {
      'name': 'Cơm gà',
      'calories': 600,
      'protein': 30,
      'carb': 65,
      'fat': 18,
    },
    {
      'name': 'Cơm cá',
      'calories': 400,
      'protein': 25,
      'carb': 50,
      'fat': 10,
    },
    {
      'name': 'Salad',
      'calories': 180,
      'protein': 8,
      'carb': 20,
      'fat': 7,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Danh sách món ăn'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: foods.length,
        separatorBuilder: (context, index) {
          return const SizedBox(height: 10);
        },
        itemBuilder: (context, index) {
          final food = foods[index];

          return Card(
            child: ListTile(
              leading: const CircleAvatar(
                child: Icon(Icons.restaurant),
              ),
              title: Text(
                food['name'],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                '${food['calories']} kcal',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FoodDetailScreen(
                      food: food,
                    ),
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