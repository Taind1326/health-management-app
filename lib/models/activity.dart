/// Một lần ghi nhận hoạt động thể chất của người dùng.
/// `type` lưu bằng mã (walking/running/cycling/other), hiển thị bằng [typeLabel].
class Activity {
  static const List<String> types = ['walking', 'running', 'cycling', 'other'];

  static const Map<String, String> typeLabels = {
    'walking': 'Đi bộ',
    'running': 'Chạy bộ',
    'cycling': 'Đạp xe',
    'other': 'Khác',
  };

  static String labelOf(String type) =>
      typeLabels[type] ?? typeLabels['other']!;

  final int? id; // null khi chưa lưu vào SQLite
  final int userId;
  final String type; // mã loại hoạt động
  final DateTime date;
  final int steps;
  final double distanceKm;
  final int durationMinutes;
  final int calories;
  final String? origin;
  final String? destination;

  const Activity({
    this.id,
    required this.userId,
    required this.type,
    required this.date,
    required this.steps,
    required this.distanceKm,
    required this.durationMinutes,
    required this.calories,
    required this.origin,
    required this.destination,
  });

  String get typeLabel => labelOf(type);

  /// Hoạt động có diễn ra trong ngày [day] không.
  bool isOn(DateTime day) =>
      date.year == day.year && date.month == day.month && date.day == day.day;

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'type': type,
        'recorded_at': date.toIso8601String(),
        'steps': steps,
        'distance_km': distanceKm,
        'duration_minutes': durationMinutes,
        'calories': calories,
        'origin': origin,
        'destination': destination,
      };

  factory Activity.fromMap(Map<String, dynamic> map) {
    final rawType = map['type'] as String? ?? 'other';
    return Activity(
      id: map['id'] as int?,
      userId: map['user_id'] as int,
      type: types.contains(rawType) ? rawType : 'other',
      date: DateTime.parse(map['recorded_at'] as String),
      steps: (map['steps'] as num).toInt(),
      distanceKm: (map['distance_km'] as num).toDouble(),
      durationMinutes: (map['duration_minutes'] as num).toInt(),
      calories: (map['calories'] as num).toInt(),
      origin: map['origin'] as String?,
      destination: map['destination'] as String?,
    );
  }
}