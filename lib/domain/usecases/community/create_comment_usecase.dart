import '../../entities/comment_entity.dart';
import '../../repositories/community_repository_interface.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';

/// Use case for creating a comment on a post
class CreateCommentUseCase {
  final CommunityRepositoryInterface repository;

  CreateCommentUseCase(this.repository);

  /// Execute the use case
  ///
  /// Creates a new comment with validation.
  ///
  /// Returns Result<CommentEntity> with created comment or error
  Future<Result<CommentEntity>> execute({
    required String postId,
    required String userId,
    required String userName,
    required String content,
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

    // Validate user name
    if (userName.trim().isEmpty) {
      return ResultError(
        InvalidInputFailure(message: 'User name cannot be empty'),
      );
    }

    // Validate content
    final trimmedContent = content.trim();
    if (trimmedContent.isEmpty) {
      return ResultError(
        InvalidInputFailure(message: 'Comment content cannot be empty'),
      );
    }

    if (trimmedContent.length > 1000) {
      return ResultError(
        InvalidInputFailure(
          message: 'Comment content cannot exceed 1000 characters',
        ),
      );
    }

    return await repository.createComment(
      postId: postId,
      userId: userId,
      userName: userName,
      content: trimmedContent,
    );
  }
}
