class WaterRecord {
  final int id;
  final int userId;
  final int amountMl;
  final DateTime recordedAt;

  const WaterRecord({
    required this.id,
    required this.userId,
    required this.amountMl,
    required this.recordedAt,
  });
}