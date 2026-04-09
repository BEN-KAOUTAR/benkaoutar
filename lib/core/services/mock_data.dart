import 'package:flutter/material.dart';
import '../models/models.dart';
import 'package:latlong2/latlong.dart';
import 'translation_service.dart';

class MockData {
  // ===== COMMON DATA =====
  static UserModel parentUser = _buildParentFr();
  static List<ChildModel> children = _buildChildrenFr();
  static List<GradeModel> grades = _buildGradesFr();
  static List<AttendanceRecord> attendance = _buildAttendanceFr();
  static List<TeacherActivityModel> parentActivities = _buildParentActivitiesFr();
  static List<PostModel> homeworks = _buildHomeworksFr();
  static List<PostModel> posts = _buildPostsFr();
  static List<PaymentModel> payments = _buildPaymentsFr();
  static List<ChatThreadModel> chatThreads = _buildChatThreadsFr();
  static List<EventModel> events = _buildEventsFr();
  static List<NotificationModel> notifications = _buildNotificationsFr();
  static List<LocationHistoryRecord> locationHistory = _buildLocationHistoryFr();
  
  // ===== TEACHER DATA =====
  static UserModel teacherUser = _buildTeacherFr();
  static List<ClassModel> teacherClasses = _buildTeacherClassesFr();
  static List<TeacherActivityModel> teacherActivities = _buildTeacherActivitiesFr();
  static List<HomeworkModel> teacherHomework = _buildTeacherHomeworkFr();
  static Map<String, List<Map<String, dynamic>>> teacherTimetable = _buildTeacherTimetableFr();
  static List<HomeworkModel> get homeworkList => teacherHomework;
  
  static Map<String, List<GradeModel>> get subjectHistory => {
    'Mathématiques': [
      GradeModel(id: 'h1', subject: 'Mathématiques', grade: 16.5, maxGrade: 20, coefficient: 3, date: '15 Mars 2026', type: 'Examen'),
      GradeModel(id: 'h2', subject: 'Mathématiques', grade: 15.0, maxGrade: 20, coefficient: 3, date: '01 Mars 2026', type: 'Contrôle'),
    ],
    'Français': [
      GradeModel(id: 'h3', subject: 'Français', grade: 14.0, maxGrade: 20, coefficient: 2, date: '12 Mars 2026', type: 'Contrôle'),
    ],
  };

  /// Main method to switch app language and trigger AI translation for dynamic data.
  static Future<void> setLocale(String lang) async {
    if (lang == 'fr') {
      _resetToDefault();
      return;
    }

    // Translate dynamic data using AI
    final translator = TranslationService.instance;

    // 1. User Data
    parentUser = parentUser.copyWith(
      schoolName: await translator.translate(parentUser.schoolName ?? '', lang),
    );

    // 2. Children Data
    children = await Future.wait(children.map((c) async => c.copyWith(
      className: await translator.translate(c.className, lang),
      status: await translator.translate(c.status, lang),
      lastUpdate: await translator.translate(c.lastUpdate, lang),
      nextExamSubject: c.nextExamSubject != null ? await translator.translate(c.nextExamSubject!, lang) : null,
    )));

    // 3. Grades
    grades = await Future.wait(grades.map((g) async => g.copyWith(
      subject: await translator.translate(g.subject, lang),
      type: await translator.translate(g.type, lang),
      comment: g.comment != null ? await translator.translate(g.comment!, lang) : null,
    )));

    // 4. Homeworks & Posts
    homeworks = await Future.wait(homeworks.map((h) async => h.copyWith(
      title: await translator.translate(h.title, lang),
      content: await translator.translate(h.content, lang),
    )));

    posts = await Future.wait(posts.map((p) async => p.copyWith(
      title: await translator.translate(p.title, lang),
      content: await translator.translate(p.content, lang),
      authorRole: await translator.translate(p.authorRole, lang),
      date: await translator.translate(p.date, lang),
    )));

    // 5. Payments
    payments = await Future.wait(payments.map((p) async => PaymentModel(
      id: p.id,
      month: await translator.translate(p.month, lang),
      amount: p.amount,
      status: p.status,
      date: await translator.translate(p.date, lang),
      invoiceUrl: p.invoiceUrl,
      childIds: p.childIds,
    )));

    // 6. Notifications
    notifications = await Future.wait(notifications.map((n) async => n.copyWith(
      title: await translator.translate(n.title, lang),
      body: await translator.translate(n.body, lang),
      time: await translator.translate(n.time, lang),
    )));

    // 7. Events
    events = await Future.wait(events.map((e) async => e.copyWith(
      title: await translator.translate(e.title, lang),
      description: await translator.translate(e.description, lang),
      location: e.location != null ? await translator.translate(e.location!, lang) : null,
    )));
  }

