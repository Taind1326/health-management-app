import 'package:sqflite/sqflite.dart';

import '../models/activity.dart';
import '../utils/database_helper.dart';

/// Lưu hoạt động vào SQLite. Mọi truy vấn đều lọc theo user_id của tài khoản.
class ActivityRepository {
  final int userId;
  final Future<Database> Function() _open;

  ActivityRepository(this.userId, {Future<Database> Function()? open})
      : _open = open ?? (() => DatabaseHelper().database);

  static void validate(Activity a) {
    if (!Activity.types.contains(a.type)) {
      throw ArgumentError('Loại hoạt động không hợp lệ.');
    }
    if (a.steps < 0 ||
        !a.distanceKm.isFinite ||
        a.distanceKm < 0 ||
        a.durationMinutes <= 0 ||
        a.calories < 0) {
      throw ArgumentError('Số liệu hoạt động không hợp lệ.');
    }
    if (a.type == 'cycling' && a.steps != 0) {
      throw ArgumentError('Đạp xe không có số bước.');
    }
  }

  Future<List<Activity>> getAll() async {
    final db = await _open();
    final rows = await db.query(
      'activities',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'recorded_at DESC, id DESC',
    );
    return rows.map((r) => Activity.fromMap(r)).toList();
  }

  /// Thêm hoạt động cho tài khoản hiện tại. Trả về id vừa tạo.
  Future<int> add(Activity activity) async {
    if (activity.userId != userId) {
      throw ArgumentError('Hoạt động không thuộc tài khoản đang đăng nhập.');
    }
    validate(activity);
    final db = await _open();
    return db.insert('activities', {...activity.toMap(), 'user_id': userId});
  }

  Future<void> delete(int id) async {
    final db = await _open();
    final count = await db.delete(
      'activities',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    if (count == 0) {
      throw StateError('Hoạt động không còn tồn tại trong tài khoản.');
    }
  }
}