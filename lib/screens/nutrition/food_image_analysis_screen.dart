import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../../models/food.dart';
import 'nutrition_store.dart';

class FoodImageAnalysisScreen extends StatefulWidget {
  const FoodImageAnalysisScreen({super.key});

  @override
  State<FoodImageAnalysisScreen> createState() =>
      _FoodImageAnalysisScreenState();
}

class _FoodImageAnalysisScreenState
    extends State<FoodImageAnalysisScreen> {
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://127.0.0.1:3000',
  );

  final ImagePicker _picker = ImagePicker();
  final NutritionStore store = NutritionStore.instance;

  XFile? _image;
  Map<String, dynamic>? _result;
  bool _loading = false;
  bool _saving = false;
  String? _error;

  String _selectedMealType = 'Bữa trưa';

  final List<String> _mealTypes = [
    'Bữa sáng',
    'Bữa trưa',
    'Bữa tối',
  ];

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (image == null || !mounted) return;

      setState(() {
        _image = image;
        _result = null;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Không thể mở ảnh. Vui lòng thử lại.';
      });
    }
  }

  Future<void> _analyzeImage() async {
    final image = _image;

    if (image == null || _loading || _saving) return;

    setState(() {
      _loading = true;
      _error = null;
      _result = null;
    });

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$_apiBaseUrl/analyze-food'),
      );

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          image.path,
        ),
      );

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 120),
      );

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      dynamic decoded;

      try {
        decoded = jsonDecode(response.body);
      } on FormatException {
        throw Exception('Máy chủ trả về dữ liệu không hợp lệ.');
      }

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        final message = decoded is Map
            ? decoded['error']?.toString()
            : null;

        throw Exception(
          message ?? 'Không thể phân tích ảnh.',
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Dữ liệu trả về không hợp lệ.');
      }

      if (!mounted) return;

      setState(() {
        _result = decoded;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error =
            'Phân tích thất bại: '
            '${e.toString().replaceFirst('Exception: ', '')}';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> get _foods {
    final raw = _result?['foods'];

    if (raw is! List) return [];

    return raw
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  double _number(
    Map<String, dynamic> food,
    String key,
  ) {
    final value = food[key];

    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(
          value?.toString() ?? '',
        ) ??
        0;
  }

  String _format(num value) {
    return value
        .toStringAsFixed(1)
        .replaceAll(RegExp(r'\.0$'), '');
  }

  void _saveToDiary() {
    if (_saving) return;

    if (_foods.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không có món ăn để lưu.'),
        ),
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final recognizedFoods = _foods.map((item) {
        return Food(
          id: 0,
          userId: NutritionStore.currentUserId,
          name: (item['name']?.toString() ?? '').trim(),
          calories: _number(item, 'calories_kcal'),
          protein: _number(item, 'protein_g'),
          carb: _number(item, 'carbs_g'),
          fat: _number(item, 'fat_g'),
          portionGrams: _number(item, 'portion_grams') > 0
              ? _number(item, 'portion_grams')
              : null,
        );
      }).toList();

      store.addRecognizedMeal(
        mealType: _selectedMealType,
        recognizedFoods: recognizedFoods,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Đã lưu bữa ăn và cập nhật dinh dưỡng!',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _saving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Không thể lưu bữa ăn: $e',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nhận diện món ăn'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 240,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: _image == null
                  ? const Column(
                      mainAxisAlignment:
                          MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fastfood,
                          size: 64,
                          color: Colors.green,
                        ),
                        SizedBox(height: 12),
                        Text('Chụp hoặc chọn ảnh món ăn'),
                      ],
                    )
                  : Image.file(
                      File(_image!.path),
                      fit: BoxFit.cover,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Center(
                          child: Text(
                            'Không hiển thị được ảnh',
                          ),
                        );
                      },
                    ),
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading || _saving
                        ? null
                        : () => _pickImage(
                              ImageSource.camera,
                            ),
                    icon: const Icon(
                      Icons.camera_alt_outlined,
                    ),
                    label: const Text('Chụp ảnh'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _loading || _saving
                        ? null
                        : () => _pickImage(
                              ImageSource.gallery,
                            ),
                    icon: const Icon(
                      Icons.photo_library_outlined,
                    ),
                    label: const Text('Thư viện'),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            ElevatedButton.icon(
              onPressed: _image == null ||
                      _loading ||
                      _saving
                  ? null
                  : _analyzeImage,
              icon: _loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
              label: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 13,
                ),
                child: Text(
                  _loading
                      ? 'Đang nhận diện...'
                      : 'Phân tích dinh dưỡng',
                ),
              ),
            ),

            if (_error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            ],

            if (_result != null) ...[
              const SizedBox(height: 24),

              const Text(
                'Kết quả ước tính',
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Thông tin dinh dưỡng chỉ mang tính ước tính. '
                'Hãy kiểm tra kết quả trước khi lưu.',
              ),

              const SizedBox(height: 12),

              if (_foods.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Chưa nhận diện được món ăn rõ ràng.',
                    ),
                  ),
                )
              else
                ..._foods.map((food) {
                  return Card(
                    margin: const EdgeInsets.only(
                      bottom: 10,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            food['name']?.toString() ??
                                'Món ăn',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            'Khẩu phần: '
                            '${_format(_number(food, 'portion_grams'))} g',
                          ),

                          const Divider(height: 24),

                          _nutritionRow(
                            'Năng lượng',
                            '${_format(_number(food, 'calories_kcal'))} kcal',
                          ),

                          _nutritionRow(
                            'Protein',
                            '${_format(_number(food, 'protein_g'))} g',
                          ),

                          _nutritionRow(
                            'Carbohydrate',
                            '${_format(_number(food, 'carbs_g'))} g',
                          ),

                          _nutritionRow(
                            'Chất béo',
                            '${_format(_number(food, 'fat_g'))} g',
                          ),
                        ],
                      ),
                    ),
                  );
                }),

              if ((_result?['note']?.toString() ?? '')
                  .isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(_result!['note'].toString()),
              ],

              if (_foods.isNotEmpty) ...[
                const SizedBox(height: 20),

                DropdownButtonFormField<String>(
                  initialValue: _selectedMealType,
                  decoration: const InputDecoration(
                    labelText: 'Lưu vào bữa ăn',
                    border: OutlineInputBorder(),
                  ),
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

                const SizedBox(height: 12),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _saving
                        ? null
                        : _saveToDiary,
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
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                      ),
                      child: Text(
                        _saving
                            ? 'Đang lưu...'
                            : 'Lưu vào nhật ký dinh dưỡng',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _nutritionRow(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}