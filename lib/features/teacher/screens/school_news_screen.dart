import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/deep_space_background.dart';

// ─────────────────────────────────────────────────────────────
// Data Models for News Posts
// ─────────────────────────────────────────────────────────────

class NewsPost {
  final String id;
  final String authorName;
  final String authorRole;
  final String content;
  final String time;
  final String? imageUrl;
  final List<String>? extraImages;
  int likes;
  int comments;
  bool isLiked;
  final bool isEvent;
  final String? eventDate;
  final List<NewsComment> commentList;

  NewsPost({
    required this.id,
    required this.authorName,
    required this.authorRole,
    required this.content,
    required this.time,
    this.imageUrl,
    this.extraImages,
    this.likes = 0,
    this.comments = 0,
    this.isEvent = false,
    this.eventDate,
    List<NewsComment>? commentList,
  }) : commentList = commentList ?? [],
       isLiked = false;
}

class NewsComment {
  final String author;
  final String text;
  final String time;
  NewsComment({required this.author, required this.text, required this.time});
}

// ─────────────────────────────────────────────────────────────
// School News Feed Screen
// ─────────────────────────────────────────────────────────────
class SchoolNewsScreen extends StatefulWidget {
  const SchoolNewsScreen({super.key});

  @override
  State<SchoolNewsScreen> createState() => _SchoolNewsScreenState();
}

class _SchoolNewsScreenState extends State<SchoolNewsScreen> {
  final List<NewsPost> _posts = [
    NewsPost(
      id: '1',
      authorName: 'news_author_atelier_tech',
      authorRole: 'news_cat_info',
      content: 'Félicitations à nos élèves de 5ème pour leur victoire au concours régional de robotique ! Leurs prototypes innovants ont impressionné le jury.',
      time: 'Il y a 1h',
      imageUrl: 'https://images.unsplash.com/photo-1581091226825-a6a2a5aee158?w=800&q=80',
      likes: 34,
      comments: 8,
    ),
    NewsPost(
      id: '2',
      authorName: 'news_author_dept_sport',
      authorRole: 'news_cat_club',
      content: 'Le tournoi de football inter-classes commence ce vendredi. Venez nombreux encourager nos jeunes athلهètes sur le terrain principal !',
      time: 'Il y a 3h',
      imageUrl: 'https://images.unsplash.com/photo-1574629810360-7efbbe195018?w=800&q=80',
      likes: 62,
      comments: 15,
      isEvent: true,
      eventDate: '5 Avril 2026',
    ),
    NewsPost(
      id: '4',
      authorName: 'news_author_sciences',
      authorRole: 'news_cat_exploration',
      content: 'Sortie scolaire au jardin botanique ! Une journée riche en découvertes pour nos élèves qui ont pu observer des espèces rares et apprendre sur la biodiversité.',
      time: 'Hier',
      imageUrl: 'https://images.unsplash.com/photo-1585320806297-9794b3e4eeae?w=800&q=80',
      likes: 45,
      comments: 12,
    ),
    NewsPost(
      id: '3',
      authorName: 'news_author_admin',
      authorRole: 'news_cat_official',
      content: 'Rappel : Les réunions parents-profs sont prévues pour la semaine prochaine. Veuillez choisir votre créneau via le portail.',
      time: 'Hier',
      likes: 19,
      comments: 3,
      commentList: [
        NewsComment(author: 'Mme. Lahlou', text: 'Merci pour l\'information !', time: '10h30'),
        NewsComment(author: 'M. Bensaid', text: 'Confirmé pour le jeudi.', time: '11:00'),
      ],
    ),
    NewsPost(
      id: '5',
      authorName: 'news_author_library',
      authorRole: 'news_cat_culture',
      content: 'Nouvel arrivage de livres ! Venez découvrir notre sélection "Coups de cœur du mois" de littérature jeunesse et de bandes dessinées.',
      time: '2 Jours',
      imageUrl: 'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f?w=800&q=80',
      likes: 28,
      comments: 5,
    ),
  ];

