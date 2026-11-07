import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../models/medication.dart';
import '../models/medication_schedule.dart';
import '../models/reminder.dart';
import '../utils/database_helper.dart';
import '../services/medication_rules.dart';

class MedicationRepository {
  final int userId;
  final Future<Database> Function() _open;
  MedicationRepository(this.userId, {Future<Database> Function()? open})
    : _open = open ?? (() => DatabaseHelper().database);

  Future<Medication> _owned(DatabaseExecutor db, String id) async {
    final rows = await db.query(
      'medications',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
    if (rows.isEmpty)
      throw StateError('Thuốc không còn tồn tại trong tài khoản.');
    return medicationFromMap(rows.first);
  }

  static Medication medicationFromMap(Map<String, Object?> m) => Medication(
    id: m['id'] as String,
    userId: m['user_id'] as int,
    name: m['name'] as String,
    dosage: '${m['dosage']}',
    unit: m['unit'] as String,
    note: m['note'] as String,
    stockAmount: (m['stock_amount'] as num?)?.toDouble(),
  );

  Future<List<Medication>> medications() async {
    final rows = await (await _open()).query(
      'medications',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(medicationFromMap).toList();
  }

  Future<void> saveMedication(Medication med, {required bool isNew}) async {
    final dose = double.tryParse(med.dosage.replaceAll(',', '.'));
    if (med.userId != userId ||
        !RegExp(r'\p{L}', unicode: true).hasMatch(med.name) ||
        dose == null ||
        !dose.isFinite ||
        dose <= 0 ||
        !['viên', 'ml', 'gói', 'giọt', 'nhát xịt'].contains(med.unit) ||
        (med.stockAmount != null &&
            (!med.stockAmount!.isFinite || med.stockAmount! < 0))) {
      throw ArgumentError('Thông tin thuốc hoặc lượng tồn không hợp lệ.');
    }
    final db = await _open();
    await db.transaction((tx) async {
      final values = <String, Object?>{
        'name': med.name.trim(),
        'dosage': dose,
        'unit': med.unit,
        'note': med.note.trim(),
      };
      if (isNew) {
        await tx.insert('medications', {
          ...values,
          'id': med.id,
          'user_id': userId,
          'stock_amount': med.stockAmount,
        });
        if (med.stockAmount != null) {
          await _movement(
            tx,
            med.id,
            med.stockAmount!,
            med.stockAmount!,
            'Lượng ban đầu',
          );
        }
      } else {
        final old = await _owned(tx, med.id);
        if (old.unit != med.unit) {
          final logs = await tx.query(
            'medication_logs',
            where: 'medication_id = ?',
            whereArgs: [med.id],
            limit: 1,
          );
          if (old.stockAmount != null || logs.isNotEmpty) {
            throw StateError(
              'Không đổi đơn vị khi đã theo dõi tồn hoặc ghi nhận uống. Hãy tạo thuốc mới.',
            );
          }
        }
        // Không ghi đè stock bằng bản snapshot cũ từ biểu mẫu.
        await tx.update(
          'medications',
          values,
          where: 'id = ? AND user_id = ?',
          whereArgs: [med.id, userId],
        );
      }
    });
  }

  Future<void> deleteMedication(String id) async {
    final db = await _open();
    await db.transaction((tx) async {
      await _owned(tx, id);
      await tx.delete(
        'medications',
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
    });
  }

  static String dateOnly(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<List<MedicationSchedule>> schedules() async {
    final rows = await (await _open()).rawQuery(
      'SELECT s.* FROM medication_schedules s JOIN medications m ON m.id=s.medication_id WHERE m.user_id=?',
      [userId],
    );
    return rows
        .map(
          (m) => MedicationSchedule(
            id: m['id'] as String,
            medicationId: m['medication_id'] as String,
            startDate: DateTime.parse(m['start_date'] as String),
            endDate: m['end_date'] == null
                ? null
                : DateTime.parse(m['end_date'] as String),
            hour: m['hour'] as int,
            minute: m['minute'] as int,
            repeat:
                MedicationRepeat.values[[
                  'once',
                  'daily',
                  'selected_weekdays',
                ].indexOf(m['repeat_type'] as String)],
            weekdays: (jsonDecode(m['weekdays'] as String) as List).cast<int>(),
            isEnabled: m['is_enabled'] == 1,
          ),
        )
        .toList();
  }

  Future<void> saveSchedules(
    String medicationId,
    List<MedicationSchedule> items,
  ) async {
    final ids = <String>{};
    for (final item in items) {
      if (!ids.add(item.id) || item.medicationId != medicationId)
        throw ArgumentError('Lịch không hợp lệ.');
      MedicationRules.validateSchedule(item);
      if (items.any(
        (other) => other.id != item.id && MedicationRules.overlaps(item, other),
      )) {
        throw StateError('Các lịch của cùng thuốc bị chồng giờ uống.');
      }
    }
    final db = await _open();
    await db.transaction((tx) async {
      await _owned(tx, medicationId);
      final old = await tx.query(
        'medication_schedules',
        where: 'medication_id = ?',
        whereArgs: [medicationId],
      );
      final oldById = {for (final row in old) row['id'] as String: row};
      for (final row in old) {
        if (!ids.contains(row['id']))
          await tx.delete(
            'medication_schedules',
            where: 'id = ?',
            whereArgs: [row['id']],
          );
      }
      for (final item in items) {
        final values = <String, Object?>{
          'medication_id': medicationId,
          'start_date': dateOnly(item.startDate),
          'end_date': item.endDate == null ? null : dateOnly(item.endDate!),
          'hour': item.hour,
          'minute': item.minute,
          'repeat_type': [
            'once',
            'daily',
            'selected_weekdays',
          ][item.repeat.index],
          'weekdays': jsonEncode(item.weekdays),
          'is_enabled': item.isEnabled ? 1 : 0,
        };
        if (oldById.containsKey(item.id)) {
          // Lịch có log không được thay đổi ngày/giờ/lặp; hãy tạo lịch mới.
          final previous = oldById[item.id]!;
          final changed = [
            'start_date',
            'end_date',
            'hour',
            'minute',
            'repeat_type',
            'weekdays',
          ].any((k) => previous[k] != values[k]);
          if (changed) {
            final logs = await tx.query(
              'medication_logs',
              where: 'schedule_id = ?',
              whereArgs: [item.id],
              limit: 1,
            );
            if (logs.isNotEmpty)
              throw StateError(
                'Lịch đã có lịch sử: tạo lịch mới để đổi ngày hoặc giờ.',
              );
          }
          await tx.update(
            'medication_schedules',
            values,
            where: 'id = ? AND medication_id = ?',
            whereArgs: [item.id, medicationId],
          );
          final reminderValues = Map<String, Object?>.from(values)
            ..remove('medication_id')
            ..remove('is_enabled');
          // Giữ lựa chọn tắt nhắc của người dùng; tắt lịch thì tắt nhắc liên kết.
          if (!item.isEnabled) reminderValues['is_enabled'] = 0;
          await tx.update(
            'reminders',
            reminderValues,
            where: 'medication_schedule_id = ? AND user_id = ?',
            whereArgs: [item.id, userId],
          );
        } else {
          final at = MedicationRules.at(item, item.startDate);
          if (item.repeat == MedicationRepeat.once &&
              !at.isAfter(DateTime.now()))
            throw StateError('Lịch một lần mới phải ở tương lai.');
          await tx.insert('medication_schedules', {'id': item.id, ...values});
        }
      }
    });
  }

  Future<List<Map<String, Object?>>> logs() async => (await _open()).query(
    'medication_logs',
    where: 'user_id = ?',
    whereArgs: [userId],
    orderBy: 'scheduled_at DESC',
  );

  /// Idempotent: cùng kết quả không trừ lần hai. Sửa kết quả hoàn/chỉnh tồn
  /// bằng đúng lượng đã trừ trước đó, không dùng liều mới sau khi sửa thuốc.
  Future<void> record(
    MedicationSchedule schedule,
    DateTime when,
    String status,
  ) async {
    if (!['taken', 'skipped'].contains(status))
      throw ArgumentError('Trạng thái không hợp lệ.');
    final db = await _open();
    await db.transaction((tx) async {
      final schedules = await tx.rawQuery(
        'SELECT s.* FROM medication_schedules s JOIN medications m ON m.id=s.medication_id WHERE s.id=? AND m.user_id=?',
        [schedule.id, userId],
      );
      if (schedules.isEmpty) throw StateError('Lịch không còn tồn tại.');
      final current = schedules.first;
      // Không dùng lịch snapshot nếu đã thay đổi trong khi đang mở màn hình.
      if (current['medication_id'] != schedule.medicationId ||
          current['hour'] != when.hour ||
          current['minute'] != when.minute ||
          current['start_date'] != dateOnly(schedule.startDate) ||
          current['end_date'] !=
              (schedule.endDate == null ? null : dateOnly(schedule.endDate!)) ||
          current['repeat_type'] !=
              ['once', 'daily', 'selected_weekdays'][schedule.repeat.index] ||
          current['weekdays'] != jsonEncode(schedule.weekdays))
        throw StateError('Lịch đã thay đổi, hãy tải lại.');
      if (when.second != 0 ||
          when.millisecond != 0 ||
          when.microsecond != 0 ||
          when.isAfter(DateTime.now()) ||
          !MedicationRules.occursOn(schedule, when))
        throw StateError('Chỉ xác nhận lần uống đã đến hạn và đúng lịch.');
      final med = await _owned(tx, schedule.medicationId);
      final stamp = when.toIso8601String();
      final old = await tx.query(
        'medication_logs',
        where: 'schedule_id = ? AND scheduled_at = ? AND user_id = ?',
        whereArgs: [schedule.id, stamp, userId],
      );
      if (old.isNotEmpty && old.first['status'] == status) return;
      if (old.isEmpty && current['is_enabled'] != 1)
        throw StateError('Lịch đang tắt.');
      final previous = old.isEmpty ? null : old.first;
      final dose =
          (previous?['dosage'] as num?)?.toDouble() ?? double.parse(med.dosage);
      final oldDeducted =
          (previous?['stock_deducted'] as num?)?.toDouble() ?? 0;
      final deducted = status == 'taken' && med.stockAmount != null
          ? dose
          : 0.0;
      final delta = oldDeducted - deducted;
      final balance = med.stockAmount == null ? null : med.stockAmount! + delta;
      if (balance != null && balance < -0.0000001)
        throw StateError(
          'Lượng tồn đã ghi nhận không đủ. Kiểm tra và điều chỉnh lượng thực tế trước khi xác nhận.',
        );
      final id =
          previous?['id'] as String? ??
          '${schedule.id}-${when.millisecondsSinceEpoch}';
      final values = <String, Object?>{
        'user_id': userId,
        'schedule_id': schedule.id,
        'medication_id': med.id,
        'scheduled_at': stamp,
        'status': status,
        'taken_at': status == 'taken' ? DateTime.now().toIso8601String() : null,
        'medication_name': previous?['medication_name'] ?? med.name,
        'dosage': dose,
        'unit': previous?['unit'] ?? med.unit,
        'note': previous?['note'] ?? med.note,
        'stock_deducted': deducted,
      };
      if (previous == null) {
        await tx.insert('medication_logs', {'id': id, ...values});
      } else {
        await tx.update(
          'medication_logs',
          values,
          where: 'id = ? AND user_id = ?',
          whereArgs: [id, userId],
        );
      }
      if (balance != null && delta != 0) {
        final safe = balance < 0 ? 0.0 : balance;
        await tx.update(
          'medications',
          {'stock_amount': safe},
          where: 'id = ? AND user_id = ?',
          whereArgs: [med.id, userId],
        );
        await _movement(
          tx,
          med.id,
          delta,
          safe,
          'Đổi kết quả thành ${status == 'taken' ? 'đã uống' : 'bỏ qua'}',
          logId: id,
        );
      }
    });
  }

  Future<void> adjustStock(
    String id,
    double amount, {
    required bool add,
    required String reason,
  }) async {
    if (!amount.isFinite ||
        amount < 0 ||
        (add && amount == 0) ||
        reason.trim().isEmpty)
      throw ArgumentError('Lượng thuốc và lý do chưa hợp lệ.');
    final db = await _open();
    await db.transaction((tx) async {
      final med = await _owned(tx, id);
      if (add && med.stockAmount == null)
        throw StateError('Hãy nhập lượng hiện có để bắt đầu theo dõi trước.');
      final balance = add ? med.stockAmount! + amount : amount;
      if (!balance.isFinite) throw ArgumentError('Lượng thuốc quá lớn.');
      final delta = balance - (med.stockAmount ?? 0);
      await tx.update(
        'medications',
        {'stock_amount': balance},
        where: 'id = ? AND user_id = ?',
        whereArgs: [id, userId],
      );
      await _movement(tx, id, delta, balance, reason.trim());
    });
  }

  Future<void> _movement(
    DatabaseExecutor tx,
    String med,
    double delta,
    double balance,
    String reason, {
    String? logId,
  }) async {
    await tx.insert('medication_stock_movements', {
      'medication_id': med,
      'user_id': userId,
      'log_id': logId,
      'delta': delta,
      'balance_after': balance,
      'reason': reason,
      'recorded_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> movements(String id) async {
    final db = await _open();
    await _owned(db, id);
    return db.query(
      'medication_stock_movements',
      where: 'medication_id = ? AND user_id = ?',
      whereArgs: [id, userId],
      orderBy: 'id DESC',
    );
  }

  Future<List<Reminder>> reminders() async {
    final rows = await (await _open()).query(
      'reminders',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
    return rows
        .map(
          (m) => Reminder(
            id: m['id'] as String,
            userId: userId,
            title: m['title'] as String,
            type:
                ReminderType.values[[
                  'medication',
                  'water',
                  'activity',
                  'sleep',
                  'health_metric',
                ].indexOf(m['type'] as String)],
            startDate: DateTime.parse(m['start_date'] as String),
            endDate: m['end_date'] == null
                ? null
                : DateTime.parse(m['end_date'] as String),
            hour: m['hour'] as int,
            minute: m['minute'] as int,
            repeat:
                ReminderRepeat.values[[
                  'once',
                  'daily',
                  'selected_weekdays',
                ].indexOf(m['repeat_type'] as String)],
            weekdays: (jsonDecode(m['weekdays'] as String) as List).cast<int>(),
            isEnabled: m['is_enabled'] == 1,
            medicationScheduleId: m['medication_schedule_id'] as String?,
          ),
        )
        .toList();
  }

  Future<void> saveReminders(List<Reminder> items) async {
    final db = await _open();
    await db.transaction((tx) async {
      final old = await tx.query(
        'reminders',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      final linkedSchedules = <String>{};
      final ids = items.map((e) => e.id).toSet();
      if (ids.length != items.length) throw ArgumentError('Trùng mã nhắc nhở.');
      for (final row in old) {
        if (!ids.contains(row['id']))
          await tx.delete(
            'reminders',
            where: 'id = ? AND user_id = ?',
            whereArgs: [row['id'], userId],
          );
      }
      for (final item in items) {
        if (item.userId != userId || item.title.trim().isEmpty)
          throw ArgumentError('Nhắc nhở không thuộc tài khoản.');
        if ((item.type == ReminderType.medication) !=
            (item.medicationScheduleId != null)) {
          throw ArgumentError('Nhắc thuốc phải liên kết với một lịch uống.');
        }
        if (item.medicationScheduleId != null) {
          if (!linkedSchedules.add(item.medicationScheduleId!))
            throw StateError('Một lịch uống chỉ có một lịch nhắc.');
          final owner = await tx.rawQuery(
            'SELECT s.* FROM medication_schedules s JOIN medications m ON m.id=s.medication_id WHERE s.id=? AND m.user_id=?',
            [item.medicationScheduleId, userId],
          );
          if (owner.isEmpty) throw StateError('Lịch thuốc không còn tồn tại.');
          final linked = owner.first;
          if ((item.isEnabled && linked['is_enabled'] != 1) ||
              linked['hour'] != item.hour ||
              linked['minute'] != item.minute ||
              linked['start_date'] != dateOnly(item.startDate) ||
              linked['end_date'] !=
                  (item.endDate == null ? null : dateOnly(item.endDate!)) ||
              linked['repeat_type'] !=
                  ['once', 'daily', 'selected_weekdays'][item.repeat.index] ||
              linked['weekdays'] != jsonEncode(item.weekdays)) {
            throw StateError(
              'Lịch thuốc đã thay đổi hoặc đang tắt. Hãy tải lại.',
            );
          }
        }
        MedicationRules.validateSchedule(
          MedicationSchedule(
            id: item.id,
            medicationId: '',
            startDate: item.startDate,
            endDate: item.endDate,
            hour: item.hour,
            minute: item.minute,
            repeat: MedicationRepeat.values[item.repeat.index],
            weekdays: item.weekdays,
          ),
        );
        final values = <String, Object?>{
          'user_id': userId,
          'title': item.title,
          'type': [
            'medication',
            'water',
            'activity',
            'sleep',
            'health_metric',
          ][item.type.index],
          'start_date': dateOnly(item.startDate),
          'end_date': item.endDate == null ? null : dateOnly(item.endDate!),
          'hour': item.hour,
          'minute': item.minute,
          'repeat_type': [
            'once',
            'daily',
            'selected_weekdays',
          ][item.repeat.index],
          'weekdays': jsonEncode(item.weekdays),
          'is_enabled': item.isEnabled ? 1 : 0,
          'medication_schedule_id': item.medicationScheduleId,
        };
        if (old.any((e) => e['id'] == item.id)) {
          await tx.update(
            'reminders',
            values,
            where: 'id = ? AND user_id = ?',
            whereArgs: [item.id, userId],
          );
        } else {
          await tx.insert('reminders', {'id': item.id, ...values});
        }
      }
    });
  }
}
