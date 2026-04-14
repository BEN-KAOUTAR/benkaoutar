import 'package:flutter/material.dart';
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
  List<Map<String, dynamic>> _todayAgenda = [];
  List<Map<String, dynamic>> get todayAgenda => _todayAgenda;
  List<Map<String, dynamic>> _subjectAverages = [];
  List<Map<String, dynamic>> get subjectAverages => _subjectAverages;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> init() async {
    await Future.wait([
      fetchChildren(),
      fetchStats(),
      fetchTodayAgenda(), // New: Fetch today's context first
      fetchActivities(),
      fetchSubjectAverages(),
    ]);
  }

  Future<void> fetchTodayAgenda() async {
    try {
      final now = DateTime.now();
      final todayStr = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
      final dayOfWeekIndex = now.weekday - 1; // 0=Mon, ..., 6=Sun

      final results = await Future.wait([
        _apiService.getTimetable('me').catchError((_) => <TimetableSessionModel>[]),
        _apiService.getGrades('me').catchError((_) => <GradeModel>[]),
        _apiService.getAbsences('me').catchError((_) => <AttendanceRecord>[]),
        _apiService.getHomework('me').catchError((_) => <HomeworkModel>[]),
        _apiService.getCalendarEvents(studentId: 'me', month: now.month, year: now.year).catchError((_) => <EventModel>[]),
      ]);

      final List<Map<String, dynamic>> agenda = [];

      // 1. Add Sessions (Classes)
      final sessions = results[0] as List<TimetableSessionModel>;
      for (var s in sessions) {
        if (s.dayIndex == dayOfWeekIndex) {
          agenda.add({
            'type': 'session',
            'title': s.subject,
            'content': '${s.time} - ${s.room} (Prof. ${s.teacher})',
            'time': s.time,
            'icon': Icons.schedule_rounded,
            'color': Colors.blueAccent,
            'date_raw': now,
          });
        }
      }

      // 2. Add Exams (Grades from today)
      final exams = results[1] as List<GradeModel>;
      for (var e in exams) {
        if (e.date.contains(todayStr)) {
          agenda.add({
            'type': 'exam',
            'title': 'Examen: ${e.subject}',
            'content': e.title ?? 'Évaluation prévue',
            'date': 'Aujourd\'hui',
            'icon': Icons.assignment_rounded,
            'color': Colors.purpleAccent,
            'date_raw': now,
          });
        }
      }

      // 3. Add Absences / Attendance today
      final absences = results[2] as List<AttendanceRecord>;
      for (var ab in absences) {
        if (ab.date.contains(todayStr)) {
          final isAbsence = ab.status.toLowerCase().contains('absent');
          agenda.add({
            'type': 'absence',
            'title': isAbsence ? 'Absence Détectée' : 'Retard Détecté',
            'content': '${ab.subjectName ?? "Session"} - ${ab.status}',
            'date': 'Aujourd\'hui',
            'icon': isAbsence ? Icons.event_busy_rounded : Icons.history_toggle_off_rounded,
            'color': isAbsence ? Colors.redAccent : Colors.orangeAccent,
            'date_raw': now,
          });
        }
      }

      // 4. Add Homework (Due Today)
      final homeworks = results[3] as List<HomeworkModel>;
      for (var h in homeworks) {
        if (h.dueDate.contains(todayStr)) {
          agenda.add({
            'type': 'homework',
            'title': 'Devoir à rendre: ${h.subject}',
            'content': h.title,
            'date': 'Aujourd\'hui',
            'icon': Icons.menu_book_rounded,
            'color': Colors.greenAccent,
            'date_raw': now,
          });
        }
      }

      // 5. Add Calendar Events (Today)
      final events = results[4] as List<EventModel>;
      for (var ev in events) {
        if (ev.date.contains(todayStr)) {
          agenda.add({
            'type': 'event',
            'title': ev.title,
            'content': ev.description.isNotEmpty ? ev.description : 'Événement scolaire',
            'time': ev.time.isNotEmpty ? ev.time : null,
            'icon': Icons.event_available_rounded,
            'color': Colors.indigoAccent,
            'date_raw': now,
          });
        }
      }

      // Sort by time if it exists (for sessions)
      agenda.sort((a, b) {
        final timeA = a['time'] ?? '00:00';
        final timeB = b['time'] ?? '00:00';
        return timeA.compareTo(timeB);
      });

      _todayAgenda = agenda;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching today agenda: $e');
    }
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
      final rawActivities = await _apiService.getDashboardActivities();
      _activities = rawActivities.map((a) {
        final iconType = a['icon_type'] ?? 'info';
        IconData icon;
        Color color;

        switch (iconType) {
          case 'post':
          case 'news':
            icon = Icons.newspaper_rounded;
            color = Colors.blueAccent;
            break;
          case 'absence':
            icon = Icons.event_busy_rounded;
            color = Colors.redAccent;
            break;
          case 'grade':
            icon = Icons.grade_rounded;
            color = Colors.greenAccent;
            break;
          default:
            icon = Icons.info_outline_rounded;
            color = Colors.blueGrey;
        }

        return {
          ...a,
          'icon': icon,
          'color': color,
        };
      }).toList();
      notifyListeners();
    } catch (e) {
      // Background fetch, handle silently
    }
  }

  List<GradeModel>? _cachedGrades;

  Future<void> fetchSubjectAverages({String? semester, bool forceRefresh = false}) async {
    try {
      if (forceRefresh || _cachedGrades == null) {
        _cachedGrades = await _apiService.getGrades('me');
      }
      
      final grades = _cachedGrades ?? [];
      if (grades.isEmpty) {
        _subjectAverages = [];
        notifyListeners();
        return;
      }

      // Filter by semester if specified
      final filteredGrades = (semester == null || semester == 'all')
          ? grades
          : grades.where((g) {
              final s = g.semester.toString().toUpperCase().replaceAll('S', '');
              final target = semester.toString().toUpperCase().replaceAll('S', '');
              return s == target;
            }).toList();

      if (filteredGrades.isEmpty) {
        _subjectAverages = [];
        notifyListeners();
        return;
      }

      final Map<String, List<double>> subjectScores = {};
      for (var g in filteredGrades) {
        if (!subjectScores.containsKey(g.subject)) {
          subjectScores[g.subject] = [];
        }
        // Normalize to a 10-point scale: (grade / maxGrade) * 10
        final normalizedGrade = (g.grade / (g.maxGrade > 0 ? g.maxGrade : 20.0)) * 10.0;
        subjectScores[g.subject]!.add(normalizedGrade);
      }

      _subjectAverages = [];
      int index = 0;
      for (var subject in subjectScores.keys) {
        final scores = subjectScores[subject]!;
        final average = scores.fold(0.0, (sum, score) => sum + score) / scores.length;
        _subjectAverages.add({
          'index': index++,
          'subject': subject,
          'grade': double.parse(average.toStringAsFixed(2)),
        });
      }
      notifyListeners();
    } catch (e) {
      // Handle silently
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
