import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/websocket_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;
  final WebSocketService _wsService = WebSocketService();

  List<ChatThreadModel> _threads = [];
  List<ChatMessageModel> _activeMessages = [];
  bool _isLoadingThreads = false;
  bool _isLoadingMessages = false;
  String? _errorMessage;
  String? _activeThreadId;
  bool _isWebSocketConnected = false;
  bool _useWebSocket = true; // Toggle for WebSocket vs polling

  // Real-time polling (fallback)
  Timer? _pollingTimer;
  bool _isRefreshing = false;
  Timer? _keepAliveTimer;

  // Stream subscriptions
  StreamSubscription<ChatMessageModel>? _messageSubscription;
  StreamSubscription<Map<String, dynamic>>? _eventSubscription;
  StreamSubscription<bool>? _connectionStatusSubscription;

  List<ChatThreadModel> get threads => _threads;
  List<ChatMessageModel> get activeMessages => _activeMessages;
  bool get isLoadingThreads => _isLoadingThreads;
  bool get isLoadingMessages => _isLoadingMessages;
  String? get errorMessage => _errorMessage;
  String? get activeThreadId => _activeThreadId;
  bool get isWebSocketConnected => _isWebSocketConnected;

  /// Initialize WebSocket connection
  Future<void> initializeWebSocket() async {
    if (!_useWebSocket) return;

    try {
      final token = _apiService.token ?? '';
      final baseUrl = _apiService.baseUrl;
      
      if (token.isEmpty || baseUrl.isEmpty) {
        debugPrint('[ChatVM] Missing token or baseUrl, skipping WebSocket init');
        _useWebSocket = false;
        startPolling();
        return;
      }

      _wsService.initialize(token: token, baseUrl: baseUrl);
      await _wsService.connect();
      
      _setupWebSocketListeners();
      _setupKeepAlive();
      
      debugPrint('[ChatVM] WebSocket initialized and connected');
    } catch (e) {
      debugPrint('[ChatVM] Failed to initialize WebSocket: $e');
      _useWebSocket = false;
      startPolling(); // Fallback to polling
    }
  }

  /// Setup listeners for WebSocket events
  void _setupWebSocketListeners() {
    // Listen to incoming messages
    _messageSubscription = _wsService.messageStream.listen((message) {
      debugPrint('[ChatVM] New message received via WebSocket');
      
      if (message.threadId == _activeThreadId) {
        _handleNewMessage(message);
      }
      
      // Update thread list
      _updateThreadWithMessage(message);
      notifyListeners();
    });

    // Listen to other events (typing indicators, etc.)
    _eventSubscription = _wsService.eventStream.listen((event) {
      debugPrint('[ChatVM] Event received: ${event["type"]}');
      
      if (event["type"] == "typing") {
        // Handle typing indicator
        notifyListeners();
      } else if (event["type"] == "error") {
        _errorMessage = event["message"] ?? "Unknown error";
        notifyListeners();
      }
    });

    // Listen to connection status changes
    _connectionStatusSubscription = _wsService.connectionStatusStream.listen((connected) {
      _isWebSocketConnected = connected;
      
      if (connected) {
        debugPrint('[ChatVM] WebSocket connected');
        // Re-join active thread if any
        if (_activeThreadId != null) {
          _wsService.joinThread(_activeThreadId!);
        }
      } else {
        debugPrint('[ChatVM] WebSocket disconnected, falling back to polling');
        // If WebSocket disconnects, fall back to polling
        if (_isRefreshing == false) {
          startPolling();
        }
      }
      
      notifyListeners();
    });
  }

  /// Setup keep-alive mechanism (ping every 30 seconds)
  void _setupKeepAlive() {
    _keepAliveTimer?.cancel();
    _keepAliveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isWebSocketConnected) {
        _wsService.sendPing();
      }
    });
  }

  /// Handle new message received
  void _handleNewMessage(ChatMessageModel message) {
    // Check if message already exists (to avoid duplicates)
    final exists = _activeMessages.any((m) => m.id == message.id);
    if (!exists) {
      _activeMessages.add(message);
    }
  }

  /// Update thread list with new message
  void _updateThreadWithMessage(ChatMessageModel message) {
    final threadIndex = _threads.indexWhere((t) => t.id == message.threadId);
    if (threadIndex != -1) {
      final t = _threads[threadIndex];
      _threads[threadIndex] = ChatThreadModel(
        id: t.id,
        contactName: t.contactName,
        contactRole: t.contactRole,
        lastMessage: message.content,
        lastTime: message.time,
        unreadCount: t.unreadCount,
        onlyAdminsCanMessage: t.onlyAdminsCanMessage,
        avatarUrl: t.avatarUrl,
      );
    }
  }

  void startPolling() {
    if (_useWebSocket && _isWebSocketConnected) return; // Skip if using WebSocket
    
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(
        const Duration(seconds: 2), (_) => refreshSilent());
    debugPrint('[ChatVM] Polling started (2s interval)');
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
    debugPrint('[ChatVM] Polling stopped');
  }

  @override
  void dispose() {
    stopPolling();
    _keepAliveTimer?.cancel();
    _messageSubscription?.cancel();
    _eventSubscription?.cancel();
    _connectionStatusSubscription?.cancel();
    
    if (_activeThreadId != null) {
      _wsService.leaveThread(_activeThreadId!);
    }
    
    _wsService.disconnect();
    super.dispose();
  }

  Future<void> refreshSilent() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    try {
      await fetchThreads(silent: true);
    } finally {
      _isRefreshing = false;
    }
  }

  Future<void> fetchThreads({bool silent = false}) async {
    if (!silent) {
      _isLoadingThreads = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      _threads = await _apiService.getChatThreads();
    } catch (e) {
      if (!silent) {
        _errorMessage = _apiService.getLocalizedErrorMessage(e);
      }
    } finally {
      if (!silent) {
        _isLoadingThreads = false;
      }
      // Always notify listeners so UI updates reflect data changes
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String threadId, {bool silent = false}) async {
    _activeThreadId = threadId;
    
    // Join the thread via WebSocket if connected
    if (_isWebSocketConnected) {
      _wsService.joinThread(threadId);
    }
    
    if (!silent) {
      _isLoadingMessages = true;
      _activeMessages = [];
      notifyListeners();
    }

    try {
      _activeMessages = await _apiService.getMessages(threadId);
    } catch (e) {
      if (!silent) {
        _errorMessage = _apiService.getLocalizedErrorMessage(e);
      }
    } finally {
      if (!silent) {
        _isLoadingMessages = false;
      }
      // Always notify listeners so UI updates reflect data changes
      notifyListeners();
    }
  }

  /// Send message using WebSocket if connected, otherwise use HTTP API
  Future<void> sendMessage(String threadId, String content,
      {String type = 'text'}) async {
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
      if (_isWebSocketConnected) {
        // Send via WebSocket
        _wsService.sendMessage(
          threadId: threadId,
          content: content,
          type: type,
        );
        debugPrint('[ChatVM] Message sent via WebSocket');
      } else {
        // Send via HTTP API
        final realMessage =
            await _apiService.sendMessage(threadId, content, type);
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
        debugPrint('[ChatVM] Message sent via HTTP API');
      }
    } catch (e) {
      // Rollback on failure or show error
      _activeMessages.removeWhere((m) => m.id == tempMessage.id);
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      debugPrint('[ChatVM] Error sending message: $e');
    } finally {
      notifyListeners();
    }
  }

  /// Send typing indicator
  void sendTypingIndicator(String threadId) {
    if (_isWebSocketConnected) {
      _wsService.sendTypingIndicator(threadId);
    }
  }

  /// Stop typing indicator
  void stopTypingIndicator(String threadId) {
    if (_isWebSocketConnected) {
      _wsService.stopTypingIndicator(threadId);
    }
  }

  void clearActiveChat() {
    if (_activeThreadId != null && _isWebSocketConnected) {
      _wsService.leaveThread(_activeThreadId!);
    }
    
    _activeThreadId = null;
    _activeMessages = [];
    notifyListeners();
  }
}
