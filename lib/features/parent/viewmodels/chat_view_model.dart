import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<ChatThreadModel> _threads = [];
  List<ChatMessageModel> _activeMessages = [];
  bool _isLoadingThreads = false;
  bool _isLoadingMessages = false;
  String? _errorMessage;
  String? _activeThreadId;

  List<ChatThreadModel> get threads => _threads;
  List<ChatMessageModel> get activeMessages => _activeMessages;
  bool get isLoadingThreads => _isLoadingThreads;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get errorMessage => _errorMessage;
  String? get activeThreadId => _activeThreadId;

  Future<void> fetchThreads() async {
    _isLoadingThreads = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _threads = await _apiService.getChatThreads();
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      _isLoadingThreads = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String threadId) async {
    _activeThreadId = threadId;
    _isLoadingMessages = true;
    _activeMessages = [];
    notifyListeners();

    try {
      _activeMessages = await _apiService.getMessages(threadId);
    } catch (e) {
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      _isLoadingMessages = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String threadId, String content, {String type = 'text'}) async {
    // Optimistic UI update
    final tempMessage = ChatMessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      threadId: threadId,
      senderId: 'me',
      content: content,
      time: 'just_now', // Will be replaced by server time
      isMe: true,
      type: type,
    );

    _activeMessages.add(tempMessage);
    notifyListeners();

    try {
      final realMessage = await _apiService.sendMessage(threadId, content, type);
      // Replace temp message with real message from server
      final index = _activeMessages.indexWhere((m) => m.id == tempMessage.id);
      if (index != -1) {
        _activeMessages[index] = realMessage;
      }
      
      // Update last message in thread list
      final threadIndex = _threads.indexWhere((t) => t.id == threadId);
      if (threadIndex != -1) {
        final t = _threads[threadIndex];
        _threads[threadIndex] = ChatThreadModel(
          id: t.id,
          contactName: t.contactName,
          contactRole: t.contactRole,
          lastMessage: content,
          lastTime: realMessage.time,
          unreadCount: t.unreadCount,
          onlyAdminsCanMessage: t.onlyAdminsCanMessage,
          avatarUrl: t.avatarUrl,
        );
      }
    } catch (e) {
      // Rollback on failure or show error
      _activeMessages.removeWhere((m) => m.id == tempMessage.id);
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
    } finally {
      notifyListeners();
    }
  }

  void clearActiveChat() {
    _activeThreadId = null;
    _activeMessages = [];
    notifyListeners();
  }
}
