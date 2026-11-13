import 'package:flutter/material.dart';
import '../../controllers/health_metric_controller.dart';
import '../../models/health_metric.dart';
import '../../services/auth_service.dart';
import '../../widgets/aurora_page.dart';
import '../../widgets/tv1_glass_widgets.dart';
import 'heart_rate_measure_screen.dart';

/// Màn hình Thêm mới hoặc Chỉnh sửa bản ghi chỉ số sức khỏe (TV2 - Đợt 2).
/// Đồng bộ thiết kế Glassmorphism Aurora Borealis, kết nối [HealthMetricController]
/// và SQLite, tích hợp đo nhịp tim bằng đèn Flash (PPG) & tự động tính BMI.
class AddMetricScreen extends StatefulWidget {
  final HealthMetric? initialMetric;
  final String? initialType;

  const AddMetricScreen({
    super.key,
    this.initialMetric,
    this.initialType,
  });

  bool get isEditing => initialMetric != null;

  @override
  State<AddMetricScreen> createState() => _AddMetricScreenState();
}

class _AddMetricScreenState extends State<AddMetricScreen> {
  final _formKey = GlobalKey<FormState>();
  final HealthMetricController _controller = HealthMetricController();

  late String _selectedType;
  late DateTime _selectedDate;
  bool _isSubmitting = false;

  static const Map<String, String> _metricTypeLabels = {
    'blood_pressure': 'Huyết áp',
    'heart_rate': 'Nhịp tim',
    'weight': 'Cân nặng',
    'bmi': 'BMI',
  };

