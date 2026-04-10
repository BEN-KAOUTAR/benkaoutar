import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

enum HomeworkStatus { notStarted, inProgress, done, late }
enum UserRole { parent, teacher }
enum IconType { location, grade, absence, payment, post, message, info }

class UserModel {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? avatarUrl;
  final int? avatarIndex;
  final String? phone;
  final List<String> childrenIds; // for parent
  final List<String> classIds; // for teacher
  final String? schoolName;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.avatarIndex,
    this.phone,
    this.childrenIds = const [],
    this.classIds = const [],
    this.schoolName,
  });

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    UserRole? role,
    String? avatarUrl,
    int? avatarIndex,
    String? phone,
    List<String>? childrenIds,
    List<String>? classIds,
    String? schoolName,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      phone: phone ?? this.phone,
      childrenIds: childrenIds ?? this.childrenIds,
      classIds: classIds ?? this.classIds,
      schoolName: schoolName ?? this.schoolName,
    );
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['fullName'] ?? json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] == 'teacher' ? UserRole.teacher : UserRole.parent,
      avatarUrl: processImageUrl(json['avatarUrl']),
      avatarIndex: json['avatarIndex'],
      phone: json['phone'],
      childrenIds: List<String>.from(json['childrenIds'] ?? []),
      classIds: List<String>.from(json['classIds'] ?? []),
      schoolName: json['schoolName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role.toString().split('.').last,
      'avatarUrl': avatarUrl,
      'avatarIndex': avatarIndex,
      'phone': phone,
      'childrenIds': childrenIds,
      'classIds': classIds,
      'schoolName': schoolName,
    };
  }
}

class ChildModel {
  final String id;
  final String name;
  final String className;
  final String? avatarUrl;
  final int age;
  final double attendanceRate;
  final double averageGrade;
  final String status; // 'at_school', 'on_way', 'at_home'
  final String lastUpdate;
  final int lateHomeworkCount;
  final String? nextExamDate;
  final String? nextExamSubject;

  ChildModel({
    required this.id,
    required this.name,
    required this.className,
    this.avatarUrl,
    required this.age,
    required this.attendanceRate,
    required this.averageGrade,
    this.status = 'at_school',
    this.lastUpdate = '',
    this.lateHomeworkCount = 0,
    this.nextExamDate,
    this.nextExamSubject,
  });

  ChildModel copyWith({
    String? id,
    String? name,
    String? className,
    String? avatarUrl,
    int? age,
    double? attendanceRate,
    double? averageGrade,
    String? status,
    String? lastUpdate,
    int? lateHomeworkCount,
    String? nextExamDate,
    String? nextExamSubject,
  }) {
    return ChildModel(
      id: id ?? this.id,
      name: name ?? this.name,
      className: className ?? this.className,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      age: age ?? this.age,
      attendanceRate: attendanceRate ?? this.attendanceRate,
      averageGrade: averageGrade ?? this.averageGrade,
      status: status ?? this.status,
      lastUpdate: lastUpdate ?? this.lastUpdate,
      lateHomeworkCount: lateHomeworkCount ?? this.lateHomeworkCount,
      nextExamDate: nextExamDate ?? this.nextExamDate,
      nextExamSubject: nextExamSubject ?? this.nextExamSubject,
    );
  }
}

class GradeModel {
  final String id;
  final String subject;
  final double grade;
  final double maxGrade;
  final double coefficient;
  final String date;
  final String type; // 'exam', 'devoir', 'controle'
  final String? comment;
  final double? classAverage;
  final String? semester;
  final String? title;
  final int? rank;
  final int? classSize;

  GradeModel({
    required this.id,
    required this.subject,
    required this.grade,
    required this.maxGrade,
    required this.coefficient,
    required this.date,
    required this.type,
    this.comment,
    this.classAverage,
    this.semester,
    this.title,
    this.rank,
    this.classSize,
  });

