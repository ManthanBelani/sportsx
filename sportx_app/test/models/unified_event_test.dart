import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/features/trial/presentation/providers/unified_events_provider.dart';

/// The unified events list feeds the organizer dashboard — it must carry the
/// registration counters and the external-registration flag.
void main() {
  group('UnifiedEvent.fromJson', () {
    test('parses a tournament with its registration counters', () {
      final e = UnifiedEvent.fromJson({
        'id': 15,
        'event_type': 'tournament',
        'name': 'ZZ Cup',
        'status': 'published',
        'venue': 'Audit Ground',
        'start_date': '2027-09-01T00:00:00.000000Z',
        'total_spots': 26,
        'filled_spots': 4,
        'registrations_count': 7,
        'external_registration_clicks': 3,
        'has_external_registration': true,
      });

      expect(e.id, '15');
      expect(e.isTournament, isTrue);
      expect(e.venue, 'Audit Ground');
      expect(e.startDate, isNotNull);
      expect(e.totalSpots, 26);
      expect(e.filledSpots, 4);
      expect(e.registrationsCount, 7);
      expect(e.externalRegistrationClicks, 3);
      expect(e.hasExternalRegistration, isTrue);
    });

    test('parses a trial and defaults the counters', () {
      final e = UnifiedEvent.fromJson({
        'id': 3,
        'event_type': 'trial',
        'name': 'Open Trial',
        'status': 'published',
        'event_datetime': '2027-05-01T10:00:00.000000Z',
      });

      expect(e.isTournament, isFalse);
      expect(e.totalSpots, isNull);
      expect(e.filledSpots, isNull);
      expect(e.registrationsCount, 0);
      expect(e.externalRegistrationClicks, 0);
      expect(e.hasExternalRegistration, isFalse);
    });
  });
}
