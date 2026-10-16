import 'package:flutter/foundation.dart';
import '../models/health_metric.dart';

/// In-memory repository for Health Metrics during Phase 1 prototype.
/// Provides a shared data source across Overview, History, Detail, and Chart screens.
/// Extends [ChangeNotifier] so UI screens update immediately on add/delete.
class HealthMetricRepository extends ChangeNotifier {
  static final HealthMetricRepository _instance =
      HealthMetricRepository._internal();

  factory HealthMetricRepository() => _instance;

  HealthMetricRepository._internal() {
    _metrics = HealthMetric.sampleData();
  }

  late List<HealthMetric> _metrics;

  /// Returns a copy of all health metrics sorted by recordedAt descending.
  List<HealthMetric> getAll() {
    final list = List<HealthMetric>.from(_metrics);
    list.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return list;
  }

  /// Returns the latest metric for the given type, or null if none.
  HealthMetric? getLatest(String type) {
    final filtered = _metrics.where((m) => m.metricType == type).toList();
    if (filtered.isEmpty) return null;
    filtered.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return filtered.first;
  }

  /// Adds a new health metric and notifies all listening screens.
  void add(HealthMetric metric) {
    _metrics.add(metric);
    notifyListeners();
  }

  /// Deletes a health metric by ID and notifies all listening screens.
  bool delete(int id) {
    final index = _metrics.indexWhere((m) => m.id == id);
    if (index != -1) {
      _metrics.removeAt(index);
      notifyListeners();
      return true;
    }
    return false;
  }

  /// Returns metrics filtered by type and date range, sorted ascending by date (for charts).
  List<HealthMetric> getFiltered({
    required String metricType,
    required DateTime since,
  }) {
    final filtered = _metrics.where((m) =>
        m.metricType == metricType &&
        (m.recordedAt.isAfter(since) || m.recordedAt.isAtSameMomentAs(since))).toList();
    filtered.sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return filtered;
  }
}
