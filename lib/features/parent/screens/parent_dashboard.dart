import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'suivi_scolaire_screen.dart';
import 'feed_screen.dart';
import 'payment_screen.dart';
import 'chat_screen.dart';
import '../../common/screens/profile_screen.dart';
import '../../common/screens/notifications_screen.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models/models.dart';
import 'location_screen.dart';
import 'homework_screen.dart';
import 'timetable_grid_screen.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/widgets/sprite_avatar.dart';
import '../../../core/localization/app_localizations.dart';
import '../viewmodels/dashboard_view_model.dart';
import '../viewmodels/feed_view_model.dart';
import '../viewmodels/homework_view_model.dart';
import '../../common/viewmodels/notification_view_model.dart';

class ParentDashboard extends StatefulWidget {
  const ParentDashboard({super.key});

  @override
  State<ParentDashboard> createState() => _ParentDashboardState();
}

class _ParentDashboardState extends State<ParentDashboard> {

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final pages = [
      const _ParentHome(),
      const FeedScreen(),
      const ChatScreen(),
      const PaymentScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      extendBody: true,
      backgroundColor: Colors.transparent,
      body: DeepSpaceBackground(
        showOrbs: true,
        child: pages[appState.dashboardIndex],
      ),
      bottomNavigationBar: _buildBottomNav(isDark, appState),
    );
  }

  Widget _buildBottomNav(bool isDark, AppState appState) {
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: Colors.blueAccent.withValues(alpha: 0.1),
                blurRadius: 30,
                offset: const Offset(0, 10))
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded,
                    AppLocalizations.of(context)!.translate('home'), 0, isDark, appState),
                _buildNavItem(
                    Icons.feed_rounded,
                    AppLocalizations.of(context)!.translate('feed_nav'),
                    1,
                    isDark,
                    appState),
                _buildNavItem(
                    Icons.chat_bubble_outline_rounded,
                    AppLocalizations.of(context)!.translate('messages'),
                    2,
                    isDark,
                    appState),
                _buildNavItem(
                    Icons.payment_rounded,
                    AppLocalizations.of(context)!.translate('payments_nav'),
                    3,
                    isDark,
                    appState),
                _buildNavItem(
                    Icons.person_outline_rounded,
                    AppLocalizations.of(context)!.translate('profile_nav'),
                    4,
                    isDark,
                    appState),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark, AppState appState) {
    final isActive = appState.dashboardIndex == index;
    final activeColor = Colors.white;
    final inactiveColor = isDark ? const Color(0xFF64748B) : Colors.black38;

    return GestureDetector(
      onTap: () => appState.setDashboardIndex(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [Colors.blueAccent, Colors.indigoAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight)
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: Colors.blueAccent.withValues(alpha: 0.4),
                      blurRadius: 15,
                      offset: const Offset(0, 5))
                ]
              : [],
        ),
        child: Icon(
          icon,
          color: isActive ? activeColor : inactiveColor,
          size: 24,
        ),
      ),
    );
  }
}

class _ParentHome extends StatefulWidget {
  const _ParentHome();

