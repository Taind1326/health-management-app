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
}