  GradeModel copyWith({
    String? id,
    String? subject,
    double? grade,
    double? maxGrade,
    double? coefficient,
    String? date,
    String? type,
    String? comment,
    double? classAverage,
    String? semester,
    String? title,
    int? rank,
    int? classSize,
  }) {
    return GradeModel(
      id: id ?? this.id,
      subject: subject ?? this.subject,
      grade: grade ?? this.grade,
      maxGrade: maxGrade ?? this.maxGrade,
      coefficient: coefficient ?? this.coefficient,
      date: date ?? this.date,
      type: type ?? this.type,
      comment: comment ?? this.comment,
      classAverage: classAverage ?? this.classAverage,
      semester: semester ?? this.semester,
      title: title ?? this.title,
      rank: rank ?? this.rank,
      classSize: classSize ?? this.classSize,
    );
  }

  factory GradeModel.fromJson(Map<String, dynamic> json) {
    // Extract subject name from various possible structures
    String subjectName = '';
    if (json['subject'] is Map) {
      subjectName = json['subject']['name'] ?? json['subject']['title'] ?? '';
    } else if (json['matiere'] is Map) {
      subjectName = json['matiere']['name'] ?? json['matiere']['title'] ?? '';
    } else {
      subjectName = json['subject'] ?? json['subjectName'] ?? json['matiere'] ?? '';
    }

    // Infer semester from date if not provided
    String semester = json['semester']?.toString() ?? '';
    final rawDate = json['date'] ?? json['createdAt'] ?? json['passedAt'] ?? '';
    if (semester.isEmpty && rawDate.isNotEmpty) {
      try {
        final dt = DateTime.parse(rawDate);
        semester = (dt.month >= 9 || dt.month <= 1) ? "1" : "2";
      } catch (_) {}
    }

    // Try all possible grade field names
    double gradeValue = 0.0;
    for (final key in ['note', 'score', 'mark', 'grade', 'result', 'value', 'obtainedGrade', 'obtained']) {
      if (json[key] != null) {
        gradeValue = (json[key] as num).toDouble();
        break;
      }
    }

    // Try all possible title/name field names
    String? title;
    for (final key in ['title', 'name', 'label', 'examName', 'description', 'evaluationName']) {
      if (json[key] != null && json[key].toString().isNotEmpty) {
        title = json[key].toString();
        break;
      }
    }

    return GradeModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      subject: subjectName,
      grade: gradeValue,
      maxGrade: (json['maxGrade'] ?? json['total'] ?? json['outOf'] ?? 20 as num).toDouble(),
      coefficient: (json['coefficient'] as num?)?.toDouble() ?? 1.0,
      date: rawDate,
      type: json['type'] ?? json['evaluationType'] ?? 'exam',
      comment: json['comment'] ?? json['appreciation'] ?? json['observation'],
      classAverage: (json['classAverage'] ?? json['moyenne'] ?? json['average'] as num?)?.toDouble(),
      semester: semester,
      title: title,
      rank: (json['rank'] ?? json['classement'] ?? json['position'] as num?)?.toInt(),
      classSize: (json['classSize'] ?? json['totalStudents'] ?? json['effectif'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'grade': grade,
      'maxGrade': maxGrade,
      'coefficient': coefficient,
      'date': date,
      'type': type,
      'comment': comment,
      'classAverage': classAverage,
      'semester': semester,
      'title': title,
      'rank': rank,
      'classSize': classSize,
    };
  }
}

class AttendanceRecord {
  final String date;
  final String status; // 'present', 'absent', 'late', 'sick'
  final String? motif;
  final String? rawStatus;
  final String? startTime;
  final String? endTime;
  final String? subjectName;
  final String? sessionName;

