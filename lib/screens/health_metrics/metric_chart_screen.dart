import 'package:flutter/material.dart';
import '../../controllers/health_metric_controller.dart';
import '../../models/health_metric.dart';
import '../../widgets/aurora_page.dart';
import '../../widgets/tv1_glass_widgets.dart';

/// Màn hình Biểu đồ xu hướng & Thống kê chi tiết chỉ số sức khỏe (TV2 - Đợt 2).
/// Đồng bộ giao diện Aurora Borealis Glassmorphism, vẽ biểu đồ [CustomPaint]
/// theo tỷ lệ thời gian thực tế, tách 2 đường Tâm thu / Tâm trương cho Huyết áp.
class MetricChartScreen extends StatefulWidget {
  final String? initialType;

  const MetricChartScreen({super.key, this.initialType});

  @override
  State<MetricChartScreen> createState() => _MetricChartScreenState();
}

class _MetricChartScreenState extends State<MetricChartScreen> {
  final HealthMetricController _controller = HealthMetricController();
  late String _selectedType;
  String _selectedTimeRange = '7d'; // '7d', '30d', '90d'

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'blood_pressure';
    _controller.loadMetrics();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final filteredData = _getFilteredData();

        return AuroraPage(
          title: 'Biểu đồ chỉ số',
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildTypeSelector(),
                const SizedBox(height: 14),
                _buildTimeRangeSelector(),
                const SizedBox(height: 18),
                _buildChartCard(filteredData),
                const SizedBox(height: 18),
                _buildStatisticsCard(filteredData),
                const SizedBox(height: 18),
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
          _buildChoiceChip(
            'blood_pressure',
            'Huyết áp',
            Icons.bloodtype,
            const Color(0xFFFB7185),
          ),
          const SizedBox(width: 8),
          _buildChoiceChip(
            'heart_rate',
            'Nhịp tim',
            Icons.favorite,
            const Color(0xFFF472B6),
          ),
          const SizedBox(width: 8),
          _buildChoiceChip(
            'weight',
            'Cân nặng',
            Icons.monitor_weight,
            const Color(0xFF38BDF8),
          ),
          const SizedBox(width: 8),
          _buildChoiceChip(
            'bmi',
            'BMI',
            Icons.calculate,
            const Color(0xFF34D399),
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceChip(
    String type,
    String label,
    IconData icon,
    Color color,
  ) {
    final isSelected = _selectedType == type;
    return ChoiceChip(
      avatar: Icon(
        icon,
        size: 18,
        color: isSelected ? Colors.white : color,
      ),
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withValues(alpha: 0.45),
      labelStyle: TextStyle(
        color: Colors.white,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? color : Colors.white.withValues(alpha: 0.30),
        width: isSelected ? 1.4 : 1.0,
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
    return _controller.getChartData(
      metricType: _selectedType,
      timeRange: _selectedTimeRange,
    );
  }

  Widget _buildChartCard(List<HealthMetric> data) {
    final isBp = _selectedType == 'blood_pressure';
    final primaryColor = _getPrimaryColor();
    const secondaryColor = Color(0xFF38BDF8);
    final unit = _getUnit();

    return Tv1GlassCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Biểu đồ xu hướng ($unit)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '${data.length} điểm đo',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
          if (data.isEmpty)
            Container(
              height: 180,
              alignment: Alignment.center,
              child: Text(
                'Không có dữ liệu trong khoảng thời gian này',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontStyle: FontStyle.italic,
                ),
              ),
            )
          else
            SizedBox(
              height: 210,
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
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ],
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
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildStatisticsCard(List<HealthMetric> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    final isBp = _selectedType == 'blood_pressure';
    final unit = _getUnit();

    if (isBp) {
      final sysValues = data.map((e) => e.value).toList();
      final diaValues =
          data.where((e) => e.value2 != null).map((e) => e.value2!).toList();

      final maxSys = sysValues.reduce((a, b) => a > b ? a : b);
      final minSys = sysValues.reduce((a, b) => a < b ? a : b);
      final avgSys = sysValues.reduce((a, b) => a + b) / sysValues.length;

      final maxDia =
          diaValues.isNotEmpty ? diaValues.reduce((a, b) => a > b ? a : b) : 0.0;
      final minDia =
          diaValues.isNotEmpty ? diaValues.reduce((a, b) => a < b ? a : b) : 0.0;
      final avgDia = diaValues.isNotEmpty
          ? diaValues.reduce((a, b) => a + b) / diaValues.length
          : 0.0;

      return Tv1GlassCard(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thống kê Huyết áp ($unit)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${data.length} lần đo',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFB7185),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              '🔴 Tâm thu (Systolic):',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFFFB7185),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Cao nhất',
                    '${maxSys.toInt()} $unit',
                    const Color(0xFFFDA4AF),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Thấp nhất',
                    '${minSys.toInt()} $unit',
                    const Color(0xFFFDA4AF),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Trung bình',
                    '${avgSys.toStringAsFixed(0)} $unit',
                    const Color(0xFFFDA4AF),
                  ),
                ),
              ],
            ),
            Divider(
              height: 24,
              color: Colors.white.withValues(alpha: 0.18),
            ),
            const Text(
              '🔵 Tâm trương (Diastolic):',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF38BDF8),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Cao nhất',
                    '${maxDia.toInt()} $unit',
                    const Color(0xFF7DD3FC),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Thấp nhất',
                    '${minDia.toInt()} $unit',
                    const Color(0xFF7DD3FC),
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Trung bình',
                    '${avgDia.toStringAsFixed(0)} $unit',
                    const Color(0xFF7DD3FC),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      final values = data.map((e) => e.value).toList();
      final maxVal = values.reduce((a, b) => a > b ? a : b);
      final minVal = values.reduce((a, b) => a < b ? a : b);
      final avgVal = values.reduce((a, b) => a + b) / values.length;
      final color = _getPrimaryColor();

      return Tv1GlassCard(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Thống kê ${_getMetricLabel()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${data.length} lần đo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    'Cao nhất',
                    '${_formatVal(maxVal)} $unit',
                    color,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Thấp nhất',
                    '${_formatVal(minVal)} $unit',
                    color,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    'Trung bình',
                    '${_formatVal(avgVal)} $unit',
                    color,
                  ),
                ),
              ],
            ),
          ],
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
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.72),
            fontSize: 11.5,
          ),
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

    final reversed = data.reversed.toList();

    return Tv1GlassCard(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Danh sách số liệu trong kỳ',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          ...reversed.map((metric) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 5.0),
              child: Row(
                children: [
                  SizedBox(
                    width: 86,
                    child: Text(
                      '${metric.recordedAt.day.toString().padLeft(2, '0')}/${metric.recordedAt.month.toString().padLeft(2, '0')} ${metric.recordedAt.hour.toString().padLeft(2, '0')}:${metric.recordedAt.minute.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            metric.displayValue,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            metric.statusLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.80),
                            ),
                          ),
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
    );
  }

  Color _getPrimaryColor() {
    switch (_selectedType) {
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

  String _getUnit() => HealthMetric.unitForType(_selectedType);

  String _getMetricLabel() => HealthMetric.labelForType(_selectedType);
}

/// Custom painter vẽ biểu đồ xu hướng với trục thời gian thực tế, đường lưới và điểm đo.
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
    const leftPadding = 38.0;
    const rightPadding = 16.0;
    const topPadding = 24.0;
    const bottomPadding = 30.0;

    final chartWidth = size.width - leftPadding - rightPadding;
    final chartHeight = size.height - topPadding - bottomPadding;

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

    double range = maxY - minY;
    if (range < 4) range = 8;
    minY = (minY - range * 0.15).floorToDouble();
    maxY = (maxY + range * 0.15).ceilToDouble();
    if (minY < 0) minY = 0;
    final ySpan = (maxY - minY == 0) ? 1.0 : (maxY - minY);

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.22)
      ..strokeWidth = 0.8;

    final axisTextPainter = TextPainter(textDirection: TextDirection.ltr);

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
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.78),
          fontSize: 10,
        ),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(
        canvas,
        Offset(
          leftPadding - axisTextPainter.width - 6,
          yPos - axisTextPainter.height / 2,
        ),
      );
    }

    final totalDurationMs = data.length > 1
        ? data.last.recordedAt.difference(data.first.recordedAt).inMilliseconds
        : 0;

    double getX(int index) {
      if (data.length <= 1 || totalDurationMs == 0) {
        return leftPadding + chartWidth / 2;
      }
      const pointMargin = 12.0;
      final usableWidth = chartWidth - (pointMargin * 2);
      final pointDiffMs = data[index]
          .recordedAt
          .difference(data.first.recordedAt)
          .inMilliseconds;
      final ratio = pointDiffMs / totalDurationMs;
      return leftPadding + pointMargin + (ratio * usableWidth);
    }

    double getY(double val) {
      return topPadding + chartHeight - ((val - minY) / ySpan) * chartHeight;
    }

    final line1Paint = Paint()
      ..color = primaryColor
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final line2Paint = Paint()
      ..color = secondaryColor
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final dotPaint1 = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    final dotPaint2 = Paint()
      ..color = secondaryColor
      ..style = PaintingStyle.fill;
    final dotInnerPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;

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
            primaryColor.withValues(alpha: 0.30),
            primaryColor.withValues(alpha: 0.0),
          ],
        ).createShader(
          Rect.fromLTWH(leftPadding, topPadding, chartWidth, chartHeight),
        );

      canvas.drawPath(fillPath, fillPaint);
    }

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

    for (int i = 0; i < data.length; i++) {
      final m = data[i];
      final x = getX(i);
      final y1 = getY(m.value);

      canvas.drawCircle(Offset(x, y1), 4.8, dotPaint1);
      canvas.drawCircle(Offset(x, y1), 2.2, dotInnerPaint);

      final valStr = isBp
          ? '${m.value.toInt()}'
          : (m.value == m.value.roundToDouble()
              ? m.value.toInt().toString()
              : m.value.toStringAsFixed(1));
      axisTextPainter.text = TextSpan(
        text: valStr,
        style: TextStyle(
          color: primaryColor,
          fontSize: 10.5,
          fontWeight: FontWeight.bold,
        ),
      );
      axisTextPainter.layout();
      axisTextPainter.paint(
        canvas,
        Offset(x - axisTextPainter.width / 2, y1 - 16),
      );

      if (isBp && m.value2 != null) {
        final y2 = getY(m.value2!);
        canvas.drawCircle(Offset(x, y2), 4.8, dotPaint2);
        canvas.drawCircle(Offset(x, y2), 2.2, dotInnerPaint);

        axisTextPainter.text = TextSpan(
          text: '${m.value2!.toInt()}',
          style: TextStyle(
            color: secondaryColor,
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
          ),
        );
        axisTextPainter.layout();
        axisTextPainter.paint(
          canvas,
          Offset(x - axisTextPainter.width / 2, y2 + 6),
        );
      }

      final dateText =
          '${m.recordedAt.day.toString().padLeft(2, '0')}/${m.recordedAt.month.toString().padLeft(2, '0')}';
      axisTextPainter.text = TextSpan(
        text: dateText,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.80),
          fontSize: 10,
        ),
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
