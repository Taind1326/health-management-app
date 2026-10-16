import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_app/main.dart';
import 'package:health_app/services/auth_service.dart';

void main() {
  setUp(() {
    AuthService().resetForTesting();
  });

  testWidgets('LoginScreen UI smoke test', (WidgetTester tester) async {
    // Build app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Kiểm tra các thành phần giao diện chính trên màn hình Đăng nhập
    expect(find.text('Đăng nhập'), findsWidgets);
    expect(find.text('Tên tài khoản'), findsOneWidget);
    expect(find.text('Mật khẩu'), findsOneWidget);
    expect(find.widgetWithText(ElevatedButton, 'Đăng nhập'), findsOneWidget);
    expect(find.text('Chưa có tài khoản?'), findsOneWidget);
    expect(find.text('Đăng ký'), findsOneWidget);
  });

  testWidgets('LoginScreen validation test with empty inputs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Nhấn nút Đăng nhập khi để trống các trường
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pump();

    // Kiểm tra thông báo lỗi validation
    expect(find.text('Tên tài khoản không được để trống.'), findsOneWidget);
    expect(find.text('Mật khẩu không được để trống.'), findsOneWidget);
  });

  testWidgets('Đăng nhập thất bại khi sai mật khẩu -> ở lại Đăng nhập và hiện lỗi', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // Nhập tài khoản mẫu và mật khẩu sai
    final usernameField = find.widgetWithText(TextFormField, 'Tên tài khoản');
    final passwordField = find.widgetWithText(TextFormField, 'Mật khẩu');

    await tester.enterText(usernameField, 'user01');
    await tester.enterText(passwordField, 'wrongpass');

    // Bấm Đăng nhập
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    // Vẫn ở màn hình Đăng nhập và hiển thị thông báo lỗi
    expect(find.text('Tên tài khoản hoặc mật khẩu không đúng.'), findsWidgets);
    expect(find.text('Trang chủ'), findsNothing);
  });

  testWidgets('Đăng nhập thành công với tài khoản mẫu -> điều hướng vào Trang chủ', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    final usernameField = find.widgetWithText(TextFormField, 'Tên tài khoản');
    final passwordField = find.widgetWithText(TextFormField, 'Mật khẩu');

    await tester.enterText(usernameField, 'user01');
    await tester.enterText(passwordField, '123456');

    // Bấm Đăng nhập
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    // Đã vào Trang chủ
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Xin chào, user01!'), findsOneWidget);
  });

  testWidgets('Luồng đăng ký tài khoản mới -> quay lại Đăng nhập -> thiết lập chỉ số sức khỏe -> vào Trang chủ', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    // 1. Từ LoginScreen bấm chuyển sang RegisterScreen
    await tester.tap(find.text('Đăng ký'));
    await tester.pumpAndSettle();

    expect(find.text('Tạo tài khoản mới'), findsOneWidget);

    // 2. Điền thông tin đăng ký mới
    await tester.enterText(find.widgetWithText(TextFormField, 'Họ và tên'), 'Trần Thị B');
    await tester.enterText(find.widgetWithText(TextFormField, 'Số điện thoại'), '0987654321');
    await tester.enterText(find.widgetWithText(TextFormField, 'Tên tài khoản'), 'newuser02');
    await tester.enterText(find.widgetWithText(TextFormField, 'Mật khẩu'), 'password123');
    await tester.enterText(find.widgetWithText(TextFormField, 'Xác nhận mật khẩu'), 'password123');

    // 3. Bấm Đăng ký
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng ký'));
    await tester.pumpAndSettle();

    // 4. Kiểm tra đã quay về màn hình Đăng nhập
    expect(find.text('Ứng dụng Quản lý Sức khỏe'), findsOneWidget);

    // 5. Đăng nhập bằng tài khoản vừa tạo
    final usernameField = find.widgetWithText(TextFormField, 'Tên tài khoản');
    final passwordField = find.widgetWithText(TextFormField, 'Mật khẩu');

    await tester.enterText(usernameField, 'newuser02');
    await tester.enterText(passwordField, 'password123');

    // 6. Bấm Đăng nhập
    await tester.tap(find.widgetWithText(ElevatedButton, 'Đăng nhập'));
    await tester.pumpAndSettle();

    // 7. Người dùng mới chưa có chỉ số sức khỏe -> hệ thống hiển thị màn hình Thiết lập hồ sơ sức khỏe
    expect(find.text('Thiết lập hồ sơ sức khỏe'), findsOneWidget);
    expect(find.text('Nhập thông tin sức khỏe ban đầu'), findsOneWidget);

    // 8. Nhập các chỉ số ban đầu
    await tester.enterText(find.widgetWithText(TextFormField, 'Tuổi'), '21');
    await tester.enterText(find.widgetWithText(TextFormField, 'Chiều cao (cm)'), '165');
    await tester.enterText(find.widgetWithText(TextFormField, 'Cân nặng (kg)'), '55');

    // Đóng SnackBar cũ (nếu có từ màn hình đăng ký)
    ScaffoldMessenger.of(tester.element(find.byType(Scaffold).first)).hideCurrentSnackBar();
    await tester.pumpAndSettle();

    // 9. Cuộn tới nút và bấm Hoàn tất & Vào trang chủ
    final completeButton = find.widgetWithText(ElevatedButton, 'Hoàn tất & Vào trang chủ');
    await tester.ensureVisible(completeButton);
    await tester.pumpAndSettle();
    await tester.tap(completeButton, warnIfMissed: false);
    await tester.pumpAndSettle();

    // 10. Kiểm tra đã chuyển sang Trang chủ thành công
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Xin chào, newuser02!'), findsOneWidget);
  });
}
