import 'package:flutter/material.dart';

import '../../models/medication.dart';
import '../../models/medication_log.dart';
import '../../models/medication_schedule.dart';

class MedicationHistoryScreen extends StatefulWidget {
  final List<Medication> medications;
  final List<MedicationSchedule> schedules;
  final List<MedicationLog> logs;
  final ValueChanged<MedicationLog> onLogChanged;

  const MedicationHistoryScreen({
    super.key,
    required this.medications,
    required this.schedules,
    required this.logs,
    required this.onLogChanged,
  });

  @override
  State<MedicationHistoryScreen> createState() =>
      _MedicationHistoryScreenState();
}

class _MedicationHistoryScreenState extends State<MedicationHistoryScreen> {
  late final List<MedicationLog> _logs;

  @override
  void initState() {
    super.initState();
    _logs = List.of(widget.logs);
  }

  String _formatDateTime(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$day/$month/${date.year} $hour:$minute';
  }

  String _statusLabel(MedicationStatus status) {
    switch (status) {
      case MedicationStatus.pending:
        return 'Chưa xác nhận';
      case MedicationStatus.taken:
        return 'Đã uống';
      case MedicationStatus.skipped:
        return 'Bỏ qua';
    }
  }

  Medication? _findMedication(String scheduleId) {
    for (final schedule in widget.schedules) {
      if (schedule.id == scheduleId) {
        for (final medication in widget.medications) {
          if (medication.id == schedule.medicationId) {
            return medication;
          }
        }
      }
    }
    return null;
  }

  List<MedicationLog> _todayEntries() {
    final today = DateUtils.dateOnly(DateTime.now());
    final entries = <MedicationLog>[];

    for (final schedule in widget.schedules) {
      if (!schedule.isEnabled) continue;

      final start = DateUtils.dateOnly(schedule.startDate);
      final end = schedule.endDate == null
          ? null
          : DateUtils.dateOnly(schedule.endDate!);

      if (today.isBefore(start)) continue;
      if (end != null && today.isAfter(end)) continue;

      switch (schedule.repeat) {
        case MedicationRepeat.once:
          if (!DateUtils.isSameDay(today, start)) continue;
          break;
        case MedicationRepeat.daily:
          break;
        case MedicationRepeat.selectedWeekdays:
          if (!schedule.weekdays.contains(today.weekday)) continue;
          break;
      }

      final scheduledAt = DateTime(
        today.year,
        today.month,
        today.day,
        schedule.hour,
        schedule.minute,
      );

      final id = '${schedule.id}-${scheduledAt.millisecondsSinceEpoch}';

      final existingIndex = _logs.indexWhere((log) => log.id == id);

      entries.add(
        existingIndex == -1
            ? MedicationLog(
                id: id,
                scheduleId: schedule.id,
                scheduledAt: scheduledAt,
              )
            : _logs[existingIndex],
      );
    }

    entries.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    return entries;
  }

  Future<void> _recordStatus(
    MedicationLog entry,
    MedicationStatus status,
  ) async {
    final medication = _findMedication(entry.scheduleId);
    final name = medication?.name ?? 'Thuốc';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          status == MedicationStatus.taken
              ? 'Xác nhận đã uống'
              : 'Xác nhận bỏ qua',
        ),
        content: Text(
          '$name\n'
          'Lịch: ${_formatDateTime(entry.scheduledAt)}\n\n'
          'Ghi nhận trạng thái "${_statusLabel(status)}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Xác nhận'),
          ),
        ],
      ),
    );

    if (!mounted || confirmed != true) return;

    final updated = MedicationLog(
      id: entry.id,
      scheduleId: entry.scheduleId,
      scheduledAt: entry.scheduledAt,
      takenAt: status == MedicationStatus.taken ? DateTime.now() : null,
      status: status,
      // Giữ thông tin minh họa nếu thuốc/lịch bị xóa sau này.
      note: medication == null
          ? entry.note
          : '${medication.name} — '
                '${medication.dosage} ${medication.unit}',
    );

    setState(() {
      final index = _logs.indexWhere((log) => log.id == updated.id);

      if (index == -1) {
        _logs.add(updated);
      } else {
        _logs[index] = updated;
      }
    });

    widget.onLogChanged(updated);
  }

  Widget _buildEntry(MedicationLog entry, {required bool allowActions}) {
    final medication = _findMedication(entry.scheduleId);
    final title = entry.note.isNotEmpty
        ? entry.note
        : medication?.name ?? 'Thuốc không còn trong danh sách';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Dự kiến: ${_formatDateTime(entry.scheduledAt)}'),
            const SizedBox(height: 4),
            Text('Trạng thái: ${_statusLabel(entry.status)}'),
            if (entry.takenAt != null) ...[
              const SizedBox(height: 4),
              Text('Xác nhận uống: ${_formatDateTime(entry.takenAt!)}'),
            ],
            if (allowActions && entry.status == MedicationStatus.pending) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  FilledButton.icon(
                    onPressed: () =>
                        _recordStatus(entry, MedicationStatus.taken),
                    icon: const Icon(Icons.check),
                    label: const Text('Đã uống'),
                  ),
                  OutlinedButton(
                    onPressed: () =>
                        _recordStatus(entry, MedicationStatus.skipped),
                    child: const Text('Bỏ qua'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildList(
    List<MedicationLog> entries, {
    required bool allowActions,
    required String emptyMessage,
  }) {
    if (entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(emptyMessage, textAlign: TextAlign.center),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: entries
          .map((entry) => _buildEntry(entry, allowActions: allowActions))
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final history = List<MedicationLog>.of(_logs)
      ..sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Theo dõi uống thuốc'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Hôm nay'),
              Tab(text: 'Lịch sử'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildList(
              _todayEntries(),
              allowActions: true,
              emptyMessage: 'Hôm nay chưa có lịch uống thuốc.',
            ),
            _buildList(
              history,
              allowActions: false,
              emptyMessage: 'Chưa có lần uống nào được ghi nhận.',
            ),
          ],
        ),
      ),
    );
  }
}
