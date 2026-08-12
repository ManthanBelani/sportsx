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

Future<bool> commentOnPost(WidgetRef ref, String postId, String body) async {
  try {
    await ref.read(dioProvider).post('/posts/$postId/comments', data: {'body': body});
    ref.invalidate(postDetailProvider(postId));
    return true;
  } on DioException {
    return false;
  }
}
