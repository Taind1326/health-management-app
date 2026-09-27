import 'package:flutter/material.dart';
import '../../models/health_profile.dart';

class EditProfileScreen extends StatefulWidget {
  final HealthProfile currentProfile;

  const EditProfileScreen({
    super.key,
    required this.currentProfile,
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

  @override
  void initState() {
    super.initState();
    // Điền sẵn dữ liệu hiện tại
    _fullNameController = TextEditingController(text: widget.currentProfile.fullName);
    _ageController = TextEditingController(text: widget.currentProfile.age.toString());
    _heightController = TextEditingController(
      text: widget.currentProfile.height % 1 == 0
          ? widget.currentProfile.height.toInt().toString()
          : widget.currentProfile.height.toString(),
    );
    _weightController = TextEditingController(
      text: widget.currentProfile.weight % 1 == 0
          ? widget.currentProfile.weight.toInt().toString()
          : widget.currentProfile.weight.toString(),
    );

    _selectedGender = _genderOptions.contains(widget.currentProfile.gender)
        ? widget.currentProfile.gender
        : 'Nam';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final fullName = _fullNameController.text.trim();
    final age = int.parse(_ageController.text.trim());
    final height = double.parse(_heightController.text.trim());
    final weight = double.parse(_weightController.text.trim());

    // Tính lại BMI:
    // heightMeter = heightCm / 100
    // BMI = weight / (heightMeter * heightMeter)
    final double heightMeter = height / 100.0;
    final double calculatedBmi = weight / (heightMeter * heightMeter);
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

    // Trả dữ liệu đã cập nhật về cho ProfileScreen
    Navigator.pop(context, updatedProfile);
  }

  void _handleCancel() {
    // Không thay đổi dữ liệu, quay lại ProfileScreen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉnh sửa hồ sơ'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(
                  Icons.edit_note_outlined,
                  size: 64,
                  color: Colors.teal,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Cập nhật thông tin sức khỏe',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),

                // 1. Họ và tên
                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Họ và tên',
                    hintText: 'Nhập họ và tên',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Tuổi',
                    hintText: 'Nhập số tuổi',
                    prefixIcon: Icon(Icons.calendar_today_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Tuổi không được để trống.';
                    }
                    final parsed = int.tryParse(value.trim());
                    if (parsed == null) {
                      return 'Tuổi phải là số nguyên hợp lệ.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 3. Giới tính (DropdownButtonFormField)
                DropdownButtonFormField<String>(
                  initialValue: _selectedGender,
                  decoration: const InputDecoration(
                    labelText: 'Giới tính',
                    prefixIcon: Icon(Icons.wc),
                    border: OutlineInputBorder(),
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
                  decoration: const InputDecoration(
                    labelText: 'Chiều cao (cm)',
                    hintText: 'Nhập chiều cao theo cm (vd: 170)',
                    suffixText: 'cm',
                    prefixIcon: Icon(Icons.height),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Chiều cao không được để trống.';
                    }
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null) {
                      return 'Chiều cao phải là số hợp lệ.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // 5. Cân nặng (kg)
                TextFormField(
                  controller: _weightController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Cân nặng (kg)',
                    hintText: 'Nhập cân nặng theo kg (vd: 65)',
                    suffixText: 'kg',
                    prefixIcon: Icon(Icons.scale_outlined),
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Cân nặng không được để trống.';
                    }
                    final parsed = double.tryParse(value.trim());
                    if (parsed == null) {
                      return 'Cân nặng phải là số hợp lệ.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Nút Lưu
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.teal,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text(
                      'Lưu',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Nút Hủy
                SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _handleCancel,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.grey),
                      foregroundColor: Colors.grey.shade800,
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
