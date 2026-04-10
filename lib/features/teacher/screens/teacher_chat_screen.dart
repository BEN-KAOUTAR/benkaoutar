import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../core/providers/app_state.dart';

import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';
import 'student_detail_full_screen.dart';
import 'group_info_screen.dart';
import '../../../core/models/models.dart';

// ─────────────────────────────────────────────────────────────
// Main Teacher Chat Screen (shown via Bottom Nav)
// ─────────────────────────────────────────────────────────────
class TeacherChatScreen extends StatefulWidget {
  const TeacherChatScreen({super.key});

  @override
  State<TeacherChatScreen> createState() => _TeacherChatScreenState();
}

class _TeacherChatScreenState extends State<TeacherChatScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final classes = <ClassModel>[];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          loc.translate('messages_teacher'),
          style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor, fontSize: 22, letterSpacing: -0.5),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                color: isDark ? Colors.blueAccent.withValues(alpha: 0.2) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isDark ? [] : [BoxShadow(color: Colors.white, blurRadius: 10, offset: const Offset(0, 4))],
              ),
              labelColor: isDark ? Colors.white : Colors.blueAccent,
              unselectedLabelColor: secondaryTextColor,
              labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 0.5),
              tabs: [
                Tab(text: loc.translate('tab_individuel')),
                Tab(text: loc.translate('tab_classes')),
              ],
            ),
          ),
        ),
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildMessagesTab(context, classes, isDark, primaryTextColor, secondaryTextColor),
              _buildGroupsTab(context, classes, isDark, primaryTextColor, secondaryTextColor),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 120.0),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NewChatSearchScreen())),
          backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
          foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: const Icon(Icons.edit_note_rounded, size: 28),
        ).animate().scale(delay: const Duration(milliseconds: 400), curve: Curves.elasticOut),
      ),
    );
  }

  Widget _buildMessagesTab(BuildContext context, List<dynamic> classes, bool isDark, Color primaryTextColor, Color secondaryTextColor) {
    final loc = AppLocalizations.of(context)!;
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
      children: [
        if (classes.isNotEmpty && classes.first.students.length >= 4) ...[
          _ChatTile(
            name: '${loc.translate('parent_of')} ${classes.first.students[0].name}',
            lastMsg: 'Merci pour l\'info',
            time: '14:30',
            unread: 1,
            role: 'Parent',
          ),
          _ChatTile(
            name: 'Administration',
            lastMsg: 'Réunion reportée à demain.',
            time: loc.translate('time_yesterday'),
            unread: 2,
            role: 'Admin',
            isSpecial: true,
          ),
          _ChatTile(
            name: '${loc.translate('parent_of')} ${classes.first.students[2].name}',
            lastMsg: 'Comment va Yassin ?',
            time: loc.translate('time_yesterday'),
            unread: 0,
            role: 'Parent',
          ),
        ] else ...[
          _ChatTile(name: 'Demo Parent', lastMsg: 'Hello', time: '10:00', unread: 1, role: 'Parent'),
        ],
      ],
    );
  }

  Widget _buildGroupsTab(BuildContext context, List<dynamic> classes, bool isDark, Color primaryTextColor, Color secondaryTextColor) {
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
      itemCount: classes.length,
      itemBuilder: (context, index) {
        final cls = classes[index];
        final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
            boxShadow: isDark ? [] : [BoxShadow(color: Colors.white.withValues(alpha: 0.7), blurRadius: 15, offset: const Offset(0, 5))],
          ),
          child: ListTile(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatDetailScreen(
                    name: cls.name,
                    avatarUrl: 'https://img.icons8.com/clouds/150/000000/groups.png',
                    classModel: cls,
                  ),
                ),
              );
            },
            contentPadding: const EdgeInsets.all(16),
            leading: Stack(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [Colors.blueAccent, Colors.blueAccent.withValues(alpha: 0.7)]),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(Icons.groups_rounded, color: Colors.white, size: 28),
                ),
                Positioned(
                  bottom: -2, right: -2, 
                  child: Container(
                    width: 14, height: 14, 
                    decoration: BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle, border: Border.all(color: cardBg, width: 2))
                  )
                ),
              ],
            ),
            title: Text(cls.name, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryTextColor)),
            subtitle: Text('${cls.studentCount} ${AppLocalizations.of(context)!.translate('students')}', style: TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.bold)),
            trailing: Icon(Icons.chevron_right_rounded, color: secondaryTextColor),
          ),
        ).animate().fadeIn(delay: Duration(milliseconds: (index * 80))).slideY(begin: 0.1);
      },
    );
  }
}

