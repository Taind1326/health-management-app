import 'package:flutter/material.dart';
import '../../models/health_metric.dart';
import 'add_metric_screen.dart';
import 'metric_history_screen.dart';
import 'metric_chart_screen.dart';

/// Main overview screen for Health Metrics module.
/// Shows the latest values for each metric type as cards,
/// with navigation to Add, History, and Chart screens.
class HealthMetricScreen extends StatefulWidget {
  const HealthMetricScreen({super.key});

  @override
  State<HealthMetricScreen> createState() => _HealthMetricScreenState();
}

class _HealthMetricScreenState extends State<HealthMetricScreen> {
  final List<HealthMetric> _metrics = HealthMetric.sampleData();

  /// Get the most recent metric record for a given type.
  HealthMetric? _getLatestMetric(String type) {
    try {
      final typeMetrics = _metrics.where((m) => m.metricType == type).toList();
      if (typeMetrics.isEmpty) return null;
      typeMetrics.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
      return typeMetrics.first;
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final latestBp = _getLatestMetric('blood_pressure');
    final latestHr = _getLatestMetric('heart_rate');
    final latestWeight = _getLatestMetric('weight');
    final latestBmi = _getLatestMetric('bmi');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chỉ số sức khỏe'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Chỉ số gần nhất',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            // Row 1: Blood Pressure + Heart Rate
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    metric: latestBp,
                    icon: Icons.bloodtype,
                    color: Colors.red,
                    defaultLabel: 'Huyết áp',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    metric: latestHr,
                    icon: Icons.favorite,
                    color: Colors.pink,
                    defaultLabel: 'Nhịp tim',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Row 2: Weight + BMI
            Row(
              children: [
                Expanded(
                  child: _buildMetricCard(
                    context,
                    metric: latestWeight,
                    icon: Icons.monitor_weight,
                    color: Colors.blue,
                    defaultLabel: 'Cân nặng',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildMetricCard(
                    context,
                    metric: latestBmi,
                    icon: Icons.calculate,
                    color: Colors.green,
                    defaultLabel: 'BMI',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            // Action buttons
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MetricHistoryScreen()),
                );
              },
              icon: const Icon(Icons.history),
              label: const Text('Xem lịch sử'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const MetricChartScreen()),
                );
              },
              icon: const Icon(Icons.bar_chart),
              label: const Text('Xem biểu đồ'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMetricScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Builds a card widget showing the latest value for a metric type.
  Widget _buildMetricCard(
    BuildContext context, {
    required HealthMetric? metric,
    required IconData icon,
    required Color color,
    required String defaultLabel,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    metric?.metricTypeLabel ?? defaultLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (metric != null) ...[
              Text(
                metric.displayValue,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                '${metric.recordedAt.day.toString().padLeft(2, '0')}/${metric.recordedAt.month.toString().padLeft(2, '0')}/${metric.recordedAt.year}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
              ),
            ] else ...[
              Text(
                'Chưa có dữ liệu',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 4),
              const Text('', style: TextStyle(fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}
