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
  double _uploadProgress = 0.0;

  List<GradeModel> get grades => _grades;
  List<AttendanceRecord> get absences => _absences;
  Map<String, List<dynamic>> get evolutionData => _evolutionData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get uploadProgress => _uploadProgress;

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

  List<Map<String, dynamic>> _schedule = [];
  List<Map<String, dynamic>> get schedule => _schedule;

  Future<void> fetchSuiviData(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('Fetching suivi data for student: $studentId');
      final results = await Future.wait([
        _apiService.getGrades(studentId),
        _apiService.getAbsences(studentId),
        _apiService.getTimetable(studentId).catchError((_) => <Map<String, dynamic>>[]),
      ]);

      _grades = results[0] as List<GradeModel>;
      _absences = results[1] as List<AttendanceRecord>;
      _schedule = results[2] as List<Map<String, dynamic>>;
      
      debugPrint('Parsed ${_grades.length} grades, ${_absences.length} absences, ${_schedule.length} schedule slots');
      
      // Diagnostic logging for persistence issue
      for (var a in _absences) {
        if (a.status == 'absent') {
          debugPrint('Absence ID: ${a.id}, Justified: ${a.isJustified}, Flag: ${a.justifiedByStudent}, Approval: ${a.approvalStatus}, Motif: ${a.motif}');
        }
      }

      // Generate evolution data from local grades chronologically
      _processEvolutionDataFromGrades();
    } catch (e) {
      debugPrint('Error fetching suivi data: $e');
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Find a matching schedule slot for a given attendance record
  /// Matches by day of week and subject name
  Map<String, dynamic>? getScheduleForAttendance(AttendanceRecord a) {
    try {
      final dt = DateTime.parse(a.date);
      // weekday: 1=Monday, 2=Tuesday,...,7=Sunday
      final dayOfWeek = dt.weekday;
      final dayNames = ['', 'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
      final dayName = dayNames[dayOfWeek].toLowerCase();

      for (final slot in _schedule) {
        final slotDay = (slot['day'] ?? slot['dayOfWeek'] ?? '').toString().toLowerCase();
        if (!slotDay.contains(dayName) && slotDay != dayOfWeek.toString()) continue;

        // Try to match by subject name
        if (a.subjectName != null) {
          final slotSubject = (slot['subject'] ?? '').toString().toLowerCase();
          if (slotSubject.contains(a.subjectName!.toLowerCase()) || a.subjectName!.toLowerCase().contains(slotSubject)) {
            return slot;
          }
        } else {
          // Return first slot for that day
          return slot;
        }
      }
    } catch (_) {}
    return null;
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


  int get totalAttendanceDays => _absences.length;

  int get unjustifiedAbsences => _absences.where((a) => a.status == 'absent' && !a.isJustified).length;
  int get justifiedAbsences => _absences.where((a) => a.isJustified).length;
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

  // Helper to find attendance record for a specific date
  AttendanceRecord? getAttendanceForDate(DateTime dt) {
    for (var a in _absences) {
      try {
        final attendanceDate = DateTime.parse(a.date);
        if (attendanceDate.year == dt.year && 
            attendanceDate.month == dt.month && 
            attendanceDate.day == dt.day) {
          return a;
        }
      } catch (e) {
        // Fallback for non-standard formats if possible
        if (a.date.contains('${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}')) {
          return a;
        }
      }
    }
    return null;
  }

  Future<bool> submitJustification(String attendanceId, {String? filePath, Uint8List? fileBytes, required String fileName, String reason = ''}) async {
    _isLoading = true;
    _errorMessage = null;
    _uploadProgress = 0.0;
    notifyListeners();

    try {
      final result = await _apiService.submitJustification(
        attendanceId, 
        filePath: filePath,
        fileBytes: fileBytes,
        fileName: fileName,
        reason: reason,
        onProgress: (sent, total) {
            if (total > 0) {
                _uploadProgress = sent / total;
                notifyListeners();
            }
        }
      );
      if (result != null) {
        // Instant local state update: mark the absence as justified
        final index = _absences.indexWhere((a) => a.id == attendanceId);
        if (index != -1) {
          final old = _absences[index];
          final newAttachmentUrl = (result != 'success') ? result : old.attachment;
          _absences[index] = AttendanceRecord(
            id: old.id,
            date: old.date,
            status: old.status,
            motif: reason.isNotEmpty ? reason : old.motif,
            attachment: newAttachmentUrl,
            rawStatus: 'absent_justifie',
            startTime: old.startTime,
            endTime: old.endTime,
            subjectName: old.subjectName,
            sessionName: old.sessionName,
            justifiedByStudent: true,
            approvalStatus: old.approvalStatus ?? 'pending',
            recordedBy: old.recordedBy,
          );
        }
        
        // Optional: Re-fetch to confirm server persistence
        // await fetchSuiviData(studentId); 
        
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      return false;
    } finally {
      _isLoading = false;
      _uploadProgress = 0.0;
      notifyListeners();
    }
  }
}
