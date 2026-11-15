import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/models/medication_schedule.dart';
import 'package:health_app/models/reminder.dart';
import 'package:health_app/services/reminder_notifications.dart';

void main() {
  final now = DateTime(2026, 11, 16, 9); // Thứ Hai.
  Reminder reminder(
    String id, {
    String? link,
    bool enabled = true,
    int hour = 8,
    DateTime? start,
    DateTime? end,
  }) => Reminder(
    id: id,
    userId: 1,
    title: id,
    type: link == null ? ReminderType.water : ReminderType.medication,
    startDate: start ?? now,
    endDate: end,
    hour: hour,
    minute: 0,
    isEnabled: enabled,
    medicationScheduleId: link,
  );

  test('chỉ lấy ngày còn hiệu lực, giờ tương lai và gộp mốc trùng', () {
    final end = DateTime(2026, 11, 18);
    final times = ReminderNotifications.notificationTimes(
      [
        reminder('a', end: end),
        reminder('b', end: end),
        reminder('disabled', enabled: false, hour: 15),
        reminder('missing', link: 'deleted'),
      ],
      [],
      now,
    );
    expect(times, [DateTime(2026, 11, 17, 8), DateTime(2026, 11, 18, 8)]);
  });

  test('nhắc thuốc dùng giờ và thứ từ lịch liên kết', () {
    final schedule = MedicationSchedule(
      id: 's',
      medicationId: 'm',
      startDate: now,
      endDate: DateTime(2026, 11, 22),
      hour: 10,
      minute: 30,
      repeat: MedicationRepeat.selectedWeekdays,
      weekdays: [1, 3],
    );
    expect(
      ReminderNotifications.notificationTimes(
        [reminder('med', link: 's')],
        [schedule],
        now,
      ),
      [DateTime(2026, 11, 16, 10, 30), DateTime(2026, 11, 18, 10, 30)],
    );
  });

  test('giới hạn trong 14 ngày lịch, tính cả hôm nay', () {
    final times = ReminderNotifications.notificationTimes(
      [
        reminder('daily', hour: 11),
        reminder('later', hour: 13, start: DateTime(2026, 12, 1)),
      ],
      [],
      now,
    );
    expect(times.length, 14);
    expect(times.last, DateTime(2026, 11, 29, 11));
  });
}
