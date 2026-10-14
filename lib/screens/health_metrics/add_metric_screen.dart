import 'package:flutter/material.dart';
import '../../models/health_metric.dart';
import '../../repositories/health_metric_repository.dart';

/// Screen for adding a new health metric record.
/// Handles numeric parsing (supporting commas), range checks, future date prevention,
/// and adds the record directly to the shared [HealthMetricRepository].
class AddMetricScreen extends StatefulWidget {
  const AddMetricScreen({super.key});

  @override
  State<AddMetricScreen> createState() => _AddMetricScreenState();
}

class _AddMetricScreenState extends State<AddMetricScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'blood_pressure';
  DateTime _selectedDate = DateTime.now();

  // Map of metric type key -> Vietnamese label
  static const Map<String, String> _metricTypeLabels = {
    'blood_pressure': 'Huyết áp',
    'heart_rate': 'Nhịp tim',
    'weight': 'Cân nặng',
    'bmi': 'BMI',
  };

  // Controllers
  final _sysController = TextEditingController();
  final _diaController = TextEditingController();
  final _valueController = TextEditingController(); // For HR, Weight, BMI
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _sysController.dispose();
    _diaController.dispose();
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  /// Normalizes and parses input string to a finite double.
  /// Converts comma to dot (e.g. "65,5" -> 65.5) and checks isFinite.
  double? _parseNumber(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().replaceAll(',', '.');
    final val = double.tryParse(normalized);
    if (val == null || !val.isFinite || val.isNaN) return null;
    return val;
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: now, // Prevents picking dates in the future
    );
    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null && mounted) {
        final pickedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        if (pickedDateTime.isAfter(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Thời điểm đo không được ở tương lai!'),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        setState(() {
          _selectedDate = pickedDateTime;
        });
      }
    }
  }

  void _saveForm() {
    // 1. Chặn thời điểm đo ở tương lai và giữ nguyên form nếu vi phạm
    if (_selectedDate.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thời điểm đo không được vượt quá thời gian hiện tại!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    double primaryValue = 0;
    double? secondaryValue;
    String unit = '';

    if (_selectedType == 'blood_pressure') {
      primaryValue = _parseNumber(_sysController.text)!;
      secondaryValue = _parseNumber(_diaController.text)!;
      unit = 'mmHg';
    } else {
      primaryValue = _parseNumber(_valueController.text)!;
      switch (_selectedType) {
        case 'heart_rate':
          unit = 'bpm';
          break;
        case 'weight':
          unit = 'kg';
          break;
        case 'bmi':
          unit = 'kg/m²';
          break;
      }
    }

    // Tạo bản ghi HealthMetric và đưa vào nguồn dữ liệu dùng chung
    final newMetric = HealthMetric(
      id: DateTime.now().millisecondsSinceEpoch,
      userId: 1,
      metricType: _selectedType,
      value: primaryValue,
      value2: secondaryValue,
      unit: unit,
      note: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      recordedAt: _selectedDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    HealthMetricRepository().add(newMetric);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Đã lưu chỉ số thành công!'),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
  }

  Widget _buildTypeSelector() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: 'Loại chỉ số',
        border: OutlineInputBorder(),
      ),
      initialValue: _selectedType,
      items: _metricTypeLabels.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedType = value;
            _sysController.clear();
            _diaController.clear();
            _valueController.clear();
          });
        }
      },
    );
  }

  Widget _buildInputFields() {
    if (_selectedType == 'blood_pressure') {
      return Row(
        children: [
          Expanded(
            child: TextFormField(
              controller: _sysController,
              decoration: const InputDecoration(
                labelText: 'Tâm thu (mmHg)',
                border: OutlineInputBorder(),
                hintText: 'VD: 120',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Bắt buộc nhập';
                final v = _parseNumber(value);
                if (v == null) return 'Phải là số hợp lệ';
                if (v < 60 || v > 250) return 'Từ 60 – 250 mmHg';
                return null;
              },
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: TextFormField(
              controller: _diaController,
              decoration: const InputDecoration(
                labelText: 'Tâm trương (mmHg)',
                border: OutlineInputBorder(),
                hintText: 'VD: 80',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null || value.trim().isEmpty) return 'Bắt buộc nhập';
                final v = _parseNumber(value);
                if (v == null) return 'Phải là số hợp lệ';
                if (v < 40 || v > 150) return 'Từ 40 – 150 mmHg';
                return null;
              },
            ),
          ),
        ],
      );
    } else {
      String label = '';
      String hint = '';
      String errorRange = '';
      double min = 0;
      double max = 0;

      switch (_selectedType) {
        case 'heart_rate':
          label = 'Nhịp tim (bpm)';
          hint = 'VD: 75';
          min = 30;
          max = 250;
          errorRange = 'Từ 30 – 250 bpm';
          break;
        case 'weight':
          label = 'Cân nặng (kg)';
          hint = 'VD: 65.5 hoặc 65,5';
          min = 2;
          max = 300;
          errorRange = 'Từ 2 – 300 kg';
          break;
        case 'bmi':
          label = 'BMI (kg/m²)';
          hint = 'VD: 22.4';
          min = 10;
          max = 50;
          errorRange = 'Từ 10 – 50 kg/m²';
          break;
      }

      return TextFormField(
        controller: _valueController,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.trim().isEmpty) return 'Bắt buộc nhập';
          final v = _parseNumber(value);
          if (v == null) return 'Phải là số hợp lệ';
          if (v < min || v > max) return 'Không hợp lệ ($errorRange)';
          return null;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thêm chỉ số'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTypeSelector(),
              const SizedBox(height: 24),
              _buildInputFields(),
              const SizedBox(height: 24),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Thời gian'),
                subtitle: Text(_formatDateTime(_selectedDate)),
                trailing: const Icon(Icons.calendar_today),
                onTap: _selectDateTime,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(
                  labelText: 'Ghi chú (tùy chọn)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _saveForm,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Lưu', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
