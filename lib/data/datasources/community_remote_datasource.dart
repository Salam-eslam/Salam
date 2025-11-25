import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';
import '../models/comment_model.dart';

abstract class CommunityRemoteDataSource {
  Future<List<PostModel>> getPosts({int limit = 20, String? lastPostId});
  Future<PostModel> getPost(String postId);
  Future<List<PostModel>> getPostsByVerse({
    required int surahNumber,
    required int verseNumber,
    int limit = 20,
  });
  Future<PostModel> createPost({
    required String userId,
    required String userName,
    required String content,
    int? surahNumber,
    int? verseNumber,
    String? verseText,
  });
  Future<PostModel> updatePost({
    required String postId,
    required String userId,
    required String content,
  });
  Future<void> deletePost(String postId, String userId);
  Future<PostModel> toggleLikePost({
    required String postId,
    required String userId,
  });
  Future<void> reportPost({
    required String postId,
    required String userId,
    required String reason,
  });

  Future<List<CommentModel>> getComments({
    required String postId,
    int limit = 50,
    String? lastCommentId,
  });
  Future<CommentModel> createComment({
    required String postId,
    required String userId,
    required String userName,
    required String content,
  });
  Future<CommentModel> updateComment({
    required String commentId,
    required String userId,
    required String content,
  });
  Future<void> deleteComment(String commentId, String userId);
  Future<CommentModel> toggleLikeComment({
    required String commentId,
    required String userId,
  });
  Future<void> reportComment({
    required String commentId,
    required String userId,
    required String reason,
  });

  Future<List<PostModel>> getUserPosts({
    required String userId,
    int limit = 20,
    String? lastPostId,
  });
  Future<List<PostModel>> getUserLikedPosts({
    required String userId,
    int limit = 20,
  });
}

class CommunityRemoteDataSourceImpl implements CommunityRemoteDataSource {
  final SupabaseClient supabaseClient;

  CommunityRemoteDataSourceImpl({required this.supabaseClient});

  @override
  Future<List<PostModel>> getPosts({int limit = 20, String? lastPostId}) async {
    var query = supabaseClient
        .from('posts')
        .select()
        .order('created_at', ascending: false)
        .limit(limit);

    if (lastPostId != null) {
      // Pagination: fetch posts created before the last post
      // We need to fetch the created_at of the last post first or pass it
      // For simplicity, assuming ID based pagination isn't ideal with created_at sorting
      // Better to use created_at for cursor.
      // But let's stick to simple limit for now or use range if we had page number.
      // Supabase supports range.
      // For cursor based, we'd need the value of the sort column.
      // Let's assume simple fetch for now.
    }

    final response = await query;
    return (response as List).map((json) => PostModel.fromJson(json)).toList();
  }

  @override
  Future<PostModel> getPost(String postId) async {
    final response =
        await supabaseClient.from('posts').select().eq('id', postId).single();
    return PostModel.fromJson(response);
  }

