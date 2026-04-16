import 'dart:async';
import 'package:flutter/material.dart';
import '../chat_api_service.dart';
import '../models/chat_message_model.dart';
import '../models/chat_thread_model.dart';
import '../../../core/services/websocket_service.dart';
import '../../../core/models/models.dart';

class ChatViewModel extends ChangeNotifier {
  ChatApiService? _apiService;
  final WebSocketService _webSocketService = WebSocketService();
  late StreamSubscription<ChatMessageModel> _messageSubscription;
  late StreamSubscription<bool> _connectionSubscription;
  
  final List<ChatThread> _conversations = [];
  final List<ChatMessage> _messages = [];
  bool _loading = false;
  bool _isConnected = false;
  String? _currentThreadId;
  String? _userId;
  String? _userName;
  Map<String, bool> _typingUsers = {}; // threadId -> isTyping

  // Getters
  List<ChatThread> get conversations => _conversations;
  List<ChatMessage> get messages => _messages;
  bool get loading => _loading;
  bool get isConnected => _isConnected;
  String? get currentThreadId => _currentThreadId;
  String? get userId => _userId;
  String? get userName => _userName;
  Map<String, bool> get typingUsers => _typingUsers;

  ChatViewModel(this._apiService) {
    // Initialize WebSocket when ViewModel is created
    _listenToWebSocket();
  }

  /// Initialize WebSocket connection with API base URL and token
  Future<void> initializeWebSocket({required String token, required String baseUrl}) async {
    try {
      _webSocketService.initialize(token: token, baseUrl: baseUrl);
      await _webSocketService.connect();
      debugPrint('[ChatViewModel] WebSocket initialized and connected');
    } catch (e) {
      debugPrint('[ChatViewModel] Error initializing WebSocket: $e');
    }
  }

  /// Listen to WebSocket messages and connection status
  void _listenToWebSocket() {
    // Listen to incoming messages
    _messageSubscription = _webSocketService.messageStream.listen(
      (message) {
        debugPrint('[ChatViewModel] Received message via WebSocket: ${message.id}');
        
        // Only add message if it's not from current user
        if (message.id.isNotEmpty && message.senderId != _userId) {
          // Convert ChatMessageModel to ChatMessage
          final msg = ChatMessage(
            id: message.id,
            senderId: message.senderId,
            senderName: message.senderId, // Use senderId as senderName if not available
            senderAvatar: '',
            content: message.content,
            timestamp: DateTime.tryParse(message.time) ?? DateTime.now(),
            isOwn: false,
          );
          addMessage(msg);
        }
      },
      onError: (error) {
        debugPrint('[ChatViewModel] WebSocket message stream error: $error');
      },
    );

    // Listen to connection status changes
    _connectionSubscription = _webSocketService.connectionStatusStream.listen(
      (isConnected) {
        debugPrint('[ChatViewModel] WebSocket connection status: $isConnected');
        _isConnected = isConnected;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('[ChatViewModel] WebSocket connection stream error: $error');
      },
    );
  }

  void setUserId(String id) {
    _userId = id;
    notifyListeners();
  }

  void setUserName(String name) {
    _userName = name;
    notifyListeners();
  }

  void setApiService(ChatApiService apiService) {
    _apiService = apiService;
  }

  Future<void> loadConversations() async {
    if (_apiService == null) return;
    try {
      _loading = true;
      notifyListeners();

      final threads = await _apiService!.fetchThreads();
      _conversations.clear();

      for (var thread in threads) {
        if (thread is Map) {
          try {
            _conversations.add(ChatThread.fromJson(Map<String, dynamic>.from(thread)));
          } catch (e) {
            debugPrint('Error parsing thread: $e');
          }
        }
      }

      _loading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading conversations: $e');
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages(String threadId) async {
    if (_apiService == null) return;
    
    try {
      // Leave previous thread if any
      if (_currentThreadId != null && _currentThreadId != threadId) {
        _webSocketService.leaveThread(_currentThreadId!);
      }
      
      _currentThreadId = threadId;
      _loading = true;
      _messages.clear();
      notifyListeners();

      // Load message history from REST API
      final history = await _apiService!.fetchMessages(threadId: threadId);
      
      for (var msg in history) {
        if (msg is Map<String, dynamic>) {
          _messages.add(ChatMessage.fromJson(msg, isOwn: msg['senderId'] == _userId));
        } else if (msg is Map) {
          final jsonMap = Map<String, dynamic>.from(msg);
          _messages.add(ChatMessage.fromJson(jsonMap, isOwn: jsonMap['senderId'] == _userId));
        }
      }

      // Join thread via WebSocket for real-time updates
      _webSocketService.joinThread(threadId);
      
      _loading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading messages: $e');
      _loading = false;
      notifyListeners();
    }
  }

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void setConnectionStatus(bool connected) {
    _isConnected = connected;
    notifyListeners();
  }

  void setTypingIndicator(String userId, bool isTyping) {
    if (isTyping) {
      _typingUsers[userId] = true;
    } else {
      _typingUsers.remove(userId);
    }
    notifyListeners();
  }

  void clearTypingIndicators() {
    _typingUsers.clear();
    notifyListeners();
  }

  Future<void> sendMessage(String content, {String? reactedMessageId}) async {
    if (_currentThreadId == null) return;

    try {
      // Create message object
      final messageData = {
        'type': 'message',
        'action': 'send',
        'threadId': _currentThreadId,
        'content': content,
        'messageType': 'text',
        'timestamp': DateTime.now().toIso8601String(),
        if (reactedMessageId != null) 'reactedMessageId': reactedMessageId,
      };

      // Create local message for immediate UI update
      final localMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: _userId ?? 'unknown',
        senderName: _userName ?? 'You',
        senderAvatar: '',
        content: content,
        timestamp: DateTime.now(),
        isOwn: true,
      );

      addMessage(localMsg);

      // Send via WebSocket for real-time delivery
      if (_isConnected) {
        debugPrint('[ChatViewModel] Sending message via WebSocket');
        _webSocketService.sendMessage(
          threadId: _currentThreadId!,
          content: content,
          type: 'text',
        );
      } else {
        // Fallback to REST API if WebSocket is not connected
        debugPrint('[ChatViewModel] WebSocket not connected, using REST API fallback');
        if (_apiService != null) {
          await _apiService!.sendMessage(messageData);
        }
      }
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  /// Send typing indicator to WebSocket
  void sendTypingIndicator() {
    if (_currentThreadId != null && _isConnected) {
      _webSocketService.sendTypingIndicator(_currentThreadId!);
    }
  }

  /// Stop sending typing indicator
  void stopTypingIndicator() {
    if (_currentThreadId != null && _isConnected) {
      _webSocketService.stopTypingIndicator(_currentThreadId!);
    }
  }

  /// Cleanup resources
  void dispose() {
    _messageSubscription.cancel();
    _connectionSubscription.cancel();
    if (_currentThreadId != null) {
      _webSocketService.leaveThread(_currentThreadId!);
    }
    super.dispose();
  }
}