  static void _resetToDefault() {
    parentUser = _buildParentFr();
    children = _buildChildrenFr();
    grades = _buildGradesFr();
    attendance = _buildAttendanceFr();
    parentActivities = _buildParentActivitiesFr();
    homeworks = _buildHomeworksFr();
    posts = _buildPostsFr();
    payments = _buildPaymentsFr();
    chatThreads = _buildChatThreadsFr();
    events = _buildEventsFr();
    notifications = _buildNotificationsFr();
    teacherUser = _buildTeacherFr();
    teacherClasses = _buildTeacherClassesFr();
    teacherActivities = _buildTeacherActivitiesFr();
    teacherHomework = _buildTeacherHomeworkFr();
    teacherTimetable = _buildTeacherTimetableFr();
    locationHistory = _buildLocationHistoryFr();
  }

  // ==========================================================
  // FRENCH DATA (DEFAULT)
  // ==========================================================
  static UserModel _buildParentFr() => UserModel(id: 'p1', name: 'Yassin Benani', email: 'ahmed.benani@email.com', role: UserRole.parent, phone: '+212 6 12 34 56 78', schoolName: 'École Al Irfane', childrenIds: ['c1'], avatarIndex: 3);
  
  static List<ChildModel> _buildChildrenFr() => [
    ChildModel(id: 'c1', name: 'Yassin Benani', className: '4ème Année A', age: 10, attendanceRate: 95.5, averageGrade: 15.8, status: 'at_school', lastUpdate: 'Il y a 15 min', lateHomeworkCount: 2, nextExamDate: '15 Mai', nextExamSubject: 'Mathématiques'),
  ];

  static List<GradeModel> _buildGradesFr() => [
    GradeModel(id: 'g1', subject: 'Mathématiques', grade: 16.5, maxGrade: 20, coefficient: 3, date: '15 Mars 2026', type: 'Examen', classAverage: 14.2, comment: 'Excellent travail, continue ainsi !'),
    GradeModel(id: 'g2', subject: 'Français', grade: 14.0, maxGrade: 20, coefficient: 2, date: '12 Mars 2026', type: 'Contrôle', classAverage: 13.5, comment: 'Bonne participation en classe.'),
  ];

  static List<AttendanceRecord> _buildAttendanceFr() => [
    AttendanceRecord(date: '27 Mars 2026', status: 'present'),
    AttendanceRecord(date: '25 Mars 2026', status: 'absent', motif: 'Grippe saisonnière'),
  ];

  static List<TeacherActivityModel> _buildParentActivitiesFr() => [
    TeacherActivityModel(id: 'pa1', title: 'Nouvelle Note : Mathématiques', date: 'Aujourd\'hui', detail: 'Yassin : 16.5/20', icon: Icons.grade_rounded, color: Colors.blue),
  ];

  static List<PostModel> _buildHomeworksFr() => [
    PostModel(id: 'hw1', authorName: 'Mme. Lahlou', authorRole: 'Professeur', title: 'Mathématiques', content: 'Exercices 1 à 5 page 42 du manuel. Géométrie des triangles.', date: '31 Mars 2026', isUrgent: true, isCompleted: false),
    PostModel(id: 'hw2', authorName: 'M. Alaoui', authorRole: 'Professeur', title: 'Français', content: 'Lecture du chapitre 3 de "Le Petit Prince". Résumé court.', date: '02 Avr 2026', isUrgent: false, isCompleted: true),
  ];

  static List<PostModel> _buildPostsFr() => [
    PostModel(id: 'post_reins', authorName: 'Direction', authorRole: 'Admin', title: 'Réinscriptions', content: 'Important : Les réinscriptions pour l\'année scolaire 2026-2027 sont ouvertes jusqu\'au 30 avril. Veuillez vous présenter à l\'administration...', date: 'Il y a 3h', isUrgent: true),
    PostModel(id: 'post_medical', authorName: 'Service Médical', authorRole: 'Santé', title: 'Visite Médicale', content: 'Avis : Campagne de visite médicale annuelle pour les classes de primaire à partir de lundi prochain. Merci de vérifier le carnet de...', date: 'Il y a 5h', isUrgent: true),
    PostModel(id: 'post1', authorName: 'Ikenas Admin', authorRole: 'Direction', content: 'Rappel : La réunion d\'Information pour le voyage scolaire en France aura lieu ce vendredi à 17h30 au grand amphithéâtre.', date: 'Hier', isUrgent: true, likes: 0, comments: 0),
  ];

  static List<PaymentModel> _buildPaymentsFr() => [
    PaymentModel(id: 'pay1', month: 'Mars 2026', amount: 1500.0, status: PaymentStatus.paid, date: '02 Mars 2026', childIds: ['c1']),
    PaymentModel(id: 'pay2', month: 'Avril 2026', amount: 450.0, status: PaymentStatus.pending, date: '10 Avril 2026', childIds: ['c1']),
  ];

