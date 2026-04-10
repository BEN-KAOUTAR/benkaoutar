import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/models/models.dart';
import '../viewmodels/security_view_model.dart';

class SecurityAlertsScreen extends StatefulWidget {
  final StudentModel student;
  const SecurityAlertsScreen({super.key, required this.student});

  @override
  State<SecurityAlertsScreen> createState() => _SecurityAlertsScreenState();
}

class _SecurityAlertsScreenState extends State<SecurityAlertsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SecurityViewModel>().fetchSecurityData(widget.student.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryTextColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Consumer<SecurityViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: primaryTextColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(AppLocalizations.of(context)!.translate('security_alerts_title'), style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w900, fontSize: 18)),
            centerTitle: true,
            actions: [
              Stack(
                children: [
                  IconButton(onPressed: () {}, icon: Icon(Icons.notifications_none_rounded, color: secondaryTextColor, size: 24)),
                  if (vm.alerts.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                        child: Text('${vm.alerts.length}', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: DeepSpaceBackground(
            showOrbs: true,
            child: Builder(
              builder: (context) {
                if (vm.isLoading && vm.alerts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (vm.errorMessage != null && vm.alerts.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline_rounded, size: 64, color: Colors.blueAccent.withValues(alpha: 0.2)),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context)!.translate(vm.errorMessage!), style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.w900, fontSize: 16)),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () => vm.fetchSecurityData(widget.student.id),
                          child: Text(AppLocalizations.of(context)!.translate('retry')),
                        ),
                      ],
                    ),
                  );
                }
                return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildProfileHeader(context, vm.status),
                  const SizedBox(height: 40),
                  if (vm.alerts.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Text(AppLocalizations.of(context)!.translate('no_alerts'), style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                      ),
                    )
                  else ...[
                    _buildSectionHeader(context, AppLocalizations.of(context)!.translate('today_section')),
                    const SizedBox(height: 20),
                    ...vm.alerts.map((alert) => _buildAlertCard(
                      context: context,
                      type: alert['type'] ?? '',
                      title: alert['title'] ?? '',
                      address: alert['address'] ?? '',
                      time: alert['time'] ?? '0 min',
                      icon: _getIconForAlertType(alert['type']),
                      color: _getColorForAlertType(alert['type']),
                    )),
                  ],
                  const SizedBox(height: 48),
                  _buildHistoryButton(context),
                  const SizedBox(height: 60),
                ],
              ),
            );
              }
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForAlertType(String? type) {
    switch (type?.toLowerCase()) {
      case 'arrival': return Icons.login_rounded;
      case 'departure': return Icons.logout_rounded;
      case 'proximity': return Icons.near_me_rounded;
      case 'school': return Icons.school_rounded;
      case 'home': return Icons.home_rounded;
      default: return Icons.notifications_active_rounded;
    }
  }

  Color _getColorForAlertType(String? type) {
    switch (type?.toLowerCase()) {
      case 'arrival': return Colors.greenAccent;
      case 'departure': return Colors.blueAccent;
      case 'proximity': return Colors.orangeAccent;
      default: return Colors.indigoAccent;
    }
  }

  Widget _buildProfileHeader(BuildContext context, Map<String, dynamic> status) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final batteryLevel = status['battery_level'] ?? 0;
    final studentName = widget.student.name;
    final studentClass = widget.student.className ?? '';
    final studentAvatar = widget.student.avatarUrl ?? 'https://ui-avatars.com/api/?name=${widget.student.name}&background=random';

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white10 : Colors.white),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 20, offset: const Offset(0, 5))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 2)),
            child: CircleAvatar(radius: 28, backgroundImage: NetworkImage(studentAvatar)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(studentName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: primaryTextColor)),
                Text(studentClass, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(AppLocalizations.of(context)!.translate('battery_upper'), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              Row(
                children: [
                   Text('$batteryLevel%', style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w900, fontSize: 16)),
                   const SizedBox(width: 4),
                   Icon(
                     batteryLevel < 20 ? Icons.battery_alert_rounded : Icons.battery_5_bar_rounded, 
                     color: batteryLevel < 20 ? Colors.redAccent : Colors.greenAccent, 
                     size: 18
                   ),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: -0.1);
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Divider(color: isDark ? Colors.white10 : Colors.white),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            color: isDark ? const Color(0xFF020617) : const Color(0xFFF8FAFC),
            child: Text(title, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard({
    required BuildContext context,
    required String type,
    required String title,
    required String address,
    required String time,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.02) : Colors.white;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.white.withValues(alpha: 0.7), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(color: isDark ? Colors.white10 : Colors.white, borderRadius: BorderRadius.circular(10)),
                          child: Text(type.toUpperCase(), style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ),
                        Row(
                          children: [
                            Icon(Icons.access_time_rounded, size: 12, color: isDark ? Colors.white38 : Colors.black38),
                            const SizedBox(width: 4),
                            Text('${AppLocalizations.of(context)!.translate('ago_suffix')} $time', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryTextColor)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_rounded, size: 14, color: Colors.blueAccent),
                        const SizedBox(width: 6),
                        Expanded(child: Text(address, style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, fontWeight: FontWeight.bold))),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: isDark ? Colors.white10 : Colors.white),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.translate('trip_details_upper'), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                child: Row(
                  children: [
                    Text(AppLocalizations.of(context)!.translate('see_on_map'), style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w900)),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: Colors.blueAccent),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildHistoryButton(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        color: isDark ? Colors.indigoAccent.withValues(alpha: 0.1) : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Text(AppLocalizations.of(context)!.translate('view_full_history').toUpperCase(), style: TextStyle(color: isDark ? Colors.indigoAccent : const Color(0xFF4338CA), fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
      ),
    );
  }
}
