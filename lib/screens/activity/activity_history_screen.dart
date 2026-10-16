import 'package:flutter/material.dart';

import '../../models/activity.dart';

/// Lịch sử hoạt động: biểu đồ số bước 7 ngày gần nhất + danh sách theo ngày.
class ActivityHistoryScreen extends StatelessWidget {
  final List<Activity> activities;
  final int stepGoal;

  const ActivityHistoryScreen({
    super.key,
    required this.activities,
    required this.stepGoal,
  });

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  String _dmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // 7 ngày gần nhất, cũ -> mới.
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - (6 - i)),
    );
    final stepsPerDay = days
        .map((d) => activities
            .where((a) => a.isOn(d))
            .fold<int>(0, (s, a) => s + a.steps))
        .toList();
    final maxValue = [stepGoal, ...stepsPerDay].reduce((a, b) => a > b ? a : b);

    // Nhóm theo ngày, mới nhất trước.
    final sorted = [...activities]..sort((a, b) => b.date.compareTo(a.date));
    final dates = <DateTime>[];
    for (final a in sorted) {
      final d = DateTime(a.date.year, a.date.month, a.date.day);
      if (dates.isEmpty || dates.last != d) dates.add(d);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử hoạt động')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Số bước 7 ngày qua', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Cột đậm là ngày đạt mục tiêu $stepGoal bước',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final value = stepsPerDay[i];
                final reached = value >= stepGoal;
                final barHeight = maxValue == 0 ? 0.0 : 100 * value / maxValue;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text('$value', style: theme.textTheme.labelSmall),
                      const SizedBox(height: 4),
                      Container(
                        height: barHeight,
                        margin: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: reached
                              ? theme.colorScheme.primary
                              : theme.colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(_weekdays[days[i].weekday - 1],
                          style: theme.textTheme.labelSmall),
                    ],
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          if (dates.isEmpty)
            Center(
              child: Text('Chưa có lịch sử hoạt động.',
                  style: theme.textTheme.bodyMedium),
            ),
          for (final d in dates) ...[
            Text(_dmy(d), style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            ...sorted.where((a) => a.isOn(d)).map(
                  (a) => Card(
                    child: ListTile(
                      title: Text('${a.type} - ${a.steps} bước'),
                      subtitle: Text(
                        '${_hm(a.date)} - ${a.durationMinutes} phút - ${a.distanceKm.toStringAsFixed(1)} km - ${a.calories} kcal',
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}