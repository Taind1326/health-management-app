class Medication {
  final String id;
  final String userId;
  final String name;
  final String dosage;
  final String unit;
  final String note;

  const Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.unit,
    this.note = '',
  });
}
