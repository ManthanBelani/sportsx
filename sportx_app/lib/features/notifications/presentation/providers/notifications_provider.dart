import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class NotificationItem {
  final int id;
  final String title;
  final String body;
  final String? type;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as int,
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      type: json['type'] as String?,
      isRead: json['is_read'] == true || json['is_read'] == 1,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }
}

class NotificationsState {
  final List<NotificationItem> items;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final int unreadCount;
  final String? error;

  NotificationsState({
    this.items = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.unreadCount = 0,
    this.error,
  });

  NotificationsState copyWith({
    List<NotificationItem>? items,
    bool? isLoading,
    bool? hasMore,
    int? page,
    int? unreadCount,
    String? error,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      unreadCount: unreadCount ?? this.unreadCount,
      error: error ?? this.error,
    );
  }
}

class NotificationsNotifier extends StateNotifier<NotificationsState> {
  final Dio _dio;

  NotificationsNotifier(this._dio) : super(NotificationsState()) {
    load();
  }

  Future<void> load() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, page: 1);
    try {
      final resp = await _dio.get('/me/notifications', queryParameters: {'page': 1, 'per_page': 20});
      final data = (resp.data['data'] as List).map((e) => NotificationItem.fromJson(e)).toList();
      final unreadCount = resp.data['meta']?['unread_count'] as int? ?? 0;
      final pagination = resp.data['meta']?['pagination'];
      final hasMore = pagination != null
          && (pagination['current_page'] as int) < (pagination['last_page'] as int);
      state = NotificationsState(items: data, hasMore: hasMore, page: 1, unreadCount: unreadCount);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    try {
      final nextPage = state.page + 1;
      final resp = await _dio.get('/me/notifications', queryParameters: {'page': nextPage, 'per_page': 20});
      final data = (resp.data['data'] as List).map((e) => NotificationItem.fromJson(e)).toList();
      final pagination = resp.data['meta']?['pagination'];
      final hasMore = pagination != null
          && (pagination['current_page'] as int) < (pagination['last_page'] as int);
      state = state.copyWith(
        items: [...state.items, ...data],
        hasMore: hasMore,
        page: nextPage,
        isLoading: false,
      );
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await _dio.patch('/me/notifications/$id/read');
      state = state.copyWith(
        items: state.items.map((item) {
          if (item.id == id) {
            return NotificationItem(
              id: item.id,
              title: item.title,
              body: item.body,
              type: item.type,
              isRead: true,
              createdAt: item.createdAt,
            );
          }
          return item;
        }).toList(),
        unreadCount: state.unreadCount > 0 ? state.unreadCount - 1 : 0,
      );
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    try {
      await _dio.post('/me/notifications/read-all');
      state = state.copyWith(
        items: state.items.map((item) => NotificationItem(
          id: item.id, title: item.title, body: item.body,
          type: item.type, isRead: true, createdAt: item.createdAt,
        )).toList(),
        unreadCount: 0,
      );
    } catch (_) {}
  }

  Future<void> refresh() async {
    state = NotificationsState();
    await load();
  }
}

final notificationsProvider = StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  return NotificationsNotifier(ref.watch(dioProvider));
});
