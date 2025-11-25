import '../../entities/post_entity.dart';
import '../../repositories/community_repository_interface.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';

/// Use case for fetching community posts feed
///
/// Implements business logic for retrieving paginated posts from the community.
/// Validates pagination parameters and delegates to repository.
class GetPostsUseCase {
  final CommunityRepositoryInterface repository;

  GetPostsUseCase(this.repository);

  /// Execute the use case
  ///
  /// [limit] - Number of posts to fetch (1-50, default: 20)
  /// [lastPostId] - ID for pagination (optional)
  ///
  /// Returns Result<List<PostEntity>> with posts or error
  Future<Result<List<PostEntity>>> execute({
    int limit = 20,
    String? lastPostId,
  }) async {
    // Validate limit
    if (limit < 1 || limit > 50) {
      return ResultError(
        InvalidInputFailure(
          message: 'Limit must be between 1 and 50',
        ),
      );
    }

    return await repository.getPosts(
      limit: limit,
      lastPostId: lastPostId,
    );
  }
}
