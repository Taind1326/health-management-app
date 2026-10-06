import 'package:flutter/material.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  String selectedMeal = 'Bữa sáng';
  String selectedFood = 'Bánh mì trứng';

  final List<String> mealTypes = [
    'Bữa sáng',
    'Bữa trưa',
    'Bữa tối',
  ];

  final List<String> foods = [
    'Bánh mì trứng',
    'Cơm gà',
    'Cơm cá',
    'Salad',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm bữa ăn'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Loại bữa ăn',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedMeal,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: mealTypes.map((meal) {
                return DropdownMenuItem(
                  value: meal,
                  child: Text(meal),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedMeal = value;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Món ăn',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: selectedFood,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              items: foods.map((food) {
                return DropdownMenuItem(
                  value: food,
                  child: Text(food),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedFood = value;
                  });
                }
              },
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Thông tin dinh dưỡng mẫu',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text('Calo: 350 kcal'),
                  Text('Protein: 20 g'),
                  Text('Carb: 40 g'),
                  Text('Fat: 12 g'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Đã thêm bữa ăn - dữ liệu mẫu',
                      ),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text('Thêm bữa ăn'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}