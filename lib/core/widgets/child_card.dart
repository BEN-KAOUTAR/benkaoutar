import 'package:flutter/material.dart';
import '../models/models.dart';
import '../../features/parent/screens/location_screen.dart';
import '../../features/parent/screens/chat_screen.dart';
import '../../features/parent/screens/suivi_scolaire_screen.dart';

class ChildCard extends StatelessWidget {
  final StudentModel child;
  const ChildCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=${child.name}'),
                  ),
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 14, height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF22C55E),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(child.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A1A1A))),
                    const SizedBox(height: 2),
                    Text('${child.className ?? "Classe"} - Groupe B', style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          _ProgressBar(
            label: 'TAUX DE PRÉSENCE', 
            percentage: child.attendanceRate ?? 0, 
            valueText: '${(child.attendanceRate ?? 0).toInt()}%', 
            icon: Icons.access_time
          ),
          const SizedBox(height: 16),
          _ProgressBar(
            label: 'MOYENNE GÉNÉRALE', 
            percentage: (child.average / 20 * 100), 
            valueText: '${child.average}/20', 
            icon: Icons.school_outlined
          ),
          
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9)),
          const SizedBox(height: 16),
          
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _CircularAction(icon: Icons.location_on_outlined, label: 'SUIVI', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => LocationScreen(student: child)))),
              _CircularAction(
                icon: Icons.description_outlined, 
                label: 'DÉTAILS', 
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SuiviScolaireScreen(student: child)))
              ),
              _CircularAction(icon: Icons.chat_bubble_outline_rounded, label: 'CHAT', onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatScreen()))),
              
              const Spacer(),
              
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SuiviScolaireScreen(student: child))),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(color: Color(0xFF0000FF), shape: BoxShape.circle),
                  child: const Icon(Icons.chevron_right, color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final String label;
  final double percentage;
  final String valueText;
  final IconData icon;

  const _ProgressBar({required this.label, required this.percentage, required this.valueText, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              ],
            ),
            Text(valueText, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF1A1A1A))),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percentage / 100).clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFF1F5F9),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF0000FF)),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

class _CircularAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CircularAction({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFF1F5F9)),
            ),
            child: Icon(icon, color: const Color(0xFF64748B), size: 22),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 9, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
