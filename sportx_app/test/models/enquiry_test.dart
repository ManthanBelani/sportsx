import 'package:flutter_test/flutter_test.dart';
import 'package:sportx_app/shared/providers/enquiry_provider.dart';

void main() {
  group('EnquiryMessage.fromJson', () {
    test('parses message with sender_name', () {
      final msg = EnquiryMessage.fromJson({
        'id': '1',
        'sender_name': 'John Coach',
        'body': 'Yes, slots available',
        'created_at': '2026-08-23T10:00:00Z',
        'sender_id': '5',
      });

      expect(msg.id, '1');
      expect(msg.sender, 'John Coach');
      expect(msg.body, 'Yes, slots available');
      expect(msg.createdAt, '2026-08-23T10:00:00Z');
    });

    test('marks isMe true when sender_id matches currentUserId', () {
      final msg = EnquiryMessage.fromJson({
        'id': '2',
        'sender': 'Coach',
        'body': 'Reply text',
        'sender_id': '5',
      }, currentUserId: '5');

      expect(msg.isMe, true);
    });

    test('marks isMe false when sender_id differs from currentUserId', () {
      final msg = EnquiryMessage.fromJson({
        'id': '3',
        'sender': 'Coach',
        'body': 'Reply text',
        'sender_id': '5',
      }, currentUserId: '10');

      expect(msg.isMe, false);
    });

    test('handles missing fields gracefully', () {
      final msg = EnquiryMessage.fromJson({}, currentUserId: '1');
      expect(msg.id, '');
      expect(msg.sender, 'Unknown');
      expect(msg.body, '');
      expect(msg.isMe, false);
    });

    test('isMe is true when both sender_id and currentUserId are null', () {
      final msg = EnquiryMessage.fromJson({});
      expect(msg.isMe, true);
    });
  });

  group('Enquiry.fromJson', () {
    test('parses basic enquiry fields', () {
      final enquiry = Enquiry.fromJson({
        'id': '100',
        'subject_type': 'coach_profile',
        'message': 'I want to join training',
        'status': 'new',
        'created_at': '2026-08-23T09:00:00Z',
        'is_read': false,
      });

      expect(enquiry.id, '100');
      expect(enquiry.subject, 'coach_profile');
      expect(enquiry.message, 'I want to join training');
      expect(enquiry.status, 'new');
      expect(enquiry.isRead, false);
    });

    test('parses sport as string', () {
      final enquiry = Enquiry.fromJson({
        'id': '101',
        'sport': 'Football',
        'message': 'Test',
        'status': 'new',
      });

      expect(enquiry.sport, 'Football');
    });

    test('parses sport from nested object', () {
      final enquiry = Enquiry.fromJson({
        'id': '102',
        'sport': {'name': 'Tennis'},
        'message': 'Test',
        'status': 'new',
      });

      expect(enquiry.sport, 'Tennis');
    });

    test('parses athlete name from nested athlete object', () {
      final enquiry = Enquiry.fromJson({
        'id': '103',
        'athlete': {'full_name': 'Rahul Athlete'},
        'message': 'Test',
        'status': 'new',
      });

      expect(enquiry.athleteName, 'Rahul Athlete');
    });

    test('falls back to athlete_name flat field', () {
      final enquiry = Enquiry.fromJson({
        'id': '104',
        'athlete_name': 'Sita Sharma',
        'message': 'Test',
        'status': 'new',
      });

      expect(enquiry.athleteName, 'Sita Sharma');
    });

    test('marks isRead true when read_at is present', () {
      final enquiry = Enquiry.fromJson({
        'id': '105',
        'message': 'Test',
        'status': 'new',
        'read_at': '2026-08-23T10:00:00Z',
      });

      expect(enquiry.isRead, true);
    });

    test('handles missing fields gracefully', () {
      final enquiry = Enquiry.fromJson({});
      expect(enquiry.id, '');
      expect(enquiry.athleteName, 'Unknown');
      expect(enquiry.subject, '');
      expect(enquiry.message, '');
      expect(enquiry.status, 'new');
    });
  });

  group('Enquiry.hasReplied', () {
    test('returns true when messages contain one from current user', () {
      final enquiry = Enquiry(
        id: '1',
        athleteName: 'Test',
        subject: 'test',
        message: 'Initial',
        status: 'new',
        messages: [
          EnquiryMessage(id: '1', sender: 'Coach', body: 'Reply', isMe: false),
          EnquiryMessage(id: '2', sender: 'Athlete', body: 'Thanks', isMe: true),
        ],
      );

      expect(enquiry.hasReplied, true);
    });

    test('returns false when no messages from current user', () {
      final enquiry = Enquiry(
        id: '2',
        athleteName: 'Test',
        subject: 'test',
        message: 'Initial',
        status: 'new',
        messages: [
          EnquiryMessage(id: '1', sender: 'Coach', body: 'Reply', isMe: false),
        ],
      );

      expect(enquiry.hasReplied, false);
    });

    test('returns false when no messages', () {
      final enquiry = Enquiry(
        id: '3',
        athleteName: 'Test',
        subject: 'test',
        message: 'Initial',
        status: 'new',
        messages: [],
      );

      expect(enquiry.hasReplied, false);
    });
  });

  group('EnquiryState', () {
    test('copyWith creates new instance with updated values', () {
      final state = EnquiryState(items: [], isLoading: false);
      final newState = state.copyWith(isLoading: true);

      expect(newState.isLoading, true);
      expect(newState.items, isEmpty);
    });

    test('default state has empty items and isLoading false', () {
      final state = EnquiryState();
      expect(state.items, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });
  });
}
