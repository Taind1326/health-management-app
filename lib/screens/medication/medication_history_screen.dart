import 'package:flutter/material.dart';

import '../../models/medication.dart';
import '../../models/medication_schedule.dart';
import '../../repositories/medication_repository.dart';
import '../../services/medication_rules.dart';
import 'medication_style.dart';

class MedicationHistoryScreen extends StatefulWidget {
  final int userId;
  const MedicationHistoryScreen({super.key, required this.userId});
  @override
  State<MedicationHistoryScreen> createState() =>
      _MedicationHistoryScreenState();
}

class _MedicationHistoryScreenState extends State<MedicationHistoryScreen> {
  late final repo = MedicationRepository(widget.userId);
  List<Medication> medications = [];
  List<MedicationSchedule> schedules = [];
  List<Map<String, Object?>> logs = [];
  bool loading = true, busy = false;
  String? error;
  DateTime selectedDay = MedicationRules.day(DateTime.now());

  Future<void> _chooseDay() async {
    final now = MedicationRules.day(DateTime.now());
    final first = DateTime(now.year, now.month, now.day - 30);
    final initial = selectedDay.isBefore(first) || selectedDay.isAfter(now)
        ? now
        : selectedDay;
    final picked = await showDatePicker(
      context: context,
      firstDate: first,
      lastDate: now,
      initialDate: initial,
    );
    if (!mounted || picked == null || busy) return;
    setState(() => selectedDay = picked);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final m = await repo.medications();
      final s = await repo.schedules();
      final l = await repo.logs();
      if (mounted)
        setState(() {
          medications = m;
          schedules = s;
          logs = l;
          loading = false;
          error = null;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          error = medError(e);
          loading = false;
        });
    }
  }

  MedicationSchedule? _schedule(String? id) {
    for (final s in schedules) {
      if (s.id == id) return s;
    }
    return null;
  }

  Future<void> _record(
    MedicationSchedule s,
    DateTime when,
    String status,
  ) async {
    final confirmed = await showMedicationDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'taken' ? 'Xác nhận đã uống' : 'Xác nhận bỏ qua'),
        content: const Text(
          'Chỉ ghi lại việc đã xảy ra. Ghi nhận đã uống sẽ trừ liều nếu đang theo dõi tồn kho. Nếu lượng tồn đã được kiểm kê sau lần uống đó, hãy đối chiếu lại sau khi lưu.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true || busy) return;
    setState(() => busy = true);
    try {
      await repo.record(s, when, status);
      await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(medError(e))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget _entry({
    required String name,
    required DateTime when,
    required String status,
    MedicationSchedule? schedule,
    String? unit,
    double? dose,
  }) {
    final due = !when.isAfter(DateTime.now());
    return MedicationGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            if (dose != null) Text('${medNumber(dose)} ${unit ?? ''}'),
            Text('Dự kiến: ${medTime(when)}'),
            Text(
              status == 'taken'
                  ? 'Đã uống'
                  : status == 'skipped'
                  ? 'Đã bỏ qua'
                  : due
                  ? 'Đến hạn, chưa xác nhận'
                  : 'Sắp đến giờ',
            ),
            if (schedule != null && due)
              Wrap(
                spacing: 8,
                children: [
                  TextButton(
                    onPressed: busy || status == 'taken'
                        ? null
                        : () => _record(schedule, when, 'taken'),
                    child: Text(
                      status == 'skipped' ? 'Sửa thành đã uống' : 'Đã uống',
                    ),
                  ),
                  TextButton(
                    onPressed: busy || status == 'skipped'
                        ? null
                        : () => _record(schedule, when, 'skipped'),
                    child: Text(
                      status == 'taken' ? 'Sửa thành bỏ qua' : 'Bỏ qua',
                    ),
                  ),
                ],
              ),
            if (schedule == null)
              const Text('Lịch đã xóa; giữ nguyên lịch sử đã ghi nhận.'),
          ],
        ),
      ),
    );
  }

  Widget _dayEntry(MedicationSchedule schedule, DateTime when) {
    final med = medications.firstWhere((m) => m.id == schedule.medicationId);
    final matches = logs.where(
      (l) =>
          l['schedule_id'] == schedule.id &&
          l['scheduled_at'] == when.toIso8601String(),
    );
    final log = matches.isEmpty ? null : matches.first;
    return _entry(
      name: log?['medication_name'] as String? ?? med.name,
      when: when,
      status: log?['status'] as String? ?? 'pending',
      schedule: schedule,
      unit: log?['unit'] as String? ?? med.unit,
      dose: (log?['dosage'] as num?)?.toDouble() ?? double.parse(med.dosage),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = selectedDay == MedicationRules.day(now);
    final entries = <({MedicationSchedule s, DateTime at})>[];
    for (final s in schedules.where((s) => s.isEnabled)) {
      if (MedicationRules.occursOn(s, selectedDay))
        entries.add((s: s, at: MedicationRules.at(s, selectedDay)));
    }
    entries.sort((a, b) => a.at.compareTo(b.at));
    return DefaultTabController(
      length: 2,
      child: MedicationScaffold(
        appBar: AppBar(
          title: const Text('Theo dõi uống thuốc'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Theo ngày'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(error!),
                    TextButton(onPressed: _load, child: const Text('Tải lại')),
                  ],
                ),
              )
            : TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      OutlinedButton.icon(
                        onPressed: busy ? null : _chooseDay,
                        icon: const Icon(Icons.calendar_today),
                        label: Text(
                          isToday
                              ? 'Hôm nay · Đổi ngày'
                              : '${selectedDay.day}/${selectedDay.month}/${selectedDay.year} · Đổi ngày',
                        ),
                      ),
                      if (!isToday)
                        const Text('Ghi bù lần đã đến hạn theo lịch còn bật.'),
                      Text(
                        'Đã uống: ${entries.where((e) => logs.any((l) => l['schedule_id'] == e.s.id && l['scheduled_at'] == e.at.toIso8601String() && l['status'] == 'taken')).length}/${entries.length} lần theo lịch đang bật',
                      ),
                      TextButton.icon(
                        onPressed: busy ? null : _load,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Cập nhật'),
                      ),
                      if (busy) const LinearProgressIndicator(),
                      if (entries.isEmpty)
                        const Text(
                          'Ngày này không có lần uống theo lịch đang bật.',
                        ),
                      for (final entry in entries) _dayEntry(entry.s, entry.at),
                    ],
                  ),
                  ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (logs.isEmpty)
                        const Text('Chưa có kết quả uống thuốc.'),
                      for (final log in logs)
                        _entry(
                          name: log['medication_name'] as String,
                          when: DateTime.parse(log['scheduled_at'] as String),
                          status: log['status'] as String,
                          schedule: _schedule(log['schedule_id'] as String?),
                          unit: log['unit'] as String,
                          dose: (log['dosage'] as num).toDouble(),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
