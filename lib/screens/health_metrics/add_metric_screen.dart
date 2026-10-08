import 'package:flutter/material.dart';

/// Screen for adding a new health metric record.
/// Phase 1 prototype: validates input but does not persist to database.
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

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDateTime() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (time != null && mounted) {
        setState(() {
          _selectedDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  void _saveForm() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu chỉ số thành công!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
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
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Bắt buộc';
                final v = double.tryParse(value);
                if (v == null) return 'Phải là số';
                if (v < 60 || v > 250) return '60–250';
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
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Bắt buộc';
                final v = double.tryParse(value);
                if (v == null) return 'Phải là số';
                if (v < 40 || v > 150) return '40–150';
                return null;
              },
            ),
          ),
        ],
      );
    } else {
      String label = '';
      String errorRange = '';
      double min = 0;
      double max = 0;

      switch (_selectedType) {
        case 'heart_rate':
          label = 'Nhịp tim (bpm)';
          min = 30;
          max = 250;
          errorRange = '30–250';
          break;
        case 'weight':
          label = 'Cân nặng (kg)';
          min = 2;
          max = 300;
          errorRange = '2–300';
          break;
        case 'bmi':
          label = 'BMI (kg/m²)';
          min = 10;
          max = 50;
          errorRange = '10–50';
          break;
      }

      return TextFormField(
        controller: _valueController,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Bắt buộc';
          final v = double.tryParse(value);
          if (v == null) return 'Phải là số';
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
