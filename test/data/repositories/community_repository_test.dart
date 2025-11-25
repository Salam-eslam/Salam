import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:salam/core/utils/result.dart';
import 'package:salam/data/datasources/community_remote_datasource.dart';
import 'package:salam/data/repositories/community_repository.dart';
import 'package:salam/domain/entities/post_entity.dart';
import 'package:salam/data/models/post_model.dart';

@GenerateMocks([CommunityRemoteDataSource])
import 'community_repository_test.mocks.dart';

void main() {
  late CommunityRepository repository;
  late MockCommunityRemoteDataSource mockRemoteDataSource;

  setUp(() {
    mockRemoteDataSource = MockCommunityRemoteDataSource();
    repository = CommunityRepository(remoteDataSource: mockRemoteDataSource);
  });

  group('CommunityRepository', () {
    final tPostModel = PostModel(
      id: '1',
      userId: 'user1',
      username: 'User 1',
      content: 'Test Content',
      createdAt: DateTime.now(),
      likesCount: 0,
      commentsCount: 0,
      isLiked: false,
    );
    final List<PostModel> tPostModelList = [tPostModel];
    final List<PostEntity> tPostEntityList = tPostModelList;

    test('getPosts should return list of posts from remote data source',
        () async {
      // Arrange
      when(mockRemoteDataSource.getPosts())
          .thenAnswer((_) async => tPostModelList);

      // Act
      final result = await repository.getPosts();

      // Assert
      verify(mockRemoteDataSource.getPosts());
      expect(result, isA<Success<List<PostEntity>>>());
      expect(
          (result as Success<List<PostEntity>>).data, equals(tPostEntityList));
    });

    test('createPost should return created post from remote data source',
        () async {
      // Arrange
      when(mockRemoteDataSource.createPost(
        content: anyNamed('content'),
        userId: anyNamed('userId'),
        userName: anyNamed('userName'),
      )).thenAnswer((_) async => tPostModel);

      // Act
      final result = await repository.createPost(
        content: 'Test Content',
        userId: 'user1',
        username: 'User 1',
      );

      // Assert
      verify(mockRemoteDataSource.createPost(
        content: 'Test Content',
        userId: 'user1',
        userName: 'User 1',
      ));
      expect(result, isA<Success<PostEntity>>());
      expect((result as Success<PostEntity>).data, equals(tPostModel));
    });

    test('toggleLikePost should call toggleLikePost on remote data source',
        () async {
      // Arrange
      when(mockRemoteDataSource.toggleLikePost(
        postId: anyNamed('postId'),
        userId: anyNamed('userId'),
      )).thenAnswer(
          (_) async => tPostModel); // toggleLikePost returns PostModel now

      // Act
      final result =
          await repository.toggleLikePost(postId: '1', userId: 'user1');

      // Assert
      verify(mockRemoteDataSource.toggleLikePost(postId: '1', userId: 'user1'));
      expect(result, isA<Success<void>>());
    });
  });
}
