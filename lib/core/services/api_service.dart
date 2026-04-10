import 'package:dio/dio.dart';
import '../models/models.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(
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

    // Add logging/interceptors if needed
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
    ));
  }

  // Set auth token dynamically
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  // Helper to extract data field from ApiResponse
  dynamic _handleResponseData(Response response) {
    if (response.data is Map && response.data.containsKey('data')) {
      return response.data['data'];
    }
    return response.data;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _dio.post('/auth/login', data: {
        'email': email,
        'password': password,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        final token = data['token'] ?? data['access_token'];
        if (token != null) {
          setToken(token);
        }
        return data; // Expected: { "token": "...", "user": { ... } }
      }
      throw Exception('Login failed: ${response.statusCode}');
    } catch (e) {
      rethrow;
    }
  }

  void clearToken() {
    _dio.options.headers.remove('Authorization');
  }

  // --- POSTS / FEED ---

  Future<List<PostModel>> getPosts() async {
    try {
      final response = await _dio.get('/news'); // Changed from /posts to /news
      if (response.statusCode == 200) {
        final List data = _handleResponseData(response);
        return data.map((json) => PostModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load news');
    } catch (e) {
      rethrow;
    }
  }

  Future<PostModel> updatePost(String id, Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/posts/$id', data: data);
      if (response.statusCode == 200) {
        return PostModel.fromJson(response.data);
      }
      throw Exception('Failed to update post');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> likePost(String id) async {
    try {
      final response = await _dio.post('/news/$id/like'); // Updated from /posts to /news
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      rethrow;
    }
  }

  Future<CommentModel> addComment(String postId, String content) async {
    try {
      final response = await _dio.post('/news/$postId/comments', data: { // Updated to plural /comments
        'content': content,
      });
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = _handleResponseData(response);
        return CommentModel.fromJson(data);
      }
      throw Exception('Failed to add comment');
    } catch (e) {
      rethrow;
    }
  }

  Future<bool> deletePost(String id) async {
    try {
      final response = await _dio.delete('/posts/$id');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      rethrow;
    }
  }

  // --- STUDENT / PARENT DATA ---

  Future<List<GradeModel>> getGrades(String studentId) async {
    try {
      // Fetch both exams and notes as some results might be in one or the other
      final responses = await Future.wait([
        _dio.get('/exams/my-results'),
        _dio.get('/notes/my-results').catchError((e) => Response(requestOptions: RequestOptions(path: ''), statusCode: 404, data: {'data': []})),
      ]);

      List<GradeModel> allGrades = [];
      
      for (final response in responses) {
        if (response.statusCode == 200) {
          final List data = _handleResponseData(response);
          allGrades.addAll(data.map((json) => GradeModel.fromJson(json)));
        }
      }
      
      // Sort by date descending if possible
      allGrades.sort((a, b) => b.date.compareTo(a.date));
      
      return allGrades;
    } catch (e) {
      // Fallback to one of them if the wait fails
      try {
        final response = await _dio.get('/exams/my-results');
        if (response.statusCode == 200) {
          final List data = _handleResponseData(response);
          return data.map((json) => GradeModel.fromJson(json)).toList();
        }
      } catch (_) {}
      rethrow;
    }
  }

  Future<List<AttendanceRecord>> getAbsences(String studentId) async {
    try {
      final response = await _dio.get('/attendances/me');
      if (response.statusCode == 200) {
        final List data = _handleResponseData(response);
        return data.map((json) => AttendanceRecord.fromJson(json)).toList();
      }
      throw Exception('Failed to load absences');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<HomeworkModel>> getHomework(String studentId) async {
    try {
      // Swagger: /assignments is the correct route for student assignments
      final response = await _dio.get('/assignments');
      if (response.statusCode == 200) {
        final List data = _handleResponseData(response);
        return data.map((json) => HomeworkModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load homework');
    } catch (e) {
      rethrow;
    }
  }

  Future<HomeworkModel> updateHomeworkStatus(String id, HomeworkStatus status) async {
    try {
      final response = await _dio.patch('/homework/$id', data: {
        'status': status.toString().split('.').last,
      });
      if (response.statusCode == 200) {
        return HomeworkModel.fromJson(response.data);
      }
      throw Exception('Failed to update homework');
    } catch (e) {
      rethrow;
    }
  }

  // --- PAYMENTS ---

  Future<List<PaymentModel>> getPayments() async {
    try {
      final response = await _dio.get('/payments/student/me/space');
      if (response.statusCode == 200) {
        final Map<String, dynamic> dataMap = _handleResponseData(response);
        final List history = dataMap['history'] ?? [];
        return history.map((json) => PaymentModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load payments');
    } catch (e) {
      rethrow;
    }
  }

  Future<String> downloadReceipt(String paymentId, String type) async {
    try {
      final response = await _dio.get('/payments/$paymentId/receipt', queryParameters: {'type': type});
      if (response.statusCode == 200) {
        return response.data['url'] ?? '';
      }
      throw Exception('Failed to get receipt URL');
    } catch (e) {
      rethrow;
    }
  }

  // --- MESSAGING (replaces chat/threads) ---

  Future<List<ChatThreadModel>> getChatThreads() async {
    try {
      // Swagger: /messages is the correct endpoint for the messaging inbox
      final response = await _dio.get('/messages');
      if (response.statusCode == 200) {
        final List data = _handleResponseData(response);
        return data.map((json) => ChatThreadModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load messages');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ChatMessageModel>> getMessages(String threadId) async {
    try {
      // Fetch individual message detail (thread replies)
      final response = await _dio.get('/messages/$threadId');
      if (response.statusCode == 200) {
        final data = _handleResponseData(response);
        if (data is List) {
          return data.map((json) => ChatMessageModel.fromJson(json)).toList();
        }
        // Single message response
        return [ChatMessageModel.fromJson(data)];
      }
      throw Exception('Failed to load messages');
    } catch (e) {
      rethrow;
    }
  }

  Future<ChatMessageModel> sendMessage(String threadId, String content, String type) async {
    try {
      // Swagger: /messages/:id/reply
      final response = await _dio.post('/messages/$threadId/reply', data: {
        'content': content,
        'type': type,
      });
      if (response.statusCode == 201 || response.statusCode == 200) {
        return ChatMessageModel.fromJson(_handleResponseData(response));
      }
      throw Exception('Failed to send message');
    } catch (e) {
      rethrow;
    }
  }

  // --- TRANSPORT / LOCATION ---

  Future<BusLocationModel> getBusLocation(String studentId) async {
    try {
      final response = await _dio.get('/transport/bus-location', queryParameters: {'studentId': studentId});
      if (response.statusCode == 200) {
        return BusLocationModel.fromJson(response.data);
      }
      throw Exception('Failed to load bus location');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<LocationHistoryRecord>> getLocationHistory(String studentId) async {
    try {
      final response = await _dio.get('/transport/history', queryParameters: {'studentId': studentId});
      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((json) => LocationHistoryRecord.fromJson(json)).toList();
      }
      throw Exception('Failed to load location history');
    } catch (e) {
      rethrow;
    }
  }

  // --- NOTIFICATIONS ---

  Future<List<NotificationModel>> getNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      if (response.statusCode == 200) {
        final List data = _handleResponseData(response);
        return data.map((json) => NotificationModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load notifications');
    } catch (e) {
      rethrow;
    }
  }

  Future<void> markNotificationRead(String id) async {
    try {
      // The API uses /notifications/read (PUT/PATCH) according to Swagger
      await _dio.post('/notifications/read', data: {'id': id});
    } catch (e) {
      // If ID-based fails, try just the endpoint (some APIs ignore ID if provided in other ways)
      try {
        await _dio.post('/notifications/mark-all-read');
      } catch (_) {
        rethrow;
      }
    }
  }

  Future<void> markAllNotificationsRead() async {
    try {
      await _dio.post('/notifications/mark-all-read');
    } catch (e) {
      rethrow;
    }
  }

  // --- PROFILE ---

  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.patch('/profile', data: data);
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }
      throw Exception('Failed to update profile');
    } catch (e) {
      rethrow;
    }
  }


  // --- DASHBOARD ---

  Future<List<StudentModel>> getChildren() async {
    try {
      // For student role, we can get profile info or use /payments/student/me/space
      final response = await _dio.get('/payments/student/me/space');
      if (response.statusCode == 200) {
        final dataMap = _handleResponseData(response);
        final studentJson = dataMap['student'];
        if (studentJson != null) {
          return [StudentModel.fromJson(studentJson)];
        }
        return [];
      }
      throw Exception('Failed to load children data');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getDashboardActivities() async {
    try {
      final response = await _dio.get('/dashboard/activities');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return []; // Return empty on non-200
    } catch (e) {
      return []; // Silently fail for dashboard widgets
    }
  }

  Future<List<Map<String, dynamic>>> getGradeEvolution({
    required String studentId,
    required String year,
    required String semester,
  }) async {
    try {
      final response = await _dio.get('/dashboard/evolution', queryParameters: {
        'studentId': studentId,
        'year': year,
        'semester': semester,
      });
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // --- BEHAVIOR ---

  Future<Map<String, dynamic>> getBehaviorSummary(String studentId) async {
    try {
      final response = await _dio.get('/students/$studentId/behavior/summary');
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load behavior summary');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBehaviorHistory(String studentId) async {
    try {
      final response = await _dio.get('/students/$studentId/behavior/history');
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      throw Exception('Failed to load behavior history');
    } catch (e) {
      rethrow;
    }
  }

  // --- CALENDAR & EVENTS ---

  Future<List<EventModel>> getCalendarEvents({
    required String studentId,
    required int month,
    required int year,
  }) async {
    try {
      final response = await _dio.get('/calendar/events', queryParameters: {
        'studentId': studentId,
        'month': month,
        'year': year,
      });
      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((json) => EventModel.fromJson(json)).toList();
      }
      throw Exception('Failed to load calendar events');
    } catch (e) {
      rethrow;
    }
  }

  // --- SECURITY & GEOFENCING ---

  Future<Map<String, dynamic>> getSecurityStatus(String studentId) async {
    try {
      final response = await _dio.get('/security/status', queryParameters: {'studentId': studentId});
      if (response.statusCode == 200) {
        return response.data;
      }
      throw Exception('Failed to load security status');
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getSecurityAlerts(String studentId) async {
    try {
      final response = await _dio.get('/security/alerts', queryParameters: {'studentId': studentId});
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(response.data);
      }
      throw Exception('Failed to load security alerts');
    } catch (e) {
      rethrow;
    }
  }

  // --- TIMETABLE ---

  Future<List<Map<String, dynamic>>> getTimetable(String studentId) async {
    try {
      final response = await _dio.get('/schedules/my-schedule-student');
      if (response.statusCode == 200) {
        final List data = _handleResponseData(response);
        
        // Map API objects to UI strings
        return data.map((item) {
          final Map<String, dynamic> mapped = Map<String, dynamic>.from(item as Map);
          
          // Time mapping
          mapped['time'] = mapped['startTime'] ?? '00:00';
          
          // Subject mapping
          if (mapped['subject'] is Map) {
            mapped['subject'] = mapped['subject']['name'] ?? 'Subject';
          }
          
          // Teacher mapping
          if (mapped['teacher'] is Map) {
            final user = mapped['teacher']['user'];
            if (user is Map) {
              mapped['teacher'] = user['fullName'] ?? user['name'] ?? 'Teacher';
            } else {
              mapped['teacher'] = 'Teacher';
            }
          }
          
          return mapped;
        }).toList();
      }
      throw Exception('Failed to load timetable');
    } catch (e) {
      rethrow;
    }
  }

  // --- ERROR HANDLING HELPER ---
  String getLocalizedErrorMessage(dynamic error) {
    if (error is DioException) {
      if (error.type == DioExceptionType.connectionError || 
          error.type == DioExceptionType.connectionTimeout) {
        return 'server_down_or_no_internet';
      }
      
      final status = error.response?.statusCode;
      switch (status) {
        case 401: return 'unauthorized';
        case 403: return 'forbidden';
        case 404: return 'resource_not_found';
        case 500: return 'internal_server_error';
        default: return 'something_went_wrong';
      }
    }
    return 'unknown_error';
  }
}
