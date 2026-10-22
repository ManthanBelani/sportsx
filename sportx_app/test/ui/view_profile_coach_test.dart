import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/coach/presentation/screens/coach_directory_screen.dart';
import 'package:sportx_app/features/shared/presentation/screens/view_profile_screen.dart';

/// Regression: tapping a coach row (directory explore / community) must open
/// the shared coach profile (ViewProfileScreen) and render it without errors.
void main() {
  testWidgets('coach profile renders from the /coaches/{id} payload',
      (tester) async {
    final dio = _stubbedDio();

    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: const ViewProfileScreen(type: 'coach', id: '1'),
      ),
    ));

    await tester.pump(); // skeleton
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Ravi Kumar'), findsWidgets);
    // achievements arrived as a plain multi-line string → split into items.
    expect(find.text('Played nationals 2024'), findsOneWidget);
    expect(find.text('State champion 2023'), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'Opening a coach profile must not throw (string achievements)',
    );
  });

  testWidgets('JSON-encoded string achievements do not crash the profile',
      (tester) async {
    final dio = _stubbedDio(achievementsOverride:
        '[{"text":"National camp 2024","year":"2024"}]');

    tester.view.physicalSize = const Size(400, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      home: ProviderScope(
        overrides: [dioProvider.overrideWithValue(dio)],
        child: const ViewProfileScreen(type: 'coach', id: '1'),
      ),
    ));

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('National camp 2024'), findsOneWidget);
    expect(find.text('2024'), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'JSON-encoded string achievements must render',
    );
  });

  testWidgets('tapping a coach row in the directory opens the coach profile',
      (tester) async {
    final stubbed = _stubbedDio();
    final router = GoRouter(
      initialLocation: '/coaches',
      routes: [
        GoRoute(
          path: '/coaches',
          builder: (context, state) => const CoachDirectoryScreen(),
        ),
        GoRoute(
          path: '/view-profile',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return ViewProfileScreen(
              type: extra?['type'] as String? ?? 'athlete',
              id: extra?['id'] as String? ?? '',
            );
          },
        ),
      ],
    );

    tester.view.physicalSize = const Size(420, 3000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(ProviderScope(
      overrides: [dioProvider.overrideWithValue(stubbed)],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pump(); // directory skeleton
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    // Directory list renders the coach row...
    expect(find.text('Preem Coach'), findsOneWidget);

    // ...tapping it opens the coach profile detail.
    await tester.tap(find.text('Preem Coach'));
    await tester.pump(); // navigation
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Bio text'), findsOneWidget);
    expect(
      tester.takeException(),
      isNull,
      reason: 'Tapping a coach must open the profile without errors',
    );
  });
}

Dio _stubbedDio({Object? achievementsOverride}) {
  final dio = Dio();
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      final path = options.path;
      if (path == '/coaches') {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {
            'data': [_coachListPayload()],
            'current_page': 1,
            'last_page': 1,
          },
        ));
        return;
      }
      if (path == '/coaches/1') {
        final payload = _coachPayload();
        if (achievementsOverride != null) {
          payload['achievements'] = achievementsOverride;
        }
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: {'data': payload},
        ));
        return;
      }
      // follow/status + saved lookups → 404, must not break the screen.
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 404,
        data: {
          'error': {'code': 'NOT_FOUND', 'message': 'nope'},
        },
      ));
    },
  ));
  return dio;
}

/// Mirrors the DirectoryController for coaches row payload (raw model + relations).
Map<String, dynamic> _coachListPayload() => {
      'id': 1,
      'user_id': 11,
      'full_name': 'Preem Coach',
      'sport_id': 1,
      'city_id': 1,
      'sport': {'id': 1, 'name': 'Cricket'},
      'city': {'id': 1, 'name': 'Delhi', 'state': 'Delhi'},
      'experience': '8',
      'qualification': 'BCCI Level 2',
      'qualification_year': 2016,
      'certifications': ['NIS'],
      'languages': ['Hindi'],
      'fee_structure': '500/session',
      'personal_coaching': true,
      'listing_status': 'published',
    };

/// Mirrors the /coaches/1 detail payload (raw model + relations).
Map<String, dynamic> _coachPayload() => {
      'id': 1,
      'user_id': 11,
      'full_name': 'Ravi Kumar',
      'sport_id': 1,
      'city_id': 1,
      'sport': {'id': 1, 'name': 'Cricket'},
      'city': {'id': 1, 'name': 'Delhi', 'state': 'Delhi'},
      'experience': '8',
      'qualification': 'BCCI Level 2',
      'specialization': 'Batting',
      'achievements': 'Played nationals 2024\nState champion 2023',
      'certifications': ['NIS'],
      'languages': ['Hindi'],
      'personal_coaching': true,
      'fee_per_session': 500,
      'fee_monthly': 4000,
      'fee_quarterly': 10000,
      'hourly_rate': 500,
      'contact_number': '9876543210',
      'email': 'ravi@example.com',
      'bio': 'Bio text',
      'credentials': [
        {'title': 'NIS Certified', 'year': '2021'},
      ],
      'facilities': [
        {'type': 'facility', 'name': 'Outdoor nets'},
      ],
      'showcase_athletes': [
        {'id': 2, 'name': 'Arjun Mehta'},
      ],
      'social_links': {},
      'is_verified': true,
    };
