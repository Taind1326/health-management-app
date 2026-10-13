import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:health_app/screens/nutrition/nutrition_screen.dart';
import 'package:health_app/screens/nutrition/nutrition_store.dart';

void main() {
  final store = NutritionStore.instance;

  setUp(() {
    store.resetForTesting();
  });

  testWidgets(
    'Tổng dinh dưỡng được tính từ các bữa ăn',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NutritionScreen(),
        ),
      );

      expect(find.text('1350 kcal'), findsOneWidget);
      expect(find.text('75 g'), findsOneWidget);
      expect(find.text('155 g'), findsOneWidget);
      expect(find.text('40 g'), findsOneWidget);
    },
  );

  testWidgets(
    'Thêm bữa ăn cập nhật tổng calo',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NutritionScreen(),
        ),
      );

      final addMealButton = find.widgetWithText(
        OutlinedButton,
        'Thêm bữa ăn',
      );

      await tester.ensureVisible(addMealButton);
      await tester.tap(addMealButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Lưu bữa ăn'));
      await tester.pumpAndSettle();

      expect(find.text('1700 kcal'), findsOneWidget);
    },
  );

  testWidgets(
    'Thêm nước tạo bản ghi và giữ tổng khi mở lịch sử',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NutritionScreen(),
        ),
      );

      final waterButton = find.widgetWithText(
        OutlinedButton,
        'Theo dõi nước',
      );

      await tester.ensureVisible(waterButton);
      await tester.tap(waterButton);
      await tester.pumpAndSettle();

      expect(find.text('1000 ml'), findsOneWidget);

      await tester.tap(find.text('+500 ml'));
      await tester.pumpAndSettle();

      expect(find.text('1500 ml'), findsOneWidget);

      await tester.tap(find.text('Xem lịch sử nước'));
      await tester.pumpAndSettle();

      expect(find.text('500 ml'), findsNWidgets(2));

      await tester.pageBack();
      await tester.pumpAndSettle();

      expect(find.text('1500 ml'), findsOneWidget);
    },
  );

  testWidgets(
    'Chỉnh mục tiêu nước cập nhật tiến độ',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: NutritionScreen(),
        ),
      );

      final waterButton = find.widgetWithText(
        OutlinedButton,
        'Theo dõi nước',
      );

      await tester.ensureVisible(waterButton);
      await tester.tap(waterButton);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Chỉnh mục tiêu'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byType(TextFormField),
        '2500',
      );

      await tester.tap(find.text('Lưu mục tiêu'));
      await tester.pumpAndSettle();

      expect(find.text('Mục tiêu: 2500 ml'), findsOneWidget);
      expect(find.text('40% tiến độ'), findsOneWidget);
    },
  );
}