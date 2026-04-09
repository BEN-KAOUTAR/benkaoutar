import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';

class BehaviorViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;
  String? _errorMessage;

  Map<String, dynamic> get summary => _summary;
  List<Map<String, dynamic>> get history => _history;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchBehaviorData(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getBehaviorSummary(studentId),
        _apiService.getBehaviorHistory(studentId),
      ]);
      _summary = results[0] as Map<String, dynamic>;
      _history = results[1] as List<Map<String, dynamic>>;
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