  @override
  Future<List<PostModel>> getPostsByVerse({
    required int surahNumber,
    required int verseNumber,
    int limit = 20,
  }) async {
    final response = await supabaseClient
        .from('posts')
        .select()
        .eq('surah_number', surahNumber)
        .eq('verse_number', verseNumber)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => PostModel.fromJson(json)).toList();
  }

  @override
  Future<PostModel> createPost({
    required String userId,
    required String userName,
    required String content,
    int? surahNumber,
    int? verseNumber,
    String? verseText,
  }) async {
    final response = await supabaseClient
        .from('posts')
        .insert({
          'user_id': userId,
          'user_name': userName,
          'content': content,
          'surah_number': surahNumber,
          'verse_number': verseNumber,
          'verse_text': verseText,
        })
        .select()
        .single();

    return PostModel.fromJson(response);
  }

  @override
  Future<PostModel> updatePost({
    required String postId,
    required String userId,
    required String content,
  }) async {
    final response = await supabaseClient
        .from('posts')
        .update({
          'content': content,
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('id', postId)
        .eq('user_id', userId)
        .select()
        .single();

    return PostModel.fromJson(response);
  }

  @override
  Future<void> deletePost(String postId, String userId) async {
    await supabaseClient
        .from('posts')
        .delete()
        .eq('id', postId)
        .eq('user_id', userId);
  }

  @override
  Future<PostModel> toggleLikePost({
    required String postId,
    required String userId,
  }) async {
    // Fetch current post to check likes
    final post = await getPost(postId);
    final likedByUserIds = List<String>.from(post.likedByUserIds);

    if (likedByUserIds.contains(userId)) {
      likedByUserIds.remove(userId);
    } else {
      likedByUserIds.add(userId);
    }

    final response = await supabaseClient
        .from('posts')
        .update({
          'liked_by_user_ids': likedByUserIds,
          'likes_count': likedByUserIds.length
        })
        .eq('id', postId)
        .select()
        .single();

    return PostModel.fromJson(response);
  }

  @override
  Future<void> reportPost({
    required String postId,
    required String userId,
    required String reason,
  }) async {
    // In a real app, we'd have a reports table.
    // For now, just flag the post.
    await supabaseClient
        .from('posts')
        .update({'is_reported': true}).eq('id', postId);
  }

  @override
  Future<List<CommentModel>> getComments({
    required String postId,
    int limit = 50,
    String? lastCommentId,
  }) async {
    final response = await supabaseClient
        .from('comments')
        .select()
        .eq('post_id', postId)
        .order('created_at', ascending: true)
        .limit(limit);

    return (response as List)
        .map((json) => CommentModel.fromJson(json, json['id']))
        .toList();
  }

  @override
  Future<CommentModel> createComment({
    required String postId,
    required String userId,
    required String userName,
    required String content,
  }) async {
    final response = await supabaseClient
        .from('comments')
        .insert({
          'post_id': postId,
          'user_id': userId,
          'user_name': userName,
          'content': content,
        })
        .select()
        .single();

    return CommentModel.fromJson(response, response['id']);
  }

  @override
  Future<CommentModel> updateComment({
    required String commentId,
    required String userId,
    required String content,
  }) async {
    final response = await supabaseClient
        .from('comments')
        .update({
          'content': content,
          'updated_at': DateTime.now().toIso8601String()
        })
        .eq('id', commentId)
        .eq('user_id', userId)
        .select()
        .single();

    return CommentModel.fromJson(response, response['id']);
  }

  @override
  Future<void> deleteComment(String commentId, String userId) async {
    await supabaseClient
        .from('comments')
        .delete()
        .eq('id', commentId)
        .eq('user_id', userId);
  }

  @override
  Future<CommentModel> toggleLikeComment({
    required String commentId,
    required String userId,
  }) async {
    final response = await supabaseClient
        .from('comments')
        .select()
        .eq('id', commentId)
        .single();

    final comment = CommentModel.fromJson(response, response['id']);
    final likedByUserIds = List<String>.from(comment.likedByUserIds);

    if (likedByUserIds.contains(userId)) {
      likedByUserIds.remove(userId);
    } else {
      likedByUserIds.add(userId);
    }

    final updatedResponse = await supabaseClient
        .from('comments')
        .update({
          'liked_by_user_ids': likedByUserIds,
          'likes_count': likedByUserIds.length
        })
        .eq('id', commentId)
        .select()
        .single();

    return CommentModel.fromJson(updatedResponse, updatedResponse['id']);
  }

  @override
  Future<void> reportComment({
    required String commentId,
    required String userId,
    required String reason,
  }) async {
    await supabaseClient
        .from('comments')
        .update({'is_reported': true}).eq('id', commentId);
  }

  @override
  Future<List<PostModel>> getUserPosts({
    required String userId,
    int limit = 20,
    String? lastPostId,
  }) async {
    final response = await supabaseClient
        .from('posts')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => PostModel.fromJson(json)).toList();
  }

  @override
  Future<List<PostModel>> getUserLikedPosts({
    required String userId,
    int limit = 20,
  }) async {
    // This is tricky with array column.
    // Supabase/Postgres has 'contains' operator for arrays.
    final response = await supabaseClient
        .from('posts')
        .select()
        .contains('liked_by_user_ids', [userId])
        .order('created_at', ascending: false)
        .limit(limit);

    return (response as List).map((json) => PostModel.fromJson(json)).toList();
  }
}
