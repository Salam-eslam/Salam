import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:salam/core/errors/failures.dart';
import 'package:salam/core/utils/result.dart';
import 'package:salam/domain/entities/post_entity.dart';
import 'package:salam/domain/entities/comment_entity.dart';
import 'package:salam/domain/usecases/community/create_post_usecase.dart';
import 'package:salam/domain/usecases/community/get_posts_usecase.dart';
import 'package:salam/domain/usecases/community/toggle_like_post_usecase.dart';
import 'package:salam/domain/usecases/community/create_comment_usecase.dart';
import 'package:salam/domain/usecases/community/get_comments_usecase.dart';
import 'package:salam/presentation/providers/community_provider.dart';

@GenerateMocks([
  GetPostsUseCase,
  CreatePostUseCase,
  ToggleLikePostUseCase,
  CreateCommentUseCase,
  GetCommentsUseCase
])
import 'community_provider_test.mocks.dart';

void main() {
  late CommunityProvider provider;
  late MockGetPostsUseCase mockGetPostsUseCase;
  late MockCreatePostUseCase mockCreatePostUseCase;
  late MockToggleLikePostUseCase mockToggleLikePostUseCase;
  late MockCreateCommentUseCase mockCreateCommentUseCase;
  late MockGetCommentsUseCase mockGetCommentsUseCase;

  setUp(() {
    provideDummy<Result<List<PostEntity>>>(const Success([]));
    provideDummy<Result<PostEntity>>(Success(PostEntity(
      id: 'dummy',
      userId: 'dummy',
      username: 'dummy',
      content: 'dummy',
      createdAt: DateTime.now(),
    )));
    provideDummy<Result<void>>(const Success(null));
    provideDummy<Result<List<CommentEntity>>>(const Success([]));
    provideDummy<Result<CommentEntity>>(Success(CommentEntity(
      id: 'dummy',
      postId: 'dummy',
      userId: 'dummy',
      userName: 'dummy',
      content: 'dummy',
      createdAt: DateTime.now(),
    )));

    mockGetPostsUseCase = MockGetPostsUseCase();
    mockCreatePostUseCase = MockCreatePostUseCase();
    mockToggleLikePostUseCase = MockToggleLikePostUseCase();
    mockCreateCommentUseCase = MockCreateCommentUseCase();
    mockGetCommentsUseCase = MockGetCommentsUseCase();
    provider = CommunityProvider(
      getPostsUseCase: mockGetPostsUseCase,
      createPostUseCase: mockCreatePostUseCase,
      toggleLikePostUseCase: mockToggleLikePostUseCase,
      createCommentUseCase: mockCreateCommentUseCase,
      getCommentsUseCase: mockGetCommentsUseCase,
    );
  });

  group('CommunityProvider', () {
    final tPost = PostEntity(
      id: '1',
      userId: 'user1',
      username: 'User 1',
      content: 'Test Content',
      createdAt: DateTime.now(),
      likesCount: 0,
      commentsCount: 0,
      isLiked: false,
    );
    final tPostList = [tPost];

    test('loadPosts should update posts list on success', () async {
      // Arrange
      when(mockGetPostsUseCase.execute())
          .thenAnswer((_) async => Success(tPostList));

      // Act
      await provider.loadPosts();

      // Assert
      expect(provider.posts, equals(tPostList));
      expect(provider.isLoading, false);
      expect(provider.error, null);
      verify(mockGetPostsUseCase.execute());
    });

    test('loadPosts should set error on failure', () async {
      // Arrange
      when(mockGetPostsUseCase.execute()).thenAnswer((_) async =>
          ResultError(ServerFailure(message: 'Failed to load posts')));

      // Act
      await provider.loadPosts();

      // Assert
      expect(provider.posts, isEmpty);
      expect(provider.isLoading, false);
      expect(provider.error, contains('Failed to load posts'));
      verify(mockGetPostsUseCase.execute());
    });

    test('createPost should add new post to list', () async {
      // Arrange
      when(mockCreatePostUseCase.execute(
        content: anyNamed('content'),
        userId: anyNamed('userId'),
        userName: anyNamed('userName'),
      )).thenAnswer((_) async => Success(tPost));

      // Act
      await provider.createPost('Test Content', 'user1', 'User 1');

      // Assert
      expect(provider.posts, contains(tPost));
      verify(mockCreatePostUseCase.execute(
        content: 'Test Content',
        userId: 'user1',
        userName: 'User 1',
      ));
    });

    test('toggleLikePost should update post like status', () async {
      // Arrange
      provider.posts.add(tPost);
      when(mockToggleLikePostUseCase.execute(
        postId: anyNamed('postId'),
        userId: anyNamed('userId'),
      )).thenAnswer((_) async => Success(null));

      // Act
      await provider.toggleLikePost('1', 'user1');

      // Assert
      verify(mockToggleLikePostUseCase.execute(
        postId: '1',
        userId: 'user1',
      ));
      // Note: Optimistic update changes the state, but since we mocked success, it should stay changed.
      // However, the test setup adds tPost which has isLiked=false.
      // toggleLikePost will flip it to true.
      expect(provider.posts.first.isLiked, true);
    });
  });
}
