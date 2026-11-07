import '../models/medication_schedule.dart';

class MedicationRules {
  static DateTime day(DateTime d) => DateTime(d.year, d.month, d.day);
  static DateTime at(MedicationSchedule s, DateTime d) =>
      DateTime(d.year, d.month, d.day, s.hour, s.minute);
  static bool occursOn(MedicationSchedule s, DateTime d) {
    final date = day(d), start = day(s.startDate);
    if (date.isBefore(start) ||
        (s.endDate != null && date.isAfter(day(s.endDate!))))
      return false;
    switch (s.repeat) {
      case MedicationRepeat.once:
        return date == start;
      case MedicationRepeat.daily:
        return true;
      case MedicationRepeat.selectedWeekdays:
        return s.weekdays.contains(date.weekday);
    }
  }

  static DateTime? end(MedicationSchedule s) =>
      s.repeat == MedicationRepeat.once
      ? day(s.startDate)
      : s.endDate == null
      ? null
      : day(s.endDate!);
  static bool overlaps(MedicationSchedule a, MedicationSchedule b) {
    if (a.medicationId != b.medicationId ||
        a.hour != b.hour ||
        a.minute != b.minute)
      return false;
    var d = day(a.startDate.isAfter(b.startDate) ? a.startDate : b.startDate);
    final ae = end(a), be = end(b);
    final last = ae == null
        ? be
        : be == null
        ? ae
        : ae.isBefore(be)
        ? ae
        : be;
    for (var i = 0; i < 7; i++, d = DateTime(d.year, d.month, d.day + 1)) {
      if (last != null && d.isAfter(last)) return false;
      if (occursOn(a, d) && occursOn(b, d)) return true;
    }
    return false;
  }

  static void validateSchedule(MedicationSchedule s) {
    if (s.hour < 0 ||
        s.hour > 23 ||
        s.minute < 0 ||
        s.minute > 59 ||
        (s.endDate != null && day(s.endDate!).isBefore(day(s.startDate))) ||
        s.weekdays.any((d) => d < 1 || d > 7) ||
        s.weekdays.toSet().length != s.weekdays.length ||
        (s.repeat != MedicationRepeat.selectedWeekdays &&
            s.weekdays.isNotEmpty))
      throw ArgumentError('Ngày giờ hoặc cách lặp không hợp lệ.');
    var d = day(s.startDate);
    for (var i = 0; i < 7; i++, d = DateTime(d.year, d.month, d.day + 1)) {
      if (occursOn(s, d)) return;
    }
    throw ArgumentError('Khoảng áp dụng không có lần uống nào.');
  }

  /// Đếm cả lần đã đến hạn hôm nay nhưng chưa xác nhận. Không tính taken/skipped.
  /// Cửa sổ 7 ngày để không giả định người dùng phải dùng thuốc vô thời hạn.
  static int remainingSevenDays(
    List<MedicationSchedule> schedules,
    List<Map<String, Object?>> logs,
    DateTime now,
  ) {
    var count = 0;
    for (final s in schedules.where((s) => s.isEnabled)) {
      for (var i = 0; i < 7; i++) {
        final d = DateTime(now.year, now.month, now.day + i);
        if (!occursOn(s, d)) continue;
        final stamp = at(s, d).toIso8601String();
        if (!logs.any(
          (l) => l['schedule_id'] == s.id && l['scheduled_at'] == stamp,
        ))
          count++;
      }
    }
    return count;
  }

  static String courseLabel(List<MedicationSchedule> schedules, DateTime now) {
    final active = schedules.where((s) => s.isEnabled).toList();
    if (active.isEmpty) return 'Chưa có lịch đang bật';
    if (active.every((s) => end(s) != null && at(s, end(s)!).isBefore(now))) {
      return 'Đã đến thời điểm kết thúc các lịch đã nhập';
    }
    return 'Theo dõi theo lịch đã nhập';
  }
}
