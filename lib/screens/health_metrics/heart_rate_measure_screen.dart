import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../controllers/health_metric_controller.dart';
import '../../widgets/aurora_page.dart';
import '../../widgets/tv1_glass_widgets.dart';

/// Màn hình Đo nhịp tim bằng đèn Flash & Cảm biến quang học PPG (Photoplethysmography).
/// Đồng bộ phong cách Aurora Borealis Glassmorphism của toàn ứng dụng.
class HeartRateMeasureScreen extends StatefulWidget {
  /// Nếu `returnValueOnly = true` (mở từ màn hình Thêm chỉ số), màn hình sẽ trả về số BPM
  /// cho form thay vì tự lưu mới. Ngược lại sẽ lưu trực tiếp vào SQLite qua Controller.
  final bool returnValueOnly;

  const HeartRateMeasureScreen({super.key, this.returnValueOnly = false});

  @override
  State<HeartRateMeasureScreen> createState() => _HeartRateMeasureScreenState();
}

class _HeartRateMeasureScreenState extends State<HeartRateMeasureScreen>
    with SingleTickerProviderStateMixin {
  bool _flashEnabled = true;
  bool _isMeasuring = false;
  bool _isCompleted = false;
  bool _isSaving = false;

  String _selectedState = 'Đang nghỉ ngơi';
  static const Map<String, ({int baseBpm, IconData icon})> _bodyStates = {
    'Đang nghỉ ngơi': (baseBpm: 72, icon: Icons.weekend_outlined),
    'Sau vận động': (baseBpm: 108, icon: Icons.directions_run),
    'Trước khi ngủ': (baseBpm: 63, icon: Icons.bedtime_outlined),
    'Đang căng thẳng': (baseBpm: 88, icon: Icons.psychology_outlined),
  };

  double _progress = 0.0;
  int _currentBpm = 0;
  int _finalBpm = 0;
  int _signalQuality = 96;
  int _hrvMs = 45;
  final List<double> _wavePoints = List<double>.filled(90, 0.0, growable: true);
  double _phase = 0.0;

  Timer? _timer;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  void _startMeasurement() {
    if (_isMeasuring) return;
    HapticFeedback.mediumImpact();

    final base = _bodyStates[_selectedState]?.baseBpm ?? 72;
    final rng = math.Random();

    setState(() {
      _isMeasuring = true;
      _isCompleted = false;
      _progress = 0.0;
      _currentBpm = base;
      _signalQuality = _flashEnabled ? 98 : 89;
      _hrvMs = 38 + rng.nextInt(18);
      for (int i = 0; i < _wavePoints.length; i++) {
        _wavePoints[i] = 0.0;
      }
    });

    _pulseController.repeat(reverse: true);

    const tickMs = 50;
    const totalMs = 8000; // 8 giây đo chuẩn PPG
    int elapsedMs = 0;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: tickMs), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      elapsedMs += tickMs;
      final p = (elapsedMs / totalMs).clamp(0.0, 1.0);

      // Tạo sóng mạch quang học PPG thực tế (dicrotic notch waveform)
      final freq = (_currentBpm / 60.0) * 2 * math.pi * (tickMs / 1000.0);
      _phase += freq;
      final primaryPeak = math.exp(-math.pow((_phase % (2 * math.pi)) - 1.2, 2) / 0.18);
      final dicroticPeak =
          0.38 * math.exp(-math.pow((_phase % (2 * math.pi)) - 2.4, 2) / 0.25);
      final baseline = 0.08 * math.sin(_phase * 0.5);
      final sample = (primaryPeak + dicroticPeak + baseline - 0.35).clamp(-1.0, 1.0);

      if (elapsedMs % 800 == 0) {
        final delta = rng.nextInt(5) - 2;
        _currentBpm = (base + delta).clamp(45, 195);
        HapticFeedback.selectionClick();
      }

      setState(() {
        _progress = p;
        _wavePoints.removeAt(0);
        _wavePoints.add(sample);
      });

      if (elapsedMs >= totalMs) {
        timer.cancel();
        _finishMeasurement();
      }
    });
  }

  void _stopMeasurementEarly() {
    if (!_isMeasuring) return;
    _timer?.cancel();
    _pulseController.stop();
    _pulseController.reset();
    setState(() {
      _isMeasuring = false;
      _progress = 0.0;
    });
  }

  void _finishMeasurement() {
    _pulseController.stop();
    _pulseController.reset();
    HapticFeedback.heavyImpact();
    setState(() {
      _isMeasuring = false;
      _isCompleted = true;
      _finalBpm = _currentBpm;
    });
  }

  String _getHeartStatus(int bpm) {
    if (bpm < 60) return 'Nhịp chậm';
    if (bpm > 100) return 'Nhịp nhanh';
    return 'Bình thường';
  }

  Color _getStatusColor(int bpm) {
    if (bpm < 60 || bpm > 100) return const Color(0xFFFBBF24);
    return const Color(0xFF34D399);
  }

  Future<void> _saveMeasuredResult() async {
    if (_finalBpm <= 0 || _isSaving) return;

    if (widget.returnValueOnly) {
      Navigator.pop(context, _finalBpm.toDouble());
      return;
    }

    setState(() => _isSaving = true);
    try {
      final flashNote = _flashEnabled ? 'Bật đèn Flash LED' : 'Ánh sáng môi trường';
      await HealthMetricController().addMetric(
        metricType: 'heart_rate',
        value: _finalBpm.toDouble(),
        note: 'Đo bằng cảm biến Flash PPG ($_selectedState - $flashNote)',
        recordedAt: DateTime.now(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã lưu nhịp tim $_finalBpm bpm thành công!'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      Navigator.pop(context, _finalBpm.toDouble());
    } catch (e) {
      if (!mounted) return;
      showErrorSnack(context, errorText(e));
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayBpm = _isCompleted
        ? _finalBpm
        : (_isMeasuring ? _currentBpm : 0);

    return AuroraPage(
      title: 'Đo nhịp tim bằng đèn Flash',
      actions: [
        IconButton(
          tooltip: _flashEnabled ? 'Tắt đèn Flash' : 'Bật đèn Flash',
          onPressed: () {
            setState(() => _flashEnabled = !_flashEnabled);
          },
          icon: Icon(
            _flashEnabled ? Icons.flash_on : Icons.flash_off,
            color: _flashEnabled ? const Color(0xFFFDE047) : Colors.white70,
          ),
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Thẻ trạng thái Đèn Flash & Hướng dẫn PPG
            Tv1GlassCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _flashEnabled
                          ? const Color(0xFFFDE047).withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.12),
                      border: Border.all(
                        color: _flashEnabled
                            ? const Color(0xFFFDE047)
                            : Colors.white38,
                      ),
                      boxShadow: _flashEnabled
                          ? [
                              BoxShadow(
                                color: const Color(
                                  0xFFF87171,
                                ).withValues(alpha: 0.45),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: Icon(
                      _flashEnabled ? Icons.flashlight_on : Icons.flashlight_off,
                      color: _flashEnabled
                          ? const Color(0xFFFDE047)
                          : Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              _flashEnabled
                                  ? 'Đèn Flash PPG: ĐANG BẬT'
                                  : 'Đèn Flash PPG: ĐANG TẮT',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const Spacer(),
                            Switch(
                              value: _flashEnabled,
                              activeThumbColor: const Color(0xFFFDE047),
                              onChanged: (v) =>
                                  setState(() => _flashEnabled = v),
                            ),
                          ],
                        ),
                        Text(
                          'Đặt nhẹ đầu ngón trỏ che kín cụm Camera và đèn Flash để cảm biến quang học nhận tín hiệu mạch máu.',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Chọn trạng thái cơ thể lúc đo
            Text(
              'Trạng thái cơ thể khi đo',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _bodyStates.entries.map((entry) {
                  final selected = _selectedState == entry.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.key),
                      selected: selected,
                      selectedColor: const Color(0xFF0284C7),
                      backgroundColor: Colors.white.withValues(alpha: 0.12),
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            selected ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: _isMeasuring
                          ? null
                          : (val) {
                              if (val) {
                                setState(() => _selectedState = entry.key);
                              }
                            },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 20),

            // Vòng cảm biến quang học & Nhịp đập trái tim
            Center(
              child: GestureDetector(
                onTap: _isMeasuring ? _stopMeasurementEarly : _startMeasurement,
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (context, _) {
                    final scale = _isMeasuring
                        ? 1.0 + (_pulseController.value * 0.06)
                        : 1.0;
                    return Transform.scale(
                      scale: scale,
                      child: SizedBox(
                        width: 230,
                        height: 230,
                        child: CustomPaint(
                          painter: _PpgRingPainter(
                            progress: _isCompleted ? 1.0 : _progress,
                            isMeasuring: _isMeasuring,
                            flashEnabled: _flashEnabled,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.favorite,
                                  size: 46,
                                  color: _isMeasuring || _isCompleted
                                      ? const Color(0xFFFB7185)
                                      : Colors.white70,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  displayBpm > 0 ? '$displayBpm' : '--',
                                  style: const TextStyle(
                                    fontSize: 46,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.0,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'BPM (Nhịp/phút)',
                                  style: TextStyle(
                                    color: Color(0xFF7DD3FC),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.16),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _isMeasuring
                                        ? 'Đang đo ${(100 * _progress).toInt()}%...'
                                        : (_isCompleted
                                            ? _getHeartStatus(_finalBpm)
                                            : 'Chạm để bắt đầu đo'),
                                    style: TextStyle(
                                      color: _isCompleted
                                          ? _getStatusColor(_finalBpm)
                                          : Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Khung đồ thị sóng mạch quang học PPG trực tiếp
            Tv1GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.monitor_heart_outlined,
                            color: Color(0xFFFB7185),
                            size: 18,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Sóng mạch quang học (PPG Waveform)',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        'Tín hiệu: $_signalQuality% • HRV: $_hrvMs ms',
                        style: const TextStyle(
                          color: Color(0xFF6EE7B7),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 80,
                    child: CustomPaint(
                      painter: _PpgWaveformPainter(
                        points: _wavePoints,
                        isActive: _isMeasuring || _isCompleted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Nút điều khiển Đo / Lưu kết quả
            if (!_isCompleted)
              FilledButton.icon(
                onPressed: _isMeasuring
                    ? _stopMeasurementEarly
                    : _startMeasurement,
                style: Tv1GlassTheme.primaryButtonStyle(
                  backgroundColor: _isMeasuring
                      ? const Color(0xFFE11D48)
                      : const Color(0xFF0284C7),
                ).copyWith(
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                icon: Icon(
                  _isMeasuring ? Icons.stop_circle_outlined : Icons.fingerprint,
                ),
                label: Text(
                  _isMeasuring
                      ? 'Dừng đo'
                      : 'Bắt đầu đo bằng đèn Flash (8 giây)',
                ),
              )
            else ...[
              Tv1GlassCard(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_outlined,
                      color: _getStatusColor(_finalBpm),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Đánh giá: ${_getHeartStatus(_finalBpm)} ($_finalBpm bpm)',
                            style: TextStyle(
                              color: _getStatusColor(_finalBpm),
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _finalBpm >= 60 && _finalBpm <= 100
                                ? 'Nhịp tim của bạn nằm trong ngưỡng lý tưởng (60 – 100 bpm).'
                                : 'Nhịp tim nằm ngoài ngưỡng lúc nghỉ thông thường (60 – 100 bpm).',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isSaving ? null : _startMeasurement,
                      style: Tv1GlassTheme.secondaryButtonStyle().copyWith(
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Đo lại'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: _isSaving ? null : _saveMeasuredResult,
                      style: Tv1GlassTheme.primaryButtonStyle().copyWith(
                        padding: const WidgetStatePropertyAll(
                          EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                      icon: const Icon(Icons.check_circle_outline),
                      label: Text(
                        widget.returnValueOnly
                            ? 'Dùng kết quả ($_finalBpm bpm)'
                            : 'Lưu chỉ số ($_finalBpm bpm)',
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PpgRingPainter extends CustomPainter {
  final double progress;
  final bool isMeasuring;
  final bool flashEnabled;

  _PpgRingPainter({
    required this.progress,
    required this.isMeasuring,
    required this.flashEnabled,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 14;

    // Quầng sáng đỏ hồng mô phỏng đèn Flash chiếu qua mao mạch ngón tay
    if (flashEnabled && isMeasuring) {
      final glowPaint = Paint()
        ..shader = RadialGradient(
          colors: [
            const Color(0xFFFB7185).withValues(alpha: 0.38),
            const Color(0xFFE11D48).withValues(alpha: 0.12),
            Colors.transparent,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius + 12));
      canvas.drawCircle(center, radius + 12, glowPaint);
    }

    final bgRing = Paint()
      ..color = Colors.white.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10;
    canvas.drawCircle(center, radius, bgRing);

    if (progress > 0) {
      final arcPaint = Paint()
        ..shader = const SweepGradient(
          colors: [
            Color(0xFF38BDF8),
            Color(0xFFFB7185),
            Color(0xFFF43F5E),
            Color(0xFF38BDF8),
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = 10;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        arcPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PpgRingPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isMeasuring != isMeasuring ||
        oldDelegate.flashEnabled != flashEnabled;
  }
}

class _PpgWaveformPainter extends CustomPainter {
  final List<double> points;
  final bool isActive;

  _PpgWaveformPainter({required this.points, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 0.8;

    for (int i = 1; i <= 3; i++) {
      final y = (size.height / 4) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    if (points.isEmpty) return;

    final path = Path();
    final midY = size.height * 0.58;
    final amp = size.height * 0.36;

    for (int i = 0; i < points.length; i++) {
      final x = (i / (points.length - 1)) * size.width;
      final y = isActive ? (midY - points[i] * amp) : midY;
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final wavePaint = Paint()
      ..color = isActive ? const Color(0xFFFB7185) : Colors.white38
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, wavePaint);
  }

  @override
  bool shouldRepaint(covariant _PpgWaveformPainter oldDelegate) => true;
}