  AttendanceRecord({
    required this.date,
    required this.status,
    this.motif,
    this.rawStatus,
    this.startTime,
    this.endTime,
    this.subjectName,
    this.sessionName,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    // Standardize status: absent_justifie, absent_non_justifie, retard, present
    String rawStatus = (json['status'] ?? json['attendanceStatus'] ?? json['type'] ?? 'present').toString().toLowerCase();
    
    // Normalize status strings
    String finalStatus = 'present';
    if (rawStatus.contains('absent')) {
      finalStatus = 'absent';
    } else if (rawStatus.contains('retard') || rawStatus.contains('late')) {
      finalStatus = 'late';
    } else if (rawStatus.contains('sick') || rawStatus.contains('malade')) {
      finalStatus = 'sick';
    }

    // Extract subject/session info
    String? subjectName;
    String? sessionName;
    if (json['session'] is Map) {
      final session = json['session'];
      sessionName = session['name'] ?? session['title'];
      if (session['subject'] is Map) {
        subjectName = session['subject']['name'] ?? session['subject']['title'];
      }
    } else if (json['matiere'] is Map) {
      subjectName = json['matiere']['name'] ?? json['matiere']['title'];
    }
    
    // Fallback subject mapping - handle Map or String
    if (subjectName == null) {
      final rawSubject = json['subjectName'] ?? json['subject'] ?? json['matiere'];
      if (rawSubject is Map) {
        subjectName = rawSubject['name'] ?? rawSubject['title'] ?? rawSubject['nom'];
      } else if (rawSubject is String && rawSubject.isNotEmpty) {
        subjectName = rawSubject;
      }
    }

    // Also extract timing from session if available
    String? startTime = json['startTime'] ?? json['hourStart'] ?? json['start'];
    String? endTime = json['endTime'] ?? json['hourEnd'] ?? json['end'];
    if (json['session'] is Map) {
      final session = json['session'];
      startTime ??= session['startTime'] ?? session['hourStart'] ?? session['start'];
      endTime ??= session['endTime'] ?? session['hourEnd'] ?? session['end'];
    }

    return AttendanceRecord(
      date: json['date'] ?? json['createdAt'] ?? json['passedAt'] ?? '',
      status: finalStatus,
      motif: json['motif'] ?? json['justification'] ?? json['reason'],
      rawStatus: rawStatus,
      startTime: startTime,
      endTime: endTime,
      subjectName: subjectName,
      sessionName: sessionName,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'status': status,
      'motif': motif,
    };
  }
}

class PostModel {
  final String id;
  final String authorName;
  final String authorRole;
  final String? authorAvatar;
  final String title; // Added for homework
  final String content;
  final String? imageUrl;
  final String date;
  final int likes;
  final int comments;
  final bool isLiked;
  final bool isSaved;
  final bool isEvent;
  final bool isUrgent;
  final bool? isCompleted; // Added for homework
  final String? eventDate;
  final List<CommentModel> commentsList;

