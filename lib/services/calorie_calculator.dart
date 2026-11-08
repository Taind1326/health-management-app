import '../repositories/health_metric_repository.dart';
import 'auth_service.dart';

/// Ước lượng calo tiêu hao theo công thức MET:
///
///   kcal = MET × cân nặng (kg) × thời gian (giờ)
///
/// MET phụ thuộc tốc độ (quãng đường / thời gian), theo bảng Compendium of
/// Physical Activities. Đây chỉ là ước lượng.
class CalorieCalculator {
  CalorieCalculator._();

  static double walkingMet(double speedKmh) {
    if (speedKmh <= 3.2) return 2.8;
    if (speedKmh <= 4.0) return 3.0;
    if (speedKmh <= 4.8) return 3.5;
    if (speedKmh <= 5.6) return 4.3;
    if (speedKmh <= 6.4) return 5.0;
    if (speedKmh <= 7.2) return 7.0;
    return 8.3;
  }

  static double runningMet(double speedKmh) {
    if (speedKmh <= 7.2) return 7.0;
    if (speedKmh <= 8.85) return 8.3;
    if (speedKmh <= 10.46) return 9.8;
    if (speedKmh <= 12.07) return 11.0;
    if (speedKmh <= 13.68) return 11.8;
    if (speedKmh <= 15.3) return 12.8;
    return 14.5;
  }

  static double cyclingMet(double speedKmh) {
    if (speedKmh <= 16.0) return 4.0;
    if (speedKmh <= 19.2) return 6.8;
    if (speedKmh <= 22.4) return 8.0;
    if (speedKmh <= 25.6) return 10.0;
    if (speedKmh <= 30.6) return 12.0;
    return 15.8;
  }

  /// Tính kcal an toàn: kiểm tra isFinite TRƯỚC khi tính và làm tròn
  /// (round() trên NaN/Infinity sẽ ném lỗi). Dữ liệu sai trả về 0.
  static int _kcal({
    required double weightKg,
    required double distanceKm,
    required int durationMinutes,
    required double Function(double speedKmh) metOf,
  }) {
    if (!weightKg.isFinite || !distanceKm.isFinite) return 0;
    if (weightKg <= 0 || distanceKm <= 0 || durationMinutes <= 0) return 0;
    final hours = durationMinutes / 60;
    final speed = distanceKm / hours;
    if (!hours.isFinite || !speed.isFinite) return 0;
    final kcal = metOf(speed) * weightKg * hours;
    if (!kcal.isFinite) return 0;
    return kcal.round();
  }

  static int walkingKcal({
    required double weightKg,
    required double distanceKm,
    required int durationMinutes,
  }) =>
      _kcal(
        weightKg: weightKg,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        metOf: walkingMet,
      );

  static int runningKcal({
    required double weightKg,
    required double distanceKm,
    required int durationMinutes,
  }) =>
      _kcal(
        weightKg: weightKg,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        metOf: runningMet,
      );

  static int cyclingKcal({
    required double weightKg,
    required double distanceKm,
    required int durationMinutes,
  }) =>
      _kcal(
        weightKg: weightKg,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        metOf: cyclingMet,
      );

  static bool _validWeight(double? w) => w != null && w.isFinite && w > 0;

  /// Cân nặng (kg) của NGƯỜI ĐANG ĐĂNG NHẬP.
  /// Quy tắc thống nhất: ưu tiên chỉ số cân nặng mới nhất của chính người đó
  /// (có ngày ghi nhận); nếu chưa có thì dùng cân nặng trong hồ sơ.
  /// Trả về null nếu chưa đăng nhập hoặc chưa có cân nặng hợp lệ.
  static double? currentWeightKg() {
    final userId = AuthService().currentUser?.id;
    if (userId == null) return null;

    final latest =
        HealthMetricRepository().getLatestForUser(userId, 'weight')?.value;
    if (_validWeight(latest)) return latest;

    final profileWeight = AuthService().getProfile(userId).weight;
    if (_validWeight(profileWeight)) return profileWeight;
    return null;
  }
}