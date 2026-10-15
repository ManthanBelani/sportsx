import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

/// Phase 8 unified events (v3 OR.4/AC.6 + AT.9).
/// Backend: /me/events (Upcoming/Past + counts), /events/{id},
/// /me/events CRUD + publish/close, unified registrations + export + cancel.

class UnifiedEvent {
  final String id;
  final String eventType;
  final String name;
  final String status;

  UnifiedEvent({required this.id, required this.eventType, required this.name, required this.status});

  factory UnifiedEvent.fromJson(Map<String, dynamic> json) => UnifiedEvent(
        id: (json['id'] ?? '').toString(),
        eventType: (json['event_type'] ?? 'trial').toString(),
        name: (json['name'] ?? '').toString(),
        status: (json['status'] ?? '').toString(),
      );
}

class MyEventsState {
  final List<UnifiedEvent> events;
  final int upcoming;
  final int past;
  final int total;
  final bool isLoading;
  final String? error;
  final String filter;

  MyEventsState({
    this.events = const [],
    this.upcoming = 0,
    this.past = 0,
    this.total = 0,
    this.isLoading = false,
    this.error,
    this.filter = 'upcoming',
  });

  MyEventsState copyWith({
    List<UnifiedEvent>? events,
    int? upcoming,
    int? past,
    int? total,
    bool? isLoading,
    String? error,
    String? filter,
  }) =>
      MyEventsState(
        events: events ?? this.events,
        upcoming: upcoming ?? this.upcoming,
        past: past ?? this.past,
        total: total ?? this.total,
        isLoading: isLoading ?? this.isLoading,
        error: error,
        filter: filter ?? this.filter,
      );
}

class MyEventsNotifier extends StateNotifier<MyEventsState> {
  final Dio _dio;
  MyEventsNotifier(this._dio) : super(MyEventsState()) {
    load();
  }

  Future<void> load({String? filter}) async {
    state = state.copyWith(isLoading: true, filter: filter ?? state.filter);
    try {
      final resp = await _dio.get('/me/events', queryParameters: {'filter': state.filter});
      if (!mounted) {
        return;
      }
      final data = resp.data['data'] as Map<String, dynamic>;
      final list = (data['events'] as List? ?? [])
          .map((e) => UnifiedEvent.fromJson(e as Map<String, dynamic>))
          .toList();
      final counts = data['counts'] as Map<String, dynamic>? ?? {};
      if (mounted) {
        state = state.copyWith(
        events: list,
        upcoming: (counts['upcoming'] as num?)?.toInt() ?? 0,
        past: (counts['past'] as num?)?.toInt() ?? 0,
        total: (counts['total'] as num?)?.toInt() ?? 0,
        isLoading: false,
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

  Future<bool> publish(String id, String type) async {
    try {
      await _dio.post('/me/events/$id/publish', queryParameters: {'type': type});
      if (!mounted) {
        return false;
      }
      await load();
      if (!mounted) {
        return false;
      }
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> close(String id, String type) async {
    try {
      await _dio.post('/me/events/$id/close', queryParameters: {'type': type});
      if (!mounted) {
        return false;
      }
      await load();
      if (!mounted) {
        return false;
      }
      return true;
    } on DioException {
      return false;
    }
  }
}

final myEventsProvider = StateNotifierProvider<MyEventsNotifier, MyEventsState>((ref) {
  return MyEventsNotifier(ref.watch(dioProvider));
});

/// Unified registrant list: GET /events/{id}/registrations?status=&q=
final eventRegistrationsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, Map<String, dynamic>>((ref, args) async {
  final resp = await ref.watch(dioProvider).get(
    '/events/${args['id']}/registrations',
    queryParameters: {
      if (args['type'] != null) 'type': args['type'],
      if (args['status'] != null) 'status': args['status'],
      if (args['q'] != null) 'q': args['q'],
    },
  );
  final body = resp.data;
  final list = body is Map && body['data'] is List ? body['data'] as List : (body is List ? body : []);
  return list.cast<Map<String, dynamic>>();
});

Future<bool> decideRegistration(
  WidgetRef ref, {
  required String registrationId,
  required String type,
  required bool approve,
  String? reason,
}) async {
  try {
    await ref.read(dioProvider).post(
      '/registrations/$registrationId/${approve ? 'approve' : 'reject'}',
      queryParameters: {'type': type},
      data: reason != null ? {'reason': reason} : null,
    );
    return true;
  } on DioException {
    return false;
  }
}

Future<bool> bulkDecideRegistrations(
  WidgetRef ref, {
  required String eventId,
  required String type,
  required bool approve,
  required List<int> ids,
}) async {
  try {
    await ref.read(dioProvider).post(
      '/events/$eventId/registrations/bulk',
      queryParameters: {'type': type},
      data: {'action': approve ? 'approve' : 'reject', 'ids': ids},
    );
    return true;
  } on DioException {
    return false;
  }
}

/// DELETE /me/registrations/{id}?type= — athlete cancel (AT.9).
Future<bool> cancelRegistration(WidgetRef ref, {required String id, required String type}) async {
  try {
    await ref.read(dioProvider).delete('/me/registrations/$id', queryParameters: {'type': type});
    return true;
  } on DioException {
    return false;
  }
}

/// Tournament results (per category + public bracket view).
final eventResultsProvider = FutureProvider.family<List<Map<String, dynamic>>, String>((ref, tournamentId) async {
  final resp = await ref.watch(dioProvider).get('/tournaments/$tournamentId/results');
  final list = resp.data['data'] as List? ?? [];
  return list.cast<Map<String, dynamic>>();
});
