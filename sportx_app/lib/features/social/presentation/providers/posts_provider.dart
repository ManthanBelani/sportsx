import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class SocialPost {
  final String id;
  final String authorName;
  final String? authorAvatar;
  final String? body;
  final String? imageUrl;
  final List<String> images;
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
    this.images = const [],
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
      images: (json['images'] as List? ?? [])
          .map((e) => e.toString())
          .where((e) => e.isNotEmpty)
          .toList(),
      createdAt: json['created_at'] as String?,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      liked: json['liked'] == true,
    );
  }

  SocialPost copyWith({int? likesCount, bool? liked}) => SocialPost(
        id: id,
        authorName: authorName,
        authorAvatar: authorAvatar,
        body: body,
        imageUrl: imageUrl,
        images: images,
        createdAt: createdAt,
        likesCount: likesCount ?? this.likesCount,
        commentsCount: commentsCount,
        liked: liked ?? this.liked,
      );
}

/// Paginated feed state — page size 15 comes from the API; the notifier keeps
/// appending pages on load-more so users can actually scroll past post 15.
class PostsFeedState {
  final List<SocialPost> posts;
  final bool hasMore;
  final bool loadingMore;
  final bool loading;
  final String? error;

  const PostsFeedState({
    this.posts = const [],
    this.hasMore = false,
    this.loadingMore = false,
    this.loading = true,
    this.error,
  });

  PostsFeedState copyWith({
    List<SocialPost>? posts,
    bool? hasMore,
    bool? loadingMore,
    bool? loading,
    String? error,
  }) =>
      PostsFeedState(
        posts: posts ?? this.posts,
        hasMore: hasMore ?? this.hasMore,
        loadingMore: loadingMore ?? this.loadingMore,
        loading: loading ?? this.loading,
        error: error,
      );
}

Map<String, dynamic> _feedQuery(String filter) {
  if (filter == 'following') return {'following': 1};
  if (filter.startsWith('role:')) return {'author_role': filter.substring(5)};
  return {};
}

Future<(List<SocialPost>, bool hasMore)> _fetchPostsPage(Ref ref, String filter, int page) async {
  final resp = await ref.read(dioProvider).get(
        '/posts',
        queryParameters: {'page': page, ..._feedQuery(filter)},
      );
  final data = resp.data['data'];
  final posts = (data as List).map((e) => SocialPost.fromJson(e as Map<String, dynamic>)).toList();
  final lastPage = resp.data['meta']?['pagination']?['last_page'] ??
      resp.data['last_page'] ??
      1;
  return (posts, page < (lastPage is int ? lastPage : int.tryParse('$lastPage') ?? 1));
}

class PostsFeedNotifier extends FamilyNotifier<PostsFeedState, String> {
  @override
  PostsFeedState build(String arg) {
    _refresh();
    return const PostsFeedState();
  }

  Future<void> _refresh() async {
    try {
      final (posts, hasMore) = await _fetchPostsPage(ref, arg, 1);
      if (!ref.exists(paginatedPostsProvider(arg))) return;
      state = PostsFeedState(posts: posts, hasMore: hasMore, loading: false);
    } on DioException catch (e) {
      if (!ref.exists(paginatedPostsProvider(arg))) return;
      state = PostsFeedState(loading: false, error: ApiException.messageFor(e));
    } catch (e) {
      if (!ref.exists(paginatedPostsProvider(arg))) return;
      state = PostsFeedState(loading: false, error: e.toString());
    }
  }

  Future<void> refresh() => _refresh();

  Future<void> loadMore() async {
    if (state.loadingMore || !state.hasMore || state.loading) return;
    state = state.copyWith(loadingMore: true);
    try {
      final nextPage = (state.posts.length / 15).floor() + 1;
      final (posts, hasMore) = await _fetchPostsPage(ref, arg, nextPage);
      final existingIds = state.posts.map((p) => p.id).toSet();
      state = state.copyWith(
        posts: [...state.posts, ...posts.where((p) => !existingIds.contains(p.id))],
        hasMore: hasMore,
        loadingMore: false,
      );
    } on DioException {
      state = state.copyWith(loadingMore: false, error: 'network');
    } catch (_) {
      state = state.copyWith(loadingMore: false, error: 'error');
    }
  }

