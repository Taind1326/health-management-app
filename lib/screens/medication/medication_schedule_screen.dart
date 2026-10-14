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

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Dùng ngày lịch thay vì cộng 24 giờ để tránh lệch ngày
  // khi thiết bị ở múi giờ có đổi giờ mùa hè.
  DateTime _nextDay(DateTime date) {
    return DateTime(date.year, date.month, date.day + 1);
  }

  DateTime? _effectiveEnd(MedicationSchedule schedule) {
    if (schedule.repeat == MedicationRepeat.once) {
      return _dateOnly(schedule.startDate);
    }

    return schedule.endDate == null ? null : _dateOnly(schedule.endDate!);
  }

  bool _occursOn(MedicationSchedule schedule, DateTime day) {
    final date = _dateOnly(day);
    final start = _dateOnly(schedule.startDate);
    final end = _effectiveEnd(schedule);

    if (date.isBefore(start)) return false;
    if (end != null && date.isAfter(end)) return false;

    switch (schedule.repeat) {
      case MedicationRepeat.once:
        return date == start;
      case MedicationRepeat.daily:
        return true;
      case MedicationRepeat.selectedWeekdays:
        return schedule.weekdays.contains(date.weekday);
    }
  }

  bool _hasOccurrence(MedicationSchedule schedule) {
    var day = _dateOnly(schedule.startDate);
    final end = _effectiveEnd(schedule);

    // Lịch theo thứ lặp lại mỗi tuần: chỉ cần xét tối đa 7 ngày.
    for (var i = 0; i < 7; i++) {
      if (end != null && day.isAfter(end)) return false;
      if (_occursOn(schedule, day)) return true;

      day = _nextDay(day);
    }

    return false;
  }

  bool _overlaps(MedicationSchedule first, MedicationSchedule second) {
    if (first.medicationId != second.medicationId) return false;

    if (first.hour != second.hour || first.minute != second.minute) {
      return false;
    }

    final firstStart = _dateOnly(first.startDate);
    final secondStart = _dateOnly(second.startDate);

    // Bắt đầu khoảng giao nhau.
    var day = firstStart.isAfter(secondStart) ? firstStart : secondStart;

    final firstEnd = _effectiveEnd(first);
    final secondEnd = _effectiveEnd(second);

    // Kết thúc khoảng giao nhau; null nghĩa là không giới hạn.
    DateTime? end;

    if (firstEnd == null) {
      end = secondEnd;
    } else if (secondEnd == null) {
      end = firstEnd;
    } else {
      end = firstEnd.isBefore(secondEnd) ? firstEnd : secondEnd;
    }

    if (end != null && day.isAfter(end)) return false;

    // Trong khoảng giao nhau, xét tối đa một tuần.
    for (var i = 0; i < 7; i++) {
      if (end != null && day.isAfter(end)) return false;

      if (_occursOn(first, day) && _occursOn(second, day)) {
        return true;
      }

      day = _nextDay(day);
    }

    return false;
  }

  void _addSchedule() {
    if (_repeat == MedicationRepeat.selectedWeekdays && _weekdays.isEmpty) {
      _showMessage('Vui lòng chọn ít nhất một ngày trong tuần.');
      return;
    }

    final startDate = _dateOnly(_startDate);
    final endDate = _repeat == MedicationRepeat.once
        ? null
        : (_endDate == null ? null : _dateOnly(_endDate!));

    if (endDate != null && endDate.isBefore(startDate)) {
      _showMessage('Ngày kết thúc không được trước ngày bắt đầu.');
      return;
    }

    final scheduledAt = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
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

    final newSchedule = MedicationSchedule(
      id: 'schedule-${DateTime.now().microsecondsSinceEpoch}',
      medicationId: widget.medication.id,
      startDate: startDate,
      endDate: endDate,
      hour: _time.hour,
      minute: _time.minute,
      repeat: _repeat,
      weekdays: days,
    );

    if (!_hasOccurrence(newSchedule)) {
      _showMessage('Khoảng ngày đã chọn không có ngày uống phù hợp.');
      return;
    }

    final overlaps = _schedules.any(
      (existing) => _overlaps(existing, newSchedule),
    );

    if (overlaps) {
      _showMessage(
        'Thuốc này đã có lịch cùng giờ/phút '
        'vào ít nhất một ngày trong khoảng đã chọn.',
      );
      return;
    }

    setState(() {
      _schedules.add(newSchedule);
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
