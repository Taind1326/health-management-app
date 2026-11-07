import 'package:flutter/material.dart';

import '../../controllers/nutrition_controller.dart';
import '../../models/food.dart';
import 'add_food_screen.dart';

class AddMealScreen extends StatefulWidget {
  const AddMealScreen({super.key});

  @override
  State<AddMealScreen> createState() => _AddMealScreenState();
}

class _AddMealScreenState extends State<AddMealScreen> {
  final NutritionController controller = NutritionController.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _quantityController = TextEditingController(
    text: '1',
  );

  final List<String> _mealTypes = [
    'Bữa sáng',
    'Bữa trưa',
    'Bữa tối',
    'Bữa phụ',
  ];

  String _selectedMealType = 'Bữa sáng';
  int? _selectedFoodId;

  bool _saving = false;
  String? _error;

  List<Food> get _foods => controller.foods;

  Food? get _selectedFood {
    final id = _selectedFoodId;

    if (id == null) return null;

    return controller.foodById(id);
  }

  double get _quantity {
    final value = double.tryParse(
      _quantityController.text.trim().replaceAll(',', '.'),
    );

    if (value == null || !value.isFinite || value <= 0) {
      return 0;
    }

    return value;
  }

  @override
  void initState() {
    super.initState();

    if (_foods.isNotEmpty) {
      _selectedFoodId = _foods.first.id;
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    super.dispose();
  }

  // Mở màn hình thêm món thủ công.
  Future<void> _addFoodManually() async {
    final food = await Navigator.push<Food>(
      context,
      MaterialPageRoute<Food>(builder: (context) => const AddFoodScreen()),
    );

    if (!mounted || food == null) return;

    setState(() {
      _selectedFoodId = food.id;
      _error = null;
    });
  }

  Future<void> _saveMeal() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFoodId == null) {
      setState(() {
        _error = 'Vui lòng chọn món ăn.';
      });
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await controller.addMeal(
        mealType: _selectedMealType,
        foodId: _selectedFoodId!,
        quantity: _quantity,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã lưu bữa ăn thành công!')),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _buildFoodSelector() {
    if (_foods.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
        child: const Text(
          'Danh sách món ăn chưa có dữ liệu. '
          'Bạn có thể thêm món thủ công hoặc dùng chức năng '
          'nhận diện món ăn bằng ảnh.',
        ),
      );
    }

    return DropdownButtonFormField<int>(
      initialValue: _selectedFoodId,
      isExpanded: true,
      decoration: const InputDecoration(border: OutlineInputBorder()),
      items: _foods.map((item) {
        return DropdownMenuItem<int>(value: item.id, child: Text(item.name));
      }).toList(),
      onChanged: _saving
          ? null
          : (value) {
              if (value != null) {
                setState(() {
                  _selectedFoodId = value;
                });
              }
            },
    );
  }

  @override
  Widget build(BuildContext context) {
    final food = _selectedFood;
    final quantity = _quantity;

    return Scaffold(
      appBar: AppBar(title: const Text('Thêm bữa ăn')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Loại bữa ăn',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: _selectedMealType,
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: _mealTypes.map((type) {
                  return DropdownMenuItem<String>(
                    value: type,
                    child: Text(type),
                  );
                }).toList(),
                onChanged: _saving
                    ? null
                    : (value) {
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
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              const SizedBox(height: 8),

              _buildFoodSelector(),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _saving ? null : _addFoodManually,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm món mới'),
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Số khẩu phần',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: _quantityController,
                enabled: !_saving,
                keyboardType: const TextInputType.numberWithOptions(
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
                    (value ?? '').trim().replaceAll(',', '.'),
                  );

                  if (quantity == null || !quantity.isFinite || quantity <= 0) {
                    return 'Nhập số khẩu phần lớn hơn 0.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 24),

              if (food != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving || food == null ? null : _saveMeal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: _saving
                        ? const CircularProgressIndicator()
                        : const Text('Lưu bữa ăn'),
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
