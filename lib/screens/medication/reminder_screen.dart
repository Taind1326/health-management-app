import 'package:flutter/material.dart';

import '../../models/medication_schedule.dart';
import '../../models/reminder.dart';

String _typeLabel(ReminderType type) {
  switch (type) {
    case ReminderType.medication:
      return 'Uống thuốc';
    case ReminderType.water:
      return 'Uống nước';
    case ReminderType.activity:
      return 'Vận động';
    case ReminderType.sleep:
      return 'Đi ngủ';
    case ReminderType.healthMetric:
      return 'Cập nhật chỉ số';
  }
}

String _timeLabel(int hour, int minute) {
  return '${hour.toString().padLeft(2, '0')}:'
      '${minute.toString().padLeft(2, '0')}';
}

String _dateLabel(DateTime date) {
  return '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';
}

String _weekdayLabel(int day) => day == 7 ? 'CN' : 'T${day + 1}';

String _repeatLabel(ReminderRepeat repeat, List<int> weekdays) {
  switch (repeat) {
    case ReminderRepeat.once:
      return 'Một lần';
    case ReminderRepeat.daily:
      return 'Hằng ngày';
    case ReminderRepeat.selectedWeekdays:
      final days = List<int>.of(weekdays)..sort();
      return days.map(_weekdayLabel).join(', ');
  }
}

ReminderRepeat _reminderRepeat(MedicationRepeat repeat) {
  switch (repeat) {
    case MedicationRepeat.once:
      return ReminderRepeat.once;
    case MedicationRepeat.daily:
      return ReminderRepeat.daily;
    case MedicationRepeat.selectedWeekdays:
      return ReminderRepeat.selectedWeekdays;
  }
}

String _scheduleDescription(MedicationSchedule schedule) {
  return 'Giờ nhắc: ${_timeLabel(schedule.hour, schedule.minute)}\n'
      'Lặp lại: ${_repeatLabel(_reminderRepeat(schedule.repeat), schedule.weekdays)}\n'
      'Bắt đầu: ${_dateLabel(schedule.startDate)}'
      '${schedule.endDate == null ? '' : '\nKết thúc: ${_dateLabel(schedule.endDate!)}'}';
}

class ReminderScreen extends StatefulWidget {
  final List<Reminder> reminders;
  final Map<String, String> medicationSchedules;
  final Map<String, MedicationSchedule> scheduleDetails;
  final ValueChanged<List<Reminder>> onChanged;

  const ReminderScreen({
    super.key,
    required this.reminders,
    required this.medicationSchedules,
    required this.scheduleDetails,
    required this.onChanged,
  });

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  late final List<Reminder> _reminders;

  @override
  void initState() {
    super.initState();
    _reminders = List.of(widget.reminders);
  }

  void _notifyParent() {
    widget.onChanged(List.of(_reminders));
  }

