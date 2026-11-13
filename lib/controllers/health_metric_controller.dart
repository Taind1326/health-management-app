import 'package:flutter/foundation.dart';

import '../models/health_metric.dart';
import '../models/health_profile.dart';
import '../repositories/health_metric_repository.dart';
import '../services/auth_service.dart';

/// Lớp Controller của phân hệ Chỉ số sức khỏe (TV2).
/// Phụ trách:
/// - Nhận yêu cầu từ View (thêm, sửa, xóa, lọc, tính toán thống kê)
/// - Kiểm tra các quy tắc nghiệp vụ y khoa (validation khoảng giá trị, dấu phẩy thập phân, chặn tương lai, tâm thu > tâm trương)
/// - Gọi `HealthMetricRepository` để thao tác SQLite
/// - Quản lý trạng thái tải (`isLoading`) và lỗi (`errorMessage`)
class HealthMetricController extends ChangeNotifier {
  static final HealthMetricController _instance =
      HealthMetricController._internal();

  factory HealthMetricController() => _instance;

  final HealthMetricRepository _repository;

  HealthMetricController._internal() : _repository = HealthMetricRepository() {
    _repository.addListener(_onRepositoryChanged);
  }

  /// Constructor dành riêng cho Unit Test với Repository tùy chỉnh.
  HealthMetricController.forTesting(this._repository) {
    _repository.addListener(_onRepositoryChanged);
  }

  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Lấy ID người dùng đang đăng nhập; nếu ở môi trường preview/test độc lập thì mặc định là 1.
  int get currentUserId => AuthService().currentUser?.id ?? 1;

  void _onRepositoryChanged() {
    notifyListeners();
  }

  void clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // ---------------------------------------------------------------------------
  // KIỂM TRA NGHIỆP VỤ & VALIDATION CHUẨN Y KHOA
  // ---------------------------------------------------------------------------

  /// Chuẩn hóa chuỗi nhập (hỗ trợ cả dấu phẩy `,` và dấu chấm `.`) thành số thực hữu hạn.
  static double? parseNumber(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    final val = double.tryParse(normalized);
    if (val == null || !val.isFinite || val.isNaN) return null;
    return val;
  }

  /// Kiểm tra giá trị chính (Tâm thu / Nhịp tim / Cân nặng / BMI).
  static String? validatePrimaryValue(String metricType, String? raw) {
    if (raw == null || raw.trim().isEmpty) {
      return 'Bắt buộc nhập';
    }
    final v = parseNumber(raw);
    if (v == null) {
      return 'Phải là số hợp lệ';
    }
    switch (metricType) {
      case 'blood_pressure':
        if (v < 60 || v > 250) return 'Từ 60 – 250 mmHg';
        break;
      case 'heart_rate':
        if (v < 30 || v > 250) return 'Từ 30 – 250 bpm';
        break;
      case 'weight':
        if (v < 2 || v > 300) return 'Từ 2 – 300 kg';
        break;
      case 'bmi':
        if (v < 10 || v > 50) return 'Từ 10 – 50 kg/m²';
        break;
      default:
        return 'Loại chỉ số không hợp lệ';
    }
    return null;
  }

  /// Kiểm tra giá trị phụ (Tâm trương cho Huyết áp) và quy tắc Tâm thu > Tâm trương.
  static String? validateSecondaryValue(
    String metricType,
    String? raw, {
    String? primaryRaw,
  }) {
    if (metricType != 'blood_pressure') return null;
    if (raw == null || raw.trim().isEmpty) {
      return 'Bắt buộc nhập';
    }
    final dia = parseNumber(raw);
    if (dia == null) {
      return 'Phải là số hợp lệ';
    }
    if (dia < 40 || dia > 150) {
      return 'Từ 40 – 150 mmHg';
    }
    final sys = parseNumber(primaryRaw);
    if (sys != null && dia >= sys) {
      return 'Phải nhỏ hơn tâm thu';
    }
    return null;
  }

  /// Kiểm tra thời điểm đo không được vượt quá hiện tại.
  static String? validateRecordedAt(DateTime recordedAt) {
    if (recordedAt.isAfter(DateTime.now().add(const Duration(seconds: 30)))) {
      return 'Thời điểm đo không được vượt quá thời gian hiện tại!';
    }
    return null;
  }

