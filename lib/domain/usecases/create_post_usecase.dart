import '../../core/utils/result.dart';
import '../entities/post_entity.dart';
import '../repositories/community_repository_interface.dart';

class CreatePostUseCase {
  final CommunityRepositoryInterface repository;

  CreatePostUseCase(this.repository);

  Future<Result<PostEntity>> call(
      String content, String userId, String username) async {
    return await repository.createPost(
      content: content,
      userId: userId,
      username: username,
    );
  }
}
