import 'package:flutter/material.dart';

import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';

class AddHomeworkScreen extends StatefulWidget {
  const AddHomeworkScreen({super.key});

  @override
  State<AddHomeworkScreen> createState() => _AddHomeworkScreenState();
}

class _AddHomeworkScreenState extends State<AddHomeworkScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedClass = '';
  String _selectedSubject = '';
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  bool _isPublishing = false;

  @override
  void initState() {
    super.initState();
    _selectedClass = '';
    _selectedSubject = '';
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-sync class selection when locale changes class names
    final classNames = <String>[];
    if (classNames.isNotEmpty && !classNames.contains(_selectedClass)) {
      setState(() => _selectedClass = classNames.first);
    }
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
          icon: Icon(Icons.close_rounded, color: primaryTextColor, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.translate('new_homework'),
            style: TextStyle(
                fontWeight: FontWeight.w900,
                color: primaryTextColor,
                fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _isPublishing ? null : _publish,
              style: TextButton.styleFrom(
                foregroundColor: Colors.blueAccent,
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              child: _isPublishing
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: primaryTextColor))
                  : Text(AppLocalizations.of(context)!.translate('publish'),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          letterSpacing: 1)),
            ),
          ),
        ],
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Subject & Class row
                Row(
                  children: [
                    Expanded(
                      child: _buildDropdown(
                        context,
                        AppLocalizations.of(context)!
                            .translate('subject_label'),
                        _selectedSubject,
                        [
                          'math',
                          'french_sub',
                          'science',
                          'history_geo',
                          'english',
                          'physics',
                          'arabic',
                          'sport'
                        ],
                        (val) => setState(() => _selectedSubject = val!),
                        isSubject: true,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildDropdown(
                        context,
                        AppLocalizations.of(context)!.translate('class_label'),
                        _selectedClass,
                        <String>[].map((c) => c).toList(),
                        (val) => setState(() => _selectedClass = val!),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                    AppLocalizations.of(context)!
                        .translate('homework_title_label'),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: secondaryTextColor,
                        letterSpacing: 1.5)),
                const SizedBox(height: 12),
                TextField(
                  controller: _titleController,
                  style: TextStyle(
                      color: primaryTextColor,
                      fontSize: 15,
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!
                        .translate('homework_title_hint'),
                    hintStyle:
                        TextStyle(color: secondaryTextColor, fontSize: 14),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.03)
                        : Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.blueAccent)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                  ),
                ),

                const SizedBox(height: 32),

                // Description
                Text(
                    AppLocalizations.of(context)!
                        .translate('instructions_desc'),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: secondaryTextColor,
                        letterSpacing: 1.5)),
                const SizedBox(height: 12),
                TextField(
                  controller: _descriptionController,
                  maxLines: 5,
                  style: TextStyle(
                      color: primaryTextColor.withValues(alpha: 0.8),
                      fontSize: 14,
                      height: 1.6,
                      fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!
                        .translate('instructions_hint'),
                    hintStyle:
                        TextStyle(color: secondaryTextColor, fontSize: 14),
                    filled: true,
                    fillColor: isDark
                        ? Colors.white.withValues(alpha: 0.02)
                        : Colors.white,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide(
                            color: isDark ? Colors.white10 : Colors.black12)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Colors.blueAccent)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 20),
                  ),
                ),

                const SizedBox(height: 32),

                // Deadline
                Text(AppLocalizations.of(context)!.translate('submission_date'),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: secondaryTextColor,
                        letterSpacing: 1.5)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 18),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.03)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.white),
                      boxShadow: isDark
                          ? []
                          : [
                              BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  blurRadius: 10)
                            ],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 20, color: Colors.blueAccent),
                        const SizedBox(width: 16),
                        Text(
                          '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: primaryTextColor),
                        ),
                        const Spacer(),
                        Icon(Icons.keyboard_arrow_down_rounded,
                            color: secondaryTextColor),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),

                // Attachments
                Text(AppLocalizations.of(context)!.translate('attachments'),
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 11,
                        color: secondaryTextColor,
                        letterSpacing: 1.5)),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.01)
                        : Colors.white.withValues(alpha: 0.5),
                    border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.1),
                        style: BorderStyle.solid),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          color: secondaryTextColor.withValues(alpha: 0.5),
                          size: 40),
                      const SizedBox(height: 16),
                      Text(
                          AppLocalizations.of(context)!
                              .translate('upload_doc_hint'),
                          style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),

                const SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown(BuildContext context, String label, String value,
      List<String> items, Function(String?) onChanged,
      {bool isSubject = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w900,
                color: secondaryTextColor,
                letterSpacing: 1)),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.white),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: secondaryTextColor),
              style: TextStyle(
                  fontSize: 14,
                  color: primaryTextColor,
                  fontWeight: FontWeight.w900),
              items: items.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(isSubject
                      ? AppLocalizations.of(context)!.translate(value)
                      : value),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime(2027),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: Colors.blueAccent,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E293B),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: Colors.blueAccent,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Color(0xFF0F172A),
                  ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _publish() {
    if (_titleController.text.isEmpty) return;
    setState(() => _isPublishing = true);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.translate('homework_published'),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            backgroundColor:
                isDark ? const Color(0xFF1E293B) : const Color(0xFF0F172A),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    });
  }
}
