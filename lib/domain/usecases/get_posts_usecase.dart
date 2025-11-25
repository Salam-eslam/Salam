import '../../core/utils/result.dart';
import '../entities/post_entity.dart';
import '../repositories/community_repository_interface.dart';

class GetPostsUseCase {
  final CommunityRepositoryInterface repository;

  GetPostsUseCase(this.repository);

  Future<Result<List<PostEntity>>> call() async {
    return await repository.getPosts();
  }
}
