import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../viewmodels/homework_view_model.dart';
//devoir
class HomeworkScreen extends StatefulWidget {
  final String studentId;
  const HomeworkScreen({super.key, required this.studentId});

  @override
  State<HomeworkScreen> createState() => _HomeworkScreenState();
}

class _HomeworkScreenState extends State<HomeworkScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HomeworkViewModel>().fetchHomework(widget.studentId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

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
        title: Text(AppLocalizations.of(context)!.translate('homework_title'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: primaryTextColor, letterSpacing: -0.5)),
        centerTitle: true,
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: Consumer<HomeworkViewModel>(
            builder: (context, vm, child) {
              if (vm.isLoading && vm.homeworks.isEmpty) {
                return const Center(child: CircularProgressIndicator(color: Colors.blueAccent));
              }

              if (vm.errorMessage != null && vm.homeworks.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline_rounded, size: 64, color: Colors.orangeAccent.withValues(alpha: 0.5)),
                      const SizedBox(height: 16),
                      Text(vm.errorMessage!, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () => vm.fetchHomework(widget.studentId),
                        child: const Text("Réessayer"),
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
                    // Global Progress Indicator
                    _buildProgressHeader(context, isDark, vm),

                    const SizedBox(height: 48),

                    Text(AppLocalizations.of(context)!.translate('to_do_week').toUpperCase(), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: secondaryTextColor, letterSpacing: 2)).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 24),

                    if (vm.homeworks.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 60),
                          child: Column(
                            children: [
                              Icon(Icons.assignment_turned_in_rounded, size: 64, color: Colors.greenAccent.withValues(alpha: 0.2)),
                              const SizedBox(height: 16),
                              Text(AppLocalizations.of(context)!.translate('all_caught_up'), style: const TextStyle(color: Colors.white38, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      )
                    else
                      ...vm.homeworks.asMap().entries.map((entry) {
                        final homework = entry.value;
                        return _HomeworkListItem(
                          homework: homework,
                          onStatusUpdate: (status) => vm.updateStatus(homework.id, status),
                        ).animate().fadeIn(delay: (entry.key * 150).ms).slideY(begin: 0.1);
                      }),
                    const SizedBox(height: 100),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildProgressHeader(BuildContext context, bool isDark, HomeworkViewModel vm) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    final progression = vm.progressionRate;
    final label = vm.progressionLabel;

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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.translate('week_progression').toUpperCase(), style: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 2)),
                      const SizedBox(height: 8),
                      Text('${progression.toInt()}% ${AppLocalizations.of(context)!.translate('completed_percent')}', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -1)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.greenAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.greenAccent.withValues(alpha: 0.3), width: 2),
                    ),
                    child: Text(label, style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 14)),
                  ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05), duration: 2.seconds),
                ],
              ),
              const SizedBox(height: 32),
              LayoutBuilder(
                builder: (context, constraints) {
                   return Stack(
                    children: [
                      Container(
                        height: 12,
                        width: constraints.maxWidth,
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white10 : Colors.white,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      AnimatedContainer(
                        duration: 1.seconds,
                        curve: Curves.easeOutCubic,
                        height: 12,
                        width: constraints.maxWidth * (progression / 100),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Colors.greenAccent, Colors.tealAccent]),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [BoxShadow(color: Colors.greenAccent.withValues(alpha: 0.4), blurRadius: 10)],
                        ),
                      ).animate().slideX(begin: -1, duration: 800.ms, curve: Curves.easeOutQuart),
                    ],
                  );
                }
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: -0.1);
  }
}

class _HomeworkListItem extends StatelessWidget {
  final HomeworkModel homework;
  final Function(HomeworkStatus) onStatusUpdate;
  
  const _HomeworkListItem({
    required this.homework, 
    required this.onStatusUpdate
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white54 : Colors.black54;

    Color statusColor;
    String statusLabel;
    switch (homework.status) {
      case HomeworkStatus.notStarted:
        statusColor = isDark ? Colors.white38 : Colors.black38;
        statusLabel = AppLocalizations.of(context)!.translate('not_started');
        break;
      case HomeworkStatus.inProgress:
        statusColor = Colors.orangeAccent;
        statusLabel = AppLocalizations.of(context)!.translate('in_progress');
        break;
      case HomeworkStatus.done:
        statusColor = Colors.greenAccent;
        statusLabel = AppLocalizations.of(context)!.translate('done_status');
        break;
      case HomeworkStatus.late:
        statusColor = Colors.redAccent;
        statusLabel = AppLocalizations.of(context)!.translate('late_status');
        break;
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: AnimatedContainer(
          duration: 400.ms,
          curve: Curves.easeOutQuart,
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: statusColor.withValues(alpha: 0.3), width: homework.status == HomeworkStatus.done ? 2 : 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        statusLabel.toUpperCase(),
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 1.5),
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Row(
                        children: [
                          Icon(Icons.event_outlined, size: 12, color: secondaryTextColor),
                          const SizedBox(width: 6),
                          Text(homework.dueDate, style: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text(
                  homework.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: homework.status == HomeworkStatus.done ? secondaryTextColor : primaryTextColor,
                    decoration: homework.status == HomeworkStatus.done ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 8),
                Text(homework.subject, style: TextStyle(color: secondaryTextColor, fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.translate('instructions_desc'), style: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                      const SizedBox(height: 8),
                      Text(
                        homework.description,
                        style: TextStyle(
                          color: primaryTextColor.withValues(alpha: 0.8),
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (homework.status != HomeworkStatus.done) ...[
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      _buildActionButton(
                        context,
                        AppLocalizations.of(context)!.translate('done_status'),
                        Icons.check_circle_outline_rounded,
                        Colors.greenAccent,
                        () => _showUploadDialog(context, isDark),
                      ),
                      if (homework.status == HomeworkStatus.notStarted) ...[
                        const SizedBox(width: 16),
                        _buildActionButton(
                          context,
                          AppLocalizations.of(context)!.translate('in_progress'),
                          Icons.pending_actions_rounded,
                          Colors.orangeAccent,
                          () => onStatusUpdate(HomeworkStatus.inProgress),
                        ),
                      ],
                    ],
                  ),
                ] else ...[
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.verified_rounded, color: Colors.greenAccent, size: 16),
                      const SizedBox(width: 8),
                      Text(AppLocalizations.of(context)!.translate('verified_status'), style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showUploadDialog(BuildContext context, bool isDark) {
    final loc = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          ),
          padding: EdgeInsets.fromLTRB(32, 24, 32, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 48, height: 4,
                  decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 32),
              const Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.blueAccent),
              const SizedBox(height: 16),
              Text(
                loc.translate('submit_homework_title'),
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 20, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              const SizedBox(height: 8),
              Text(
                loc.translate('submit_homework_desc'),
                textAlign: TextAlign.center,
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
              ),
              const SizedBox(height: 32),
              
              GestureDetector(
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.add_photo_alternate_outlined, color: Colors.blueAccent, size: 32),
                      const SizedBox(height: 12),
                      Text(loc.translate('add_file_hint'), style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w900, fontSize: 12)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),
              
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  onStatusUpdate(HomeworkStatus.done);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc.translate('homework_sent_success'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      backgroundColor: Colors.greenAccent.shade700,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    )
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: Text(loc.translate('send_finish_button'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 0.5)),
            ],
          ),
        ),
      ),
    );
  }
}
