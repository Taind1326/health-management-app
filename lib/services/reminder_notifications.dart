import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/medication_schedule.dart';
import '../models/reminder.dart';
import '../repositories/medication_repository.dart';
import 'auth_service.dart';
import 'medication_rules.dart';

/// SQLite là nguồn lịch chính. Android giữ các mốc đã lên lịch khi app đóng.
class ReminderNotifications {
  ReminderNotifications._();
  static final instance = ReminderNotifications._();

  static const horizonDays = 14;
  static const maxPending = 120;
  static const _tag = 'health_app_reminder:';
  final _plugin = FlutterLocalNotificationsPlugin();
  Future<void> _tail = Future.value();
  bool _initialized = false;

  bool get supported =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin
      >();

  Future<void> _init() async {
    if (_initialized) return;
    await _plugin.initialize(
      const InitializationSettings(
        android: AndroidInitializationSettings('ic_health_reminder'),
      ),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    if (!supported) return false;
    await _init();
    return await _android?.requestNotificationsPermission() ?? false;
  }

  Future<void> _enqueue(Future<void> Function() work) {
    final result = _tail.then((_) => work());
    _tail = result.then<void>((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }

  Future<void> _clear() async {
    for (final item in await _plugin.pendingNotificationRequests()) {
      if (item.payload?.startsWith(_tag) == true) {
        await _plugin.cancel(item.id);
      }
    }
  }

  Future<void> clear() async {
    if (!supported) return;
    await _enqueue(() async {
      await _init();
      await _clear();
    });
  }

  Future<void> syncQuietly(int userId) async {
    try {
      await sync(userId);
    } catch (e) {
      debugPrint('Không thể đồng bộ lịch nhắc: $e');
    }
  }

  Future<void> sync(int userId) async {
    if (!supported) return;
    await _enqueue(() async {
      if (AuthService().currentUser?.id != userId) return;
      await _init();
      if (await _android?.areNotificationsEnabled() != true) {
        await _clear();
        return;
      }
      final repo = MedicationRepository(userId);
      final reminders = await repo.reminders();
      final schedules = await repo.schedules();
      if (AuthService().currentUser?.id != userId) return;
      final times = notificationTimes(
        reminders,
        schedules,
        DateTime.now(),
      ).take(maxPending);
      final desired = {
        for (final time in times)
          '$_tag$userId:${time.millisecondsSinceEpoch}': time,
      };
      final occupied = <int>{};
      for (final item in await _plugin.pendingNotificationRequests()) {
        final payload = item.payload;
        if (payload?.startsWith(_tag) != true) {
          occupied.add(item.id);
        } else if (desired.remove(payload) != null) {
          occupied.add(item.id);
        } else {
          await _plugin.cancel(item.id);
        }
      }
      var id = 780000;
      for (final entry in desired.entries) {
        if (AuthService().currentUser?.id != userId) break;
        if (!entry.value.isAfter(DateTime.now())) continue;
        while (occupied.contains(id)) {
          id++;
        }
        await _plugin.zonedSchedule(
          id++,
          'Nhắc sức khỏe',
          'Mở Quản lý sức khỏe để xem lịch nhắc.',
          tz.TZDateTime.from(entry.value, tz.UTC),
          const NotificationDetails(
            android: AndroidNotificationDetails(
              'health_reminders',
              'Nhắc sức khỏe',
              channelDescription: 'Thông báo từ lịch nhắc sức khỏe',
              importance: Importance.high,
              priority: Priority.high,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: entry.key,
        );
      }
    });
  }

  /// Gộp các lịch cùng thời điểm thành một thông báo chung.
  static List<DateTime> notificationTimes(
    List<Reminder> reminders,
    List<MedicationSchedule> schedules,
    DateTime now,
  ) {
    final byId = {for (final schedule in schedules) schedule.id: schedule};
    final times = <DateTime>{};
    for (final reminder in reminders.where((r) => r.isEnabled)) {
      final linked = byId[reminder.medicationScheduleId];
      if (reminder.type == ReminderType.medication &&
          (linked == null || !linked.isEnabled)) {
        continue;
      }
      final schedule =
          linked ??
          MedicationSchedule(
            id: reminder.id,
            medicationId: '',
            startDate: reminder.startDate,
            endDate: reminder.endDate,
            hour: reminder.hour,
            minute: reminder.minute,
            repeat: switch (reminder.repeat) {
              ReminderRepeat.once => MedicationRepeat.once,
              ReminderRepeat.daily => MedicationRepeat.daily,
              ReminderRepeat.selectedWeekdays =>
                MedicationRepeat.selectedWeekdays,
            },
            weekdays: reminder.weekdays,
          );
      for (var i = 0; i < horizonDays; i++) {
        final day = DateTime(now.year, now.month, now.day + i);
        if (!MedicationRules.occursOn(schedule, day)) continue;
        final time = MedicationRules.at(schedule, day);
        if (time.isAfter(now)) times.add(time);
      }
    }
    return times.toList()..sort();
  }
}
