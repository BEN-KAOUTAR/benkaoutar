import 'package:dio/dio.dart';

void main() async {
  final dio = Dio(BaseOptions(
    baseUrl: 'https://api-demo.intranet.ikenas.com/api',
  ));

  try {
    print('Logging in...');
    final loginRes = await dio.post('/auth/login', data: {
      'email': 'ahmed.benani@email.com',
      'password': 'password123',
    });
    final token = loginRes.data['token']; // In your app it uses response.data['token']
    print('Token received. Fetching attendance...');

    dio.options.headers['Authorization'] = 'Bearer $token';

    final res1 = await dio.get('/attendances/me');
    print('/attendances/me success! Data: ${res1.data}');
  } on DioException catch (e) {
    if (e.response != null) {
      print('Error on /attendances/me : ${e.response?.statusCode} - ${e.response?.data}');
    } else {
      print('Network error: $e');
    }
  }

  try {
    final res2 = await dio.get('/absences');
    print('/absences success! Data: ${res2.data}');
  } catch (e) {
    if (e is DioException && e.response != null) {
      print('Error on /absences : ${e.response?.statusCode} - ${e.response?.data}');
    } else {
      print('Error on /absences : $e');
    }
  }
}
