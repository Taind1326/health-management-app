import '../repositories/health_metric_repository.dart';
import 'auth_service.dart';

/// Ước lượng calo tiêu hao khi đi bộ theo công thức MET:
///
///   kcal = MET × cân nặng (kg) × thời gian (giờ)
///
/// MET phụ thuộc tốc độ đi (lấy từ quãng đường / thời gian của tuyến),
/// theo bảng Compendium of Physical Activities. Đây chỉ là ước lượng.
class CalorieCalculator {
  CalorieCalculator._();

  /// MET khi đi bộ theo tốc độ (km/h).
  static double walkingMet(double speedKmh) {
    if (speedKmh <= 3.2) return 2.8; // ~2.0 mph
    if (speedKmh <= 4.0) return 3.0; // ~2.5 mph
    if (speedKmh <= 4.8) return 3.5; // ~3.0 mph
    if (speedKmh <= 5.6) return 4.3; // ~3.5 mph
    if (speedKmh <= 6.4) return 5.0; // ~4.0 mph
    if (speedKmh <= 7.2) return 7.0; // ~4.5 mph
    return 8.3; // đi bộ rất nhanh
  }

  /// MET khi chạy bộ theo tốc độ (km/h), lấy mốc gần nhất trong bảng
  /// Compendium (5, 6, 7, 8, 9 mph ≈ 8.0, 9.7, 11.3, 12.9, 14.5 km/h).
  static double runningMet(double speedKmh) {
    if (speedKmh <= 7.2) return 7.0; // chạy chậm (jogging)
    if (speedKmh <= 8.85) return 8.3; // ~5 mph
    if (speedKmh <= 10.46) return 9.8; // ~6 mph
    if (speedKmh <= 12.07) return 11.0; // ~7 mph
    if (speedKmh <= 13.68) return 11.8; // ~8 mph
    if (speedKmh <= 15.3) return 12.8; // ~9 mph
    return 14.5; // ~10 mph trở lên
  }

  /// Calo tiêu hao (kcal, làm tròn) khi chạy bộ. Trả về 0 nếu dữ liệu không hợp lệ.
  static int runningKcal({
    required double weightKg,
    required double distanceKm,
    required int durationMinutes,
  }) {
    if (weightKg <= 0 || distanceKm <= 0 || durationMinutes <= 0) return 0;
    final hours = durationMinutes / 60;
    final met = runningMet(distanceKm / hours);
    return (met * weightKg * hours).round();
  }

  /// Calo tiêu hao (kcal, làm tròn) khi đi bộ. Trả về 0 nếu dữ liệu không hợp lệ.
  static int walkingKcal({
    required double weightKg,
    required double distanceKm,
    required int durationMinutes,
  }) {
    if (weightKg <= 0 || distanceKm <= 0 || durationMinutes <= 0) return 0;
    final hours = durationMinutes / 60;
    final met = walkingMet(distanceKm / hours);
    return (met * weightKg * hours).round();
  }

  /// MET khi đạp xe theo tốc độ (km/h), theo bảng Compendium
  /// (dưới 10 mph, 10–12, 12–14, 14–16, 16–20 mph và trên 20 mph).
  static double cyclingMet(double speedKmh) {
    if (speedKmh <= 16.0) return 4.0; // đạp thong thả
    if (speedKmh <= 19.2) return 6.8;
    if (speedKmh <= 22.4) return 8.0;
    if (speedKmh <= 25.6) return 10.0;
    if (speedKmh <= 30.6) return 12.0;
    return 15.8; // trên ~20 mph
  }

  /// Calo tiêu hao (kcal, làm tròn) khi đạp xe. Trả về 0 nếu dữ liệu không hợp lệ.
  static int cyclingKcal({
    required double weightKg,
    required double distanceKm,
    required int durationMinutes,
  }) {
    if (weightKg <= 0 || distanceKm <= 0 || durationMinutes <= 0) return 0;
    final hours = durationMinutes / 60;
    final met = cyclingMet(distanceKm / hours);
    return (met * weightKg * hours).round();
  }

  /// Cân nặng (kg) của người dùng đang đăng nhập: ưu tiên hồ sơ, nếu hồ sơ
  /// chưa nhập thì lấy chỉ số cân nặng mới nhất. Trả về null nếu chưa có.
  static double? currentWeightKg() {
    final userId = AuthService().currentUser?.id ?? 1;
    final profileWeight = AuthService().getProfile(userId).weight;
    if (profileWeight > 0) return profileWeight;

    final latest = HealthMetricRepository().getLatest('weight')?.value;
    if (latest != null && latest > 0) return latest;
    return null;
  }
}