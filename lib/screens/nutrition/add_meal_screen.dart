import 'package:flutter/material.dart';

import '../../models/food.dart';
import 'nutrition_store.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() =>
      _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final NutritionStore store = NutritionStore.instance;
  final GlobalKey<FormState> _formKey =
      GlobalKey<FormState>();

  final TextEditingController _quantityController =
      TextEditingController(text: '1');

  final List<String> _mealTypes = [
    'Bữa sáng',
    'Bữa trưa',
    'Bữa tối',
  ];

  String _selectedMealType = 'Bữa sáng';
  int _selectedFoodId = 1;

  Food get _selectedFood {
    return store.foodById(_selectedFoodId) ??
        store.foods.first;
  }

  double get _quantity {
    final value = double.tryParse(
      _quantityController.text.trim(),
    );

    if (value == null || !value.isFinite || value <= 0) {
      return 0;
    }

    return value;
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  void _saveMeal() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    store.addMeal(
      mealType: _selectedMealType,
      foodId: _selectedFoodId,
      quantity: _quantity,
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final food = _selectedFood;
    final quantity = _quantity;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm bữa ăn'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
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
                initialValue: _selectedMealType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _mealTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedMealType = value;
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
              DropdownButtonFormField<int>(
                initialValue: _selectedFoodId,
                isExpanded: true,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: store.foods.map((item) {
                  return DropdownMenuItem<int>(
                    value: item.id,
                    child: Text(item.name),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedFoodId = value;
                    });
                  }
                },
              ),
              const SizedBox(height: 20),
              const Text(
                'Số khẩu phần',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _quantityController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Ví dụ: 1 hoặc 1.5',
                ),
                onChanged: (value) {
                  setState(() {});
                },
                validator: (value) {
                  final quantity = double.tryParse(
                    value?.trim() ?? '',
                  );

                  if (quantity == null ||
                      !quantity.isFinite ||
                      quantity <= 0) {
                    return 'Nhập số khẩu phần lớn hơn 0.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dinh dưỡng của ${food.name}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Calo: ${formatNutritionValue(food.calories * quantity)} kcal',
                    ),
                    Text(
                      'Protein: ${formatNutritionValue(food.protein * quantity)} g',
                    ),
                    Text(
                      'Carb: ${formatNutritionValue(food.carb * quantity)} g',
                    ),
                    Text(
                      'Fat: ${formatNutritionValue(food.fat * quantity)} g',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saveMeal,
                  child: const Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: 14,
                    ),
                    child: Text('Lưu bữa ăn'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}