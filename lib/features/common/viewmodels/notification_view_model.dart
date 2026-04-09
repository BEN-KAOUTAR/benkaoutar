import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class NotificationViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<NotificationModel> _notifications = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<NotificationModel> get notifications => _notifications;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> fetchNotifications() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notifications = await _apiService.getNotifications();
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(String id) async {
    // Optimistic UI
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index != -1 && !_notifications[index].isRead) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      notifyListeners();

      try {
        await _apiService.markNotificationRead(id);
      } catch (e) {
        // Rollback on failure
        _notifications[index] = _notifications[index].copyWith(isRead: false);
        _errorMessage = _apiService.getLocalizedErrorMessage(e);
        notifyListeners();
      }
    }
  }

  Future<void> markAllAsRead() async {
    final oldNotifications = List<NotificationModel>.from(_notifications);
    
    // Optimistic UI
    _notifications = _notifications.map((n) => n.copyWith(isRead: true)).toList();
    notifyListeners();

    try {
      await _apiService.markAllNotificationsRead();
    } catch (e) {
      _notifications = oldNotifications;
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      notifyListeners();
    }
  }
}
