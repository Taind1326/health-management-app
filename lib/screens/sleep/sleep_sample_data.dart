import '../../models/sleep_record.dart';

/// Dữ liệu mẫu cho prototype đợt 1 (7 đêm gần nhất, tính theo ngày hiện tại).
/// Đợt 2: thay bằng dữ liệu đọc từ SQLite qua repository.
List<SleepRecord> buildSampleSleepRecords() {
  final now = DateTime.now();

  // (giờ ngủ, phút ngủ, giờ thức, phút thức) cho từng ngày thức dậy, từ hôm nay lùi về.
  const nights = [
    [23, 15, 6, 30],
    [0, 10, 6, 45],
    [22, 50, 5, 55],
    [23, 40, 7, 10],
    [1, 5, 7, 0],
    [23, 0, 6, 20],
    [22, 30, 6, 15],
  ];

  return List.generate(nights.length, (i) {
    final n = nights[i];
    final wake = DateTime(now.year, now.month, now.day - i, n[2], n[3]);
    var sleep = DateTime(now.year, now.month, now.day - i, n[0], n[1]);
    if (!sleep.isBefore(wake)) sleep = sleep.subtract(const Duration(days: 1));
    return SleepRecord(userId: 1, sleepTime: sleep, wakeTime: wake);
  });
}