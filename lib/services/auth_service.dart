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

  // Đăng nhập tài khoản bằng Username, Email hoặc Số điện thoại (SQLite làm nguồn chính)
  Future<User?> login(String identifier, String password) async {
    final cleanId = identifier.trim();
    if (cleanId.isEmpty || password.isEmpty) return null;

    if (!_isTestingMode) {
      final dbUser = await _repository.authenticate(cleanId, password);
      if (dbUser != null) {
        _currentUser = dbUser;
        _users.removeWhere((u) => u.id == dbUser.id);
        _users.add(dbUser);

        // Nạp profile và goals từ SQLite vào RAM cache
        final profile = await _repository.getProfile(dbUser.id);
        _profiles[dbUser.id] = profile;

        final goals = await _repository.getGoals(dbUser.id);
        _goals[dbUser.id] = goals;

        return dbUser;
      }
      return null;
    }

    // Môi trường kiểm thử (in-memory)
    final cleanLower = cleanId.toLowerCase();
    for (final user in _users) {
      final matchUsername = user.username.toLowerCase() == cleanLower;
      final matchPhone = user.phone?.toLowerCase() == cleanLower;
      final matchEmail = user.email?.toLowerCase() == cleanLower;

      if (matchUsername || matchPhone || matchEmail) {
        if (user.passwordSalt != null && user.passwordHash != null) {
          final hash = HashUtil.hashPassword(password, user.passwordSalt!);
          if (hash == user.passwordHash) {
            _currentUser = user;
            return user;
          }
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
  Future<bool> isUsernameTaken(String username) async {
    final cleanUsername = username.trim();
    if (cleanUsername.isEmpty) return false;
    if (!_isTestingMode) {
      return await _repository.isUsernameTaken(cleanUsername);
    }
    return _users.any((u) => u.username.toLowerCase() == cleanUsername.toLowerCase());
  }

  // Kiểm tra số điện thoại đã tồn tại chưa
  Future<bool> isPhoneTaken(String? phone) async {
    if (phone == null || phone.trim().isEmpty) return false;
    final cleanPhone = phone.trim();
    if (!_isTestingMode) {
      return await _repository.isPhoneTaken(cleanPhone);
    }
    return _users.any((u) => u.phone == cleanPhone);
  }

  // Kiểm tra email đã tồn tại chưa
  Future<bool> isEmailTaken(String? email) async {
    if (email == null || email.trim().isEmpty) return false;
    final cleanEmail = email.trim();
    if (!_isTestingMode) {
      return await _repository.isEmailTaken(cleanEmail);
    }
    return _users.any((u) => (u.email ?? '').toLowerCase() == cleanEmail.toLowerCase());
  }

  // Đăng ký tài khoản mới kèm khởi tạo hồ sơ sức khỏe và cài đặt trong 1 transaction SQLite
  Future<User> register({
    required String fullName,
    String? phone,
    String? email,
    required String username,
    required String password,
  }) async {
    if (!_isTestingMode) {
      // 1. Ghi vào SQLite trong transaction (tạo users + health_profiles + user_settings)
      final newUser = await _repository.registerUser(
        fullName: fullName,
        phone: phone,
        email: email,
        username: username,
        password: password,
      );

      // 2. Lấy chính xác newUserId tự tăng từ SQLite làm nguồn chân lý
      final newUserId = newUser.id;
      _users.add(newUser);

      _profiles[newUserId] = HealthProfile(
        id: newUserId,
        userId: newUserId,
        fullName: fullName.trim(),
        age: 0,
        gender: 'Nam',
        height: 0.0,
        weight: 0.0,
        bmi: 0.0,
      );
      _goals[newUserId] = [];

      return newUser;
    }

    // Môi trường kiểm thử (in-memory)
    final newId = _users.isEmpty ? 1 : _users.map((u) => u.id).reduce((a, b) => a > b ? a : b) + 1;
    final salt = HashUtil.generateSalt();
    final hash = HashUtil.hashPassword(password, salt);

    final newUser = User(
      id: newId,
      username: username.trim(),
      phone: (phone != null && phone.trim().isNotEmpty) ? phone.trim() : null,
      email: (email != null && email.trim().isNotEmpty) ? email.trim() : null,
      password: '',
      passwordHash: hash,
      passwordSalt: salt,
    );
    _users.add(newUser);

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
  Future<void> updateProfile(HealthProfile updatedProfile) async {
    _profiles[updatedProfile.userId] = updatedProfile;
    if (!_isTestingMode) {
      await _repository.updateProfile(updatedProfile);
    }
  }

  // Lấy danh sách mục tiêu sức khỏe theo userId
  List<HealthGoal> getGoals(int userId) {
    return _goals[userId] ?? [];
  }

  // Thêm mục tiêu sức khỏe mới (lấy ID tự tăng từ SQLite)
  Future<HealthGoal> addGoal(int userId, String goalText) async {
    final cleanGoal = goalText.trim();
    if (cleanGoal.isEmpty) {
      throw ArgumentError('Mục tiêu sức khỏe không được để trống.');
    }
    final list = _goals.putIfAbsent(userId, () => []);

    if (!_isTestingMode) {
      final savedGoal = await _repository.addGoal(userId, cleanGoal);
      list.add(savedGoal);
      return savedGoal;
    }

    final newId = list.isEmpty ? 1 : list.map((g) => g.id).reduce((a, b) => a > b ? a : b) + 1;
    final newGoal = HealthGoal(id: newId, userId: userId, goal: cleanGoal);
    list.add(newGoal);
    return newGoal;
  }

  // Xóa mục tiêu sức khỏe theo userId và goalId (đảm bảo quyền sở hữu)
  Future<void> deleteGoal(int userId, int goalId) async {
    if (_goals.containsKey(userId)) {
      _goals[userId]!.removeWhere((g) => g.id == goalId);
    }
    if (!_isTestingMode) {
      await _repository.deleteGoal(userId, goalId);
    }
  }

  // Xóa mục tiêu sức khỏe theo nội dung text
  Future<void> deleteGoalByText(int userId, String goalText) async {
    final cleanGoal = goalText.trim();
    if (_goals.containsKey(userId)) {
      _goals[userId]!.removeWhere((g) => g.goal == cleanGoal);
    }
    if (!_isTestingMode) {
      await _repository.deleteGoalByText(userId, cleanGoal);
    }
  }

  // --- CÔNG THỨC TÍNH TOÁN THÔNG MINH CHO MỤC TIÊU SỨC KHỎE (BẢO VỆ CHỐNG SỐ VÔ HẠN/NAN) ---

  /// Tính chỉ số BMI từ chiều cao (cm) và cân nặng (kg)
  static double calculateBmi(double heightCm, double weightKg) {
    if (heightCm <= 0 || weightKg <= 0 ||
        heightCm.isNaN || heightCm.isInfinite ||
        weightKg.isNaN || weightKg.isInfinite) {
      return 0.0;
    }
    final heightMeter = heightCm / 100.0;
    final denominator = heightMeter * heightMeter;
    if (denominator <= 0 || denominator.isNaN || denominator.isInfinite) return 0.0;
    final bmi = weightKg / denominator;
    if (bmi.isNaN || bmi.isInfinite || bmi <= 0) return 0.0;
    return double.parse(bmi.toStringAsFixed(2));
  }

  /// Tính BMR (Basal Metabolic Rate) theo công thức Mifflin - St Jeor
  static double calculateBmr({
    required double weightKg,
    required double heightCm,
    required int age,
    required String gender,
  }) {
    if (weightKg <= 0 || heightCm <= 0 || age <= 0 ||
        weightKg.isNaN || weightKg.isInfinite ||
        heightCm.isNaN || heightCm.isInfinite) {
      return 0.0;
    }
    // Nam: 10 * weight + 6.25 * height - 5 * age + 5
    // Nữ: 10 * weight + 6.25 * height - 5 * age - 161
    final isMale = gender.trim().toLowerCase() == 'nam' || gender.trim().toLowerCase() == 'male';
    final base = (10 * weightKg) + (6.25 * heightCm) - (5 * age);
    final bmr = isMale ? base + 5 : base - 161;
    if (bmr.isNaN || bmr.isInfinite || bmr <= 0) return 0.0;
    return bmr;
  }

  /// Tính TDEE (Total Daily Energy Expenditure) ước lượng dựa trên mức hoạt động
  static int calculateTdee({
    required double bmr,
    String activityLevel = 'moderate',
  }) {
    if (bmr <= 0 || bmr.isNaN || bmr.isInfinite) return 0;
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
    final tdee = bmr * factor;
    if (tdee.isNaN || tdee.isInfinite || tdee <= 0) return 0;
    return tdee.round();
  }

  /// Tính lượng nước uống khuyến nghị mỗi ngày (ml) dựa trên cân nặng
  /// Chuẩn y khoa: ~35ml trên mỗi kg thể trọng
  static int calculateRecommendedWater(double weightKg) {
    if (weightKg <= 0 || weightKg.isNaN || weightKg.isInfinite) return 2000;
    final raw = weightKg * 35;
    if (raw.isNaN || raw.isInfinite) return 2000;
    final ml = raw.round();
    // Làm tròn đến 50ml gần nhất
    return ((ml + 25) ~/ 50) * 50;
  }
}
