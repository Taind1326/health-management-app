import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart' as p;
import 'package:health_app/models/medication.dart';
import 'package:health_app/models/medication_schedule.dart';
import 'package:health_app/models/reminder.dart';
import 'package:health_app/repositories/medication_repository.dart';
import 'package:health_app/utils/database_helper.dart';

import 'fixtures/database_v1.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late DatabaseHelper helper;
  late Database db;
  late String path;
  late MedicationRepository repo;
  final yesterday = DateTime.now().subtract(const Duration(days: 1));
  final when = DateTime(yesterday.year, yesterday.month, yesterday.day, 8);
  Medication med({String dose = '2', double? stock = 10}) => Medication(
    id: 'test-med',
    userId: 1,
    name: 'Thuốc thử',
    dosage: dose,
    unit: 'viên',
    note: '',
    stockAmount: stock,
  );
  MedicationSchedule schedule({int hour = 8}) => MedicationSchedule(
    id: 'test-schedule',
    medicationId: 'test-med',
    startDate: when,
    hour: hour,
    minute: 0,
  );
  Future<void> seed(Database database) async {
    for (var id = 1; id <= 2; id++) {
      await database.insert('users', {
        'id': id,
        'username': 'test$id',
        'phone': '090000000$id',
        'password_hash': 'test',
        'password_salt': 'test',
      });
    }
  }

  Future<void> create({double? stock = 10}) async {
    await repo.saveMedication(med(stock: stock), isNew: true);
    await repo.saveSchedules('test-med', [schedule()]);
  }

  Future<double?> balance() async =>
      (await repo.medications()).single.stockAmount;

  setUp(() async {
    path = p.join(
      await getDatabasesPath(),
      'tv5_test_${DateTime.now().microsecondsSinceEpoch}.db',
    );
    helper = DatabaseHelper.forTesting(path);
    db = await helper.database;
    await seed(db);
    repo = MedicationRepository(1, open: () async => db);
  });
  tearDown(() async {
    await helper.close();
    await deleteDatabase(path);
  });

  test('taken is idempotent; correction restores the original dose', () async {
    await create();
    await repo.record(schedule(), when, 'taken');
    await repo.record(schedule(), when, 'taken');
    expect(await balance(), 8);
    expect((await repo.logs()).length, 1);
    await repo.saveMedication(med(dose: '3', stock: 999), isNew: false);
    expect(await balance(), 8); // stale form cannot overwrite stock
    await repo.record(schedule(), when, 'skipped');
    expect(await balance(), 10);
    await repo.record(schedule(), when, 'taken');
    expect(await balance(), 8); // original snapshot dose 2, not new dose 3
    expect((await repo.logs()).single['dosage'], 2);
  });

  test('insufficient stock rolls back log and ledger together', () async {
    await create(stock: 1);
    await expectLater(repo.record(schedule(), when, 'taken'), throwsStateError);
    expect(await balance(), 1);
    expect(await repo.logs(), isEmpty);
    expect((await repo.movements('test-med')).length, 1);
  });

  test(
    'skip and untracked stock do not deduct; enabling is not retroactive',
    () async {
      await create(stock: null);
      await repo.record(schedule(), when, 'taken');
      expect(await balance(), isNull);
      await repo.adjustStock('test-med', 5, add: false, reason: 'Kiểm đếm');
      await repo.record(schedule(), when, 'taken');
      expect(await balance(), 5);
      await repo.record(schedule(), when, 'skipped');
      expect(await balance(), 5);
      await repo.record(schedule(), when, 'taken');
      expect(await balance(), 3);
    },
  );

  test(
    'restock and reconciliation have ledger; another user cannot mutate',
    () async {
      await create();
      await repo.adjustStock('test-med', 5, add: true, reason: 'Bổ sung');
      await repo.adjustStock('test-med', 4, add: false, reason: 'Đếm thực tế');
      expect(await balance(), 4);
      expect((await repo.movements('test-med')).length, 3);
      final other = MedicationRepository(2, open: () async => db);
      expect(await other.medications(), isEmpty);
      await expectLater(other.deleteMedication('test-med'), throwsStateError);
      await expectLater(
        other.adjustStock('test-med', 99, add: true, reason: 'X'),
        throwsStateError,
      );
      await expectLater(
        other.record(schedule(), when, 'taken'),
        throwsStateError,
      );
      expect(await balance(), 4);
    },
  );

  test('failed schedule edit preserves history and deduction', () async {
    await create();
    await repo.record(schedule(), when, 'taken');
    await expectLater(
      repo.saveSchedules('test-med', [schedule(hour: 9)]),
      throwsStateError,
    );
    expect((await repo.schedules()).single.hour, 8);
    expect((await repo.logs()).length, 1);
    expect(await balance(), 8);
  });

  test(
    'reminder disabled by user stays disabled when saving schedule',
    () async {
      await create();
      await repo.saveReminders([
        Reminder(
          id: 'r',
          userId: 1,
          title: 'Uống thuốc',
          type: ReminderType.medication,
          startDate: DateTime(when.year, when.month, when.day),
          hour: 8,
          minute: 0,
          repeat: ReminderRepeat.daily,
          isEnabled: false,
          medicationScheduleId: schedule().id,
        ),
      ]);
      await repo.saveSchedules('test-med', [schedule()]);
      expect((await repo.reminders()).single.isEnabled, false);
    },
  );

  test(
    'deleting medication preserves log snapshots and foreign keys',
    () async {
      await create();
      await repo.record(schedule(), when, 'taken');
      await repo.deleteMedication('test-med');
      expect(await repo.schedules(), isEmpty);
      final log = (await repo.logs()).single;
      expect(log['medication_name'], 'Thuốc thử');
      expect(log['schedule_id'], isNull);
      expect(log['medication_id'], isNull);
      expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
    },
  );

  test('data survives reopening the database', () async {
    await create();
    await repo.record(schedule(), when, 'taken');
    await helper.close();
    db = await helper.database;
    expect(await balance(), 8);
    expect((await repo.logs()).length, 1);
  });

  test('v1 to v2 preserves existing users, logs, and links', () async {
    await helper.close();
    await deleteDatabase(path);
    var old = await openDatabase(
      path,
      version: 1,
      onConfigure: (d) async {
        await d.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (d, _) async {
        for (final sql in databaseV1) {
          await d.execute(sql);
        }
      },
    );
    await seed(old);
    await old.insert('medications', {
      'id': 'test-med',
      'user_id': 1,
      'name': 'Thuốc cũ',
      'dosage': 2,
      'unit': 'viên',
      'note': '',
    });
    await old.insert('medication_schedules', {
      'id': 'test-schedule',
      'medication_id': 'test-med',
      'start_date': MedicationRepository.dateOnly(when),
      'hour': 8,
      'minute': 0,
      'repeat_type': 'daily',
    });
    await old.insert('medication_logs', {
      'id': 'old-log',
      'user_id': 1,
      'schedule_id': 'test-schedule',
      'scheduled_at': when.toIso8601String(),
      'taken_at': when.toIso8601String(),
      'status': 'taken',
      'medication_name': 'Thuốc cũ',
      'dosage': 2,
      'unit': 'viên',
    });
    await old.close();
    db = await helper.database;
    expect(await db.getVersion(), 2);
    expect((await repo.medications()).single.name, 'Thuốc cũ');
    expect(await balance(), isNull);
    expect((await repo.logs()).single['medication_id'], 'test-med');
    expect((await repo.logs()).single['stock_deducted'], 0);
    expect((await db.query('users')).length, 2);
    expect(await db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });
}
