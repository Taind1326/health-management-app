import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_app/main.dart';
import 'package:health_app/screens/health_metrics/health_metric_screen.dart';
import 'package:health_app/services/auth_service.dart';

void main() {
  setUp(() {
    AuthService().resetForTesting();
  });

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
    'LoginScreen validation test with empty inputs',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final loginButton =
          find.widgetWithText(ElevatedButton, 'Đăng nhập');

      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pump();

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

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tên tài khoản'),
        'user01',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu'),
        'wrongpass',
      );

      final loginButton =
          find.widgetWithText(ElevatedButton, 'Đăng nhập');

      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

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

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Tên tài khoản'),
        'user01',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Mật khẩu'),
        '123456',
      );

      final loginButton =
          find.widgetWithText(ElevatedButton, 'Đăng nhập');

      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(AppBar, 'Trang chủ'),
        findsOneWidget,
      );
      expect(find.text('Xin chào, user01!'), findsOneWidget);
    },
  );

  testWidgets(
    'Đăng ký tài khoản mới rồi đăng nhập thành công',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      final registerLink =
          find.widgetWithText(TextButton, 'Đăng ký');

      await tester.ensureVisible(registerLink);
      await tester.tap(registerLink);
      await tester.pumpAndSettle();

      expect(find.text('Tạo tài khoản mới'), findsOneWidget);

      Future<void> fillField(String label, String value) async {
        final field = find.widgetWithText(TextFormField, label);

        await tester.ensureVisible(field);
        await tester.enterText(field, value);
        await tester.pump();
      }

      await fillField('Họ và tên', 'Trần Thị B');
      await fillField('Số điện thoại', '0987654321');
      await fillField('Tên tài khoản', 'newuser02');
      await fillField('Mật khẩu', 'password123');
      await fillField('Xác nhận mật khẩu', 'password123');

      final registerButton =
          find.widgetWithText(ElevatedButton, 'Đăng ký');

      await tester.ensureVisible(registerButton);
      await tester.tap(registerButton);
      await tester.pumpAndSettle();

      expect(
        find.text('Ứng dụng Quản lý Sức khỏe'),
        findsOneWidget,
      );

      await fillField('Tên tài khoản', 'newuser02');
      await fillField('Mật khẩu', 'password123');

      final loginButton =
          find.widgetWithText(ElevatedButton, 'Đăng nhập');

      await tester.ensureVisible(loginButton);
      await tester.tap(loginButton);
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(AppBar, 'Trang chủ'),
        findsOneWidget,
      );
      expect(find.text('Xin chào, newuser02!'), findsOneWidget);
    },
  );
}