  PostModel({
    required this.id,
    required this.authorName,
    required this.authorRole,
    this.authorAvatar,
    this.title = '',
    required this.content,
    this.imageUrl,
    required this.date,
    this.likes = 0,
    this.comments = 0,
    this.isLiked = false,
    this.isSaved = false,
    this.isEvent = false,
    this.isUrgent = false,
    this.isCompleted = false,
    this.eventDate,
    this.commentsList = const [],
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    String authorName = json['authorName'] ?? '';
    String authorRole = json['authorRole'] ?? '';
    String? authorAvatar = json['authorAvatar'];

    if (json['author'] is Map) {
      final author = json['author'];
      authorName = author['fullName'] ?? author['name'] ?? authorName;
      authorRole = author['role'] ?? authorRole;
      authorAvatar = author['avatar'] ?? authorAvatar;
    }

    return PostModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      authorName: authorName,
      authorRole: authorRole,
      authorAvatar: processImageUrl(authorAvatar),
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      imageUrl: processImageUrl(json['imageUrl'] ?? json['image']),
      date: json['date'] ?? json['createdAt'] ?? '',
      likes: json['likesCount'] ?? (json['likes'] is List ? (json['likes'] as List).length : 0),
      comments: json['commentsCount'] ?? (json['comments'] is List ? (json['comments'] as List).length : 0),
      isLiked: json['isLiked'] ?? false,
      isSaved: json['isSaved'] ?? false,
      isEvent: json['isEvent'] ?? (json['type'] == 'event'),
      isUrgent: json['isUrgent'] ?? false,
      isCompleted: json['isCompleted'] ?? false,
      eventDate: json['eventDate'],
      commentsList: (json['comments'] is List && json['comments'].isNotEmpty && json['comments'][0] is Map)
              ? (json['comments'] as List).map((c) => CommentModel.fromJson(c)).toList()
              : const [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorRole': authorRole,
      'authorAvatar': authorAvatar,
      'title': title,
      'content': content,
      'imageUrl': imageUrl,
      'date': date,
      'likes': likes,
      'comments': comments,
      'isLiked': isLiked,
      'isSaved': isSaved,
      'isEvent': isEvent,
      'isUrgent': isUrgent,
      'isCompleted': isCompleted,
      'eventDate': eventDate,
      'commentsList': commentsList.map((c) => c.toJson()).toList(),
    };
  }

  PostModel copyWith({
    String? id,
    String? authorName,
    String? authorRole,
    String? authorAvatar,
    String? title,
    String? content,
    String? imageUrl,
    String? date,
    int? likes,
    int? comments,
    bool? isLiked,
    bool? isSaved,
    bool? isEvent,
    bool? isUrgent,
    bool? isCompleted,
    String? eventDate,
    List<CommentModel>? commentsList,
  }) {
    return PostModel(
      id: id ?? this.id,
      authorName: authorName ?? this.authorName,
      authorRole: authorRole ?? this.authorRole,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      title: title ?? this.title,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      date: date ?? this.date,
      likes: likes ?? this.likes,
      comments: comments ?? this.comments,
      isLiked: isLiked ?? this.isLiked,
      isSaved: isSaved ?? this.isSaved,
      isEvent: isEvent ?? this.isEvent,
      isUrgent: isUrgent ?? this.isUrgent,
      isCompleted: isCompleted ?? this.isCompleted,
      eventDate: eventDate ?? this.eventDate,
      commentsList: commentsList ?? this.commentsList,
    );
  }
}

String? processImageUrl(dynamic img) {
  if (img == null || img.toString().trim().isEmpty) return null;
  String url = img.toString();
  if (url.startsWith('http')) return url;
  if (url.startsWith('/')) {
    return 'https://api-demo.intranet.ikenas.com$url';
  }
  return 'https://api-demo.intranet.ikenas.com/$url';
}

class CommentModel {
  final String id;
  final String authorName;
  final String? authorAvatar;
  final String content;
  final String date;

  CommentModel({
    required this.id,
    required this.authorName,
    this.authorAvatar,
    required this.content,
    required this.date,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    String authorName = json['authorName'] ?? '';
    String? authorAvatar = json['authorAvatar'];

    if (json['author'] is Map) {
      final author = json['author'];
      authorName = author['fullName'] ?? author['name'] ?? authorName;
      authorAvatar = author['avatar'] ?? authorAvatar;
    }

    return CommentModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      authorName: authorName,
      authorAvatar: processImageUrl(authorAvatar),
      content: json['content'] ?? '',
      date: json['date'] ?? json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'authorName': authorName,
      'authorAvatar': authorAvatar,
      'content': content,
      'date': date,
    };
  }
}


class ChatThreadModel {
  final String id;
  final String contactName;
  final String contactRole;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;
  final bool onlyAdminsCanMessage;
  final String? avatarUrl;

  ChatThreadModel({
    required this.id,
    required this.contactName,
    required this.contactRole,
    required this.lastMessage,
    required this.lastTime,
    this.unreadCount = 0,
    this.onlyAdminsCanMessage = false,
    this.avatarUrl,
  });

