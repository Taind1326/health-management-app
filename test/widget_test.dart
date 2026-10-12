import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_app/main.dart';

void main() {
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
}
