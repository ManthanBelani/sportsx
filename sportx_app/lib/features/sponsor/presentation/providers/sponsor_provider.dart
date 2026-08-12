import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/providers/directory_provider.dart';

/// Sponsor's own sponsorship listings (GET /me/sponsorships).
final mySponsorshipsProvider =
    StateNotifierProvider<DirectoryNotifier<Sponsorship>, DirectoryState<Sponsorship>>((ref) {
  return DirectoryNotifier<Sponsorship>(ref.watch(dioProvider), '/me/sponsorships', Sponsorship.fromJson);
});

/// Athlete discovery (GET /athletes) — reuse the shared athletes feed.
// (athletesProvider lives in directory_provider.dart)

/// Applications the athlete has submitted, viewed by athlete (GET /me/applications).
final myApplicationsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final resp = await ref.watch(dioProvider).get('/me/applications');
  final data = resp.data['data'];
  return List<Map<String, dynamic>>.from(data as List);
});

/// Applications received for a sponsorship (GET /sponsorships/{id}/applications).
final sponsorshipApplicationsProvider =
    FutureProvider.family<List<Map<String, dynamic>>, String>((ref, sponsorshipId) async {
  final resp =
      await ref.watch(dioProvider).get('/sponsorships/$sponsorshipId/applications');
  final data = resp.data['data'];
  return List<Map<String, dynamic>>.from(data as List);
});

/// Aggregated applications across all of the sponsor's listings (N+1 over
/// /me/sponsorships + /sponsorships/{id}/applications). Each entry carries the
/// source sponsorship title.
final sponsorApplicationsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final dio = ref.watch(dioProvider);
  final sponsorshipsResp = await dio.get('/me/sponsorships');
  final sponsorships = (sponsorshipsResp.data['data'] as List? ?? [])
      .cast<Map<String, dynamic>>();

  final all = <Map<String, dynamic>>[];
  for (final s in sponsorships) {
    final id = s['id']?.toString();
    final title = s['title'] ?? 'Sponsorship';
    if (id == null) continue;
    try {
      final resp = await dio.get('/sponsorships/$id/applications');
      final apps = (resp.data['data'] as List? ?? []).cast<Map<String, dynamic>>();
      for (final a in apps) {
        all.add({...a, 'sponsorship_id': id, 'sponsorship_title': title});
      }
    } on DioException {
      // skip listings that error
    }
  }
  return all;
});

class ShortlistEntry {
  final String id;
  final String athleteId;
  final String name;
  final String? sport;
  final String? note;

  ShortlistEntry({
    required this.id,
    required this.athleteId,
    required this.name,
    this.sport,
    this.note,
  });

  factory ShortlistEntry.fromJson(Map<String, dynamic> json) {
    final athlete = json['athlete'] as Map<String, dynamic>?;
    final sportRaw = athlete?['sport'];
    final sport = sportRaw is String
        ? sportRaw
        : sportRaw is Map
            ? sportRaw['name'] as String?
            : null;
    return ShortlistEntry(
      id: json['id']?.toString() ?? '',
      athleteId: (athlete?['id'] ?? json['athlete_id'])?.toString() ?? '',
      name: athlete?['name'] as String? ?? json['athlete_name'] as String? ?? 'Athlete',
      sport: sport,
      note: json['note'] as String?,
    );
  }
}

class ShortlistState {
  final List<ShortlistEntry> items;
  final bool isLoading;
  final String? error;

  ShortlistState({this.items = const [], this.isLoading = false, this.error});

  ShortlistState copyWith({List<ShortlistEntry>? items, bool? isLoading, String? error}) {
    return ShortlistState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ShortlistNotifier extends StateNotifier<ShortlistState> {
  final Dio _dio;

  ShortlistNotifier(this._dio) : super(ShortlistState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/me/shortlist');
      final list = (resp.data['data'] as List? ?? [])
          .map((e) => ShortlistEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      state = ShortlistState(items: list);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  Future<bool> add(String athleteId, {String? note}) async {
    try {
      await _dio.post('/me/shortlist', data: {'athlete_id': athleteId, if (note != null) 'note': note});
      await load();
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> remove(String entryId) async {
    try {
      await _dio.delete('/me/shortlist/$entryId');
      state = state.copyWith(items: state.items.where((e) => e.id != entryId).toList());
      return true;
    } on DioException {
      return false;
    }
  }
}

final shortlistProvider = StateNotifierProvider<ShortlistNotifier, ShortlistState>((ref) {
  return ShortlistNotifier(ref.watch(dioProvider));
});

/// Sponsorship lifecycle actions.
class SponsorshipActions {
  final Dio _dio;
  final Ref _ref;
  SponsorshipActions(this._dio, this._ref);

  Future<bool> create(Map<String, dynamic> data) async {
    try {
      await _dio.post('/me/sponsorships', data: data);
      _ref.read(mySponsorshipsProvider.notifier).refresh();
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> publish(String id) async {
    try {
      await _dio.post('/me/sponsorships/$id/publish');
      _ref.read(mySponsorshipsProvider.notifier).refresh();
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> close(String id) async {
    try {
      await _dio.post('/me/sponsorships/$id/close');
      _ref.read(mySponsorshipsProvider.notifier).refresh();
      return true;
    } on DioException {
      return false;
    }
  }

  Future<bool> updateApplication(String sponsorshipId, String applicationId, String status) async {
    try {
      await _dio.patch('/sponsorships/$sponsorshipId/applications/$applicationId', data: {'status': status});
      _ref.invalidate(sponsorshipApplicationsProvider(sponsorshipId));
      return true;
    } on DioException {
      return false;
    }
  }
}

final sponsorshipActionsProvider = Provider<SponsorshipActions>((ref) {
  return SponsorshipActions(ref.watch(dioProvider), ref);
});
