import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/models.dart';

/// WebSocket Service for Real-time Chat Communication
/// Handles connection, disconnection, message streaming, and automatic reconnection
class WebSocketService {
  static final WebSocketService _instance = WebSocketService._internal();
  
  factory WebSocketService() {
    return _instance;
  }
  
  WebSocketService._internal();

  WebSocketChannel? _channel;
  late String _token;
  late String _baseUrl;
  bool _isConnected = false;
  bool _isConnecting = false;
  
  // Stream controllers for different event types
  late StreamController<ChatMessageModel> _messageStreamController;
  late StreamController<Map<String, dynamic>> _eventStreamController;
  late StreamController<bool> _connectionStatusController;

  // Streams exposed to listeners
  Stream<ChatMessageModel> get messageStream => _messageStreamController.stream;
  Stream<Map<String, dynamic>> get eventStream => _eventStreamController.stream;
  Stream<bool> get connectionStatusStream => _connectionStatusController.stream;
  
  bool get isConnected => _isConnected;
  
  // Reconnection settings
  int _reconnectAttempts = 0;
  final int _maxReconnectAttempts = 5;
  Timer? _reconnectTimer;
  final Duration _reconnectDelay = const Duration(seconds: 3);

  /// Initialize the WebSocket service with API token and base URL
  void initialize({required String token, required String baseUrl}) {
    _token = token;
    _baseUrl = baseUrl;
    
    _messageStreamController = StreamController<ChatMessageModel>.broadcast();
    _eventStreamController = StreamController<Map<String, dynamic>>.broadcast();
    _connectionStatusController = StreamController<bool>.broadcast();
    
    debugPrint('[WebSocket] Service initialized');
  }

  /// Connect to the WebSocket server
  Future<void> connect() async {
    if (_isConnected || _isConnecting) {
      debugPrint('[WebSocket] Already connected or connecting');
      return;
    }

    _isConnecting = true;

    try {
      // Convert http/https URL to ws/wss
      String wsUrl = _baseUrl.replaceFirst('http://', 'ws://').replaceFirst('https://', 'wss://');
      
      // Remove trailing slash if present
      if (wsUrl.endsWith('/')) {
        wsUrl = wsUrl.substring(0, wsUrl.length - 1);
      }
      
      // Add chat endpoint
      wsUrl = '$wsUrl/chat?token=$_token';
      
      debugPrint('[WebSocket] Connecting to: $wsUrl');
      
      _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
      
      // Wait for the connection to be established
      await _channel!.ready;
      
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;
      _reconnectTimer?.cancel();
      
      _connectionStatusController.add(true);
      debugPrint('[WebSocket] Connected successfully');
      
      // Start listening to messages
      _listenToMessages();
    } catch (e) {
      _isConnecting = false;
      debugPrint('[WebSocket] Connection failed: $e');
      _connectionStatusController.add(false);
      _attemptReconnect();
    }
  }

  /// Disconnect from the WebSocket server
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;
    
