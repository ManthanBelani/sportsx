import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class SocialPost {
  final String id;
  final String authorName;
  final String? authorAvatar;
  final String? body;
  final String? imageUrl;
  final String? createdAt;
  final int likesCount;
  final int commentsCount;
  final bool liked;

  SocialPost({
    required this.id,
    required this.authorName,
    this.authorAvatar,
    this.body,
    this.imageUrl,
    this.createdAt,
    this.likesCount = 0,
    this.commentsCount = 0,
    this.liked = false,
  });

  factory SocialPost.fromJson(Map<String, dynamic> json) {
    final user = json['user'] as Map<String, dynamic>?;
    return SocialPost(
      id: json['id']?.toString() ?? '',
      authorName: (user?['name'] ?? 'User').toString(),
      authorAvatar: user?['profile_photo_url'] as String?,
      body: json['body'] as String?,
      imageUrl: json['image_url'] as String?,
      createdAt: json['created_at'] as String?,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      liked: json['liked'] == true,
    );
  }
}

final postsFeedProvider = FutureProvider<List<SocialPost>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/posts');
  final data = resp.data['data'];
  return (data as List).map((e) => SocialPost.fromJson(e as Map<String, dynamic>)).toList();
});

/// Feed for one tab of the feed switcher.
///
/// `filter` is either empty (For You), `following` (posts by people the
/// viewer follows) or `role:<role>` (posts authored by that role — this is
/// what makes the feed role-aware: a coach sees coaching posts, an
/// organizer sees event announcements).
final filteredPostsFeedProvider = FutureProvider.family<List<SocialPost>, String>((ref, filter) async {
  final query = <String, dynamic>{};
  if (filter == 'following') {
    query['following'] = 1;
  } else if (filter.startsWith('role:')) {
    query['author_role'] = filter.substring('role:'.length);
  }

  final resp = await ref.watch(dioProvider).get(
    '/posts',
    queryParameters: query.isEmpty ? null : query,
  );
  final data = resp.data['data'];
  return (data as List).map((e) => SocialPost.fromJson(e as Map<String, dynamic>)).toList();
});

final postDetailProvider = FutureProvider.family<SocialPost, String>((ref, id) async {
  final resp = await ref.watch(dioProvider).get('/posts/$id');
  final body = resp.data['data'] as Map<String, dynamic>;
  return SocialPost.fromJson(body);
});

Future<bool> togglePostLike(WidgetRef ref, String postId) async {
  try {
    await ref.read(dioProvider).post('/posts/$postId/like');
    ref.invalidate(postDetailProvider(postId));
    ref.invalidate(postsFeedProvider);
    return true;
  } on DioException {
    return false;
  }
}

Future<bool> unlikePost(WidgetRef ref, String postId) async {
  try {
    await ref.read(dioProvider).delete('/posts/$postId/like');
    ref.invalidate(postDetailProvider(postId));
    ref.invalidate(postsFeedProvider);
    return true;
  } on DioException {
    return false;
  }
}

Future<bool> updatePost(WidgetRef ref, String postId, String body) async {
  try {
    await ref.read(dioProvider).patch('/posts/$postId', data: {'body': body});
    ref.invalidate(postDetailProvider(postId));
    ref.invalidate(postsFeedProvider);
    return true;
  } on DioException {
    return false;
  }
}

Future<bool> deletePost(WidgetRef ref, String postId) async {
  try {
    await ref.read(dioProvider).delete('/posts/$postId');
    ref.invalidate(postDetailProvider(postId));
    ref.invalidate(postsFeedProvider);
    return true;
  } on DioException {
    return false;
  }
}

final postCommentsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, postId) async {
  final resp = await ref.watch(dioProvider).get('/posts/$postId/comments');
  final body = resp.data;
  final list = body is Map && body['data'] is List ? body['data'] as List : (body is List ? body : []);
  return list.cast<Map<String, dynamic>>();
});

Future<bool> deleteComment(WidgetRef ref, String postId, String commentId) async {
  try {
    await ref.read(dioProvider).delete('/comments/$commentId');
    ref.invalidate(postDetailProvider(postId));
    ref.invalidate(postCommentsProvider(postId));
    return true;
  } on DioException {
    return false;
  }
}

Future<bool> commentOnPost(WidgetRef ref, String postId, String body, {String? parentId}) async {
  try {
    await ref.read(dioProvider).post('/posts/$postId/comments', data: {'body': body, if (parentId != null) 'parent_id': int.tryParse(parentId) ?? parentId});
    ref.invalidate(postDetailProvider(postId));
    ref.invalidate(postCommentsProvider(postId));
    return true;
  } on DioException {
    return false;
  }
}
