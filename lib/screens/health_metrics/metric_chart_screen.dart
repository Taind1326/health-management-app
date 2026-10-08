import 'package:flutter/material.dart';
import '../../models/health_metric.dart';

class MetricChartScreen extends StatefulWidget {
  const MetricChartScreen({super.key});

  @override
  State<MetricChartScreen> createState() => _MetricChartScreenState();
}

class _MetricChartScreenState extends State<MetricChartScreen> {
  String _selectedType = 'blood_pressure';
  String _selectedTimeRange = '7d'; // '7d', '30d', '90d'
  
  final List<HealthMetric> _allData = HealthMetric.sampleData();

  @override
  Widget build(BuildContext context) {
    final filteredData = _getFilteredData();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biểu đồ chỉ số'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTypeSelector(),
            const SizedBox(height: 16),
            _buildTimeRangeSelector(),
            const SizedBox(height: 24),
            _buildChart(filteredData),
            const SizedBox(height: 24),
            _buildStatistics(filteredData),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChoiceChip('blood_pressure', 'Huyết áp'),
          const SizedBox(width: 8),
          _buildChoiceChip('heart_rate', 'Nhịp tim'),
          const SizedBox(width: 8),
          _buildChoiceChip('weight', 'Cân nặng'),
          const SizedBox(width: 8),
          _buildChoiceChip('bmi', 'BMI'),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String type, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _selectedType == type,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
          });
        }
      },
      selectedColor: Colors.green.shade100,
    );
  }

  Widget _buildTimeRangeSelector() {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(value: '7d', label: Text('7 ngày')),
        ButtonSegment(value: '30d', label: Text('30 ngày')),
        ButtonSegment(value: '90d', label: Text('3 tháng')),
      ],
      selected: {_selectedTimeRange},
      onSelectionChanged: (Set<String> newSelection) {
        setState(() {
          _selectedTimeRange = newSelection.first;
        });
      },
    );
  }

  List<HealthMetric> _getFilteredData() {
    DateTime cutoffDate = DateTime.now();
    switch (_selectedTimeRange) {
      case '7d':
        cutoffDate = cutoffDate.subtract(const Duration(days: 7));
        break;
      case '30d':
        cutoffDate = cutoffDate.subtract(const Duration(days: 30));
        break;
      case '90d':
        cutoffDate = cutoffDate.subtract(const Duration(days: 90));
        break;
    }

    var data = _allData.where((m) => 
      m.metricType == _selectedType && 
      m.recordedAt.isAfter(cutoffDate)
    ).toList();
    
    // Sort by date ascending for chart
    data.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return data;
  }

  Widget _buildChart(List<HealthMetric> data) {
    if (data.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Center(child: Text('Không có dữ liệu trong khoảng thời gian này')),
        ),
      );
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Xu hướng',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            ...data.asMap().entries.map((entry) {
              int index = entry.key;
              HealthMetric metric = entry.value;
              
              // Compare with previous to show trend
              IconData trendIcon = Icons.horizontal_rule;
              Color trendColor = Colors.grey;
              
              if (index > 0) {
                double currentVal = metric.value;
                double prevVal = data[index - 1].value;
                if (currentVal > prevVal) {
                  trendIcon = Icons.arrow_upward;
                  trendColor = Colors.red;
                } else if (currentVal < prevVal) {
                  trendIcon = Icons.arrow_downward;
                  trendColor = Colors.green;
                }
              }

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        '${metric.recordedAt.day.toString().padLeft(2, '0')}/${metric.recordedAt.month.toString().padLeft(2, '0')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        height: 30,
                        alignment: Alignment.centerLeft,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                metric.displayValue,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (index > 0)
                              Icon(trendIcon, color: trendColor, size: 16),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistics(List<HealthMetric> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    double maxVal = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    double minVal = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    double avgVal = data.map((e) => e.value).reduce((a, b) => a + b) / data.length;
    
    String unit = data.first.unit;

    return Card(
      elevation: 0,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Thống kê',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Colors.green.shade900,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatItem('Cao nhất', '${maxVal.toStringAsFixed(1)} $unit')),
                Expanded(child: _buildStatItem('Thấp nhất', '${minVal.toStringAsFixed(1)} $unit')),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildStatItem('Trung bình', '${avgVal.toStringAsFixed(1)} $unit')),
                Expanded(child: _buildStatItem('Số lần đo', '${data.length}')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.green.shade800, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.green.shade900,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
