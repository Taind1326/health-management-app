import 'package:flutter/material.dart';

import '../../models/sleep_record.dart';
import 'sleep_history_screen.dart';
import 'sleep_sample_data.dart';

/// Màn hình theo dõi giấc ngủ: đêm gần nhất, mục tiêu, ghi nhận giấc ngủ mới.
class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  // Prototype đợt 1: dữ liệu giữ trong bộ nhớ.
  final List<SleepRecord> _records = buildSampleSleepRecords();
  int _goalMinutes = 8 * 60;

  SleepRecord? get _latest {
    if (_records.isEmpty) return null;
    return ([..._records]..sort((a, b) => b.wakeTime.compareTo(a.wakeTime)))
        .first;
  }

  String _duration(int minutes) => '${minutes ~/ 60} giờ ${minutes % 60} phút';

  String _hm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  void _openHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SleepHistoryScreen(
          records: List.of(_records),
          goalMinutes: _goalMinutes,
        ),
      ),
    );
  }

  Future<void> _editGoal() async {
    var hours = _goalMinutes / 60;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Mục tiêu giấc ngủ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${hours.toStringAsFixed(1)} giờ mỗi đêm',
                  style: Theme.of(ctx).textTheme.titleMedium),
              Slider(
                value: hours,
                min: 4,
                max: 12,
                divisions: 16,
                label: hours.toStringAsFixed(1),
                onChanged: (v) => setLocal(() => hours = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Lưu mục tiêu'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || saved != true) return;
    setState(() => _goalMinutes = (hours * 60).round());
  }

  String _dmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _addRecord() async {
    final result = await showModalBottomSheet<SleepRecord>(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddSleepSheet(),
    );
    if (!mounted || result == null) return;

    // Mỗi ngày thức dậy chỉ giữ một bản ghi: nếu đã có thì hỏi trước khi thay.
    final hasOld = _records.any((r) => r.isOn(result.wakeTime));
    if (hasOld) {
      final replace = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Thay thế bản ghi cũ?'),
          content: Text(
            'Ngày ${_dmy(result.wakeTime)} đã có dữ liệu giấc ngủ. '
            'Bạn có muốn thay bằng bản ghi mới không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Thay thế'),
            ),
          ],
        ),
      );
      // Chọn Hủy (hoặc đóng dialog): giữ nguyên bản ghi cũ.
      if (!mounted || replace != true) return;
    }

    setState(() {
      _records.removeWhere((r) => r.isOn(result.wakeTime));
      _records.add(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = _latest;
    final progress = latest == null
        ? 0.0
        : (latest.durationMinutes / _goalMinutes).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Giấc ngủ'),
        actions: [
          IconButton(
            tooltip: 'Lịch sử giấc ngủ',
            icon: const Icon(Icons.history),
            onPressed: _openHistory,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRecord,
        icon: const Icon(Icons.bedtime_outlined),
        label: const Text('Ghi nhận giấc ngủ'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (latest == null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 48),
              child: Center(
                child: Text(
                  'Chưa có dữ liệu giấc ngủ.\nNhấn "Ghi nhận giấc ngủ" để thêm đêm đầu tiên.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            )
          else ...[
            Text('Đêm gần nhất', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_duration(latest.durationMinutes),
                        style: theme.textTheme.headlineMedium),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      latest.durationMinutes >= _goalMinutes
                          ? 'Đạt mục tiêu ${_duration(_goalMinutes)}'
                          : 'Thiếu ${_duration(_goalMinutes - latest.durationMinutes)} so với mục tiêu',
                      style: theme.textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: _TimeTile(
                    icon: Icons.bedtime_outlined,
                    label: 'Đi ngủ',
                    value: _hm(latest.sleepTime),
                  ),
                ),
                Expanded(
                  child: _TimeTile(
                    icon: Icons.wb_sunny_outlined,
                    label: 'Thức dậy',
                    value: _hm(latest.wakeTime),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Mục tiêu giấc ngủ'),
              subtitle: Text('${_duration(_goalMinutes)} mỗi đêm'),
              trailing: TextButton(
                onPressed: _editGoal,
                child: const Text('Chỉnh sửa'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _TimeTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Icon(icon, color: theme.colorScheme.primary),
            const SizedBox(height: 6),
            Text(value, style: theme.textTheme.titleLarge),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet nhập giấc ngủ: ngày thức dậy, giờ đi ngủ, giờ thức dậy.
/// Nếu giờ ngủ không sớm hơn giờ thức thì hiểu là đi ngủ từ hôm trước của
/// ngày thức dậy. Không cho lưu giấc ngủ chưa kết thúc (giờ thức ở tương lai).
class _AddSleepSheet extends StatefulWidget {
  const _AddSleepSheet();

  @override
  State<_AddSleepSheet> createState() => _AddSleepSheetState();
}

class _AddSleepSheetState extends State<_AddSleepSheet> {
  late DateTime _wakeDate = _today();
  TimeOfDay _sleep = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wake = const TimeOfDay(hour: 6, minute: 30);
  String? _error;

  static DateTime _today() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  String _dmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    final today = _today();
    final picked = await showDatePicker(
      context: context,
      initialDate: _wakeDate,
      firstDate: DateTime(today.year - 1, today.month, today.day),
      lastDate: today,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _wakeDate = DateTime(picked.year, picked.month, picked.day);
      _error = null;
    });
  }

  Future<void> _pickTime(bool isSleep) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isSleep ? _sleep : _wake,
    );
    if (!mounted || picked == null) return;
    setState(() {
      if (isSleep) {
        _sleep = picked;
      } else {
        _wake = picked;
      }
      _error = null;
    });
  }

  void _save() {
    final wake = DateTime(_wakeDate.year, _wakeDate.month, _wakeDate.day,
        _wake.hour, _wake.minute);

    if (wake.isAfter(DateTime.now())) {
      setState(() => _error =
          'Giờ thức dậy ${_fmt(_wake)} ngày ${_dmy(_wakeDate)} chưa tới. '
          'Chỉ ghi nhận được giấc ngủ đã kết thúc.');
      return;
    }

    var sleep = DateTime(_wakeDate.year, _wakeDate.month, _wakeDate.day,
        _sleep.hour, _sleep.minute);
    if (!sleep.isBefore(wake)) sleep = sleep.subtract(const Duration(days: 1));

    final minutes = wake.difference(sleep).inMinutes;
    if (minutes < 30 || minutes > 16 * 60) {
      setState(() => _error = 'Thời gian ngủ phải từ 30 phút đến 16 giờ');
      return;
    }
    Navigator.pop(
      context,
      SleepRecord(
        userId: 1, // đợt 2: lấy từ người dùng đang đăng nhập (TV1)
        sleepTime: sleep,
        wakeTime: wake,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Ghi nhận giấc ngủ',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_today),
              label: Text('Ngày thức dậy ${_dmy(_wakeDate)}'),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(true),
                  icon: const Icon(Icons.bedtime_outlined),
                  label: Text('Đi ngủ ${_fmt(_sleep)}'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickTime(false),
                  icon: const Icon(Icons.wb_sunny_outlined),
                  label: Text('Thức dậy ${_fmt(_wake)}'),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('Lưu giấc ngủ'),
            ),
          ),
        ],
      ),
    );
  }
}