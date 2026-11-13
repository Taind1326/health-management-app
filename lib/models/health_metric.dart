class HealthMetric {
  static const List<String> types = [
    'blood_pressure',
    'heart_rate',
    'weight',
    'bmi',
  ];

  static const Map<String, String> typeLabels = {
    'blood_pressure': 'Huyết áp',
    'heart_rate': 'Nhịp tim',
    'weight': 'Cân nặng',
    'bmi': 'BMI',
  };

  static const Map<String, String> typeUnits = {
    'blood_pressure': 'mmHg',
    'heart_rate': 'bpm',
    'weight': 'kg',
    'bmi': 'kg/m²',
  };

  static String unitForType(String type) => typeUnits[type] ?? '';
  static String labelForType(String type) => typeLabels[type] ?? 'Chỉ số';

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

  const HealthMetric({
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

  HealthMetric copyWith({
    int? id,
    int? userId,
    String? metricType,
    double? value,
    double? value2,
    bool clearValue2 = false,
    String? unit,
    String? note,
    bool clearNote = false,
    DateTime? recordedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthMetric(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      metricType: metricType ?? this.metricType,
      value: value ?? this.value,
      value2: clearValue2 ? null : (value2 ?? this.value2),
      unit: unit ?? this.unit,
      note: clearNote ? null : (note ?? this.note),
      recordedAt: recordedAt ?? this.recordedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Chuyển đổi sang Map chuẩn cột SQLite trong bảng `health_metrics`.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'metric_type': metricType,
      'value': value,
      'value2': metricType == 'blood_pressure' ? value2 : null,
      'unit': unit,
      'note': note,
      'recorded_at': recordedAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Hỗ trợ đọc từ cả tên cột SQLite (`snake_case`) và `camelCase`.
  factory HealthMetric.fromMap(Map<String, dynamic> map) {
    final rawRecordedAt =
        (map['recorded_at'] ?? map['recordedAt']) as String? ??
        DateTime.now().toIso8601String();
    final rawCreatedAt =
        (map['created_at'] ?? map['createdAt']) as String? ?? rawRecordedAt;
    final rawUpdatedAt =
        (map['updated_at'] ?? map['updatedAt']) as String? ?? rawRecordedAt;
    final rawType =
        (map['metric_type'] ?? map['metricType']) as String? ??
        'blood_pressure';

    return HealthMetric(
      id: (map['id'] as num?)?.toInt(),
      userId: ((map['user_id'] ?? map['userId']) as num?)?.toInt() ?? 1,
      metricType: rawType,
      value: (map['value'] as num).toDouble(),
      value2: map['value2'] != null ? (map['value2'] as num).toDouble() : null,
      unit: (map['unit'] as String?) ?? (typeUnits[rawType] ?? ''),
      note: map['note'] as String?,
      recordedAt: DateTime.parse(rawRecordedAt),
      createdAt: DateTime.parse(rawCreatedAt),
      updatedAt: DateTime.parse(rawUpdatedAt),
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

  String get metricTypeLabel => typeLabels[metricType] ?? 'Khác';

  /// Phân loại trạng thái sức khỏe theo tiêu chuẩn y khoa (WHO / AHA).
  String get statusLabel {
    switch (metricType) {
      case 'blood_pressure':
        final sys = value;
        final dia = value2 ?? 80;
        if (sys < 90 || dia < 60) return 'Huyết áp thấp';
        if (sys >= 140 || dia >= 90) return 'Cao HA độ 2';
        if (sys >= 130 || dia >= 80) return 'Cao HA độ 1';
        if (sys >= 120 && dia < 80) return 'Tiền cao HA';
        return 'Bình thường';
      case 'heart_rate':
        if (value < 60) return 'Nhịp chậm';
        if (value > 100) return 'Nhịp nhanh';
        return 'Bình thường';
      case 'bmi':
        if (value < 18.5) return 'Thiếu cân';
        if (value < 25.0) return 'Bình thường';
        if (value < 30.0) return 'Thừa cân';
        return 'Béo phì';
      case 'weight':
        return 'Ổn định';
      default:
        return 'Đã ghi nhận';
    }
  }

  /// Mức độ cảnh báo: 'normal' | 'warning' | 'danger'
  String get statusSeverity {
    switch (metricType) {
      case 'blood_pressure':
        final sys = value;
        final dia = value2 ?? 80;
        if (sys >= 140 || dia >= 90 || sys < 90 || dia < 60) return 'danger';
        if (sys >= 120 || dia >= 80) return 'warning';
        return 'normal';
      case 'heart_rate':
        if (value < 50 || value > 120) return 'danger';
        if (value < 60 || value > 100) return 'warning';
        return 'normal';
      case 'bmi':
        if (value >= 30.0 || value < 16.5) return 'danger';
        if (value >= 25.0 || value < 18.5) return 'warning';
        return 'normal';
      default:
        return 'normal';
    }
  }

  /// Khoảng tham chiếu y khoa chuẩn.
  String get normalRangeText {
    switch (metricType) {
      case 'blood_pressure':
        return 'Chuẩn AHA: 90/60 – 120/80 mmHg';
      case 'heart_rate':
        return 'Chuẩn lúc nghỉ: 60 – 100 bpm';
      case 'bmi':
        return 'Chuẩn WHO: 18.5 – 24.9 kg/m²';
      case 'weight':
        return 'Duy trì cân nặng mục tiêu cá nhân';
      default:
        return '';
    }
  }

  /// Khuyến nghị sức khỏe dựa trên chỉ số đo.
  String get statusAdvice {
    switch (metricType) {
      case 'blood_pressure':
        final sys = value;
        final dia = value2 ?? 80;
        if (sys < 90 || dia < 60) {
          return 'Huyết áp hơi thấp. Nên nghỉ ngơi, uống đủ nước và tránh đứng dậy đột ngột.';
        }
        if (sys >= 140 || dia >= 90) {
          return 'Huyết áp cao độ 2. Nên nghỉ ngơi, giảm muối và tham khảo ý kiến bác sĩ.';
        }
        if (sys >= 130 || dia >= 80) {
          return 'Huyết áp cao độ 1. Hãy hạn chế đồ mặn, tập thể dục nhẹ và theo dõi hàng ngày.';
        }
        if (sys >= 120 && dia < 80) {
          return 'Tiền tăng huyết áp. Duy trì lối sống lành mạnh và kiểm soát căng thẳng.';
        }
        return 'Huyết áp ở mức lý tưởng! Hãy tiếp tục duy trì chế độ sinh hoạt hiện tại.';
      case 'heart_rate':
        if (value < 60) {
          return 'Nhịp tim hơi chậm (bình thường nếu bạn là vận động viên). Nếu kèm chóng mặt, hãy nghỉ ngơi.';
        }
        if (value > 100) {
          return 'Nhịp tim nhanh. Có thể do vừa vận động, căng thẳng hoặc dùng caffeine. Hãy hít thở sâu.';
        }
        return 'Nhịp tim lúc nghỉ ngơi rất tốt, hệ tim mạch hoạt động ổn định.';
      case 'bmi':
        if (value < 18.5) {
          return 'Chỉ số BMI thiếu cân. Nên bổ sung dinh dưỡng giàu đạm và tập luyện tăng cơ.';
        }
        if (value < 25.0) {
          return 'Chỉ số BMI cân đối chuẩn WHO! Hãy duy trì vận động và dinh dưỡng hợp lý.';
        }
        if (value < 30.0) {
          return 'Thừa cân nhẹ. Nên kết hợp ăn giảm tinh bột/đường và tăng vận động 30 phút/ngày.';
        }
        return 'Chỉ số BMI ở ngưỡng béo phì. Nên xây dựng kế hoạch giảm cân khoa học và bền vững.';
      case 'weight':
        return 'Theo dõi cân nặng định kỳ vào buổi sáng giúp kiểm soát vóc dáng và BMI chính xác nhất.';
      default:
        return 'Hãy ghi nhận chỉ số đều đặn để theo dõi xu hướng sức khỏe.';
    }
  }

  static List<HealthMetric> sampleData({int userId = 1}) {
    final now = DateTime.now();
    return [
      HealthMetric(
        id: 1,
        userId: userId,
        metricType: 'blood_pressure',
        value: 120,
        value2: 80,
        unit: 'mmHg',
        note: 'Đo buổi sáng sau khi nghỉ ngơi',
        recordedAt: now.subtract(const Duration(days: 0)),
        createdAt: now.subtract(const Duration(days: 0)),
        updatedAt: now.subtract(const Duration(days: 0)),
      ),
      HealthMetric(
        id: 2,
        userId: userId,
        metricType: 'blood_pressure',
        value: 125,
        value2: 82,
        unit: 'mmHg',
        note: 'Đo sau giờ làm việc',
        recordedAt: now.subtract(const Duration(days: 2)),
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(days: 2)),
      ),
      HealthMetric(
        id: 3,
        userId: userId,
        metricType: 'heart_rate',
        value: 75,
        unit: 'bpm',
        note: 'Đo bằng cảm biến quang học Flash PPG',
        recordedAt: now.subtract(const Duration(days: 0)),
        createdAt: now.subtract(const Duration(days: 0)),
        updatedAt: now.subtract(const Duration(days: 0)),
      ),
      HealthMetric(
        id: 4,
        userId: userId,
        metricType: 'heart_rate',
        value: 72,
        unit: 'bpm',
        note: 'Trạng thái nghỉ ngơi',
        recordedAt: now.subtract(const Duration(days: 1)),
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      HealthMetric(
        id: 5,
        userId: userId,
        metricType: 'weight',
        value: 65.5,
        unit: 'kg',
        note: 'Cân buổi sáng trước ăn',
        recordedAt: now.subtract(const Duration(days: 0)),
        createdAt: now.subtract(const Duration(days: 0)),
        updatedAt: now.subtract(const Duration(days: 0)),
      ),
      HealthMetric(
        id: 6,
        userId: userId,
        metricType: 'weight',
        value: 66.0,
        unit: 'kg',
        recordedAt: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      HealthMetric(
        id: 7,
        userId: userId,
        metricType: 'bmi',
        value: 22.4,
        unit: 'kg/m²',
        note: 'Chiều cao 171 cm, cân nặng 65.5 kg',
        recordedAt: now.subtract(const Duration(days: 0)),
        createdAt: now.subtract(const Duration(days: 0)),
        updatedAt: now.subtract(const Duration(days: 0)),
      ),
      HealthMetric(
        id: 8,
        userId: userId,
        metricType: 'bmi',
        value: 22.6,
        unit: 'kg/m²',
        recordedAt: now.subtract(const Duration(days: 5)),
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(days: 5)),
      ),
      HealthMetric(
        id: 9,
        userId: userId,
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
        userId: userId,
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
