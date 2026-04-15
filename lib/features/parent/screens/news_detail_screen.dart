import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/localization/app_localizations.dart';

class NewsDetailScreen extends StatelessWidget {
  final Map<String, dynamic>? news;

  const NewsDetailScreen({super.key, this.news});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final secondaryTextColor =
        isDark ? Colors.white60 : const Color(0xFF94A3B8);
    final backgroundColor = isDark ? const Color(0xFF020617) : Colors.white;

    final title = news?['title'] ??
        'Grande Fête de la Science 2026 : Un succès retentissant';
    final content = news?['content'] ??
        'Ce vendredi, nos élèves de primaire ont transformé la cour de l\'école en un véritable laboratoire à ciel ouvert. Entre expériences de chimie volcanique et démonstrations de robotique, l\'enthousiasme était palpable.\n\nLes parents ont pu découvrir les projets innovants sur lesquels les classes travaillent depuis le début du trimestre. L\'objectif était de rendre les sciences accessibles et ludiques pour tous.';
    final category = news?['category'] ?? 'Événement';
    final timeAgo = news?['time'] ?? '2h';
    final imageUrl = news?['image'] ??
        'https://images.unsplash.com/photo-1511632765486-a01980e01a18?auto=format&fit=crop&q=80';
    final likes = news?['likes']?.toString() ?? '124';
    final commentsCount = news?['comments_count']?.toString() ?? '12';

    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, imageUrl),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildCategoryBadge(context, category),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 32,
                        color: primaryTextColor,
                        height: 1.1,
                        letterSpacing: -1),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 16, color: secondaryTextColor),
                      const SizedBox(width: 8),
                      Text(
                          '${AppLocalizations.of(context)!.translate('published_ago')} $timeAgo',
                          style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                      const SizedBox(width: 24),
                      Icon(Icons.timer_outlined,
                          color: secondaryTextColor, size: 14),
                      const SizedBox(width: 6),
                      Text(
                          '5 ${AppLocalizations.of(context)!.translate('read_time')}',
                          style: TextStyle(
                              color: secondaryTextColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    content,
                    style: TextStyle(
                        color:
                            isDark ? Colors.white70 : const Color(0xFF475569),
                        fontSize: 16,
                        height: 1.8,
                        fontWeight: FontWeight.w500),
                  ),
                  _buildActionRow(context, likes, commentsCount),
                  const SizedBox(height: 48),
                  Text(
                      AppLocalizations.of(context)!
                          .translate('gallery_photos_upper'),
                      style: TextStyle(
                          color: isDark ? Colors.white38 : Colors.black38,
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5)),
                  const SizedBox(height: 20),
                  _buildPhotoGallery(),
                  const SizedBox(height: 48),
                  _buildQuoteSection(context),
                  const SizedBox(height: 16),
                  Divider(
                      height: 48,
                      color: isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
                  _buildCommentsSection(context, commentsCount),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: _buildCommentInput(context),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String imageUrl) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 350,
      pinned: true,
      backgroundColor:
          isDark ? const Color(0xFF0F172A) : const Color(0xFF1E1B4B),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.3),
              shape: BoxShape.circle),
          child: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.blueAccent)),
              ),
              errorWidget: (context, url, error) => Container(
                color:
                    isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.image_not_supported_rounded,
                        color: Colors.white24, size: 64),
                    const SizedBox(height: 12),
                    Text(
                      AppLocalizations.of(context)!
                          .translate('image_not_available'),
                      style: const TextStyle(
                          color: Colors.white38, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: 0.6),
                    Colors.transparent,
                    isDark ? const Color(0xFF020617) : Colors.white
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBadge(BuildContext context, String category) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          color: Colors.cyanAccent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(12)),
      child: Text(category.toUpperCase(),
          style: const TextStyle(
              color: Colors.cyanAccent,
              fontWeight: FontWeight.w900,
              fontSize: 10,
              letterSpacing: 1.5)),
    );
  }

  Widget _buildActionRow(BuildContext context, String likes, String comments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final secondaryTextColor =
        isDark ? Colors.white60 : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(top: 40),
      child: Row(
        children: [
          _buildStatItem(
              context, Icons.favorite_rounded, likes, Colors.pinkAccent),
          const SizedBox(width: 24),
          _buildStatItem(context, Icons.chat_bubble_rounded, comments,
              Colors.indigoAccent),
          const Spacer(),
          IconButton(
              onPressed: () {},
              icon: Icon(Icons.bookmark_border_rounded,
                  color: secondaryTextColor)),
          IconButton(
              onPressed: () {},
              icon: Icon(Icons.share_outlined, color: secondaryTextColor)),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, IconData icon, String count, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 8),
        Text(count,
            style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: isDark ? Colors.white : const Color(0xFF1E1B4B))),
      ],
    );
  }

  Widget _buildPhotoGallery() {
    return SizedBox(
      height: 180,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        children: [
          _buildGalleryImage(
              'https://images.unsplash.com/photo-1564066394514-821079bc0863?auto=format&fit=crop&q=80'),
          _buildGalleryImage(
              'https://images.unsplash.com/photo-1518133910546-b6c2fb7d79e3?auto=format&fit=crop&q=80'),
          _buildGalleryImage(
              'https://images.unsplash.com/photo-1544621591-4e7892af2f6e?auto=format&fit=crop&q=80'),
        ],
      ),
    );
  }

  Widget _buildGalleryImage(String url) {
    return Container(
      width: 180,
      margin: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10)
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: CachedNetworkImage(
          imageUrl: url,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.white.withValues(alpha: 0.1),
            child: const Center(
                child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2))),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.white.withValues(alpha: 0.1),
            child:
                const Icon(Icons.broken_image_rounded, color: Colors.white24),
          ),
        ),
      ),
    );
  }

  Widget _buildQuoteSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.indigoAccent.withValues(alpha: 0.05)
            : const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.indigoAccent.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.format_quote_rounded,
              color: isDark ? Colors.indigoAccent : const Color(0xFF4338CA),
              size: 40),
          const SizedBox(height: 16),
          Text(
            '« Voir l\'étincelle de curiosité dans les yeux de nos enfants est la plus belle récompense pour toute l\'équipe pédagogique. »',
            style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF4338CA),
                fontSize: 16,
                height: 1.6,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 24),
          Text('— Mme. Dubois, Directrice',
              style: TextStyle(
                  color: isDark ? Colors.indigoAccent : const Color(0xFF6366F1),
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildCommentsSection(BuildContext context, String count) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
                '${AppLocalizations.of(context)!.translate('comments_count')} ($count)',
                style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.black38,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5)),
            TextButton(
                onPressed: () {},
                child: Text(
                    AppLocalizations.of(context)!.translate('view_all_upper'),
                    style: const TextStyle(
                        color: Colors.blueAccent,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1))),
          ],
        ),
        const SizedBox(height: 24),
        _buildCommentItem(
            context,
            'Marc Lefebvre',
            'PARENT',
            'Magnifique Initiative ! Mon fils Lucas n\'arrête pas de parler de l\'expérience avec l\'azote liquide. Merci aux enseignants.',
            'Il y a 1h'),
        const SizedBox(height: 32),
        _buildCommentItem(
            context,
            'Sophie Martin',
            'PARENT',
            'Les photos sont superbes, on ressent vraiment l\'ambiance de la journée. C\'était un plaisir d\'y participer.',
            'Il y a 45min'),
      ],
    );
  }

  Widget _buildCommentItem(BuildContext context, String user, String role,
      String content, String time) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryTextColor = isDark ? Colors.white : const Color(0xFF1E1B4B);
    final secondaryTextColor =
        isDark ? Colors.white38 : const Color(0xFF94A3B8);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
            radius: 24,
            backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$user')),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(user,
                          style: TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: primaryTextColor)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: Colors.indigoAccent.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6)),
                        child: Text(role.toUpperCase(),
                            style: const TextStyle(
                                color: Colors.indigoAccent,
                                fontSize: 8,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1)),
                      ),
                    ],
                  ),
                  Text(time,
                      style: TextStyle(
                          color: secondaryTextColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              Text(content,
                  style: TextStyle(
                      color: isDark ? Colors.white70 : const Color(0xFF475569),
                      fontSize: 14,
                      height: 1.6)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCommentInput(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
            top: BorderSide(
                color: isDark ? Colors.white10 : const Color(0xFFF1F5F9))),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                    color: Colors.white,
                    blurRadius: 20,
                    offset: const Offset(0, -10))
              ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            const CircleAvatar(
                radius: 20,
                backgroundImage:
                    NetworkImage('https://i.pravatar.cc/150?u=User')),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(24)),
                child: Text('Ajouter un commentaire...',
                    style: TextStyle(
                        color:
                            isDark ? Colors.white38 : const Color(0xFF94A3B8),
                        fontSize: 14,
                        fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                  color: Colors.indigoAccent, shape: BoxShape.circle),
              child:
                  const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
