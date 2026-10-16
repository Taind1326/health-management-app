import 'package:flutter/material.dart';

import 'routes/app_routes.dart';
import 'screens/activity/activity_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/health_metrics/health_metric_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/medication/medication_screen.dart';
import 'screens/nutrition/nutrition_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/sleep/sleep_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Quản lý sức khỏe',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      initialRoute: AppRoutes.login,
      routes: {
        AppRoutes.login: (_) => const LoginScreen(),
        AppRoutes.register: (_) => const RegisterScreen(),
        AppRoutes.home: (_) => const HomeScreen(),
        AppRoutes.profile: (_) => const ProfileScreen(),
        AppRoutes.healthMetrics: (_) => const HealthMetricScreen(),
        AppRoutes.medication: (_) => const MedicationScreen(),
        AppRoutes.nutrition: (_) => const NutritionScreen(),
        AppRoutes.activity: (_) => const ActivityScreen(),
        AppRoutes.sleep: (_) => const SleepScreen(),
      },
    );
  }
}