  @override
  State<_ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<_ParentHome> {
  int _currentPostIndex = 0;
  String _selectedYear = '2023-2024';
  String _selectedSemester = 'S1';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Academic year logic
    if (now.month >= 9) {
      _selectedYear = '${now.year}-${now.year + 1}';
    } else {
      _selectedYear = '${now.year - 1}-${now.year}';
    }
    // Semester logic
    if (now.month >= 2 && now.month <= 7) {
      _selectedSemester = 'S2';
    } else {
      _selectedSemester = 'S1';
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final dashboardVM = context.read<DashboardViewModel>();
      dashboardVM.init().then((_) {
        if (!mounted) return;
        // Fetch initial evolution and homework for the first child if available
        if (dashboardVM.children.isNotEmpty) {
          final studentId = dashboardVM.children[0].id;
          dashboardVM.fetchEvolution(studentId, _selectedYear, _selectedSemester);
          context.read<HomeworkViewModel>().fetchHomework(studentId);
        }
      });
      context.read<FeedViewModel>().fetchPosts();
      context.read<NotificationViewModel>().fetchNotifications();
    });
  }

  void _showPostDetails(BuildContext context, PostModel post) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 20,
                top: 20,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded,
                      color: isDark ? Colors.white38 : Colors.black38),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: Colors.redAccent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12)),
                      child: Text(
                          AppLocalizations.of(context)!.translate('urgent'),
                          style: const TextStyle(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                              letterSpacing: 2)),
                    ),
                    const SizedBox(height: 32),
                    Text(post.content,
                        style: TextStyle(
                            color:
                                isDark ? Colors.white : const Color(0xFF0F172A),
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.6)),
                    const Spacer(),
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              Colors.blueAccent.withValues(alpha: 0.1),
                          child: const Icon(Icons.person_rounded,
                              color: Colors.blueAccent),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(post.authorName,
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14)),
                            Text(post.authorRole,
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white38
                                        : Colors.black38,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w900)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(post.date,
                        style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontSize: 12,
                            fontWeight: FontWeight.w900)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Consumer2<FeedViewModel, DashboardViewModel>(
      builder: (context, feedVM, dashVM, child) {
        final appState = Provider.of<AppState>(context);
        final urgentPosts = feedVM.posts.where((p) => p.isUrgent || p.isEvent).toList();
        final totalUrgent = urgentPosts.length;
        final currentIndex = _currentPostIndex % (totalUrgent > 0 ? totalUrgent : 1);
        final urgentPost = urgentPosts.isNotEmpty ? urgentPosts[currentIndex] : null;

        final isOffline = appState.isOffline;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: (dashVM.isLoading && dashVM.children.isEmpty)
            ? const Center(child: CircularProgressIndicator(color: Colors.blueAccent))
            : dashVM.errorMessage != null && dashVM.children.isEmpty
              ? _buildErrorPlaceholder(context, dashVM.errorMessage!, dashVM.init)
              : SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (isOffline) _buildOfflineBanner(context),
                _buildHeader(context, isDark)
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: -0.2),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 40),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.translate('hello'),
                                style: TextStyle(
                                    color: isDark ? Colors.white38 : Colors.black38,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1.5)),
                            const SizedBox(height: 4),
                            Text(
                                '${AppLocalizations.of(context)!.translate('parent_name')} 👋',
                                style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 32,
                                    letterSpacing: -1)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        if (urgentPost != null)
                          _buildUrgentCard(
                              context, urgentPost, isDark, totalUrgent, currentIndex),
                        const SizedBox(height: 24),
                        const SizedBox(height: 48),
                        _buildQuickActions(context, isDark),
                        const SizedBox(height: 48),
                        _buildComparisonChart(context, isDark),
                        const SizedBox(height: 48),
                        _buildRecentActivities(context, isDark),
                        const SizedBox(height: 120),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRecentActivities(BuildContext context, bool isDark) {
    final activities = context.watch<DashboardViewModel>().activities;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            AppLocalizations.of(context)!
                .translate('recent_activities')
                .toUpperCase(),
            style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2)),
        const SizedBox(height: 24),
        ...activities
            .map((a) => _ActivityPlatinumTile(activity: a, isDark: isDark)),
      ],
    );
  }

  Widget _buildOfflineBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Colors.orangeAccent,
          Colors.deepOrangeAccent.withValues(alpha: 0.8)
        ]),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 10),
          Text(
            AppLocalizations.of(context)!.translate('offline_mode'),
            style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 10,
                letterSpacing: 2),
          ),
        ],
      ),
    ).animate().slideY(begin: -1, end: 0);
  }

  Widget _buildErrorPlaceholder(BuildContext context, String message, VoidCallback onRetry) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.cloud_off_rounded, size: 80, color: Colors.blueAccent.withValues(alpha: 0.3)),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.translate(message),
              textAlign: TextAlign.center,
              style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.translate('check_connection'),
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w700, fontSize: 14),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(AppLocalizations.of(context)!.translate('retry_btn').toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final primaryColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryBg = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.02);
    final borderCol = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.black.withValues(alpha: 0.05);
    final user = Provider.of<AppState>(context).currentUser;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.blueAccent.withValues(alpha: 0.2),
                Colors.purpleAccent.withValues(alpha: 0.1)
              ]),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
            child: Image.asset('assets/images/image3.png',
                width: 24, height: 24, fit: BoxFit.contain),
          ),
          const SizedBox(width: 16),
          Text('Ikenas',
              style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  color: primaryColor,
                  letterSpacing: -0.5)),
          const Spacer(),
          GestureDetector(
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen())),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: secondaryBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: borderCol),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10)
                  ]),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(Icons.notifications_none_rounded,
                      color: primaryColor, size: 24),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.redAccent, blurRadius: 6)
                            ])),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blueAccent.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                ),
                child: user?.avatarIndex != null
                    ? SpriteAvatar(index: user!.avatarIndex!, size: 40)
                    : CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                        child: Icon(Icons.person_rounded, color: isDark ? Colors.white38 : Colors.black26, size: 20),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

   Widget _buildUrgentCard(
      BuildContext context, PostModel post, bool isDark, int totalPosts, int currentIndex) {
    final showArrow = totalPosts > 1;
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.redAccent.withValues(alpha: 0.1) : Colors.redAccent,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(
            color: isDark
                ? Colors.redAccent.withValues(alpha: 0.2)
                : Colors.redAccent.withValues(alpha: 0.1),
            width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.redAccent.withValues(alpha: 0.15),
              blurRadius: 30,
              offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Icon(Icons.event_rounded,
                        color: Colors.redAccent, size: 14),
                    SizedBox(width: 8),
                    Text("ÉVÉNEMENT",
                        style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w900,
                            fontSize: 9,
                            letterSpacing: 1.5)),
                  ],
                ),
              ),
              const Spacer(),
              if (showArrow)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('${currentIndex + 1}/$totalPosts',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1)),
                ),
              const SizedBox(width: 12),
              Text(post.date,
                  style: TextStyle(
                      color: isDark
                          ? Colors.redAccent.withValues(alpha: 0.8)
                          : Colors.white.withValues(alpha: 0.7),
                      fontSize: 10,
                      fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 24),
          Text(post.content,
              key: ValueKey('content_${post.id}'),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  height: 1.5)).animate().fadeIn().slideX(begin: 0.02),
          const SizedBox(height: 32),
          Row(
            children: [
              if (showArrow)
                GestureDetector(
                  onTap: () => setState(() => _currentPostIndex++),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white12, width: 1.5)
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        color: Colors.white, size: 16),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds, color: Colors.white24),
              const Spacer(),
              InkWell(
                onTap: () => _showPostDetails(context, post),
                child: Text(
                    AppLocalizations.of(context)!.translate('view_details'),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 1)),
              ),
            ],
          ),
        ],
      ),
    ).animate(key: ValueKey('card_${post.id}')).fadeIn(duration: 400.ms).slideY(begin: 0.05);
  }


  Widget _buildQuickActions(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(AppLocalizations.of(context)!.translate('quick_nav').toUpperCase(),
            style: TextStyle(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 11,
                fontWeight: FontWeight.w900,
                letterSpacing: 2)),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildActionIcon(
                context,
                AppLocalizations.of(context)!.translate('timetable'),
                Icons.grid_view_rounded,
                Colors.purpleAccent,
                null,
                isDark,
                onTap: () {
                  final children = context.read<DashboardViewModel>().children;
                  if (children.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => TimetableGridScreen(student: children[0])));
                  }
                }),
            Consumer<HomeworkViewModel>(
              builder: (context, homeworkVM, child) => _buildActionIcon(
                  context,
                  'Devoir/Examen',
                  Icons.assignment_rounded,
                  Colors.orangeAccent,
                  null,
                  isDark,
                  showBadge: homeworkVM.hasNewAssignments,
                  onTap: () {
                    final dashVM = context.read<DashboardViewModel>();
                    if (dashVM.children.isNotEmpty) {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => HomeworkScreen(studentId: dashVM.children[0].id)));
                    }
                  }),
            ),
            _buildActionIcon(
                context,
                AppLocalizations.of(context)!.translate('trip'),
                Icons.location_on_rounded,
                Colors.blueAccent,
                null,
                isDark,
                onTap: () {
                  final children = context.read<DashboardViewModel>().children;
                  if (children.isNotEmpty) {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => LocationScreen(student: children[0])));
                  }
                }),
            _buildActionIcon(
                context,
                AppLocalizations.of(context)!.translate('evaluation'),
                Icons.bar_chart_rounded,
                Colors.greenAccent,
                null,
                isDark,
                onTap: () {
                  final children = context.read<DashboardViewModel>().children;
                  if (children.isEmpty) return;
                  final student = children[0];
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SuiviScolaireScreen(
                        student: student,
                      ),
                    ),
                  );
                }),
          ],
        ),
      ],
    );
  }

  Widget _buildActionIcon(BuildContext context, String label, IconData icon,
      Color color, Widget? screen, bool isDark, {VoidCallback? onTap, bool showBadge = false}) {
    return GestureDetector(
      onTap: onTap ?? () {
        if (screen != null) {
          Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
        }
      },
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                        color: color.withValues(alpha: 0.2),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ],
                  border: Border.all(color: color.withValues(alpha: 0.2)),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              if (showBadge)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.redAccent.withValues(alpha: 0.4),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true)).shimmer(duration: 2.seconds),
            ],
          ),
          const SizedBox(height: 12),
          Text(label,
              style: TextStyle(
                  color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5)),
        ],
      ),
    ).animate().scale();
  }

  Widget _buildComparisonChart(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white38 : Colors.black45;
    final yassinColor = isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5); // Indigo

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(AppLocalizations.of(context)!.translate('global_evolution'),
                style: TextStyle(
                    color: textColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2)),
            const Spacer(),
            // Year Selector
            _buildChartSelector(
              _selectedYear,
              ['2025-2026', '2024-2025', '2023-2024', '2022-2023'],
              (val) => setState(() => _selectedYear = val),
              isDark,
            ),
            const SizedBox(width: 8),
            // Semester Selector
            _buildChartSelector(
              _selectedSemester,
              ['S1', 'S2'],
              (val) => setState(() => _selectedSemester = val),
              isDark,
            ),
          ],
        ),
        const SizedBox(height: 24),
        ClipRRect(
          borderRadius: BorderRadius.circular(40),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              height: 360, // Increased height for titles and tooltips
              padding: const EdgeInsets.fromLTRB(16, 48, 28, 20), // Increased top padding
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.03)
                    : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(40),
                border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.black.withValues(alpha: 0.05)),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                        color: yassinColor.withValues(alpha: 0.05),
                        blurRadius: 30,
                        offset: const Offset(0, 15))
                ],
              ),
              child: Column(
                children: [
                  Expanded(
                    child: LineChart(
                      LineChartData(
                        minY: 0,
                        maxY: 25, // Internal scale is higher to avoid clipping
                        gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 5,
                            getDrawingHorizontalLine: (value) => FlLine(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.05)
                                    : Colors.black.withValues(alpha: 0.05),
                                strokeWidth: 1,
                                dashArray: [5, 5])),
                        titlesData: FlTitlesData(
                          show: true,
                          rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false)),
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                  showTitles: true,
                                  interval: 5,
                                  reservedSize: 35,
                                  getTitlesWidget: (val, meta) {
                                    if (val > 20) return const SizedBox.shrink(); // Strict 0-20 axis
                                    return Padding(
                                        padding: const EdgeInsets.only(right: 8),
                                        child: Text(val.toInt().toString(),
                                            style: TextStyle(
                                                color: textColor.withValues(alpha: 0.5),
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900)),
                                      );
                                  })),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              interval: 1,
                              getTitlesWidget: (val, meta) {
                                final titles = [
                                  AppLocalizations.of(context)!.translate('math'),
                                  AppLocalizations.of(context)!.translate('physics'),
                                  AppLocalizations.of(context)!.translate('arabic'),
                                  AppLocalizations.of(context)!.translate('french'),
                                  AppLocalizations.of(context)!.translate('english'),
                                ];
                                if (val.toInt() >= 0 && val.toInt() < titles.length) {
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 12.0),
                                    child: Text(titles[val.toInt()],
                                        style: TextStyle(
                                            color: textColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w900)),
                                  );
                                }
                                return const SizedBox.shrink();
                              },
                              reservedSize: 35,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        lineTouchData: LineTouchData(
                          handleBuiltInTouches: true,
                          getTouchedSpotIndicator: (LineChartBarData barData, List<int> spotIndexes) {
                            return spotIndexes.map((spotIndex) {
                              return TouchedSpotIndicatorData(
                                FlLine(color: barData.color?.withValues(alpha: 0.3), strokeWidth: 4),
                                FlDotData(
                                  getDotPainter: (spot, percent, barData, index) =>
                                      FlDotCirclePainter(
                                    radius: 8,
                                    color: barData.color ?? Colors.blueAccent,
                                    strokeWidth: 2,
                                    strokeColor: Colors.white,
                                  ),
                                ),
                              );
                            }).toList();
                          },
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (touchedSpot) => isDark
                                ? const Color(0xFF0F172A)
                                : Colors.white,
                            tooltipBorderRadius: BorderRadius.circular(20),
                            tooltipPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            tooltipBorder: BorderSide(
                                color: isDark
                                    ? Colors.white.withValues(alpha: 0.1)
                                    : Colors.black.withValues(alpha: 0.05)),
                            getTooltipItems: (List<LineBarSpot> touchedSpots) {
                              return touchedSpots.map((LineBarSpot touchedSpot) {
                                return LineTooltipItem(
                                  touchedSpot.y.toStringAsFixed(1),
                                  TextStyle(
                                    color: touchedSpot.bar.color,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: context.read<DashboardViewModel>().evolutionData.isEmpty 
                              ? const [FlSpot(0, 0)] // Empty fallback
                              : context.read<DashboardViewModel>().evolutionData.map((e) => FlSpot(
                                  (e['index'] as num).toDouble(), 
                                  (e['grade'] as num).toDouble()
                                )).toList(),
                            isCurved: true,
                            curveSmoothness: 0.35,
                            color: yassinColor,
                            barWidth: 4,
                            isStrokeCapRound: true,
                            shadow: Shadow(
                              color: yassinColor.withValues(alpha: 0.4),
                              blurRadius: 15,
                              offset: const Offset(0, 8),
                            ),
                            dotData: FlDotData(
                              show: true,
                              getDotPainter: (spot, percent, barData, index) =>
                                  FlDotCirclePainter(
                                radius: 4,
                                color: Colors.white,
                                strokeWidth: 3,
                                strokeColor: yassinColor,
                              ),
                            ),
                            belowBarData: BarAreaData(
                              show: true,
                              gradient: LinearGradient(
                                colors: [
                                  yassinColor.withValues(alpha: 0.15),
                                  yassinColor.withValues(alpha: 0),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.02),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: context.read<DashboardViewModel>().children.asMap().entries.map((entry) {
                        final index = entry.key;
                        final child = entry.value;
                        final color = Colors.blueAccent;
                        return Row(
                          children: [
                            _buildLegendItem(child.name.split(' ')[0], color, isDark),
                            if (index < context.read<DashboardViewModel>().children.length - 1) const SizedBox(width: 40),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1);
  }

  Widget _buildChartSelector(String value, List<String> options, Function(String) onChanged, bool isDark) {
    return PopupMenuButton<String>(
      onSelected: onChanged,
      offset: const Offset(0, 40),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      itemBuilder: (context) => options.map((opt) => PopupMenuItem(
        value: opt,
        child: Text(opt, style: TextStyle(
          color: isDark ? Colors.white70 : Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.bold
        )),
      )).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Text(value, style: TextStyle(
              color: isDark ? Colors.white70 : Colors.black54,
              fontSize: 10,
              fontWeight: FontWeight.w900
            )),
            Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: isDark ? Colors.white38 : Colors.black38)
          ],
        ),
      ),
    );
  }
  Widget _buildLegendItem(String name, Color color, bool isDark) {
    return Row(
      children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)
                ])),
        const SizedBox(width: 8),
        Text(name,
            style: TextStyle(
                color: isDark ? Colors.white70 : const Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w900)),
      ],
    );
  }
}