    try {
      await _channel?.sink.close();
      _isConnected = false;
      _isConnecting = false;
      _connectionStatusController.add(false);
      debugPrint('[WebSocket] Disconnected');
    } catch (e) {
      debugPrint('[WebSocket] Error during disconnect: $e');
    }
  }

  /// Send a message through WebSocket
  void sendMessage({
    required String threadId,
    required String content,
    String type = 'text',
    Map<String, dynamic>? metadata,
  }) {
    if (!_isConnected) {
      debugPrint('[WebSocket] Not connected, cannot send message');
      return;
    }

    try {
      final message = {
        'type': 'message',
        'action': 'send',
        'threadId': threadId,
        'content': content,
        'messageType': type,
        'metadata': metadata,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _channel?.sink.add(jsonEncode(message));
      debugPrint('[WebSocket] Message sent: $threadId');
    } catch (e) {
      debugPrint('[WebSocket] Error sending message: $e');
    }
  }

  /// Join a chat thread (subscribe to updates)
  void joinThread(String threadId) {
    if (!_isConnected) {
      debugPrint('[WebSocket] Not connected, cannot join thread');
      return;
    }

    try {
      final joinMessage = {
        'type': 'thread',
        'action': 'join',
        'threadId': threadId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _channel?.sink.add(jsonEncode(joinMessage));
      debugPrint('[WebSocket] Joined thread: $threadId');
    } catch (e) {
      debugPrint('[WebSocket] Error joining thread: $e');
    }
  }

  /// Leave a chat thread (stop receiving updates)
  void leaveThread(String threadId) {
    if (!_isConnected) {
      debugPrint('[WebSocket] Not connected, cannot leave thread');
      return;
    }

    try {
      final leaveMessage = {
        'type': 'thread',
        'action': 'leave',
        'threadId': threadId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _channel?.sink.add(jsonEncode(leaveMessage));
      debugPrint('[WebSocket] Left thread: $threadId');
    } catch (e) {
      debugPrint('[WebSocket] Error leaving thread: $e');
    }
  }

  /// Request typing indicator
  void sendTypingIndicator(String threadId) {
    if (!_isConnected) return;

    try {
      final typingMessage = {
        'type': 'typing',
        'action': 'start',
        'threadId': threadId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _channel?.sink.add(jsonEncode(typingMessage));
    } catch (e) {
      debugPrint('[WebSocket] Error sending typing indicator: $e');
    }
  }

  /// Stop typing indicator
  void stopTypingIndicator(String threadId) {
    if (!_isConnected) return;

    try {
      final typingMessage = {
        'type': 'typing',
        'action': 'stop',
        'threadId': threadId,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _channel?.sink.add(jsonEncode(typingMessage));
    } catch (e) {
      debugPrint('[WebSocket] Error stopping typing indicator: $e');
    }
  }

  /// Listen to incoming messages from WebSocket
  void _listenToMessages() {
    try {
      _channel?.stream.listen(
        (message) {
          _handleMessage(message);
        },
        onError: (error) {
          debugPrint('[WebSocket] Stream error: $error');
          _isConnected = false;
          _connectionStatusController.add(false);
          _attemptReconnect();
        },
        onDone: () {
          debugPrint('[WebSocket] Stream closed');
          _isConnected = false;
          _connectionStatusController.add(false);
          _attemptReconnect();
        },
      );
    } catch (e) {
      debugPrint('[WebSocket] Error setting up listener: $e');
      _attemptReconnect();
    }
  }

  /// Handle incoming messages
  void _handleMessage(dynamic message) {
    try {
      if (message is! String) {
        debugPrint('[WebSocket] Invalid message type: ${message.runtimeType}');
        return;
      }

      final data = jsonDecode(message) as Map<String, dynamic>;
      final messageType = data['type'] as String?;

      debugPrint('[WebSocket] Received message type: $messageType');

      switch (messageType) {
        case 'message':
          _handleChatMessage(data);
          break;
        case 'event':
          _eventStreamController.add(data);
          break;
        case 'typing':
          _eventStreamController.add(data);
          break;
        case 'error':
          debugPrint('[WebSocket] Server error: ${data['message']}');
          _eventStreamController.add(data);
          break;
        case 'pong':
          debugPrint('[WebSocket] Pong received');
          break;
        default:
          debugPrint('[WebSocket] Unknown message type: $messageType');
          _eventStreamController.add(data);
      }
    } catch (e) {
      debugPrint('[WebSocket] Error handling message: $e');
    }
  }

  /// Handle chat message
  void _handleChatMessage(Map<String, dynamic> data) {
    try {
      final messageData = data['message'] ?? data;
      final chatMessage = ChatMessageModel.fromJson(messageData);
      _messageStreamController.add(chatMessage);
      debugPrint('[WebSocket] Chat message received: ${chatMessage.id}');
    } catch (e) {
      debugPrint('[WebSocket] Error parsing chat message: $e');
    }
  }

  /// Attempt to reconnect with exponential backoff
  void _attemptReconnect() {
    if (_reconnectAttempts >= _maxReconnectAttempts) {
      debugPrint('[WebSocket] Max reconnection attempts reached');
      return;
    }

    _reconnectAttempts++;
    final delay = _reconnectDelay * _reconnectAttempts;
    
    debugPrint('[WebSocket] Reconnecting in ${delay.inSeconds}s (attempt $_reconnectAttempts/$_maxReconnectAttempts)');
    
    _reconnectTimer = Timer(delay, connect);
  }

  /// Send a ping to keep connection alive
  void sendPing() {
    if (!_isConnected) return;

    try {
      final pingMessage = {
        'type': 'ping',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      _channel?.sink.add(jsonEncode(pingMessage));
    } catch (e) {
      debugPrint('[WebSocket] Error sending ping: $e');
    }
  }

  /// Dispose the service
  void dispose() {
    _reconnectTimer?.cancel();
    _messageStreamController.close();
    _eventStreamController.close();
    _connectionStatusController.close();
    _channel?.sink.close();
    debugPrint('[WebSocket] Service disposed');
  }
}
