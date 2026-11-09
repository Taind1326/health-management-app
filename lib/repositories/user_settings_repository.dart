import 'package:sqflite/sqflite.dart';

import '../utils/database_helper.dart';

class UserSettings {
  final int stepGoal;
  final int activityGoalMinutes;
  final int sleepGoalMinutes;

  const UserSettings({
    required this.stepGoal,
    required this.activityGoalMinutes,
    required this.sleepGoalMinutes,
  });
}

/// Mục tiêu theo từng tài khoản, lưu trong bảng user_settings.
class UserSettingsRepository {
  final int userId;
  final Future<Database> Function() _open;

  UserSettingsRepository(this.userId, {Future<Database> Function()? open})
      : _open = open ?? (() => DatabaseHelper().database);

  Future<UserSettings> get() async {
    final db = await _open();
    await DatabaseHelper.ensureUserSettings(db, userId);
    final rows = await db.query(
      'user_settings',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    final row = rows.first;
    return UserSettings(
      stepGoal: (row['step_goal'] as num).toInt(),
      activityGoalMinutes: (row['activity_goal_minutes'] as num).toInt(),
      sleepGoalMinutes: (row['sleep_goal_minutes'] as num).toInt(),
    );
  }

  /// Chỉ cập nhật các mục tiêu được truyền vào, giữ nguyên phần còn lại.
  Future<void> update({
    int? stepGoal,
    int? activityGoalMinutes,
    int? sleepGoalMinutes,
  }) async {
    final values = <String, Object?>{
      if (stepGoal != null) 'step_goal': stepGoal,
      if (activityGoalMinutes != null)
        'activity_goal_minutes': activityGoalMinutes,
      if (sleepGoalMinutes != null) 'sleep_goal_minutes': sleepGoalMinutes,
    };
    if (values.isEmpty) return;
    if (values.values.any((v) => v is int && v <= 0)) {
      throw ArgumentError('Mục tiêu phải lớn hơn 0.');
    }
    final db = await _open();
    await DatabaseHelper.ensureUserSettings(db, userId);
    await db.update(
      'user_settings',
      values,
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }
}