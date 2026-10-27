import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/program/presentation/screens/my_programs_screen.dart';

Dio _stubDio(Map<String, dynamic> programItem) {
  final dio = Dio();
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {'data': [programItem]},
          ),
        );
      },
    ),
  );
  return dio;
}

Future<void> pumpScreen(WidgetTester tester, Dio dio) async {
  tester.view.physicalSize = const Size(400, 800);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [dioProvider.overrideWithValue(dio)],
      child: const MaterialApp(home: MyProgramsScreen()),
    ),
  );
  await tester.pump(); // skeleton
  await tester.pump(const Duration(seconds: 2));
}

void main() {
  testWidgets('renders a normal program payload without exceptions',
      (tester) async {
    await pumpScreen(
      tester,
      _stubDio({
        'id': 12,
        'title': 'Cricket Masterclass',
        'mode': 'offline',
        'price': '1500.00',
        'status': 'active',
        'sport': {'name': 'Cricket'},
        'duration': '12 weeks',
        'schedule': 'Mon-Fri',
        'about': 'Test',
      }),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Cricket Masterclass'), findsOneWidget);
  });

  testWidgets('renders a payload whose id arrives as a double', (tester) async {
    await pumpScreen(
      tester,
      _stubDio({'id': 12.0, 'title': 'D The Program', 'mode': 'offline'}),
    );
    final err = tester.takeException();
    expect(err, isNull, reason: 'double id threw: $err');
  });

  testWidgets('renders a payload with a missing id', (tester) async {
    await pumpScreen(
      tester,
      _stubDio({'title': 'No Id Program', 'mode': 'offline'}),
    );
    final err = tester.takeException();
    expect(err, isNull, reason: 'missing id threw: $err');
  });

  testWidgets('renders when the API returns a bare list', (tester) async {
    final dio = Dio();
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          handler.resolve(
            Response(
              requestOptions: options,
              statusCode: 200,
              data: [
                {'id': 3, 'title': 'Bare List', 'mode': 'offline'},
              ],
            ),
          );
        },
      ),
    );
    await pumpScreen(tester, dio);
    final err = tester.takeException();
    expect(err, isNull, reason: 'bare-list shape threw: $err');
  });
}
