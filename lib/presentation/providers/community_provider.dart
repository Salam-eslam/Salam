import 'package:flutter/foundation.dart';
import '../../core/utils/result.dart';
import '../../domain/entities/post_entity.dart';
import '../../domain/usecases/community/get_posts_usecase.dart';
import '../../domain/usecases/community/create_post_usecase.dart';
import '../../domain/usecases/community/toggle_like_post_usecase.dart';
import '../../domain/usecases/community/create_comment_usecase.dart';
import '../../domain/usecases/community/get_comments_usecase.dart';
import '../../domain/entities/comment_entity.dart';

class CommunityProvider with ChangeNotifier {
  final GetPostsUseCase getPostsUseCase;
  final CreatePostUseCase createPostUseCase;
  final ToggleLikePostUseCase toggleLikePostUseCase;
  final CreateCommentUseCase createCommentUseCase;
  final GetCommentsUseCase getCommentsUseCase;

  List<PostEntity> _posts = [];
  bool _isLoading = false;
  String? _error;

  // Map to store comments for each post
  final Map<String, List<CommentEntity>> _comments = {};
  final Map<String, bool> _loadingComments = {};

  CommunityProvider({
    required this.getPostsUseCase,
    required this.createPostUseCase,
    required this.toggleLikePostUseCase,
    required this.createCommentUseCase,
    required this.getCommentsUseCase,
  });

  List<PostEntity> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<CommentEntity> getCommentsForPost(String postId) =>
      _comments[postId] ?? [];
  bool isCommentsLoading(String postId) => _loadingComments[postId] ?? false;

  Future<void> loadPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await getPostsUseCase.execute();

    if (result is Success<List<PostEntity>>) {
      _posts = result.data;
    } else if (result is ResultError<List<PostEntity>>) {
      _error = result.failure.message;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createPost(
      String content, String userId, String username) async {
    final result = await createPostUseCase.execute(
      content: content,
      userId: userId,
      userName: username,
    );

    if (result is Success<PostEntity>) {
      _posts.insert(0, result.data);
      notifyListeners();
    } else if (result is ResultError<PostEntity>) {
      _error = result.failure.message;
      notifyListeners();
      throw Exception(result.failure.message); // Rethrow for UI to handle
    }
  }

  Future<void> toggleLikePost(String postId, String userId) async {
    // Optimistic update
    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final post = _posts[postIndex];
    final isLiked = post.isLiked;
    final newLikesCount = isLiked ? post.likesCount - 1 : post.likesCount + 1;

    // Update local state immediately
    _posts[postIndex] = post.copyWith(
      isLiked: !isLiked,
      likesCount: newLikesCount,
    );
    notifyListeners();

    // Call API
    final result =
        await toggleLikePostUseCase.execute(postId: postId, userId: userId);

    if (result is ResultError) {
      // Revert on error
      _posts[postIndex] = post; // Revert to original
      _error = result.failure.message;
      notifyListeners();
    }
  }

  Future<void> loadComments(String postId) async {
    _loadingComments[postId] = true;
    notifyListeners();

    final result = await getCommentsUseCase.execute(postId: postId);

    if (result is Success<List<CommentEntity>>) {
      _comments[postId] = result.data;
    }
    // We could handle error here, but for now just stop loading

    _loadingComments[postId] = false;
    notifyListeners();
  }

  Future<void> addComment(
      String postId, String content, String userId, String username) async {
    final result = await createCommentUseCase.execute(
      postId: postId,
      content: content,
      userId: userId,
      userName: username,
    );

    if (result is Success<CommentEntity>) {
      // Add to local list
      final currentComments = _comments[postId] ?? [];
      _comments[postId] = [result.data, ...currentComments];

      // Update post comment count locally
      final postIndex = _posts.indexWhere((p) => p.id == postId);
      if (postIndex != -1) {
        final post = _posts[postIndex];
        _posts[postIndex] =
            post.copyWith(commentsCount: post.commentsCount + 1);
      }

      notifyListeners();
    } else if (result is ResultError<CommentEntity>) {
      _error = result.failure.message;
      notifyListeners();
      throw Exception(result.failure.message);
    }
  }
}
