import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

/// Phase 6: one-way follows (v3 S.19) + safety blocks (v3 S.23).
/// Backend: POST/DELETE /follow/{type}/{id}, GET /me/followers|following,
/// GET/POST/DELETE /blocks. All v3 yellow-theme surfaces consume these.

final followingProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/me/following');
  final body = resp.data;
  final list = body is Map && body['data'] is List ? body['data'] as List : (body is List ? body : []);
  return list.cast<Map<String, dynamic>>();
});

final followersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/me/followers');
  final body = resp.data;
  final list = body is Map && body['data'] is List ? body['data'] as List : (body is List ? body : []);
  return list.cast<Map<String, dynamic>>();
});

final blockedUsersProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/blocks');
  final body = resp.data;
  final list = body is Map && body['data'] is List ? body['data'] as List : (body is List ? body : []);
  return list.cast<Map<String, dynamic>>();
});

final myReportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/me/reports');
  final body = resp.data;
  final list = body is Map && body['data'] is List ? body['data'] as List : (body is List ? body : []);
  return list.cast<Map<String, dynamic>>();
});

Future<bool> followProfile(WidgetRef ref, String type, String id) async {
  try {
    await ref.read(dioProvider).post('/follow/$type/$id');
    ref.invalidate(followingProvider);
    return true;
  } on DioException {
    return false;
  }
}

Future<bool> unfollowProfile(WidgetRef ref, String type, String id) async {
  try {
    await ref.read(dioProvider).delete('/follow/$type/$id');
    ref.invalidate(followingProvider);
    return true;
  } on DioException {
    return false;
  }
}

Future<bool> blockUser(WidgetRef ref, String userId) async {
  try {
    await ref.read(dioProvider).post('/blocks', data: {'user_id': int.parse(userId)});
    ref.invalidate(blockedUsersProvider);
    ref.invalidate(followingProvider);
    ref.invalidate(followersProvider);
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> unblockUser(WidgetRef ref, String userId) async {
  try {
    await ref.read(dioProvider).delete('/blocks/$userId');
    ref.invalidate(blockedUsersProvider);
    return true;
  } on DioException {
    return false;
  }
}
