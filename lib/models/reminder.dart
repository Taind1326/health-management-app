enum ReminderType { medication, water, activity, sleep, healthMetric }

enum ReminderRepeat { once, daily, selectedWeekdays }

class Reminder {
  final String id;
  final String userId;
  final String title;
  final ReminderType type;
  final DateTime startDate;
  final DateTime? endDate;
  final int hour;
  final int minute;
  final ReminderRepeat repeat;
  final List<int> weekdays;
  final bool isEnabled;
  final String? medicationScheduleId;

  Reminder({
    required this.id,
    required this.userId,
    required this.title,
    required this.type,
    required this.startDate,
    this.endDate,
    required this.hour,
    required this.minute,
    this.repeat = ReminderRepeat.daily,
    List<int> weekdays = const [],
    this.isEnabled = true,
    this.medicationScheduleId,
  }) : weekdays = List.unmodifiable(weekdays);
}