  Future<void> _openForm({Reminder? reminder}) async {
    final result = await Navigator.push<Reminder>(
      context,
      MaterialPageRoute<Reminder>(
        builder: (context) => _ReminderFormScreen(
          reminder: reminder,
          medicationSchedules: widget.medicationSchedules,
          scheduleDetails: widget.scheduleDetails,
        ),
      ),
    );

    if (!mounted || result == null) return;

    final duplicate = _reminders.any(
      (item) =>
          item.id != result.id &&
          item.type == ReminderType.medication &&
          result.type == ReminderType.medication &&
          item.medicationScheduleId == result.medicationScheduleId,
    );

    if (duplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Lịch uống này đã có nhắc nhở. '
            'Hãy sửa nhắc nhở hiện có.',
          ),
        ),
      );
      return;
    }

    setState(() {
      final index = _reminders.indexWhere((item) => item.id == result.id);

      if (index == -1) {
        _reminders.add(result);
      } else {
        _reminders[index] = result;
      }
    });

    _notifyParent();
  }

  void _toggleReminder(Reminder reminder, bool enabled) {
    final schedule = widget.scheduleDetails[reminder.medicationScheduleId];

    if (enabled &&
        reminder.type == ReminderType.medication &&
        (schedule == null || !schedule.isEnabled)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lịch uống không tồn tại hoặc đang tắt.')),
      );
      return;
    }

    final updated = Reminder(
      id: reminder.id,
      userId: reminder.userId,
      title: reminder.title,
      type: reminder.type,
      startDate: reminder.startDate,
      endDate: reminder.endDate,
      hour: reminder.hour,
      minute: reminder.minute,
      repeat: reminder.repeat,
      weekdays: reminder.weekdays,
      isEnabled: enabled,
      medicationScheduleId: reminder.medicationScheduleId,
    );

    setState(() {
      final index = _reminders.indexWhere((item) => item.id == reminder.id);
      if (index != -1) _reminders[index] = updated;
    });

    _notifyParent();
  }

  Future<void> _deleteReminder(Reminder reminder) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa nhắc nhở'),
        content: Text('Bạn muốn xóa "${reminder.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    setState(() {
      _reminders.removeWhere((item) => item.id == reminder.id);
    });

    _notifyParent();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nhắc nhở')),
      body: _reminders.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Bạn chưa tạo nhắc nhở nào.\n'
                  'Bấm “Thêm nhắc nhở” để bắt đầu.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: _reminders.map((reminder) {
                final linkedLabel =
                    widget.medicationSchedules[reminder.medicationScheduleId];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                reminder.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Switch(
                              value: reminder.isEnabled,
                              onChanged: (value) =>
                                  _toggleReminder(reminder, value),
                            ),
                          ],
                        ),
                        Text(
                          '${_typeLabel(reminder.type)} • '
                          '${_timeLabel(reminder.hour, reminder.minute)}',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_repeatLabel(reminder.repeat, reminder.weekdays)}'
                          ' • ${reminder.isEnabled ? 'Đang bật' : 'Đã tắt'}',
                        ),
                        const SizedBox(height: 4),
                        Text('Bắt đầu: ${_dateLabel(reminder.startDate)}'),
                        if (reminder.endDate != null) ...[
                          const SizedBox(height: 4),
                          Text('Kết thúc: ${_dateLabel(reminder.endDate!)}'),
                        ],
                        if (reminder.type == ReminderType.medication) ...[
                          const SizedBox(height: 4),
                          Text(
                            linkedLabel == null
                                ? 'Lịch thuốc không còn tồn tại.'
                                : 'Lịch thuốc: $linkedLabel',
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            TextButton.icon(
                              onPressed: () => _openForm(reminder: reminder),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Sửa'),
                            ),
                            TextButton.icon(
                              onPressed: () => _deleteReminder(reminder),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Xóa'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Thêm nhắc nhở'),
      ),
    );
  }
}

class _ReminderFormScreen extends StatefulWidget {
  final Reminder? reminder;
  final Map<String, String> medicationSchedules;
  final Map<String, MedicationSchedule> scheduleDetails;

  const _ReminderFormScreen({
    this.reminder,
    required this.medicationSchedules,
    required this.scheduleDetails,
  });

  @override
  State<_ReminderFormScreen> createState() => _ReminderFormScreenState();
}