  /// In-place like toggle so a heart tap doesn't reload the whole feed.
  void applyLike(String postId, {required bool liked}) {
    state = state.copyWith(
      posts: state.posts
          .map((p) => p.id == postId
              ? p.copyWith(liked: liked, likesCount: p.likesCount + (liked ? 1 : -1))
              : p)
          .toList(),
    );
  }

  void overrideLikeCount(String postId, int count) {
    state = state.copyWith(
      posts: state.posts
          .map((p) => p.id == postId ? p.copyWith(likesCount: count, liked: count > 0 && p.liked) : p)
          .toList(),
    );
  }
}

final paginatedPostsProvider =
    NotifierProvider.family<PostsFeedNotifier, PostsFeedState, String>(
  PostsFeedNotifier.new,
);

// ── Back-compat readers (page-1 views over the paginated provider) ──────────

final postsFeedProvider = FutureProvider<List<SocialPost>>((ref) async {
  return ref.watch(paginatedPostsProvider('')).posts;
});

/// Feed for one tab of the feed switcher (see [paginatedPostsProvider]).
///
/// `filter` is either empty (For You), `following` (posts by people the
/// viewer follows) or `role:<role>` (posts authored by that role — this is
/// what makes the feed role-aware: a coach sees coaching posts, an
/// organizer sees event announcements).
final filteredPostsFeedProvider = FutureProvider.family<List<SocialPost>, String>((ref, filter) async {
  return ref.watch(paginatedPostsProvider(filter)).posts;
});

final postDetailProvider = FutureProvider.family<SocialPost, String>((ref, id) async {
  final resp = await ref.watch(dioProvider).get('/posts/$id');
  final body = resp.data['data'] as Map<String, dynamic>;
  return SocialPost.fromJson(body);
});

Future<bool> togglePostLike(WidgetRef ref, String postId) async {
  try {
    final resp = await ref.read(dioProvider).post('/posts/$postId/like');
    // Update feed pages in place — a full invalidate used to reload and
    // scroll-jump the whole feed on every heart tap.
    final liked = resp.data['data']?['liked'] == true;
    final count = (resp.data['data']?['likes_count'] as num?)?.toInt();
    try {
      ref.read(paginatedPostsProvider('').notifier).applyLike(postId, liked: liked);
    } catch (_) {}
    for (final f in ['following']) {
      try {
        ref.read(paginatedPostsProvider(f).notifier).applyLike(postId, liked: liked);
      } catch (_) {}
    }
    if (count != null) {
      // Keep the authoritative count from the server.
      _overrideCount(ref, postId, count);
    }
    ref.invalidate(postDetailProvider(postId));
    return true;
  } on DioException {
    return false;
  }
}

void _overrideCount(WidgetRef ref, String postId, int count) {
  for (final f in ['', 'following']) {
    try {
      ref.read(paginatedPostsProvider(f).notifier).overrideLikeCount(postId, count);
    } catch (_) {}
  }
}

Future<bool> unlikePost(WidgetRef ref, String postId) async {
  try {
    final resp = await ref.read(dioProvider).delete('/posts/$postId/like');
    final liked = resp.data['data']?['liked'] == true;
    final count = (resp.data['data']?['likes_count'] as num?)?.toInt();
    for (final f in ['', 'following']) {
      try {
        ref.read(paginatedPostsProvider(f).notifier).applyLike(postId, liked: liked);
      } catch (_) {}
    }
    if (count != null) _overrideCount(ref, postId, count);
    ref.invalidate(postDetailProvider(postId));
    return true;
  } on DioException {
    return false;
  }
}

Future<bool> updatePost(WidgetRef ref, String postId, String body) async {
  try {
    await ref.read(dioProvider).patch('/posts/$postId', data: {'body': body});
    ref.invalidate(postDetailProvider(postId));
    await ref.read(paginatedPostsProvider('').notifier).refresh();
    return true;
  } on DioException {
    return false;
  }
}

Future<bool> deletePost(WidgetRef ref, String postId) async {
  try {
    await ref.read(dioProvider).delete('/posts/$postId');
    ref.invalidate(postDetailProvider(postId));
    await ref.read(paginatedPostsProvider('').notifier).refresh();
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
