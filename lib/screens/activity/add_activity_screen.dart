import 'package:flutter/material.dart';

import '../../models/activity.dart';

/// Form ghi nhận một hoạt động. Trả về [Activity] qua Navigator.pop khi lưu.
class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stepsCtrl = TextEditingController(text: '0');
  final _distanceCtrl = TextEditingController(text: '0');
  final _durationCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController(text: '0');

  String _type = Activity.types.first;
  DateTime _date = DateTime.now();

  @override
  void dispose() {
    _stepsCtrl.dispose();
    _distanceCtrl.dispose();
    _durationCtrl.dispose();
    _caloriesCtrl.dispose();
    super.dispose();
  }

  String _dmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(picked.year, picked.month, picked.day, _date.hour,
            _date.minute);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (picked != null) {
      setState(() {
        _date = DateTime(
            _date.year, _date.month, _date.day, picked.hour, picked.minute);
      });
    }
  }

  String? _intValidator(String? v, {required int min, required int max}) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null) return 'Nhập một số nguyên';
    if (n < min || n > max) return 'Nhập từ $min đến $max';
    return null;
  }

  double? _parseDouble(String? v) =>
      double.tryParse((v ?? '').trim().replaceAll(',', '.'));

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    if (_date.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian không được ở tương lai')),
      );
      return;
    }
    Navigator.pop(
      context,
      Activity(
        userId: 1, // đợt 2: lấy từ người dùng đang đăng nhập (TV1)
        type: _type,
        date: _date,
        steps: int.parse(_stepsCtrl.text.trim()),
        distanceKm: _parseDouble(_distanceCtrl.text)!,
        durationMinutes: int.parse(_durationCtrl.text.trim()),
        calories: int.parse(_caloriesCtrl.text.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm hoạt động')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Loại hoạt động'),
              items: Activity.types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? _type),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_dmy(_date)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      '${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Thời gian vận động (phút)'),
              validator: (v) => _intValidator(v, min: 1, max: 1440),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stepsCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số bước'),
              validator: (v) => _intValidator(v, min: 0, max: 100000),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _distanceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quãng đường (km)'),
              validator: (v) {
                final d = _parseDouble(v);
                if (d == null) return 'Nhập một số, ví dụ 2.5';
                if (d < 0 || d > 500) return 'Nhập từ 0 đến 500';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _caloriesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calo tiêu hao (kcal)'),
              validator: (v) => _intValidator(v, min: 0, max: 10000),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Lưu hoạt động')),
          ],
        ),
      ),
    );
  }
}