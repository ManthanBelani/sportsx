import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';

/// Public program directory (Phase 5).
final programsProvider =
    StateNotifierProvider<DirectoryNotifier<Program>, DirectoryState<Program>>((ref) {
  return DirectoryNotifier<Program>(ref.watch(dioProvider), '/programs', Program.fromJson);
});

final programDetailProvider = FutureProvider.family<Program, String>((ref, id) async {
  final resp = await ref.watch(dioProvider).get('/programs/$id');
  return Program.fromJson(resp.data['data'] as Map<String, dynamic>);
});

class MyProgramsState {
  final List<Program> items;
  final bool isLoading;
  final String? error;

  MyProgramsState({this.items = const [], this.isLoading = false, this.error});

  MyProgramsState copyWith({List<Program>? items, bool? isLoading, String? error}) {
    return MyProgramsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class MyProgramsNotifier extends StateNotifier<MyProgramsState> {
  final Dio _dio;

  MyProgramsNotifier(this._dio) : super(MyProgramsState(isLoading: true)) {
    load();
  }

  Future<void> load({String? status}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/me/programs',
          queryParameters: status != null ? {'status': status} : null);
      if (!mounted) {
        return;
      }
      final page = resp.data;
      final raw = (page is Map ? page['data'] as List? : page as List?) ?? [];
      if (mounted) {
        state = MyProgramsState(
        items: raw.map((e) => Program.fromJson(e as Map<String, dynamic>)).toList(),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
        }
    }
  }

  Future<bool> save(Map<String, dynamic> payload, {String? id}) async {
    try {
      if (id == null) {
        await _dio.post('/me/programs', data: payload);
        if (!mounted) {
          return false;
        }
      } else {
        await _dio.put('/me/programs/$id', data: payload);
        if (!mounted) {
          return false;
        }
      }
      await load();
      if (!mounted) {
        return false;
      }
      return true;
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(error: ApiException.fromDio(e).message);
      }
      return false;
    }
  }
}

final myProgramsProvider =
    StateNotifierProvider<MyProgramsNotifier, MyProgramsState>((ref) {
  return MyProgramsNotifier(ref.watch(dioProvider));
});

class FacilitiesState {
  final List<Facility> items;
  final bool isLoading;
  final String? error;

  FacilitiesState({this.items = const [], this.isLoading = false, this.error});

  FacilitiesState copyWith({List<Facility>? items, bool? isLoading, String? error}) {
    return FacilitiesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class FacilitiesNotifier extends StateNotifier<FacilitiesState> {
  final Dio _dio;

  FacilitiesNotifier(this._dio) : super(FacilitiesState(isLoading: true)) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/me/facilities');
      if (!mounted) {
        return;
      }
      final raw = (resp.data['data'] as List? ?? []);
      if (mounted) {
        state = FacilitiesState(
        items: raw.map((e) => Facility.fromJson(e as Map<String, dynamic>)).toList(),
        );
      }
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
      }
    } catch (_) {
      if (mounted) {
        state = state.copyWith(isLoading: false, error: 'Something went wrong. Please try again.');
        }
    }
  }

  Future<bool> save(Map<String, dynamic> payload, {String? id}) async {
    try {
      if (id == null) {
        await _dio.post('/me/facilities', data: payload);
        if (!mounted) {
          return false;
        }
      } else {
        await _dio.put('/me/facilities/$id', data: payload);
        if (!mounted) {
          return false;
        }
      }
      await load();
      if (!mounted) {
        return false;
      }
      return true;
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(error: ApiException.fromDio(e).message);
      }
      return false;
    }
  }

  Future<bool> remove(String id) async {
    try {
      await _dio.delete('/me/facilities/$id');
      if (!mounted) {
        return false;
      }
      if (mounted) {
        state = state.copyWith(items: state.items.where((f) => f.id.toString() != id).toList());
      }
      return true;
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(error: ApiException.fromDio(e).message);
      }
      return false;
    }
  }
}

final facilitiesProvider =
    StateNotifierProvider<FacilitiesNotifier, FacilitiesState>((ref) {
  return FacilitiesNotifier(ref.watch(dioProvider));
});
