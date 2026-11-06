import 'package:flutter/material.dart';
import '../../models/health_profile.dart';
import '../../services/auth_service.dart';
import '../../widgets/tv1_glass_widgets.dart';
import '../home/home_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final HealthProfile currentProfile;
  final bool isInitialSetup;

  const EditProfileScreen({
    super.key,
    required this.currentProfile,
    this.isInitialSetup = false,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _fullNameController;
  late TextEditingController _ageController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  String? _selectedGender;
  final List<String> _genderOptions = ['Nam', 'Nữ'];

  // Mục tiêu sức khỏe ban đầu khi onboarding
  String _selectedGoal = 'Duy trì vóc dáng & Sức khỏe';
  final List<String> _goalOptions = [
    'Duy trì vóc dáng & Sức khỏe',
    'Giảm mỡ & Giảm cân lành mạnh',
    'Tăng cơ & Tăng thể lực',
  ];

  @override
  void initState() {
    super.initState();
    String formatInitial(double val) {
      if (val <= 0) return '';
      return val % 1 == 0
          ? val.toInt().toString()
          : val.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }

    _fullNameController = TextEditingController(text: widget.currentProfile.fullName);
    _ageController = TextEditingController(
      text: widget.currentProfile.age > 0 ? widget.currentProfile.age.toString() : '',
    );
    _heightController = TextEditingController(text: formatInitial(widget.currentProfile.height));
    _weightController = TextEditingController(text: formatInitial(widget.currentProfile.weight));

    _selectedGender = _genderOptions.contains(widget.currentProfile.gender)
        ? widget.currentProfile.gender
        : 'Nam';

    _heightController.addListener(_onMetricChanged);
    _weightController.addListener(_onMetricChanged);
    _ageController.addListener(_onMetricChanged);
  }

  void _onMetricChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _heightController.removeListener(_onMetricChanged);
    _weightController.removeListener(_onMetricChanged);
    _ageController.removeListener(_onMetricChanged);
    _fullNameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final fullName = _fullNameController.text.trim();
    final age = int.parse(_ageController.text.trim());
    final heightNormalized = _heightController.text.trim().replaceAll(',', '.');
    final weightNormalized = _weightController.text.trim().replaceAll(',', '.');
    final height = double.parse(heightNormalized);
    final weight = double.parse(weightNormalized);

    final double heightMeter = height / 100.0;
    if (heightMeter <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chiều cao phải lớn hơn 0.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final double calculatedBmi = weight / (heightMeter * heightMeter);

    if (calculatedBmi.isNaN || calculatedBmi.isInfinite || calculatedBmi <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chỉ số BMI không hợp lệ, vui lòng kiểm tra lại chiều cao và cân nặng.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final double roundedBmi = double.parse(calculatedBmi.toStringAsFixed(2));

    final updatedProfile = HealthProfile(
      id: widget.currentProfile.id,
      userId: widget.currentProfile.userId,
      fullName: fullName,
      age: age,
      gender: _selectedGender!,
      height: height,
      weight: weight,
      bmi: roundedBmi,
    );

    final authService = AuthService();

    try {
      if (widget.isInitialSetup) {
        // Cập nhật profile vào AuthService & SQLite
        await authService.updateProfile(updatedProfile);

        // Thêm mục tiêu sức khỏe thông minh khởi tạo cho người dùng
        final waterGoal = AuthService.calculateRecommendedWater(weight);
        final bmr = AuthService.calculateBmr(
          weightKg: weight,
          heightCm: height,
          age: age,
          gender: _selectedGender!,
        );
        final tdee = AuthService.calculateTdee(bmr: bmr);

        int calorieTarget = tdee;
        String dietMode = 'balanced';
        int stepGoal = 8000;

        if (_selectedGoal.contains('Giảm')) {
          calorieTarget = tdee - 500;
          dietMode = 'weight_loss'; // Chuẩn CHECK constraint SQLite ('weight_loss')
          stepGoal = 10000;
        } else if (_selectedGoal.contains('Tăng')) {
          calorieTarget = tdee + 400;
          dietMode = 'muscle_gain'; // Chuẩn CHECK constraint SQLite ('muscle_gain')
          stepGoal = 7000;
        } else {
          dietMode = 'balanced';
        }

        await authService.addGoal(
          widget.currentProfile.userId,
          '$_selectedGoal (Mục tiêu: $calorieTarget kcal/ngày, $waterGoal ml nước)',
        );

        // Đồng bộ thiết lập sang bảng user_settings của hệ thống nếu không trong môi trường test
        if (!authService.isTestingMode) {
          await authService.repository.syncUserSettings(
            widget.currentProfile.userId,
            waterGoalMl: waterGoal,
            stepGoal: stepGoal,
            dietMode: dietMode,
          );
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Thiết lập hồ sơ sức khỏe ban đầu thành công!'),
            backgroundColor: Color(0xFF0284C7),
          ),
        );

        // Chuyển thẳng vào HomeScreen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const HomeScreen(),
          ),
        );
      } else {
        // Cập nhật profile vào AuthService & SQLite
        await authService.updateProfile(updatedProfile);
        if (!mounted) return;

        // Trả dữ liệu đã cập nhật về cho ProfileScreen
        Navigator.pop(context, updatedProfile);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lưu thông tin thất bại: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handleCancel() {
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    // Tính toán ước tính nhanh để hiển thị preview
    final heightParsed = double.tryParse(_heightController.text.trim().replaceAll(',', '.')) ?? 0;
    final weightParsed = double.tryParse(_weightController.text.trim().replaceAll(',', '.')) ?? 0;
    final ageParsed = int.tryParse(_ageController.text.trim()) ?? 0;

    double previewBmi = 0.0;
    double previewBmr = 0.0;
    int previewWater = 2000;

    if (heightParsed > 0 && weightParsed > 0) {
      previewBmi = AuthService.calculateBmi(heightParsed, weightParsed);
      previewWater = AuthService.calculateRecommendedWater(weightParsed);
      if (ageParsed > 0) {
        previewBmr = AuthService.calculateBmr(
          weightKg: weightParsed,
          heightCm: heightParsed,
          age: ageParsed,
          gender: _selectedGender ?? 'Nam',
        );
      }
    }

    return Tv1GlassScaffold(
      appBar: Tv1GlassAppBar(
        title: Text(
          widget.isInitialSetup ? 'Thiết lập hồ sơ sức khỏe' : 'Chỉnh sửa hồ sơ',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: !widget.isInitialSetup,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Huy hiệu kính đa lớp
              Center(
                child: Tv1LayeredBadge(
                  icon: widget.isInitialSetup
                      ? Icons.monitor_heart_rounded
                      : Icons.edit_note_rounded,
                  size: 50,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                widget.isInitialSetup ? 'Nhập thông tin sức khỏe ban đầu' : 'Cập nhật thông tin sức khỏe',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              if (widget.isInitialSetup) ...[
                const SizedBox(height: 6),
                Text(
                  'Vui lòng nhập chiều cao, cân nặng và tuổi để ứng dụng tính toán chỉ số BMI cho bạn.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
              const SizedBox(height: 20),

              // Thẻ kính Form thông tin
              Tv1GlassCard(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Họ và tên
                    TextFormField(
                      controller: _fullNameController,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: Tv1GlassTheme.inputDecoration(
                        labelText: 'Họ và tên',
                        hintText: 'Nhập họ và tên',
                        prefixIcon: const Icon(Icons.badge_outlined, color: Color(0xFF7DD3FC)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Họ và tên không được để trống.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 2. Tuổi
                    TextFormField(
                      controller: _ageController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: Tv1GlassTheme.inputDecoration(
                        labelText: 'Tuổi',
                        hintText: 'Nhập số tuổi',
                        prefixIcon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF7DD3FC)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Tuổi không được để trống.';
                        }
                        final parsed = int.tryParse(value.trim());
                        if (parsed == null) {
                          return 'Tuổi phải là số nguyên hợp lệ.';
                        }
                        if (parsed <= 0 || parsed > 120) {
                          return 'Tuổi phải nằm trong khoảng từ 1 đến 120.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 3. Giới tính
                    DropdownButtonFormField<String>(
                      initialValue: _selectedGender,
                      dropdownColor: const Color(0xFF1E1B4B),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      iconEnabledColor: const Color(0xFF7DD3FC),
                      decoration: Tv1GlassTheme.inputDecoration(
                        labelText: 'Giới tính',
                        prefixIcon: const Icon(Icons.wc, color: Color(0xFF7DD3FC)),
                      ),
                      items: _genderOptions.map((gender) {
                        return DropdownMenuItem<String>(
                          value: gender,
                          child: Text(gender),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedGender = value;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng chọn giới tính.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 4. Chiều cao (cm)
                    TextFormField(
                      controller: _heightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: Tv1GlassTheme.inputDecoration(
                        labelText: 'Chiều cao (cm)',
                        hintText: 'Nhập chiều cao theo cm (vd: 170)',
                        suffixText: 'cm',
                        prefixIcon: const Icon(Icons.height, color: Color(0xFF7DD3FC)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Chiều cao không được để trống.';
                        }
                        final normalized = value.trim().replaceAll(',', '.');
                        final parsed = double.tryParse(normalized);
                        if (parsed == null || parsed.isNaN || parsed.isInfinite) {
                          return 'Chiều cao phải là số hợp lệ.';
                        }
                        if (parsed <= 0) {
                          return 'Chiều cao phải lớn hơn 0.';
                        }
                        if (parsed > 300) {
                          return 'Chiều cao không được vượt quá 300 cm.';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // 5. Cân nặng (kg)
                    TextFormField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                      decoration: Tv1GlassTheme.inputDecoration(
                        labelText: 'Cân nặng (kg)',
                        hintText: 'Nhập cân nặng theo kg (vd: 65)',
                        suffixText: 'kg',
                        prefixIcon: const Icon(Icons.scale_outlined, color: Color(0xFF7DD3FC)),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Cân nặng không được để trống.';
                        }
                        final normalized = value.trim().replaceAll(',', '.');
                        final parsed = double.tryParse(normalized);
                        if (parsed == null || parsed.isNaN || parsed.isInfinite) {
                          return 'Cân nặng phải là số hợp lệ.';
                        }
                        if (parsed <= 0) {
                          return 'Cân nặng phải lớn hơn 0.';
                        }
                        if (parsed > 500) {
                          return 'Cân nặng không được vượt quá 500 kg.';
                        }
                        return null;
                      },
                    ),

                    // 6. Mục tiêu sức khỏe (khi thiết lập ban đầu)
                    if (widget.isInitialSetup) ...[
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _selectedGoal,
                        dropdownColor: const Color(0xFF1E1B4B),
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                        iconEnabledColor: const Color(0xFF7DD3FC),
                        decoration: Tv1GlassTheme.inputDecoration(
                          labelText: 'Mục tiêu sức khỏe ban đầu',
                          prefixIcon: const Icon(Icons.flag_circle_outlined, color: Color(0xFF7DD3FC)),
                        ),
                        items: _goalOptions.map((goal) {
                          return DropdownMenuItem<String>(
                            value: goal,
                            child: Text(goal),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() {
                              _selectedGoal = val;
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Thẻ xem trước chỉ số thông minh
              if (previewBmi > 0) ...[
                Tv1GlassCard(
                  padding: const EdgeInsets.all(14),
                  surfaceColor: Colors.white.withValues(alpha: 0.15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.insights, size: 20, color: Color(0xFF7DD3FC)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Ước tính chỉ số: BMI ${(previewBmi.isFinite && !previewBmi.isNaN) ? previewBmi.toStringAsFixed(2) : "0.00"}',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF7DD3FC),
                                fontSize: 15,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '• BMR ước tính: ${(previewBmr.isFinite && !previewBmr.isNaN && previewBmr > 0) ? "${previewBmr.round()} kcal/ngày" : "Đang tính..."}\n• Lượng nước khuyến nghị: $previewWater ml/ngày',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                          height: 1.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Nút Lưu / Hoàn tất
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _handleSave,
                  style: Tv1GlassTheme.primaryButtonStyle(),
                  child: Text(
                    widget.isInitialSetup ? 'Hoàn tất & Vào trang chủ' : 'Lưu',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (!widget.isInitialSetup) ...[
                const SizedBox(height: 12),
                SizedBox(
                  height: 50,
                  child: OutlinedButton(
                    onPressed: _handleCancel,
                    style: Tv1GlassTheme.secondaryButtonStyle(),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
