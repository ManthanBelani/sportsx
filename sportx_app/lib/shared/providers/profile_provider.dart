import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

final profileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final dio = ref.watch(dioProvider);
  try {
    final response = await dio.get('/me/profile');
    return response.data['data'] as Map<String, dynamic>?;
  } catch (e) {
    return null;
  }
});
