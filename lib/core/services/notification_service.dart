import 'package:flutter/foundation.dart';

/// Mock notification service — no Firebase dependency.
/// Will be replaced with real push notifications when backend is ready.
class NotificationService {
  Future<void> init() async {
    if (kDebugMode) {
      debugPrint('[NotificationService] Mock init — no Firebase');
    }
  }
}
