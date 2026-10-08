class HealthMetric {
  final int? id;
  final int userId;
  final String metricType; // 'blood_pressure', 'heart_rate', 'weight', 'bmi'
  final double value;
  final double? value2;
  final String unit; // 'mmHg', 'bpm', 'kg', 'kg/m²'
  final String? note;
  final DateTime recordedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  HealthMetric({
    this.id,
    required this.userId,
    required this.metricType,
    required this.value,
    this.value2,
    required this.unit,
    this.note,
    required this.recordedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'metricType': metricType,
      'value': value,
      'value2': value2,
      'unit': unit,
      'note': note,
      'recordedAt': recordedAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory HealthMetric.fromMap(Map<String, dynamic> map) {
    return HealthMetric(
      id: map['id'] as int?,
      userId: map['userId'] as int,
      metricType: map['metricType'] as String,
      value: (map['value'] as num).toDouble(),
      value2: map['value2'] != null ? (map['value2'] as num).toDouble() : null,
      unit: map['unit'] as String,
      note: map['note'] as String?,
      recordedAt: DateTime.parse(map['recordedAt'] as String),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  String get displayValue {
    if (metricType == 'blood_pressure') {
      return '${value.toInt()}/${value2?.toInt() ?? 0} $unit';
    } else if (metricType == 'heart_rate') {
      return '${value.toInt()} $unit';
    } else if (metricType == 'weight' || metricType == 'bmi') {
      return '${value.toStringAsFixed(1)} $unit';
    }
    return '$value $unit';
  }

  String get metricTypeLabel {
    switch (metricType) {
      case 'blood_pressure':
        return 'Huyết áp';
      case 'heart_rate':
        return 'Nhịp tim';
      case 'weight':
        return 'Cân nặng';
      case 'bmi':
        return 'BMI';
      default:
        return 'Khác';
    }
  }

  static List<HealthMetric> sampleData() {
    final now = DateTime.now();
    return [
      HealthMetric(
        id: 1,
        userId: 1,
        metricType: 'blood_pressure',
        value: 120,
        value2: 80,
        unit: 'mmHg',
        recordedAt: now.subtract(const Duration(days: 0)),
        createdAt: now.subtract(const Duration(days: 0)),
        updatedAt: now.subtract(const Duration(days: 0)),
      ),
      HealthMetric(
        id: 2,
        userId: 1,
        metricType: 'blood_pressure',
        value: 125,
        value2: 82,
        unit: 'mmHg',
        recordedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      HealthMetric(
        id: 3,
        userId: 1,
        metricType: 'heart_rate',
        value: 75,
        unit: 'bpm',
        recordedAt: now.subtract(const Duration(days: 0)),
        createdAt: now.subtract(const Duration(days: 0)),
        updatedAt: now.subtract(const Duration(days: 0)),
      ),
      HealthMetric(
        id: 4,
        userId: 1,
        metricType: 'heart_rate',
        value: 72,
        unit: 'bpm',
        recordedAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      HealthMetric(
        id: 5,
        userId: 1,
        metricType: 'weight',
        value: 65.5,
        unit: 'kg',
        recordedAt: now.subtract(const Duration(days: 0)),
        createdAt: now.subtract(const Duration(days: 0)),
        updatedAt: now.subtract(const Duration(days: 0)),
      ),
      HealthMetric(
        id: 6,
        userId: 1,
        metricType: 'weight',
        value: 66.0,
        unit: 'kg',
        recordedAt: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      HealthMetric(
        id: 7,
        userId: 1,
        metricType: 'bmi',
        value: 22.4,
        unit: 'kg/m²',
        recordedAt: now.subtract(const Duration(days: 0)),
        createdAt: now.subtract(const Duration(days: 0)),
        updatedAt: now.subtract(const Duration(days: 0)),
      ),
      HealthMetric(
        id: 8,
        userId: 1,
        metricType: 'bmi',
        value: 22.6,
        unit: 'kg/m²',
        recordedAt: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      HealthMetric(
        id: 9,
        userId: 1,
        metricType: 'blood_pressure',
        value: 118,
        value2: 78,
        unit: 'mmHg',
        recordedAt: now.subtract(const Duration(days: 6)),
        createdAt: now.subtract(const Duration(days: 6)),
        updatedAt: now.subtract(const Duration(days: 6)),
      ),
      HealthMetric(
        id: 10,
        userId: 1,
        metricType: 'heart_rate',
        value: 80,
        unit: 'bpm',
        recordedAt: now.subtract(const Duration(days: 7)),
        createdAt: now.subtract(const Duration(days: 7)),
        updatedAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }
}
