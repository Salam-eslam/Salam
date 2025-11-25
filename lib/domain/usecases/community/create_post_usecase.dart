import '../../entities/post_entity.dart';
import '../../repositories/community_repository_interface.dart';
import '../../../core/errors/failures.dart';
import '../../../core/utils/result.dart';

/// Use case for creating a community post
///
/// Implements business logic for post creation with validation.
class CreatePostUseCase {
  final CommunityRepositoryInterface repository;

  CreatePostUseCase(this.repository);

  /// Execute the use case
  ///
  /// Validates input and creates a new post in the community.
  ///
  /// Returns Result<PostEntity> with created post or error
  Future<Result<PostEntity>> execute({
    required String userId,
    required String userName,
    required String content,
    int? surahNumber,
    int? verseNumber,
    String? verseText,
  }) async {
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
        InvalidInputFailure(message: 'Post content cannot be empty'),
      );
    }

    if (trimmedContent.length > 2000) {
      return ResultError(
        InvalidInputFailure(
          message: 'Post content cannot exceed 2000 characters',
        ),
      );
    }

    // Validate surah number if provided
    if (surahNumber != null && (surahNumber < 1 || surahNumber > 114)) {
      return ResultError(
        InvalidInputFailure(
          message: 'Surah number must be between 1 and 114',
        ),
      );
    }

    // Validate verse number if provided
    if (verseNumber != null && verseNumber < 1) {
      return ResultError(
        InvalidInputFailure(message: 'Verse number must be positive'),
      );
    }

    // If verse is referenced, both surah and verse numbers must be provided
    if ((surahNumber != null && verseNumber == null) ||
        (surahNumber == null && verseNumber != null)) {
      return ResultError(
        InvalidInputFailure(
          message: 'Both surah and verse numbers must be provided together',
        ),
      );
    }

    return await repository.createPost(
      userId: userId,
      username: userName,
      content: trimmedContent,
      surahNumber: surahNumber,
      verseNumber: verseNumber,
      verseText: verseText,
    );
  }
}
