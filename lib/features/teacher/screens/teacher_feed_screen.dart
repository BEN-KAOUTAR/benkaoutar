import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/services/mock_data.dart';
import '../../../core/models/models.dart';
import '../../../core/widgets/deep_space_background.dart';
import '../../../core/localization/app_localizations.dart';

class TeacherFeedScreen extends StatefulWidget {
  const TeacherFeedScreen({super.key});

  @override
  State<TeacherFeedScreen> createState() => _TeacherFeedScreenState();
}

class _TeacherFeedScreenState extends State<TeacherFeedScreen> {
  List<PostModel> _posts = [];

  @override
  void initState() {
    super.initState();
    _posts = List.from(MockData.posts);
  }


  void _createPost() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final controller = TextEditingController();
        bool isEvent = false;
        return StatefulBuilder(builder: (context, setSheetState) {
          return Container(
            padding: EdgeInsets.fromLTRB(24, 20, 24, MediaQuery.of(context).viewInsets.bottom + 40),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
                ),
                const SizedBox(height: 24),
                Text(AppLocalizations.of(context)!.translate('new_post'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white, letterSpacing: -0.5)),
                const SizedBox(height: 24),
                TextField(
                  controller: controller,
                  maxLines: 4,
                  style: const TextStyle(color: Colors.white, fontSize: 15),
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)!.translate('post_hint'),
                    hintStyle: const TextStyle(color: Colors.white24, fontSize: 14),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.white10)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.white10)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Colors.blueAccent)),
                    filled: true,
                    fillColor: Colors.white.withValues(alpha: 0.02),
                    contentPadding: const EdgeInsets.all(20),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    _buildSheetAction(Icons.camera_alt_rounded, AppLocalizations.of(context)!.translate('photo_btn'), false, () {}),
                    const SizedBox(width: 12),
                    _buildSheetAction(Icons.calendar_today_rounded, AppLocalizations.of(context)!.translate('event'), isEvent, () => setSheetState(() => isEvent = !isEvent)),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (controller.text.trim().isNotEmpty) {
                        setState(() {
                          _posts.insert(0, PostModel(
                            id: 'new_${_posts.length}',
                            authorName: 'Mme. Lahlou',
                            authorRole: AppLocalizations.of(context)!.translate('teacher_role'),
                            content: controller.text.trim(),
                            date: AppLocalizations.of(context)!.translate('just_now'),
                            isEvent: isEvent,
                            eventDate: isEvent ? AppLocalizations.of(context)!.translate('todo_status') : null,
                          ));
                        });
                      }
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: Text(AppLocalizations.of(context)!.translate('publish_now'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildSheetAction(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.blueAccent : Colors.white10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: isSelected ? Colors.blueAccent : Colors.white70),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.blueAccent : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(AppLocalizations.of(context)!.translate('news_title'), style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor, fontSize: 18)),
        automaticallyImplyLeading: false,
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: _posts.isEmpty
              ? Center(child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.feed_rounded, size: 64, color: isDark ? Colors.white10 : Colors.black12),
                    const SizedBox(height: 20),
                    Text(AppLocalizations.of(context)!.translate('no_posts'), style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontWeight: FontWeight.w900, letterSpacing: 1)),
                  ],
                ))
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 100),
                  itemCount: _posts.length,
                  itemBuilder: (context, index) {
                    final post = _posts[index];
                    return _buildPostCard(post, index, isDark);
                  },
                ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createPost,
        backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
        foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        icon: const Icon(Icons.add_rounded, size: 24),
        label: Text(AppLocalizations.of(context)!.translate('publish'), style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: 1)),
      ).animate().scale(delay: const Duration(milliseconds: 400)),

    );
  }

  Widget _buildPostCard(PostModel post, int index, bool isDark) {
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white24 : Colors.black26;
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.white.withValues(alpha: 0.7), blurRadius: 20)],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: primaryTextColor.withValues(alpha: 0.1))),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                    child: Text(post.authorName.substring(0, 1), style: TextStyle(color: primaryTextColor, fontWeight: FontWeight.w900)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(post.authorName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: primaryTextColor)),
                      Text(post.date, style: TextStyle(color: secondaryTextColor, fontSize: 11, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                if (post.isEvent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withValues(alpha: 0.1), 
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orangeAccent.withValues(alpha: 0.2)),
                    ),
                    child: Text(AppLocalizations.of(context)!.translate('event'), style: const TextStyle(color: Colors.orangeAccent, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            Text(post.content, style: TextStyle(fontSize: 14, height: 1.6, color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w600)),
            const SizedBox(height: 20),
            Row(
              children: [
                _buildPostStat('❤️', post.likes.toString(), isDark),
                const SizedBox(width: 20),
                _buildPostStat('💬', post.comments.toString(), isDark),
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: (80 * index))).slideY(begin: 0.05);
  }

  Widget _buildPostStat(String emoji, String count, bool isDark) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Text(count, style: TextStyle(color: isDark ? Colors.white38 : Colors.black45, fontSize: 12, fontWeight: FontWeight.w900)),
      ],
    );
  }
}