  static List<ChatThreadModel> _buildChatThreadsFr() => [
    ChatThreadModel(id: 'ch1', contactName: 'Mme. Lahlou', contactRole: 'Prof. Français', lastMessage: 'Yassin a très bien travaillé !', lastTime: '14:30', unreadCount: 2),
    ChatThreadModel(id: 'group1', contactName: 'Groupe 4ème Année A', contactRole: 'GROUPE', lastMessage: 'N\'oubliez pas vos livres d\'histoire demain.', lastTime: '10:15', unreadCount: 5, onlyAdminsCanMessage: true),
  ];

  static List<EventModel> _buildEventsFr() => [
    EventModel(id: 'e1', title: 'Journée Portes Ouvertes', description: 'Découverte des activités', date: '29 Mars 2026', time: '09:00 - 16:00', type: 'event', location: 'École Al Irfane'),
  ];

  static List<NotificationModel> _buildNotificationsFr() => [
    NotificationModel(id: 'n1', title: 'Alerte Proximité', body: 'Yassin ha quitté le périmètre scolaire.', time: '10 min', type: 'location', iconType: IconType.location),
  ];

  static List<LocationHistoryRecord> _buildLocationHistoryFr() => [
    LocationHistoryRecord(time: "16:55", title: "Maison", subtitle: "Arrivée à destination", icon: Icons.home_rounded, color: Colors.greenAccent, mode: 'private_transport_mode', status: 'trip_finished', duration: '25 min', fromAddress: 'Collège International', toAddress: '12 Rue de la Paix', startTime: '16:30', endTime: '16:55', startCoord: const LatLng(33.5731, -7.5898), endCoord: const LatLng(33.5651, -7.5958)),
    LocationHistoryRecord(time: "08:15", title: "École", subtitle: "Arrivée le matin", icon: Icons.school_rounded, color: Colors.indigoAccent, mode: 'school_bus_mode', status: 'trip_finished', duration: '30 min', fromAddress: '12 Rue de la Paix', toAddress: 'Collège International', startTime: '07:45', endTime: '08:15', startCoord: const LatLng(33.5651, -7.5958), endCoord: const LatLng(33.5731, -7.5898), isLast: true),
  ];

  static UserModel _buildTeacherFr() => UserModel(id: 't1', name: 'Mme. Lahlou Nadia', email: 'n.lahlou@alirfane.ma', role: UserRole.teacher, phone: '+212 6 99 88 77 66', schoolName: 'École Al Irfane', classIds: ['cl1', 'cl2'], avatarUrl: 'assets/images/avatars/avatar_3.png', avatarIndex: 3);
  
  static List<ClassModel> _buildTeacherClassesFr() => [
    ClassModel(id: 'cl1', name: '4ème Année A', level: 'Primaire', studentCount: 32, attendanceRate: 94.5, classAverage: 14.8, students: _generateStudentsFr(32)),
  ];

  static List<StudentModel> _generateStudentsFr(int count) {
    final names = ['Yassin Benani', 'Omar Tazi', 'Fatima Zahra', 'Mehdi Alaoui', 'Zineb Bennani'];
    return List.generate(count, (i) => StudentModel(id: 'stu_$i', name: names[i % names.length], massarCode: 'K${100000000 + i}', average: 10.0 + (i * 0.7 % 10), attendanceRate: 85.0 + (i * 1.3 % 15), parentName: 'Parent de ${names[i % names.length]}', parentPhone: '+212 6 00 00 00 00', behavior: 'Bon', birthDate: '12/06/2014', age: 11, className: '4ème Année A', group: 'G1'));
  }

  static List<TeacherActivityModel> _buildTeacherActivitiesFr() => [
    TeacherActivityModel(id: 'a1', title: 'Note ajoutée', description: 'Amine Benali : 18/20', date: 'Aujourd\'hui', time: '10 min', icon: Icons.edit_note_rounded, color: Colors.blue),
  ];

  static List<HomeworkModel> _buildTeacherHomeworkFr() => [
    HomeworkModel(id: 'th1', subject: 'Maths', title: 'Algèbre', description: 'Exercices 1 et 2', dueDate: '30/03/2026', teacherName: 'Mme. Lahlou Nadia'),
  ];

  static Map<String, List<Map<String, dynamic>>> _buildTeacherTimetableFr() => {
    'Lundi': [{'time': '08:30 - 10:30', 'class': '4ème A', 'subject': 'Français', 'room': 'Salle 12'}],
    'Mardi': [{'time': '08:30 - 10:30', 'class': '4ème A', 'subject': 'Maths', 'room': 'Salle 12'}],
  };


  static IconData getNotificationIcon(IconType type) {
    switch (type) {
      case IconType.location: return Icons.location_on;
      case IconType.grade: return Icons.school;
      case IconType.absence: return Icons.person_off;
      case IconType.payment: return Icons.payment;
      case IconType.post: return Icons.article;
      case IconType.message: return Icons.chat;
      case IconType.info: return Icons.info;
    }
  }
}
