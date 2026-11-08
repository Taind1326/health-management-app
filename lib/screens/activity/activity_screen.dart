import 'package:flutter/material.dart';

import '../../models/activity.dart';
import '../../repositories/activity_repository.dart';
import '../../repositories/user_settings_repository.dart';
import '../../services/auth_service.dart';
import '../../widgets/aurora_page.dart';
import '../../widgets/tv1_glass_widgets.dart';
import 'activity_history_screen.dart';
import 'add_activity_screen.dart';

/// Màn hình tổng quan vận động trong ngày + mục tiêu (lưu SQLite theo tài khoản).
class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  ActivityRepository? _activityRepo;
  UserSettingsRepository? _settingsRepo;

  List<Activity> _activities = [];
  bool _loading = true;
  String? _error;
  int _stepGoal = 10000;
  int _minuteGoal = 30;

  @override
  void initState() {
    super.initState();
    final userId = AuthService().currentUser?.id;
    if (userId == null) {
      _loading = false;
      _error = 'Vui lòng đăng nhập để xem dữ liệu vận động.';
      return;
    }
    _activityRepo = ActivityRepository(userId);
    _settingsRepo = UserSettingsRepository(userId);
    _load();
  }

  Future<void> _load() async {
    final activityRepo = _activityRepo;
    final settingsRepo = _settingsRepo;
    if (activityRepo == null || settingsRepo == null) return;
    try {
      final activities = await activityRepo.getAll();
      final settings = await settingsRepo.get();
      if (!mounted) return;
      setState(() {
        _activities = activities;
        _stepGoal = settings.stepGoal;
        _minuteGoal = settings.activityGoalMinutes;
        _loading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Không đọc được dữ liệu vận động: ${errorText(e)}';
      });
    }
  }

  void _retryLoad() {
    setState(() {
      _loading = true;
      _error = null;
    });
    _load();
  }

  List<Activity> get _today =>
      _activities.where((a) => a.isOn(DateTime.now())).toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  int get _steps => _today.fold(0, (s, a) => s + a.steps);
  double get _km => _today.fold(0.0, (s, a) => s + a.distanceKm);
  int get _minutes => _today.fold(0, (s, a) => s + a.durationMinutes);
  int get _kcal => _today.fold(0, (s, a) => s + a.calories);

  Future<void> _addActivity() async {
    if (_activityRepo == null) return;
    final result = await Navigator.push<Activity>(
      context,
      MaterialPageRoute(builder: (_) => const AddActivityScreen()),
    );
    if (!mounted || result == null) return;
    await _saveActivity(result);
  }

  /// Chỉ cập nhật giao diện SAU khi ghi SQLite thành công; lỗi thì báo và cho thử lại.
  Future<void> _saveActivity(Activity activity) async {
    final repo = _activityRepo;
    if (repo == null) return;
    try {
      await repo.add(activity);
      final list = await repo.getAll();
      if (!mounted) return;
      setState(() => _activities = list);
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(
        context,
        'Chưa lưu được hoạt động: ${errorText(e)}',
        onRetry: () => _saveActivity(activity),
      );
    }
  }

  Future<void> _openHistory() async {
    final repo = _activityRepo;
    if (repo == null) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ActivityHistoryScreen(repository: repo, stepGoal: _stepGoal),
      ),
    );
    if (mounted) _load(); // lịch sử có thể đã xóa bản ghi
  }

  Future<void> _editGoals() async {
    final result = await showAuroraDialog<({int steps, int minutes})>(
      context: context,
      builder: (_) => _GoalDialog(stepGoal: _stepGoal, minuteGoal: _minuteGoal),
    );
    if (!mounted || result == null) return;
    await _saveGoals(result.steps, result.minutes);
  }

  Future<void> _saveGoals(int steps, int minutes) async {
    final repo = _settingsRepo;
    if (repo == null) return;
    try {
      await repo.update(stepGoal: steps, activityGoalMinutes: minutes);
      if (!mounted) return;
      setState(() {
        _stepGoal = steps;
        _minuteGoal = minutes;
      });
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(
        context,
        'Chưa lưu được mục tiêu: ${errorText(e)}',
        onRetry: () => _saveGoals(steps, minutes),
      );
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'walking':
        return Icons.directions_walk;
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.directions_bike;
      default:
        return Icons.fitness_center;
    }
  }

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return AuroraPage(
      title: 'Vận động',
      actions: [
        IconButton(
          tooltip: 'Lịch sử hoạt động',
          icon: const Icon(Icons.history),
          onPressed: _activityRepo == null ? null : _openHistory,
        ),
      ],
      floatingActionButton: _activityRepo == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _addActivity,
              icon: const Icon(Icons.add),
              label: const Text('Thêm hoạt động'),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AuroraErrorView(
                  message: _error!,
                  onRetry: _activityRepo == null ? null : _retryLoad,
                )
              : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final progress = (_steps / _stepGoal).clamp(0.0, 1.0);
    final today = _today;

    return ListView(
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
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF6EE7B7)),
                  ),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$_steps', style: theme.textTheme.displaySmall),
                    Text('/ $_stepGoal bước', style: theme.textTheme.bodyMedium),
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
            (a) => Tv1GlassCard(
              margin: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Tv1LayeredBadge(icon: _iconFor(a.type), size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.typeLabel, style: theme.textTheme.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                          '${_hm(a.date)} - ${a.durationMinutes} phút - '
                          '${a.distanceKm.toStringAsFixed(1)} km',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (a.type != 'cycling') Text('${a.steps} bước'),
                ],
              ),
            ),
          ),
      ],
    );
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
      child: Tv1GlassCard(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.titleMedium),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Dialog đặt mục tiêu. Controller thuộc về dialog và được giải phóng trong dispose().
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