  factory ChatThreadModel.fromJson(Map<String, dynamic> json) {
    return ChatThreadModel(
      id: json['id']?.toString() ?? '',
      contactName: json['contactName'] ?? '',
      contactRole: json['contactRole'] ?? '',
      lastMessage: json['lastMessage'] ?? '',
      lastTime: json['lastTime'] ?? '',
      unreadCount: json['unreadCount'] ?? 0,
      onlyAdminsCanMessage: json['onlyAdminsCanMessage'] ?? false,
      avatarUrl: processImageUrl(json['avatarUrl']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'contactName': contactName,
      'contactRole': contactRole,
      'lastMessage': lastMessage,
      'lastTime': lastTime,
      'unreadCount': unreadCount,
      'onlyAdminsCanMessage': onlyAdminsCanMessage,
      'avatarUrl': avatarUrl,
    };
  }
}

class ChatMessageModel {
  final String id;
  final String threadId;
  final String senderId;
  final String content;
  final String time;
  final bool isMe;
  final String type; // 'text', 'image', 'video', 'document', 'voice'
  final Map<String, dynamic>? metadata; // for duration, size, etc.

  ChatMessageModel({
    required this.id,
    required this.threadId,
    required this.senderId,
    required this.content,
    required this.time,
    this.isMe = false,
    this.type = 'text',
    this.metadata,
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    String senderId = json['senderId']?.toString() ?? '';
    // Handle nested sender object
    if (json['sender'] is Map) {
      senderId = (json['sender']['id'] ?? json['sender']['_id'])?.toString() ?? senderId;
    }

    return ChatMessageModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      threadId: (json['threadId'] ?? json['message_id'])?.toString() ?? '',
      senderId: senderId,
      content: json['content'] ?? '',
      time: json['time'] ?? json['createdAt'] ?? '',
      isMe: json['isMe'] ?? false,
      type: json['type'] ?? 'text',
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'threadId': threadId,
      'senderId': senderId,
      'content': content,
      'time': time,
      'isMe': isMe,
      'type': type,
      'metadata': metadata,
    };
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final String time;
  final bool isMe;
  final bool isRead;

  MessageModel({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.time,
    this.isMe = false,
    this.isRead = false,
  });
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String type;
  final String? location;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.type,
    this.location,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      type: json['type'] ?? '',
      location: json['location'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'type': type,
      'location': location,
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? date,
    String? time,
    String? type,
    String? location,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
      location: location ?? this.location,
    );
  }
}

class HomeworkModel {
  final String id, subject, title, description, dueDate;
  final HomeworkStatus status;
  final String? attachment;
  final String? teacherComment;
  final String? teacherName;

  HomeworkModel({
    required this.id,
    required this.subject,
    required this.title,
    required this.description,
    required this.dueDate,
    this.status = HomeworkStatus.notStarted,
    this.attachment,
    this.teacherComment,
    this.teacherName,
  });

  factory HomeworkModel.fromJson(Map<String, dynamic> json) {
    return HomeworkModel(
      id: json['id']?.toString() ?? '',
      subject: json['subject'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: json['dueDate'] ?? '',
      status: _statusFromString(json['status']),
      attachment: json['attachment'],
      teacherComment: json['teacherComment'],
      teacherName: json['teacherName'],
    );
  }

  static HomeworkStatus _statusFromString(String? status) {
    switch (status) {
      case 'notStarted': return HomeworkStatus.notStarted;
      case 'inProgress': return HomeworkStatus.inProgress;
      case 'done': return HomeworkStatus.done;
      case 'late': return HomeworkStatus.late;
      default: return HomeworkStatus.notStarted;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subject': subject,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'status': status.toString().split('.').last,
      'attachment': attachment,
      'teacherComment': teacherComment,
      'teacherName': teacherName,
    };
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String time;
  final String type;
  final IconType iconType;
  final bool isRead;
  final bool? isUrgent;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    required this.time,
    required this.type,
    required this.iconType,
    this.isRead = false,
    this.isUrgent = false,
  });

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? time,
    String? type,
    IconType? iconType,
    bool? isRead,
    bool? isUrgent,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      time: time ?? this.time,
      type: type ?? this.type,
      iconType: iconType ?? this.iconType,
      isRead: isRead ?? this.isRead,
      isUrgent: isUrgent ?? this.isUrgent,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      title: json['title'] ?? '',
      body: json['message'] ?? json['body'] ?? '',
      time: json['createdAt'] ?? json['time'] ?? '',
      type: json['type'] ?? '',
      iconType: _iconTypeFromString(json['type']), // Use type to infer icon
      isRead: (json['readBy'] as List?)?.isNotEmpty ?? json['isRead'] ?? false,
      isUrgent: json['isUrgent'] ?? (json['type'] == 'exam_scheduled'),
    );
  }

