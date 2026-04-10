import 'package:flutter/foundation.dart';

/// Service for handling push notifications.
class NotificationService {
  Future<void> init() async {
    if (kDebugMode) {
      debugPrint('[NotificationService] Initialized');
    }
  }
}
