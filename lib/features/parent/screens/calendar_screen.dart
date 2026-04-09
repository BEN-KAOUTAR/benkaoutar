import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../viewmodels/calendar_view_model.dart';
import 'package:intl/intl.dart';

class CalendarScreen extends StatefulWidget {
  final StudentModel student;
  const CalendarScreen({super.key, required this.student});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  late DateTime _currentMonth;

  @override
  void initState() {
    super.initState();
    _currentMonth = DateTime(_selectedDate.year, _selectedDate.month);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData();
    });
  }

  void _fetchData() {
     context.read<CalendarViewModel>().fetchEvents(widget.student.id, _currentMonth.month, _currentMonth.year);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;
    final loc = AppLocalizations.of(context)!;

    return Consumer<CalendarViewModel>(
      builder: (context, vm, child) {
        final dayEvents = vm.events.where((e) {
          try {
            final eventDate = DateTime.parse(e.date);
            return eventDate.year == _selectedDate.year && 
                   eventDate.month == _selectedDate.month && 
                   eventDate.day == _selectedDate.day;
          } catch (_) {
            return false;
          }
        }).toList();

        final upcomingExams = vm.events.where((e) => e.type.toLowerCase().contains('exam')).toList();

        return Scaffold(
          extendBodyBehindAppBar: true,
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white, shape: BoxShape.circle),
                child: Icon(Icons.arrow_back_ios_new_rounded, color: primaryTextColor, size: 16),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(loc.translate('calendar_title'), style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor, fontSize: 20, letterSpacing: -0.5)),
            centerTitle: true,
            actions: [
              IconButton(
                icon: Icon(Icons.filter_list_rounded, color: secondaryTextColor),
                onPressed: () {},
              ),
            ],
          ),
          body: DeepSpaceBackground(
            showOrbs: true,
            child: SafeArea(
              child: Builder(
                builder: (context) {
                  if (vm.isLoading && vm.events.isEmpty) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (vm.errorMessage != null && vm.events.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 64, color: Colors.blueAccent.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text(loc.translate(vm.errorMessage!), style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w900, fontSize: 16)),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _fetchData,
                            child: Text(loc.translate('retry')),
                          ),
                        ],
                      ),
                    );
                  }
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUpcomingExamsHeader(context, isDark, upcomingExams),
                    const SizedBox(height: 48),
                    _buildCalendarGrid(context, isDark, vm.events),
                    const SizedBox(height: 48),
                    Text(
                      DateFormat('EEEE d MMMM yyyy', 'fr_FR').format(_selectedDate).toUpperCase(),
                      style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: secondaryTextColor, letterSpacing: 2),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 24),
                    if (dayEvents.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Text(loc.translate('no_events'), style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                        ),
                      )
                    else
                      ...dayEvents.map((e) => _buildEventCard(
                        context: context,
                        title: e.title,
                        time: e.time,
                        location: e.location ?? 'Salle 12',
                        type: e.type,
                        color: e.type.toLowerCase().contains('exam') ? Colors.redAccent : Colors.orangeAccent,
                        showRSVP: true,
                      )),
                    const SizedBox(height: 100),
                  ],
                ),
              );
              }
            ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpcomingExamsHeader(BuildContext context, bool isDark, List<EventModel> exams) {
    final loc = AppLocalizations.of(context)!;
    if (exams.isEmpty) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(loc.translate('upcoming_evaluations').toUpperCase(), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: exams.length,
            itemBuilder: (context, index) {
              final exam = exams[index];
              final dateStr = DateFormat('dd MMM').format(DateTime.parse(exam.date)).toUpperCase();
              return _buildExamMiniCard(context, exam.title, dateStr, Colors.blueAccent);
            },
          ),
        ),
      ],
    ).animate().fadeIn(duration: 600.ms).slideX(begin: 0.1);
  }

  Widget _buildExamMiniCard(BuildContext context, String title, String date, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: 150,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(Icons.assignment_turned_in_rounded, color: color, size: 20),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 14), maxLines: 2, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(date, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarGrid(BuildContext context, bool isDark, List<EventModel> allEvents) {
    final loc = AppLocalizations.of(context)!;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;

    final monthName = DateFormat('MMMM yyyy', 'fr_FR').format(_currentMonth);

    // Basic calendar logic for current month
    final firstDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final lastDayOfMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final firstWeekday = (firstDayOfMonth.weekday - 1) % 7; 
    final daysInMonth = lastDayOfMonth.day;
    final prevMonthLastDay = DateTime(_currentMonth.year, _currentMonth.month, 0).day;

    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(monthName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: primaryTextColor, letterSpacing: -0.5)),
                  Row(
                    children: [
                      _buildIconButton(Icons.chevron_left_rounded, isDark, () {
                        setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1, 1);
                          _fetchData();
                        });
                      }),
                      const SizedBox(width: 8),
                      _buildIconButton(Icons.chevron_right_rounded, isDark, () {
                        setState(() {
                          _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1, 1);
                          _fetchData();
                        });
                      }),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  loc.translate('mon'),
                  loc.translate('tue'),
                  loc.translate('wed'),
                  loc.translate('thu'),
                  loc.translate('fri'),
                  loc.translate('sat'),
                  loc.translate('sun')
                ]
                .map((d) => SizedBox(width: 32, child: Center(child: Text(d, style: TextStyle(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1)))))
                .toList(),
              ),
              const SizedBox(height: 24),
              ...List.generate(6, (weekIndex) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(7, (dayIndex) {
                      final calendarPos = weekIndex * 7 + dayIndex;
                      final dayNum = calendarPos - firstWeekday + 1;
                      
                      bool isCurrentMonth = dayNum > 0 && dayNum <= daysInMonth;
                      int displayDay = dayNum;
                      if (!isCurrentMonth) {
                        if (dayNum <= 0) displayDay = prevMonthLastDay + dayNum;
                        else displayDay = dayNum - daysInMonth;
                      }

                      final dateToCheck = isCurrentMonth 
                          ? DateTime(_currentMonth.year, _currentMonth.month, dayNum)
                          : (dayNum <= 0 
                              ? DateTime(_currentMonth.year, _currentMonth.month - 1, displayDay)
                              : DateTime(_currentMonth.year, _currentMonth.month + 1, displayDay));

                      bool isSelected = dateToCheck.year == _selectedDate.year && 
                                       dateToCheck.month == _selectedDate.month && 
                                       dateToCheck.day == _selectedDate.day;

                      final dayEvents = allEvents.where((e) {
                         try {
                           final ed = DateTime.parse(e.date);
                           return ed.year == dateToCheck.year && ed.month == dateToCheck.month && ed.day == dateToCheck.day;
                         } catch(_) { return false; }
                      }).toList();

                      bool hasEvent = dayEvents.isNotEmpty;
                      bool isExam = dayEvents.any((e) => e.type.toLowerCase().contains('exam'));

                      return GestureDetector(
                        onTap: () => setState(() => _selectedDate = dateToCheck),
                        child: AnimatedContainer(
                          duration: 300.ms,
                          width: 36, height: 36,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.blueAccent : (hasEvent ? (isExam ? Colors.redAccent.withValues(alpha: 0.1) : Colors.orangeAccent.withValues(alpha: 0.1)) : Colors.transparent),
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected ? [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
                            border: hasEvent && !isSelected ? Border.all(color: isExam ? Colors.redAccent.withValues(alpha: 0.3) : Colors.orangeAccent.withValues(alpha: 0.3)) : null,
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('$displayDay', 
                                  style: TextStyle(
                                    color: !isCurrentMonth ? secondaryTextColor.withValues(alpha: 0.2) : (isSelected ? Colors.white : (hasEvent ? (isExam ? Colors.redAccent : Colors.orangeAccent) : primaryTextColor)), 
                                    fontWeight: FontWeight.w900,
                                    fontSize: 13
                                  )),
                                if (hasEvent && isCurrentMonth && !isSelected) ...[
                                  const SizedBox(height: 2),
                                  Container(width: 4, height: 4, decoration: BoxDecoration(color: isExam ? Colors.redAccent : Colors.orangeAccent, shape: BoxShape.circle)),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildIconButton(IconData icon, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDark ? Colors.white60 : Colors.black54, size: 18),
      ),
    );
  }

  Widget _buildEventCard({
    required BuildContext context,
    required String title,
    required String time,
    required String location,
    required String type,
    required Color color,
    bool showRSVP = false,
    String rsvpLabel = 'OUI, JE SERAI LÀ',
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white60 : Colors.black54;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: isDark ? color.withValues(alpha: 0.1) : Colors.white),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(36),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(type.toUpperCase(), style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                    ),
                    const Spacer(),
                    Icon(Icons.more_horiz_rounded, color: secondaryTextColor),
                  ],
                ),
                const SizedBox(height: 24),
                Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: primaryTextColor, letterSpacing: -0.5)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _buildMetaInfo(Icons.access_time_rounded, time, secondaryTextColor),
                    const SizedBox(width: 24),
                    _buildMetaInfo(Icons.location_on_rounded, location, secondaryTextColor),
                  ],
                ),
                if (showRSVP) ...[
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            side: BorderSide(color: isDark ? Colors.white10 : Colors.black12, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: Text(AppLocalizations.of(context)!.translate('reminder').toUpperCase(), style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 8))],
                          ),
                          child: ElevatedButton(
                            onPressed: () {},
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                              foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: Text(rsvpLabel.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildMetaInfo(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
