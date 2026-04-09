import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class SuiviViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<GradeModel> _grades = [];
  List<AttendanceRecord> _absences = [];
  int _totalAttendanceDays = 0;
  bool _isLoading = false;
  String? _errorMessage;

  List<GradeModel> get grades => _grades;
  List<AttendanceRecord> get absences => _absences;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchSuiviData(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _apiService.getGrades(studentId),
        _apiService.getAbsences(studentId),
      ]);

      _grades = results[0] as List<GradeModel>;
      _absences = results[1] as List<AttendanceRecord>;
      _totalAttendanceDays = _absences.length;
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper getters for UI stats
  int get unjustifiedAbsences => _absences.where((a) => a.status == 'absent' && (a.motif == null || a.motif!.isEmpty)).length;
  int get justifiedAbsences => _absences.where((a) => a.status == 'absent' && a.motif != null && a.motif!.isNotEmpty).length;
  int get delays => _absences.where((a) => a.status == 'late').length;
  int get presentDays => _absences.where((a) => a.status == 'present').length;

  double get attendanceRate {
    if (_totalAttendanceDays == 0) return 100.0;
    return (presentDays / _totalAttendanceDays) * 100;
  }

  double get gradeAverage {
    if (_grades.isEmpty) return 0.0;
    final total = _grades.fold<double>(0, (sum, g) => sum + g.grade);
    return total / _grades.length;
  }
}
