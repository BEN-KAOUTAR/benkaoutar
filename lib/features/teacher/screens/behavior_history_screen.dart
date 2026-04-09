import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';

class BehaviorHistoryScreen extends StatelessWidget {
  const BehaviorHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pt = isDark ? Colors.white : const Color(0xFF0F172A);
    final loc = AppLocalizations.of(context)!;

    final List<Map<String, dynamic>> history = [
      {
        'date': '05 Avril 2026',
        'student': 'Ahmed Alami',
        'type': 'Positif',
        'points': 10,
        'note': 'Excellente participation en classe et aide aux camarades.',
        'icon': Icons.emoji_events_rounded,
        'color': Colors.greenAccent,
      },
      {
        'date': '04 Avril 2026',
        'student': 'Sara Benani',
        'type': 'Négatif',
        'points': 5,
        'note': 'Bavardages incessants malgré plusieurs avertissements.',
        'icon': Icons.warning_amber_rounded,
        'color': Colors.redAccent,
      },
      {
        'date': '03 Avril 2026',
        'student': 'Yassine Karim',
        'type': 'Positif',
        'points': 5,
        'note': 'Deoirs très bien faits et rendus à temps.',
        'icon': Icons.thumb_up_rounded,
        'color': Colors.greenAccent,
      },
      {
        'date': '02 Avril 2026',
        'student': 'Lina Fahmi',
        'type': 'Positif',
        'points': 15,
        'note': 'Projet de groupe mené avec brio et leadership.',
        'icon': Icons.stars_rounded,
        'color': Colors.greenAccent,
      },
    ];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, color: pt, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          loc.translate('behavior_history_title') ?? 'Historique des Rapports',
          style: TextStyle(color: pt, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(20),
            physics: const BouncingScrollPhysics(),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              return _buildHistoryCard(context, item, index, isDark, pt);
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, Map<String, dynamic> item, int index, bool isDark, Color pt) {
    final statusColor = item['color'];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.white.withValues(alpha: 0.7), blurRadius: 10, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                item['date'],
                style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 0.5),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: statusColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    Icon(item['icon'], size: 12, color: statusColor),
                    const SizedBox(width: 6),
                    Text(
                      '${item['type'] == 'Positif' ? '+' : '-'}${item['points']}',
                      style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            item['student'],
            style: TextStyle(color: pt, fontWeight: FontWeight.w900, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            item['note'],
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13, height: 1.5, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
  }
}
