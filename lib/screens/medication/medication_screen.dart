import 'package:flutter/material.dart';

import '../../models/medication.dart';
import 'medication_form_screen.dart';
import '../../models/medication_schedule.dart';
import 'medication_schedule_screen.dart';
import '../../models/medication_log.dart';
import 'medication_history_screen.dart';
import '../../models/reminder.dart';
import 'reminder_screen.dart';

class MedicationScreen extends StatefulWidget {
  const MedicationScreen({super.key});

  @override
  State<MedicationScreen> createState() => _MedicationScreenState();
}

class _MedicationScreenState extends State<MedicationScreen> {
  final Map<String, List<MedicationSchedule>> _schedulesByMedication = {};
  final List<MedicationLog> _medicationLogs = [];
  final List<Reminder> _reminders = [];
  // Dữ liệu mẫu phục vụ prototype đợt 1.
  final List<Medication> _medications = [
    const Medication(
      id: 'medication-001',
      userId: 'demo-user',
      name: 'Thuốc mẫu A',
      dosage: '1',
      unit: 'viên',
      note: 'Dữ liệu minh họa cho giao diện.',
    ),
    const Medication(
      id: 'medication-002',
      userId: 'demo-user',
      name: 'Thuốc mẫu B',
      dosage: '5',
      unit: 'ml',
    ),
  ];

  void _openMedicationHistory() {
    final schedules = _schedulesByMedication.values
        .expand((items) => items)
        .toList();

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => MedicationHistoryScreen(
          medications: List.of(_medications),
          schedules: schedules,
          logs: List.of(_medicationLogs),
          onLogChanged: (updated) {
            if (!mounted) return;

            setState(() {
              final index = _medicationLogs.indexWhere(
                (log) => log.id == updated.id,
              );

              if (index == -1) {
                _medicationLogs.add(updated);
              } else {
                _medicationLogs[index] = updated;
              }
            });
          },
        ),
      ),
    );
  }

  void _openReminders() {
    final scheduleLabels = <String, String>{};

    for (final medication in _medications) {
      final schedules = _schedulesByMedication[medication.id] ?? [];

      for (final schedule in schedules) {
        final hour = schedule.hour.toString().padLeft(2, '0');
        final minute = schedule.minute.toString().padLeft(2, '0');

        scheduleLabels[schedule.id] = '${medication.name} — $hour:$minute';
      }
    }

    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (context) => ReminderScreen(
          reminders: List.of(_reminders),
          medicationSchedules: scheduleLabels,
          onChanged: (updated) {
            if (!mounted) return;

            setState(() {
              _reminders
                ..clear()
                ..addAll(updated);
            });
          },
        ),
      ),
    );
  }

  Future<void> _openMedicationSchedule(Medication medication) async {
    final result = await Navigator.push<List<MedicationSchedule>>(
      context,
      MaterialPageRoute<List<MedicationSchedule>>(
        builder: (context) => MedicationScheduleScreen(
          medication: medication,
          schedules: _schedulesByMedication[medication.id] ?? [],
        ),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      final oldIds = (_schedulesByMedication[medication.id] ?? [])
          .map((schedule) => schedule.id)
          .toSet();

      final newIds = result.map((schedule) => schedule.id).toSet();
      final removedIds = oldIds.difference(newIds);

      _schedulesByMedication[medication.id] = List.of(result);

      _reminders.removeWhere(
        (reminder) => removedIds.contains(reminder.medicationScheduleId),
      );
    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Đã lưu lịch uống.')));
  }

  Future<void> _openMedicationForm({Medication? medication}) async {
    final result = await Navigator.push<Medication>(
      context,
      MaterialPageRoute<Medication>(
        builder: (context) =>
            MedicationFormScreen(medication: medication, userId: 'demo-user'),
      ),
    );

    if (!mounted || result == null) return;

    setState(() {
      if (medication == null) {
        _medications.add(result);
      } else {
        final index = _medications.indexWhere(
          (item) => item.id == medication.id,
        );

        if (index != -1) {
          _medications[index] = result;
        }
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          medication == null ? 'Đã thêm thuốc.' : 'Đã cập nhật thuốc.',
        ),
      ),
    );
  }

  Future<void> _deleteMedication(Medication medication) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa thuốc'),
        content: Text(
          'Bạn muốn xóa "${medication.name}"?\n\n'
          'Các lịch uống và nhắc nhở liên quan cũng sẽ bị xóa. '
          'Lịch sử đã ghi nhận được giữ lại.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final removedScheduleIds = (_schedulesByMedication[medication.id] ?? [])
        .map((schedule) => schedule.id)
        .toSet();

    setState(() {
      _reminders.removeWhere(
        (reminder) =>
            removedScheduleIds.contains(reminder.medicationScheduleId),
      );

      _medications.removeWhere((item) => item.id == medication.id);

      _schedulesByMedication.remove(medication.id);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã xóa thuốc khỏi danh sách.')),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.medication_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'Bạn chưa thêm thuốc nào',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Thêm thuốc khi bạn cần theo dõi lịch uống.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: () => _openMedicationForm(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm thuốc'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationCard(Medication medication) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
                    medication.name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Tùy chọn thuốc',
                  onSelected: (value) {
                    if (value == 'edit') {
                      _openMedicationForm(medication: medication);
                    } else if (value == 'delete') {
                      _deleteMedication(medication);
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Sửa thuốc')),
                    PopupMenuItem(value: 'delete', child: Text('Xóa thuốc')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Liều mỗi lần: ${medication.dosage} ${medication.unit}'),
            if (medication.note.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Ghi chú: ${medication.note}'),
            ],
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openMedicationSchedule(medication),
              icon: const Icon(Icons.schedule),
              label: const Text('Lịch uống'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thuốc & Nhắc nhở'),
        actions: [
          IconButton(
            tooltip: 'Lịch sử uống thuốc',
            onPressed: _openMedicationHistory,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: 'Quản lý nhắc nhở',
            onPressed: _openReminders,
            icon: const Icon(Icons.notifications_outlined),
          ),
        ],
      ),
      body: _medications.isEmpty
          ? _buildEmptyState()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              children: [
                Text(
                  'Danh sách thuốc (${_medications.length})',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                const Text('Dữ liệu mẫu để minh họa giao diện.'),
                const SizedBox(height: 16),
                ..._medications.map(_buildMedicationCard),
              ],
            ),
      floatingActionButton: _medications.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openMedicationForm(),
              icon: const Icon(Icons.add),
              label: const Text('Thêm thuốc'),
            ),
    );
  }
}
