import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<StudentModel> _children = [];
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _evolutionData = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<StudentModel> get children => _children;
  List<Map<String, dynamic>> get activities => _activities;
  List<Map<String, dynamic>> get evolutionData => _evolutionData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    await Future.wait([
      fetchChildren(),
      fetchStats(),
      fetchActivities(),
    ]);
  }

  Future<void> fetchChildren() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _children = await _apiService.getChildren();
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchStats() async {
    try {
      await _apiService.getDashboardStats();
      // Stats are fetched to populate any server-side cache or aggregated data
      notifyListeners();
    } catch (e) {
      // Handle silently
    }
  }

  Future<void> fetchActivities() async {
    try {
      _activities = await _apiService.getDashboardActivities();
      notifyListeners();
    } catch (e) {
      // Background fetch, handle silently
    }
  }

  Future<void> fetchEvolution(String studentId, String year, String semester) async {
    try {
      _evolutionData = await _apiService.getGradeEvolution(
        studentId: studentId,
        year: year,
        semester: semester,
      );
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
}
