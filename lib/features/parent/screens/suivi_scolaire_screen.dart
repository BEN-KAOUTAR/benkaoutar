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
              'Performance Académique', 
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



  Widget _buildEvaluationsTab(bool isDark, SuiviViewModel vm) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    final groupedGrades = vm.groupedGrades;
    final subjects = groupedGrades.keys.toList();

    if (groupedGrades.isEmpty) {
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
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        final subjectId = subjects[index];
        final subjectAvg = vm.calculateSubjectAverage(subjectId);

        final subjectName = AppLocalizations.of(context)!.translate(subjectId);
        final color = (index % 4 == 0 ? Colors.blueAccent : index % 4 == 1 ? Colors.orangeAccent : index % 4 == 2 ? Colors.purpleAccent : const Color(0xFF10B981));

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B2336) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.04), width: 1.5),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04), blurRadius: 20, offset: const Offset(0, 8)),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Pop Icon badge
                Container(
                  width: 54, height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [color.withValues(alpha: 0.75), color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: Icon(
                    index % 4 == 0 ? Icons.calculate_rounded
                      : index % 4 == 1 ? Icons.menu_book_rounded
                      : index % 4 == 2 ? Icons.science_rounded
                      : Icons.history_edu_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                // Subject info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(subjectName,
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17, color: primaryTextColor, letterSpacing: -0.3),
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // Soft Classement pill
                      Builder(builder: (ctx) {
                        final rank = vm.getSubjectRank(subjectId);
                        final classSize = vm.getSubjectClassSize(subjectId);
                        
                        String label = "Classement: --";
                        if (rank != null) {
                          final suffix = rank == 1 ? 'er' : 'e';
                          label = classSize != null ? '$rank$suffix / $classSize' : '$rank$suffix';
                        }
                        
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.military_tech_rounded, size: 14, color: isDark ? Colors.white54 : Colors.black54),
                              const SizedBox(width: 4),
                              Text(label, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      // Soft History link button
                      GestureDetector(
                        onTap: () {
                          showModalBottomSheet(
                            context: context,
                            backgroundColor: Colors.transparent,
                            isScrollControlled: true,
                            builder: (context) => _buildAcademicHistorySheet(context, isDark, subjectId, color, vm),
                          );
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.history_rounded, size: 15, color: color.withValues(alpha: 0.8)),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)!.translate('academic_history'),
                              style: TextStyle(color: color.withValues(alpha: 0.8), fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.2),
                            ),
                            Icon(Icons.chevron_right_rounded, size: 16, color: color.withValues(alpha: 0.7)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Soft Score pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: color.withValues(alpha: 0.15), width: 1.5),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        subjectAvg.toStringAsFixed(1),
                        style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: color, height: 1.1, letterSpacing: -0.5),
                      ),
                      Text('/20', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: color.withValues(alpha: 0.65))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: (index * 80).ms).slideY(begin: 0.04);
      },
    );
  }

  Widget _buildAcademicHistorySheet(BuildContext context, bool isDark, String subjectId, Color color, SuiviViewModel vm) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;
    
    // Filter history for exact subject if available
    final history = vm.groupedGrades[subjectId] ?? [];

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
      ),
      padding: const EdgeInsets.fromLTRB(32, 20, 32, 32),
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
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                itemCount: history.length,
                separatorBuilder: (context, index) => const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  final h = history[index];
                  final hLabel = h.title ?? AppLocalizations.of(context)!.translate(h.type);
                  return _buildHistoryRow(
                    "$hLabel${h.semester != null ? ' (Semestre ${h.semester})' : ''}", 
                    h.date, 
                    '${h.grade}/${h.maxGrade}', 
                    '+0.0',
                    true, 
                    isDark, 
                    color
                  );
                },
              ),
            ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHistoryRow(String title, String date, String score, String trend, bool isPositive, bool isDark, Color themeColor) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: themeColor.withValues(alpha: 0.15)),
        boxShadow: [
          BoxShadow(color: themeColor.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Colored bar indicator
          Container(
            width: 4, height: 28,
            decoration: BoxDecoration(
              color: themeColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w800, fontSize: 15)),
          ),
          // Score
          Text(score, style: TextStyle(color: themeColor, fontWeight: FontWeight.w900, fontSize: 20)),
        ],
      ),
    );
  }

  Widget _buildEvolutionTab(bool isDark, SuiviViewModel vm) {
    // Subject keys used in API/ViewModel
    final subjectKeys = vm.evolutionData.keys.toList();
    
    // If empty, use a default list to avoid UI crash, or show empty state
    if (subjectKeys.isEmpty) {
      if (!vm.isLoading) {
        // Option: call setMockEvolution if you want to show SOMETHING during demo
        // vm.setMockEvolution(); 
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Icon(Icons.show_chart_rounded, size: 64, color: Colors.blueAccent.withValues(alpha: 0.3)),
             const SizedBox(height: 16),
             Text(AppLocalizations.of(context)!.translate('no_history'), style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w900)),
          ],
        ),
      );
    }

    // Map keys to localized names
    final schoolSubjects = subjectKeys.map((key) => AppLocalizations.of(context)!.translate(key)).toList();
    
    // Ensure selected index is within bounds
    if (_selectedSubjectIndex >= subjectKeys.length) {
      _selectedSubjectIndex = 0;
    }

    final currentKey = subjectKeys[_selectedSubjectIndex];
    final semesterData = vm.evolutionDataBySemester[currentKey] ?? {};
    final s1Data = semesterData['1'] ?? [];
    final s2Data = semesterData['2'] ?? [];
    
    final List<FlSpot> s1Spots = s1Data.map((p) => FlSpot((p['x'] as num?)?.toDouble() ?? 0.0, (p['y'] as num?)?.toDouble() ?? 0.0)).toList();
    final int s1Count = s1Spots.length;
    final List<FlSpot> s2Spots = s2Data.map((p) => FlSpot(((p['x'] as num?)?.toDouble() ?? 0.0) + s1Count, (p['y'] as num?)?.toDouble() ?? 0.0)).toList();

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

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
          _buildEvolutionChart(isDark, s1Spots, s2Spots).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),
          const SizedBox(height: 16),
          _buildSimpleExtremas(isDark, [...s1Spots, ...s2Spots]).animate().fadeIn(delay: 600.ms),
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
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.translate('global_average').toUpperCase(), style: TextStyle(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 2)),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                   Text(vm.generalAverage.toStringAsFixed(2), style: TextStyle(color: primaryTextColor, fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: -1.5)),
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
              Text('--/--', style: TextStyle(color: Colors.blueAccent, fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -1)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEvolutionChart(bool isDark, List<FlSpot> s1Spots, List<FlSpot> s2Spots) {
    if (s1Spots.isEmpty && s2Spots.isEmpty) return const SizedBox(height: 220);
    
    final combinedSpots = [...s1Spots, ...s2Spots];
    double maxY = 20;
    double minY = 0; 
    
    double maxX = combinedSpots.isNotEmpty ? combinedSpots.map((e) => e.x).reduce((a, b) => a > b ? a : b) : 4;
    if (maxX < 4) maxX = 4;
    
    for (var s in combinedSpots) {
      if (s.y > maxY) maxY = ((s.y / 5).ceil() * 5).toDouble();
    }
    
    int s1Count = s1Spots.length;

    return Container(
      height: 240,
      width: double.infinity,
      padding: const EdgeInsets.only(top: 20, right: 20, left: 10),
      child: LineChart(
        LineChartData(
          gridData: FlGridData(
            show: true, 
            drawVerticalLine: false, 
            horizontalInterval: 5, 
            getDrawingHorizontalLine: (v) => FlLine(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05), 
              strokeWidth: 1,
              dashArray: [8, 8] // Premium dashed grid
            )
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 34,
                getTitlesWidget: (v, meta) {
                  final index = v.toInt();
                  if (index >= 0 && index < combinedSpots.length && v == index) {
                    final dIndex = index >= s1Count ? (index - s1Count + 1) : (index + 1);
                    return Padding(
                      padding: const EdgeInsets.only(top: 10), 
                      child: Text('D$dIndex', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w900, fontSize: 10))
                    );
                  }
                  return const SizedBox.shrink();
                },
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (v, meta) => Text(v.toInt().toString(), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontWeight: FontWeight.w900, fontSize: 10)),
                interval: 5,
                reservedSize: 32,
              ),
            ),
          ),
          extraLinesData: ExtraLinesData(
            verticalLines: [
              if (s1Spots.isNotEmpty && s2Spots.isNotEmpty)
                VerticalLine(
                  x: s1Count - 0.5,
                  color: isDark ? Colors.white.withValues(alpha: 0.15) : Colors.black.withValues(alpha: 0.15),
                  strokeWidth: 2,
                  dashArray: [5, 5],
                  label: VerticalLineLabel(
                    show: true,
                    labelResolver: (l) => " S2 ",
                    style: TextStyle(
                      color: isDark ? Colors.white : Colors.black87, 
                      fontSize: 10, 
                      fontWeight: FontWeight.w900,
                      backgroundColor: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.05),
                    ),
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  ),
                ),
            ],
          ),
          borderData: FlBorderData(show: false),
          minX: 0, maxX: maxX, minY: minY, maxY: maxY,
          lineBarsData: [
            LineChartBarData(
              spots: combinedSpots,
              isCurved: true,
              curveSmoothness: 0.35,
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6), Color(0xFFEC4899)]), // Beautiful gradient line
              barWidth: 5,
              isStrokeCapRound: true,
              shadow: Shadow(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 5)), // Line glow
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 5,
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    strokeWidth: 3,
                    strokeColor: const Color(0xFF8B5CF6), // Purple stroke
                  );
                },
              ),
              belowBarData: BarAreaData(
                show: true,
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.25),
                    const Color(0xFF3B82F6).withValues(alpha: 0.0)
                  ]
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleExtremas(bool isDark, List<FlSpot> spots) {
    if (spots.isEmpty) return const SizedBox.shrink();
    final highestSpot = spots.reduce((a, b) => a.y > b.y ? a : b);
    final lowestSpot = spots.reduce((a, b) => a.y < b.y ? a : b);

    Widget buildBadge(String label, String value, Color color, IconData icon, bool isDark) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 12),
            ),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w800, fontSize: 10, letterSpacing: 0.5)),
            const SizedBox(width: 4),
            Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        buildBadge(AppLocalizations.of(context)!.translate('min'), '${lowestSpot.y.toStringAsFixed(1)}/20', const Color(0xFFEF4444), Icons.arrow_downward_rounded, isDark),
        buildBadge(AppLocalizations.of(context)!.translate('max'), '${highestSpot.y.toStringAsFixed(1)}/20', const Color(0xFF10B981), Icons.arrow_upward_rounded, isDark),
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
