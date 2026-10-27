import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/core/responsive_scaler.dart';
import 'package:sportx_app/core/router.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/storage_service.dart';
import 'package:sportx_app/theme/app_theme.dart';

final _academyUser = {
  'id': 16,
  'role': 'academy',
  'name': 'Elite Academy',
  'email': 'academy@sportx.test',
  'phone': '+91 79 2345 6789',
  'email_verified_at': '2026-10-22T07:16:42+00:00',
  'status': 'active',
  'is_verified': false,
};

const _programItem = {
  'id': 3,
  'owner_type': 'academy',
  'owner_id': 1,
  'created_by_user_id': 16,
  'title': 'Elite Junior Cricket Residential',
  'sport_id': 1,
  'age_group_id': 3,
  'duration': '12 weeks',
  'mode': 'offline',
  'price': '25000.00',
  'schedule': 'Full-time, Mon-Sat',
  'about': 'Residential programme.',
  'status': 'active',
  'created_at': '2026-10-22T07:17:07.000000Z',
  'updated_at': '2026-10-22T07:17:07.000000Z',
  'deleted_at': null,
  'sport': {'id': 1, 'name': 'Cricket', 'is_active': 1, 'sort_order': 1, 'created_at': null, 'updated_at': null},
  'age_group': {'id': 3, 'name': 'Under-14', 'min_age': 12, 'max_age': 13, 'is_active': 1, 'created_at': null, 'updated_at': null},
};

Dio _stubDio() {
  final dio = Dio();
  dio.options.validateStatus = (status) => status != null && status >= 200 && status < 300;
  dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
    final path = options.uri.path;
    if (path.endsWith('/auth/me')) {
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {'data': _academyUser}));
    } else if (path.contains('/me/programs')) {
      handler.resolve(Response(
        requestOptions: options,
        statusCode: 200,
        data: {
          'current_page': 1,
          'data': [_programItem],
          'first_page_url': 'x',
          'from': 1,
          'last_page': 1,
          'last_page_url': 'x',
          'links': [],
          'next_page_url': null,
          'path': 'x',
          'per_page': 20,
          'prev_page_url': null,
          'to': 1,
          'total': 1,
        },
      ));
    } else {
      handler.resolve(Response(requestOptions: options, statusCode: 200, data: {'data': []}));
    }
  }));
  return dio;
}

class _FakeStorage extends StorageService {
  @override
  Future<String?> getToken() async => 'fake-token';
  @override
  Future<void> saveToken(String token) async {}
  @override
  Future<void> deleteToken() async {}
  @override
  Future<void> saveUserData(Map<String, dynamic> userData) async {}
  @override
  Future<Map<String, dynamic>?> getUserData() async => null;
  @override
  Future<void> clearAll() async {}
}

void main() {
  testWidgets('full app stack renders /my-programs without red screen', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.reset);

    final dio = _stubDio();
    final container = ProviderContainer(overrides: [
      dioProvider.overrideWithValue(dio),
      storageServiceProvider.overrideWithValue(_FakeStorage()),
    ]);
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.lightTheme,
          builder: (context, child) => ResponsiveScaler(child: child),
          routerConfig: container.read(routerProvider),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(seconds: 2));
    tester.takeException();
    debugPrint('after auth settle, errors cleared');

    final router = container.read(routerProvider);
    debugPrint('current location pre-go: ${router.routerDelegate.currentConfiguration.uri}');
    router.go('/my-programs');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    debugPrint('location now: ${router.routerDelegate.currentConfiguration.uri}');

    final err = tester.takeException();
    debugPrint('MYPROGRAMS EXCEPTION: $err');
    final hasTitle = find.text('Elite Junior Cricket Residential').evaluate().isNotEmpty;
    debugPrint('hasProgramTitle=$hasTitle');    expect(err, isNull, reason: 'red screen cause: $err');
    expect(hasTitle, isTrue, reason: 'my programs screen not visible (title=${find.textContaining("My").evaluate().length})');
  });
}
