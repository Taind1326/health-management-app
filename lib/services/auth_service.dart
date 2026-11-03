import '../models/user.dart';
import '../models/health_profile.dart';
import '../models/health_goal.dart';
import '../utils/hash_util.dart';
import '../repositories/auth_repository.dart';

class AuthService {
  // Singleton pattern để dùng chung nguồn dữ liệu trong toàn bộ phiên chạy ứng dụng
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initSampleData();
  }

  // Repository SQLite (dùng cho môi trường app thật)
  final AuthRepository _repository = AuthRepository();
  AuthRepository get repository => _repository;

  // Danh sách tài khoản in-memory
  final List<User> _users = [];

  // Lưu hồ sơ theo userId: Map<userId, HealthProfile>
  final Map<int, HealthProfile> _profiles = {};

  // Lưu danh sách mục tiêu theo userId: Map<userId, List<HealthGoal>>
  final Map<int, List<HealthGoal>> _goals = {};

  // Lưu danh sách người dùng đã xem trang Giới thiệu (App Intro)
  final Set<int> _seenIntroUserIds = {};

  // Cờ phục vụ kiểm thử tự động
  bool _isTestingMode = false;
  bool get isTestingMode => _isTestingMode;
  bool _introEnabledForTesting = false;

  // Người dùng đang đăng nhập trong phiên hiện tại
  User? _currentUser;
  User? get currentUser => _currentUser;

  void _initSampleData() {
    // Tài khoản mẫu ban đầu: user01 / 123456
    final salt = HashUtil.generateSalt();
    final hash = HashUtil.hashPassword('123456', salt);

    final sampleUser = User(
      id: 1,
      username: 'user01',
      phone: '0901234567',
      email: 'user01@example.com',
      password: '123456',
      passwordHash: hash,
      passwordSalt: salt,
    );
    _users.add(sampleUser);
    _seenIntroUserIds.add(1);

    _profiles[1] = HealthProfile(
      id: 1,
      userId: 1,
      fullName: 'Nguyễn Văn A',
      age: 20,
      gender: 'Nam',
      height: 170.0,
      weight: 65.0,
      bmi: 22.49,
    );

    _goals[1] = [
      HealthGoal(
        id: 1,
        userId: 1,
        goal: 'Tập thể dục 30 phút mỗi ngày',
      ),
      HealthGoal(
        id: 2,
        userId: 1,
        goal: 'Uống đủ 2 lít nước mỗi ngày',
      ),
    ];
  }

  // Reset dữ liệu về trạng thái mẫu ban đầu (phục vụ unit/widget test)
  void resetForTesting() {
    _isTestingMode = true;
    _introEnabledForTesting = false;
    _users.clear();
    _profiles.clear();
    _goals.clear();
    _seenIntroUserIds.clear();
    _currentUser = null;
    _initSampleData();
  }

  /// Kích hoạt hiển thị App Intro trong môi trường Test (dành cho Test #11)
  void enableIntroForTesting() {
    _introEnabledForTesting = true;
  }

  /// Kiểm tra người dùng đã xem App Intro chưa
  bool hasSeenIntro(int userId) {
    if (_isTestingMode) {
      if (!_introEnabledForTesting) {
        return true; // Mặc định không chặn các test cũ
      }
      return _seenIntroUserIds.contains(userId);
    }
    return _seenIntroUserIds.contains(userId);
  }

  /// Đánh dấu đã xem App Intro
  void setSeenIntro(int userId) {
    _seenIntroUserIds.add(userId);
  }

  // Đăng nhập tài khoản bằng Username, Email hoặc Số điện thoại
  User? login(String identifier, String password) {
    final cleanId = identifier.trim().toLowerCase();
    for (final user in _users) {
      final matchUsername = user.username.toLowerCase() == cleanId;
      final matchPhone = user.phone?.toLowerCase() == cleanId;
      final matchEmail = user.email?.toLowerCase() == cleanId;

      if (matchUsername || matchPhone || matchEmail) {
        bool passwordMatches = false;
        if (user.passwordSalt != null && user.passwordHash != null) {
          final hash = HashUtil.hashPassword(password, user.passwordSalt!);
          passwordMatches = (hash == user.passwordHash);
        }
        if (!passwordMatches && user.password == password) {
          passwordMatches = true;
        }

        if (passwordMatches) {
          _currentUser = user;
          return user;
        }
      }
    }
    return null;
  }

  // Đăng xuất: xóa phiên người dùng hiện tại
  void logout() {
    _currentUser = null;
  }

  // Kiểm tra tên tài khoản đã tồn tại chưa
  bool isUsernameTaken(String username) {
    final cleanUsername = username.trim().toLowerCase();
    return _users.any((u) => u.username.toLowerCase() == cleanUsername);
  }

  // Kiểm tra số điện thoại đã tồn tại chưa
  bool isPhoneTaken(String? phone) {
    if (phone == null || phone.trim().isEmpty) return false;
    final cleanPhone = phone.trim();
    return _users.any((u) => u.phone == cleanPhone);
  }

  // Kiểm tra email đã tồn tại chưa
  bool isEmailTaken(String? email) {
    if (email == null || email.trim().isEmpty) return false;
    final cleanEmail = email.trim().toLowerCase();
    return _users.any((u) => (u.email ?? '').toLowerCase() == cleanEmail);
  }

  // Đăng ký tài khoản mới kèm khởi tạo hồ sơ sức khỏe liên kết với userId
  User register({
    required String fullName,
    String? phone,
    String? email,
    required String username,
    required String password,
  }) {
    final newId = _users.isEmpty ? 1 : _users.map((u) => u.id).reduce((a, b) => a > b ? a : b) + 1;
    final salt = HashUtil.generateSalt();
    final hash = HashUtil.hashPassword(password, salt);

    final newUser = User(
      id: newId,
      username: username.trim(),
      phone: (phone != null && phone.trim().isNotEmpty) ? phone.trim() : null,
      email: (email != null && email.trim().isNotEmpty) ? email.trim() : null,
      password: password,
      passwordHash: hash,
      passwordSalt: salt,
    );
    _users.add(newUser);

    // Hồ sơ sức khỏe ban đầu liên kết với User.id, chưa thiết lập các chỉ số sức khỏe
    _profiles[newId] = HealthProfile(
      id: newId,
      userId: newId,
      fullName: fullName.trim(),
      age: 0,
      gender: 'Nam',
      height: 0.0,
      weight: 0.0,
      bmi: 0.0,
    );

    _goals[newId] = [];

    // Cố gắng đồng bộ ngầm vào SQLite nếu không ở chế độ kiểm thử
    if (!_isTestingMode) {
      _repository.registerUser(
        fullName: fullName,
        phone: phone,
        email: email,
        username: username,
        password: password,
      ).catchError((_) => newUser);
    }

    return newUser;
  }

  // Lấy hồ sơ sức khỏe theo userId
  HealthProfile getProfile(int userId) {
    if (_profiles.containsKey(userId)) {
      return _profiles[userId]!;
    }
    // Dự phòng nếu chưa có
    final defaultProfile = HealthProfile(
      id: userId,
      userId: userId,
      fullName: _currentUser?.username ?? 'Người dùng',
      age: 0,
      gender: 'Nam',
      height: 0.0,
      weight: 0.0,
      bmi: 0.0,
    );
    _profiles[userId] = defaultProfile;
    return defaultProfile;
  }

  // Cập nhật hồ sơ sức khỏe
  void updateProfile(HealthProfile updatedProfile) {
    _profiles[updatedProfile.userId] = updatedProfile;
    if (!_isTestingMode) {
      _repository.updateProfile(updatedProfile).catchError((_) {});
    }
  }

  // Lấy danh sách mục tiêu sức khỏe theo userId
  List<HealthGoal> getGoals(int userId) {
    return _goals[userId] ?? [];
  }

  // Thêm mục tiêu sức khỏe mới
  HealthGoal addGoal(int userId, String goalText) {
    final list = _goals.putIfAbsent(userId, () => []);
    final newId = DateTime.now().millisecondsSinceEpoch;
    final newGoal = HealthGoal(id: newId, userId: userId, goal: goalText);
    list.add(newGoal);

    if (!_isTestingMode) {
      _repository.addGoal(userId, goalText).catchError((_) => newGoal);
    }

    return newGoal;
  }

  // Xóa mục tiêu sức khỏe theo userId và goalId
  void deleteGoal(int userId, int goalId) {
    if (_goals.containsKey(userId)) {
      _goals[userId]!.removeWhere((g) => g.id == goalId);
    }
    if (!_isTestingMode) {
      _repository.deleteGoal(goalId).catchError((_) => 0);
    }
  }

  // Xóa mục tiêu sức khỏe theo nội dung text
  void deleteGoalByText(int userId, String goalText) {
    if (_goals.containsKey(userId)) {
      _goals[userId]!.removeWhere((g) => g.goal == goalText.trim());
    }
    if (!_isTestingMode) {
      _repository.deleteGoalByText(userId, goalText).catchError((_) => 0);
    }
  }

  // --- CÔNG THỨC TÍNH TOÁN THÔNG MINH CHO MỤC TIÊU SỨC KHỎE ---

  /// Tính chỉ số BMI từ chiều cao (cm) và cân nặng (kg)
  static double calculateBmi(double heightCm, double weightKg) {
    if (heightCm <= 0 || weightKg <= 0) return 0.0;
    final heightMeter = heightCm / 100.0;
    final bmi = weightKg / (heightMeter * heightMeter);
    return double.parse(bmi.toStringAsFixed(2));
  }

  /// Tính BMR (Basal Metabolic Rate) theo công thức Mifflin - St Jeor
  static double calculateBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0) return 0.0;
    // Nam: 10 * weight + 6.25 * height - 5 * age + 5
    // Nữ: 10 * weight + 6.25 * height - 5 * age - 161
    final isMale = gender.trim().toLowerCase() == 'nam' || gender.trim().toLowerCase() == 'male';
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    return isMale ? base + 5 : base - 161;
  }

  /// Tính TDEE (Total Daily Energy Expenditure) ước lượng dựa trên mức hoạt động
  static int calculateTdee({
    required double bmr,
    String activityLevel = 'moderate',
  }) {
    double factor = 1.375; // light activity default
    switch (activityLevel) {
      case 'sedentary':
        factor = 1.2;
        break;
      case 'light':
        factor = 1.375;
        break;
      case 'moderate':
        factor = 1.55;
        break;
      case 'active':
        factor = 1.725;
        break;
    }
    return (bmr * factor).round();
  }

  /// Tính lượng nước uống khuyến nghị mỗi ngày (ml) dựa trên cân nặng
  /// Chuẩn y khoa: ~35ml trên mỗi kg thể trọng
  static int calculateRecommendedWater(double weightKg) {
    if (weightKg <= 0) return 2000;
    final ml = (weightKg * 35).round();
    // Làm tròn đến 50ml gần nhất
    return ((ml + 25) ~/ 50) * 50;
  }
}