  /// Kiểm tra toàn vẹn thực thể `HealthMetric` trước khi ghi xuống Repository.
  static void validateMetric(HealthMetric metric) {
    if (!HealthMetric.types.contains(metric.metricType)) {
      throw ArgumentError('Loại chỉ số sức khỏe không hợp lệ.');
    }
    if (!metric.value.isFinite || metric.value <= 0) {
      throw ArgumentError('Giá trị chỉ số không hợp lệ.');
    }
    final timeErr = validateRecordedAt(metric.recordedAt);
    if (timeErr != null) {
      throw ArgumentError(timeErr);
    }
    switch (metric.metricType) {
      case 'blood_pressure':
        if (metric.value < 60 || metric.value > 250) {
          throw ArgumentError('Huyết áp tâm thu phải từ 60 đến 250 mmHg.');
        }
        final dia = metric.value2;
        if (dia == null || !dia.isFinite || dia < 40 || dia > 150) {
          throw ArgumentError('Huyết áp tâm trương phải từ 40 đến 150 mmHg.');
        }
        if (dia >= metric.value) {
          throw ArgumentError('Huyết áp tâm trương phải nhỏ hơn tâm thu.');
        }
        break;
      case 'heart_rate':
        if (metric.value < 30 || metric.value > 250) {
          throw ArgumentError('Nhịp tim phải từ 30 đến 250 bpm.');
        }
        break;
      case 'weight':
        if (metric.value < 2 || metric.value > 300) {
          throw ArgumentError('Cân nặng phải từ 2 đến 300 kg.');
        }
        break;
      case 'bmi':
        if (metric.value < 10 || metric.value > 50) {
          throw ArgumentError('Chỉ số BMI phải từ 10 đến 50 kg/m².');
        }
        break;
    }
  }

  // ---------------------------------------------------------------------------
  // TRUY XUẤT DỮ LIỆU TỪ REPOSITORY CHO VIEW
  // ---------------------------------------------------------------------------

