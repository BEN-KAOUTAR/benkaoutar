import 'dart:typed_data';
import 'package:dio/dio.dart';
import '../models/models.dart';
import 'package:http_parser/http_parser.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  late final Dio _dio;

  ApiService._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: 'https://api-demo.intranet.ikenas.com/api',
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 45),
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

  /// Submit a PDF or image justification for an absence
  Future<AttendanceRecord?> submitJustification({
    required String attendanceId,
    String? filePath,
    Uint8List? fileBytes,
    required String fileName,
    String reason = '',
    String? oldAttachmentUrl,
    void Function(int, int)? onProgress,
  }) async {
    try {
      MultipartFile? attachment;
      final hasFilePath = filePath != null && filePath.isNotEmpty;
      final hasFileBytes = fileBytes != null && fileBytes.isNotEmpty;

      if (hasFilePath || hasFileBytes) {
        final ext = fileName.split('.').last.toLowerCase();
        MediaType? mediaType;
        if (ext == 'pdf') {
          mediaType = MediaType('application', 'pdf');
        } else if (ext == 'jpg' || ext == 'jpeg') {
          mediaType = MediaType('image', 'jpeg');
        } else if (ext == 'png') {
          mediaType = MediaType('image', 'png');
        }

        // Web compatibility: Use fromBytes if available (always for Web picker). 
        // Chrome fails with UnimplementedError if trying fromFile.
        if (fileBytes != null && fileBytes.isNotEmpty) {
          attachment = MultipartFile.fromBytes(fileBytes, filename: fileName, contentType: mediaType);
        } else if (filePath != null && filePath.isNotEmpty) {
          attachment = await MultipartFile.fromFile(filePath, filename: fileName, contentType: mediaType);
        }
      }

      final payload = <String, dynamic>{
        'reason': reason,
        'motif': reason, 
        'justificationReason': reason,
        'justificationText': reason,
        'justifiedByStudent': true,
        'hasJustification': true,
        'isJustified': true,
      };

      // Always use FormData (multipart/form-data) for the file
      final formDataMap = <String, dynamic>{};
      payload.forEach((k, v) => formDataMap[k] = v.toString());
      final formData = FormData.fromMap(formDataMap);
      
      if (attachment != null) {
        formData.files.add(MapEntry('attachment', attachment));
      } else if (oldAttachmentUrl != null && oldAttachmentUrl.isNotEmpty) {
        formData.fields.add(MapEntry('attachment', oldAttachmentUrl));
      }

      final response = await _dio.put(
        '/attendances/$attendanceId/justify', 
        data: formData,
        onSendProgress: onProgress,
        options: Options(
          sendTimeout: const Duration(seconds: 45),
          receiveTimeout: const Duration(seconds: 45),
          contentType: 'multipart/form-data',
          headers: {'Accept': 'application/json'},
        )
      );

      // --- SECONDARY SYNC ---
      // Force update the record using standard JSON PUT just in case the /justify multipart route 
      // fails to map the boolean or reason fields in Node.js
      try {
         await _dio.put(
            '/attendances/$attendanceId',
            data: payload, // Sending as raw application/json
         );
      } catch (e) {
         print('Secondary JSON sync failed, proceeding anyway: $e');
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map) {
          if (response.data['success'] == false) {
             throw Exception(response.data['message'] ?? 'Erreur Serveur');
          }
          final responseData = response.data['data'];
          if (responseData != null && responseData is Map<String, dynamic>) {
            return AttendanceRecord.fromJson(responseData);
          }
        }
        // If data is missing but status is success, return a partial object to signal success
        return AttendanceRecord(
          id: attendanceId,
          date: '',
          status: 'absent',
          motif: reason,
          justifiedByStudent: true,
        );
      }
      return null;
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
        final dynamic data = _handleResponseData(response);
        List history = [];
        String? globalStudentName;
        String? globalClassName;

        if (data is List) {
          history = data;
        } else if (data is Map) {
          // Debug: log top-level keys to understand API structure
          print('[PaymentAPI] Top-level keys: ${data.keys.toList()}');

          // Extract student name and class from the top-level response
          // Could be at data['student'], data['user'], or data['space']['student']
          if (data.containsKey('student') && data['student'] is Map) {
            final s = data['student'];
            if (s['user'] is Map) {
              globalStudentName = s['user']['fullName']?.toString() ?? s['user']['name']?.toString();
            }
            globalStudentName ??= s['fullName']?.toString() ?? s['name']?.toString();
            // Class might be nested in student
            if (s['class'] is Map) {
              globalClassName = (s['class'] as Map)['name']?.toString() ?? (s['class'] as Map)['label']?.toString();
            } else if (s['classe'] is Map) {
              globalClassName = (s['classe'] as Map)['name']?.toString() ?? (s['classe'] as Map)['label']?.toString();
            } else if (s['group'] is Map) {
              globalClassName = (s['group'] as Map)['name']?.toString() ?? (s['group'] as Map)['label']?.toString();
            } else if (s['affectation'] is Map) {
              final aff = s['affectation'];
              if (aff['class'] is Map) {
                globalClassName = aff['class']['name']?.toString();
              } else if (aff['classe'] is Map) globalClassName = aff['classe']['name']?.toString();
              else if (aff['group'] is Map) globalClassName = aff['group']['name']?.toString();
            }
            globalClassName ??= s['className']?.toString() ?? s['level']?.toString();
            if (globalClassName == null && s['classe'] is String) globalClassName = s['classe'].toString();
            if (globalClassName == null && s['class'] is String) globalClassName = s['class'].toString();
          }
          // Also check data['user']
          if (globalStudentName == null && data.containsKey('user') && data['user'] is Map) {
            globalStudentName = data['user']['fullName']?.toString() ?? data['user']['name']?.toString();
          }
          if (globalClassName == null) {
            if (data['class'] is Map) {
              globalClassName = (data['class'] as Map)['name']?.toString() ?? (data['class'] as Map)['label']?.toString();
            } else if (data['classe'] is Map) {
              globalClassName = (data['classe'] as Map)['name']?.toString() ?? (data['classe'] as Map)['label']?.toString();
            } else if (data['group'] is Map) {
              globalClassName = (data['group'] as Map)['name']?.toString() ?? (data['group'] as Map)['label']?.toString();
            } else if (data['affectation'] is Map) {
              final aff = data['affectation'];
              if (aff['class'] is Map) {
                globalClassName = aff['class']['name']?.toString();
              } else if (aff['classe'] is Map) globalClassName = aff['classe']['name']?.toString();
              else if (aff['group'] is Map) globalClassName = aff['group']['name']?.toString();
            }
            globalClassName ??= data['className']?.toString() ?? data['level']?.toString() ?? data['groupName']?.toString();
            if (globalClassName == null && data['classe'] is String) globalClassName = data['classe'].toString();
            if (globalClassName == null && data['class'] is String) globalClassName = data['class'].toString();
          }

          // Check nested structures (e.g. data['space']['payments'])
          if (data.containsKey('space') && data['space'] is Map) {
            final space = data['space'];
            print('[PaymentAPI] Space keys: ${(space as Map).keys.toList()}');
            history = space['history'] ?? space['payments'] ?? space['invoices'] ?? space['dues'] ?? space['scolarity'] ?? [];
            
            // Student info may also be in space
            if (globalStudentName == null && space.containsKey('student') && space['student'] is Map) {
              final s = space['student'];
              if (s['user'] is Map) {
                globalStudentName = s['user']['fullName']?.toString() ?? s['user']['name']?.toString();
              }
              globalStudentName ??= s['fullName']?.toString() ?? s['name']?.toString();
              if (globalClassName == null) {
                if (s['class'] is Map) globalClassName = (s['class'] as Map)['name']?.toString();
                if (s['group'] is Map) globalClassName ??= (s['group'] as Map)['name']?.toString();
                globalClassName ??= s['className']?.toString();
              }
            }
          }
          if (history.isEmpty) {
            history = data['history'] ?? data['payments'] ?? data['invoices'] ?? data['scolarity'] ?? data['dues'] ?? [];
          }
          if (history.isEmpty && data.containsKey('data') && data['data'] is List) {
            history = data['data'];
          }
        }

        if (history.isNotEmpty) {
          print('[PaymentAPI] First item keys: ${(history[0] as Map).keys.toList()}');
          print('[PaymentAPI] Global studentName=$globalStudentName, className=$globalClassName');
        }
        
        return history.map((json) {
          try {
            final payment = PaymentModel.fromJson(json);
            // Inject global student/class if missing from individual item
            return PaymentModel(
              id: payment.id,
              month: payment.month,
              amount: payment.amount,
              status: payment.status,
              date: payment.date,
              invoiceUrl: payment.invoiceUrl,
              childIds: payment.childIds,
              invoiceNumber: payment.invoiceNumber,
              studentName: payment.studentName ?? globalStudentName,
              className: payment.className ?? globalClassName,
              paymentMethod: payment.paymentMethod,
              year: payment.year,
              paymentType: payment.paymentType,
            );
          } catch (e) {
            print('Error parsing payment item: $e');
            return null;
          }
        }).whereType<PaymentModel>().toList();
      }
      throw Exception('Failed to load payments');
    } catch (e) {
      rethrow;
    }
  }

  Future<String?> downloadInternalFile(String endpoint, String savePath) async {
    try {
      final response = await _dio.download(
        endpoint,
        savePath,
        onReceiveProgress: (count, total) {
          if (total != -1) {
            print('[PaymentAPI] Download progress: ${(count / total * 100).toStringAsFixed(0)}%');
          }
        },
      );
      if (response.statusCode == 200) {
        return savePath;
      }
      return null;
    } catch (e) {
      print('[PaymentAPI] Internal download error: $e');
      rethrow;
    }
  }

  Future<String> downloadReceipt(String paymentId, String type) async {
    try {
      // Return relative endpoint for internal download or direct absolute URL for external.
      String normalizedType = type.toLowerCase();
      String category = 'receipts'; // Default
      
      if (normalizedType.contains('invoice') || normalizedType.contains('scolarit')) {
        category = 'invoices';
      } else if (normalizedType.contains('receipt') || normalizedType.contains('transport')) {
        category = 'receipts';
      }
      
      return '/payments/student/me/$category/$paymentId/download';
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

  Future<UserModel> getProfile() async {
    try {
      final response = await _dio.get('/auth/me');
      if (response.statusCode == 200) {
        return UserModel.fromJson(response.data);
      }
      throw Exception('Failed to load profile');
    } catch (e) {
      rethrow;
    }
  }

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

  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final response = await _dio.get('/dashboard/stats');
      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(response.data);
      }
      return {};
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getDashboardActivities() async {
    try {
      // Aggregate from multiple sources for a rich dashboard
      final results = await Future.wait([
        getPosts().catchError((_) => <PostModel>[]),
        getAbsences('me').catchError((_) => <AttendanceRecord>[]),
        // We can't easily call getGrades('me') here without returning List<GradeModel>
        // so we just fetch posts and absences for now as primary activities
      ]);

      final List<Map<String, dynamic>> activities = [];
      
      // Map Posts (News)
      final posts = results[0] as List<PostModel>;
      for (var post in posts.take(3)) {
        activities.add({
          'id': post.id,
          'type': 'news',
          'title': post.title.isNotEmpty ? post.title : 'Nouveauté',
          'content': post.content,
          'date': post.date,
          'icon': 'post',
        });
      }

      // Map Absences
      final absences = results[1] as List<AttendanceRecord>;
      for (var abs in absences.take(3)) {
        activities.add({
          'id': abs.id,
          'type': 'absence',
          'title': 'Absence / Retard',
          'content': '${abs.subjectName ?? "Session"} - ${abs.status}',
          'date': abs.date,
          'icon': 'absence',
        });
      }

      // Sort by date descending
      activities.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      
      return activities.take(5).toList();
    } catch (e) {
      return []; 
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
