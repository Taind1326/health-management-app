import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../models/activity.dart';
import 'package:health_app/services/calorie_calculator.dart';
import 'package:health_app/services/google_maps_service.dart';

/// Chuyển chuỗi nhập thành số km. Chấp nhận dấu phẩy thập phân ("2,5").
/// Lưu ý: double.tryParse chấp nhận cả "NaN" và "Infinity".
double? parseDistance(String? v) =>
    double.tryParse((v ?? '').trim().replaceAll(',', '.'));

/// Kiểm tra quãng đường (km). Trả về null nếu hợp lệ, ngược lại là thông báo lỗi.
/// Phải kiểm tra isFinite trước khi so sánh khoảng, vì mọi phép so sánh với NaN
/// đều trả về false nên NaN sẽ lọt qua điều kiện `d < 0 || d > 500`.
String? validateDistance(String? v) {
  final d = parseDistance(v);
  if (d == null || !d.isFinite) return 'Nhập một số hợp lệ, ví dụ 2.5';
  if (d < 0 || d > 500) return 'Nhập từ 0 đến 500';
  return null;
}

/// Tự kiểm tra [validateDistance] với các giá trị cần thử: NaN, Infinity, số âm,
/// số vượt 500 và số hợp lệ như 2,5. Chỉ chạy ở chế độ debug (gọi trong
/// initState qua assert); nếu validator bị sửa sai sẽ báo lỗi ngay khi mở màn hình.
bool _selfCheckDistanceValidator() {
  const rejected = [
    'NaN',
    'Infinity',
    '-Infinity',
    '-1',
    '500.1',
    '501',
    '',
    'abc',
  ];
  const accepted = ['2,5', '2.5', '0', '500'];

  for (final v in rejected) {
    assert(validateDistance(v) != null, 'validateDistance phải từ chối "$v"');
  }
  assert(validateDistance(null) != null, 'validateDistance phải từ chối null');
  for (final v in accepted) {
    assert(validateDistance(v) == null, 'validateDistance phải chấp nhận "$v"');
  }
  return true;
}

/// Form ghi nhận một hoạt động. Trả về [Activity] qua Navigator.pop khi lưu.
class AddActivityScreen extends StatefulWidget {
  const AddActivityScreen({super.key});

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _stepsCtrl = TextEditingController(text: '0');
  final _distanceCtrl = TextEditingController(text: '0');
  final _durationCtrl = TextEditingController();
  final _caloriesCtrl = TextEditingController(text: '0');
  final _originCtrl = TextEditingController();
  final _destinationCtrl = TextEditingController();

  final GoogleMapsService _mapsService = GoogleMapsService();

  /// Thời gian chờ sau lần gõ cuối trước khi tự tính tuyến (tránh gọi API
  /// sau mỗi ký tự).
  static const Duration _autoCalcDelay = Duration(milliseconds: 900);

  /// Giả định khi chạy bộ: tốc độ trung bình (km/h) và độ dài mỗi bước (m).
  /// Thời gian và số bước khi chạy được suy ra từ quãng đường theo hai số này.
  static const double _runningSpeedKmh = 10.0;
  static const double _runningStepLengthMeters = 1.0;

  Timer? _debounce;
  int _routeRequestId = 0; // bỏ qua kết quả của lần tính đã bị thay thế

  bool _calculatingRoute = false;
  bool _routeCalculated = false;
  String? _routeError;
  WalkingRoute? _route;

  String _type = Activity.types.first;
  DateTime _date = DateTime.now();

  @override
  void initState() {
    super.initState();
    assert(_selfCheckDistanceValidator());
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _stepsCtrl.dispose();
    _distanceCtrl.dispose();
    _durationCtrl.dispose();
    _caloriesCtrl.dispose();
    _originCtrl.dispose();
    _destinationCtrl.dispose();
    _mapsService.dispose();
    super.dispose();
  }

  /// Loại hoạt động tính tự động từ tuyến đường (chọn điểm đi/đến).
  bool get _isRouteType =>
      _type == 'Đi bộ' || _type == 'Chạy bộ' || _type == 'Đạp xe';

