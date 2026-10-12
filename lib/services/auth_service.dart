import '../models/user.dart';
import '../models/health_profile.dart';
import '../models/health_goal.dart';

class AuthService {
  // Singleton pattern để dùng chung nguồn dữ liệu trong toàn bộ phiên chạy ứng dụng
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initSampleData();
  }

  // Danh sách tài khoản in-memory
  final List<User> _users = [];

  // Lưu hồ sơ theo userId: Map<userId, HealthProfile>
  final Map<int, HealthProfile> _profiles = {};

  // Lưu danh sách mục tiêu theo userId: Map<userId, List<HealthGoal>>
  final Map<int, List<HealthGoal>> _goals = {};

  // Người dùng đang đăng nhập trong phiên hiện tại
  User? _currentUser;
  User? get currentUser => _currentUser;

  void _initSampleData() {
    // Tài khoản mẫu ban đầu: user01 / 123456
    final sampleUser = User(
      id: 1,
      username: 'user01',
      phone: '0901234567',
      password: '123456',
    );
    _users.add(sampleUser);

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
    _users.clear();
    _profiles.clear();
    _goals.clear();
    _currentUser = null;
    _initSampleData();
  }

  // Đăng nhập tài khoản
  User? login(String username, String password) {
    for (final user in _users) {
      if (user.username == username && user.password == password) {
        _currentUser = user;
        return user;
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

  // Đăng ký tài khoản mới kèm khởi tạo hồ sơ sức khỏe liên kết với userId
  User register({
    required String fullName,
    required String phone,
    required String username,
    required String password,
  }) {
    final newId = _users.isEmpty ? 1 : _users.map((u) => u.id).reduce((a, b) => a > b ? a : b) + 1;
    final newUser = User(
      id: newId,
      username: username,
      phone: phone,
      password: password,
    );
    _users.add(newUser);

    // Hồ sơ sức khỏe ban đầu liên kết với User.id và lưu đúng họ tên đã đăng ký
    _profiles[newId] = HealthProfile(
      id: newId,
      userId: newId,
      fullName: fullName,
      age: 20,
      gender: 'Nam',
      height: 170.0,
      weight: 65.0,
      bmi: 22.49,
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
      age: 20,
      gender: 'Nam',
      height: 170.0,
      weight: 65.0,
      bmi: 22.49,
    );
    _profiles[userId] = defaultProfile;
    return defaultProfile;
  }

  // Cập nhật hồ sơ sức khỏe
  void updateProfile(HealthProfile updatedProfile) {
    _profiles[updatedProfile.userId] = updatedProfile;
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
    return newGoal;
  }
}
