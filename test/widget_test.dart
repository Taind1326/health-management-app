import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_app/main.dart';
import 'package:health_app/models/health_goal.dart';
import 'package:health_app/models/health_profile.dart';
import 'package:health_app/models/user.dart';
import 'package:health_app/screens/health_metrics/health_metric_screen.dart';
import 'package:health_app/screens/nutrition/nutrition_screen.dart';
import 'package:health_app/screens/nutrition/nutrition_store.dart';
import 'package:health_app/screens/profile/health_goal_screen.dart';
import 'package:health_app/services/auth_service.dart';
import 'package:health_app/utils/hash_util.dart';

void main() {
  setUp(() {
    AuthService().resetForTesting();
    NutritionStore.instance.resetForTesting();
  });

  Future<void> tapVisible(
    WidgetTester tester,
    Finder finder,
  ) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> fillField(
    WidgetTester tester,
    String label,
    String value,
  ) async {
    final field = find.widgetWithText(TextFormField, label);

    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.enterText(field, value);
    await tester.pump();
  }

  Future<void> openNutrition(WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: NutritionScreen(),
      ),
    );
  }

  testWidgets(
    'Health Metric Screen displays correctly',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HealthMetricScreen(),
        ),
      );

      expect(find.text('Chỉ số sức khỏe'), findsOneWidget);
      expect(find.text('Huyết áp'), findsOneWidget);
      expect(find.text('Nhịp tim'), findsOneWidget);
      expect(find.text('Cân nặng'), findsOneWidget);
      expect(find.text('BMI'), findsOneWidget);
      expect(find.text('Xem lịch sử'), findsOneWidget);
      expect(find.text('Xem biểu đồ'), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    },
  );

  testWidgets(
    'LoginScreen UI smoke test',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      expect(find.text('Đăng nhập'), findsWidgets);
      expect(find.text('Tên tài khoản'), findsOneWidget);
      expect(find.text('Mật khẩu'), findsOneWidget);
      expect(
        find.widgetWithText(ElevatedButton, 'Đăng nhập'),
        findsOneWidget,
      );
      expect(find.text('Chưa có tài khoản?'), findsOneWidget);
      expect(find.text('Đăng ký'), findsOneWidget);
    },
  );

  testWidgets(
    'Đăng nhập với dữ liệu trống hiển thị lỗi',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Đăng nhập'),
      );

      expect(
        find.text('Tên tài khoản không được để trống.'),
        findsOneWidget,
      );
      expect(
        find.text('Mật khẩu không được để trống.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Đăng nhập sai mật khẩu thì ở lại màn hình Đăng nhập',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      await fillField(tester, 'Tên tài khoản', 'user01');
      await fillField(tester, 'Mật khẩu', 'wrongpass');

      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Đăng nhập'),
      );

      expect(
        find.text('Tên tài khoản hoặc mật khẩu không đúng.'),
        findsWidgets,
      );
      expect(find.text('Trang chủ'), findsNothing);
      expect(
        find.widgetWithText(TextFormField, 'Tên tài khoản'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Đăng nhập tài khoản mẫu thành công',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      await fillField(tester, 'Tên tài khoản', 'user01');
      await fillField(tester, 'Mật khẩu', '123456');

      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Đăng nhập'),
      );

      expect(
        find.widgetWithText(AppBar, 'Trang chủ'),
        findsOneWidget,
      );
      expect(find.text('Xin chào, user01!'), findsOneWidget);
    },
  );

  testWidgets(
    'Đăng ký rồi đăng nhập và thiết lập hồ sơ trước khi vào Trang chủ',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Mở màn hình đăng ký.
      await tapVisible(
        tester,
        find.widgetWithText(TextButton, 'Đăng ký'),
      );

      expect(find.text('Tạo tài khoản mới'), findsOneWidget);

      // Nhập thông tin tài khoản mới.
      await fillField(tester, 'Họ và tên', 'Trần Thị B');
      await fillField(tester, 'Số điện thoại', '0987654321');
      await fillField(tester, 'Tên tài khoản', 'newuser02');
      await fillField(tester, 'Mật khẩu', 'password123');
      await fillField(
        tester,
        'Xác nhận mật khẩu',
        'password123',
      );

      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Đăng ký'),
      );

      // Đăng ký thành công thì quay về đăng nhập.
      expect(
        find.text('Ứng dụng Quản lý Sức khỏe'),
        findsOneWidget,
      );

      await fillField(tester, 'Tên tài khoản', 'newuser02');
      await fillField(tester, 'Mật khẩu', 'password123');

      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Đăng nhập'),
      );

      // Tài khoản mới cần thiết lập hồ sơ sức khỏe.
      expect(
        find.text('Thiết lập hồ sơ sức khỏe'),
        findsOneWidget,
      );
      expect(
        find.text('Nhập thông tin sức khỏe ban đầu'),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(AppBar, 'Trang chủ'),
        findsNothing,
      );

      await fillField(tester, 'Tuổi', '21');
      await fillField(tester, 'Chiều cao (cm)', '165');
      await fillField(tester, 'Cân nặng (kg)', '55');

      // Đóng bàn phím và thông báo trước khi bấm hoàn tất.
      FocusManager.instance.primaryFocus?.unfocus();

      final completeButton = find.widgetWithText(
        ElevatedButton,
        'Hoàn tất & Vào trang chủ',
      );

      ScaffoldMessenger.of(
        tester.element(completeButton),
      ).hideCurrentSnackBar();

      await tester.pumpAndSettle();
      await tapVisible(tester, completeButton);

      expect(
        find.widgetWithText(AppBar, 'Trang chủ'),
        findsOneWidget,
      );
      expect(
        find.text('Xin chào, newuser02!'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'Tổng dinh dưỡng được tính từ các bữa ăn',
    (WidgetTester tester) async {
      await openNutrition(tester);

      expect(find.text('1350 kcal'), findsOneWidget);
      expect(find.text('75 g'), findsOneWidget);
      expect(find.text('155 g'), findsOneWidget);
      expect(find.text('40 g'), findsOneWidget);
    },
  );

  testWidgets(
    'Thêm bữa ăn cập nhật tổng calo',
    (WidgetTester tester) async {
      await openNutrition(tester);

      await tapVisible(
        tester,
        find.widgetWithText(OutlinedButton, 'Thêm bữa ăn'),
      );

      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Lưu bữa ăn'),
      );

      expect(find.text('1700 kcal'), findsOneWidget);
    },
  );

  testWidgets(
    'Thêm nước tạo bản ghi và giữ tổng khi mở lịch sử',
    (WidgetTester tester) async {
      await openNutrition(tester);

      await tapVisible(
        tester,
        find.widgetWithText(OutlinedButton, 'Theo dõi nước'),
      );

      expect(find.text('1000 ml'), findsOneWidget);

      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, '+500 ml'),
      );

      expect(find.text('1500 ml'), findsOneWidget);

      await tapVisible(
        tester,
        find.widgetWithText(
          OutlinedButton,
          'Xem lịch sử nước',
        ),
      );

      expect(find.text('500 ml'), findsNWidgets(2));

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('1500 ml'), findsOneWidget);
    },
  );

  testWidgets(
    'Chỉnh mục tiêu nước cập nhật tiến độ',
    (WidgetTester tester) async {
      await openNutrition(tester);

      await tapVisible(
        tester,
        find.widgetWithText(OutlinedButton, 'Theo dõi nước'),
      );

      await tapVisible(
        tester,
        find.widgetWithText(OutlinedButton, 'Chỉnh mục tiêu'),
      );

      await tester.enterText(
        find.byType(TextFormField),
        '2500',
      );

      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Lưu mục tiêu'),
      );

      expect(
        find.text('Mục tiêu: 2500 ml'),
        findsOneWidget,
      );
      expect(find.text('40% tiến độ'), findsOneWidget);
    },
  );

  // --- CÁC BÀI TEST BỔ SUNG CHO MODULE TV1 ---

  testWidgets(
    'Màn hình Giới thiệu App (AppIntro) hiển thị và nút Bỏ qua chuyển sang Thiết lập hồ sơ',
    (WidgetTester tester) async {
      AuthService().enableIntroForTesting();

      await tester.pumpWidget(const MyApp());

      // Mở màn hình đăng ký
      await tapVisible(
        tester,
        find.widgetWithText(TextButton, 'Đăng ký'),
      );

      // Điền thông tin đăng ký
      await fillField(tester, 'Họ và tên', 'Lê Văn C');
      await fillField(tester, 'Số điện thoại', '0912345678');
      await fillField(tester, 'Tên tài khoản', 'user_intro_test');
      await fillField(tester, 'Mật khẩu', 'pass123456');
      await fillField(tester, 'Xác nhận mật khẩu', 'pass123456');

      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Đăng ký'),
      );

      // Đăng nhập
      await fillField(tester, 'Tên tài khoản', 'user_intro_test');
      await fillField(tester, 'Mật khẩu', 'pass123456');

      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Đăng nhập'),
      );

      // Vì enableIntroForTesting() nên người dùng mới thấy AppIntroScreen
      expect(find.text('Bỏ qua'), findsOneWidget);
      expect(find.text('Theo dõi chỉ số sức khỏe'), findsOneWidget);
      expect(find.text('Tiếp tục'), findsOneWidget);

      // Bấm nút "Bỏ qua" để đi thẳng vào thiết lập hồ sơ
      await tapVisible(tester, find.text('Bỏ qua'));

      expect(find.text('Thiết lập hồ sơ sức khỏe'), findsOneWidget);
      expect(find.text('Nhập thông tin sức khỏe ban đầu'), findsOneWidget);
    },
  );

  testWidgets(
    'Đăng ký bằng Email và đăng nhập thành công bằng Email',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      await tapVisible(
        tester,
        find.widgetWithText(TextButton, 'Đăng ký'),
      );

      // Chọn chuyển sang hình thức Email
      await tapVisible(tester, find.text('Email'));

      // Điền thông tin với email
      await fillField(tester, 'Họ và tên', 'Phạm Hoàng D');
      await fillField(tester, 'Email', 'hoangd@example.com');
      await fillField(tester, 'Tên tài khoản', 'hoangd_email');
      await fillField(tester, 'Mật khẩu', 'securePass123');
      await fillField(tester, 'Xác nhận mật khẩu', 'securePass123');

      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Đăng ký'),
      );

      // Quay về màn hình đăng nhập, dùng Email để đăng nhập
      await fillField(tester, 'Tên tài khoản', 'hoangd@example.com');
      await fillField(tester, 'Mật khẩu', 'securePass123');

      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Đăng nhập'),
      );

      // Vì profile mới chưa xong -> vào thiết lập hồ sơ
      expect(find.text('Thiết lập hồ sơ sức khỏe'), findsOneWidget);
    },
  );

  test(
    'Kiểm tra HashUtil và SQLite User, Profile, Goal model mapping',
    () {
      // 1. Kiểm tra HashUtil SHA-256
      final hash = HashUtil.sha256('123456');
      expect(hash, equals('8d969eef6ecad3c29a3a629280e686cf0c3f5d5a86aff3ca12020c923adc6c92'));

      final salt = HashUtil.generateSalt();
      expect(salt.isNotEmpty, isTrue);
      final saltedHash = HashUtil.hashPassword('123456', salt);
      expect(saltedHash.length, equals(64));

      // 2. Kiểm tra User model toMap và fromMap
      final user = User(
        id: 99,
        username: 'test_sql_user',
        phone: '0933333333',
        email: 'test_sql@example.com',
        password: '',
        passwordHash: saltedHash,
        passwordSalt: salt,
      );
      final userMap = user.toMap();
      expect(userMap['username'], equals('test_sql_user'));
      expect(userMap['phone'], equals('0933333333'));
      expect(userMap['email'], equals('test_sql@example.com'));
      expect(userMap['password_hash'], equals(saltedHash));
      expect(userMap['password_salt'], equals(salt));

      final restoredUser = User.fromMap(userMap);
      expect(restoredUser.id, equals(99));
      expect(restoredUser.username, equals('test_sql_user'));
      expect(restoredUser.email, equals('test_sql@example.com'));

      // 3. Kiểm tra HealthProfile model toMap và fromMap
      final profile = HealthProfile(
        id: 1,
        userId: 99,
        fullName: 'Nguyễn Văn Test',
        age: 25,
        gender: 'Nam',
        height: 175.0,
        weight: 70.0,
        bmi: 22.86,
      );
      final profileMap = profile.toMap();
      expect(profileMap['user_id'], equals(99));
      expect(profileMap['gender'], equals('male'));
      expect(profileMap['height_cm'], equals(175.0));
      expect(profileMap['weight_kg'], equals(70.0));
      expect(profileMap['bmi'], equals(22.86));

      final restoredProfile = HealthProfile.fromMap(profileMap);
      expect(restoredProfile.gender, equals('Nam'));
      expect(restoredProfile.height, equals(175.0));

      // 4. Kiểm tra HealthGoal toMap và fromMap
      final goal = HealthGoal(id: 10, userId: 99, goal: 'Uống 2500ml nước');
      final goalMap = goal.toMap();
      expect(goalMap['goal'], equals('Uống 2500ml nước'));
      final restoredGoal = HealthGoal.fromMap(goalMap);
      expect(restoredGoal.goal, equals('Uống 2500ml nước'));

      // 5. Kiểm tra công thức tính toán thông minh
      final bmi = AuthService.calculateBmi(170.0, 65.0);
      expect(bmi, equals(22.49));

      final bmrMale = AuthService.calculateBmr(
        weightKg: 65.0,
        heightCm: 170.0,
        age: 20,
        gender: 'Nam',
      );
      expect(bmrMale, equals(1617.5));

      final water = AuthService.calculateRecommendedWater(65.0);
      expect(water, equals(2300));
    },
  );

  testWidgets(
    'Thêm và Xóa mục tiêu sức khỏe trên HealthGoalScreen',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HealthGoalScreen(),
        ),
      );

      // Kiểm tra danh sách ban đầu có 2 mục tiêu mẫu
      expect(find.text('Danh sách mục tiêu (2)'), findsOneWidget);

      // Thêm mục tiêu mới
      await tester.enterText(
        find.byType(TextFormField),
        'Chạy bộ 5km mỗi sáng',
      );
      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Thêm mục tiêu'),
      );

      // Kiểm tra danh sách đã có 3 mục tiêu
      expect(find.text('Danh sách mục tiêu (3)'), findsOneWidget);
      expect(find.text('Chạy bộ 5km mỗi sáng'), findsOneWidget);

      // Bấm nút xóa của mục tiêu vừa thêm (icon delete_outline cuối cùng)
      final deleteButtons = find.byIcon(Icons.delete_outline);
      expect(deleteButtons, findsNWidgets(3));

      await tapVisible(tester, deleteButtons.last);

      // Kiểm tra mục tiêu đã bị xóa và danh sách giảm còn 2
      expect(find.text('Chạy bộ 5km mỗi sáng'), findsNothing);
      expect(find.text('Danh sách mục tiêu (2)'), findsOneWidget);
      expect(find.text('Đã xóa mục tiêu sức khỏe.'), findsOneWidget);
    },
  );

  testWidgets(
    'Lời chào trên HomeScreen hiển thị đúng Họ và tên fullName từ hồ sơ',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      // Đăng nhập tài khoản mẫu user01
      await fillField(tester, 'Tên tài khoản', 'user01');
      await fillField(tester, 'Mật khẩu', '123456');

      await tapVisible(
        tester,
        find.widgetWithText(ElevatedButton, 'Đăng nhập'),
      );

      // user01 có fullName trong hồ sơ là "Nguyễn Văn A"
      expect(find.text('Xin chào, Nguyễn Văn A!'), findsOneWidget);
    },
  );
}
