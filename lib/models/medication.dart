class Medication {
  final String id;
  final int userId;
  final String name;
  final String dosage;
  final String unit;
  final String note;
  final double? stockAmount;

  Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dosage,
    required this.unit,
    required this.note,
    this.stockAmount,
  });
}