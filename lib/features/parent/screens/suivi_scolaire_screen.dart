import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../viewmodels/suivi_view_model.dart';

class SuiviScolaireScreen extends StatefulWidget {
  final StudentModel student;
  const SuiviScolaireScreen({super.key, required this.student});

  @override
  State<SuiviScolaireScreen> createState() => _SuiviScolaireScreenState();
}

class _SuiviScolaireScreenState extends State<SuiviScolaireScreen> {
  int _activeTab = 0;
  int _currentMonthIndex = 6;
  int _selectedSubjectIndex = 0;
  late String _selectedYear;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final startYear = now.month >= 9 ? now.year : now.year - 1;
    _selectedYear = '$startYear - ${startYear + 1}';

    // Fetch data on load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SuiviViewModel>().fetchSuiviData(widget.student.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: primaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.5), width: 2),
                image: widget.student.name.isNotEmpty 
                  ? DecorationImage(
                      image: NetworkImage('https://ui-avatars.com/api/?name=${widget.student.name}&background=0D8ABC&color=fff'),
                      fit: BoxFit.cover,
                    )
                  : null,
              ),
              child: widget.student.name.isEmpty 
                ? const Icon(Icons.person_rounded, color: Colors.blueAccent, size: 20)
                : null,
            ),
            const SizedBox(width: 12),
            Text(
              '${AppLocalizations.of(context)!.translate('tracking')}: ${widget.student.name.split(' ')[0]}', 
              style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: -0.5)
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(70),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
                  ),
                  child: Row(
                    children: [
                      _buildTab(AppLocalizations.of(context)!.translate('evaluations'), 0, isDark),
                      _buildTab(AppLocalizations.of(context)!.translate('evolution'), 1, isDark),
                      _buildTab(AppLocalizations.of(context)!.translate('absences_tab'), 2, isDark),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Consumer<SuiviViewModel>(
                  builder: (context, vm, child) {
                    if (vm.isLoading && vm.grades.isEmpty && vm.absences.isEmpty) {
                      return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
                    }

                    if (vm.errorMessage != null && vm.grades.isEmpty && vm.absences.isEmpty) {
                       return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline_rounded, size: 64, color: Colors.redAccent.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text(vm.errorMessage!, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => vm.fetchSuiviData(widget.student.id), 
                              child: const Text("Réessayer")
                            ),
                          ],
                        ),
                      );
                    }

                    return AnimatedSwitcher(
                      duration: 400.ms,
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      child: _getActiveTabContent(isDark, vm),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _getActiveTabContent(bool isDark, SuiviViewModel vm) {
    switch (_activeTab) {
      case 0: return KeyedSubtree(key: const ValueKey(0), child: _buildEvaluationsTab(isDark, vm));
      case 1: return KeyedSubtree(key: const ValueKey(1), child: _buildEvolutionTab(isDark, vm));
      case 2: return KeyedSubtree(key: const ValueKey(2), child: _buildAbsencesTab(isDark, vm));
      default: return const SizedBox.shrink();
    }
  }

  Widget _buildTab(String label, int index, bool isDark) {
    bool isActive = _activeTab == index;
    final activeText = isDark ? const Color(0xFF0F172A) : Colors.white;
    final inactiveText = isDark ? Colors.white54 : Colors.black54;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _activeTab = index),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: 300.ms,
          curve: Curves.easeOutCubic,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: isActive 
              ? const LinearGradient(colors: [Colors.blueAccent, Colors.indigoAccent], begin: Alignment.topLeft, end: Alignment.bottomRight)
              : null,
            color: isActive ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isActive ? [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? activeText : inactiveText,
              fontWeight: isActive ? FontWeight.w900 : FontWeight.bold,
              fontSize: 10,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAcademicHeader(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    const int joinYear = 2020;
    final now = DateTime.now();
    final currentStartYear = now.month >= 9 ? now.year : now.year - 1;
    
    List<String> years = [];
    for (int y = currentStartYear; y >= joinYear; y--) {
      years.add('$y - ${y + 1}');
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppLocalizations.of(context)!.translate('academic_year'), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedYear,
              icon: Icon(Icons.keyboard_arrow_down_rounded, color: textColor.withValues(alpha: 0.3), size: 20),
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              onChanged: (v) => setState(() => _selectedYear = v!),
              items: years.map((y) => DropdownMenuItem(
                value: y,
                child: Text(y, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 18)),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationsTab(bool isDark, SuiviViewModel vm) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    final grades = vm.grades;

    if (grades.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.blueAccent.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.translate('no_history'), style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      itemCount: grades.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _buildAcademicHeader(context, isDark);
        final grade = grades[index - 1];
        final subjectName = AppLocalizations.of(context)!.translate(grade.subject);
        final appreciation = grade.comment != null 
            ? AppLocalizations.of(context)!.translate(grade.comment!)
            : "";
        
        final trend = index % 2 == 0 ? '+' : '-'; // Placeholder for trend
        final color = (index % 3 == 0 ? Colors.blueAccent : index % 3 == 1 ? Colors.orangeAccent : Colors.purpleAccent);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8)),
            boxShadow: [if (!isDark) BoxShadow(color: Colors.white.withValues(alpha: 0.7), blurRadius: 20, offset: const Offset(0, 5))],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 56, height: 56,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [color.withValues(alpha: 0.3), color.withValues(alpha: 0.1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withValues(alpha: 0.2)),
                          ),
                          child: Icon(
                            index % 3 == 0 ? Icons.calculate_rounded : index % 3 == 1 ? Icons.menu_book_rounded : Icons.science_rounded,
                            color: color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(subjectName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: primaryTextColor, letterSpacing: -0.5)),
                              const SizedBox(height: 6),
                              Text('${AppLocalizations.of(context)!.translate(grade.type)} • ${grade.date}', style: TextStyle(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${grade.grade}/${grade.maxGrade}',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: primaryTextColor),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: trend == '+' ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(trend == '+' ? Icons.trending_up : Icons.trending_down, size: 12, color: trend == '+' ? Colors.greenAccent : Colors.redAccent),
                                  const SizedBox(width: 6),
                                  Text(
                                    trend == '+' ? '+1.5' : '-0.5',
                                    style: TextStyle(color: trend == '+' ? Colors.greenAccent : Colors.redAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(AppLocalizations.of(context)!.translate('class_avg_short').toUpperCase(), style: TextStyle(color: secondaryTextColor, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                            const SizedBox(height: 4),
                            Text('${grade.classAverage ?? "N/A"}/20', style: TextStyle(color: primaryTextColor, fontSize: 13, fontWeight: FontWeight.w900)),
                          ],
                        ),
                        GestureDetector(
                          onTap: () {
                            showModalBottomSheet(
                              context: context,
                              backgroundColor: Colors.transparent,
                              isScrollControlled: true,
                              builder: (context) => _buildAcademicHistorySheet(context, isDark, grade.subject, color, vm),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: secondaryTextColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.history_rounded, size: 14, color: secondaryTextColor),
                                const SizedBox(width: 8),
                                Text(AppLocalizations.of(context)!.translate('academic_history').toUpperCase(), style: TextStyle(color: secondaryTextColor, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: color.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppLocalizations.of(context)!.translate('teacher_appreciation').toUpperCase(), style: TextStyle(color: color, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                          const SizedBox(height: 8),
                          Text(
                            appreciation,
                            style: TextStyle(color: primaryTextColor.withValues(alpha: 0.7), fontSize: 12, fontWeight: FontWeight.w600, height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.05);
      },
    );
  }

  Widget _buildAcademicHistorySheet(BuildContext context, bool isDark, String subjectId, Color color, SuiviViewModel vm) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;
    
    // Filter history for exact subject if available
    final history = vm.grades.where((g) => g.subject == subjectId).toList();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 48, height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(Icons.history_rounded, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.translate('academic_history'), style: TextStyle(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(AppLocalizations.of(context)!.translate(subjectId), style: TextStyle(color: primaryTextColor, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                  ],
                ),
              ),
              IconButton(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.close_rounded, color: secondaryTextColor),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (history.isEmpty)
              Center(child: Text(AppLocalizations.of(context)!.translate('no_history'), style: TextStyle(color: secondaryTextColor)))
          else
            ...history.map((h) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildHistoryRow(
                AppLocalizations.of(context)!.translate(h.type), 
                h.date, 
                '${h.grade}/${h.maxGrade}', 
                '+0.0', // Trend placeholder
                true, 
                isDark, 
                color
              ),
            )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(String title, String date, String score, String trend, bool isPositive, bool isDark, Color themeColor) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w900, fontSize: 15)),
              const SizedBox(height: 6),
              Text(date, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 11, fontWeight: FontWeight.bold)),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(score, style: TextStyle(color: themeColor, fontWeight: FontWeight.w900, fontSize: 18)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.redAccent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(isPositive ? Icons.trending_up : Icons.trending_down, size: 10, color: isPositive ? Colors.greenAccent : Colors.redAccent),
                    const SizedBox(width: 4),
                    Text(trend, style: TextStyle(color: isPositive ? Colors.greenAccent : Colors.redAccent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionTab(bool isDark, SuiviViewModel vm) {
    final schoolSubjects = [
      AppLocalizations.of(context)!.translate('math'), 
      AppLocalizations.of(context)!.translate('french_sub'), 
      AppLocalizations.of(context)!.translate('science'), 
      AppLocalizations.of(context)!.translate('history_geo')
    ];
    
    final allSpots = [
      const [FlSpot(0, 14), FlSpot(1, 15.5), FlSpot(2, 14.8), FlSpot(3, 16.2), FlSpot(4, 15.8)],
      const [FlSpot(0, 12), FlSpot(1, 13.5), FlSpot(2, 15.0), FlSpot(3, 14.5), FlSpot(4, 16.0)],
      const [FlSpot(0, 15), FlSpot(1, 14.0), FlSpot(2, 16.5), FlSpot(3, 17.0), FlSpot(4, 16.2)],
      const [FlSpot(0, 13), FlSpot(1, 15.0), FlSpot(2, 15.8), FlSpot(3, 14.2), FlSpot(4, 14.5)],
    ];
    
    final currentSpots = allSpots[_selectedSubjectIndex];

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAcademicHeader(context, isDark),
          _buildSummaryCard(isDark, vm).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 48),
          
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: schoolSubjects.asMap().entries.map((entry) {
                final index = entry.key;
                final subject = entry.value;
                final isSelected = _selectedSubjectIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedSubjectIndex = index),
                    child: AnimatedContainer(
                      duration: 300.ms,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.blueAccent : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8)),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isSelected ? Colors.blueAccent : (isDark ? Colors.white10 : Colors.white)),
                      ),
                      child: Text(
                        subject, 
                        style: TextStyle(color: isSelected ? Colors.white : (isDark ? Colors.white38 : Colors.black45), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ).animate().fadeIn(delay: 300.ms),
          
          const SizedBox(height: 40),
          Text(
            AppLocalizations.of(context)!.translate('quarterly_progression'), 
            style: TextStyle(
              color: isDark ? Colors.white54 : Colors.black45, 
              fontSize: 11, 
              fontWeight: FontWeight.w900, 
              letterSpacing: 2
            )
          ).animate().fadeIn(delay: 400.ms),
          const SizedBox(height: 24),
          _buildEvolutionChart(isDark, currentSpots).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
          const SizedBox(height: 16), // Tightly coupled space
          _buildSimpleExtremas(isDark, currentSpots).animate().fadeIn(delay: 600.ms),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(bool isDark, SuiviViewModel vm) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8)),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.white.withValues(alpha: 0.7), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.translate('general_average').toUpperCase(), style: TextStyle(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                   Text(widget.student.average.toStringAsFixed(2), style: TextStyle(color: primaryTextColor, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
                   const SizedBox(width: 8),
                   Text('/20', style: TextStyle(color: secondaryTextColor, fontSize: 18, fontWeight: FontWeight.w900)),
                ],
              ),
            ],
          ),
          Container(
             width: 1.5, height: 60,
             color: secondaryTextColor.withValues(alpha: 0.1),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppLocalizations.of(context)!.translate('rank').toUpperCase(), style: TextStyle(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 12),
              Text('05/32', style: TextStyle(color: Colors.blueAccent, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionChart(bool isDark, List<FlSpot> spots) {
    return Container(
      height: 220,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, right: 20),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: true, drawVerticalLine: false, horizontalInterval: 5, getDrawingHorizontalLine: (v) => FlLine(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), strokeWidth: 1)),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) {
                  final months = ['SEP', 'NOV', 'JAN', 'MAR', 'MAI'];
                  if (v >= 0 && v < months.length) return Padding(padding: const EdgeInsets.only(top: 12), child: Text(months[v.toInt()], style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w900, fontSize: 9)));
                  return const SizedBox.shrink();
                },
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) => Text(v.toInt().toString(), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w900, fontSize: 9)),
                interval: 5,
                reservedSize: 30,
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          minX: 0, maxX: 4, minY: 10, maxY: 20,
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blueAccent,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(colors: [Colors.blueAccent.withValues(alpha: 0.2), Colors.blueAccent.withValues(alpha: 0)]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleExtremas(bool isDark, List<FlSpot> spots) {
    final highestSpot = spots.reduce((a, b) => a.y > b.y ? a : b);
    final lowestSpot = spots.reduce((a, b) => a.y < b.y ? a : b);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            const Icon(Icons.arrow_downward_rounded, color: Colors.redAccent, size: 14),
            const SizedBox(width: 4),
            Text('${AppLocalizations.of(context)!.translate('min')}: ${lowestSpot.y.toStringAsFixed(1)}/20', style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
          ],
        ),
        Row(
          children: [
            const Icon(Icons.arrow_upward_rounded, color: Colors.greenAccent, size: 14),
            const SizedBox(width: 4),
            Text('${AppLocalizations.of(context)!.translate('max')}: ${highestSpot.y.toStringAsFixed(1)}/20', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 0.5)),
          ],
        ),
      ],
    );
  }

  Widget _buildAbsencesTab(bool isDark, SuiviViewModel vm) {
    final textColor = isDark ? Colors.white54 : Colors.black45;
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAcademicHeader(context, isDark),
          Text(AppLocalizations.of(context)!.translate('academic_summary').toUpperCase(), style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.5)).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildAbsenceStat(vm.unjustifiedAbsences.toString().padLeft(2, '0'), AppLocalizations.of(context)!.translate('unjustified'), Colors.redAccent, isDark),
              const SizedBox(width: 16),
              _buildAbsenceStat(vm.justifiedAbsences.toString().padLeft(2, '0'), AppLocalizations.of(context)!.translate('justified'), Colors.greenAccent, isDark),
              const SizedBox(width: 16),
              _buildAbsenceStat(vm.delays.toString().padLeft(2, '0'), AppLocalizations.of(context)!.translate('delays'), Colors.orangeAccent, isDark),
            ],
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 48),
          _buildAttendanceDistribution(isDark, vm).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 48),
          _buildAttendanceCalendar(isDark).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
          const SizedBox(height: 48),
          Text(
            AppLocalizations.of(context)!.translate('recent_history').toUpperCase(), 
            style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2.5)
          ).animate().fadeIn(delay: 500.ms),
          const SizedBox(height: 24),
          _buildRecentHistory(isDark, vm).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildAbsenceStat(String value, String label, Color color, bool isDark) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: isDark ? color.withValues(alpha: 0.05) : color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 32)),
            const SizedBox(height: 8),
            Text(label.toUpperCase(), style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceDistribution(bool isDark, SuiviViewModel vm) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;
    final rate = vm.attendanceRate;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
      ),
      child: Row(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 130, height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.15), blurRadius: 40, spreadRadius: -5),
                  ],
                ),
              ),
              SizedBox(
                width: 120, height: 120,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 0,
                    centerSpaceRadius: 48,
                    sections: [
                      PieChartSectionData(color: Colors.greenAccent, value: rate, radius: 14, showTitle: false, badgeWidget: null),
                      PieChartSectionData(color: Colors.redAccent.withValues(alpha: 0.2), value: 100 - rate, radius: 14, showTitle: false),
                    ],
                  ),
                ).animate().rotate(duration: 1200.ms, curve: Curves.easeOutBack),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${rate.toInt()}%', style: TextStyle(color: primaryTextColor, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -1)),
                ],
              ),
            ],
          ),
          const SizedBox(width: 40),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.translate('attendance_short').toUpperCase(), style: TextStyle(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
                const SizedBox(height: 8),
                Text(
                  rate >= 90 ? AppLocalizations.of(context)!.translate('excellent') : AppLocalizations.of(context)!.translate('good_status'), 
                  style: TextStyle(
                    color: Colors.greenAccent, 
                    fontSize: 22, 
                    fontWeight: FontWeight.w900, 
                    letterSpacing: -0.5,
                    shadows: [Shadow(color: Colors.greenAccent.withValues(alpha: 0.3), blurRadius: 20)]
                  )
                ).animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.greenAccent.withValues(alpha: 0.1), 
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.2))
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 14),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.translate('verified').toUpperCase(), 
                        style: const TextStyle(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceCalendar(bool isDark) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textColor = isDark ? Colors.white54 : Colors.black45;
    final schoolMonths = [
      {'key': 'september', 'month': 9}, {'key': 'october', 'month': 10}, 
      {'key': 'november', 'month': 11}, {'key': 'december', 'month': 12}, 
      {'key': 'january', 'month': 1}, {'key': 'february', 'month': 2}, 
      {'key': 'march', 'month': 3}, {'key': 'april', 'month': 4}, 
      {'key': 'may', 'month': 5}, {'key': 'june', 'month': 6}
    ];
    
    final currentMonthData = schoolMonths[_currentMonthIndex];
    final realMonth = currentMonthData['month'] as int;
    final yearParts = _selectedYear.split(' - ');
    final realYear = int.parse(realMonth >= 9 ? yearParts[0] : yearParts[1]);
    
    final currentMonthLabel = AppLocalizations.of(context)!.translate(currentMonthData['key'] as String);
    final daysInMonth = DateTime(realYear, realMonth + 1, 0).day;
    final firstDay = DateTime(realYear, realMonth, 1);
    final offset = firstDay.weekday - 1;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(40),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white),
        boxShadow: [if (!isDark) BoxShadow(color: Colors.white.withValues(alpha: 0.7), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$currentMonthLabel $realYear', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: primaryTextColor)),
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _currentMonthIndex = (_currentMonthIndex > 0) ? _currentMonthIndex - 1 : 9),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8), shape: BoxShape.circle),
                      child: Icon(Icons.chevron_left_rounded, color: primaryTextColor.withValues(alpha: 0.5), size: 20),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () => setState(() => _currentMonthIndex = (_currentMonthIndex < 9) ? _currentMonthIndex + 1 : 0),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8), shape: BoxShape.circle),
                      child: Icon(Icons.chevron_right_rounded, color: primaryTextColor.withValues(alpha: 0.5), size: 20),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              'L', 'M', 'M', 'J', 'V', 'S', 'D'
            ].map((d) => SizedBox(
              width: 32,
              child: Text(d, textAlign: TextAlign.center, style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1))
            )).toList(),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 8),
            itemCount: 42,
            itemBuilder: (context, index) {
              final dayNum = index - offset + 1;
              if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox.shrink();
              
              // Simplified mock attendance check
              final isAbsent = [3, 14, 22].contains(dayNum); 
              final isLate = [7, 25].contains(dayNum);
              final isToday = dayNum == DateTime.now().day && realMonth == DateTime.now().month;

              return Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isAbsent ? Colors.redAccent.withValues(alpha: 0.1) : (isLate ? Colors.orangeAccent.withValues(alpha: 0.1) : (isToday ? Colors.blueAccent : Colors.transparent)),
                  borderRadius: BorderRadius.circular(10),
                  border: isAbsent ? Border.all(color: Colors.redAccent.withValues(alpha: 0.2)) : (isLate ? Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)) : null),
                ),
                child: Text(dayNum.toString(), style: TextStyle(color: isAbsent ? Colors.redAccent : (isLate ? Colors.orangeAccent : (isToday ? Colors.white : primaryTextColor)), fontWeight: FontWeight.w900, fontSize: 11)),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecentHistory(bool isDark, SuiviViewModel vm) {
    if (vm.absences.isEmpty) {
        return Center(
          child: Text(AppLocalizations.of(context)!.translate('no_history'), style: const TextStyle(color: Colors.white54))
        );
    }

    return Column(
      children: vm.absences.map((a) {
        Color color;
        IconData icon;
        switch (a.status) {
          case 'absent': 
            color = Colors.redAccent;
            icon = Icons.cancel_rounded;
            break;
          case 'late':
            color = Colors.orangeAccent;
            icon = Icons.watch_later_rounded;
            break;
          default:
            color = Colors.greenAccent;
            icon = Icons.check_circle_rounded;
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(AppLocalizations.of(context)!.translate(a.status), style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 16)),
                    if (a.motif != null) ...[
                       const SizedBox(height: 4),
                       Text(a.motif!, style: const TextStyle(color: Colors.white38, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ],
                ),
              ),
              Text(a.date, style: TextStyle(color: isDark ? Colors.white54 : Colors.black45, fontSize: 11, fontWeight: FontWeight.w900)),
            ],
          ),
        );
      }).toList(),
    );
  }
}
