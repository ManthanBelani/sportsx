import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/core/session_scope.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:sportx_app/features/search/presentation/providers/search_provider.dart';

/// Stub Dio: resolves canned payloads so provider tests never hit the network.
Dio _stubDio() {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final path = options.path;
        Object data;
        if (path == '/search') {
          data = {
            'data': {
              'coaches': [
                {'id': 7, 'full_name': 'Stub Coach'},
              ],
              'academies': [],
              'athletes': [],
              'trials': [],
              'tournaments': [],
              'scholarships': [],
              'sponsorships': [],
              'sports_venues': [],
            },
            'meta': {'current_page': 1, 'last_page': 1},
          };
        } else if (path == '/me/recent-searches') {
          data = {'data': []};
        } else if (path == '/me/notifications') {
          data = {
            'data': [
              {
                'id': 1,
                'title': 'Stub',
                'body': 'Body',
                'type': 'mention',
                'is_read': false,
                'created_at': '2026-01-01T00:00:00Z',
              },
            ],
            'meta': {'unread_count': 1},
          };
        } else if (path == '/me/settings') {
          data = {
            'data': {
              'notification_prefs': {'push': true, 'in_app': true},
              'language': 'en',
            },
          };
        } else if (path == '/me/privacy') {
          data = {
            'data': {
              'profile_visibility': 'public',
              'who_can_message': 'everyone',
              'who_can_connect': 'everyone',
            },
          };
        } else if (path == '/me/events') {
          data = {
            'data': {
              'events': [],
              'counts': {'upcoming': 0, 'past': 0, 'total': 0},
            },
          };
        } else if (path == '/me/scout-profile' || path == '/me/profile') {
          data = {'data': null};
        } else {
          // Flat Laravel paginator shape for every other directory endpoint.
          data = {'data': [], 'current_page': 1, 'last_page': 1};
        }
        handler.resolve(
          Response(requestOptions: options, data: data, statusCode: 200),
        );
      },
    ),
  );
  return dio;
}

void main() {
  /// Exposes a real [Ref] inside tests (ProviderContainer is not a Ref).
  final probeProvider = Provider<Ref>((ref) => ref);

  group('resetUserScopedProviders', () {
    test('drops search results and notification state', () async {
      final container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(_stubDio())],
      );
      addTearDown(container.dispose);
      final ref = container.read(probeProvider);

      // Seed user-visible state through the real notifiers.
      await container.read(searchProvider.notifier).search('cricket');
      expect(container.read(searchProvider).results, isNotNull);
      expect(container.read(searchProvider).results!.coaches, hasLength(1));

      // Let the auto-loading notifications notifier settle (stub is instant).
      for (
        var i = 0;
        container.read(notificationsProvider).items.isEmpty && i < 200;
        i++
      ) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
      expect(container.read(notificationsProvider).items, hasLength(1));

      resetUserScopedProviders(ref);

      expect(container.read(searchProvider).results, isNull);
      expect(container.read(searchProvider).query, isEmpty);
      // Notifications notifier recreates fresh (auto-load refires in background).
      expect(container.read(notificationsProvider).items, isEmpty);
    });

    test('stale search responses cannot overwrite newer state', () async {
      final dio = Dio();
      var releaseFirst = false;
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final q = options.queryParameters['q'];
            if (options.path == '/search' && q == 'slow') {
              // Hold the first request until the second one has completed.
              while (!releaseFirst) {
                await Future<void>.delayed(const Duration(milliseconds: 5));
              }
            }
            final coaches = q == 'slow'
                ? [
                    {'id': 9, 'full_name': 'Stale Coach'},
                  ]
                : [];
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': {
                    'coaches': coaches,
                    'academies': [],
                    'athletes': [],
                    'trials': [],
                    'tournaments': [],
                    'scholarships': [],
                    'sponsorships': [],
                    'sports_venues': [],
                  },
                  'meta': {'current_page': 1, 'last_page': 1},
                },
              ),
            );
          },
        ),
      );
      final container = ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dio)],
      );
      addTearDown(container.dispose);

      final first = container.read(searchProvider.notifier).search('slow');
      // Skip ahead: a newer keystroke wins even though it finishes first.
      await container.read(searchProvider.notifier).search('fast');
      releaseFirst = true;
      await first;

      expect(container.read(searchProvider).query, 'fast');
      // The stale 'slow' response must not clobber the newer empty results.
      expect(container.read(searchProvider).results!.coaches, isEmpty);
    });
  });
}
