import 'package:flutter/material.dart';
import '../../models/health_metric.dart';
import 'metric_detail_screen.dart';

/// Screen displaying the history of all health metric records.
/// Supports filtering by metric type.
class MetricHistoryScreen extends StatefulWidget {
  const MetricHistoryScreen({super.key});

  @override
  State<MetricHistoryScreen> createState() => _MetricHistoryScreenState();
}

class _MetricHistoryScreenState extends State<MetricHistoryScreen> {
  String? _selectedFilter; // null means 'Tất cả'
  late List<HealthMetric> _allMetrics;

  // Filter options: metric type key -> Vietnamese label
  static const Map<String, String> _filterLabels = {
    'blood_pressure': 'Huyết áp',
    'heart_rate': 'Nhịp tim',
    'weight': 'Cân nặng',
    'bmi': 'BMI',
  };

  @override
  void initState() {
    super.initState();
    _allMetrics = HealthMetric.sampleData();
    _allMetrics.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
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
        return Colors.red;
      case 'heart_rate':
        return Colors.pink;
      case 'weight':
        return Colors.blue;
      case 'bmi':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = _selectedFilter == null
        ? _allMetrics
        : _allMetrics.where((m) => m.metricType == _selectedFilter).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử chỉ số'),
      ),
      body: Column(
        children: [
          // Filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('Tất cả'),
                  selected: _selectedFilter == null,
                  onSelected: (_) => setState(() => _selectedFilter = null),
                ),
                const SizedBox(width: 8),
                ..._filterLabels.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: FilterChip(
                      label: Text(entry.value),
                      selected: _selectedFilter == entry.key,
                      onSelected: (_) =>
                          setState(() => _selectedFilter = entry.key),
                    ),
                  );
                }),
              ],
            ),
          ),
          // List
          Expanded(
            child: filteredList.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.inbox_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'Chưa có dữ liệu',
                          style: TextStyle(
                              fontSize: 16, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredList.length,
                    itemBuilder: (context, index) {
                      final metric = filteredList[index];
                      final color = _getColor(metric.metricType);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.15),
                          child: Icon(_getIcon(metric.metricType), color: color),
                        ),
                        title: Text(
                          '${metric.metricTypeLabel}: ${metric.displayValue}',
                        ),
                        subtitle:
                            Text(_formatDateTime(metric.recordedAt)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  MetricDetailScreen(metric: metric),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
