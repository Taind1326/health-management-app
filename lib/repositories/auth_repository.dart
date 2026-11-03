import 'package:sqflite/sqflite.dart';

import '../models/health_goal.dart';
import '../models/health_profile.dart';
import '../models/user.dart';
import '../utils/database_helper.dart';
import '../utils/hash_util.dart';

/// Repository xử lý dữ liệu Tài khoản, Hồ sơ và Mục tiêu với SQLite
class AuthRepository {
  final DatabaseHelper _dbHelper;

  AuthRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<Database> get _db => _dbHelper.database;

  /// Tự động khởi tạo tài khoản mẫu user01 / 123456 nếu chưa có trong DB
  Future<void> seedSampleUserIfNeeded() async {
    final db = await _db;
    final existing = await db.query(
      'users',
      where: 'username = ? COLLATE NOCASE',
      whereArgs: ['user01'],
      limit: 1,
    );

    if (existing.isEmpty) {
      await db.transaction((txn) async {
        final salt = HashUtil.generateSalt();
        final hash = HashUtil.hashPassword('123456', salt);

        final userId = await txn.insert('users', {
          'id': 1,
          'username': 'user01',
          'phone': '0901234567',
          'email': 'user01@example.com',
          'password_hash': hash,
          'password_salt': salt,
        });

        await txn.insert('health_profiles', {
          'user_id': userId,
          'full_name': 'Nguyễn Văn A',
          'age': 20,
          'gender': 'male',
          'height_cm': 170.0,
          'weight_kg': 65.0,
          'bmi': 22.49,
        });

        await DatabaseHelper.ensureUserSettings(txn, userId);

        await txn.insert('health_goals', {
          'user_id': userId,
          'goal': 'Tập thể dục 30 phút mỗi ngày',
        });
        await txn.insert('health_goals', {
          'user_id': userId,
          'goal': 'Uống đủ 2 lít nước mỗi ngày',
        });
      });
    }
  }

