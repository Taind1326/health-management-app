
import 'package:flutter/material.dart';

import '../../controllers/nutrition_controller.dart';
import '../../models/food.dart';

class AddFoodScreen extends StatefulWidget {
  const AddFoodScreen({super.key});

  @override
  State<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends State<AddFoodScreen> {
  final NutritionController controller = NutritionController.instance;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _portionController = TextEditingController();
  final TextEditingController _caloriesController = TextEditingController();
  final TextEditingController _proteinController = TextEditingController();
  final TextEditingController _carbController = TextEditingController();
  final TextEditingController _fatController = TextEditingController();

  bool _saving = false;
  String? _error;

  double? _parseNumber(String? value) {
    return double.tryParse(
      (value ?? '').trim().replaceAll(',', '.'),
    );
  }

  String? _validateNumber(
    String? value, {
    required String label,
    bool optional = false,
    bool positive = false,
  }) {
    final raw = value?.trim() ?? '';

    if (raw.isEmpty && optional) return null;

    if (raw.isEmpty) {
      return 'Vui lòng nhập $label.';
    }

    final number = _parseNumber(raw);

    if (number == null || !number.isFinite) {
      return '$label phải là số hợp lệ.';
    }

    if (positive ? number <= 0 : number < 0) {
      return positive
          ? '$label phải lớn hơn 0.'
          : '$label không được âm.';
    }

    return null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _portionController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  Future<void> _saveFood() async {
    if (_saving || !_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final Food food = await controller.addFood(
        name: _nameController.text.trim(),
        calories: _parseNumber(_caloriesController.text)!,
        protein: _parseNumber(_proteinController.text)!,
        carb: _parseNumber(_carbController.text)!,
        fat: _parseNumber(_fatController.text)!,
        portionGrams: _portionController.text.trim().isEmpty
            ? null
            : _parseNumber(_portionController.text),
      );

      if (!mounted) return;

      Navigator.pop<Food>(context, food);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _buildNumberField({
    required String label,
    required TextEditingController textController,
    required String suffix,
    bool optional = false,
    bool positive = false,
  }) {
    return TextFormField(
      controller: textController,
      enabled: !_saving,
      keyboardType: const TextInputType.numberWithOptions(
        decimal: true,
      ),
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
        border: const OutlineInputBorder(),
      ),
      validator: (value) => _validateNumber(
        value,
        label: label,
        optional: optional,
        positive: positive,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm món ăn thủ công'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Thông tin món ăn',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                'Nhập giá trị dinh dưỡng cho một khẩu phần. '
                'Số liệu do bạn cung cấp sẽ được lưu vào danh sách món ăn.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 20),

              TextFormField(
                controller: _nameController,
                enabled: !_saving,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Tên món ăn',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên món ăn.';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 14),

              _buildNumberField(
                label: 'Khối lượng khẩu phần',
                textController: _portionController,
                suffix: 'g',
                optional: true,
                positive: true,
              ),

              const SizedBox(height: 14),

              _buildNumberField(
                label: 'Calo',
                textController: _caloriesController,
                suffix: 'kcal',
              ),

              const SizedBox(height: 14),

              _buildNumberField(
                label: 'Protein',
                textController: _proteinController,
                suffix: 'g',
              ),

              const SizedBox(height: 14),

              _buildNumberField(
                label: 'Carb',
                textController: _carbController,
                suffix: 'g',
              ),

              const SizedBox(height: 14),

              _buildNumberField(
                label: 'Fat',
                textController: _fatController,
                suffix: 'g',
              ),

              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ],

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _saving ? null : _saveFood,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      _saving ? 'Đang lưu...' : 'Lưu món ăn',
                    ),
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
