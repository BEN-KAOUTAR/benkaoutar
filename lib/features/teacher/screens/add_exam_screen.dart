import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../../../core/localization/app_localizations.dart';

import '../../../core/widgets/deep_space_background.dart';

class AddExamScreen extends StatefulWidget {
  const AddExamScreen({super.key});

  @override
  State<AddExamScreen> createState() => _AddExamScreenState();
}

class _AddExamScreenState extends State<AddExamScreen> {
  final _formKey = GlobalKey<FormState>();
  String? _selectedClass;
  String? _selectedSubject;
  String? _selectedType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();

  final List<String> _evaluationTypes = ['type_quiz', 'type_exam', 'type_project', 'type_control'];
  final List<String> _subjects = ['subj_math', 'subj_french', 'subj_arabic', 'subj_hist_geo', 'subj_science', 'subj_sport'];

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.blueAccent,
              brightness: Theme.of(context).brightness,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      // Simulate submission
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.translate('announcement_published')),
          backgroundColor: Colors.greenAccent,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final loc = AppLocalizations.of(context)!;

    final classes = <String>[];

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
        title: Text(
          loc.translate('examens'),
          style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  
                  _buildSectionHeader(loc.translate('class_label'), isDark),
                  _buildDropdown(
                    value: _selectedClass,
                    items: classes,
                    hint: loc.translate('select_class_hint'),
                    onChanged: (val) => setState(() => _selectedClass = val),
                    isDark: isDark,
                  ),

                  const SizedBox(height: 24),
                  
                  _buildSectionHeader(loc.translate('subject_label'), isDark),
                  _buildDropdown(
                    value: _selectedSubject,
                    items: _subjects,
                    hint: loc.translate('select_subject_hint'),
                    onChanged: (val) => setState(() => _selectedSubject = val),
                    isDark: isDark,
                  ),

                  const SizedBox(height: 24),
                  
                  _buildSectionHeader(loc.translate('evaluation_type_label'), isDark),
                  _buildDropdown(
                    value: _selectedType,
                    items: _evaluationTypes,
                    hint: loc.translate('evaluation_type_label'),
                    onChanged: (val) => setState(() => _selectedType = val),
                    isDark: isDark,
                  ),

                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(loc.translate('date_label'), isDark),
                            _buildPickerTile(
                              icon: Icons.calendar_today_rounded,
                              label: DateFormat('dd/MM/yyyy').format(_selectedDate),
                              onTap: _pickDate,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSectionHeader(loc.translate('hour_label'), isDark),
                            _buildPickerTile(
                              icon: Icons.access_time_rounded,
                              label: _selectedTime.format(context),
                              onTap: _pickTime,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: Text(
                        loc.translate('validate_upper'),
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white24 : Colors.black26,
          fontSize: 10,
          fontWeight: FontWeight.w900,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          hint: Text(hint, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14)),
          isExpanded: true,
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white38 : Colors.black38),
          dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(AppLocalizations.of(context)!.translate(item), style: TextStyle(color: isDark ? Colors.white : const Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600)),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.05);
  }

  Widget _buildPickerTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.blueAccent, size: 18),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05);
  }
}
