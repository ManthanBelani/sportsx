import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class ActivityEntry {
  final String id;
  final String title;
  final String status;
  final String? date;
  final String category; // trial | tournament | sponsorship

  ActivityEntry({
    required this.id,
    required this.title,
    required this.status,
    this.date,
    required this.category,
  });

  factory ActivityEntry.fromJson(Map<String, dynamic> json) {
    final type = (json['type'] as String? ?? json['category'] as String? ?? '').toLowerCase();
    return ActivityEntry(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? json['name'] as String? ?? 'Untitled',
      status: (json['status'] as String? ?? 'pending').toLowerCase(),
      date: json['date'] as String? ?? json['start_date'] as String? ?? json['created_at'] as String?,
      category: type.contains('tournament')
          ? 'tournament'
          : type.contains('sponsor') || type.contains('application')
              ? 'sponsorship'
              : 'trial',
    );
  }
}

class ActivityState {
  final List<ActivityEntry> items;
  final bool isLoading;
  final String? error;

  ActivityState({this.items = const [], this.isLoading = false, this.error});

  ActivityState copyWith({List<ActivityEntry>? items, bool? isLoading, String? error}) {
    return ActivityState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class ActivityNotifier extends StateNotifier<ActivityState> {
  final Dio _dio;

  ActivityNotifier(this._dio) : super(ActivityState()) {
    load();
  }

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final resp = await _dio.get('/me/activity');
      final list = (resp.data['data'] as List? ?? [])
          .map((e) => ActivityEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      state = ActivityState(items: list);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }
}

final activityProvider = StateNotifierProvider<ActivityNotifier, ActivityState>((ref) {
  return ActivityNotifier(ref.watch(dioProvider));
});
