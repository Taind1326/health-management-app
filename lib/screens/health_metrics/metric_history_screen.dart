import 'package:flutter/material.dart';
import '../../controllers/health_metric_controller.dart';
import '../../models/health_metric.dart';
import '../../widgets/aurora_page.dart';
import '../../widgets/tv1_glass_widgets.dart';
import 'metric_detail_screen.dart';

/// Màn hình Lịch sử chỉ số sức khỏe (TV2 - Đợt 2).
/// Đồng bộ giao diện Aurora Borealis Glassmorphism, lọc theo loại chỉ số
/// và kết nối trực tiếp với [HealthMetricController].
class MetricHistoryScreen extends StatefulWidget {
  const MetricHistoryScreen({super.key});

  @override
  State<MetricHistoryScreen> createState() => _MetricHistoryScreenState();
}

class _MetricHistoryScreenState extends State<MetricHistoryScreen> {
  final HealthMetricController _controller = HealthMetricController();
  String? _selectedFilter; // null means 'Tất cả'

  static const Map<String, String> _filterLabels = {
    'blood_pressure': 'Huyết áp',
    'heart_rate': 'Nhịp tim',
    'weight': 'Cân nặng',
    'bmi': 'BMI',
  };

  @override
  void initState() {
    super.initState();
    _controller.loadMetrics();
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  IconData _getIcon(String type) {
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

  Color _getColor(String type) {
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final List<HealthMetric> filteredList =
            _controller.getByType(_selectedFilter);

        return AuroraPage(
          title: 'Lịch sử chỉ số',
          body: Column(
            children: [
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 10.0,
                ),
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Tất cả'),
                      selected: _selectedFilter == null,
                      selectedColor: const Color(0xFF0284C7),
                      checkmarkColor: Colors.white,
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: _selectedFilter == null
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      onSelected: (_) =>
                          setState(() => _selectedFilter = null),
                    ),
                    const SizedBox(width: 8),
                    ..._filterLabels.entries.map((entry) {
                      final isSelected = _selectedFilter == entry.key;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: FilterChip(
                          label: Text(entry.value),
                          selected: isSelected,
                          selectedColor: const Color(0xFF0284C7),
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          onSelected: (_) =>
                              setState(() => _selectedFilter = entry.key),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              Expanded(
                child: filteredList.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.inbox_outlined,
                              size: 64,
                              color: Colors.white.withValues(alpha: 0.45),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Chưa có dữ liệu',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.white.withValues(alpha: 0.70),
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                        itemCount: filteredList.length,
                        itemBuilder: (context, index) {
                          final metric = filteredList[index];
                          final color = _getColor(metric.metricType);
                          final badgeColor =
                              _severityColor(metric.statusSeverity);
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Tv1GlassCard(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(14),
                                onTap: () async {
                                  final changed = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          MetricDetailScreen(metric: metric),
                                    ),
                                  );
                                  if (changed == true) {
                                    _controller.loadMetrics();
                                  }
                                },
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 22,
                                      backgroundColor:
                                          color.withValues(alpha: 0.20),
                                      child: Icon(
                                        _getIcon(metric.metricType),
                                        color: color,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  '${metric.metricTypeLabel}: ${metric.displayValue}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 15,
                                                  ),
                                                ),
                                              ),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 3,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: badgeColor.withValues(
                                                      alpha: 0.20),
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color: badgeColor.withValues(
                                                        alpha: 0.50),
                                                  ),
                                                ),
                                                child: Text(
                                                  metric.statusLabel,
                                                  style: TextStyle(
                                                    color: badgeColor,
                                                    fontSize: 10.5,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatDateTime(metric.recordedAt),
                                            style: TextStyle(
                                              color: Colors.white
                                                  .withValues(alpha: 0.72),
                                              fontSize: 12.5,
                                            ),
                                          ),
                                          if (metric.note != null &&
                                              metric.note!.isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              metric.note!,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white
                                                    .withValues(alpha: 0.65),
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    const Icon(
                                      Icons.chevron_right,
                                      color: Colors.white70,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