class _ChildPlatinumCard extends StatelessWidget {
  final StudentModel child;
  final bool isDark;
  const _ChildPlatinumCard({required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return Container(
      width: 250,
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(44),
        border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 40,
                offset: const Offset(0, 15))
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: Colors.purpleAccent.withValues(alpha: 0.4),
                        width: 1.5),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.purpleAccent.withValues(alpha: 0.2),
                          blurRadius: 10)
                    ]),
                child: CircleAvatar(
                  radius: 22,
                  backgroundImage:
                      NetworkImage('https://i.pravatar.cc/150?u=${child.id}'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.name,
                        style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 1),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.03),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text((child.className ?? "CLASSE").toUpperCase(),
                          style: TextStyle(
                              color: isDark ? Colors.white60 : Colors.black54,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildCompactStat(AppLocalizations.of(context)!.translate('avg'),
                  '${child.average}', Colors.blueAccent, isDark),
              Container(
                  width: 1,
                  height: 16,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05)),
              _buildCompactStat(
                  AppLocalizations.of(context)!.translate('homework'),
                  '--',
                  Colors.orangeAccent,
                  isDark),
              Container(
                  width: 1,
                  height: 16,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05)),
              _buildCompactStat(
                  AppLocalizations.of(context)!.translate('attendance_short'),
                  '${(child.attendanceRate ?? 0).toInt()}%',
                  Colors.greenAccent,
                  isDark),
            ],
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => SuiviScolaireScreen(student: child))),
                child: Row(
                  children: [
                    Text(
                        AppLocalizations.of(context)!
                            .translate('detailed_tracking'),
                        style: TextStyle(
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                            letterSpacing: 0.5)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.05),
                          shape: BoxShape.circle),
                      child: Icon(Icons.arrow_forward_ios_rounded,
                          size: 8,
                          color: isDark ? Colors.white38 : Colors.black38),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCompactStat(
      String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.w900,
                fontSize: 18)),
        const SizedBox(height: 2),
        Text(label,
            style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5)),
      ],
    );
  }
}

