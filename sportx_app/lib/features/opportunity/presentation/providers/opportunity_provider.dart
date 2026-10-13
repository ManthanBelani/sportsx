import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';

/// Paginated opportunity directory (Phase 4): GET /opportunities with
/// type/sport/age/deadline filters.
final opportunitiesProvider =
    StateNotifierProvider<DirectoryNotifier<Opportunity>, DirectoryState<Opportunity>>((ref) {
  return DirectoryNotifier<Opportunity>(ref.watch(dioProvider), '/opportunities', Opportunity.fromJson);
});

final opportunityDetailProvider = FutureProvider.family<Opportunity, String>((ref, id) async {
  final resp = await ref.watch(dioProvider).get('/opportunities/$id');
  return Opportunity.fromJson(resp.data['data'] as Map<String, dynamic>);
});

class MyOpportunitiesState {
  final List<OpportunityApplication> applied;
  final List<Opportunity> created;
  final bool isLoading;
  final String? error;

  MyOpportunitiesState({
    this.applied = const [],
    this.created = const [],
    this.isLoading = false,
    this.error,
  });

  MyOpportunitiesState copyWith({
    List<OpportunityApplication>? applied,
    List<Opportunity>? created,
    bool? isLoading,
    String? error,
  }) {
    return MyOpportunitiesState(
      applied: applied ?? this.applied,
      created: created ?? this.created,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MyOpportunitiesNotifier extends StateNotifier<MyOpportunitiesState> {
  final Dio _dio;

  MyOpportunitiesNotifier(this._dio) : super(MyOpportunitiesState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final appliedResp = await _dio.get('/me/opportunities', queryParameters: {'type': 'applied'});
      final appliedPage = appliedResp.data;
      final appliedList = (appliedPage is Map ? appliedPage['data'] as List? : appliedPage as List?) ?? [];
      List<Opportunity> created = [];
      try {
        final createdResp = await _dio.get('/me/opportunities', queryParameters: {'type': 'created'});
        final createdPage = createdResp.data;
        final createdList = (createdPage is Map ? createdPage['data'] as List? : createdPage as List?) ?? [];
        created = createdList.map((e) => Opportunity.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        // Providers only — athletes get applied; created stays empty.
      }
      state = MyOpportunitiesState(
        applied: appliedList.map((e) => OpportunityApplication.fromJson(e as Map<String, dynamic>)).toList(),
        created: created,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  Future<bool> apply({required String opportunityId, required String pitch}) async {
    try {
      await _dio.post('/opportunities/$opportunityId/apply', data: {'pitch': pitch});
      await load();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: ApiException.fromDio(e).message);
      return false;
    }
  }

  Future<bool> post(Map<String, dynamic> payload) async {
    try {
      await _dio.post('/me/opportunities', data: payload);
      await load();
      return true;
    } on DioException catch (e) {
      state = state.copyWith(error: ApiException.fromDio(e).message);
      return false;
    }
  }
}

final myOpportunitiesProvider =
    StateNotifierProvider<MyOpportunitiesNotifier, MyOpportunitiesState>((ref) {
  return MyOpportunitiesNotifier(ref.watch(dioProvider));
});
