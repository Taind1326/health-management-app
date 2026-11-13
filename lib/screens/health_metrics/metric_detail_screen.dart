import 'package:flutter/material.dart';
import '../../controllers/health_metric_controller.dart';
import '../../models/health_metric.dart';
import '../../widgets/aurora_page.dart';
import '../../widgets/tv1_glass_widgets.dart';
import 'add_metric_screen.dart';

/// Màn hình Chi tiết bản ghi chỉ số sức khỏe (TV2 - Đợt 2).
/// Cho phép Chỉnh sửa trực tiếp hoặc Xóa bản ghi khỏi SQLite thông qua [HealthMetricController],
/// kèm theo thẻ Đánh giá y khoa & Khuyến nghị theo chuẩn WHO/AHA.
class MetricDetailScreen extends StatefulWidget {
  final HealthMetric metric;

  const MetricDetailScreen({super.key, required this.metric});

  @override
  State<MetricDetailScreen> createState() => _MetricDetailScreenState();
}

class _MetricDetailScreenState extends State<MetricDetailScreen> {
  final HealthMetricController _controller = HealthMetricController();
  late HealthMetric _metric;

  @override
  void initState() {
    super.initState();
    _metric = widget.metric;
  }

  Future<void> _editMetric() async {
    final result = await Navigator.push<Object?>(
      context,
      MaterialPageRoute(
        builder: (_) => AddMetricScreen(initialMetric: _metric),
      ),
    );
    if (result is HealthMetric && mounted) {
      setState(() {
        _metric = result;
      });
    } else if (result == true && mounted) {
      await _controller.loadMetrics();
      if (_metric.id != null) {
        final refreshed = _controller
            .getAll()
            .where((m) => m.id == _metric.id)
            .firstOrNull;
        if (refreshed != null && mounted) {
          setState(() {
            _metric = refreshed;
          });
        }
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showAuroraDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: Text(
          'Bạn có chắc muốn xóa bản ghi ${_metric.metricTypeLabel} (${_metric.displayValue}) này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Xóa',
              style: TextStyle(color: Color(0xFFFF6B6B)),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (_metric.id != null) {
      await _controller.deleteMetric(_metric.id!);
    }

    if (!mounted) return;
    Navigator.pop(context, true);

    messenger.showSnackBar(
      const SnackBar(
        content: Text('Đã xóa bản ghi chỉ số thành công!'),
        backgroundColor: Colors.redAccent,
      ),
    );
  }

  Color _accentForType(String type) {
    switch (type) {
      case 'blood_pressure':
        return const Color(0xFFFB7185);
      case 'heart_rate':
        return const Color(0xFFF472B6);
      case 'weight':
        return const Color(0xFF38BDF8);
      case 'bmi':
        return const Color(0xFF34D399);
      default:
        return const Color(0xFF7DD3FC);
    }
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'normal':
        return const Color(0xFF34D399);
      case 'warning':
        return const Color(0xFFFBBF24);
      default:
        return const Color(0xFFFB7185);
    }
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final accent = _accentForType(_metric.metricType);
    final statusColor = _severityColor(_metric.statusSeverity);

    return AuroraPage(
      title: 'Chi tiết chỉ số',
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          tooltip: 'Chỉnh sửa',
          onPressed: _editMetric,
        ),
        IconButton(
          icon: const Icon(Icons.delete),
          tooltip: 'Xóa',
          onPressed: _confirmDelete,
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Tv1GlassCard(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.20),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: accent.withValues(alpha: 0.45),
                      ),
                    ),
                    child: Icon(
                      _getIconForType(_metric.metricType),
                      size: 40,
                      color: accent,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    _metric.metricTypeLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _metric.displayValue,
                    style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: statusColor.withValues(alpha: 0.55),
                      ),
                    ),
                    child: Text(
                      _metric.statusLabel,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Tv1GlassCard(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medical_information_outlined,
                          color: statusColor, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Đánh giá & Khuyến nghị y khoa',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _metric.normalRangeText,
                    style: const TextStyle(
                      color: Color(0xFF7DD3FC),
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _metric.statusAdvice,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 13.5,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Tv1GlassCard(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow(
                    'Thời gian đo',
                    _formatDateTime(_metric.recordedAt),
                    Icons.access_time,
                  ),
                  Divider(
                    height: 28,
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                  _buildDetailRow(
                    'Ghi chú',
                    _metric.note?.isNotEmpty == true
                        ? _metric.note!
                        : 'Không có ghi chú',
                    Icons.note_alt_outlined,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: const Color(0xFF7DD3FC), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 12.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
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
