/// Một lần ghi nhận hoạt động thể chất của người dùng.
class Activity {
  static const List<String> types = [
    'Đi bộ',
    'Chạy bộ',
    'Đạp xe',
    'Bơi lội',
    'Yoga',
    'Khác',
  ];

  final int? id; // null khi chưa lưu vào SQLite (đợt 2)
  final int userId;
  final String type;
  final DateTime date;
  final int steps;
  final double distanceKm;
  final int durationMinutes;
  final int calories;

  const Activity({
    this.id,
    required this.userId,
    required this.type,
    required this.date,
    required this.steps,
    required this.distanceKm,
    required this.durationMinutes,
    required this.calories,
  });

  /// Hoạt động có diễn ra trong ngày [day] không.
  bool isOn(DateTime day) =>
      date.year == day.year && date.month == day.month && date.day == day.day;

  Map<String, dynamic> toMap() => {
        'id': id,
        'user_id': userId,
        'type': type,
        'date': date.toIso8601String(),
        'steps': steps,
        'distance_km': distanceKm,
        'duration_minutes': durationMinutes,
        'calories': calories,
      };

  factory Activity.fromMap(Map<String, dynamic> map) => Activity(
        id: map['id'] as int?,
        userId: map['user_id'] as int,
        type: map['type'] as String,
        date: DateTime.parse(map['date'] as String),
        steps: map['steps'] as int,
        distanceKm: (map['distance_km'] as num).toDouble(),
        durationMinutes: map['duration_minutes'] as int,
        calories: map['calories'] as int,
      );
}