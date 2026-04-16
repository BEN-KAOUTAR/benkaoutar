import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';

class ChatService {
  final String url;
  late WebSocketChannel _socket;
  bool _isConnected = false;

  ChatService(this.url);

  Future<void> connect() async {
    try {
      _socket = WebSocketChannel.connect(Uri.parse(url));
      await _socket.ready;
      _isConnected = true;
    } catch (e) {
      _isConnected = false;
      rethrow;
    }
  }

  void sendMessage(dynamic message) {
    if (!_isConnected) return;
    try {
      if (message is Map) {
        _socket.sink.add(jsonEncode(message));
      } else if (message is String) {
        _socket.sink.add(message);
      }
    } catch (e) {
      print('Error sending message: $e');
    }
  }

  Stream<dynamic> get onMessage => _socket.stream.map((event) {
    try {
      return jsonDecode(event);
    } catch (_) {
      return event;
    }
  });

  void disconnect() {
    _isConnected = false;
    _socket.sink.close();
  }
  
  bool get isConnected => _isConnected;
}
