import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class SuiviViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<GradeModel> _grades = [];
  List<AttendanceRecord> _absences = [];
  Map<String, List<dynamic>> _evolutionData = {}; // Map of subject -> list of FlSpot-like data
  bool _isLoading = false;
  String? _errorMessage;

  List<GradeModel> get grades => _grades;
  List<AttendanceRecord> get absences => _absences;
  Map<String, List<dynamic>> get evolutionData => _evolutionData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Group grades by subject for UI display
  Map<String, List<GradeModel>> get groupedGrades {
    final Map<String, List<GradeModel>> grouped = {};
    for (var g in _grades) {
      if (!grouped.containsKey(g.subject)) {
        grouped[g.subject] = [];
      }
      grouped[g.subject]!.add(g);
    }
    return grouped;
  }

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
      
      // Generate evolution data from local grades chronologically
      _processEvolutionDataFromGrades();
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Map<String, Map<String, List<Map<String, double>>>> _evolutionDataBySemester = {};
  Map<String, Map<String, List<Map<String, double>>>> get evolutionDataBySemester => _evolutionDataBySemester;

  void _processEvolutionDataFromGrades() {
    _evolutionDataBySemester = {};
    _evolutionData = {}; // legacy flat map for fallback
    
    final grouped = groupedGrades;
    for (var entry in grouped.entries) {
      final subject = entry.key;
      final chronologicalGrades = entry.value.reversed.toList();
      
      List<Map<String, double>> s1Points = [];
      List<Map<String, double>> s2Points = [];
      List<Map<String, double>> allPoints = [];
      
      int s1Index = 0;
      int s2Index = 0;
      
      for (int i = 0; i < chronologicalGrades.length; i++) {
        final g = chronologicalGrades[i];
        double score = g.grade;
        if (g.maxGrade > 0 && g.maxGrade != 20) {
          score = (g.grade / g.maxGrade) * 20.0;
        }

        final isS2 = g.semester?.toUpperCase().contains('2') ?? false;

        if (isS2) {
          s2Points.add({'x': s2Index.toDouble(), 'y': score});
          s2Index++;
        } else { // default to S1
          s1Points.add({'x': s1Index.toDouble(), 'y': score});
          s1Index++;
        }
        allPoints.add({'x': i.toDouble(), 'y': score});
      }
      
      _evolutionDataBySemester[subject] = {'1': s1Points, '2': s2Points};
      if (allPoints.isNotEmpty) {
        _evolutionData[subject] = allPoints;
      }
    }
  }

  double get generalAverage {
    final grouped = groupedGrades;
    if (grouped.isEmpty) return gradeAverage; // fallback
    double sum = 0;
    for (var sub in grouped.keys) {
      sum += calculateSubjectAverage(sub);
    }
    return sum / grouped.length;
  }

  void setMockEvolution() {
    _evolutionData = {
      'math': [{'x': 0.0, 'y': 12.0}, {'x': 1.0, 'y': 14.5}, {'x': 2.0, 'y': 13.0}, {'x': 3.0, 'y': 16.0}, {'x': 4.0, 'y': 15.5}],
      'french_sub': [{'x': 0.0, 'y': 10.0}, {'x': 1.0, 'y': 11.0}, {'x': 2.0, 'y': 12.5}, {'x': 3.0, 'y': 11.5}, {'x': 4.0, 'y': 13.0}],
      'science': [{'x': 0.0, 'y': 15.0}, {'x': 1.0, 'y': 14.0}, {'x': 2.0, 'y': 16.5}, {'x': 3.0, 'y': 17.0}, {'x': 4.0, 'y': 16.0}],
      'history_geo': [{'x': 0.0, 'y': 11.0}, {'x': 1.0, 'y': 13.0}, {'x': 2.0, 'y': 12.0}, {'x': 3.0, 'y': 14.0}, {'x': 4.0, 'y': 15.0}],
    };
    notifyListeners();
  }

  int get totalAttendanceDays => _absences.length;
  int get unjustifiedAbsences => _absences.where((a) => a.status == 'absent' && (a.motif == null || a.motif!.isEmpty)).length;
  int get justifiedAbsences => _absences.where((a) => a.status == 'absent' && a.motif != null && a.motif!.isNotEmpty).length;
  int get delays => _absences.where((a) => a.status == 'late').length;
  int get presentDays => _absences.where((a) => a.status == 'present').length;

  double get attendanceRate {
    if (totalAttendanceDays == 0) return 100.0;
    return (presentDays / totalAttendanceDays) * 100;
  }

  double get gradeAverage {
    if (_grades.isEmpty) return 0.0;
    final total = _grades.fold<double>(0, (sum, g) => sum + g.grade);
    return total / _grades.length;
  }

  double calculateSubjectAverage(String subjectId) {
    final subjectGrades = _grades.where((g) => g.subject == subjectId);
    if (subjectGrades.isEmpty) return 0.0;
    final total = subjectGrades.fold<double>(0, (sum, g) => sum + g.grade);
    return total / subjectGrades.length;
  }

  // Returns latest rank for the subject, or null if not available
  int? getSubjectRank(String subjectId) {
    final subjectGrades = _grades.where((g) => g.subject == subjectId && g.rank != null);
    if (subjectGrades.isEmpty) return null;
    return subjectGrades.first.rank; // Latest grade's rank
  }

  int? getSubjectClassSize(String subjectId) {
    final subjectGrades = _grades.where((g) => g.subject == subjectId && g.classSize != null);
    if (subjectGrades.isEmpty) return null;
    return subjectGrades.first.classSize;
  }
}
