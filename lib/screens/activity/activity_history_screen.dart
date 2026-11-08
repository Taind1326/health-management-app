import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../repositories/activity_repository.dart';
import '../../widgets/aurora_page.dart';
import '../../widgets/tv1_glass_widgets.dart';

/// Lịch sử hoạt động: biểu đồ số bước 7 ngày gần nhất + danh sách theo ngày.
class ActivityHistoryScreen extends StatefulWidget {
  final ActivityRepository repository;
  final int stepGoal;

  const ActivityHistoryScreen({
    super.key,
    required this.repository,
    required this.stepGoal,
  });

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  static const _weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  List<Activity> _activities = [];
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
        _activities = list;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không đọc được lịch sử hoạt động: ${errorText(e)}';
      });
    }
  }

  Future<void> _delete(Activity a) async {
    final id = a.id;
    if (id == null) return;
    final ok = await showAuroraDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa hoạt động?'),
        content: Text(
          '${a.typeLabel} lúc ${_hm(a.date)} ngày ${_dmy(a.date)} sẽ bị xóa.',
        ),
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
        'Chưa xóa được hoạt động: ${errorText(e)}',
        onRetry: () => _delete(a),
      );
    }
  }

  String _dmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AuroraPage(
      title: 'Lịch sử hoạt động',
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
    final stepGoal = widget.stepGoal;
    final now = DateTime.now();

    // 7 ngày gần nhất, cũ -> mới.
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - (6 - i)),
    );
    final stepsPerDay = days
        .map((d) => _activities
            .where((a) => a.isOn(d))
            .fold<int>(0, (s, a) => s + a.steps))
        .toList();
    final maxValue = [stepGoal, ...stepsPerDay].reduce((a, b) => a > b ? a : b);

    // Nhóm theo ngày, mới nhất trước.
    final sorted = [..._activities]..sort((a, b) => b.date.compareTo(a.date));
    final dates = <DateTime>[];
    for (final a in sorted) {
      final d = DateTime(a.date.year, a.date.month, a.date.day);
      if (dates.isEmpty || dates.last != d) dates.add(d);
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Tv1GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Số bước 7 ngày qua', style: theme.textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Cột sáng là ngày đạt mục tiêu $stepGoal bước',
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
        if (dates.isEmpty)
          Center(
            child: Text('Chưa có lịch sử hoạt động.',
                style: theme.textTheme.bodyMedium),
          ),
        for (final d in dates) ...[
          Text(_dmy(d), style: theme.textTheme.titleSmall),
          const SizedBox(height: 6),
          ...sorted.where((a) => a.isOn(d)).map(
                (a) => Tv1GlassCard(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.type == 'cycling'
                                  ? a.typeLabel
                                  : '${a.typeLabel} - ${a.steps} bước',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              [
                                '${_hm(a.date)} - ${a.durationMinutes} phút '
                                    '- ${a.distanceKm.toStringAsFixed(2)} km '
                                    '- ${a.calories} kcal',
                                if (a.origin != null && a.destination != null)
                                  '${a.origin} → ${a.destination}',
                              ].join('\n'),
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Xóa hoạt động',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () => _delete(a),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}