  static IconType _iconTypeFromString(String? type) {
    switch (type) {
      case 'location': return IconType.location;
      case 'grade': return IconType.grade;
      case 'absence': return IconType.absence;
      case 'payment': return IconType.payment;
      case 'post': return IconType.post;
      case 'message': return IconType.message;
      default: return IconType.info;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'time': time,
      'type': type,
      'iconType': iconType.toString().split('.').last,
      'isRead': isRead,
      'isUrgent': isUrgent,
    };
  }
}

class ClassModel {
  final String id;
  final String name;
  final String? level;
  final int studentCount;
  final double? attendanceRate;
  final double? classAverage;
  final List<StudentModel> students;

  ClassModel({
    required this.id,
    required this.name,
    this.level,
    required this.studentCount,
    this.attendanceRate,
    this.classAverage,
    this.students = const [],
  });
}

class StudentModel {
  final String id;
  final String name;
  final double average;
  final String? massarCode;
  final double? attendanceRate;
  final String? parentName;
  final String? parentPhone;
  final String? behavior;
  final String? birthDate;
  final int? age;
  final String? className;
  final String? group;
  final String? avatarUrl;

  StudentModel({
    required this.id,
    required this.name,
    required this.average,
    this.massarCode,
    this.attendanceRate,
    this.parentName,
    this.parentPhone,
    this.behavior,
    this.birthDate,
    this.age,
    this.className,
    this.group,
    this.avatarUrl,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    String studentName = json['name'] ?? '';
    if (json['user'] is Map) {
      studentName = json['user']['fullName'] ?? json['user']['name'] ?? studentName;
    }

    String className = json['className'] ?? '';
    if (json['classe'] is Map) {
      className = json['classe']['name'] ?? className;
    }

    return StudentModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      name: studentName,
      average: (json['average'] as num?)?.toDouble() ?? 0.0,
      massarCode: json['matricule'] ?? json['massarCode'],
      attendanceRate: (json['attendanceRate'] as num?)?.toDouble(),
      parentName: json['parentName'],
      parentPhone: json['parentPhone'],
      behavior: json['behavior'],
      birthDate: json['dateOfBirth'] ?? json['birthDate'],
      age: json['age'],
      className: className,
      group: json['group'],
      avatarUrl: processImageUrl(json['avatarUrl'] ?? json['avatar']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'average': average,
      'massarCode': massarCode,
      'attendanceRate': attendanceRate,
      'parentName': parentName,
      'parentPhone': parentPhone,
      'behavior': behavior,
      'birthDate': birthDate,
      'age': age,
      'className': className,
      'group': group,
      'avatarUrl': avatarUrl,
    };
  }
}

class TeacherActivityModel {
  final String id;
  final String title;
  final String? description;
  final String? type; // for older screens
  final String? detail; // for older screens
  final String date; // for older screens
  final String? time;
  final IconData? icon;
  final Color? color;

  TeacherActivityModel({
    required this.id,
    required this.title,
    this.description,
    this.type,
    this.detail,
    required this.date,
    this.time,
    this.icon,
    this.color,
  });
}
class BusLocationModel {
  final String id;
  final double latitude;
  final double longitude;
  final double speed;
  final double batteryLevel;
  final String lastUpdate;
  final String status; // 'moving', 'stopped', 'offline'