  /// Đạp xe không có số bước: ẩn ô này, lưu 0.
  bool get _showSteps => _type != 'Đạp xe';

  /// Đi bộ và chạy bộ dùng chung đường đi; đạp xe dùng profile riêng.
  String get _routeProfile =>
      _type == 'Đạp xe' ? 'cycling-regular' : 'foot-walking';

  String get _routeVerb => switch (_type) {
        'Chạy bộ' => 'chạy bộ',
        'Đạp xe' => 'đạp xe',
        _ => 'đi bộ',
      };

  /// Số bước, thời gian và calo của [route] theo loại hoạt động hiện tại.
  ({int steps, int minutes, int kcal}) _estimate(
    WalkingRoute route,
    double weightKg,
  ) {
    if (_type == 'Chạy bộ') {
      final minutes =
          math.max(1, (route.distanceKm / _runningSpeedKmh * 60).ceil());
      return (
        steps: (route.distanceMeters / _runningStepLengthMeters).round(),
        minutes: minutes,
        kcal: CalorieCalculator.runningKcal(
          weightKg: weightKg,
          distanceKm: route.distanceKm,
          durationMinutes: minutes,
        ),
      );
    }
    if (_type == 'Đạp xe') {
      return (
        steps: 0,
        minutes: route.durationMinutes,
        kcal: CalorieCalculator.cyclingKcal(
          weightKg: weightKg,
          distanceKm: route.distanceKm,
          durationMinutes: route.durationMinutes,
        ),
      );
    }
    return (
      steps: route.estimatedSteps,
      minutes: route.durationMinutes,
      kcal: CalorieCalculator.walkingKcal(
        weightKg: weightKg,
        distanceKm: route.distanceKm,
        durationMinutes: route.durationMinutes,
      ),
    );
  }

  /// Điền các ô từ [route] (gọi bên trong setState).
  void _fillFromRoute(WalkingRoute route, double weightKg) {
    final e = _estimate(route, weightKg);
    _route = route;
    _distanceCtrl.text = route.distanceKm.toStringAsFixed(3);
    _stepsCtrl.text = '${e.steps}';
    _durationCtrl.text = '${e.minutes}';
    _caloriesCtrl.text = '${e.kcal}';
    _routeCalculated = true;
    _calculatingRoute = false;
  }

