/// Một đêm ngủ: giờ đi ngủ và giờ thức dậy.
class SleepRecord {
  final int? id; // null khi chưa lưu vào SQLite (đợt 2)
  final int userId;
  final DateTime sleepTime;
  final DateTime wakeTime;

  const SleepRecord({
    this.id,
    required this.userId,
    required this.sleepTime,
    required this.wakeTime,
  });

  /// Tổng thời gian ngủ (phút).
  int get durationMinutes => wakeTime.difference(sleepTime).inMinutes;

  /// Giấc ngủ được tính cho ngày thức dậy.
  bool isOn(DateTime day) =>
      wakeTime.year == day.year &&
      wakeTime.month == day.month &&
      wakeTime.day == day.day;

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'sleep_time': sleepTime.toIso8601String(),
        'wake_time': wakeTime.toIso8601String(),
      };

  factory SleepRecord.fromMap(Map<String, dynamic> map) => SleepRecord(
        id: map['id'] as int?,
        userId: map['user_id'] as int,
        sleepTime: DateTime.parse(map['sleep_time'] as String),
        wakeTime: DateTime.parse(map['wake_time'] as String),
      );
}