import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/models/models.dart';
import '../../../core/services/api_service.dart';

class FeedViewModel extends ChangeNotifier {
  final ApiService _apiService = ApiService.instance;

  List<PostModel> _posts = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<PostModel> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Fetch posts from API
  Future<void> fetchPosts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final freshPosts = await _apiService.getPosts();
      
      // Load local likes
      final prefs = await SharedPreferences.getInstance();
      final likedPostIds = prefs.getStringList('local_liked_posts') ?? [];
      
      _posts = freshPosts.map((post) {
        if (likedPostIds.contains(post.id)) {
           return post.copyWith(isLiked: true, likes: post.isLiked ? post.likes : post.likes + 1);
        }
        return post;
      }).toList();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      notifyListeners();
    }
  }

  // OPTIMISTIC UI: Toggle Like
  Future<void> toggleLike(PostModel post, {String? userName, String? userAvatar}) async {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final originalPost = _posts[index];
    final isLiked = !originalPost.isLiked;
    
    final currentUserName = userName ?? "Moi";
    List<LikeModel> newLikedBy = List.from(originalPost.likedBy);
    
    if (isLiked) {
      // Prevent duplicates in likedBy (Instagram behavior)
      if (!newLikedBy.any((l) => l.userName.toLowerCase() == currentUserName.toLowerCase())) {
        newLikedBy.add(LikeModel(userName: currentUserName, userAvatar: userAvatar));
      }
    } else {
      newLikedBy.removeWhere((l) => l.userName.toLowerCase() == currentUserName.toLowerCase());
    }

    _posts[index] = originalPost.copyWith(
      isLiked: isLiked,
      likes: newLikedBy.length, // Ensure likes count perfectly matches the list
      likedBy: newLikedBy,
    );
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final likedPostIds = prefs.getStringList('local_liked_posts') ?? [];
      if (isLiked && !likedPostIds.contains(post.id)) {
        likedPostIds.add(post.id);
        await prefs.setStringList('local_liked_posts', likedPostIds);
      } else if (!isLiked && likedPostIds.contains(post.id)) {
        likedPostIds.remove(post.id);
        await prefs.setStringList('local_liked_posts', likedPostIds);
      }
    } catch (e) {
      // Ignore prefs error
    }

    try {
      final success = await _apiService.likePost(post.id);
      if (!success) throw Exception('API failed');
    } catch (e) {
      // User specifically requested to keep the heart red even on error
      // _posts[index] = originalPost;
      _errorMessage = 'failed_to_like';
      notifyListeners();
      
      Future.delayed(const Duration(seconds: 2), () {
        _errorMessage = null;
        notifyListeners();
      });
    }
  }

  // OPTIMISTIC UI: Add Comment
  Future<void> addComment(String postId, String authorName, String content) async {
    final index = _posts.indexWhere((p) => p.id == postId);
    if (index == -1) return;

    final originalPost = _posts[index];
    final tempCommentId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    
    final tempComment = CommentModel(
      id: tempCommentId,
      authorName: authorName,
      content: content,
      date: 'À l\'instant',
    );

    _posts[index] = originalPost.copyWith(
      comments: originalPost.comments + 1,
      commentsList: [...originalPost.commentsList, tempComment],
    );
    notifyListeners();

    try {
      final realComment = await _apiService.addComment(postId, content);
      
      final updatedIndex = _posts.indexWhere((p) => p.id == postId);
      if (updatedIndex != -1) {
        final currentPost = _posts[updatedIndex];
        
        final combinedComment = CommentModel(
          id: realComment.id,
          authorName: authorName, // Keep the actual user's name locally
          content: content,
          date: DateTime.now().toUtc().toIso8601String(), // Force REAL time to override mock server dates
          authorAvatar: tempComment.authorAvatar,
        );

        final newList = currentPost.commentsList.map((c) => c.id == tempCommentId ? combinedComment : c).toList();
        _posts[updatedIndex] = currentPost.copyWith(commentsList: newList);
        notifyListeners();
      }
    } catch (e) {
      _posts[index] = originalPost;
      _errorMessage = 'failed_to_comment';
      notifyListeners();
      
      Future.delayed(const Duration(seconds: 2), () {
        _errorMessage = null;
        notifyListeners();
      });
    }
  }

  void toggleSave(PostModel post) {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index != -1) {
      _posts[index] = _posts[index].copyWith(isSaved: !post.isSaved);
      notifyListeners();
    }
  }

  void clearErrorMessage() {
    _errorMessage = null;
    notifyListeners();
  }
}
