import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/models/models.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import './grades_history_screen.dart';

class GradeEntryScreen extends StatefulWidget {
  const GradeEntryScreen({super.key});

  @override
  State<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends State<GradeEntryScreen> {
  final List<ClassModel> classes = <ClassModel>[];
  late ClassModel selectedClass;
  
  final List<String> subjects = ['subj_arabic', 'subj_french', 'subj_math', 'subj_hist_geo'];
  String selectedSubject = 'subj_arabic';
  
  final List<String> terms = ['term_1', 'term_2'];
  String selectedTerm = 'term_1';
  
  final List<String> assignments = ['assign_1', 'assign_2', 'assign_3', 'assign_exam'];
  String selectedAssignment = 'assign_1';

  final Map<String, List<String>> _subjectComponents = {
    'subj_arabic': ['الإستماع والتحدث', 'النقل', 'الخط', 'الإملاء', 'القراءة', 'التعبير الكتابي'],
    'subj_french': ['Lecture', 'Conjugaison', 'Grammaire', 'Orthographe', 'Dictée', 'Production Écrite'],
    'subj_math': ['Calcul', 'Géométrie', 'Mesures', 'Résolution de P.'],
    'subj_hist_geo': ['Histoire', 'Géographie', 'Education Civique'],
  };

  @override
  void initState() {
    super.initState();
    selectedClass = classes.isNotEmpty ? classes[0] : ClassModel(id: '', name: 'Aucune', students: [], studentCount: 0);
  }

  void _showGradesTable() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;
    final components = _subjectComponents[selectedSubject] ?? [];

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Grades Table',
      transitionDuration: 400.ms,
      pageBuilder: (context, animation, secondaryAnimation) {
        return StatefulBuilder(
          builder: (context, setStateModal) {
            return Center(
              child: Container(
                width: MediaQuery.of(context).size.width * 0.95,
                height: MediaQuery.of(context).size.height * 0.8,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 10))],
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white, width: 1),
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Header
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.translate('grade_entry_title'),
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: primaryTextColor),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(context),
                              icon: Icon(Icons.close_rounded, color: secondaryTextColor),
                            ),
                          ],
                        ),
                      ),
                      
                      // Massar Indicator
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('Composantes Massar:', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold, fontSize: 11)),
                            ...components.map((c) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                              child: Text(c, style: TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                            )),
                          ],
                        ),
                      ),
                      
                      Container(height: 1, color: isDark ? Colors.white10 : Colors.white),
                      
                      // Table Area
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: const BouncingScrollPhysics(),
                          child: SingleChildScrollView(
                            physics: const BouncingScrollPhysics(),
                            child: Theme(
                              data: Theme.of(context).copyWith(
                                dividerColor: isDark ? Colors.white10 : Colors.white,
                              ),
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white.withValues(alpha: 0.5)),
                                dataRowMinHeight: 60,
                                dataRowMaxHeight: 60,
                                columnSpacing: 30,
                                border: TableBorder.all(color: isDark ? Colors.white10 : Colors.white, width: 1),
                                columns: [
                                  DataColumn(label: Text(AppLocalizations.of(context)!.translate('table_student_header'), style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor, fontSize: 12))),
                                  DataColumn(label: Text(AppLocalizations.of(context)!.translate('table_grade_header'), style: TextStyle(fontWeight: FontWeight.w900, color: secondaryTextColor, fontSize: 12))),
                                  ...components.map((c) => DataColumn(label: Text(c, style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor, fontSize: 11)))),
                                ],
                                rows: selectedClass.students.map((student) {
                                  return DataRow(
                                    cells: [
                                      DataCell(Text(student.name, style: TextStyle(fontWeight: FontWeight.bold, color: primaryTextColor, fontSize: 12))),
                                      DataCell(Text('—', style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w900))),
                                      ...components.map((c) => DataCell(
                                        Container(
                                          width: 60,
                                          height: 36,
                                          decoration: BoxDecoration(
                                            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
                                          ),
                                          child: TextField(
                                            textAlign: TextAlign.center,
                                            keyboardType: TextInputType.number,
                                            style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w900, fontSize: 13),
                                            decoration: InputDecoration(
                                              border: InputBorder.none,
                                              hintText: '—',
                                              hintStyle: TextStyle(color: secondaryTextColor),
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                                            ),
                                          ),
                                        ),
                                      )),
                                    ],
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
                      
                      // Footer Actions
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.white)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.1))),
                              ),
                              child: Text(AppLocalizations.of(context)!.translate('cancel_uppercase'), style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w900, fontSize: 12)),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(AppLocalizations.of(context)!.translate('table_save_success'), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                                    backgroundColor: Colors.blueAccent,
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blueAccent,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                elevation: 0,
                              ),
                              icon: const Icon(Icons.save_rounded, size: 18),
                              label: Text(AppLocalizations.of(context)!.translate('save_btn'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9), curve: Curves.easeOutExpo);
          }
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutExpo)),
          child: child,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;

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
        title: Text(AppLocalizations.of(context)!.translate('report_cards'), style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor, fontSize: 18)),
        actions: [
          IconButton(
            icon: Icon(Icons.history_rounded, color: primaryTextColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const GradesHistoryScreen())),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context)!.translate('report_cards'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, color: primaryTextColor, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context)!.translate('grade_selection_subtitle'), style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 40),

                // Filters Top Row
                Row(
                  children: [
                    Expanded(child: _buildDropdown(classes.map((c) => c.name).toList(), selectedClass.name, (v) {
                       setState(() => selectedClass = classes.firstWhere((c) => c.name == v));
                    }, isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdown(subjects, selectedSubject, (v) => setState(() => selectedSubject = v!), isDark)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildDropdown(terms, selectedTerm, (v) => setState(() => selectedTerm = v!), isDark)),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Filters Bottom Row & Button
                Row(
                  children: [
                    Expanded(flex: 2, child: _buildDropdown(assignments, selectedAssignment, (v) => setState(() => selectedAssignment = v!), isDark)),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 1,
                      child: ElevatedButton.icon(
                        onPressed: _showGradesTable,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[800],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text(AppLocalizations.of(context)!.translate('table_open_btn'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
                      ),
                    ),
                  ],
                ),
                
                const Spacer(),
                Center(
                  child: Icon(Icons.my_library_books_rounded, size: 120, color: isDark ? Colors.white10 : Colors.white),
                ),
                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(List<String> items, String value, void Function(String?) onChanged, bool isDark) {
    if (!items.contains(value) && items.isNotEmpty) {
      value = items.first;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white38 : Colors.black38),
          style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w900, fontSize: 13),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(AppLocalizations.of(context)!.translate(i)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
