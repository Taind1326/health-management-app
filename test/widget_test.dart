import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_app/main.dart';

void main() {
  testWidgets('Health Metric Screen displays correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const HealthApp());

    // Verify that the main screen title is displayed.
    expect(find.text('Chỉ số sức khỏe'), findsOneWidget);

    // Verify metric cards are present.
    expect(find.text('Huyết áp'), findsOneWidget);
    expect(find.text('Nhịp tim'), findsOneWidget);
    expect(find.text('Cân nặng'), findsOneWidget);
    expect(find.text('BMI'), findsOneWidget);

    // Verify action buttons.
    expect(find.text('Xem lịch sử'), findsOneWidget);
    expect(find.text('Xem biểu đồ'), findsOneWidget);

    // Verify FAB is present.
    expect(find.byIcon(Icons.add), findsOneWidget);
  });
}
