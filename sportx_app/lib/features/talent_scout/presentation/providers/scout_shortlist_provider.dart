import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/talent_scout/data/models/scout_shortlist_model.dart';

class ScoutShortlistState {
  final List<ScoutShortlistItem> items;
  final bool isLoading;
  final String? error;

  ScoutShortlistState({this.items = const [], this.isLoading = false, this.error});

  ScoutShortlistState copyWith({List<ScoutShortlistItem>? items, bool? isLoading, String? error}) {
    return ScoutShortlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ScoutShortlistNotifier extends StateNotifier<ScoutShortlistState> {
  final Dio _dio;

  ScoutShortlistNotifier(this._dio) : super(ScoutShortlistState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/me/shortlist');
      final list = (resp.data['data'] as List? ?? [])
          .map((e) => ScoutShortlistItem.fromJson(e as Map<String, dynamic>))
          .toList();
      state = ScoutShortlistState(items: list);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  Future<bool> addToShortlist(String athleteId, {String? notes}) async {
    try {
      await _dio.post('/me/shortlist/$athleteId', data: {'notes': notes});
      await load();
      return true;
    } on DioException catch (e) {
      if (e.response?.statusCode == 409) {
        state = state.copyWith(error: 'Already shortlisted');
      } else {
        state = state.copyWith(error: ApiException.fromDio(e).message);
      }
      return false;
    }
  }

  Future<bool> removeFromShortlist(String athleteId) async {
    try {
      await _dio.delete('/me/shortlist/$athleteId');
      state = state.copyWith(
        items: state.items.where((e) => e.athlete.id != athleteId).toList(),
      );
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> updateNotes(String athleteId, String notes) async {
    try {
      await _dio.patch('/me/shortlist/$athleteId', data: {'notes': notes});
      await load();
      return true;
    } on DioException {
      return false;
    }
  }
}

final scoutShortlistProvider = StateNotifierProvider<ScoutShortlistNotifier, ScoutShortlistState>((ref) {
  return ScoutShortlistNotifier(ref.watch(dioProvider));
});