  final _sysController = TextEditingController();
  final _diaController = TextEditingController();
  final _valueController = TextEditingController();
  final _noteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final initial = widget.initialMetric;
    if (initial != null) {
      _selectedType = initial.metricType;
      _selectedDate = initial.recordedAt;
      if (initial.metricType == 'blood_pressure') {
        _sysController.text = _formatInputValue(initial.value);
        if (initial.value2 != null) {
          _diaController.text = _formatInputValue(initial.value2!);
        }
      } else {
        _valueController.text = _formatInputValue(initial.value);
      }
      _noteController.text = initial.note ?? '';
    } else {
      _selectedType = widget.initialType ?? 'blood_pressure';
      _selectedDate = DateTime.now();
    }
  }

  String _formatInputValue(double v) {
    if (v == v.roundToDouble()) {
      return v.toInt().toString();
    }
    return v.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _sysController.dispose();
    _diaController.dispose();
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _selectDateTime() async {
    final now = DateTime.now();
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: _selectedDate.isAfter(now) ? now : _selectedDate,
      firstDate: DateTime(2000),
      lastDate: now,
      builder: auroraPickerBuilder,
    );
    if (date != null && mounted) {
      final TimeOfDay? time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
        builder: auroraPickerBuilder,
      );
      if (time != null && mounted) {
        final pickedDateTime = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );

        final dateError =
            HealthMetricController.validateRecordedAt(pickedDateTime);
        if (dateError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(dateError),
              backgroundColor: Colors.orange,
            ),
          );
          return;
        }

        setState(() {
          _selectedDate = pickedDateTime;
        });
      }
    }
  }

  Future<void> _openFlashHeartRateScanner() async {
    final measuredBpm = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => const HeartRateMeasureScreen(returnValueOnly: true),
      ),
    );
    if (measuredBpm != null && mounted) {
      setState(() {
        _valueController.text = measuredBpm.toString();
        if (_noteController.text.trim().isEmpty) {
          _noteController.text = 'Đo bằng cảm biến đèn Flash PPG';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã điền kết quả đo Flash PPG: $measuredBpm bpm'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
    }
  }

  Future<void> _autoCalculateBmi() async {
    final suggestion = _controller.suggestBmi();
    if (suggestion.bmi != null) {
      final bmiVal = suggestion.bmi!;
      setState(() {
        _valueController.text = bmiVal.toStringAsFixed(1);
        if (_noteController.text.trim().isEmpty) {
          _noteController.text =
              'Tự động tính từ chiều cao hồ sơ & cân nặng gần nhất';
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text('Đã tự động tính BMI: ${bmiVal.toStringAsFixed(1)} kg/m²'),
          backgroundColor: const Color(0xFF059669),
        ),
      );
      return;
    }

    final heightCtrl = TextEditingController(
      text: suggestion.heightCm != null
          ? _formatInputValue(suggestion.heightCm!)
          : '170',
    );
    final weightCtrl = TextEditingController(
      text: suggestion.weightKg != null
          ? _formatInputValue(suggestion.weightKg!)
          : '65',
    );

    final calculated = await showAuroraDialog<double>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Tính nhanh chỉ số BMI'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: heightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: Tv1GlassTheme.inputDecoration(
                  labelText: 'Chiều cao (cm)',
                  hintText: 'VD: 170',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weightCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(color: Colors.white),
                decoration: Tv1GlassTheme.inputDecoration(
                  labelText: 'Cân nặng (kg)',
                  hintText: 'VD: 65',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                final h = HealthMetricController.parseNumber(heightCtrl.text);
                final w = HealthMetricController.parseNumber(weightCtrl.text);
                if (h == null ||
                    w == null ||
                    h < 50 ||
                    h > 250 ||
                    w < 2 ||
                    w > 300) {
                  return;
                }
                final bmi = AuthService.calculateBmi(h, w);
                Navigator.pop(dialogContext, bmi);
              },
              child: const Text('Áp dụng'),
            ),
          ],
        );
      },
    );

    heightCtrl.dispose();
    weightCtrl.dispose();

    if (calculated != null && mounted) {
      setState(() {
        _valueController.text = calculated.toStringAsFixed(1);
      });
    }
  }

  Future<void> _saveForm() async {
    if (_isSubmitting) return;

    final dateErr = HealthMetricController.validateRecordedAt(_selectedDate);
    if (dateErr != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(dateErr),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    double primaryValue = 0;
    double? secondaryValue;

    if (_selectedType == 'blood_pressure') {
      primaryValue = HealthMetricController.parseNumber(_sysController.text)!;
      secondaryValue = HealthMetricController.parseNumber(_diaController.text)!;
    } else {
      primaryValue = HealthMetricController.parseNumber(_valueController.text)!;
    }

    setState(() => _isSubmitting = true);

    try {
      HealthMetric saved;
      if (widget.isEditing) {
        saved = await _controller.updateMetric(
          existing: widget.initialMetric!,
          metricType: _selectedType,
          value: primaryValue,
          value2: _selectedType == 'blood_pressure' ? secondaryValue : null,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          recordedAt: _selectedDate,
        );
      } else {
        saved = await _controller.addMetric(
          metricType: _selectedType,
          value: primaryValue,
          value2: secondaryValue,
          note: _noteController.text.trim().isEmpty
              ? null
              : _noteController.text.trim(),
          recordedAt: _selectedDate,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            widget.isEditing
                ? 'Đã cập nhật chỉ số thành công!'
                : 'Đã lưu chỉ số thành công!',
          ),
          backgroundColor: const Color(0xFF059669),
        ),
      );

      Navigator.pop(context, widget.isEditing ? saved : true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'Không thể lưu chỉ số sức khỏe: $e',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  Widget _buildTypeSelector() {
    return DropdownButtonFormField<String>(
      decoration: Tv1GlassTheme.inputDecoration(
        labelText: 'Loại chỉ số',
        prefixIcon:
            const Icon(Icons.category_outlined, color: Color(0xFF7DD3FC)),
      ),
      dropdownColor: const Color(0xFF1E1B4B),
      style: const TextStyle(color: Colors.white, fontSize: 15),
      initialValue: _selectedType,
      items: _metricTypeLabels.entries.map((entry) {
        return DropdownMenuItem(
          value: entry.key,
          child: Text(entry.value, style: const TextStyle(color: Colors.white)),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null && value != _selectedType) {
          setState(() {
            _selectedType = value;
            _sysController.clear();
            _diaController.clear();
            _valueController.clear();
          });
        }
      },
    );
  }

  Widget _buildSmartAssistantBar() {
    if (_selectedType == 'heart_rate') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: OutlinedButton.icon(
          onPressed: _openFlashHeartRateScanner,
          icon: const Icon(Icons.flashlight_on, color: Color(0xFFFDE047)),
          label: const Text('Đo bằng đèn Flash Camera (PPG)'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFFFDE047), width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
    if (_selectedType == 'bmi') {
      return Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: OutlinedButton.icon(
          onPressed: _autoCalculateBmi,
          icon: const Icon(Icons.auto_fix_high, color: Color(0xFF6EE7B7)),
          label: const Text('Tự động tính BMI từ Chiều cao & Cân nặng'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.white,
            side: const BorderSide(color: Color(0xFF6EE7B7), width: 1.2),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildInputFields() {
    if (_selectedType == 'blood_pressure') {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TextFormField(
              controller: _sysController,
              style: const TextStyle(color: Colors.white),
              decoration: Tv1GlassTheme.inputDecoration(
                labelText: 'Tâm thu (mmHg)',
                hintText: 'VD: 120',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (value) => HealthMetricController.validatePrimaryValue(
                'blood_pressure',
                value,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _diaController,
              style: const TextStyle(color: Colors.white),
              decoration: Tv1GlassTheme.inputDecoration(
                labelText: 'Tâm trương (mmHg)',
                hintText: 'VD: 80',
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              validator: (value) =>
                  HealthMetricController.validateSecondaryValue(
                'blood_pressure',
                value,
                primaryRaw: _sysController.text,
              ),
            ),
          ),
        ],
      );
    }

    String label = '';
    String hint = '';
    switch (_selectedType) {
      case 'heart_rate':
        label = 'Nhịp tim (bpm)';
        hint = 'VD: 75';
        break;
      case 'weight':
        label = 'Cân nặng (kg)';
        hint = 'VD: 65.5 hoặc 65,5';
        break;
      case 'bmi':
        label = 'BMI (kg/m²)';
        hint = 'VD: 22.4';
        break;
    }

    return TextFormField(
      controller: _valueController,
      style: const TextStyle(color: Colors.white),
      decoration: Tv1GlassTheme.inputDecoration(
        labelText: label,
        hintText: hint,
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      validator: (value) => HealthMetricController.validatePrimaryValue(
        _selectedType,
        value,
      ),
    );
  }

  HealthMetric? _buildPreviewMetric() {
    final now = DateTime.now();
    if (_selectedType == 'blood_pressure') {
      final sys = HealthMetricController.parseNumber(_sysController.text);
      final dia = HealthMetricController.parseNumber(_diaController.text);
      if (sys == null ||
          dia == null ||
          sys < 60 ||
          sys > 250 ||
          dia < 40 ||
          dia > 150 ||
          sys <= dia) {
        return null;
      }
      return HealthMetric(
        userId: 1,
        metricType: 'blood_pressure',
        value: sys,
        value2: dia,
        unit: 'mmHg',
        recordedAt: _selectedDate,
        createdAt: now,
        updatedAt: now,
      );
    } else {
      final v = HealthMetricController.parseNumber(_valueController.text);
      if (v == null) return null;
      if (HealthMetricController.validatePrimaryValue(
            _selectedType,
            _valueController.text,
          ) !=
          null) {
        return null;
      }
      return HealthMetric(
        userId: 1,
        metricType: _selectedType,
        value: v,
        unit: HealthMetric.unitForType(_selectedType),
        recordedAt: _selectedDate,
        createdAt: now,
        updatedAt: now,
      );
    }
  }

  Widget _buildLiveAssessmentPreview() {
    final preview = _buildPreviewMetric();
    if (preview == null) return const SizedBox.shrink();

    final Color badgeColor;
    switch (preview.statusSeverity) {
      case 'normal':
        badgeColor = const Color(0xFF34D399);
        break;
      case 'warning':
        badgeColor = const Color(0xFFFBBF24);
        break;
      default:
        badgeColor = const Color(0xFFFB7185);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: badgeColor.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: badgeColor.withValues(alpha: 0.45)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.health_and_safety, color: badgeColor, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Đánh giá sơ bộ: ${preview.statusLabel}',
                    style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    preview.statusAdvice,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.88),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuroraPage(
      title: widget.isEditing ? 'Chỉnh sửa chỉ số' : 'Thêm chỉ số',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Tv1GlassCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTypeSelector(),
                    const SizedBox(height: 18),
                    _buildSmartAssistantBar(),
                    _buildInputFields(),
                    _buildLiveAssessmentPreview(),
                    const SizedBox(height: 18),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: ListTile(
                        title: const Text(
                          'Thời gian',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                        subtitle: Text(
                          _formatDateTime(_selectedDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        trailing: const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF7DD3FC),
                        ),
                        onTap: _selectDateTime,
                      ),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: _noteController,
                      style: const TextStyle(color: Colors.white),
                      decoration: Tv1GlassTheme.inputDecoration(
                        labelText: 'Ghi chú (tùy chọn)',
                        hintText: 'VD: Đo buổi sáng sau khi nghỉ 5 phút',
                      ),
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isSubmitting ? null : _saveForm,
                style: Tv1GlassTheme.primaryButtonStyle().copyWith(
                  padding: const WidgetStatePropertyAll(
                    EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
                child: Text(
                  widget.isEditing ? 'Cập nhật' : 'Lưu',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
