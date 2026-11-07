import 'package:flutter/material.dart';

import '../../widgets/tv1_glass_widgets.dart';

/// Theme chỉ áp dụng cho TV5, không thay style module của thành viên khác.
class MedicationScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget body;
  final Widget? floatingActionButton;
  const MedicationScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.floatingActionButton,
  });
  @override
  Widget build(BuildContext context) {
    final theme = medicationTheme();
    return Theme(
      data: theme,
      child: DefaultTextStyle(
        style: theme.textTheme.bodyMedium!,
        child: Tv1GlassScaffold(
          appBar: appBar,
          body: body,
          floatingActionButton: floatingActionButton,
        ),
      ),
    );
  }
}

class MedicationGlassCard extends StatelessWidget {
  final Widget? child;
  final EdgeInsetsGeometry? margin;
  const MedicationGlassCard({super.key, this.child, this.margin});
  @override
  Widget build(BuildContext context) => Tv1GlassCard(
    margin: margin ?? const EdgeInsets.symmetric(vertical: 6),
    padding: EdgeInsets.zero,
    child: child ?? const SizedBox.shrink(),
  );
}

String medNumber(num n) =>
    n == n.roundToDouble() ? n.toInt().toString() : n.toStringAsFixed(2);
String medTime(DateTime d) =>
    '${d.day}/${d.month}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
String medError(Object e) => e
    .toString()
    .replaceFirst('Bad state: ', '')
    .replaceFirst('Invalid argument(s): ', '');

ThemeData medicationTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: const Color(0xFF7DD3FC),
      secondary: const Color(0xFF6EE7B7),
      surface: const Color(0xFF312E81),
    ),
    scaffoldBackgroundColor: Colors.transparent,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: .12),
      labelStyle: const TextStyle(color: Colors.white70),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: Tv1GlassTheme.primaryButtonStyle(),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: Tv1GlassTheme.primaryButtonStyle(),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: Tv1GlassTheme.secondaryButtonStyle(),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF0284C7),
      foregroundColor: Colors.white,
    ),
  );
}

Future<T?> showMedicationDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showDialog<T>(
  context: context,
  builder: (ctx) => Theme(
    data: medicationTheme(),
    child: Builder(builder: builder),
  ),
);
