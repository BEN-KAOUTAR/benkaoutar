import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class HomeworkViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<HomeworkModel> _homeworks = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<HomeworkModel> get homeworks => _homeworks;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchHomework(String studentId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _homeworks = await _apiService.getHomework(studentId);
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> updateStatus(String homeworkId, HomeworkStatus newStatus) async {
    final index = _homeworks.indexWhere((h) => h.id == homeworkId);
    if (index == -1) return;

    final originalStatus = _homeworks[index].status;
    
    // Optimistic UI update
    _homeworks[index] = _homeworks[index].copyWith(status: newStatus);
    notifyListeners();

    try {
      await _apiService.updateHomeworkStatus(homeworkId, newStatus);
    } catch (e) {
      // Rollback
      _homeworks[index] = _homeworks[index].copyWith(status: originalStatus);
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      notifyListeners();
    }
  }

  // Stats for the UI
  double get progressionRate {
    if (_homeworks.isEmpty) return 0.0;
    final done = _homeworks.where((h) => h.status == HomeworkStatus.done).length;
    return (done / _homeworks.length) * 100;
  }

  String get progressionLabel {
    final done = _homeworks.where((h) => h.status == HomeworkStatus.done).length;
    return "$done/${_homeworks.length}";
  }
}

// Extension to help with copyWith if not already there (it wasn't in models.dart)
extension HomeworkModelExtension on HomeworkModel {
  HomeworkModel copyWith({
    String? id,
    String? subject,
    String? title,
    String? description,
    String? dueDate,
    HomeworkStatus? status,
    String? attachment,
    String? teacherComment,
    String? teacherName,
  }) {
    return HomeworkModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      attachment: attachment ?? this.attachment,
      teacherComment: teacherComment ?? this.teacherComment,
      teacherName: teacherName ?? this.teacherName,
    );
  }
}
