import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/shared/models/scholarship.dart';

void main() {
  group('Scholarship.fromJson (backend API wiring)', () {
    test('parses real backend payload with name field and nested logo', () {
      final s = Scholarship.fromJson({
        'id': 1,
        'name': 'Merit Sports Scholarship 2026',
        'description': 'Full scholarship for talented athletes',
        'sport_id': 1,
        'city_id': 1,
        'organization_name': 'EduSports Trust',
        'deadline': '2026-10-15',
        'eligibility': 'Minimum state rank',
        'benefits': 'Tuition + Equipment',
        'amount': 100000,
        'application_link': 'https://example.com/scholarship',
        'contact_email': 'scholarship@edusports.org',
        'documents_required': ['Aadhaar Card', 'Income Certificate', 'Sports Certificate'],
        'status': 'published',
        'logo': {'id': 10, 'url': '/storage/logos/edu.png', 'name': 'logo'},
        'sport': {'id': 1, 'name': 'Athletics', 'is_active': 1, 'sort_order': 3},
        'city': {'id': 1, 'name': 'Mumbai', 'state': 'Maharashtra', 'is_active': 1},
        'is_saved': false,
      });

      expect(s.id, 1);
      expect(s.title, 'Merit Sports Scholarship 2026');
      expect(s.sponsorName, 'EduSports Trust');
      expect(s.sponsorLogoUrl, '/storage/logos/edu.png');
      expect(s.applicationDeadline?.year, 2026);
      expect(s.applicationDeadline?.month, 10);
      expect(s.applicationDeadline?.day, 15);
      expect(s.eligibility, 'Minimum state rank');
      expect(s.benefits, 'Tuition + Equipment');
      expect(s.amountLabel, '₹1.0L');
      expect(s.documentsRequired.length, 3);
      expect(s.status, 'published');
      expect(s.sport?.name, 'Athletics');
      expect(s.city?.name, 'Mumbai');
    });

    test('handles null logo and title fallback to name', () {
      final s = Scholarship.fromJson({
        'id': 2,
        'name': 'Annual Sports Award',
        'sport_id': 2,
        'organization_name': 'Local Club',
        'deadline': '2026-08-30',
        'status': 'published',
        'sport': {'id': 2, 'name': 'Swimming', 'is_active': 1, 'sort_order': 5},
        'is_saved': true,
      });

      expect(s.id, 2);
      expect(s.title, 'Annual Sports Award');
      expect(s.sponsorName, 'Local Club');
      expect(s.sponsorLogoUrl, isNull);
      expect(s.isSaved, true);
    });

    test('handles large amounts (Crore format)', () {
      final s = Scholarship.fromJson({
        'id': 3,
        'name': 'Grand Scholarship',
        'sport_id': 1,
        'amount': 15000000,
        'status': 'published',
        'sport': {'id': 1, 'name': 'Football', 'is_active': 1, 'sort_order': 1},
      });

      expect(s.amountLabel, '₹1.5Cr');
    });

    test('handles missing optional fields gracefully', () {
      final s = Scholarship.fromJson({
        'id': 4,
        'name': 'Minimal',
        'sport_id': 1,
        'status': 'draft',
        'sport': null,
      });

      expect(s.id, 4);
      expect(s.title, 'Minimal');
      expect(s.sponsorName, isNull);
      expect(s.sponsorLogoUrl, isNull);
      expect(s.applicationDeadline, isNull);
      expect(s.documentsRequired, isEmpty);
      expect(s.sport, isNull);
    });
  });
}
