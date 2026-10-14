import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_app/main.dart';
import 'package:health_app/screens/health_metrics/health_metric_screen.dart';
import 'package:health_app/screens/nutrition/nutrition_screen.dart';
import 'package:health_app/screens/nutrition/nutrition_store.dart';
import 'package:health_app/services/auth_service.dart';

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
    'LoginScreen validation test with empty inputs',
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
    'Đăng ký tài khoản mới rồi đăng nhập thành công',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());

      await tapVisible(
        tester,
        find.widgetWithText(TextButton, 'Đăng ký'),
      );

      expect(find.text('Tạo tài khoản mới'), findsOneWidget);

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
}