class _ActivityPlatinumTile extends StatelessWidget {
  final dynamic activity;
  final bool isDark;
  const _ActivityPlatinumTile({required this.activity, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final primaryColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final color = activity.color as Color;

    return GestureDetector(
      onTap: () {
        final title = activity.title.toString().toLowerCase();
        if (title.contains('note') || title.contains('grade')) {
           Navigator.pushNamed(context, '/grades');
        } else if (title.contains('devoir') || title.contains('homework')) {
           Navigator.pushNamed(context, '/homework');
        } else if (title.contains('absence')) {
           Navigator.pushNamed(context, '/absences');
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white,
          borderRadius: BorderRadius.circular(32),
          border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.05)
                  : Colors.black.withValues(alpha: 0.03)),
          boxShadow: isDark
              ? []
              : [
                  BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)
                ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: color.withValues(alpha: 0.2))),
              child: Icon(activity.icon as IconData, color: color, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(activity.title,
                      style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          letterSpacing: -0.5)),
                  const SizedBox(height: 6),
                  Text(activity.detail ?? '',
                      style: TextStyle(
                          color: isDark ? Colors.white60 : Colors.black54,
                          fontSize: 12,
                          fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8)),
              child: Text(activity.date,
                  style: TextStyle(
                      color: isDark ? Colors.white60 : Colors.black54,
                      fontSize: 10,
                      fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}
