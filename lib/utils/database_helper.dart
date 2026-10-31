import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Database SQLite dùng chung cho toàn bộ ứng dụng.
/// Đặt tại lib/utils/database_helper.dart.
/// Không chứa dữ liệu mẫu hoặc logic riêng của từng module.
class DatabaseHelper {
  DatabaseHelper._internal();
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;

  static const databaseName = 'health_app.db';
  static const databaseVersion = 1;

  // Dùng chung Future để các module mở đồng thời vẫn chỉ khởi tạo một lần.
  Future<Database>? _opening;

  Future<Database> get database => _opening ??= _openDatabase();

  Future<Database> _openDatabase() async {
    try {
      final directory = await getDatabasesPath();
      return await openDatabase(
        p.join(directory, databaseName),
        version: databaseVersion,
        onConfigure: (db) async {
          await db.execute('PRAGMA foreign_keys = ON');
        },
        onCreate: (db, version) async {
          // sqflite đã chạy onCreate trong transaction.
          for (final statement in _schema) {
            await db.execute(statement);
          }
        },
        onUpgrade: _onUpgrade,
      );
    } catch (_) {
      _opening = null; // Cho phép thử mở lại khi lần trước thất bại.
      rethrow;
    }
  }

  static Future<void> _onUpgrade(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    // Khi tăng databaseVersion, thêm migration ở đây.
    // Không DROP TABLE và tạo lại vì sẽ làm mất dữ liệu người dùng.
    throw UnsupportedError(
      'Chưa có migration từ version $oldVersion lên $newVersion.',
    );
  }

  /// Gọi trong CÙNG transaction tạo tài khoản và hồ sơ.
  /// Nếu settings đã tồn tại thì giữ nguyên mục tiêu của người dùng.
  static Future<void> ensureUserSettings(
    DatabaseExecutor executor,
    int userId,
  ) async {
    await executor.rawInsert(
      'INSERT INTO user_settings (user_id) VALUES (?) '
      'ON CONFLICT(user_id) DO NOTHING',
      [userId],
    );
  }

  /// Xóa tài khoản có xử lý thứ tự của liên kết foods RESTRICT.
  /// Gọi hàm này thay vì xóa trực tiếp bảng users.
  Future<void> deleteUser(int userId) async {
    final db = await database;
    await db.transaction((txn) async {
      // Xóa chi tiết qua meals trước khi cascade xóa foods.
      await txn.delete('meals', where: 'user_id = ?', whereArgs: [userId]);
      await txn.delete('users', where: 'id = ?', whereArgs: [userId]);
    });
  }

  /// Chỉ đóng khi không còn module sử dụng hoặc khi kết thúc test.
  /// Không gọi khi dispose từng màn hình.
  Future<void> close() async {
    final opening = _opening;
    if (opening == null) return;
    final db = await opening;
    await db.close();
    _opening = null;
  }