class _ChatTile extends StatelessWidget {
  final String name;
  final String lastMsg;
  final String time;
  final int unread;
  final String role;
  final bool isSpecial;

  const _ChatTile({
    required this.name,
    required this.lastMsg,
    required this.time,
    required this.unread,
    required this.role,
    this.isSpecial = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.white.withValues(alpha: 0.7), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: ListTile(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatDetailScreen(name: name, avatarUrl: 'https://i.pravatar.cc/150?u=$name'),
          ),
        ),
        contentPadding: const EdgeInsets.all(20),
        leading: Stack(
          children: [
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSpecial ? Colors.orangeAccent : Colors.blueAccent.withValues(alpha: 0.2))),
              child: CircleAvatar(
                radius: 26,
                backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
                child: Text(
                  name.contains(' ') ? name.split(' ').last.substring(0, 1) : name.substring(0, 1),
                  style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w900, fontSize: 18),
                ),
              ),
            ),
            if (unread > 0)
              Positioned(
                right: 0, top: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                  child: Text(unread.toString(), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                ),
              ),
          ],
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryTextColor, letterSpacing: -0.3),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isSpecial ? Colors.orangeAccent : Colors.blueAccent).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                role.toUpperCase(),
                style: TextStyle(color: isSpecial ? Colors.orangeAccent : Colors.blueAccent, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 0.5),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6.0),
          child: Text(
            lastMsg,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              color: unread > 0 ? (isDark ? Colors.white70 : Colors.black87) : secondaryTextColor,
              fontWeight: unread > 0 ? FontWeight.w900 : FontWeight.bold,
            ),
          ),
        ),
        trailing: Text(
          time,
          style: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 0.2),
        ),
      ),
    ).animate().fadeIn().slideX(begin: -0.05);
  }
}

class NewChatSearchScreen extends StatefulWidget {
  const NewChatSearchScreen({super.key});

  @override
  State<NewChatSearchScreen> createState() => _NewChatSearchScreenState();
}

class _NewChatSearchScreenState extends State<NewChatSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  List<String> get _parentNames {
    final classes = <ClassModel>[];
    if (classes.isNotEmpty && classes.first.students.isNotEmpty) {
      return classes.first.students.take(6).map((s) => s.name).toList();
    }
    return [];
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text.toLowerCase()));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black26;
    final loc = AppLocalizations.of(context)!;

    final filteredParents = _parentNames.where((n) => n.toLowerCase().contains(_query)).toList();
    final filteredClasses = <ClassModel>[].where((c) => c.name.toLowerCase().contains(_query)).toList();

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
        title: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(22),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold, fontSize: 14),
            decoration: InputDecoration(
              hintText: '${loc.translate('tab_individuel')} / ${loc.translate('tab_classes')}...',
              hintStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
              border: InputBorder.none,
              prefixIcon: Icon(Icons.search_rounded, color: secondaryTextColor, size: 20),
              isDense: true,
            ),
          ),
        ),
      ),
      body: DeepSpaceBackground(
        showOrbs: false,
        child: SafeArea(
          child: Column(
            children: [
               _buildSection(loc.translate('tab_individuel'), filteredParents, Colors.blueAccent, isDark, primaryTextColor, secondaryTextColor, loc),
               const Divider(height: 1, indent: 20, endIndent: 20),
               _buildSection(loc.translate('tab_classes'), filteredClasses, Colors.purpleAccent, isDark, primaryTextColor, secondaryTextColor, loc, isGroup: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<dynamic> items, Color color, bool isDark, Color pt, Color st, AppLocalizations loc, {bool isGroup = false}) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text(title.toUpperCase(), style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1.5)),
          ),
          Expanded(
            child: items.isEmpty
              ? Center(child: Text('—', style: TextStyle(color: st)))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];
                    final name = isGroup ? item.name : '${loc.translate('parent_of')} $item';
                    return _SearchResultTile(
                      name: name,
                      initial: name[0],
                      accentColor: color,
                      isDark: isDark,
                      primaryTextColor: pt,
                      secondaryTextColor: st,
                      isGroup: isGroup,
                      onTap: () {
                        if (isGroup) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ChatDetailScreen(
                                name: item.name,
                                avatarUrl: 'https://img.icons8.com/clouds/150/000000/groups.png',
                                classModel: item,
                              ),
                            ),
                          );
                        } else {
                           Navigator.push(context, MaterialPageRoute(builder: (_) => ChatDetailScreen(name: name, avatarUrl: 'https://i.pravatar.cc/150?u=$name')));
                        }
                      },
                    );
                  },
                ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultTile extends StatelessWidget {
  final String name;
  final String initial;
  final Color accentColor;
  final bool isDark;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final bool isGroup;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.name,
    required this.initial,
    required this.accentColor,
    required this.isDark,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.onTap,
    this.isGroup = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.white),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: accentColor.withValues(alpha: 0.1),
              child: isGroup
                  ? Icon(Icons.groups_rounded, color: accentColor, size: 20)
                  : Text(initial, style: TextStyle(color: accentColor, fontWeight: FontWeight.w900)),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(name, style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.bold))),
            Icon(Icons.chevron_right_rounded, color: secondaryTextColor, size: 20),
          ],
        ),
      ),
    );
  }
}

