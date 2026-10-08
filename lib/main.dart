import 'package:flutter/material.dart';
import 'screens/health_metrics/health_metric_screen.dart';

void main() {
  runApp(const HealthApp());
}

/// Root widget for the Health Management App.
/// Phase 1 prototype: launches directly into the Health Metrics module.
class HealthApp extends StatelessWidget {
  const HealthApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý sức khỏe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.green,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: true,
          elevation: 0,
        ),
      ),
      home: const HealthMetricScreen(),
    );
  }
}
