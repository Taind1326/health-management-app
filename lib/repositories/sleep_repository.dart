import 'package:sqflite/sqflite.dart';

import '../models/sleep_record.dart';
import '../utils/database_helper.dart';

/// Lưu giấc ngủ vào SQLite. Mỗi tài khoản chỉ có một bản ghi cho mỗi wake_date.
class SleepRepository {
  final int userId;
  final Future<Database> Function() _open;

  SleepRepository(this.userId, {Future<Database> Function()? open})
      : _open = open ?? (() => DatabaseHelper().database);

  Future<List<SleepRecord>> getAll() async {
    final db = await _open();
    final rows = await db.query(
      'sleep_records',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'wake_time DESC, id DESC',
    );
    return rows.map((r) => SleepRecord.fromMap(r)).toList();
  }

  /// Lưu giấc ngủ; nếu đã có bản ghi cùng ngày thức dậy thì thay thế.
  Future<void> save(SleepRecord record) async {
    if (record.userId != userId) {
      throw ArgumentError('Giấc ngủ không thuộc tài khoản đang đăng nhập.');
    }
    final minutes = record.durationMinutes;
    if (minutes < 30 || minutes > 16 * 60) {
      throw ArgumentError('Thời gian ngủ phải từ 30 phút đến 16 giờ.');
    }
    final db = await _open();
    await db.transaction((txn) async {
      await txn.delete(
        'sleep_records',
        where: 'user_id = ? AND wake_date = ?',
        whereArgs: [userId, record.wakeDate],
      );
      await txn.insert('sleep_records', {
        ...record.toMap(),
        'user_id': userId,
      });
    });
  }

  Future<void> delete(int id) async {
    final db = await _open();
    final count = await db.delete(
      'sleep_records',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    if (count == 0) {
      throw StateError('Bản ghi giấc ngủ không còn tồn tại trong tài khoản.');
    }
  }
}