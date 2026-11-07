import 'package:flutter/foundation.dart';

import '../models/water_record.dart';
import '../utils/database_helper.dart';

class WaterController extends ChangeNotifier {
  WaterController._();

  static final WaterController instance =
      WaterController._();

  final DatabaseHelper _databaseHelper = DatabaseHelper();

  int? _userId;
  int waterGoalMl = 2000;
  int todayWaterTotalMl = 0;

  bool _isLoading = false;
  String? _error;

  List<WaterRecord> _waterHistory = [];

  bool get isLoading => _isLoading;

  String? get error => _error;

  int? get currentUserId => _userId;

  List<WaterRecord> get waterHistory =>
      List.unmodifiable(_waterHistory);

  void _validateUserId(int userId) {
    if (userId <= 0) {
      throw ArgumentError('User ID không hợp lệ.');
    }
  }

  Future<void> initialize(int userId) async {
    _validateUserId(userId);

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final db = await _databaseHelper.database;

      final userRows = await db.query(
        'users',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      if (userRows.isEmpty) {
        throw StateError(
          'Tài khoản chưa được đồng bộ với SQLite. '
          'Cần tích hợp phần đăng nhập trước khi lưu dữ liệu.',
        );
      }

      await DatabaseHelper.ensureUserSettings(db, userId);

      final settingRows = await db.query(
        'user_settings',
        columns: ['water_goal_ml'],
        where: 'user_id = ?',
        whereArgs: [userId],
        limit: 1,
      );

      final historyRows = await db.query(
        'water_records',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'recorded_at DESC',
      );

      _userId = userId;

      waterGoalMl = settingRows.isEmpty
          ? 2000
          : (settingRows.first['water_goal_ml'] as num)
              .toInt();

      _waterHistory = historyRows
          .map((row) => WaterRecord.fromMap(row))
          .toList();

      _calculateTodayTotal();
    } catch (e) {
      _error = e.toString();
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _calculateTodayTotal() {
    final now = DateTime.now();

    todayWaterTotalMl = _waterHistory
        .where((record) {
          final date = record.recordedAt;

          return date.year == now.year &&
              date.month == now.month &&
              date.day == now.day;
        })
        .fold<int>(
          0,
          (total, record) => total + record.amountMl,
        );
  }

  Future<WaterRecord> addWater(int amountMl) async {
    final userId = _userId;

    if (userId == null) {
      throw StateError(
        'WaterController chưa được khởi tạo.',
      );
    }

    if (amountMl <= 0) {
      throw ArgumentError(
        'Lượng nước phải lớn hơn 0.',
      );
    }

    final date = DateTime.now();
    final db = await _databaseHelper.database;

    final id = await db.insert(
      'water_records',
      {
        'user_id': userId,
        'amount_ml': amountMl,
        'recorded_at': date.toIso8601String(),
      },
    );

    final record = WaterRecord(
      id: id,
      userId: userId,
      amountMl: amountMl,
      recordedAt: date,
    );

    _waterHistory.insert(0, record);

    _calculateTodayTotal();
    notifyListeners();

    return record;
  }

  Future<void> updateWaterGoal(int goalMl) async {
    final userId = _userId;

    if (userId == null) {
      throw StateError(
        'WaterController chưa được khởi tạo.',
      );
    }

    if (goalMl <= 0) {
      throw ArgumentError(
        'Mục tiêu nước phải lớn hơn 0.',
      );
    }

    final db = await _databaseHelper.database;

    await db.transaction((txn) async {
      await DatabaseHelper.ensureUserSettings(txn, userId);

      await txn.update(
        'user_settings',
        {'water_goal_ml': goalMl},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    });

    waterGoalMl = goalMl;
    notifyListeners();
  }

  Future<void> refresh() async {
    final userId = _userId;

    if (userId == null) {
      throw StateError(
        'WaterController chưa được khởi tạo.',
      );
    }

    await initialize(userId);
  }
}