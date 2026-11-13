import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../models/health_metric.dart';
import '../utils/database_helper.dart';

/// Lớp Repository phụ trách truy vấn và thao tác dữ liệu bảng `health_metrics` trên SQLite.
/// Đồng thời duy trì bộ đệm đồng bộ theo `user_id` để hỗ trợ truy xuất tức thì
/// (tương thích với `CalorieCalculator` và môi trường Widget Test / Web).
class HealthMetricRepository extends ChangeNotifier {
  static final HealthMetricRepository _instance =
      HealthMetricRepository._internal();

  factory HealthMetricRepository() => _instance;

  final Future<Database> Function() _open;
  final bool _strictSqlite;

  HealthMetricRepository._internal()
    : _open = (() => DatabaseHelper().database),
      _strictSqlite = false {
    _metrics = HealthMetric.sampleData(userId: 1);
  }

  /// Constructor phục vụ kiểm thử trực tiếp với SQLite database riêng.
  HealthMetricRepository.forTesting(this._open) : _strictSqlite = true {
    _metrics = [];
  }

  late List<HealthMetric> _metrics;
  final Set<int> _seededUsers = {};

  /// Khôi phục dữ liệu mẫu phục vụ kiểm thử.
  void resetForTesting({int userId = 1}) {
    _metrics = HealthMetric.sampleData(userId: userId);
    _seededUsers.clear();
    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // TRUY VẤN SQLITE (ASYNC CRUD THEO TÀI KHOẢN)
  // ---------------------------------------------------------------------------

  /// Tải toàn bộ chỉ số sức khỏe của `userId` từ SQLite `health_metrics`.
  Future<List<HealthMetric>> fetchAllByUser(int userId) async {
    try {
      final db = await _open();
      var rows = await db.query(
        'health_metrics',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'recorded_at DESC, id DESC',
      );

      // Nếu tài khoản mẫu (userId = 1) mở app lần đầu chưa có bản ghi trong SQLite,
      // tự động khởi tạo dữ liệu mẫu vào bảng health_metrics nếu user tồn tại.
      if (rows.isEmpty &&
          userId == 1 &&
          !_strictSqlite &&
          !_seededUsers.contains(userId)) {
        _seededUsers.add(userId);
        final userRows = await db.query(
          'users',
          columns: ['id'],
          where: 'id = ?',
          whereArgs: [userId],
        );
        if (userRows.isNotEmpty) {
          await db.transaction((txn) async {
            for (final sample in HealthMetric.sampleData(userId: userId)) {
              final map = Map<String, Object?>.from(sample.toMap())
                ..remove('id');
              await txn.insert('health_metrics', map);
            }
          });
          rows = await db.query(
            'health_metrics',
            where: 'user_id = ?',
            whereArgs: [userId],
            orderBy: 'recorded_at DESC, id DESC',
          );
        }
      }

      if (rows.isNotEmpty || _strictSqlite || _seededUsers.contains(userId)) {
        final loaded = rows.map((r) => HealthMetric.fromMap(r)).toList();
        _replaceUserCache(userId, loaded);
        return loaded;
      }
    } catch (_) {
      if (_strictSqlite) rethrow;
    }

    return getAllForUser(userId);
  }

  /// Lấy bản ghi mới nhất theo loại chỉ số của `userId` từ SQLite.
  Future<HealthMetric?> fetchLatestByUser(int userId, String metricType) async {
    try {
      final db = await _open();
      final rows = await db.query(
        'health_metrics',
        where: 'user_id = ? AND metric_type = ?',
        whereArgs: [userId, metricType],
        orderBy: 'recorded_at DESC, id DESC',
        limit: 1,
      );
      if (rows.isNotEmpty) {
        return HealthMetric.fromMap(rows.first);
      }
      if (_strictSqlite) return null;
    } catch (_) {
      if (_strictSqlite) rethrow;
    }
    return getLatestForUser(userId, metricType);
  }

  /// Truy vấn danh sách chỉ số theo loại và khoảng thời gian từ SQLite (sắp xếp tăng dần cho biểu đồ).
  Future<List<HealthMetric>> fetchFilteredByUser({
    required int userId,
    required String metricType,
    required DateTime since,
  }) async {
    try {
      final db = await _open();
      final rows = await db.query(
        'health_metrics',
        where: 'user_id = ? AND metric_type = ? AND recorded_at >= ?',
        whereArgs: [userId, metricType, since.toIso8601String()],
        orderBy: 'recorded_at ASC, id ASC',
      );
      if (rows.isNotEmpty || _strictSqlite) {
        return rows.map((r) => HealthMetric.fromMap(r)).toList();
      }
    } catch (_) {
      if (_strictSqlite) rethrow;
    }
    return getFiltered(userId: userId, metricType: metricType, since: since);
  }

  /// Thêm bản ghi mới vào bảng `health_metrics` trong SQLite.
  Future<HealthMetric> insertMetric(HealthMetric metric) async {
    try {
      final db = await _open();
      final values = Map<String, Object?>.from(metric.toMap())..remove('id');
      final insertedId = await db.insert('health_metrics', values);
      final saved = metric.copyWith(id: insertedId);
      _upsertCache(saved);
      notifyListeners();
      return saved;
    } catch (_) {
      if (_strictSqlite) rethrow;
      final fallbackId =
          metric.id ?? DateTime.now().microsecondsSinceEpoch.remainder(100000000);
      final saved = metric.copyWith(id: fallbackId);
      _upsertCache(saved);
      notifyListeners();
      return saved;
    }
  }

  /// Cập nhật bản ghi chỉ số trong bảng `health_metrics` của SQLite.
  Future<HealthMetric> updateMetric(HealthMetric metric) async {
    if (metric.id == null) {
      throw ArgumentError('Không thể cập nhật bản ghi chưa có ID.');
    }
    final updated = metric.copyWith(updatedAt: DateTime.now());
    try {
      final db = await _open();
      final values = Map<String, Object?>.from(updated.toMap())..remove('id');
      final count = await db.update(
        'health_metrics',
        values,
        where: 'id = ? AND user_id = ?',
        whereArgs: [updated.id, updated.userId],
      );
      if (_strictSqlite && count == 0) {
        throw StateError('Chỉ số sức khỏe không tồn tại trong tài khoản.');
      }
    } catch (_) {
      if (_strictSqlite) rethrow;
    }
    _upsertCache(updated);
    notifyListeners();
    return updated;
  }

  /// Xóa bản ghi chỉ số theo `id` và `userId` trong SQLite.
  Future<bool> deleteMetric(int id, {int? userId}) async {
    try {
      final db = await _open();
      final count = await db.delete(
        'health_metrics',
        where: userId != null ? 'id = ? AND user_id = ?' : 'id = ?',
        whereArgs: userId != null ? [id, userId] : [id],
      );
      if (_strictSqlite && count == 0) {
        throw StateError('Chỉ số sức khỏe không tồn tại trong tài khoản.');
      }
    } catch (_) {
      if (_strictSqlite) rethrow;
    }
    final removed = _removeFromCache(id, userId: userId);
    notifyListeners();
    return removed;
  }

  // ---------------------------------------------------------------------------
  // ĐỒNG BỘ CACHE & CÁC HÀM TRUY XUẤT TỨC THÌ (TƯƠNG THÍCH NGƯỢC)
  // ---------------------------------------------------------------------------

  void _replaceUserCache(int userId, List<HealthMetric> userMetrics) {
    _metrics.removeWhere((m) => m.userId == userId);
    _metrics.addAll(userMetrics);
    notifyListeners();
  }

  void _upsertCache(HealthMetric metric) {
    final index = _metrics.indexWhere((m) => m.id == metric.id);
    if (index != -1) {
      _metrics[index] = metric;
    } else {
      _metrics.add(metric);
    }
  }

  bool _removeFromCache(int id, {int? userId}) {
    final index = _metrics.indexWhere(
      (m) => m.id == id && (userId == null || m.userId == userId),
    );
    if (index != -1) {
      _metrics.removeAt(index);
      return true;
    }
    return false;
  }

  /// Lấy toàn bộ bản ghi của một tài khoản cụ thể, sắp xếp mới nhất trước.
  List<HealthMetric> getAllForUser(int userId) {
    final list = _metrics.where((m) => m.userId == userId).toList();
    list.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return list;
  }

  /// Lấy toàn bộ bản ghi trong bộ đệm, sắp xếp mới nhất trước.
  List<HealthMetric> getAll({int? userId}) {
    final list = userId != null
        ? _metrics.where((m) => m.userId == userId).toList()
        : List<HealthMetric>.from(_metrics);
    list.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return list;
  }

  /// Lấy bản ghi gần nhất theo loại chỉ số.
  HealthMetric? getLatest(String type, {int? userId}) {
    final filtered = _metrics
        .where(
          (m) =>
              m.metricType == type && (userId == null || m.userId == userId),
        )
        .toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return filtered.first;
  }

  /// Chỉ số mới nhất của một tài khoản cụ thể (được gọi bởi `CalorieCalculator`).
  HealthMetric? getLatestForUser(int userId, String type) {
    final filtered = _metrics
        .where((m) => m.userId == userId && m.metricType == type)
        .toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return filtered.first;
  }

  /// Thêm bản ghi (tương thích đồng bộ và tự động lưu xuống SQLite).
  void add(HealthMetric metric) {
    _upsertCache(metric);
    notifyListeners();
    insertMetric(metric).ignore();
  }

  /// Cập nhật bản ghi (tương thích đồng bộ và tự động lưu xuống SQLite).
  void update(HealthMetric metric) {
    _upsertCache(metric);
    notifyListeners();
    updateMetric(metric).ignore();
  }

  /// Xóa bản ghi theo ID (tương thích đồng bộ và tự động xóa trong SQLite).
  bool delete(int id, {int? userId}) {
    final ok = _removeFromCache(id, userId: userId);
    if (ok) {
      notifyListeners();
      deleteMetric(id, userId: userId).ignore();
    }
    return ok;
  }

  /// Lọc dữ liệu theo loại chỉ số và mốc thời gian, sắp xếp tăng dần cho biểu đồ.
  List<HealthMetric> getFiltered({
    required String metricType,
    required DateTime since,
    int? userId,
  }) {
    final filtered = _metrics
        .where(
          (m) =>
              m.metricType == metricType &&
              (userId == null || m.userId == userId) &&
              (m.recordedAt.isAfter(since) ||
                  m.recordedAt.isAtSameMomentAs(since)),
        )
        .toList();
    filtered.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return filtered;
  }
}
