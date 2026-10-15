import 'package:flutter/material.dart';

/// Theme dùng chung cho toàn bộ ứng dụng.
///
/// Mọi module (Chỉ số sức khỏe, Thuốc, Dinh dưỡng, Vận động, Giấc ngủ,
/// Hồ sơ...) đều lấy màu / kiểu chữ / bo góc từ đây, nên khi cần đổi giao
/// diện chỉ cần sửa tại file này.
class AppTheme {
  AppTheme._();

  /// Màu chủ đạo của ứng dụng.
  static const Color seedColor = Colors.teal;

  /// Bo góc chuẩn cho card, nút, ô nhập liệu.
  static const double radius = 12;

  /// Khoảng đệm chuẩn của một màn hình.
  static const EdgeInsets pagePadding = EdgeInsets.all(16);

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
    );
    const buttonPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 14);
    const buttonText = TextStyle(fontSize: 16, fontWeight: FontWeight.w600);

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,

      // Thanh tiêu đề: giống nhau ở mọi màn hình.
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        titleTextStyle: TextStyle(
          color: scheme.onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card: viền mảnh, không đổ bóng nặng.
      cardTheme: CardThemeData(
        elevation: 1,
        margin: EdgeInsets.zero,
        color: scheme.surfaceContainerLowest,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),

      // Các loại nút chính dùng chung một kiểu.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: buttonPadding,
          textStyle: buttonText,
          shape: shape,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: buttonPadding,
          textStyle: buttonText,
          shape: shape,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.primary,
          side: BorderSide(color: scheme.primary, width: 1.2),
          padding: buttonPadding,
          textStyle: buttonText,
          shape: shape,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
          shape: shape,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Ô nhập liệu.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radius),
          borderSide: BorderSide(color: scheme.error, width: 2),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.primary,
        shape: shape,
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant),
      textTheme: const TextTheme(
        titleLarge: TextStyle(fontWeight: FontWeight.bold),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}