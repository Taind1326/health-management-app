enum MedicationStatus { pending, taken, skipped }

class MedicationLog {
  final String id;
  final String scheduleId;
  final DateTime scheduledAt;
  final DateTime? takenAt;
  final MedicationStatus status;
  final String note;

  const MedicationLog({
    required this.id,
    required this.scheduleId,
    required this.scheduledAt,
    this.takenAt,
    this.status = MedicationStatus.pending,
    this.note = '',
  });
}
