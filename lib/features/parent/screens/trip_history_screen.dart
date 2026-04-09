import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import '../viewmodels/location_view_model.dart';

class TripHistoryScreen extends StatefulWidget {
  const TripHistoryScreen({super.key});

  @override
  State<TripHistoryScreen> createState() => _TripHistoryScreenState();
}

class _TripHistoryScreenState extends State<TripHistoryScreen> {
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Fetch data for the first child or based on current session
      context.read<LocationViewModel>().fetchLocationData('child_1');
    });
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final statusBarH = MediaQuery.of(context).padding.top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryText = isDark ? Colors.white70 : Colors.black54;

    final weekdays = ["Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche"];
    final months = ["Janvier", "Février", "Mars", "Avril", "Mai", "Juin", "Juillet", "Août", "Septembre", "Octobre", "Novembre", "Décembre"];
    final formattedDate = "${weekdays[_selectedDate.weekday - 1]}, ${_selectedDate.day} ${months[_selectedDate.month - 1]} ${_selectedDate.year}";

    return Consumer<LocationViewModel>(
      builder: (context, vm, child) {
        final history = vm.history;
        final totalTrips = history.length;

        return Scaffold(
          backgroundColor: Colors.transparent,
          body: vm.isLoading && vm.history.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : DeepSpaceBackground(
        showOrbs: true,
        child: Column(
          children: [
            // ── AppBar ──────────────────────────────────────────────
            _buildAppBar(context, loc, statusBarH),

            // ── Scrollable body ─────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Hero header ─────────────────────────────────
                    _buildHeroHeader(formattedDate, totalTrips),

                    // ── Timeline ────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                      child: Column(
                        children: history.asMap().entries.map((entry) {
                          return _buildTripItem(
                            context: context,
                            loc: loc,
                            record: entry.value,
                            isLast: entry.key == history.length - 1,
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // AppBar
  // ─────────────────────────────────────────────────────────────────
  Widget _buildAppBar(BuildContext context, AppLocalizations loc, double statusBarH) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.85),
          padding: EdgeInsets.only(top: statusBarH + 8, bottom: 16, left: 8, right: 8),
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Back button
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryText, size: 18),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              // Title
              Text(
                loc.translate('trip_history_title'),
                style: TextStyle(
                  color: primaryText,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  letterSpacing: -0.3,
                ),
              ),
              // Calendar icon
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  icon: Icon(Icons.calendar_today_rounded, color: primaryText, size: 18),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      builder: (ctx, child) => Theme(
                        data: ThemeData.dark().copyWith(
                          colorScheme: const ColorScheme.dark(primary: Colors.blueAccent),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setState(() => _selectedDate = picked);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Hero header
  // ─────────────────────────────────────────────────────────────────
  Widget _buildHeroHeader(String formattedDate, int totalTrips) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    // Determine label
    final now = DateTime.now();
    final isToday = _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
    final heroLabel = isToday ? "AUJOURD'HUI" : "TRAJETS";

    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: title + date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      heroLabel,
                      style: TextStyle(
                        color: primaryText,
                        fontWeight: FontWeight.w900,
                        fontSize: 36,
                        letterSpacing: -1,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: primaryText.withValues(alpha: 0.55),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              // Right: stats
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '$totalTrips trajets',
                    style: const TextStyle(
                      color: Colors.blueAccent,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'total: 8.6 km',
                    style: TextStyle(
                      color: primaryText.withValues(alpha: 0.45),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Trip item (timeline row)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildTripItem({
    required BuildContext context,
    required AppLocalizations loc,
    required dynamic record,
    required bool isLast,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    final LatLng center = record.startCoord != null && record.endCoord != null
        ? LatLng(
            (record.startCoord.latitude + record.endCoord.latitude) / 2,
            (record.startCoord.longitude + record.endCoord.longitude) / 2,
          )
        : const LatLng(33.5731, -7.5898);

    final bool isWalking = record.mode == 'walking_mode';
    final IconData modeIcon = isWalking ? Icons.directions_walk_rounded : Icons.directions_bus_rounded;
    final String modeLabel = isWalking ? loc.translate('a_pied') : loc.translate('bus_scolaire');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Timeline rail ──────────────────────────────────────
          Column(
            children: [
              const SizedBox(height: 6),
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.blueAccent,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.blueAccent.withValues(alpha: 0.5), blurRadius: 8, spreadRadius: 1)],
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 1.5,
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blueAccent.withValues(alpha: 0.4), Colors.transparent],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(width: 20),

          // ── Card ───────────────────────────────────────────────
          Expanded(
            child: Container(
              margin: EdgeInsets.only(bottom: isLast ? 0 : 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.75) : Colors.white.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: primaryText.withValues(alpha: 0.06)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 8)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Card header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.blueAccent.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(modeIcon, color: Colors.blueAccent, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Text(
                              modeLabel,
                              style: TextStyle(
                                color: primaryText.withValues(alpha: 0.55),
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: primaryText.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: primaryText.withValues(alpha: 0.08)),
                              ),
                              child: Text(
                                loc.translate('finished_caps'),
                                style: TextStyle(
                                  color: primaryText.withValues(alpha: 0.45),
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Mini map
                        ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: SizedBox(
                            height: 175,
                            width: double.infinity,
                            child: Stack(
                              children: [
                                FlutterMap(
                                  options: MapOptions(
                                    initialCenter: center,
                                    initialZoom: 14,
                                    interactionOptions: const InteractionOptions(flags: InteractiveFlag.none),
                                  ),
                                  children: [
                                    TileLayer(
                                      urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png',
                                      subdomains: const ['a', 'b', 'c', 'd'],
                                    ),
                                    if (record.startCoord != null && record.endCoord != null)
                                      PolylineLayer(
                                        polylines: [
                                          Polyline(
                                            points: [record.startCoord, record.endCoord],
                                            color: Colors.blueAccent,
                                            strokeWidth: 4,
                                          ),
                                        ],
                                      ),
                                  ],
                                ),
                                // Duration badge
                                Positioned(
                                  bottom: 12,
                                  right: 12,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                          color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.88) : Colors.white.withValues(alpha: 0.88),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: primaryText.withValues(alpha: 0.08)),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.timer_outlined, color: Colors.blueAccent, size: 14),
                                            const SizedBox(width: 6),
                                            Text(
                                              record.duration,
                                              style: TextStyle(
                                                color: primaryText,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Detail rows
                        _buildDetailRow(record.startTime, loc.translate('departure_caps'), record.fromAddress, true),
                        const SizedBox(height: 18),
                        _buildDetailRow(record.endTime, loc.translate('arrival_caps'), record.toAddress, false),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // Detail row (departure / arrival)
  // ─────────────────────────────────────────────────────────────────
  Widget _buildDetailRow(String time, String label, String address, bool isDeparture) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryText = isDark ? Colors.white : const Color(0xFF0F172A);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 50,
          child: Text(
            time,
            style: TextStyle(
              color: primaryText,
              fontSize: 17,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Icon(
          isDeparture ? Icons.arrow_forward_rounded : Icons.location_on_rounded,
          size: 15,
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: primaryText.withValues(alpha: 0.38),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                address,
                style: TextStyle(
                  color: primaryText,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
