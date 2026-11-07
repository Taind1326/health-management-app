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

  factory WaterRecord.fromMap(
    Map<String, dynamic> map,
  ) {
    return WaterRecord(
      id: (map['id'] as num).toInt(),
      userId: (map['user_id'] as num).toInt(),
      amountMl: (map['amount_ml'] as num).toInt(),
      recordedAt: DateTime.parse(
        map['recorded_at'] as String,
      ),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'user_id': userId,
      'amount_ml': amountMl,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}