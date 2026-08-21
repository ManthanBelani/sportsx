import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class SavedItem {
  final String id;
  final String type;
  final String itemId;
  final String title;
  final String subtitle;
  final String? meta;
  final String? imageUrl;

  SavedItem({
    required this.id,
    required this.type,
    required this.itemId,
    required this.title,
    required this.subtitle,
    this.meta,
    this.imageUrl,
  });

  factory SavedItem.fromJson(Map<String, dynamic> json) {
    final type = (json['item_type'] as String? ?? json['saveable_type'] as String? ?? json['type'] as String? ?? '').toLowerCase();
    return SavedItem(
      id: json['id']?.toString() ?? '',
      itemId: json['item_id']?.toString() ?? json['saveable_id']?.toString() ?? '',
      type: type,
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

  bool isSaved(String type, String itemId) =>
      items.any((i) => i.type.toLowerCase() == type.toLowerCase() && i.itemId == itemId);
}

class SavedNotifier extends StateNotifier<SavedState> {
  final Dio _dio;

  SavedNotifier(this._dio) : super(SavedState()) {
    load();
  }

  Future<void> load() async {
    if (state.isLoading) return;
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

  /// Toggle save state for an item. Returns true when saved, false when unsaved.
  Future<bool> toggle({required String type, required String itemId}) async {
    final lowerType = type.toLowerCase();
    final parsedItemId = int.tryParse(itemId) ?? 0;
    final existing = state.items.where((i) => i.itemId == itemId && i.type.toLowerCase() == lowerType);
    final isSaved = existing.isNotEmpty;
    try {
      if (isSaved) {
        await _dio.delete('/me/saved', data: {'item_type': lowerType, 'item_id': parsedItemId});
        state = state.copyWith(
          items: state.items.where((i) => !(i.itemId == itemId && i.type.toLowerCase() == lowerType)).toList(),
        );
        return false;
      } else {
        await _dio.post('/me/saved', data: {'item_type': lowerType, 'item_id': parsedItemId});
        await load();
        return true;
      }
    } on DioException catch (e) {
      state = state.copyWith(error: ApiException.fromDio(e).message);
      return isSaved;
    }
  }

  Future<void> remove(SavedItem item) async {
    try {
      final parsedItemId = int.tryParse(item.itemId) ?? 0;
      await _dio.delete('/me/saved', data: {'item_type': item.type.toLowerCase(), 'item_id': parsedItemId});
      state = state.copyWith(items: state.items.where((i) => i.id != item.id).toList());
    } on DioException catch (e) {
      state = state.copyWith(error: ApiException.fromDio(e).message);
    }
  }
}

final savedProvider = StateNotifierProvider<SavedNotifier, SavedState>((ref) {
  return SavedNotifier(ref.watch(dioProvider));
});
