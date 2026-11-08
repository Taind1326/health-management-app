import 'package:flutter/material.dart';

import '../../models/sleep_record.dart';
import '../../repositories/sleep_repository.dart';
import '../../widgets/aurora_page.dart';
import '../../widgets/tv1_glass_widgets.dart';

/// Lịch sử giấc ngủ: biểu đồ 7 ngày gần nhất + danh sách các đêm đã ghi.
class SleepHistoryScreen extends StatefulWidget {
  final SleepRepository repository;
  final int goalMinutes;

  const SleepHistoryScreen({
    super.key,
    required this.repository,
    required this.goalMinutes,
  });

  @override
  State<SleepHistoryScreen> createState() => _SleepHistoryScreenState();
}

class _SleepHistoryScreenState extends State<SleepHistoryScreen> {
  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  List<SleepRecord> _records = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await widget.repository.getAll();
      if (!mounted) return;
      setState(() {
        _records = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không đọc được lịch sử giấc ngủ: ${errorText(e)}';
      });
    }
  }

  Future<void> _delete(SleepRecord r) async {
    final id = r.id;
    if (id == null) return;
    final ok = await showAuroraDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa giấc ngủ?'),
        content: Text('Bản ghi ngày ${_dmy(r.wakeTime)} sẽ bị xóa.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    try {
      await widget.repository.delete(id);
      await _load();
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(
        context,
        'Chưa xóa được giấc ngủ: ${errorText(e)}',
        onRetry: () => _delete(r),
      );
    }
  }

  String _dmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _duration(int minutes) => '${minutes ~/ 60} giờ ${minutes % 60} phút';

  @override
  Widget build(BuildContext context) {
    return AuroraPage(
      title: 'Lịch sử giấc ngủ',
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AuroraErrorView(message: _error!, onRetry: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _load();
                })
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final goalMinutes = widget.goalMinutes;
    final now = DateTime.now();

    // 7 ngày gần nhất, cũ -> mới. Ngày không có dữ liệu = 0.
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - (6 - i)),
    );
    final minutesPerDay = days.map((d) {
      final match = _records.where((r) => r.isOn(d));
      return match.isEmpty ? 0 : match.first.durationMinutes;
    }).toList();
    final maxValue =
        [goalMinutes, ...minutesPerDay].reduce((a, b) => a > b ? a : b);

    final sorted = [..._records]
      ..sort((a, b) => b.wakeTime.compareTo(a.wakeTime));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Tv1GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Giờ ngủ 7 ngày qua', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Cột sáng là đêm đạt mục tiêu ${_duration(goalMinutes)}',
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
                                  ? const Color(0xFF6EE7B7)
                                  : Colors.white.withValues(alpha: 0.35),
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
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Các đêm đã ghi', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        if (sorted.isEmpty)
          Center(
            child: Text('Chưa có lịch sử giấc ngủ.',
                style: theme.textTheme.bodyMedium),
          ),
        ...sorted.map((r) {
          final diff = r.durationMinutes - goalMinutes;
          return Tv1GlassCard(
            margin: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${_dmy(r.wakeTime)} - ${_duration(r.durationMinutes)}',
                          style: theme.textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text('Ngủ ${_hm(r.sleepTime)}, thức ${_hm(r.wakeTime)}',
                          style: theme.textTheme.bodySmall),
                      const SizedBox(height: 2),
                      Text(
                        diff >= 0 ? 'Đạt mục tiêu' : 'Thiếu ${_duration(-diff)}',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Xóa giấc ngủ',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _delete(r),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}