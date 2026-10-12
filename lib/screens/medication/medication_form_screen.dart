import 'package:flutter/material.dart';

import '../../models/medication.dart';

class MedicationFormScreen extends StatefulWidget {
  final Medication? medication;
  final int userId;

  const MedicationFormScreen({
    super.key,
    this.medication,
    required this.userId,
  });

  @override
  State<MedicationFormScreen> createState() => _MedicationFormScreenState();
}

class _MedicationFormScreenState extends State<MedicationFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _dosageController;
  late final TextEditingController _unitController;
  late final TextEditingController _noteController;

  bool get _isEditing => widget.medication != null;

  @override
  void initState() {
    super.initState();

    final medication = widget.medication;

    _nameController = TextEditingController(text: medication?.name ?? '');
    _dosageController = TextEditingController(text: medication?.dosage ?? '');
    _unitController = TextEditingController(text: medication?.unit ?? '');
    _noteController = TextEditingController(text: medication?.note ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _unitController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập $label.';
    }
    return null;
  }

  String? _validateMedicationName(String? value) {
    final name = value?.trim() ?? '';

    if (name.isEmpty) {
      return 'Vui lòng nhập tên thuốc.';
    }

    final hasLetter = RegExp(r'\p{L}', unicode: true).hasMatch(name);

    if (!hasLetter) {
      return 'Tên thuốc phải có ít nhất một chữ cái.';
    }

    return null;
  }

  String? _validateDosage(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Vui lòng nhập liều lượng.';
    }

    final dosage = double.tryParse(value.trim().replaceAll(',', '.'));

    if (dosage == null || !dosage.isFinite || dosage <= 0) {
      return 'Liều lượng phải là số lớn hơn 0.';
    }

    return null;
  }

  void _saveMedication() {
    if (!_formKey.currentState!.validate()) return;

    final medication = Medication(
      id:
          widget.medication?.id ??
          'medication-${DateTime.now().microsecondsSinceEpoch}',
      userId: widget.medication?.userId ?? widget.userId,
      name: _nameController.text.trim().replaceAll(RegExp(r'\s+'), ' '),
      dosage: _dosageController.text.trim().replaceAll(',', '.'),
      unit: _unitController.text.trim(),
      note: _noteController.text.trim(),
    );

    Navigator.pop(context, medication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Sửa thuốc' : 'Thêm thuốc')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Tên thuốc',
                  hintText: 'Nhập tên thuốc',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medication_outlined),
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.next,
                validator: _validateMedicationName,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dosageController,
                decoration: const InputDecoration(
                  labelText: 'Liều mỗi lần',
                  hintText: 'Ví dụ: 1 hoặc 0,5',
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.next,
                validator: _validateDosage,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _unitController,
                decoration: const InputDecoration(
                  labelText: 'Đơn vị',
                  hintText: 'Ví dụ: viên, ml, gói',
                  border: OutlineInputBorder(),
                ),
                textInputAction: TextInputAction.next,
                validator: (value) => _validateRequired(value, 'đơn vị'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú',
                  hintText: 'Nhập ghi chú nếu có',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                minLines: 3,
                maxLines: 5,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _saveMedication,
                icon: const Icon(Icons.save_outlined),
                label: Text(_isEditing ? 'Lưu thay đổi' : 'Thêm thuốc'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