  BusLocationModel({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.speed,
    required this.batteryLevel,
    required this.lastUpdate,
    required this.status,
  });

  factory BusLocationModel.fromJson(Map<String, dynamic> json) {
    return BusLocationModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      speed: (json['speed'] as num?)?.toDouble() ?? 0.0,
      batteryLevel: (json['batteryLevel'] as num?)?.toDouble() ?? 0.0,
      lastUpdate: json['lastUpdate'] ?? '',
      status: json['status'] ?? 'offline',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'batteryLevel': batteryLevel,
      'lastUpdate': lastUpdate,
      'status': status,
    };
  }
}

class LocationHistoryRecord {
  final String time;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool isLast;
  
  // Rich Trip Data
  final String mode; // 'school_bus_mode', 'walking_mode', etc.
  final String status; // 'trip_finished', 'trip_in_progress'
  final String duration;
  final String fromAddress;
  final String toAddress;
  final String startTime;
  final String endTime;
  final LatLng? startCoord;
  final LatLng? endCoord;

  LocationHistoryRecord({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.isLast = false,
    this.mode = 'school_bus_mode',
    this.status = 'trip_finished',
    this.duration = '',
    this.fromAddress = '',
    this.toAddress = '',
    this.startTime = '',
    this.endTime = '',
    this.startCoord,
    this.endCoord,
  });

  factory LocationHistoryRecord.fromJson(Map<String, dynamic> json) {
    // Helper to map type to Icon and Color
    final String mode = json['mode'] ?? 'school_bus_mode';
    IconData icon;
    Color color;

    switch (mode) {
      case 'walking_mode':
        icon = Icons.directions_walk_rounded;
        color = Colors.orangeAccent;
        break;
      case 'private_transport_mode':
        icon = Icons.directions_car_rounded;
        color = Colors.greenAccent;
        break;
      default:
        icon = Icons.directions_bus_rounded;
        color = Colors.blueAccent;
    }

    return LocationHistoryRecord(
      time: json['time'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      icon: icon,
      color: color,
      isLast: json['isLast'] ?? false,
      mode: mode,
      status: json['status'] ?? 'trip_finished',
      duration: json['duration'] ?? '',
      fromAddress: json['fromAddress'] ?? '',
      toAddress: json['toAddress'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
      startCoord: json['startLat'] != null ? LatLng(json['startLat'], json['startLng']) : null,
      endCoord: json['endLat'] != null ? LatLng(json['endLat'], json['endLng']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'time': time,
      'title': title,
      'subtitle': subtitle,
      'isLast': isLast,
      'mode': mode,
      'status': status,
      'duration': duration,
      'fromAddress': fromAddress,
      'toAddress': toAddress,
      'startTime': startTime,
      'endTime': endTime,
      'startLat': startCoord?.latitude,
      'startLng': startCoord?.longitude,
      'endLat': endCoord?.latitude,
      'endLng': endCoord?.longitude,
    };
  }
}

enum PaymentStatus {
  paid,
  pending,
  overdue,
}

class PaymentModel {
  final String id;
  final String month;
  final double amount;
  final PaymentStatus status;
  final String date;
  final String? invoiceUrl;
  final List<String> childIds;

  PaymentModel({
    required this.id,
    required this.month,
    required this.amount,
    required this.status,
    required this.date,
    this.invoiceUrl,
    required this.childIds,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) {
    return PaymentModel(
      id: (json['id'] ?? json['_id'])?.toString() ?? '',
      month: json['month']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      status: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PaymentStatus.pending,
      ),
      date: json['date']?.toString() ?? '',
      invoiceUrl: json['invoiceUrl'],
      childIds: List<String>.from(json['childIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'month': month,
      'amount': amount,
      'status': status.toString().split('.').last,
      'date': date,
      'invoiceUrl': invoiceUrl,
      'childIds': childIds,
    };
  }
}
