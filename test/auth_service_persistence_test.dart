import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_app/models/health_goal.dart';
import 'package:health_app/models/health_profile.dart';
import 'package:health_app/models/user.dart';
import 'package:health_app/repositories/auth_repository.dart';
import 'package:health_app/screens/profile/health_goal_screen.dart';
import 'package:health_app/services/auth_service.dart';

class _StoredAuthRepository extends AuthRepository {
  HealthProfile storedProfile = HealthProfile(
    id: 1,
    userId: 1,
    fullName: 'Nguyễn Văn A',
    age: 20,
    gender: 'Nam',
    height: 170,
    weight: 65,
    bmi: 22.49,
  );
  final storedGoals = <HealthGoal>[
    HealthGoal(id: 1, userId: 1, goal: 'Uống đủ nước'),
    HealthGoal(id: 2, userId: 1, goal: 'Đi bộ'),
  ];
  bool failWrites = false;

  @override
  Future<User?> authenticate(String identifier, String password) async =>
      User(id: 1, username: identifier);

  @override
  Future<HealthProfile> getProfile(int userId) async => storedProfile;

  @override
  Future<List<HealthGoal>> getGoals(int userId) async => List.of(storedGoals);

  @override
  Future<void> updateProfile(HealthProfile profile) async {
    if (failWrites) throw StateError('SQLite write failed');
    storedProfile = profile;
  }

  @override
  Future<int> deleteGoal(int userId, int goalId) async {
    if (failWrites) throw StateError('SQLite delete failed');
    final before = storedGoals.length;
    storedGoals.removeWhere(
      (goal) => goal.userId == userId && goal.id == goalId,
    );
    return before - storedGoals.length;
  }

  @override
  Future<int> deleteGoalByText(int userId, String goalText) async {
    if (failWrites) throw StateError('SQLite delete failed');
    final before = storedGoals.length;
    storedGoals.removeWhere(
      (goal) => goal.userId == userId && goal.goal == goalText,
    );
    return before - storedGoals.length;
  }
}

Future<AuthService> _loggedInService(_StoredAuthRepository repository) async {
  final service = AuthService.withRepository(repository);
  await service.login('user01', '123456');
  return service;
}

void main() {
  test('Failed profile write retains saved weight, height and BMI', () async {
    final repository = _StoredAuthRepository();
    final service = await _loggedInService(repository);
    final changed = HealthProfile(
      id: 1,
      userId: 1,
      fullName: 'Nguyễn Văn A',
      age: 20,
      gender: 'Nam',
      height: 180,
      weight: 80,
      bmi: 24.69,
    );
    repository.failWrites = true;

    await expectLater(service.updateProfile(changed), throwsStateError);

    expect(service.getProfile(1).height, 170);
    expect(service.getProfile(1).weight, 65);
    expect(service.getProfile(1).bmi, 22.49);
    final reopened = await _loggedInService(repository);
    expect(reopened.getProfile(1).bmi, 22.49);
  });

  test('Failed goal deletion by ID retains the goal', () async {
    final repository = _StoredAuthRepository()..failWrites = true;
    final service = await _loggedInService(repository);

    await expectLater(service.deleteGoal(1, 1), throwsStateError);

    expect(service.getGoals(1).map((goal) => goal.id), contains(1));
    final reopened = await _loggedInService(repository);
    expect(reopened.getGoals(1).map((goal) => goal.id), contains(1));
  });

  test('Failed goal deletion by text retains matching goals', () async {
    final repository = _StoredAuthRepository()..failWrites = true;
    final service = await _loggedInService(repository);

    await expectLater(
      service.deleteGoalByText(1, 'Uống đủ nước'),
      throwsStateError,
    );

    expect(
      service.getGoals(1).map((goal) => goal.goal),
      contains('Uống đủ nước'),
    );
  });

  test('Successful writes update cache and survive a new session', () async {
    final repository = _StoredAuthRepository();
    final service = await _loggedInService(repository);
    final changed = HealthProfile(
      id: 1,
      userId: 1,
      fullName: 'Nguyễn Văn A',
      age: 20,
      gender: 'Nam',
      height: 180,
      weight: 80,
      bmi: 24.69,
    );

    await service.updateProfile(changed);
    await service.deleteGoal(1, 1);
    await service.deleteGoalByText(1, 'Đi bộ');

    expect(service.getProfile(1).bmi, 24.69);
    expect(service.getGoals(1), isEmpty);
    final reopened = await _loggedInService(repository);
    expect(reopened.getProfile(1).height, 180);
    expect(reopened.getProfile(1).weight, 80);
    expect(reopened.getProfile(1).bmi, 24.69);
    expect(reopened.getGoals(1), isEmpty);
  });

  testWidgets('Failed swipe deletion keeps the goal visible', (tester) async {
    final repository = _StoredAuthRepository()..failWrites = true;
    final service = await _loggedInService(repository);
    await tester.pumpWidget(
      MaterialApp(home: HealthGoalScreen(authService: service)),
    );

    await tester.drag(find.text('Uống đủ nước'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Uống đủ nước'), findsOneWidget);
    expect(find.text('Danh sách mục tiêu (2)'), findsOneWidget);
    expect(find.textContaining('Xóa mục tiêu thất bại'), findsOneWidget);
  });

  testWidgets('Successful swipe deletion updates the list and stored goals', (
    tester,
  ) async {
    final repository = _StoredAuthRepository();
    final service = await _loggedInService(repository);
    await tester.pumpWidget(
      MaterialApp(home: HealthGoalScreen(authService: service)),
    );

    await tester.drag(find.text('Uống đủ nước'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Uống đủ nước'), findsNothing);
    expect(find.text('Danh sách mục tiêu (1)'), findsOneWidget);
    final reopened = await _loggedInService(repository);
    expect(
      reopened.getGoals(1).map((goal) => goal.goal),
      isNot(contains('Uống đủ nước')),
    );
  });
}
