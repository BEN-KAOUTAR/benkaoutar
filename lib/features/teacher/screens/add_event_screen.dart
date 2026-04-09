import 'package:flutter/material.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';

class AddEventScreen extends StatefulWidget {
  const AddEventScreen({super.key});

  @override
  State<AddEventScreen> createState() => _AddEventScreenState();
}

class _AddEventScreenState extends State<AddEventScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _eventTypeKey = 'event';
  bool _isPublishing = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(AppLocalizations.of(context)!.translate('new_post'), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 18)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton(
              onPressed: _isPublishing ? null : _publish,
              child: _isPublishing 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(AppLocalizations.of(context)!.translate('publish'), style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent, letterSpacing: 1)),
            ),
          ),
        ],
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.translate('announcement_type'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white38, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Row(
                  children: [
                    _buildTypeChip('event', Icons.event_available_rounded),
                    const SizedBox(width: 12),
                    _buildTypeChip('urgent', Icons.warning_amber_rounded),
                    const SizedBox(width: 12),
                    _buildTypeChip('info_label', Icons.info_outline_rounded),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              Text(AppLocalizations.of(context)!.translate('title_label'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white38, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              TextField(
                controller: _titleController,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.translate('announcement_title_hint'),
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: Colors.blueAccent)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                ),
              ),

              const SizedBox(height: 32),

              Text(AppLocalizations.of(context)!.translate('description_label'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white38, letterSpacing: 1.5)),
              const SizedBox(height: 12),
              TextField(
                controller: _descController,
                maxLines: 6,
                style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
                decoration: InputDecoration(
                  hintText: AppLocalizations.of(context)!.translate('announcement_description_hint'),
                  hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.02),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.white10)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.white10)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.blueAccent)),
                  contentPadding: const EdgeInsets.all(20),
                ),
              ),

              const SizedBox(height: 32),

              Text(AppLocalizations.of(context)!.translate('additional_options'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: Colors.white38, letterSpacing: 1.5)),
              const SizedBox(height: 16),
              _buildOptionRow(Icons.camera_alt_rounded, AppLocalizations.of(context)!.translate('add_photo')),
              _buildOptionRow(Icons.location_on_rounded, AppLocalizations.of(context)!.translate('add_location')),
              _buildOptionRow(Icons.people_alt_rounded, AppLocalizations.of(context)!.translate('target_parents')),

              const SizedBox(height: 60),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeChip(String key, IconData icon) {
    final isSelected = _eventTypeKey == key;
    final label = AppLocalizations.of(context)!.translate(key);
    return GestureDetector(
      onTap: () => setState(() => _eventTypeKey = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? Colors.transparent : Colors.white.withValues(alpha: 0.05)),
          boxShadow: isSelected ? [BoxShadow(color: Colors.white.withValues(alpha: 0.2), blurRadius: 10)] : null,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: isSelected ? const Color(0xFF0F172A) : Colors.white38),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: isSelected ? const Color(0xFF0F172A) : Colors.white38, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5)),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionRow(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.02),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: Colors.white70),
            ),
            const SizedBox(width: 16),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white70)),
            const Spacer(),
            const Icon(Icons.add_circle_rounded, size: 24, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }

  void _publish() {
    if (_titleController.text.isEmpty) return;
    setState(() => _isPublishing = true);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() => _isPublishing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.translate('announcement_published')),
            backgroundColor: const Color(0xFF1E293B),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    });
  }
}
