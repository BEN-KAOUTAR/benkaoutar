import 'package:flutter/foundation.dart';
import '../../../core/services/api_service.dart';

class TimetableViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<Map<String, dynamic>> _timetable = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Map<String, dynamic>> get timetable => _timetable;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchTimetable(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _timetable = await _apiService.getTimetable(studentId);
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
