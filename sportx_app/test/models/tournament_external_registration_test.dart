import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/shared/models/tournament.dart';

/// Regression coverage for the external registration link + the registration
/// counters the organizer and admin screens read.
void main() {
  group('Tournament external registration', () {
    test('parses the external registration url and the counters', () {
      final t = Tournament.fromJson({
        'id': 9,
        'sport_id': 1,
        'name': 'External Cup',
        'status': 'published',
        'external_registration_url': 'https://forms.example.com/my-cup',
        'external_registration_clicks': 12,
        'registrations_count': 4,
        'confirmed_registrations_count': 2,
        'registration_mode': 'external',
        'total_spots': 32,
        'filled_spots': 2,
      });

      expect(t.hasExternalRegistration, isTrue);
      expect(t.externalRegistrationUrl, 'https://forms.example.com/my-cup');
      expect(t.externalRegistrationClicks, 12);
      expect(t.registrationsCount, 4);
      expect(t.confirmedRegistrationsCount, 2);
      expect(t.registrationMode, 'external');
      expect(t.totalSpots, 32);
      expect(t.filledSpots, 2);
    });

    test('treats a missing or blank external url as internal registration', () {
      final missing = Tournament.fromJson({
        'id': 10,
        'sport_id': 1,
        'name': 'Internal Cup',
        'status': 'published',
      });
      expect(missing.hasExternalRegistration, isFalse);
      expect(missing.externalRegistrationUrl, isNull);
      expect(missing.registrationMode, 'internal');

      final blank = Tournament.fromJson({
        'id': 11,
        'sport_id': 1,
        'name': 'Blank Link Cup',
        'status': 'published',
        'external_registration_url': '   ',
        'external_registration_clicks': null,
      });
      expect(blank.hasExternalRegistration, isFalse);
      expect(blank.externalRegistrationUrl, isNull);
      expect(blank.externalRegistrationClicks, 0);
      expect(blank.registrationsCount, 0);
      expect(blank.confirmedRegistrationsCount, 0);
    });
  });
}
