import 'package:flutter/material.dart';
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
      _posts = await _apiService.getPosts();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = _apiService.getLocalizedErrorMessage(e);
      notifyListeners();
    }
  }

  // OPTIMISTIC UI: Toggle Like
  Future<void> toggleLike(PostModel post) async {
    final index = _posts.indexWhere((p) => p.id == post.id);
    if (index == -1) return;

    final originalPost = _posts[index];
    final isLiked = !originalPost.isLiked;
    _posts[index] = originalPost.copyWith(
      isLiked: isLiked,
      likes: isLiked ? originalPost.likes + 1 : originalPost.likes - 1,
    );
    notifyListeners();

    try {
      final success = await _apiService.likePost(post.id);
      if (!success) throw Exception('API failed');
    } catch (e) {
      _posts[index] = originalPost;
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
        final newList = currentPost.commentsList.map((c) => c.id == tempCommentId ? realComment : c).toList();
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
