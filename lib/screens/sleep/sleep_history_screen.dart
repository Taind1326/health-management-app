import 'package:flutter/material.dart';

import '../../models/sleep_record.dart';

/// Lịch sử giấc ngủ: biểu đồ 7 ngày gần nhất + danh sách các đêm đã ghi.
class SleepHistoryScreen extends StatelessWidget {
  final List<SleepRecord> records;
  final int goalMinutes;

  const SleepHistoryScreen({
    super.key,
    required this.records,
    required this.goalMinutes,
  });

  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  String _dmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _duration(int minutes) => '${minutes ~/ 60} giờ ${minutes % 60} phút';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = DateTime.now();

    // 7 ngày gần nhất, cũ -> mới. Ngày không có dữ liệu = 0.
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - (6 - i)),
    );
    final minutesPerDay = days.map((d) {
      final match = records.where((r) => r.isOn(d));
      return match.isEmpty ? 0 : match.first.durationMinutes;
    }).toList();
    final maxValue =
        [goalMinutes, ...minutesPerDay].reduce((a, b) => a > b ? a : b);

    final sorted = [...records]
      ..sort((a, b) => b.wakeTime.compareTo(a.wakeTime));

    return Scaffold(
      appBar: AppBar(title: const Text('Lịch sử giấc ngủ')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Giờ ngủ 7 ngày qua', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Cột đậm là đêm đạt mục tiêu ${_duration(goalMinutes)}',
              style: theme.textTheme.bodySmall),
          const SizedBox(height: 12),
          SizedBox(
            height: 150,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final value = minutesPerDay[i];
                final reached = value >= goalMinutes;
                final barHeight = maxValue == 0 ? 0.0 : 100 * value / maxValue;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        value == 0 ? '-' : (value / 60).toStringAsFixed(1),
                        style: theme.textTheme.labelSmall,
                      ),
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
          Text('Các đêm đã ghi', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (sorted.isEmpty)
            Center(
              child: Text('Chưa có lịch sử giấc ngủ.',
                  style: theme.textTheme.bodyMedium),
            ),
          ...sorted.map((r) {
            final diff = r.durationMinutes - goalMinutes;
            return Card(
              child: ListTile(
                title: Text('${_dmy(r.wakeTime)} - ${_duration(r.durationMinutes)}'),
                subtitle: Text('Ngủ ${_hm(r.sleepTime)}, thức ${_hm(r.wakeTime)}'),
                trailing: Text(
                  diff >= 0 ? 'Đạt mục tiêu' : 'Thiếu ${_duration(-diff)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}