  /// Tìm người dùng theo Username, Email hoặc Số điện thoại
  Future<User?> findUserByIdentifier(String identifier) async {
    final clean = identifier.trim();
    if (clean.isEmpty) return null;

    final db = await _db;
    final results = await db.query(
      'users',
      where: 'username = ? COLLATE NOCASE OR phone = ? OR email = ? COLLATE NOCASE',
      whereArgs: [clean, clean, clean],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return User.fromMap(results.first);
  }

  /// Xác thực mật khẩu người dùng
  Future<User?> authenticate(String identifier, String password) async {
    await seedSampleUserIfNeeded();
    final user = await findUserByIdentifier(identifier);
    if (user == null || user.passwordSalt == null || user.passwordHash == null) {
      return null;
    }

    final inputHash = HashUtil.hashPassword(password, user.passwordSalt!);
    if (inputHash == user.passwordHash) {
      return user;
    }
    return null;
  }

  /// Kiểm tra username đã tồn tại chưa
  Future<bool> isUsernameTaken(String username) async {
    final db = await _db;
    final results = await db.query(
      'users',
      where: 'username = ? COLLATE NOCASE',
      whereArgs: [username.trim()],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Kiểm tra số điện thoại đã tồn tại chưa
  Future<bool> isPhoneTaken(String phone) async {
    final clean = phone.trim();
    if (clean.isEmpty) return false;
    final db = await _db;
    final results = await db.query(
      'users',
      where: 'phone = ?',
      whereArgs: [clean],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Kiểm tra email đã tồn tại chưa
  Future<bool> isEmailTaken(String email) async {
    final clean = email.trim();
    if (clean.isEmpty) return false;
    final db = await _db;
    final results = await db.query(
      'users',
      where: 'email = ? COLLATE NOCASE',
      whereArgs: [clean],
      limit: 1,
    );
    return results.isNotEmpty;
  }

  /// Đăng ký tài khoản mới và khởi tạo hồ sơ sức khỏe
  Future<User> registerUser({
    required String fullName,
    String? phone,
    String? email,
    required String username,
    required String password,
  }) async {
    final db = await _db;
    final salt = HashUtil.generateSalt();
    final hash = HashUtil.hashPassword(password, salt);

    int newUserId = 0;
    await db.transaction((txn) async {
      newUserId = await txn.insert('users', {
        'username': username.trim(),
        'phone': (phone != null && phone.trim().isNotEmpty) ? phone.trim() : null,
        'email': (email != null && email.trim().isNotEmpty) ? email.trim() : null,
        'password_hash': hash,
        'password_salt': salt,
      });

      // Tạo hồ sơ sức khỏe ban đầu
      await txn.insert('health_profiles', {
        'user_id': newUserId,
        'full_name': fullName.trim(),
        'age': null,
        'gender': 'male',
        'height_cm': null,
        'weight_kg': null,
        'bmi': null,
      });

      // Tạo user_settings mặc định
      await DatabaseHelper.ensureUserSettings(txn, newUserId);
    });

    return User(
      id: newUserId,
      username: username.trim(),
      phone: phone?.trim(),
      email: email?.trim(),
      password: '',
      passwordHash: hash,
      passwordSalt: salt,
    );
  }

  /// Lấy hồ sơ sức khỏe của người dùng
  Future<HealthProfile> getProfile(int userId) async {
    final db = await _db;
    final results = await db.query(
      'health_profiles',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );

    if (results.isNotEmpty) {
      return HealthProfile.fromMap(results.first);
    }

    // Dự phòng
    return HealthProfile(
      id: 0,
      userId: userId,
      fullName: 'Người dùng',
      age: 0,
      gender: 'Nam',
      height: 0.0,
      weight: 0.0,
      bmi: 0.0,
    );
  }

  /// Cập nhật hồ sơ sức khỏe
  Future<void> updateProfile(HealthProfile profile) async {
    final db = await _db;
    await db.insert(
      'health_profiles',
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lấy danh sách mục tiêu
  Future<List<HealthGoal>> getGoals(int userId) async {
    final db = await _db;
    final results = await db.query(
      'health_goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );

    return results.map((e) => HealthGoal.fromMap(e)).toList();
  }

  /// Thêm mục tiêu mới
  Future<HealthGoal> addGoal(int userId, String goalText) async {
    final db = await _db;
    final id = await db.insert('health_goals', {
      'user_id': userId,
      'goal': goalText.trim(),
    });

    return HealthGoal(id: id, userId: userId, goal: goalText.trim());
  }

  /// Xóa mục tiêu theo ID
  Future<int> deleteGoal(int goalId) async {
    final db = await _db;
    return await db.delete(
      'health_goals',
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  /// Xóa mục tiêu theo nội dung goal của user
  Future<int> deleteGoalByText(int userId, String goalText) async {
    final db = await _db;
    return await db.delete(
      'health_goals',
      where: 'user_id = ? AND goal = ?',
      whereArgs: [userId, goalText.trim()],
    );
  }

  /// Đồng bộ mục tiêu sang bảng user_settings của nhóm
  Future<void> syncUserSettings(
    int userId, {
    int? waterGoalMl,
    int? stepGoal,
    String? dietMode,
  }) async {
    final db = await _db;
    await DatabaseHelper.ensureUserSettings(db, userId);

    final values = <String, dynamic>{};
    if (waterGoalMl != null && waterGoalMl > 0) {
      values['water_goal_ml'] = waterGoalMl;
    }
    if (stepGoal != null && stepGoal > 0) {
      values['step_goal'] = stepGoal;
    }
    if (dietMode != null && dietMode.isNotEmpty) {
      values['diet_mode'] = dietMode;
    }

    if (values.isNotEmpty) {
      await db.update(
        'user_settings',
        values,
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    }
  }
}
