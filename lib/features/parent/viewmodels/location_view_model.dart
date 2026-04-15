import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class LocationViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  BusLocationModel? _currentLocation;
  List<LocationHistoryRecord> _history = [];
  bool _isLoading = false;
  String? _errorMessage;
  Timer? _pollingTimer;

  BusLocationModel? get currentLocation => _currentLocation;
  List<LocationHistoryRecord> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void startTracking(String studentId) {
    fetchLocationData(studentId);

    // Polling every 10 seconds for live bus updates
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _pollBusLocation(studentId);
    });
  }

  void stopTracking() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  Future<void> fetchLocationData(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getBusLocation(studentId),
        _apiService.getLocationHistory(studentId),
      ]);

      _currentLocation = results[0] as BusLocationModel;
      _history = results[1] as List<LocationHistoryRecord>;
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _pollBusLocation(String studentId) async {
    try {
      _currentLocation = await _apiService.getBusLocation(studentId);
      notifyListeners();
    } catch (e) {
      debugPrint('Polling error: $e');
    }
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}
