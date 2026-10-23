import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;

/// Lỗi có thông báo tiếng Việt, hiển thị thẳng cho người dùng.
class RouteException implements Exception {
  final String message;
  const RouteException(this.message);

  @override
  String toString() => message;
}

/// Một địa điểm đã được tìm thấy trên bản đồ.
class Place {
  final String name;
  final String formatted; // phần địa chỉ đi kèm tên
  final double longitude;
  final double latitude;

  const Place({
    required this.name,
    required this.formatted,
    required this.longitude,
    required this.latitude,
  });

  /// Tên đầy đủ để hiển thị cho người dùng kiểm tra.
  String get label => formatted.isEmpty ? name : '$name, $formatted';
}

class WalkingRoute {
  /// Độ dài một bước chân trung bình (m). Số bước chỉ là ước lượng.
  static const double stepLengthMeters = 0.75;

  final Place origin;
  final Place destination;
  final int distanceMeters;
  final int durationSeconds;

  const WalkingRoute({
    required this.origin,
    required this.destination,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  double get distanceKm => distanceMeters / 1000;
  int get estimatedSteps => (distanceMeters / stepLengthMeters).round();

  /// Ít nhất 1 phút để qua được bước kiểm tra của form.
  int get durationMinutes => math.max(1, (durationSeconds / 60).ceil());
}

/// Tìm địa điểm (ORS Geocode/Pelias) và tính tuyến đi bộ (ORS Directions,
/// profile foot-walking) bằng OpenRouteService của HeiGIT. Miễn phí.
///
/// Token truyền khi chạy app, KHÔNG ghi cứng vào code:
///   flutter run --dart-define=ORS_API_KEY=xxxx
///
/// Giữ tên class [GoogleMapsService] để không phải sửa chỗ import.
class GoogleMapsService {
  static const String _apiKey = String.fromEnvironment('ORS_API_KEY');

  static const String _host = 'api.openrouteservice.org';

  /// Đi bộ quá xa thường là do tìm nhầm địa điểm (trùng tên ở tỉnh khác).
  static const double _maxWalkingKm = 50;

  /// Giới hạn tương tự cho đạp xe.
  static const double _maxCyclingKm = 150;

  static const Duration _timeout = Duration(seconds: 15);

  /// Khu vực ưu tiên khi tìm điểm xuất phát (TP.HCM). Chỉ là "ưu tiên",
  /// không giới hạn: gõ địa điểm ở nơi khác vẫn tìm được. Đổi theo nhu cầu.
  static const double _biasLat = 10.7769;
  static const double _biasLng = 106.7009;

  final http.Client _client;

  GoogleMapsService({http.Client? client})
      : _client = client ?? http.Client();

  /// Gửi request, đổi mọi lỗi mạng/HTTP thành [RouteException] dễ hiểu.
  Future<Map<String, dynamic>> _send(
    Future<http.Response> Function() request,
  ) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on TimeoutException {
      throw const RouteException(
        'Hết thời gian chờ bản đồ. Kiểm tra mạng rồi thử lại.',
      );
    } on http.ClientException {
      throw const RouteException(
        'Không kết nối được tới bản đồ. Kiểm tra mạng rồi thử lại.',
      );
    }

    Map<String, dynamic>? json;
    try {
      // Giải mã UTF-8 thủ công để tiếng Việt không bị lỗi font.
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) json = decoded;
    } catch (_) {
      // Body không phải JSON: xử lý theo status code bên dưới.
    }

    if (response.statusCode == 200 && json != null) return json;

    // ORS trả lỗi dạng {"error": {"code": 2010, "message": "..."}}
    // hoặc {"error": "..."}.
    final err = json?['error'];
    final apiMessage =
        err is Map ? err['message'] as String? : (err is String ? err : null);
    final apiCode = err is Map ? err['code'] : null;

    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const RouteException(
        'ORS_API_KEY không hợp lệ hoặc đã bị chặn. Kiểm tra lại token.',
      );
    }
    if (response.statusCode == 429) {
      throw const RouteException(
        'Hết lượt gọi bản đồ (giới hạn theo phút/ngày). Thử lại sau.',
      );
    }
    // Mã 2010: không gắn được điểm vào đường đi bộ nào gần đó.
    if (apiCode == 2010) {
      throw const RouteException(
        'Điểm nhập không nằm gần đường phù hợp nào (bán kính 350 m). '
        'Hãy nhập địa điểm gần đường lớn hơn.',
      );
    }
    // Mã 2004: quá xa so với giới hạn của ORS.
    if (apiCode == 2004) {
      throw const RouteException('Quãng đường quá xa để tính tuyến.');
    }
    throw RouteException(
      'Bản đồ báo lỗi: ${apiMessage ?? 'mã ${response.statusCode}'}',
    );
  }

  /// Tìm địa điểm theo tên/địa chỉ. [near] ưu tiên kết quả gần điểm đó
  /// (điểm đến gần điểm xuất phát, tránh nhảy sang thành phố khác).
  Future<Place> findPlace(String query, {Place? near}) async {
    final q = query.trim();
    if (q.isEmpty) {
      throw const RouteException('Vui lòng nhập địa điểm.');
    }

    final uri = Uri.https(_host, '/geocode/search', {
      'api_key': _apiKey,
      'text': q,
      'boundary.country': 'VN',
      'focus.point.lat': '${near?.latitude ?? _biasLat}',
      'focus.point.lon': '${near?.longitude ?? _biasLng}',
      'size': '1',
    });

    final data = await _send(() => _client.get(uri));
    final features = data['features'];

    if (features is! List || features.isEmpty) {
      throw RouteException(
        'Không tìm thấy "$q". Hãy nhập rõ hơn, kèm quận/thành phố '
        '(ví dụ: "Công viên Tao Đàn, Quận 1, TP.HCM").',
      );
    }

    final feature = features.first as Map<String, dynamic>;
    final props = (feature['properties'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final geometry = feature['geometry'] as Map<String, dynamic>;
    final c = geometry['coordinates'] as List<dynamic>;

    final name = (props['name'] as String?)?.trim();
    final label = (props['label'] as String?)?.trim() ?? '';

    // "label" của ORS có dạng "Tên, Phường, Quận, Thành phố, Việt Nam":
    // bỏ phần tên ở đầu để không bị lặp.
    var formatted = label;
    if (name != null && name.isNotEmpty && label.startsWith('$name, ')) {
      formatted = label.substring(name.length + 2);
    } else if (name != null && label == name) {
      formatted = '';
    }

    return Place(
      name: (name != null && name.isNotEmpty) ? name : q,
      formatted: formatted,
      // ORS/GeoJSON trả về [kinh độ, vĩ độ].
      longitude: (c[0] as num).toDouble(),
      latitude: (c[1] as num).toDouble(),
    );
  }

  /// Khoảng cách đường chim bay (m) giữa hai điểm.
  static double _straightLineMeters(Place a, Place b) {
    const r = 6371000.0;
    double rad(double d) => d * math.pi / 180;
    final dLat = rad(b.latitude - a.latitude);
    final dLng = rad(b.longitude - a.longitude);
    final h = math.pow(math.sin(dLat / 2), 2) +
        math.cos(rad(a.latitude)) *
            math.cos(rad(b.latitude)) *
            math.pow(math.sin(dLng / 2), 2);
    return 2 * r * math.asin(math.min(1.0, math.sqrt(h)));
  }

  /// Tuyến đi bộ (cũng dùng cho chạy bộ vì cùng đường đi).
  Future<WalkingRoute> calculateWalkingRoute({
    required String origin,
    required String destination,
  }) =>
      calculateRoute(origin: origin, destination: destination);

  /// Tuyến đạp xe (ORS profile cycling-regular): đi theo đường cho xe đạp.
  Future<WalkingRoute> calculateCyclingRoute({
    required String origin,
    required String destination,
  }) =>
      calculateRoute(
        origin: origin,
        destination: destination,
        profile: 'cycling-regular',
        maxKm: _maxCyclingKm,
      );

  /// [profile] là profile của ORS Directions (foot-walking, cycling-regular...).
  Future<WalkingRoute> calculateRoute({
    required String origin,
    required String destination,
    String profile = 'foot-walking',
    double maxKm = _maxWalkingKm,
  }) async {
    if (_apiKey.isEmpty) {
      throw const RouteException(
        'Chưa cấu hình ORS_API_KEY '
        '(chạy app với --dart-define=ORS_API_KEY=...).',
      );
    }
    if (origin.trim().isEmpty || destination.trim().isEmpty) {
      throw const RouteException('Vui lòng nhập điểm xuất phát và điểm đến.');
    }

    final start = await findPlace(origin);
    final end = await findPlace(destination, near: start);

    final straight = _straightLineMeters(start, end);
    if (straight < 5) {
      throw RouteException(
        'Điểm đi và điểm đến trùng nhau (${start.label}).',
      );
    }
    if (straight / 1000 > maxKm) {
      throw RouteException(
        'Hai địa điểm cách nhau ${(straight / 1000).toStringAsFixed(0)} km, '
        'quá xa để tính tuyến. Có thể tìm nhầm địa điểm:\n'
        '• ${start.label}\n• ${end.label}',
      );
    }

    final uri = Uri.https(_host, '/v2/directions/$profile');
    final data = await _send(
      () => _client.post(
        uri,
        headers: {
          'Authorization': _apiKey,
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          // ORS dùng thứ tự [kinh độ, vĩ độ].
          'coordinates': [
            [start.longitude, start.latitude],
            [end.longitude, end.latitude],
          ],
          'units': 'm',
          'language': 'vi',
          'instructions': false,
        }),
      ),
    );

    final routes = data['routes'];
    if (routes is! List || routes.isEmpty) {
      throw RouteException(
        'Không có đường đi giữa:\n• ${start.label}\n• ${end.label}\n'
        'Thử nhập địa điểm gần đường lớn hơn hoặc ghi rõ địa chỉ.',
      );
    }

    final summary =
        (routes.first as Map<String, dynamic>)['summary'] as Map<String, dynamic>;
    final distance = (summary['distance'] as num?)?.round() ?? 0;
    final duration = (summary['duration'] as num?)?.round() ?? 0;

    if (distance <= 0) {
      throw const RouteException('Quãng đường trả về không hợp lệ.');
    }

    return WalkingRoute(
      origin: start,
      destination: end,
      distanceMeters: distance,
      durationSeconds: duration,
    );
  }

  void dispose() {
    _client.close();
  }
}