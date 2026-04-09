import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/glass_card.dart';
import '../viewmodels/security_view_model.dart';

class SecurityZonesScreen extends StatefulWidget {
  const SecurityZonesScreen({super.key});

  @override
  State<SecurityZonesScreen> createState() => _SecurityZonesScreenState();
}

class _SecurityZonesScreenState extends State<SecurityZonesScreen> {
  final MapController _mapController = MapController();
  
  // Same Casablanca coordinates for consistency
  final LatLng _schoolLoc = const LatLng(33.5731, -7.5898);
  final LatLng _homeLoc = const LatLng(33.5651, -7.5958);
  
  double _homeRadius = 250;
  double _schoolRadius = 400;
  double _busRadius = 150;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<SecurityViewModel>();
      if (vm.status.isNotEmpty) {
        setState(() {
          _homeRadius = (vm.status['home_radius'] as num?)?.toDouble() ?? 250;
          _schoolRadius = (vm.status['school_radius'] as num?)?.toDouble() ?? 400;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white60 : Colors.black54;
    final loc = AppLocalizations.of(context)!;

    return Consumer<SecurityViewModel>(
      builder: (context, vm, child) {
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
            title: Text(AppLocalizations.of(context)!.translate('security_zones_title'), style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w900, fontSize: 18)),
            centerTitle: true,
            actions: [
              IconButton(onPressed: () {}, icon: Icon(Icons.tune_rounded, color: secondaryTextColor, size: 20)),
              const SizedBox(width: 8),
            ],
          ),
          body: DeepSpaceBackground(
            showOrbs: true,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: 20, 
                right: 20, 
                top: MediaQuery.paddingOf(context).top + kToolbarHeight + 20,
                bottom: 60,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(loc.translate('real_time_preview'), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                  const SizedBox(height: 16),
                  _buildMapPreview(context),
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(loc.translate('configured_zones'), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
                      TextButton(onPressed: () {}, child: Text(loc.translate('add_upper'), style: const TextStyle(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildZoneCard(context: context, icon: Icons.home_rounded, title: loc.translate('your_home'), radius: _homeRadius, onRadiusChanged: (val) => setState(() => _homeRadius = val)),
                  const SizedBox(height: 16),
                  _buildZoneCard(context: context, icon: Icons.school_rounded, title: loc.translate('school_platinum'), iconColor: Colors.blueAccent, radius: _schoolRadius, onRadiusChanged: (val) => setState(() => _schoolRadius = val)),
                  const SizedBox(height: 16),
                  _buildZoneCard(context: context, icon: Icons.directions_bus_rounded, title: '${loc.translate('bus_label')} #04', iconColor: Colors.orangeAccent, radius: _busRadius, onRadiusChanged: (val) => setState(() => _busRadius = val), showSwitches: false),
                  const SizedBox(height: 32),
                  _buildSafetyTip(context),
                  const SizedBox(height: 16),
                  _buildCriticalAlerts(context),
                  const SizedBox(height: 48),
                  _buildSaveButton(),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapPreview(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, 5))],
        ),
        child: FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _schoolLoc,
            initialZoom: 14,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
              subdomains: const ['a', 'b', 'c', 'd'],
            ),
            CircleLayer(
              circles: [
                CircleMarker(
                  point: _homeLoc,
                  radius: _homeRadius,
                  useRadiusInMeter: true,
                  color: Colors.greenAccent.withValues(alpha: 0.1),
                  borderColor: Colors.greenAccent.withValues(alpha: 0.5),
                  borderStrokeWidth: 2,
                ),
                CircleMarker(
                  point: _schoolLoc,
                  radius: _schoolRadius,
                  useRadiusInMeter: true,
                  color: Colors.blueAccent.withValues(alpha: 0.1),
                  borderColor: Colors.blueAccent.withValues(alpha: 0.5),
                  borderStrokeWidth: 2,
                ),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95));
  }


  Widget _buildZoneCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required double radius,
    required Function(double) onRadiusChanged,
    Color iconColor = Colors.indigoAccent,
    bool showSwitches = true,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return GlassCard(
      padding: const EdgeInsets.all(28),
      borderRadius: 32,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16)),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryTextColor)),
                    const SizedBox(height: 4),
                    Text('${AppLocalizations.of(context)!.translate('current_radius')}: ${radius.toInt()}m', style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 13, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Switch(value: true, onChanged: (v) {}, activeColor: Colors.blueAccent),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(AppLocalizations.of(context)!.translate('security_radius_upper'), style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)),
              Text('${radius.toInt()} ${AppLocalizations.of(context)!.translate('meters')}', style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.w900)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: Colors.blueAccent,
              inactiveTrackColor: isDark ? Colors.white10 : Colors.white,
              thumbColor: Colors.white,
              overlayColor: Colors.blueAccent.withValues(alpha: 0.1),
              trackHeight: 6,
            ),
            child: Slider(
              value: radius,
              min: 50,
              max: 1000,
              onChanged: onRadiusChanged,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('50m', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.bold)),
                Text('500m', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.bold)),
                Text('1km', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          if (showSwitches) ...[
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: _buildZoneSwitch(context, AppLocalizations.of(context)!.translate('entry_alert'), true)),
                const SizedBox(width: 16),
                Expanded(child: _buildZoneSwitch(context, AppLocalizations.of(context)!.translate('exit_alert'), true)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildZoneSwitch(BuildContext context, String label, bool value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: isDark ? Colors.white10 : Colors.white.withValues(alpha: 0.8))
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isDark ? Colors.white70 : const Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: -0.2)),
          SizedBox(
            height: 24,
            child: ScaleTransition(
              scale: const AlwaysStoppedAnimation(0.8),
              child: Switch(value: value, onChanged: (v) {}, activeColor: Colors.blueAccent, activeTrackColor: Colors.blueAccent.withValues(alpha: 0.3)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSafetyTip(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      color: Colors.orangeAccent.withValues(alpha: 0.05),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.tips_and_updates_rounded, color: Colors.orangeAccent, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.translate('safety_tip_upper'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 11, color: isDark ? Colors.orangeAccent : const Color(0xFF1E1B4B), letterSpacing: 1.5)),
                const SizedBox(height: 8),
                Text(
                  AppLocalizations.of(context)!.translate('safety_tip_content'),
                  style: TextStyle(color: isDark ? Colors.white60 : const Color(0xFF64748B), fontSize: 13, height: 1.5, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCriticalAlerts(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFF1F5F9))),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(AppLocalizations.of(context)!.translate('critical_alerts'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryTextColor)),
          ),
          Switch(value: true, onChanged: (v) {}, activeColor: Colors.blueAccent),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.blueAccent,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Center(
        child: Text(AppLocalizations.of(context)!.translate('save_changes_upper'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1.5)),
      ),
    ).animate().fadeIn(delay: 400.ms);
  }
}
