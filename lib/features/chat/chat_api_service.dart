import 'package:dio/dio.dart';

class ChatApiService {
  final Dio _dio;

  ChatApiService(this._dio);

  Future<List<dynamic>> fetchMessages({int page = 1, String? threadId}) async {
    try {
      String endpoint = '/messages';
      if (threadId != null && threadId.isNotEmpty) {
        endpoint = '/messages?threadId=$threadId';
      }
      final response = await _dio.get(endpoint, queryParameters: {'page': page});
      return response.data['data'] ?? response.data ?? [];
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> fetchThreads({int page = 1}) async {
    try {
      final response = await _dio.get('/messages/threads', queryParameters: {'page': page});
      return response.data['data'] ?? response.data ?? [];
    } catch (e) {
      // If threads endpoint doesn't exist, return empty list
      return [];
    }
  }

  Future<dynamic> sendMessage(Map<String, dynamic> message) async {
    try {
      final response = await _dio.post('/messages', data: message);
      return response.data;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> getRecipients() async {
    try {
      final response = await _dio.get('/messages/recipients');
      return response.data['data'] ?? [];
    } catch (e) {
      return [];
    }
  }
}