  String _dmy(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 1),
      lastDate: now,
    );
    if (!mounted || picked == null) return;
    setState(() {
      _date = DateTime(
          picked.year, picked.month, picked.day, _date.hour, _date.minute);
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_date),
    );
    if (!mounted || picked == null) return;
    setState(() {
      _date = DateTime(
          _date.year, _date.month, _date.day, picked.hour, picked.minute);
    });
  }

  String? _intValidator(String? v, {required int min, required int max}) {
    final n = int.tryParse(v?.trim() ?? '');
    if (n == null) return 'Nhập một số nguyên';
    if (n < min || n > max) return 'Nhập từ $min đến $max';
    return null;
  }

  void _save() {
    if (_isRouteType && !_routeCalculated) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hãy nhập điểm xuất phát và điểm đến hợp lệ để tự tính.'),
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    if (_date.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thời gian không được ở tương lai')),
      );
      return;
    }
    Navigator.pop(
      context,
      Activity(
        userId: 1, // đợt 2: lấy từ người dùng đang đăng nhập (TV1)
        type: _type,
        date: _date,
        steps: int.parse(_stepsCtrl.text.trim()),
        distanceKm: parseDistance(_distanceCtrl.text)!,
        durationMinutes: int.parse(_durationCtrl.text.trim()),
        calories: int.parse(_caloriesCtrl.text.trim()),
        origin: _isRouteType ? _originCtrl.text.trim() : null,
        destination:
          _isRouteType ? _destinationCtrl.text.trim() : null,
      ),
    );
  }

  /// Xóa kết quả tính tự động và huỷ mọi lần tính đang chờ/đang chạy.
  void _resetRouteResult() {
    _debounce?.cancel();
    _routeRequestId++; // kết quả của request cũ (nếu về muộn) sẽ bị bỏ
    _calculatingRoute = false;
    _routeCalculated = false;
    _routeError = null;
    _route = null;
    _stepsCtrl.text = '0';
    _distanceCtrl.text = '0';
    _durationCtrl.clear();
    _caloriesCtrl.text = '0';
  }

  /// Người dùng sửa điểm đi/đến: bỏ kết quả cũ, rồi tự tính lại khi đã có đủ
  /// cả hai điểm và người dùng ngừng gõ.
  void _onPlaceChanged() {
    setState(_resetRouteResult);

    if (_originCtrl.text.trim().isEmpty ||
        _destinationCtrl.text.trim().isEmpty) {
      return;
    }
    _debounce = Timer(_autoCalcDelay, _calculateRoute);
  }

  /// Tính ngay (khi bấm Done trên bàn phím hoặc bấm "Thử lại").
  void _calculateNow() {
    _debounce?.cancel();
    _calculateRoute();
  }

  Future<void> _calculateRoute() async {
    final origin = _originCtrl.text.trim();
    final destination = _destinationCtrl.text.trim();
    if (origin.isEmpty || destination.isEmpty) return;

    final weightKg = CalorieCalculator.currentWeightKg();
    if (weightKg == null) {
      setState(() {
        _routeError = 'Chưa có cân nặng để tính calo. '
            'Hãy cập nhật cân nặng trong hồ sơ hoặc chỉ số sức khỏe.';
      });
      return;
    }

    final requestId = ++_routeRequestId;
    setState(() {
      _calculatingRoute = true;
      _routeError = null;
    });

    try {
      final route = _type == 'Đạp xe'
          ? await _mapsService.calculateCyclingRoute(
              origin: origin,
              destination: destination,
            )
          : await _mapsService.calculateWalkingRoute(
              origin: origin,
              destination: destination,
            );

      // Đã đổi điểm đi/đến hoặc đổi loại hoạt động trong lúc chờ.
      if (!mounted || requestId != _routeRequestId) return;

      setState(() => _fillFromRoute(route, weightKg));
    } on RouteException catch (e) {
      if (!mounted || requestId != _routeRequestId) return;
      setState(() {
        _routeError = e.message;
        _calculatingRoute = false;
      });
    } catch (e) {
      if (!mounted || requestId != _routeRequestId) return;
      setState(() {
        _routeError = 'Không tính được tuyến đường: $e';
        _calculatingRoute = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Thêm hoạt động')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Loại hoạt động'),
              items: Activity.types
                  .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                  .toList(),
              onChanged: (value) {
                if (value == null) return;

                final keepRoute = _isRouteType &&
                    (value == 'Đi bộ' || value == 'Chạy bộ' || value == 'Đạp xe');
                final oldRoute = _route;
                final oldProfile = _routeProfile;

                setState(() {
                  _type = value;
                  _resetRouteResult();
                  if (!keepRoute) {
                    // Sang loại không dùng tuyến: dọn luôn ô điểm đi/đến.
                    _originCtrl.clear();
                    _destinationCtrl.clear();
                  }
                });

                if (!keepRoute) return;
                // Giữ nguyên điểm đi/đến. Cùng loại đường (đi bộ <-> chạy bộ)
                // thì chỉ tính lại số liệu; khác loại (đạp xe) thì tính tuyến mới.
                final weightKg = CalorieCalculator.currentWeightKg();
                if (oldRoute != null &&
                    oldProfile == _routeProfile &&
                    weightKg != null) {
                  setState(() => _fillFromRoute(oldRoute, weightKg));
                } else if (_originCtrl.text.trim().isNotEmpty &&
                    _destinationCtrl.text.trim().isNotEmpty) {
                  _calculateNow();
                }
              },
            ),
            if (_isRouteType) ...[
              const SizedBox(height: 16),
              Text(
                _showSteps
                    ? 'Tuyến $_routeVerb (số bước, quãng đường, thời gian và calo tự tính)'
                    : 'Tuyến $_routeVerb (quãng đường, thời gian và calo tự tính)',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _originCtrl,
                textInputAction: TextInputAction.next,
                onChanged: (_) => _onPlaceChanged(),
                decoration: const InputDecoration(
                  labelText: 'Điểm xuất phát',
                  hintText: 'Ví dụ: Nhà thờ Đức Bà, TP.HCM',
                  prefixIcon: Icon(Icons.trip_origin),
                ),
                validator: (value) {
                  if (_isRouteType &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Vui lòng nhập điểm xuất phát';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _destinationCtrl,
                textInputAction: TextInputAction.done,
                onChanged: (_) => _onPlaceChanged(),
                onFieldSubmitted: (_) => _calculateNow(),
                decoration: const InputDecoration(
                  labelText: 'Điểm đến',
                  hintText: 'Ví dụ: Công viên Tao Đàn, TP.HCM',
                  prefixIcon: Icon(Icons.location_on_outlined),
                ),
                validator: (value) {
                  if (_isRouteType &&
                      (value == null || value.trim().isEmpty)) {
                    return 'Vui lòng nhập điểm đến';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 12),

              if (_calculatingRoute)
                const Row(
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Expanded(child: Text('Đang tính tuyến đường...')),
                  ],
                )
              else if (_routeError != null) ...[
                Text(
                  _routeError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _calculateNow,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Thử lại'),
                  ),
                ),
              ] else if (!_routeCalculated)
                const Text(
                  'Nhập điểm xuất phát và điểm đến, ứng dụng sẽ tự tính.',
                ),

              if (_route != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Từ: ${_route!.origin.label}'),
                        const SizedBox(height: 4),
                        Text('Đến: ${_route!.destination.label}'),
                        const SizedBox(height: 8),
                        Text(
                          '${_route!.distanceKm.toStringAsFixed(2)} km · '
                          '${_showSteps ? '~${_stepsCtrl.text} bước · ' : ''}'
                          '~${_durationCtrl.text} phút · '
                          '~${_caloriesCtrl.text} kcal',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Nếu địa điểm hiển thị sai, hãy nhập rõ hơn '
                          '(kèm quận/thành phố), ứng dụng sẽ tự tính lại.',
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 8),

              Text(
                _type == 'Đạp xe'
                    ? 'Quãng đường và thời gian lấy từ tuyến đường đạp xe; '
                        'calo được ước lượng theo tốc độ trung bình của tuyến '
                        'và cân nặng trong hồ sơ, không phải số đo thực tế.'
                    : _type == 'Chạy bộ'
                    ? 'Quãng đường lấy từ tuyến đường; thời gian, số bước và calo '
                        'được ước lượng với tốc độ chạy giả định '
                        '${_runningSpeedKmh.toStringAsFixed(0)} km/h và cân nặng '
                        'trong hồ sơ, không phải số đo thực tế.'
                    : 'Số bước và calo được ước lượng từ tuyến đi bộ và cân nặng '
                        'trong hồ sơ, không phải số đo thực tế.',
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today),
                    label: Text(_dmy(_date)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.access_time),
                    label: Text(
                      '${_date.hour.toString().padLeft(2, '0')}:${_date.minute.toString().padLeft(2, '0')}',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              readOnly: _isRouteType,
              controller: _durationCtrl,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Thời gian vận động (phút)'),
              validator: (v) => _intValidator(v, min: 1, max: 1440),
            ),
            if (_showSteps) ...[
              const SizedBox(height: 12),
              TextFormField(
                readOnly: _isRouteType,
                controller: _stepsCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Số bước'),
                validator: (v) => _intValidator(v, min: 0, max: 100000),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              readOnly: _isRouteType,
              controller: _distanceCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Quãng đường (km)'),
              validator: validateDistance,
            ),
            const SizedBox(height: 12),
            TextFormField(
              readOnly: _isRouteType,
              controller: _caloriesCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Calo tiêu hao (kcal)'),
              validator: (v) => _intValidator(v, min: 0, max: 10000),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: _save, child: const Text('Lưu hoạt động')),
          ],
        ),
      ),
    );
  }
}