import '../../repositories/community_repository_interface.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';

/// Use case for toggling like on a post
///
/// If user has already liked the post, removes the like.
/// If user hasn't liked the post, adds a like.
class ToggleLikePostUseCase {
  final CommunityRepositoryInterface repository;

  ToggleLikePostUseCase(this.repository);

  /// Execute the use case
  ///
  /// [postId] - ID of the post to like/unlike
  /// [userId] - ID of the user performing the action
  ///
  /// Returns Result<void> with success or error
  Future<Result<void>> execute({
    required String postId,
    required String userId,
  }) async {
    // Validate post ID
    if (postId.trim().isEmpty) {
      return ResultError(
        InvalidInputFailure(message: 'Post ID cannot be empty'),
      );
    }

    // Validate user ID
    if (userId.trim().isEmpty) {
      return ResultError(
        InvalidInputFailure(message: 'User ID cannot be empty'),
      );
    }

    return await repository.toggleLikePost(
      postId: postId,
      userId: userId,
    );
  }
}
