enum MedicationRepeat { once, daily, selectedWeekdays }

class MedicationSchedule {
  final String id;
  final String medicationId;
  final DateTime startDate;
  final DateTime? endDate;
  final int hour;
  final int minute;
  final MedicationRepeat repeat;
  final List<int> weekdays;
  final bool isEnabled;

  MedicationSchedule({
    required this.id,
    required this.medicationId,
    required this.startDate,
    this.endDate,
    required this.hour,
    required this.minute,
    this.repeat = MedicationRepeat.daily,
    List<int> weekdays = const [],
    this.isEnabled = true,
  }) : weekdays = List.unmodifiable(weekdays);
}
