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
      error: error,
    );
  }
}

class ScoutShortlistNotifier extends StateNotifier<ScoutShortlistState> {
  final Dio _dio;

  ScoutShortlistNotifier(this._dio) : super(ScoutShortlistState()) {
    load();
  }

  Future<void> load({String status = 'all'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/me/scout-shortlist', queryParameters: status == 'all' ? null : {'status': status});
      if (!mounted) {
        return;
      }
      final list = (resp.data['data'] as List? ?? [])
          .map((e) => ScoutShortlistItem.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        state = ScoutShortlistState(items: list);
      }
    } on DioException catch (e) {
      if (mounted) {
        state = ScoutShortlistState(items: state.items, isLoading: false, error: ApiException.fromDio(e).message);
      }
    } catch (_) {
      if (mounted) {
        state = ScoutShortlistState(items: state.items, isLoading: false, error: 'Something went wrong. Please try again.');
      }
    }
  }

  Future<bool> addToShortlist(String athleteId, {String? notes}) async {
    try {
      await _dio.post('/me/scout-shortlist/$athleteId', data: {'notes': notes});
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
    final previous = List<ScoutShortlistItem>.from(state.items);
    if (mounted) {
      state = state.copyWith(items: state.items.where((e) => e.athlete.id != athleteId).toList());
    }
    try {
      await _dio.delete('/me/scout-shortlist/$athleteId');
      if (!mounted) {
        return false;
      }
      return true;
    } on DioException catch (e) {
      if (mounted) {
        state = ScoutShortlistState(items: previous, isLoading: false, error: ApiException.fromDio(e).message);
      }
      return false;
    } catch (_) {
      if (mounted) {
        state = ScoutShortlistState(items: previous, isLoading: false, error: 'Something went wrong. Please try again.');
      }
      return false;
    }
  }

  Future<bool> updateNotes(String athleteId, String notes) async {
    try {
      await _dio.patch('/me/scout-shortlist/$athleteId', data: {'notes': notes});
      await load();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: ApiException.fromDio(e).message);
      return false;
    }
  }

  /// Phase 7 pipeline: status (under_review/good/high/final) + tags + notes.
  Future<bool> updateEntry(String athleteId, {String? status, List<String>? tags, String? notes}) async {
    try {
      await _dio.patch('/me/scout-shortlist/$athleteId', data: {
        if (status != null) 'status': status,
        if (tags != null) 'tags': tags,
        if (notes != null) 'notes': notes,
      });
      await load();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: ApiException.fromDio(e).message);
      return false;
    }
  }
}

final scoutShortlistProvider = StateNotifierProvider<ScoutShortlistNotifier, ScoutShortlistState>((ref) {
  return ScoutShortlistNotifier(ref.watch(dioProvider));
});
