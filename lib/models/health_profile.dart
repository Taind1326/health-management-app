class HealthProfile {
  final int id;
  final int userId;
  final String fullName;
  final int age;
  final String gender;
  final double height;
  final double weight;
  final double bmi;

  HealthProfile({
    required this.id,
    required this.userId,
    required this.fullName,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.bmi,
  });

  /// Kiểm tra xem hồ sơ đã được thiết lập chỉ số sức khỏe ban đầu hay chưa
  bool get isCompleted => height > 0 && weight > 0 && bmi > 0;

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'user_id': userId,
      'full_name': fullName,
      'age': age > 0 ? age : null,
      'gender': gender == 'Nam'
          ? 'male'
          : gender == 'Nữ'
              ? 'female'
              : 'other',
      'height_cm': height > 0 ? height : null,
      'weight_kg': weight > 0 ? weight : null,
      'bmi': bmi > 0 ? bmi : null,
    };
  }

  factory HealthProfile.fromMap(Map<String, dynamic> map) {
    final genderRaw = map['gender'] as String?;
    final gender = genderRaw == 'male'
        ? 'Nam'
        : genderRaw == 'female'
            ? 'Nữ'
            : 'Nam';

    return HealthProfile(
      id: map['id'] as int? ?? 0,
      userId: map['user_id'] as int? ?? 0,
      fullName: map['full_name'] as String? ?? 'Người dùng',
      age: map['age'] as int? ?? 0,
      gender: gender,
      height: (map['height_cm'] as num?)?.toDouble() ?? 0.0,
      weight: (map['weight_kg'] as num?)?.toDouble() ?? 0.0,
      bmi: (map['bmi'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
