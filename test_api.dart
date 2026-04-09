import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://api-demo.intranet.ikenas.com/api',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  );

  print('--- Login ---');
  String? token;

  try {
    final response = await dio.post('/auth/login', data: {
      'email': 'hiba@ikenas.com',
      'password': 'hiba123',
    });
    token = response.data['token'];
    dio.options.headers['Authorization'] = 'Bearer $token';
    print('Login OK, user: ${response.data['user']}');

    // Test /news endpoint
    print('\n--- Testing /news ---');
    try {
      final news = await dio.get('/news');
      print('NEWS SUCCESS: keys=${news.data.keys}');
      final data = news.data['data'];
      if (data is List && data.isNotEmpty) {
        print('First news item keys: ${data[0].keys}');
        print('Sample: ${data[0]}');
      } else {
        print('News data empty or not list: $data');
      }
    } catch(e) { print('NEWS FAIL: $e'); }

    // Test /messages endpoint  
    print('\n--- Testing /messages ---');
    try {
      final msgs = await dio.get('/messages');
      print('MESSAGES SUCCESS: keys=${msgs.data.keys}');
      final data = msgs.data['data'] ?? msgs.data;
      if (data is List && data.isNotEmpty) {
        print('First message keys: ${data[0].keys}');
        print('Sample: ${data[0]}');
      } else {
        print('Messages data: $data');
      }
    } catch(e) { print('MESSAGES FAIL: $e'); }

    // Test /auth/me for student profile
    print('\n--- Testing /auth/me ---');
    try {
      final me = await dio.get('/auth/me');
      print('AUTH/ME: ${me.data}');
    } catch(e) { print('AUTH/ME FAIL: $e'); }

  } catch(e) {
    print('Login FAIL: $e');
  }
}
