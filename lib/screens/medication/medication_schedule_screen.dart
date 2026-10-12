import 'package:flutter/material.dart';

import '../../models/medication.dart';
import '../../models/medication_schedule.dart';

class MedicationScheduleScreen extends StatefulWidget {
  final Medication medication;
  final List<MedicationSchedule> schedules;

  const MedicationScheduleScreen({
    super.key,
    required this.medication,
    required this.schedules,
  });

  @override
  State<MedicationScheduleScreen> createState() =>
      _MedicationScheduleScreenState();
}

class _MedicationScheduleScreenState extends State<MedicationScheduleScreen> {
  late final List<MedicationSchedule> _schedules;

  TimeOfDay _time = const TimeOfDay(hour: 8, minute: 0);
  DateTime _startDate = DateUtils.dateOnly(DateTime.now());
  DateTime? _endDate;
  MedicationRepeat _repeat = MedicationRepeat.daily;
  final Set<int> _weekdays = {};

  @override
  void initState() {
    super.initState();
    _schedules = List.of(widget.schedules);
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatTime(int hour, int minute) {
    return '${hour.toString().padLeft(2, '0')}:'
        '${minute.toString().padLeft(2, '0')}';
  }

  String _weekdayLabel(int day) {
    return day == 7 ? 'CN' : 'T${day + 1}';
  }

  String _repeatLabel(MedicationSchedule schedule) {
    switch (schedule.repeat) {
      case MedicationRepeat.once:
        return 'Một lần';
      case MedicationRepeat.daily:
        return 'Hằng ngày';
      case MedicationRepeat.selectedWeekdays:
        final days = List<int>.of(schedule.weekdays)..sort();
        return days.map(_weekdayLabel).join(', ');
    }
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);

    if (!mounted || selected == null) return;

    setState(() => _time = selected);
  }

  Future<void> _pickStartDate() async {
    final today = DateUtils.dateOnly(DateTime.now());
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate.isBefore(today) ? today : _startDate,
      firstDate: today,
      lastDate: DateTime(today.year + 5, 12, 31),
    );

    if (!mounted || selected == null) return;

    setState(() {
      _startDate = selected;

      if (_endDate != null && _endDate!.isBefore(_startDate)) {
        _endDate = null;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(_startDate.year + 5, 12, 31),
    );

    if (!mounted || selected == null) return;

    setState(() => _endDate = selected);
  }

  void _addSchedule() {
    if (_repeat == MedicationRepeat.selectedWeekdays && _weekdays.isEmpty) {
      _showMessage('Vui lòng chọn ít nhất một ngày trong tuần.');
      return;
    }

    final scheduledAt = DateTime(
      _startDate.year,
      _startDate.month,
      _startDate.day,
      _time.hour,
      _time.minute,
    );

    if (_repeat == MedicationRepeat.once &&
        !scheduledAt.isAfter(DateTime.now())) {
      _showMessage('Lịch uống một lần phải nằm trong tương lai.');
      return;
    }

    final days = _repeat == MedicationRepeat.selectedWeekdays
        ? (_weekdays.toList()..sort())
        : <int>[];

    final endDate = _repeat == MedicationRepeat.once ? null : _endDate;
    final duplicate = _schedules.any((schedule) {
      final existingDays = List<int>.of(schedule.weekdays)..sort();

      return schedule.hour == _time.hour &&
          schedule.minute == _time.minute &&
          DateUtils.isSameDay(schedule.startDate, _startDate) &&
          DateUtils.isSameDay(schedule.endDate, endDate) &&
          schedule.repeat == _repeat &&
          existingDays.join(',') == days.join(',');
    });

    if (duplicate) {
      _showMessage('Lịch uống này đã có trong danh sách.');
      return;
    }

    setState(() {
      _schedules.add(
        MedicationSchedule(
          id: 'schedule-${DateTime.now().microsecondsSinceEpoch}',
          medicationId: widget.medication.id,
          startDate: _startDate,
          endDate: endDate,
          hour: _time.hour,
          minute: _time.minute,
          repeat: _repeat,
          weekdays: days,
        ),
      );
    });

    _showMessage('Đã thêm lịch. Bấm Lưu để áp dụng thay đổi.');
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch uống thuốc')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            widget.medication.name,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Liều mỗi lần: ${widget.medication.dosage} '
            '${widget.medication.unit}',
          ),
          const SizedBox(height: 24),
          Text('Tạo lịch uống', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _pickTime,
            icon: const Icon(Icons.access_time),
            label: Text('Giờ uống: ${_formatTime(_time.hour, _time.minute)}'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickStartDate,
            icon: const Icon(Icons.calendar_today_outlined),
            label: Text('Bắt đầu: ${_formatDate(_startDate)}'),
          ),
          const SizedBox(height: 16),
          const Text('Lặp lại'),
          RadioGroup<MedicationRepeat>(
            groupValue: _repeat,
            onChanged: (value) {
              if (value == null) return;

              setState(() {
                _repeat = value;
              });
            },
            child: const Column(
              children: [
                RadioListTile<MedicationRepeat>(
                  title: Text('Một lần'),
                  value: MedicationRepeat.once,
                ),
                RadioListTile<MedicationRepeat>(
                  title: Text('Hằng ngày'),
                  value: MedicationRepeat.daily,
                ),
                RadioListTile<MedicationRepeat>(
                  title: Text('Các ngày trong tuần'),
                  value: MedicationRepeat.selectedWeekdays,
                ),
              ],
            ),
          ),
          if (_repeat != MedicationRepeat.once) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickEndDate,
              icon: const Icon(Icons.event_outlined),
              label: Text(
                _endDate == null
                    ? 'Ngày kết thúc: chưa đặt'
                    : 'Kết thúc: ${_formatDate(_endDate!)}',
              ),
            ),
            if (_endDate != null)
              TextButton(
                onPressed: () {
                  setState(() => _endDate = null);
                },
                child: const Text('Bỏ ngày kết thúc'),
              ),
          ],

          if (_repeat == MedicationRepeat.selectedWeekdays)
            Wrap(
              spacing: 8,
              children: List.generate(7, (index) {
                final day = index + 1;

                return FilterChip(
                  label: Text(_weekdayLabel(day)),
                  selected: _weekdays.contains(day),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _weekdays.add(day);
                      } else {
                        _weekdays.remove(day);
                      }
                    });
                  },
                );
              }),
            ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: _addSchedule,
            icon: const Icon(Icons.add),
            label: const Text('Thêm vào danh sách lịch'),
          ),
          const SizedBox(height: 24),
          Text(
            'Danh sách lịch (${_schedules.length})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          if (_schedules.isEmpty) const Text('Thuốc này chưa có lịch uống.'),
          ..._schedules.map(
            (schedule) => Card(
              child: ListTile(
                leading: const Icon(Icons.schedule),
                title: Text(_formatTime(schedule.hour, schedule.minute)),
                subtitle: Text(
                  '${_repeatLabel(schedule)}\n'
                  'Từ ${_formatDate(schedule.startDate)}'
                  '${schedule.endDate == null ? '' : ' đến ${_formatDate(schedule.endDate!)}'}',
                ),
                isThreeLine: true,
                trailing: IconButton(
                  tooltip: 'Bỏ lịch khỏi danh sách',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () {
                    setState(() {
                      _schedules.removeWhere((item) => item.id == schedule.id);
                    });
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.pop(context, _schedules),
            icon: const Icon(Icons.save_outlined),
            label: const Text('Lưu lịch uống'),
          ),
        ],
      ),
    );
  }
}
