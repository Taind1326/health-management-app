import '../../models/activity.dart';

/// Dữ liệu mẫu cho prototype đợt 1 (tính theo ngày hiện tại).
/// Đợt 2: thay bằng dữ liệu đọc từ SQLite qua repository.
List<Activity> buildSampleActivities() {
  final now = DateTime.now();
  DateTime at(int daysAgo, int h, int m) =>
      DateTime(now.year, now.month, now.day - daysAgo, h, m);

  Activity a(int daysAgo, int h, String type, int steps, double km, int min,
          int kcal) =>
      Activity(
        userId: 1,
        type: type,
        date: at(daysAgo, h, 0),
        steps: steps,
        distanceKm: km,
        durationMinutes: min,
        calories: kcal,
      );

  return [
    a(0, 6, 'Chạy bộ', 3800, 3.0, 25, 220),
    a(0, 12, 'Đi bộ', 2400, 1.8, 20, 90),
    a(1, 17, 'Đi bộ', 9200, 6.9, 75, 340),
    a(2, 6, 'Chạy bộ', 7600, 5.5, 45, 410),
    a(3, 18, 'Đạp xe', 1200, 12.0, 50, 380),
    a(3, 7, 'Đi bộ', 5400, 4.0, 40, 180),
    a(4, 19, 'Yoga', 800, 0.0, 40, 130),
    a(5, 6, 'Đi bộ', 11200, 8.4, 90, 420),
    a(6, 17, 'Chạy bộ', 6800, 5.0, 38, 360),
  ];
}