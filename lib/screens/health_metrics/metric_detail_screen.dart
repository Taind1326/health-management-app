import 'package:flutter/material.dart';
import '../../models/health_metric.dart';

class MetricDetailScreen extends StatelessWidget {
  final HealthMetric metric;

  const MetricDetailScreen({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi tiết chỉ số'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Chức năng sửa sẽ được hoàn thiện ở Đợt 2')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Xác nhận'),
                  content: const Text('Bạn có chắc muốn xóa chỉ số này?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã xóa')),
                        );
                      },
                      child: const Text('Xóa', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 0,
              color: Colors.green.shade50,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Icon(
                      _getIconForType(metric.metricType),
                      size: 48,
                      color: Colors.green,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      metric.metricTypeLabel,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.green.shade900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      metric.displayValue,
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                side: BorderSide(color: Colors.grey.shade200),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailRow(
                      context,
                      'Thời gian đo',
                      '${metric.recordedAt.day.toString().padLeft(2, '0')}/${metric.recordedAt.month.toString().padLeft(2, '0')}/${metric.recordedAt.year} ${metric.recordedAt.hour.toString().padLeft(2, '0')}:${metric.recordedAt.minute.toString().padLeft(2, '0')}',
                      Icons.access_time,
                    ),
                    const Divider(height: 32),
                    _buildDetailRow(
                      context,
                      'Ghi chú',
                      metric.note?.isNotEmpty == true ? metric.note! : 'Không có ghi chú',
                      Icons.note_alt_outlined,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.grey.shade600, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'blood_pressure':
        return Icons.favorite;
      case 'heart_rate':
        return Icons.monitor_heart;
      case 'weight':
        return Icons.monitor_weight;
      case 'bmi':
        return Icons.accessibility_new;
      default:
        return Icons.health_and_safety;
    }
  }
}
