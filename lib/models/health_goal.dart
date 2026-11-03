class HealthGoal {
  final int id;
  final int userId;
  final String goal;

  HealthGoal({
    required this.id,
    required this.userId,
    required this.goal,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'user_id': userId,
      'goal': goal,
    };
  }

  factory HealthGoal.fromMap(Map<String, dynamic> map) {
    return HealthGoal(
      id: map['id'] as int? ?? 0,
      userId: map['user_id'] as int? ?? 0,
      goal: map['goal'] as String? ?? '',
    );
  }
}
