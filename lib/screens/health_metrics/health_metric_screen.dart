import 'package:flutter/material.dart';

import '../../controllers/health_metric_controller.dart';
import '../../models/health_metric.dart';
import '../../widgets/aurora_page.dart';
import '../../widgets/tv1_glass_widgets.dart';
import 'add_metric_screen.dart';
import 'heart_rate_measure_screen.dart';
import 'metric_chart_screen.dart';
import 'metric_history_screen.dart';

/// Màn hình Tổng quan Chỉ số sức khỏe (TV2 - Đợt 2).
/// Đồng bộ giao diện Aurora Borealis Glassmorphism và kết nối SQLite qua [HealthMetricController].
class HealthMetricScreen extends StatefulWidget {
  const HealthMetricScreen({super.key});

  @override
  State<HealthMetricScreen> createState() => _HealthMetricScreenState();
}

class _HealthMetricScreenState extends State<HealthMetricScreen> {
  final HealthMetricController _controller = HealthMetricController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.loadMetrics();
      }
    });
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'danger':
        return const Color(0xFFFF6B6B);
      case 'warning':
        return const Color(0xFFFBBF24);
      default:
        return const Color(0xFF34D399);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final latestBp = _controller.getLatest('blood_pressure');
        final latestHr = _controller.getLatest('heart_rate');
        final latestWeight = _controller.getLatest('weight');
        final latestBmi = _controller.getLatest('bmi');

        return AuroraPage(
          title: 'Chỉ số sức khỏe',
          actions: [
            IconButton(
              tooltip: 'Làm mới dữ liệu',
              onPressed: () => _controller.loadMetrics(),
              icon: const Icon(Icons.refresh),
            ),
          ],
          floatingActionButton: FloatingActionButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddMetricScreen()),
              );
            },
            tooltip: 'Thêm chỉ số',
            child: const Icon(Icons.add),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Chỉ số gần nhất',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (_controller.isLoading)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFF7DD3FC),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 14),

                // Hàng 1: Huyết áp + Nhịp tim
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        metric: latestBp,
                        metricType: 'blood_pressure',
                        icon: Icons.bloodtype,
                        accentColor: const Color(0xFFFB7185),
                        defaultLabel: 'Huyết áp',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        metric: latestHr,
                        metricType: 'heart_rate',
                        icon: Icons.favorite,
                        accentColor: const Color(0xFFF472B6),
                        defaultLabel: 'Nhịp tim',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Hàng 2: Cân nặng + BMI
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        metric: latestWeight,
                        metricType: 'weight',
                        icon: Icons.monitor_weight,
                        accentColor: const Color(0xFF38BDF8),
                        defaultLabel: 'Cân nặng',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        context,
                        metric: latestBmi,
                        metricType: 'bmi',
                        icon: Icons.calculate,
                        accentColor: const Color(0xFF34D399),
                        defaultLabel: 'BMI',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Tính năng nổi bật: Đo nhịp tim bằng đèn Flash (PPG)
                Tv1GlassCard(
                  padding: const EdgeInsets.all(16),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HeartRateMeasureScreen(),
                        ),
                      );
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFB7185), Color(0xFFE11D48)],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFFFB7185,
                                ).withValues(alpha: 0.45),
                                blurRadius: 14,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.flashlight_on,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Đo nhịp tim bằng đèn Flash (PPG)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Cảm biến quang học qua đầu ngón tay & sóng mạch thời gian thực',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Color(0xFF7DD3FC),
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Thẻ đánh giá nhanh sức khỏe hiện tại
                if (latestBp != null || latestBmi != null)
                  _buildHealthInsightBanner(latestBp, latestHr, latestBmi),

                const SizedBox(height: 20),

                // Nút điều hướng Lịch sử & Biểu đồ
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MetricHistoryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  label: const Text('Xem lịch sử'),
                  style: Tv1GlassTheme.primaryButtonStyle().copyWith(
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MetricChartScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.bar_chart, color: Color(0xFF7DD3FC)),
                  label: const Text('Xem biểu đồ'),
                  style: Tv1GlassTheme.secondaryButtonStyle().copyWith(
                    padding: const WidgetStatePropertyAll(
                      EdgeInsets.symmetric(vertical: 15),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required HealthMetric? metric,
    required String metricType,
    required IconData icon,
    required Color accentColor,
    required String defaultLabel,
  }) {
    final badgeColor = metric != null
        ? _severityColor(metric.statusSeverity)
        : Colors.white54;

    return Tv1GlassCard(
      padding: const EdgeInsets.all(14.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MetricChartScreen(initialType: metricType),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.55),
                    ),
                  ),
                  child: Icon(icon, color: accentColor, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    metric?.metricTypeLabel ?? defaultLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (metric != null) ...[
              Text(
                metric.displayValue,
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.w800,
                  fontSize: 19,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeColor.withValues(alpha: 0.20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: badgeColor.withValues(alpha: 0.65),
                        ),
                      ),
                      child: Text(
                        metric.statusLabel,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${metric.recordedAt.day.toString().padLeft(2, '0')}/${metric.recordedAt.month.toString().padLeft(2, '0')}/${metric.recordedAt.year}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.72),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                'Chưa có dữ liệu',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontStyle: FontStyle.italic,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 8),
              const Text('', style: TextStyle(fontSize: 11)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHealthInsightBanner(
    HealthMetric? bp,
    HealthMetric? hr,
    HealthMetric? bmi,
  ) {
    final activeMetric = bp ?? hr ?? bmi;
    if (activeMetric == null) return const SizedBox.shrink();

    final color = _severityColor(activeMetric.statusSeverity);
    return Tv1GlassCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.health_and_safety_outlined, color: color, size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Đánh giá y khoa (${activeMetric.metricTypeLabel}: ${activeMetric.statusLabel})',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  activeMetric.statusAdvice,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.88),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
