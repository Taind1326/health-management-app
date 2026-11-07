import 'package:flutter/material.dart';

import '../../models/medication.dart';
import '../../models/medication_schedule.dart';
import '../../models/reminder.dart';
import '../../services/auth_service.dart';
import '../../services/medication_rules.dart';
import '../../repositories/medication_repository.dart';
import 'medication_form_screen.dart';
import 'medication_schedule_screen.dart';
import 'medication_history_screen.dart';
import 'medication_stock_screen.dart';
import 'reminder_screen.dart';
import 'medication_style.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});
  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  MedicationRepository? repo;
  List<Medication> medications = [];
  List<MedicationSchedule> schedules = [];
  List<Reminder> reminders = [];
  List<Map<String, Object?>> logs = [];
  bool loading = true, busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    final user = AuthService().currentUser;
    if (user != null) repo = MedicationRepository(user.id);
    _load();
  }

  Future<void> _load() async {
    if (repo == null) {
      if (mounted)
        setState(() {
          loading = false;
          error = 'Vui lòng đăng nhập để quản lý thuốc.';
        });
      return;
    }
    try {
      final meds = await repo!.medications();
      final sch = await repo!.schedules();
      final rem = await repo!.reminders();
      final history = await repo!.logs();
      if (!mounted) return;
      setState(() {
        medications = meds;
        schedules = sch;
        reminders = rem;
        logs = history;
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

  Future<void> _run(Future<void> Function() action) async {
    if (busy || repo == null) return;
    setState(() => busy = true);
    try {
      await action();
      await _load();
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(medError(e))));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> _form({Medication? med}) async {
    if (repo == null || busy) return;
    final result = await Navigator.push<Medication>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            MedicationFormScreen(medication: med, userId: repo!.userId),
      ),
    );
    if (!mounted || result == null) return;
    await _run(() => repo!.saveMedication(result, isNew: med == null));
  }

  Future<void> _schedule(Medication med) async {
    final result = await Navigator.push<List<MedicationSchedule>>(
      context,
      MaterialPageRoute(
        builder: (_) => MedicationScheduleScreen(
          medication: med,
          schedules: schedules.where((s) => s.medicationId == med.id).toList(),
        ),
      ),
    );
    if (!mounted || result == null) return;
    await _run(() => repo!.saveSchedules(med.id, result));
  }

  Future<void> _delete(Medication med) async {
    final confirmed = await showMedicationDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa thuốc'),
        content: Text(
          'Xóa ${med.name} cùng lịch uống và nhắc liên kết? Lịch sử uống đã ghi nhận vẫn được giữ lại.',
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
    if (!mounted || confirmed != true) return;
    await _run(() => repo!.deleteMedication(med.id));
  }

  Future<void> _history() async {
    if (repo == null || busy) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MedicationHistoryScreen(userId: repo!.userId),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _reminders() async {
    if (repo == null || busy) return;
    final labels = <String, String>{};
    final details = <String, MedicationSchedule>{};
    for (final s in schedules) {
      final m = medications.firstWhere((m) => m.id == s.medicationId);
      labels[s.id] =
          '${m.name} — ${s.hour.toString().padLeft(2, '0')}:${s.minute.toString().padLeft(2, '0')}';
      details[s.id] = s;
    }
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => ReminderScreen(
          userId: repo!.userId,
          reminders: reminders,
          medicationSchedules: labels,
          scheduleDetails: details,
          onChanged: (_) {},
        ),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _stock(Medication med) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => MedicationStockScreen(medication: med)),
    );
    if (mounted) await _load();
  }

  Widget _card(Medication med) {
    final sch = schedules.where((s) => s.medicationId == med.id).toList();
    final count = MedicationRules.remainingSevenDays(sch, logs, DateTime.now());
    final need = count * double.parse(med.dosage);
    final shortage = med.stockAmount != null && med.stockAmount! + 1e-7 < need;
    return MedicationGlassCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.medication_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    med.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (v) {
                    if (v == 'edit') _form(med: med);
                    if (v == 'delete') _delete(med);
                  },
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'edit', child: Text('Sửa thuốc')),
                    PopupMenuItem(value: 'delete', child: Text('Xóa thuốc')),
                  ],
                ),
              ],
            ),
            Text(
              'Liều mỗi lần: ${medNumber(double.parse(med.dosage))} ${med.unit}',
            ),
            if (med.note.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(med.note),
              ),
            const SizedBox(height: 12),
            Text(
              med.stockAmount == null
                  ? 'Chưa theo dõi lượng thuốc'
                  : 'Lượng còn lại: ${medNumber(med.stockAmount!)} ${med.unit}',
            ),
            Text(MedicationRules.courseLabel(sch, DateTime.now())),
            if (shortage)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Có thể không đủ cho $count lần chưa xác nhận trong 7 ngày từ hôm nay. Kiểm tra đơn và hướng dẫn điều trị.',
                  style: const TextStyle(color: Color(0xFFFFE082)),
                ),
              ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _schedule(med),
                  icon: const Icon(Icons.schedule),
                  label: const Text('Lịch uống'),
                ),
                OutlinedButton.icon(
                  onPressed: busy ? null : () => _stock(med),
                  icon: const Icon(Icons.inventory_2_outlined),
                  label: const Text('Lượng thuốc / đợt dùng'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MedicationScaffold(
    appBar: AppBar(
      title: const Text('Thuốc và nhắc nhở'),
      actions: [
        IconButton(
          tooltip: 'Lịch sử uống thuốc',
          onPressed: loading || error != null ? null : _history,
          icon: const Icon(Icons.history),
        ),
        IconButton(
          tooltip: 'Quản lý lịch nhắc',
          onPressed: loading || error != null ? null : _reminders,
          icon: const Icon(Icons.notifications_outlined),
        ),
      ],
    ),
    body: loading
        ? const Center(child: CircularProgressIndicator())
        : error != null
        ? Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(error!),
                  TextButton(onPressed: _load, child: const Text('Tải lại')),
                ],
              ),
            ),
          )
        : AbsorbPointer(
            absorbing: busy,
            child: RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  if (busy) const LinearProgressIndicator(),
                  const Text(
                    'Lịch uống của bạn',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Ghi nhận từng lần uống, đối chiếu lượng thuốc và theo dõi lịch đã nhập.',
                  ),
                  const SizedBox(height: 16),
                  if (medications.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 48),
                      child: Text(
                        'Chưa có thuốc. Nhấn Thêm thuốc để bắt đầu.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ...medications.map(_card),
                ],
              ),
            ),
          ),
    floatingActionButton: repo == null || loading || error != null
        ? null
        : FloatingActionButton.extended(
            onPressed: busy ? null : () => _form(),
            icon: const Icon(Icons.add),
            label: const Text('Thêm thuốc'),
          ),
  );
}
