import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/features/organizer/presentation/widgets/external_registration_field.dart';

void main() {
  group('validateExternalRegistrationUrl', () {
    test('accepts an empty value (the field is optional)', () {
      expect(validateExternalRegistrationUrl(null), isNull);
      expect(validateExternalRegistrationUrl(''), isNull);
      expect(validateExternalRegistrationUrl('   '), isNull);
    });

    test('accepts absolute http(s) links', () {
      expect(validateExternalRegistrationUrl('https://forms.example.com/cup'), isNull);
      expect(validateExternalRegistrationUrl('http://example.com/register'), isNull);
    });

    test('rejects links without a scheme or host', () {
      expect(validateExternalRegistrationUrl('example.com'), isNotNull);
      expect(validateExternalRegistrationUrl('forms.example.com/cup'), isNotNull);
    });

    test('rejects non http(s) schemes', () {
      expect(validateExternalRegistrationUrl('javascript:alert(1)'), isNotNull);
      expect(validateExternalRegistrationUrl('ftp://example.com/cup'), isNotNull);
    });
  });

  group('ExternalRegistrationUrlField', () {
    testWidgets('shows the URL input only when enabled', (tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ExternalRegistrationUrlField(
            controller: controller,
            enabled: false,
          ),
        ),
      ));

      expect(find.byType(TextField), findsNothing);
      expect(find.text('Use my own registration page'), findsOneWidget);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ExternalRegistrationUrlField(
            controller: controller,
            enabled: true,
          ),
        ),
      ));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('External Registration URL'), findsOneWidget);
    });

    testWidgets('reports the toggle back to the caller', (tester) async {
      final controller = TextEditingController();
      bool? enabled;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: ExternalRegistrationUrlField(
            controller: controller,
            enabled: false,
            onEnabledChanged: (v) => enabled = v,
          ),
        ),
      ));

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(enabled, isTrue);
    });
  });
}
