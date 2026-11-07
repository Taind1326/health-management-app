import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/models/medication_schedule.dart';
import 'package:health_app/services/medication_rules.dart';

void main() {
  final monday = DateTime(2026, 11, 2);
  MedicationSchedule schedule({
    String id = 's',
    MedicationRepeat repeat = MedicationRepeat.daily,
    List<int> weekdays = const [],
    DateTime? end,
    int hour = 8,
  }) => MedicationSchedule(
    id: id,
    medicationId: 'm',
    startDate: monday,
    endDate: end,
    hour: hour,
    minute: 0,
    repeat: repeat,
    weekdays: weekdays,
  );
  test('selected weekdays respect inclusive start/end bounds', () {
    final s = schedule(
      repeat: MedicationRepeat.selectedWeekdays,
      weekdays: [1, 3],
      end: monday.add(const Duration(days: 2)),
    );
    expect(MedicationRules.occursOn(s, monday), true);
    expect(
      MedicationRules.occursOn(s, monday.add(const Duration(days: 1))),
      false,
    );
    expect(
      MedicationRules.occursOn(s, monday.add(const Duration(days: 2))),
      true,
    );
    expect(
      MedicationRules.occursOn(s, monday.add(const Duration(days: 7))),
      false,
    );
  });
  test(
    'overlap detects daily and selected weekdays; different times allowed',
    () {
      expect(
        MedicationRules.overlaps(
          schedule(),
          schedule(
            id: 'b',
            repeat: MedicationRepeat.selectedWeekdays,
            weekdays: [3],
          ),
        ),
        true,
      );
      expect(
        MedicationRules.overlaps(schedule(), schedule(id: 'b', hour: 9)),
        false,
      );
      expect(
        MedicationRules.overlaps(
          schedule(repeat: MedicationRepeat.selectedWeekdays, weekdays: [1]),
          schedule(
            id: 'b',
            repeat: MedicationRepeat.selectedWeekdays,
            weekdays: [2],
          ),
        ),
        false,
      );
    },
  );
  test(
    'seven day estimate excludes taken/skipped without extending the course',
    () {
      final s = schedule(end: monday.add(const Duration(days: 2)));
      final logs = <Map<String, Object?>>[
        {
          'schedule_id': 's',
          'scheduled_at': MedicationRules.at(s, monday).toIso8601String(),
          'status': 'taken',
        },
        {
          'schedule_id': 's',
          'scheduled_at': MedicationRules.at(
            s,
            monday.add(const Duration(days: 1)),
          ).toIso8601String(),
          'status': 'skipped',
        },
      ];
      expect(MedicationRules.remainingSevenDays([s], logs, monday), 1);
      expect(MedicationRules.remainingSevenDays([s], [], monday), 3);
    },
  );
  test('empty occurrence range and invalid weekdays are rejected', () {
    expect(
      () => MedicationRules.validateSchedule(
        schedule(
          repeat: MedicationRepeat.selectedWeekdays,
          weekdays: [2],
          end: monday,
        ),
      ),
      throwsArgumentError,
    );
    expect(
      () => MedicationRules.validateSchedule(
        schedule(repeat: MedicationRepeat.selectedWeekdays, weekdays: [8]),
      ),
      throwsArgumentError,
    );
  });
  test('ended schedule describes entered dates, not recovery', () {
    final text = MedicationRules.courseLabel([
      schedule(repeat: MedicationRepeat.once),
    ], monday.add(const Duration(days: 1)));
    expect(text, 'Đã đến thời điểm kết thúc các lịch đã nhập');
  });
}