class ChatDetailScreen extends StatefulWidget {
  final String name;
  final String avatarUrl;
  final ClassModel? classModel;
  const ChatDetailScreen({super.key, required this.name, required this.avatarUrl, this.classModel});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  bool _isRecording = false;
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  final Set<int> _selectedIndices = {};

  bool get _isSelectionMode => _selectedIndices.isNotEmpty;

  void _startRecordingTimer() {
    setState(() {
      _recordingSeconds = 0;
      _isRecording = true;
    });
    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _recordingSeconds++);
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    if (mounted) setState(() => _isRecording = false);
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  final List<Map<String, dynamic>> _messages = [];

  @override
  void dispose() {
    _controller.dispose();
    _recordingTimer?.cancel();
    super.dispose();
  }

  void _showChatSettings() {
    final appState = Provider.of<AppState>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            _buildSettingsItem(Icons.info_outline_rounded, loc.translate('voir_details'), Colors.blueAccent, () {
               Navigator.pop(context);
               if (widget.classModel != null) {
                 Navigator.push(context, MaterialPageRoute(builder: (_) => GroupInfoScreen(
                   groupName: widget.name, 
                   classModel: widget.classModel,
                   messages: _messages,
                 )));
               } else {
                 final allStudents = <ClassModel>[].expand((c) => c.students).toList();
                 final student = allStudents.firstWhere((s) => s.name.contains(widget.name.split(' ').last), orElse: () => allStudents.first);
                 Navigator.push(context, MaterialPageRoute(builder: (_) => StudentDetailFullScreen(student: student)));
               }
            }),
            _buildSettingsItem(
              appState.mutedChatIds.contains(widget.name) ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
              appState.mutedChatIds.contains(widget.name) ? "Unmute" : loc.translate('mute_notifications'),
              Colors.orangeAccent,
              () {
                appState.toggleMuteChat(widget.name);
                Navigator.pop(context);
              },
            ),
            _buildSettingsItem(Icons.delete_outline_rounded, loc.translate('clear_chat'), Colors.redAccent, () {
              Navigator.pop(context);
              _confirmDeleteAll();
            }),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAll() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(loc.translate('clear_chat'), style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(loc.translate('confirm_delete_msg')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.translate('cancel_uppercase'))),
          ElevatedButton(
            onPressed: () {
              setState(() => _messages.clear());
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text(loc.translate('clear_chat')),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSelected() {
    final loc = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('${_selectedIndices.length} ${_selectedIndices.length > 1 ? loc.translate('messages').toLowerCase() : loc.translate('message').toLowerCase()}', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(loc.translate('confirm_delete_msg')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(loc.translate('cancel_uppercase'))),
          ElevatedButton(
            onPressed: () {
              final sortedIndices = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
              setState(() {
                for (var idx in sortedIndices) {
                  if (idx < _messages.length) _messages.removeAt(idx);
                }
                _selectedIndices.clear();
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: Text(loc.translate('delete_selected_btn')),
          ),
        ],
      ),
    );
  }

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
    });
  }

  void _showAttachmentMenu() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final loc = AppLocalizations.of(context)!;
    
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 32),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              mainAxisSpacing: 20,
              crossAxisSpacing: 10,
              children: [
                _buildAttachmentIcon(Icons.photo_library_rounded, loc.translate('camera_roll'), Colors.purpleAccent, () => _simulateMediaPicker(context, loc.translate('camera_roll'), Icons.photo_library_rounded)),
                _buildAttachmentIcon(Icons.camera_alt_rounded, loc.translate('selfie'), Colors.blueAccent, () => _simulateMediaPicker(context, loc.translate('selfie'), Icons.camera_alt_rounded)),
                _buildAttachmentIcon(Icons.video_collection_rounded, loc.translate('video_label'), Colors.orangeAccent, () => _simulateMediaPicker(context, loc.translate('video_label'), Icons.video_collection_rounded)),
                _buildAttachmentIcon(Icons.link_rounded, loc.translate('link_label'), Colors.tealAccent, () => _simulateMediaPicker(context, loc.translate('link_label'), Icons.link_rounded)),
                _buildAttachmentIcon(Icons.picture_as_pdf_rounded, loc.translate('pdf_label'), Colors.redAccent, () => _simulateMediaPicker(context, loc.translate('pdf_label'), Icons.picture_as_pdf_rounded)),
                _buildAttachmentIcon(Icons.mic_rounded, loc.translate('audio_recording'), Colors.greenAccent, () => _simulateMediaPicker(context, loc.translate('audio_recording'), Icons.mic_rounded)),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _simulateMediaPicker(BuildContext context, String type, IconData icon) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E293B) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), shape: BoxShape.circle), child: Icon(icon, color: Colors.blueAccent, size: 32)),
            const SizedBox(height: 16),
            Text("Simuler l'envoi de : $type", style: const TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler"))),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _sendAttachment(
                        (type.contains('Photo') || type.contains('Galerie') || type.contains('Selfie')) ? 'photo' : (type.contains('Audio') ? 'audio' : 'text'), 
                        (type.contains('Photo') || type.contains('Galerie') || type.contains('Selfie')) ? '' : '',
                        duration: type.contains('Audio') ? '0:00' : null
                      );
                    },
                    child: const Text("Envoyer"),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _sendAttachment(String type, String content, {String? duration}) {
    setState(() {
      _messages.add({
        'isMe': true,
        'content': content,
        'time': DateFormat('HH:mm').format(DateTime.now()),
        'type': type,
        if (duration != null) 'duration': duration,
      });
    });
  }

  Widget _buildAttachmentIcon(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSettingsItem(IconData icon, String title, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pt = isDark ? Colors.white : const Color(0xFF0F172A);
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              elevation: 4,
              leading: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.blueAccent),
                onPressed: () => setState(() => _selectedIndices.clear()),
              ),
              title: Text(
                '${_selectedIndices.length}',
                style: const TextStyle(fontWeight: FontWeight.w900, color: Colors.blueAccent),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                  onPressed: _confirmDeleteSelected,
                ),
                const SizedBox(width: 8),
              ],
            )
          : AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: Icon(Icons.arrow_back_ios_new, color: pt, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
              title: Row(
                children: [
                  CircleAvatar(radius: 18, backgroundImage: NetworkImage(widget.avatarUrl)),
                  const SizedBox(width: 12),
                  Text(widget.name, style: TextStyle(fontWeight: FontWeight.w900, color: pt, fontSize: 16)),
                ],
              ),
              actions: [
                IconButton(icon: Icon(Icons.settings_outlined, color: pt), onPressed: _showChatSettings),
                const SizedBox(width: 8),
              ],
            ),
      body: DeepSpaceBackground(
        showOrbs: false,
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(20),
                      itemCount: _messages.length,
                      itemBuilder: (context, i) => _buildBubble(_messages[i], i, isDark),
                    ),
                  ),
                  Consumer<AppState>(
                    builder: (context, appState, _) {
                      final isAdminOnly = appState.groupAdminOnlyMessaging.contains(widget.name);
                      if (!isAdminOnly) return const SizedBox.shrink();
                      return Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                        color: Colors.blueAccent.withValues(alpha: 0.1),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_outline_rounded, color: Colors.blueAccent, size: 14),
                            const SizedBox(width: 8),
                            Text(
                              loc.translate('admin_only_banner_msg'),
                              style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }
                  ),
                  _buildInput(isDark, pt, loc),
                ],
              ),
              if (_isRecording)
                Positioned(
                  bottom: 100,
                  left: 20,
                  right: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.3), blurRadius: 20)],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.mic_rounded, color: Colors.white).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1, 1), end: const Offset(1.2, 1.2), duration: const Duration(milliseconds: 600)),
                        const SizedBox(width: 16),
                        Text(loc.translate('audio_recording'), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(_formatDuration(_recordingSeconds), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, int index, bool isDark) {
    bool isMe = msg['isMe'];
    String type = msg['type'] ?? 'text';
    bool isSelected = _selectedIndices.contains(index);
    
    return GestureDetector(
      onLongPress: () => _toggleSelection(index),
      onTap: () {
        if (_isSelectionMode) {
          _toggleSelection(index);
        }
      },
      child: Container(
        color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.transparent,
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(type == 'photo' ? 4 : 12),
            decoration: BoxDecoration(
              color: isMe ? Colors.blueAccent : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isMe ? [] : [BoxShadow(color: Colors.white, blurRadius: 10)],
              border: isSelected ? Border.all(color: Colors.blueAccent, width: 2) : null,
            ),
            child: Column(
              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (type == 'text')
                  Text(msg['content'], style: TextStyle(color: isMe || isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
                if (type == 'photo')
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(msg['content'], width: 220, height: 160, fit: BoxFit.cover),
                  ),
                if (type == 'audio')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.play_circle_filled_rounded, color: isMe || isDark ? Colors.white : Colors.blueAccent, size: 32),
                      const SizedBox(width: 12),
                      Container(
                        width: 100,
                        height: 3,
                        decoration: BoxDecoration(color: (isMe || isDark ? Colors.white : Colors.blueAccent).withValues(alpha: 0.3), borderRadius: BorderRadius.circular(2)),
                      ),
                      const SizedBox(width: 12),
                      Text(msg['duration'] ?? '0:00', style: TextStyle(color: isMe || isDark ? Colors.white70 : Colors.black45, fontSize: 10, fontWeight: FontWeight.bold)),
                    ],
                  ),
                const SizedBox(height: 4),
                Text(msg['time'], style: TextStyle(color: (isMe || isDark ? Colors.white : Colors.black54).withValues(alpha: 0.5), fontSize: 9, fontWeight: FontWeight.bold)),
              ],
            ),
          ).animate().fadeIn().slideX(begin: isMe ? 0.1 : -0.1),
        ),
      ),
    );
  }

  Widget _buildInput(bool isDark, Color pt, AppLocalizations loc) {
    return Consumer<AppState>(
      builder: (context, appState, _) {
        final isAdminOnly = appState.groupAdminOnlyMessaging.contains(widget.name);
        
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0F172A) : Colors.white,
            border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.white)),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  isAdminOnly ? Icons.lock_outline_rounded : Icons.add_circle_outline_rounded, 
                  color: isAdminOnly ? Colors.amber : (isDark ? Colors.white38 : Colors.black38)
                ),
                onPressed: isAdminOnly ? null : _showAttachmentMenu,
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: isDark ? Colors.white10 : Colors.white),
                  ),
                  child: TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() {}),
                    style: TextStyle(color: pt, fontWeight: FontWeight.w600, fontSize: 14),
                    decoration: InputDecoration(
                      hintText: isAdminOnly 
                          ? loc.translate('admin_only_chat_setting') 
                          : loc.translate('input_message_hint'), 
                      hintStyle: TextStyle(
                        color: isAdminOnly 
                            ? Colors.amber.withValues(alpha: 0.5) 
                            : (isDark ? Colors.white.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.3))
                      ), 
                      border: InputBorder.none
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (_controller.text.isEmpty)
                GestureDetector(
                  onLongPressStart: isAdminOnly ? null : (_) => _startRecordingTimer(),
                  onLongPressEnd: isAdminOnly ? null : (_) {
                    final duration = _formatDuration(_recordingSeconds);
                    _stopRecordingTimer();
                    _sendAttachment('audio', 'Voice note', duration: duration);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: EdgeInsets.all(_isRecording ? 16 : 12),
                    decoration: BoxDecoration(
                      color: _isRecording ? Colors.redAccent : Colors.blueAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: _isRecording ? [BoxShadow(color: Colors.redAccent.withValues(alpha: 0.3), blurRadius: 15, spreadRadius: 5)] : [],
                    ),
                    child: Icon(
                      Icons.mic_rounded, 
                      color: isAdminOnly ? Colors.grey : (_isRecording ? Colors.white : Colors.blueAccent), 
                      size: _isRecording ? 28 : 24
                    ),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.send_rounded, color: Colors.blueAccent),
                  onPressed: () {
                    if (_controller.text.trim().isNotEmpty) {
                      setState(() {
                        _messages.add({
                          'isMe': true,
                          'content': _controller.text,
                          'time': DateFormat('HH:mm').format(DateTime.now()),
                          'type': 'text'
                        });
                        _controller.clear();
                      });
                    }
                  },
                ),
            ],
          ),
        );
      }
    );
  }
}