  bool _isSearching = false;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<NewsPost> get _filteredPosts {
    if (_searchQuery.isEmpty) return _posts;
    return _posts.where((post) {
      return post.content.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             post.authorName.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  void _toggleLike(String postId) {
    setState(() {
      final post = _posts.firstWhere((p) => p.id == postId);
      post.isLiked = !post.isLiked;
      post.likes += post.isLiked ? 1 : -1;
    });
  }

  void _deletePost(String postId) {
    setState(() {
      _posts.removeWhere((p) => p.id == postId);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.translate('news_deleted_success')),
        backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _editPost(NewsPost post) {
    final TextEditingController _editController = TextEditingController(text: post.content);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.edit_note_rounded, color: Colors.blueAccent, size: 24),
              ),
              const SizedBox(width: 16),
              Text(AppLocalizations.of(context)!.translate('edit_post') ?? 'Modifier', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: isDark ? Colors.white : Colors.black)),
            ],
          ),
          content: TextField(
            controller: _editController,
            maxLines: 5,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context)!.translate('edit_post_hint'),
              hintStyle: TextStyle(color: isDark ? Colors.white24 : Colors.black26),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
              filled: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context)!.translate('cancel_uppercase') ?? 'ANNULER', style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w900, fontSize: 12)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  final index = _posts.indexOf(post);
                  if (index != -1) {
                    _posts[index] = NewsPost(
                      id: post.id,
                      authorName: post.authorName,
                      authorRole: post.authorRole,
                      content: _editController.text,
                      time: post.time,
                      imageUrl: post.imageUrl,
                      extraImages: post.extraImages,
                      likes: post.likes,
                      comments: post.comments,
                      isEvent: post.isEvent,
                      eventDate: post.eventDate,
                      commentList: post.commentList,
                    );
                    _posts[index].isLiked = post.isLiked;
                  }
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(AppLocalizations.of(context)!.translate('save_changes_upper') ?? 'SAUVEGARDER', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12)),
            ),
          ],
        );
      },
    );
  }

  void _showComments(NewsPost post, bool isDark) {
    final commentController = TextEditingController();
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(builder: (context, setSheetState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                // Handle
                const SizedBox(height: 12),
                Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.translate('comments_title'), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryTextColor)),
                const Divider(height: 24),

                // Comment List
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      ...post.commentList.map((c) => _buildCommentTile(c, isDark, primaryTextColor, secondaryTextColor)),
                      if (post.commentList.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Text(AppLocalizations.of(context)!.translate('no_comments_yet'), style: TextStyle(color: secondaryTextColor)),
                          ),
                        ),
                    ],
                  ),
                ),

                // Comment Input
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.08))),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: TextField(
                            controller: commentController,
                            style: TextStyle(color: primaryTextColor, fontSize: 13),
                            decoration: InputDecoration(
                              hintText: AppLocalizations.of(context)!.translate('write_comment_hint'),
                              hintStyle: TextStyle(color: secondaryTextColor, fontSize: 13),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () {
                          final text = commentController.text.trim();
                          if (text.isNotEmpty) {
                            setState(() {
                              post.commentList.add(NewsComment(
                                author: AppLocalizations.of(context)!.translate('me_label'), 
                                text: text, 
                                time: AppLocalizations.of(context)!.translate('just_now')
                              ));
                              post.comments++;
                            });
                            setSheetState(() {});
                            commentController.clear();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                          child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _buildCommentTile(NewsComment comment, bool isDark, Color primaryTextColor, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: Colors.blueAccent.withValues(alpha: 0.15),
            child: Text(comment.author[0], style: const TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.w900, fontSize: 12)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withValues(alpha: 0.04) : Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(comment.author, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 12, color: primaryTextColor)),
                  const SizedBox(height: 4),
                  Text(comment.text, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87)),
                  const SizedBox(height: 4),
                  Text(comment.time, style: TextStyle(color: secondaryTextColor, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: _isSearching 
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: TextStyle(color: primaryTextColor, fontSize: 16, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.translate('search_posts'),
                hintStyle: TextStyle(color: secondaryTextColor, fontSize: 14),
                border: InputBorder.none,
              ),
              onChanged: (val) => setState(() => _searchQuery = val),
            )
          : Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.campaign_rounded, color: Colors.blueAccent, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  AppLocalizations.of(context)!.translate('news_title'),
                  style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor, fontSize: 20, letterSpacing: -0.5),
                ),
              ],
            ),
        actions: [
          IconButton(
            icon: Icon(Icons.bookmark_border_rounded, color: primaryTextColor),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SavedPostsScreen(allPosts: _posts))),
          ),
          IconButton(
            icon: Icon(_isSearching ? Icons.close_rounded : Icons.search_rounded, color: primaryTextColor),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchQuery = '';
                  _searchController.clear();
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: DeepSpaceBackground(
        showOrbs: true,
        child: SafeArea(
          child: Column(
            children: [
              _buildSavedHistory(context, isDark),
              Expanded(
                child: _filteredPosts.isEmpty 
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off_rounded, size: 64, color: secondaryTextColor),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context)!.translate('no_results_found'), style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  )
                : ListView.builder(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                    itemCount: _filteredPosts.length,
                    itemBuilder: (context, index) {
                      return _buildNewsCard(context, _filteredPosts[index], index, isDark, primaryTextColor, secondaryTextColor);
                    },
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSavedHistory(BuildContext context, bool isDark) {
    if (_isSearching) return const SizedBox.shrink();
    
    final appState = Provider.of<AppState>(context);
    final savedPosts = _posts.where((p) => appState.isPostSaved(p.id)).toList();
    if (savedPosts.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
          child: Text(
            AppLocalizations.of(context)!.translate('saved_history_title'), 
            style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.5)
          ),
        ),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: savedPosts.length,
            itemBuilder: (context, i) {
              final post = savedPosts[i];
              return Container(
                width: 160,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
                  image: post.imageUrl != null ? DecorationImage(
                    image: NetworkImage(post.imageUrl!), 
                    fit: BoxFit.cover, 
                    colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.45), BlendMode.darken)
                  ) : null,
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.blueAccent, shape: BoxShape.circle),
                      child: const Icon(Icons.bookmark_rounded, color: Colors.white, size: 10),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      post.content,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, height: 1.2),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: (i * 100).ms).slideX(begin: 0.2);
            },
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsPost post, int index, bool isDark, Color primaryTextColor, Color secondaryTextColor) {
    final appState = Provider.of<AppState>(context);
    final isSaved = appState.isPostSaved(post.id);
    final cardBg = isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white;

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(36),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.white),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.white.withValues(alpha: 0.8), blurRadius: 30, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar + Info + Bookmark
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 50, height: 50,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.2)),
                  ),
                  child: const Center(
                    child: Icon(Icons.verified_user_rounded, color: Colors.blueAccent, size: 24),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(AppLocalizations.of(context)!.translate(post.authorName), style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: primaryTextColor)),
                      Text(AppLocalizations.of(context)!.translate(post.authorRole), style: TextStyle(color: secondaryTextColor.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: isSaved ? Colors.blueAccent : secondaryTextColor,
                    size: 24,
                  ),
                  onPressed: () => appState.toggleSavePost(post.id),
                ),
              ],
            ),
          ),

          // Content Text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            child: Text(
              post.content,
              style: TextStyle(
                fontSize: 15,
                height: 1.6,
                color: isDark ? Colors.white.withValues(alpha: 0.7) : Colors.black.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Main Image
          if (post.imageUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.network(
                  post.imageUrl!,
                  height: 240,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    height: 240,
                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8),
                    child: Center(child: Icon(Icons.image_not_supported_rounded, color: secondaryTextColor, size: 40)),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Engagement Stats
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                 Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: Colors.blueAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                         const Icon(Icons.favorite_rounded, color: Colors.blueAccent, size: 14),
                         const SizedBox(width: 6),
                         Text('${post.likes} ${AppLocalizations.of(context)!.translate('likes_count')}', style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.w900)),
                      ],
                    ),
                 ),
                 const SizedBox(width: 8),
                 Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white.withValues(alpha: 0.8), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                         Icon(Icons.chat_bubble_rounded, color: isDark ? Colors.white38 : Colors.black38, size: 14),
                         const SizedBox(width: 6),
                         Text('${post.comments} ${AppLocalizations.of(context)!.translate('comments_count')}', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11, fontWeight: FontWeight.w900)),
                      ],
                    ),
                 ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Dual Action Buttons (Large like in the first pic)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Row(
              children: [
                Expanded(
                  child: _buildLargeActionBtn(
                    context: context,
                    icon: post.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                    label: AppLocalizations.of(context)!.translate('like_btn'),
                    color: post.isLiked ? Colors.redAccent : primaryTextColor,
                    onTap: () => _toggleLike(post.id),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildLargeActionBtn(
                    context: context,
                    icon: Icons.chat_bubble_outline_rounded,
                    label: AppLocalizations.of(context)!.translate('comment_btn'),
                    color: primaryTextColor,
                    onTap: () => _showComments(post, isDark),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1);
  }

  Widget _buildLargeActionBtn({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 10),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Saved Posts History Screen
// ─────────────────────────────────────────────────────────────
class SavedPostsScreen extends StatelessWidget {
  final List<NewsPost> allPosts;
  const SavedPostsScreen({super.key, required this.allPosts});

  @override
  Widget build(BuildContext context) {
    final appState = Provider.of<AppState>(context);
    final savedPosts = allPosts.where((p) => appState.savedPostIds.contains(p.id)).toList();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final secondaryTextColor = isDark ? Colors.white38 : Colors.black38;

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
        title: Text(
          AppLocalizations.of(context)!.translate('saved_posts'),
          style: TextStyle(fontWeight: FontWeight.w900, color: primaryTextColor, fontSize: 18),
        ),
      ),
      body: DeepSpaceBackground(
        showOrbs: false,
        child: SafeArea(
          child: savedPosts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 64, color: secondaryTextColor),
                  const SizedBox(height: 16),
                  Text(
                    AppLocalizations.of(context)!.translate('no_posts'),
                    style: TextStyle(color: secondaryTextColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.all(20),
              itemCount: savedPosts.length,
              itemBuilder: (context, index) {
                final post = savedPosts[index];
                return _buildSavedItem(context, post, isDark, primaryTextColor, secondaryTextColor);
              },
            ),
        ),
      ),
    );
  }

  Widget _buildSavedItem(BuildContext context, NewsPost post, bool isDark, Color primaryTextColor, Color secondaryTextColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
      ),
      child: Row(
        children: [
          if (post.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(post.imageUrl!, width: 80, height: 80, fit: BoxFit.cover),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(post.authorName, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: primaryTextColor)),
                const SizedBox(height: 4),
                Text(
                   post.content,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: secondaryTextColor, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_rounded, color: Colors.blueAccent),
            onPressed: () => Provider.of<AppState>(context, listen: false).toggleSavePost(post.id),
          ),
        ],
      ),
    );
  }
}
