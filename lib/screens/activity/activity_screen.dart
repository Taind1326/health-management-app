import 'package:flutter/material.dart';

import '../../models/activity.dart';
import 'activity_history_screen.dart';
import 'add_activity_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Màn hình tổng quan vận động trong ngày + mục tiêu.
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  // Prototype đợt 1: dữ liệu giữ trong bộ nhớ.
  List<Activity> _activities = [];
  bool _loadingActivities = true;
  int _stepGoal = 10000;
  int _minuteGoal = 30;

  List<Activity> get _today =>
      _activities.where((a) => a.isOn(DateTime.now())).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  int get _steps => _today.fold(0, (s, a) => s + a.steps);
  double get _km => _today.fold(0.0, (s, a) => s + a.distanceKm);
  int get _minutes => _today.fold(0, (s, a) => s + a.durationMinutes);
  int get _kcal => _today.fold(0, (s, a) => s + a.calories);

  Future<void> _addActivity() async {
    final result = await Navigator.push<Activity>(
      context,
      MaterialPageRoute(builder: (_) => const AddActivityScreen()),
    );
    if (!mounted || result == null) return;

    setState(() {
      _activities.add(result);
    });

    await _saveActivities();
  }

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ActivityHistoryScreen(
          activities: List.of(_activities),
          stepGoal: _stepGoal,
        ),
      ),
    );
  }

  Future<void> _editGoals() async {
    final result = await showDialog<({int steps, int minutes})>(
      context: context,
      builder: (_) => _GoalDialog(stepGoal: _stepGoal, minuteGoal: _minuteGoal),
    );
    if (!mounted || result == null) return;
    setState(() {
      _stepGoal = result.steps;
      _minuteGoal = result.minutes;
    });
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'Đi bộ':
        return Icons.directions_walk;
      case 'Chạy bộ':
        return Icons.directions_run;
      case 'Đạp xe':
        return Icons.directions_bike;
      default:
        return Icons.fitness_center;
    }
  }

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_steps / _stepGoal).clamp(0.0, 1.0);
    final today = _today;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vận động'),
        actions: [
          IconButton(
            tooltip: 'Lịch sử hoạt động',
            icon: const Icon(Icons.history),
            onPressed: _openHistory,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addActivity,
        icon: const Icon(Icons.add),
        label: const Text('Thêm hoạt động'),
      ),
      body: _loadingActivities
          ? const Center(child: CircularProgressIndicator())
          : ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Center(
            child: SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 14,
                      strokeCap: StrokeCap.round,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$_steps', style: theme.textTheme.displaySmall),
                      Text('/ $_stepGoal bước',
                          style: theme.textTheme.bodyMedium),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              _steps >= _stepGoal
                  ? 'Bạn đã đạt mục tiêu số bước hôm nay'
                  : 'Còn ${_stepGoal - _steps} bước nữa là đạt mục tiêu',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              _StatTile(
                icon: Icons.straighten,
                value: _km.toStringAsFixed(1),
                label: 'km',
              ),
              _StatTile(
                icon: Icons.timer_outlined,
                value: '$_minutes/$_minuteGoal',
                label: 'phút',
              ),
              _StatTile(
                icon: Icons.local_fire_department_outlined,
                value: '$_kcal',
                label: 'kcal',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _editGoals,
              icon: const Icon(Icons.flag_outlined),
              label: const Text('Đặt mục tiêu'),
            ),
          ),
          const SizedBox(height: 8),
          Text('Hoạt động hôm nay', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          if (today.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  'Chưa có hoạt động nào hôm nay.\nNhấn "Thêm hoạt động" để bắt đầu.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else
            ...today.map(
              (a) => Card(
                child: ListTile(
                  leading: CircleAvatar(child: Icon(_iconFor(a.type))),
                  title: Text(a.type),
                  subtitle: Text(
                    '${_hm(a.date)} - ${a.durationMinutes} phút - ${a.distanceKm.toStringAsFixed(1)} km',
                  ),
                  trailing: Text('${a.steps} bước'),
                ),
              ),
            ),
        ],
      ),
    );
  }
  @override
  void initState() {
    super.initState();
    _loadActivities();
  }

  Future<void> _loadActivities() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('activities');

    List<Activity> loaded = [];

    if (raw != null) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        loaded = list
            .map(
              (item) => Activity.fromMap(
                Map<String, dynamic>.from(item as Map),
              ),
            )
            .toList();
      } catch (_) {
        // Dữ liệu không hợp lệ: khởi tạo danh sách rỗng.
        loaded = [];
      }
    }

    if (!mounted) return;

    setState(() {
      _activities = loaded;
      _loadingActivities = false;
    });
  }

  Future<void> _saveActivities() async {
    final prefs = await SharedPreferences.getInstance();

    final json = jsonEncode(
      _activities.map((activity) => activity.toMap()).toList(),
    );

    await prefs.setString('activities', json);
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            children: [
              Icon(icon, color: theme.colorScheme.primary),
              const SizedBox(height: 6),
              Text(value, style: theme.textTheme.titleMedium),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dialog đặt mục tiêu. Controller thuộc về dialog và được giải phóng trong
/// dispose(), nên an toàn dù dialog hay màn hình cha bị đóng lúc nào.
class _GoalDialog extends StatefulWidget {
  final int stepGoal;
  final int minuteGoal;

  const _GoalDialog({required this.stepGoal, required this.minuteGoal});

  @override
  State<_GoalDialog> createState() => _GoalDialogState();
}

class _GoalDialogState extends State<_GoalDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _stepCtrl =
      TextEditingController(text: '${widget.stepGoal}');
  late final TextEditingController _minCtrl =
      TextEditingController(text: '${widget.minuteGoal}');

  @override
  void dispose() {
    _stepCtrl.dispose();
    _minCtrl.dispose();
    super.dispose();
  }

  String? _validate(String? v, int min, int max) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null) return 'Nhập một số nguyên';
    if (n < min || n > max) return 'Nhập từ $min đến $max';
    return null;
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(context, (
      steps: int.parse(_stepCtrl.text.trim()),
      minutes: int.parse(_minCtrl.text.trim()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Mục tiêu vận động'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _stepCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Số bước mỗi ngày'),
              validator: (v) => _validate(v, 1000, 50000),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _minCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Phút vận động mỗi ngày'),
              validator: (v) => _validate(v, 5, 600),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        FilledButton(onPressed: _save, child: const Text('Lưu mục tiêu')),
      ],
    );
  }
}