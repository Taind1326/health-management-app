import 'package:flutter/material.dart';

import 'tv1_glass_widgets.dart';

/// Theme tối nền Aurora, dựng từ style của tv1_glass_widgets.dart.
ThemeData auroraTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  final field = Tv1GlassTheme.inputDecoration(labelText: '');
  const surface = Color(0xFF312E81);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: const Color(0xFF7DD3FC),
      secondary: const Color(0xFF6EE7B7),
      surface: surface,
      error: const Color(0xFFFF6B6B),
    ),
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.38)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: field.fillColor,
      labelStyle: field.labelStyle,
      hintStyle: field.hintStyle,
      helperStyle: field.helperStyle,
      errorStyle: field.errorStyle,
      border: field.enabledBorder,
      enabledBorder: field.enabledBorder,
      focusedBorder: field.focusedBorder,
      errorBorder: field.errorBorder,
      focusedErrorBorder: field.focusedErrorBorder,
    ),
    elevatedButtonTheme:
        ElevatedButtonThemeData(style: Tv1GlassTheme.primaryButtonStyle()),
    filledButtonTheme: FilledButtonThemeData(
      style: Tv1GlassTheme.primaryButtonStyle(),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: Tv1GlassTheme.secondaryButtonStyle(),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF7DD3FC)),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF0284C7),
      foregroundColor: Colors.white,
    ),
  );
}

/// Dùng cho showDatePicker / showTimePicker: `builder: auroraPickerBuilder`.
Widget auroraPickerBuilder(BuildContext context, Widget? child) =>
    Theme(data: auroraTheme(), child: child ?? const SizedBox.shrink());

Future<T?> showAuroraDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) =>
    showDialog<T>(
      context: context,
      builder: (_) => Theme(data: auroraTheme(), child: Builder(builder: builder)),
    );

Future<T?> showAuroraSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) {
  final theme = auroraTheme();
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: const Color(0xFF312E81),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Theme(
      data: theme,
      child: DefaultTextStyle(
        style: theme.textTheme.bodyMedium!,
        child: Builder(builder: builder),
      ),
    ),
  );
}

/// Trang nền Aurora + AppBar kính, dùng cho mọi màn hình vận động / giấc ngủ.
class AuroraPage extends StatelessWidget {
  final String title;
  final List<Widget>? actions;
  final Widget body;
  final Widget? floatingActionButton;

  const AuroraPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
  });

  @override
  Widget build(BuildContext context) {
    final theme = auroraTheme();
    return Theme(
      data: theme,
      child: DefaultTextStyle(
        style: theme.textTheme.bodyMedium!,
        child: Tv1GlassScaffold(
          appBar: Tv1GlassAppBar(title: Text(title), actions: actions),
          body: body,
          floatingActionButton: floatingActionButton,
        ),
      ),
    );
  }
}

/// Khối báo lỗi có nút "Thử lại".
class AuroraErrorView extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const AuroraErrorView({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Tv1GlassCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 40),
              const SizedBox(height: 12),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String errorText(Object e) => e
    .toString()
    .replaceFirst('Bad state: ', '')
    .replaceFirst('Invalid argument(s): ', '')
    .replaceFirst('Exception: ', '');

/// Báo lỗi lưu/xóa thất bại, kèm nút thử lại.
void showErrorSnack(
  BuildContext context,
  String message, {
  VoidCallback? onRetry,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 6),
        action: onRetry == null
            ? null
            : SnackBarAction(label: 'Thử lại', onPressed: onRetry),
      ),
    );
}