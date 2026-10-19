import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class Group {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final int memberCount;
  final bool isMember;
  final String type; // 'coaching', 'athletes', 'trials', 'general'

  Group({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.memberCount,
    required this.isMember,
    required this.type,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      isMember: json['is_member'] == true,
      type: json['type'] as String? ?? 'general',
    );
  }
}

final groupsProvider = FutureProvider<List<Group>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/groups', queryParameters: {'type': 'popular', 'limit': 20});
  final data = resp.data['data'] as List? ?? [];
  return data.map((e) => Group.fromJson(e as Map<String, dynamic>)).toList();
});

final myGroupsProvider = FutureProvider<List<Group>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/me/groups');
  final data = resp.data['data'] as List? ?? [];
  return data.map((e) => Group.fromJson(e as Map<String, dynamic>)).toList();
});

Future<bool> joinGroup(WidgetRef ref, String groupId) async {
  try {
    await ref.read(dioProvider).post('/groups/$groupId/join');
    ref.invalidate(groupsProvider);
    ref.invalidate(myGroupsProvider);
    return true;
  } on DioException {
    return false;
  }
}

Future<bool> leaveGroup(WidgetRef ref, String groupId) async {
  try {
    await ref.read(dioProvider).delete('/groups/$groupId/leave');
    ref.invalidate(groupsProvider);
    ref.invalidate(myGroupsProvider);
    return true;
  } on DioException {
    return false;
  }
}