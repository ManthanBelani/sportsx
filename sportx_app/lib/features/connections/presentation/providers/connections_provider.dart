import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class ConnectionUser {
  final String id;
  final String name;
  final String? role;

  ConnectionUser({required this.id, required this.name, this.role});

  factory ConnectionUser.fromJson(Map<String, dynamic> json) {
    return ConnectionUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'User',
      role: json['role'] as String?,
    );
  }
}

class ConnectionRecord {
  final String id;
  final String status;
  final ConnectionUser other;

  ConnectionRecord({required this.id, required this.status, required this.other});
}

ConnectionUser _otherUser(Map<String, dynamic> json, String currentUserId) {
  // The list endpoint includes both follower and followee; pick the one that isn't me.
  final follower = json['follower'] as Map<String, dynamic>?;
  final followee = json['followee'] as Map<String, dynamic>?;
  final followerId = follower?['id']?.toString();
  if (followerId != null && followerId != currentUserId && followee != null) {
    return ConnectionUser.fromJson(follower!);
  }
  return ConnectionUser.fromJson(followee ?? follower ?? {});
}

final myConnectionsProvider =
    FutureProvider.family<List<ConnectionRecord>, String>((ref, currentUserId) async {
  final resp = await ref.watch(dioProvider).get('/me/connections');
  final data = resp.data['data'];
  return (data as List)
      .map((e) {
        final j = e as Map<String, dynamic>;
        return ConnectionRecord(
          id: j['id']?.toString() ?? '',
          status: (j['status'] ?? 'accepted').toString(),
          other: _otherUser(j, currentUserId),
        );
      })
      .toList();
});

final connectionRequestsProvider =
    FutureProvider.family<List<ConnectionRecord>, String>((ref, currentUserId) async {
  final resp = await ref.watch(dioProvider).get('/me/connections/requests');
  final data = resp.data['data'];
  return (data as List)
      .map((e) {
        final j = e as Map<String, dynamic>;
        return ConnectionRecord(
          id: j['id']?.toString() ?? '',
          status: (j['status'] ?? 'pending').toString(),
          other: _otherUser(j, currentUserId),
        );
      })
      .toList();
});

final connectionStatusProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, targetUserId) async {
  final resp = await ref.watch(dioProvider).get('/me/connections/status/$targetUserId');
  return resp.data['data'] as Map<String, dynamic>;
});

final connectionCountProvider = FutureProvider<int>((ref) async {
  final resp = await ref.watch(dioProvider).get('/me/connections/count');
  return resp.data['data']['count'] as int? ?? 0;
});

Future<bool> requestConnection(WidgetRef ref, int userId) async {
  try {
    await ref.read(dioProvider).post('/me/connections/request', data: {'user_id': userId});
    return true;
  } on DioException {
    return false;
  }
}

Future<bool> acceptConnection(WidgetRef ref, String connectionId, String currentUserId) async {
  try {
    await ref.read(dioProvider).post('/me/connections/$connectionId/accept');
    ref.invalidate(connectionRequestsProvider(currentUserId));
    ref.invalidate(myConnectionsProvider(currentUserId));
    return true;
  } on DioException {
    return false;
  }
}

Future<bool> removeConnection(WidgetRef ref, String connectionId, String currentUserId) async {
  try {
    await ref.read(dioProvider).delete('/me/connections/$connectionId');
    ref.invalidate(myConnectionsProvider(currentUserId));
    ref.invalidate(connectionRequestsProvider(currentUserId));
    return true;
  } on DioException {
    return false;
  }
}
