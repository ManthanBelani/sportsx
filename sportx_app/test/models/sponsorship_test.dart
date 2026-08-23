import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/shared/models/sponsorship.dart';

void main() {
  group('Sponsorship.fromJson (backend API wiring)', () {
    test('parses real backend payload with nested logo relation', () {
      final s = Sponsorship.fromJson({
        'id': 1,
        'title': 'Elite Athlete Sponsorship 2026',
        'description': 'Supporting talented athletes across India',
        'sport_id': 1,
        'city_id': null,
        'organization_name': 'SportsX Foundation',
        'deadline': '2026-12-31',
        'benefits_offered': 'Equipment, Training, Travel allowance',
        'eligibility_criteria': 'Age 14-25, Represented state/national level',
        'amount': 500000,
        'application_link': 'https://example.com/apply',
        'contact_email': 'sports@foundation.org',
        'contact_phone': '+91 98765 43210',
        'documents_required': ['Aadhaar Card', 'Sports Certificate'],
        'status': 'published',
        'expires_at': null,
        'logo': {'id': 5, 'url': '/storage/logos/sponsor1.png', 'name': 'logo'},
        'sport': {'id': 1, 'name': 'Football', 'is_active': 1, 'sort_order': 1},
        'city': null,
        'is_saved': false,
      });

      expect(s.id, 1);
      expect(s.title, 'Elite Athlete Sponsorship 2026');
      expect(s.sponsorName, 'SportsX Foundation');
      expect(s.sponsorLogoUrl, '/storage/logos/sponsor1.png');
      expect(s.applicationDeadline?.year, 2026);
      expect(s.applicationDeadline?.month, 12);
      expect(s.applicationDeadline?.day, 31);
      expect(s.benefits, 'Equipment, Training, Travel allowance');
      expect(s.eligibility, 'Age 14-25, Represented state/national level');
      expect(s.amountLabel, '₹5.0L');
      expect(s.status, 'published');
      expect(s.sport?.name, 'Football');
    });

    test('handles null logo (no nested logo relation)', () {
      final s = Sponsorship.fromJson({
        'id': 2,
        'title': 'Basic Support',
        'sport_id': 2,
        'organization_name': 'Local Sponsor',
        'deadline': '2026-06-01',
        'benefits_offered': 'Equipment only',
        'status': 'published',
        'sport': {'id': 2, 'name': 'Basketball', 'is_active': 1, 'sort_order': 2},
        'is_saved': true,
      });

      expect(s.id, 2);
      expect(s.sponsorName, 'Local Sponsor');
      expect(s.sponsorLogoUrl, isNull);
      expect(s.isSaved, true);
    });

    test('handles large amounts (Crore format)', () {
      final s = Sponsorship.fromJson({
        'id': 3,
        'title': 'Premium Package',
        'sport_id': 1,
        'organization_name': 'Big Corp',
        'amount': 25000000,
        'status': 'published',
        'sport': {'id': 1, 'name': 'Football', 'is_active': 1, 'sort_order': 1},
      });

      expect(s.amountLabel, '₹2.5Cr');
    });

    test('handles missing optional fields', () {
      final s = Sponsorship.fromJson({
        'id': 4,
        'title': 'Minimal',
        'sport_id': 1,
        'status': 'draft',
        'sport': null,
      });

      expect(s.id, 4);
      expect(s.sponsorName, isNull);
      expect(s.sponsorLogoUrl, isNull);
      expect(s.applicationDeadline, isNull);
      expect(s.benefits, isNull);
      expect(s.eligibility, isNull);
      expect(s.sport, isNull);
    });
  });
}
