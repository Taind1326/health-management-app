import 'package:flutter/material.dart';
import '../../models/health_metric.dart';
import '../../repositories/health_metric_repository.dart';

/// Screen displaying interactive visual trend charts and detailed statistics.
/// Includes a custom line chart with time axis, units, and systolic/diastolic separation for blood pressure.
class MetricChartScreen extends StatefulWidget {
  const MetricChartScreen({super.key});

  @override
  State<MetricChartScreen> createState() => _MetricChartScreenState();
}

class _MetricChartScreenState extends State<MetricChartScreen> {
  String _selectedType = 'blood_pressure';
  String _selectedTimeRange = '7d'; // '7d', '30d', '90d'

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: HealthMetricRepository(),
      builder: (context, _) {
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
                const SizedBox(height: 20),
                _buildChartCard(filteredData),
                const SizedBox(height: 20),
                _buildStatisticsCard(filteredData),
                const SizedBox(height: 20),
                _buildRecentHistoryList(filteredData),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTypeSelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildChoiceChip('blood_pressure', 'Huyết áp', Icons.bloodtype, Colors.red),
          const SizedBox(width: 8),
          _buildChoiceChip('heart_rate', 'Nhịp tim', Icons.favorite, Colors.pink),
          const SizedBox(width: 8),
          _buildChoiceChip('weight', 'Cân nặng', Icons.monitor_weight, Colors.blue),
          const SizedBox(width: 8),
          _buildChoiceChip('bmi', 'BMI', Icons.calculate, Colors.green),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(String type, String label, IconData icon, Color color) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      avatar: Icon(icon, size: 18, color: isSelected ? Colors.white : color),
      label: Text(label),
      selected: isSelected,
      selectedColor: color,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedType = type;
          });
        }
      },
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

    return HealthMetricRepository().getFiltered(
      metricType: _selectedType,
      since: cutoffDate,
    );
  }

  Widget _buildChartCard(List<HealthMetric> data) {
    final isBp = _selectedType == 'blood_pressure';
    final primaryColor = _getPrimaryColor();
    final secondaryColor = Colors.blue.shade600;
    final unit = _getUnit();

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Biểu đồ xu hướng ($unit)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  '${data.length} điểm đo',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Legend
            if (isBp)
              Row(
                children: [
                  _buildLegendItem(primaryColor, 'Tâm thu (Systolic)'),
                  const SizedBox(width: 16),
                  _buildLegendItem(secondaryColor, 'Tâm trương (Diastolic)'),
                ],
              )
            else
              Row(
                children: [
                  _buildLegendItem(primaryColor, '${_getMetricLabel()} ($unit)'),
                ],
              ),
            const SizedBox(height: 16),
            // Chart Canvas
            if (data.isEmpty)
              Container(
                height: 180,
                alignment: Alignment.center,
                child: Text(
                  'Không có dữ liệu trong khoảng thời gian này',
                  style: TextStyle(color: Colors.grey.shade600, fontStyle: FontStyle.italic),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: CustomPaint(
                  painter: HealthMetricChartPainter(
                    data: data,
                    metricType: _selectedType,
                    primaryColor: primaryColor,
                    secondaryColor: secondaryColor,
                    unit: unit,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              'Trục hoành: Thời gian đo (ngày/tháng)  •  Trục tung: Giá trị ($unit)',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey.shade800),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(List<HealthMetric> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final isBp = _selectedType == 'blood_pressure';
    final unit = _getUnit();

    if (isBp) {
      // Thống kê riêng biệt cho cả Tâm thu và Tâm trương
      final sysValues = data.map((e) => e.value).toList();
      final diaValues = data.where((e) => e.value2 != null).map((e) => e.value2!).toList();

      final maxSys = sysValues.reduce((a, b) => a > b ? a : b);
      final minSys = sysValues.reduce((a, b) => a < b ? a : b);
      final avgSys = sysValues.reduce((a, b) => a + b) / sysValues.length;

      final maxDia = diaValues.isNotEmpty ? diaValues.reduce((a, b) => a > b ? a : b) : 0.0;
      final minDia = diaValues.isNotEmpty ? diaValues.reduce((a, b) => a < b ? a : b) : 0.0;
      final avgDia = diaValues.isNotEmpty ? diaValues.reduce((a, b) => a + b) / diaValues.length : 0.0;

      return Card(
        elevation: 1,
        color: Colors.red.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thống kê Huyết áp ($unit)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.red.shade900,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${data.length} lần đo',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red.shade900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Section 1: Tâm thu (Systolic)
              Text(
                '🔴 Tâm thu (Systolic):',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red.shade800, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _buildStatItem('Cao nhất', '${maxSys.toInt()} $unit', Colors.red.shade900)),
                  Expanded(child: _buildStatItem('Thấp nhất', '${minSys.toInt()} $unit', Colors.red.shade900)),
                  Expanded(child: _buildStatItem('Trung bình', '${avgSys.toStringAsFixed(0)} $unit', Colors.red.shade900)),
                ],
              ),
              const Divider(height: 24),
              // Section 2: Tâm trương (Diastolic)
              Text(
                '🔵 Tâm trương (Diastolic):',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue.shade800, fontSize: 13),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(child: _buildStatItem('Cao nhất', '${maxDia.toInt()} $unit', Colors.blue.shade900)),
                  Expanded(child: _buildStatItem('Thấp nhất', '${minDia.toInt()} $unit', Colors.blue.shade900)),
                  Expanded(child: _buildStatItem('Trung bình', '${avgDia.toStringAsFixed(0)} $unit', Colors.blue.shade900)),
                ],
              ),
            ],
          ),
        ),
      );
    } else {
      // Thống kê cho các chỉ số đơn lẻ (Nhịp tim, Cân nặng, BMI)
      final values = data.map((e) => e.value).toList();
      final maxVal = values.reduce((a, b) => a > b ? a : b);
      final minVal = values.reduce((a, b) => a < b ? a : b);
      final avgVal = values.reduce((a, b) => a + b) / values.length;
      final color = _getPrimaryColor();

      return Card(
        elevation: 1,
        color: color.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Thống kê ${_getMetricLabel()}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${data.length} lần đo',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildStatItem('Cao nhất', '${_formatVal(maxVal)} $unit', color),
                  ),
                  Expanded(
                    child: _buildStatItem('Thấp nhất', '${_formatVal(minVal)} $unit', color),
                  ),
                  Expanded(
                    child: _buildStatItem('Trung bình', '${_formatVal(avgVal)} $unit', color),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  String _formatVal(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(1);
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade700, fontSize: 11),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildRecentHistoryList(List<HealthMetric> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    // Show reverse order (newest first)
    final reversed = data.reversed.toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Danh sách số liệu trong kỳ',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ...reversed.map((metric) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: Row(
                  children: [
                    SizedBox(
                      width: 80,
                      child: Text(
                        '${metric.recordedAt.day.toString().padLeft(2, '0')}/${metric.recordedAt.month.toString().padLeft(2, '0')} ${metric.recordedAt.hour.toString().padLeft(2, '0')}:${metric.recordedAt.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Text(
                          metric.displayValue,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
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

  Color _getPrimaryColor() {
    switch (_selectedType) {
      case 'blood_pressure':
        return Colors.red.shade600;
      case 'heart_rate':
        return Colors.pink.shade600;
      case 'weight':
        return Colors.blue.shade600;
      case 'bmi':
        return Colors.green.shade600;
      default:
        return Colors.grey.shade700;
    }
  }

  String _getUnit() {
    switch (_selectedType) {
      case 'blood_pressure':
        return 'mmHg';
      case 'heart_rate':
        return 'bpm';
      case 'weight':
        return 'kg';
      case 'bmi':
        return 'kg/m²';
      default:
        return '';
    }
  }

  String _getMetricLabel() {
    switch (_selectedType) {
      case 'blood_pressure':
        return 'Huyết áp';
      case 'heart_rate':
        return 'Nhịp tim';
      case 'weight':
        return 'Cân nặng';
      case 'bmi':
        return 'BMI';
      default:
        return 'Chỉ số';
    }
  }
}

/// Custom painter for rendering the line chart with time/value axes, grid lines, and dots.
class HealthMetricChartPainter extends CustomPainter {
  final List<HealthMetric> data;
  final String metricType;
  final Color primaryColor;
  final Color secondaryColor;
  final String unit;

  HealthMetricChartPainter({
    required this.data,
    required this.metricType,
    required this.primaryColor,
    required this.secondaryColor,
    required this.unit,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final isBp = metricType == 'blood_pressure';
    const leftPadding = 36.0;
    const rightPadding = 16.0;
    const topPadding = 24.0;
    const bottomPadding = 30.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

    // Tính Min và Max
    double minY = data.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    double maxY = data.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    if (isBp) {
      for (final m in data) {
        if (m.value2 != null) {
          if (m.value2! < minY) minY = m.value2!;
          if (m.value2! > maxY) maxY = m.value2!;
        }
      }
    }

    // Đệm khoảng cách cho trục Y
    double range = maxY - minY;
    if (range < 4) range = 8;
    minY = (minY - range * 0.15).floorToDouble();
    maxY = (maxY + range * 0.15).ceilToDouble();
    if (minY < 0) minY = 0;
    final ySpan = (maxY - minY == 0) ? 1.0 : (maxY - minY);

    final gridPaint = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 0.8;

    final axisTextPainter = TextPainter(textDirection: TextDirection.ltr);

    // Vẽ các đường lưới ngang và nhãn trục Y
    const gridSteps = 3;
    for (int i = 0; i <= gridSteps; i++) {
      final yVal = minY + (i / gridSteps) * (maxY - minY);
      final yPos = topPadding + chartHeight - (i / gridSteps) * chartHeight;

      canvas.drawLine(
        Offset(leftPadding, yPos),
        Offset(size.width - rightPadding, yPos),
        gridPaint,
      );

      axisTextPainter.text = TextSpan(
        text: yVal.toInt().toString(),
        style: TextStyle(color: Colors.grey.shade600, fontSize: 10),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(
        canvas,
        Offset(leftPadding - axisTextPainter.width - 6, yPos - axisTextPainter.height / 2),
      );
    }

    // Tính khoảng cách tọa độ X theo tỷ lệ thời gian thực tế giữa các điểm đo
    final totalDurationMs = data.length > 1
        ? data.last.recordedAt.difference(data.first.recordedAt).inMilliseconds
        : 0;

    double getX(int index) {
      if (data.length <= 1 || totalDurationMs == 0) {
        return leftPadding + chartWidth / 2;
      }
      const pointMargin = 12.0;
      final usableWidth = chartWidth - (pointMargin * 2);
      final pointDiffMs =
          data[index].recordedAt.difference(data.first.recordedAt).inMilliseconds;
      final ratio = pointDiffMs / totalDurationMs;
      return leftPadding + pointMargin + (ratio * usableWidth);
    }

    double getY(double val) {
      return topPadding + chartHeight - ((val - minY) / ySpan) * chartHeight;
    }

    final line1Paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final line2Paint = Paint()
      ..color = secondaryColor
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint1 = Paint()..color = primaryColor..style = PaintingStyle.fill;
    final dotPaint2 = Paint()..color = secondaryColor..style = PaintingStyle.fill;
    final dotInnerPaint = Paint()..color = Colors.white..style = PaintingStyle.fill;

    // Đường 1: Tâm thu hoặc chỉ số chính
    final path1 = Path();
    for (int i = 0; i < data.length; i++) {
      final x = getX(i);
      final y = getY(data[i].value);
      if (i == 0) {
        path1.moveTo(x, y);
      } else {
        path1.lineTo(x, y);
      }
    }
    if (data.length > 1) {
      canvas.drawPath(path1, line1Paint);
    }

    // Đổ bóng màu dưới đường chỉ số đơn
    if (!isBp && data.length > 1) {
      final fillPath = Path.from(path1)
        ..lineTo(getX(data.length - 1), topPadding + chartHeight)
        ..lineTo(getX(0), topPadding + chartHeight)
        ..close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            primaryColor.withValues(alpha: 0.22),
            primaryColor.withValues(alpha: 0.0),
          ],
        ).createShader(Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight));

      canvas.drawPath(fillPath, fillPaint);
    }

    // Đường 2: Tâm trương (cho Huyết áp)
    if (isBp) {
      final path2 = Path();
      for (int i = 0; i < data.length; i++) {
        if (data[i].value2 != null) {
          final x = getX(i);
          final y = getY(data[i].value2!);
          if (i == 0) {
            path2.moveTo(x, y);
          } else {
            path2.lineTo(x, y);
          }
        }
      }
      if (data.length > 1) {
        canvas.drawPath(path2, line2Paint);
      }
    }

    // Vẽ điểm tròn, giá trị số và ngày tháng trục X
    for (int i = 0; i < data.length; i++) {
      final m = data[i];
      final x = getX(i);
      final y1 = getY(m.value);

      // Điểm 1
      canvas.drawCircle(Offset(x, y1), 4.5, dotPaint1);
      canvas.drawCircle(Offset(x, y1), 2.2, dotInnerPaint);

      // Chữ số giá trị 1
      final valStr = isBp
          ? '${m.value.toInt()}'
          : (m.value == m.value.roundToDouble()
              ? m.value.toInt().toString()
              : m.value.toStringAsFixed(1));
      axisTextPainter.text = TextSpan(
        text: valStr,
        style: TextStyle(
          color: primaryColor,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(
        canvas,
        Offset(x - axisTextPainter.width / 2, y1 - 16),
      );

      // Điểm 2 & Chữ số giá trị 2 (nếu Huyết áp)
      if (isBp && m.value2 != null) {
        final y2 = getY(m.value2!);
        canvas.drawCircle(Offset(x, y2), 4.5, dotPaint2);
        canvas.drawCircle(Offset(x, y2), 2.2, dotInnerPaint);

        axisTextPainter.text = TextSpan(
          text: '${m.value2!.toInt()}',
          style: TextStyle(
            color: secondaryColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        );
        axisTextPainter.layout();
        axisTextPainter.paint(
          canvas,
          Offset(x - axisTextPainter.width / 2, y2 + 6),
        );
      }

      // Nhãn ngày tháng trên trục X
      final dateText =
          '${m.recordedAt.day.toString().padLeft(2, '0')}/${m.recordedAt.month.toString().padLeft(2, '0')}';
      axisTextPainter.text = TextSpan(
        text: dateText,
        style: TextStyle(color: Colors.grey.shade700, fontSize: 10),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(
        canvas,
        Offset(x - axisTextPainter.width / 2, topPadding + chartHeight + 8),
      );
    }
  }

  @override
  bool shouldRepaint(covariant HealthMetricChartPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.metricType != metricType ||
        oldDelegate.primaryColor != primaryColor;
  }
}
