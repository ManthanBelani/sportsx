import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class SavedItem {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String? meta;
  final String? imageUrl;

  SavedItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    this.meta,
    this.imageUrl,
  });

  factory SavedItem.fromJson(Map<String, dynamic> json) {
    return SavedItem(
      id: json['id']?.toString() ?? json['saveable_id']?.toString() ?? '',
      type: (json['saveable_type'] as String? ?? json['type'] as String? ?? '').toLowerCase(),
      title: json['title'] as String? ?? json['name'] as String? ?? 'Untitled',
      subtitle: json['subtitle'] as String? ??
          [json['sport']?['name'], json['city']?['name']]
              .whereType<String>()
              .where((s) => s.isNotEmpty)
              .join(' · '),
      meta: json['meta'] as String? ?? json['amount_label'] as String?,
      imageUrl: json['image_url'] as String? ?? json['logo_url'] as String? ?? json['cover_image_url'] as String?,
    );
  }
}

class SavedState {
  final List<SavedItem> items;
  final bool isLoading;
  final String? error;

  SavedState({this.items = const [], this.isLoading = false, this.error});

  SavedState copyWith({List<SavedItem>? items, bool? isLoading, String? error}) {
    return SavedState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class SavedNotifier extends StateNotifier<SavedState> {
  final Dio _dio;

  SavedNotifier(this._dio) : super(SavedState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/me/saved');
      final list = (resp.data['data'] as List? ?? [])
          .map((e) => SavedItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = SavedState(items: list);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  Future<void> toggle({
    required String type,
    required String id,
    Map<String, dynamic>? snapshot,
  }) async {
    final existing = state.items.where((i) => i.id == id && i.type == type);
    final isSaved = existing.isNotEmpty;
    try {
      if (isSaved) {
        await _dio.delete('/me/saved', data: {'saveable_type': type, 'saveable_id': id});
        state = state.copyWith(items: state.items.where((i) => !(i.id == id && i.type == type)).toList());
      } else {
        await _dio.post('/me/saved', data: {
          'saveable_type': type,
          'saveable_id': id,
          if (snapshot != null) ...snapshot,
        });
        await load();
      }
    } on DioException catch (e) {
      state = state.copyWith(error: ApiException.fromDio(e).message);
    }
  }

  Future<void> remove(String savedId) async {
    try {
      await _dio.delete('/me/saved', data: {'id': savedId});
      state = state.copyWith(items: state.items.where((i) => i.id != savedId).toList());
    } on DioException catch (e) {
      state = state.copyWith(error: ApiException.fromDio(e).message);
    }
  }
}

final savedProvider = StateNotifierProvider<SavedNotifier, SavedState>((ref) {
  return SavedNotifier(ref.watch(dioProvider));
});
