import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class EventViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<EventModel> _events = [];
  EventModel? _selectedEvent;
  bool _isLoading = false;
  bool _isLoadingDetails = false;
  String? _errorMessage;

  List<EventModel> get events => _events;
  EventModel? get selectedEvent => _selectedEvent;
  bool get isLoading => _isLoading;
  bool get isLoadingDetails => _isLoadingDetails;
  String? get errorMessage => _errorMessage;

  // Real-time polling
  Timer? _pollingTimer;
  bool _isRefreshing = false;

  void startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 1), (_) => refreshSilent());
    debugPrint('Event polling started (1s interval)');
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('Event polling stopped');
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }

  Future<void> refreshSilent() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await fetchEvents(silent: true);
    } finally {
      _isRefreshing = false;
    }
  }

  // Fetch all events
  Future<void> fetchEvents({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _events = await _apiService.getEvents();
    } catch (e) {
      if (!silent) _errorMessage = _apiService.getLocalizedErrorMessage(e);
      debugPrint('Error fetching events: $e');
    } finally {
      if (!silent) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // Get event details
  Future<void> fetchEventDetails(String eventId) async {
    _isLoadingDetails = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedEvent = await _apiService.getEventDetails(eventId);
      _isLoadingDetails = false;
      notifyListeners();
    } catch (e) {
      _isLoadingDetails = false;
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      debugPrint('Error fetching event details: $e');
      notifyListeners();
    }
  }

  // Select an event for preview
  void selectEvent(EventModel event) {
    _selectedEvent = event;
    notifyListeners();
  }

  // Clear selected event
  void clearSelectedEvent() {
    _selectedEvent = null;
    notifyListeners();
  }

  // Respond to event (RSVP)
  Future<bool> respondToEvent(String eventId, String status) async {
    try {
      final updatedEvent = await _apiService.respondToEventNew(eventId, status);

      if (updatedEvent != null) {
        // Update local event with the updated data from API
        final index = _events.indexWhere((e) => e.id == eventId);
        if (index != -1) {
          _events[index] = updatedEvent;
          notifyListeners();
        }

        // Update selected event if it's the same
        if (_selectedEvent?.id == eventId) {
          _selectedEvent = updatedEvent;
          notifyListeners();
        }
      }

      return updatedEvent != null;
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      debugPrint('Error responding to event: $e');
      notifyListeners();
      return false;
    }
  }

  // Delete event
  Future<bool> deleteEvent(String eventId) async {
    try {
      final success = await _apiService.deleteEvent(eventId);

      if (success) {
        _events.removeWhere((e) => e.id == eventId);
        if (_selectedEvent?.id == eventId) {
          clearSelectedEvent();
        }
        notifyListeners();
      }

      return success;
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      debugPrint('Error deleting event: $e');
      notifyListeners();
      return false;
    }
  }

  // Refresh events
  Future<void> refresh() async {
    await fetchEvents();
  }
}