  static const List<String> _schema = [
    '''CREATE TABLE users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT NOT NULL COLLATE NOCASE UNIQUE
        CHECK(length(trim(username)) > 0 AND username = trim(username)),
      phone TEXT NOT NULL CHECK(length(trim(phone)) > 0),
      password_hash TEXT NOT NULL CHECK(length(password_hash) > 0),
      password_salt TEXT NOT NULL CHECK(length(password_salt) > 0)
    )''',
    '''CREATE TABLE health_profiles (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL UNIQUE REFERENCES users(id) ON DELETE CASCADE,
      full_name TEXT NOT NULL CHECK(length(trim(full_name)) > 0),
      age INTEGER CHECK(age IS NULL OR age > 0),
      gender TEXT CHECK(gender IS NULL OR gender IN ('male','female','other')),
      height_cm REAL CHECK(height_cm IS NULL OR height_cm > 0),
      weight_kg REAL CHECK(weight_kg IS NULL OR weight_kg > 0),
      bmi REAL CHECK(bmi IS NULL OR bmi > 0)
    )''',
    '''CREATE TABLE health_goals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      goal TEXT NOT NULL CHECK(length(trim(goal)) > 0)
    )''',
    '''CREATE TABLE health_metrics (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      metric_type TEXT NOT NULL CHECK(metric_type IN
        ('blood_pressure','heart_rate','weight','bmi')),
      value REAL NOT NULL CHECK(value > 0),
      value2 REAL,
      unit TEXT NOT NULL,
      note TEXT,
      recorded_at TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      CHECK((metric_type = 'blood_pressure' AND value2 IS NOT NULL AND value2 > 0)
        OR (metric_type <> 'blood_pressure' AND value2 IS NULL)),
      CHECK((metric_type = 'blood_pressure' AND unit = 'mmHg')
        OR (metric_type = 'heart_rate' AND unit = 'bpm')
        OR (metric_type = 'weight' AND unit = 'kg')
        OR (metric_type = 'bmi' AND unit = 'kg/m²'))
    )''',
    '''CREATE TABLE activities (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      type TEXT NOT NULL CHECK(type IN ('walking','running','cycling','other')),
      recorded_at TEXT NOT NULL,
      steps INTEGER NOT NULL CHECK(steps >= 0),
      distance_km REAL NOT NULL CHECK(distance_km >= 0),
      duration_minutes INTEGER NOT NULL CHECK(duration_minutes > 0),
      calories INTEGER NOT NULL CHECK(calories >= 0),
      origin TEXT,
      destination TEXT,
      CHECK(type <> 'cycling' OR steps = 0)
    )''',
    '''CREATE TABLE sleep_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      sleep_time TEXT NOT NULL,
      wake_time TEXT NOT NULL,
      wake_date TEXT NOT NULL,
      UNIQUE(user_id, wake_date)
    )''',
    '''CREATE TABLE foods (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      name TEXT NOT NULL CHECK(length(trim(name)) > 0),
      calories REAL NOT NULL CHECK(calories >= 0),
      protein REAL NOT NULL CHECK(protein >= 0),
      carb REAL NOT NULL CHECK(carb >= 0),
      fat REAL NOT NULL CHECK(fat >= 0),
      portion_grams REAL CHECK(portion_grams IS NULL OR portion_grams > 0)
    )''',
    '''CREATE TABLE meals (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      meal_type TEXT NOT NULL CHECK(meal_type IN ('breakfast','lunch','dinner')),
      meal_date TEXT NOT NULL
    )''',
    '''CREATE TABLE meal_details (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      meal_id INTEGER NOT NULL REFERENCES meals(id) ON DELETE CASCADE,
      food_id INTEGER NOT NULL REFERENCES foods(id) ON DELETE RESTRICT,
      quantity REAL NOT NULL CHECK(quantity > 0)
    )''',
    '''CREATE TABLE water_records (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      amount_ml INTEGER NOT NULL CHECK(amount_ml > 0),
      recorded_at TEXT NOT NULL
    )''',
    '''CREATE TABLE medications (
      id TEXT NOT NULL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      name TEXT NOT NULL CHECK(length(trim(name)) > 0),
      dosage REAL NOT NULL CHECK(dosage > 0),
      unit TEXT NOT NULL CHECK(unit IN ('viên','ml','gói','giọt','nhát xịt')),
      note TEXT NOT NULL DEFAULT ''
    )''',
    '''CREATE TABLE medication_schedules (
      id TEXT NOT NULL PRIMARY KEY,
      medication_id TEXT NOT NULL REFERENCES medications(id) ON DELETE CASCADE,
      start_date TEXT NOT NULL,
      end_date TEXT,
      hour INTEGER NOT NULL CHECK(hour BETWEEN 0 AND 23),
      minute INTEGER NOT NULL CHECK(minute BETWEEN 0 AND 59),
      repeat_type TEXT NOT NULL CHECK(repeat_type IN ('once','daily','selected_weekdays')),
      weekdays TEXT NOT NULL DEFAULT '[]',
      is_enabled INTEGER NOT NULL DEFAULT 1 CHECK(is_enabled IN (0,1)),
      CHECK(end_date IS NULL OR end_date >= start_date)
    )''',
    '''CREATE TABLE medication_logs (
      id TEXT NOT NULL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      schedule_id TEXT REFERENCES medication_schedules(id) ON DELETE SET NULL,
      scheduled_at TEXT NOT NULL,
      taken_at TEXT,
      status TEXT NOT NULL CHECK(status IN ('taken','skipped')),
      medication_name TEXT NOT NULL CHECK(length(trim(medication_name)) > 0),
      dosage REAL NOT NULL CHECK(dosage > 0),
      unit TEXT NOT NULL,
      note TEXT NOT NULL DEFAULT '',
      UNIQUE(schedule_id, scheduled_at),
      CHECK((status = 'taken' AND taken_at IS NOT NULL)
        OR (status = 'skipped' AND taken_at IS NULL))
    )''',
    '''CREATE TABLE reminders (
      id TEXT NOT NULL PRIMARY KEY,
      user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      title TEXT NOT NULL CHECK(length(trim(title)) > 0),
      type TEXT NOT NULL CHECK(type IN
        ('medication','water','activity','sleep','health_metric')),
      start_date TEXT NOT NULL,
      end_date TEXT,
      hour INTEGER NOT NULL CHECK(hour BETWEEN 0 AND 23),
      minute INTEGER NOT NULL CHECK(minute BETWEEN 0 AND 59),
      repeat_type TEXT NOT NULL CHECK(repeat_type IN ('once','daily','selected_weekdays')),
      weekdays TEXT NOT NULL DEFAULT '[]',
      is_enabled INTEGER NOT NULL DEFAULT 1 CHECK(is_enabled IN (0,1)),
      medication_schedule_id TEXT REFERENCES medication_schedules(id) ON DELETE CASCADE,
      CHECK(end_date IS NULL OR end_date >= start_date),
      CHECK(medication_schedule_id IS NULL OR type = 'medication')
    )''',
    '''CREATE TABLE user_settings (
      user_id INTEGER PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
      water_goal_ml INTEGER NOT NULL DEFAULT 2000 CHECK(water_goal_ml > 0),
      step_goal INTEGER NOT NULL DEFAULT 10000 CHECK(step_goal > 0),
      activity_goal_minutes INTEGER NOT NULL DEFAULT 30 CHECK(activity_goal_minutes > 0),
      sleep_goal_minutes INTEGER NOT NULL DEFAULT 480 CHECK(sleep_goal_minutes > 0),
      diet_mode TEXT NOT NULL DEFAULT 'balanced' CHECK(diet_mode IN
        ('balanced','weight_loss','muscle_gain','vegetarian'))
    )''',
    'CREATE INDEX idx_goals_user ON health_goals(user_id)',
    'CREATE INDEX idx_metrics_user_type_time ON health_metrics(user_id, metric_type, recorded_at)',
    'CREATE INDEX idx_activities_user_time ON activities(user_id, recorded_at)',
    'CREATE INDEX idx_foods_user ON foods(user_id)',
    'CREATE INDEX idx_meals_user_time ON meals(user_id, meal_date)',
    'CREATE INDEX idx_details_meal ON meal_details(meal_id)',
    'CREATE INDEX idx_details_food ON meal_details(food_id)',
    'CREATE INDEX idx_water_user_time ON water_records(user_id, recorded_at)',
    'CREATE INDEX idx_medications_user ON medications(user_id)',
    'CREATE INDEX idx_schedules_medication ON medication_schedules(medication_id)',
    'CREATE INDEX idx_logs_user_time ON medication_logs(user_id, scheduled_at)',
    'CREATE INDEX idx_reminders_user ON reminders(user_id)',
    'CREATE INDEX idx_reminders_schedule ON reminders(medication_schedule_id)',
  ];
}