  /// Tải dữ liệu từ SQLite cho người dùng hiện tại.
  Future<void> loadMetrics({int? userId}) async {
    final uid = userId ?? currentUserId;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      await _repository.fetchAllByUser(uid);
    } catch (e) {
      _errorMessage = 'Không thể tải dữ liệu chỉ số sức khỏe: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Danh sách toàn bộ chỉ số của tài khoản hiện tại (mới nhất lên đầu).
  List<HealthMetric> getAll({int? userId}) {
    final uid = userId ?? currentUserId;
    return _repository.getAllForUser(uid);
  }

  /// Lọc danh sách theo loại chỉ số (`null` = Tất cả).
  List<HealthMetric> getByType(String? metricType, {int? userId}) {
    final all = getAll(userId: userId);
    if (metricType == null) return all;
    return all.where((m) => m.metricType == metricType).toList();
  }

  /// Lấy bản ghi gần nhất của một loại chỉ số cho tài khoản hiện tại.
  HealthMetric? getLatest(String metricType, {int? userId}) {
    final uid = userId ?? currentUserId;
    return _repository.getLatestForUser(uid, metricType);
  }

  /// Lọc dữ liệu phục vụ vẽ biểu đồ theo mốc thời gian ('7d', '30d', '90d').
  List<HealthMetric> getChartData({
    required String metricType,
    required String timeRange,
    int? userId,
  }) {
    final uid = userId ?? currentUserId;
    DateTime cutoffDate = DateTime.now();
    switch (timeRange) {
      case '7d':
        cutoffDate = cutoffDate.subtract(const Duration(days: 7));
        break;
      case '30d':
        cutoffDate = cutoffDate.subtract(const Duration(days: 30));
        break;
      case '90d':
        cutoffDate = cutoffDate.subtract(const Duration(days: 90));
        break;
    }
    return _repository.getFiltered(
      metricType: metricType,
      since: cutoffDate,
      userId: uid,
    );
  }

  // ---------------------------------------------------------------------------
  // THAO TÁC THÊM / SỬA / XÓA (CRUD) QUA CONTROLLER
  // ---------------------------------------------------------------------------

  /// Thêm bản ghi chỉ số mới sau khi kiểm tra toàn bộ quy tắc nghiệp vụ.
  Future<HealthMetric> addMetric({
    required String metricType,
    required double value,
    double? value2,
    String? note,
    required DateTime recordedAt,
    int? userId,
  }) async {
    final uid = userId ?? currentUserId;
    final now = DateTime.now();
    final unit = HealthMetric.typeUnits[metricType] ?? '';
    final cleanNote = (note == null || note.trim().isEmpty)
        ? null
        : note.trim();

    final metric = HealthMetric(
      userId: uid,
      metricType: metricType,
      value: value,
      value2: metricType == 'blood_pressure' ? value2 : null,
      unit: unit,
      note: cleanNote,
      recordedAt: recordedAt,
      createdAt: now,
      updatedAt: now,
    );

    validateMetric(metric);

    try {
      final saved = await _repository.insertMetric(metric);
      await _syncProfileIfApplicable(uid, saved);
      _errorMessage = null;
      return saved;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Cập nhật một bản ghi chỉ số đã có trong SQLite.
  Future<HealthMetric> updateMetric({
    required HealthMetric existing,
    required String metricType,
    required double value,
    double? value2,
    String? note,
    required DateTime recordedAt,
  }) async {
    final unit = HealthMetric.typeUnits[metricType] ?? existing.unit;
    final cleanNote = (note == null || note.trim().isEmpty)
        ? null
        : note.trim();

    final updated = existing.copyWith(
      metricType: metricType,
      value: value,
      value2: metricType == 'blood_pressure' ? value2 : null,
      clearValue2: metricType != 'blood_pressure',
      unit: unit,
      note: cleanNote,
      clearNote: cleanNote == null,
      recordedAt: recordedAt,
      updatedAt: DateTime.now(),
    );

    validateMetric(updated);

    try {
      final saved = await _repository.updateMetric(updated);
      await _syncProfileIfApplicable(saved.userId, saved);
      _errorMessage = null;
      return saved;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Xóa bản ghi chỉ số theo ID.
  Future<bool> deleteMetric(int id, {int? userId}) async {
    final uid = userId ?? currentUserId;
    try {
      final deleted = await _repository.deleteMetric(id, userId: uid);
      _errorMessage = null;
      return deleted;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Đồng bộ cân nặng / BMI mới nhất sang Hồ sơ sức khỏe (TV1) nếu người dùng đã có hồ sơ.
  Future<void> _syncProfileIfApplicable(int userId, HealthMetric metric) async {
    try {
      if (AuthService().currentUser == null) return;
      final profile = AuthService().getProfile(userId);
      if (metric.metricType == 'weight' && profile.height > 0) {
        final newBmi = AuthService.calculateBmi(profile.height, metric.value);
        await AuthService().updateProfile(
          HealthProfile(
            id: profile.id,
            userId: profile.userId,
            fullName: profile.fullName,
            age: profile.age,
            gender: profile.gender,
            height: profile.height,
            weight: metric.value,
            bmi: newBmi > 0 ? newBmi : profile.bmi,
          ),
        );
      } else if (metric.metricType == 'bmi') {
        await AuthService().updateProfile(
          HealthProfile(
            id: profile.id,
            userId: profile.userId,
            fullName: profile.fullName,
            age: profile.age,
            gender: profile.gender,
            height: profile.height,
            weight: profile.weight,
            bmi: metric.value,
          ),
        );
      }
    } catch (_) {
      // Không làm gián đoạn luồng lưu chỉ số nếu hồ sơ chưa thiết lập.
    }
  }

  /// Tự động gợi ý BMI dựa trên chiều cao trong Hồ sơ và cân nặng gần nhất.
  ({double? bmi, double? heightCm, double? weightKg}) suggestBmi({int? userId}) {
    final uid = userId ?? currentUserId;
    final profile = AuthService().getProfile(uid);
    final heightCm = profile.height > 0 ? profile.height : 170.0;
    final latestWeight =
        getLatest('weight', userId: uid)?.value ??
        (profile.weight > 0 ? profile.weight : null);
    if (latestWeight == null || latestWeight <= 0) {
      return (bmi: null, heightCm: heightCm, weightKg: null);
    }
    final bmi = AuthService.calculateBmi(heightCm, latestWeight);
    return (
      bmi: bmi >= 10 && bmi <= 50 ? bmi : null,
      heightCm: heightCm,
      weightKg: latestWeight,
    );
  }
}
