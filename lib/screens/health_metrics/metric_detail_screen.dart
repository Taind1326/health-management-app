import 'package:flutter/material.dart';
import '../../models/health_metric.dart';
import '../../repositories/health_metric_repository.dart';

/// Screen displaying details of a specific [HealthMetric] record.
/// Allows real deletion by ID via [HealthMetricRepository].
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
            tooltip: 'Chỉnh sửa',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Chức năng chỉnh sửa sẽ được hoàn thiện ở Đợt 2'),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Xóa',
            onPressed: () {
              showDialog(
                context: context,
                builder: (dialogContext) => AlertDialog(
                  title: const Text('Xác nhận xóa'),
                  content: Text(
                    'Bạn có chắc muốn xóa bản ghi ${metric.metricTypeLabel} (${metric.displayValue}) này không?',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text('Hủy'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Lấy ScaffoldMessenger từ context đang hoạt động trước khi pop
                        final messenger = ScaffoldMessenger.of(context);

                        // Xóa đúng ID khỏi nguồn dữ liệu chung
                        if (metric.id != null) {
                          HealthMetricRepository().delete(metric.id!);
                        }

                        // Đóng dialog xác nhận
                        Navigator.pop(dialogContext);

                        // Đóng màn hình chi tiết và trả về true để màn hình trước biết
                        Navigator.pop(context, true);

                        // Hiển thị thông báo qua messenger an toàn
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text('Đã xóa bản ghi chỉ số thành công!'),
                            backgroundColor: Colors.redAccent,
                          ),
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
                      color: Colors.green.shade700,
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
                      metric.note?.isNotEmpty == true
                          ? metric.note!
                          : 'Không có ghi chú',
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

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
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
        return Icons.bloodtype;
      case 'heart_rate':
        return Icons.favorite;
      case 'weight':
        return Icons.monitor_weight;
      case 'bmi':
        return Icons.calculate;
      default:
        return Icons.health_and_safety;
    }
  }
}