class _ReminderFormScreenState extends State<_ReminderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late ReminderType _type;
  late TimeOfDay _time;
  String? _scheduleId;

  @override
  void initState() {
    super.initState();

    final reminder = widget.reminder;

    _titleController = TextEditingController(text: reminder?.title ?? '');
    _type = reminder?.type ?? ReminderType.water;
    _time = TimeOfDay(hour: reminder?.hour ?? 8, minute: reminder?.minute ?? 0);

    final existingId = reminder?.medicationScheduleId;

    _scheduleId =
        widget.medicationSchedules.containsKey(existingId) &&
            widget.scheduleDetails.containsKey(existingId)
        ? existingId
        : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);

    if (!mounted || selected == null) return;
    setState(() => _time = selected);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final isMedication = _type == ReminderType.medication;
    final schedule = isMedication ? widget.scheduleDetails[_scheduleId] : null;

    if (isMedication && schedule == null) {
      _showMessage('Vui lòng chọn lịch uống thuốc hợp lệ.');
      return;
    }

    if (schedule != null && !schedule.isEnabled) {
      _showMessage('Lịch uống đang tắt. Hãy chọn lịch đang bật.');
      return;
    }

    final now = DateTime.now();
    final today = DateUtils.dateOnly(now);

    if (schedule != null) {
      final end = schedule.endDate;

      if (end != null && DateUtils.dateOnly(end).isBefore(today)) {
        _showMessage('Lịch uống đã kết thúc.');
        return;
      }

      if (schedule.repeat == MedicationRepeat.once) {
        final scheduledAt = DateTime(
          schedule.startDate.year,
          schedule.startDate.month,
          schedule.startDate.day,
          schedule.hour,
          schedule.minute,
        );

        if (!scheduledAt.isAfter(now)) {
          _showMessage('Lịch uống một lần đã qua.');
          return;
        }
      }
    }

    final existing = widget.reminder;
    final keepStartDate = existing != null && existing.type == _type;

    final reminder = Reminder(
      id: existing?.id ?? 'reminder-${now.microsecondsSinceEpoch}',
      userId: existing?.userId ?? 'demo-user',
      title: _titleController.text.trim().replaceAll(RegExp(r'\s+'), ' '),
      type: _type,
      startDate:
          schedule?.startDate ?? (keepStartDate ? existing.startDate : today),
      endDate: schedule?.endDate,
      hour: schedule?.hour ?? _time.hour,
      minute: schedule?.minute ?? _time.minute,
      repeat: schedule == null
          ? ReminderRepeat.daily
          : _reminderRepeat(schedule.repeat),
      weekdays: schedule?.weekdays ?? const [],
      isEnabled: existing?.isEnabled ?? true,
      medicationScheduleId: isMedication ? schedule!.id : null,
    );

    Navigator.pop(context, reminder);
  }

  @override
  Widget build(BuildContext context) {
    final selectedSchedule = widget.scheduleDetails[_scheduleId];

    final availableSchedules = widget.medicationSchedules.entries
        .where((entry) => widget.scheduleDetails.containsKey(entry.key))
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.reminder == null ? 'Thêm nhắc nhở' : 'Sửa nhắc nhở'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Nội dung nhắc nhở',
                  hintText: 'Ví dụ: Uống một cốc nước',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final title = value?.trim() ?? '';

                  if (title.isEmpty) {
                    return 'Vui lòng nhập nội dung nhắc nhở.';
                  }

                  if (!RegExp(r'\p{L}', unicode: true).hasMatch(title)) {
                    return 'Nội dung phải có ít nhất một chữ cái.';
                  }

                  return null;
                },
              ),
              const SizedBox(height: 16),
              const Text('Loại nhắc nhở'),
              DropdownButton<ReminderType>(
                value: _type,
                isExpanded: true,
                items: ReminderType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_typeLabel(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _type = value;

                    if (value != ReminderType.medication) {
                      _scheduleId = null;
                    }
                  });
                },
              ),
              if (_type == ReminderType.medication) ...[
                const SizedBox(height: 16),
                if (availableSchedules.isEmpty)
                  const Text(
                    'Chưa có lịch uống thuốc. '
                    'Hãy quay lại tạo lịch uống trước.',
                  )
                else
                  DropdownButton<String>(
                    value: _scheduleId,
                    hint: const Text('Chọn lịch uống thuốc'),
                    isExpanded: true,
                    items: availableSchedules.map((entry) {
                      return DropdownMenuItem(
                        value: entry.key,
                        child: Text(
                          entry.value,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _scheduleId = value);
                    },
                  ),
              ],
              const SizedBox(height: 16),
              if (_type == ReminderType.medication) ...[
                if (selectedSchedule != null)
                  Text(_scheduleDescription(selectedSchedule))
                else
                  const Text('Chọn lịch uống để xem thời gian nhắc.'),
              ] else ...[
                OutlinedButton.icon(
                  onPressed: _pickTime,
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    'Giờ nhắc: ${_timeLabel(_time.hour, _time.minute)}',
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Lặp lại: hằng ngày'),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Lưu nhắc nhở'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
