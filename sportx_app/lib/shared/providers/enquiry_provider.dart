import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/core/config/api_config.dart';

class EnquiryMessage {
  final String id;
  final String sender;
  final String body;
  final String? createdAt;
  final bool isMe;

  EnquiryMessage({
    required this.id,
    required this.sender,
    required this.body,
    this.createdAt,
    this.isMe = false,
  });

  factory EnquiryMessage.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    return EnquiryMessage(
      id: json['id']?.toString() ?? '',
      sender: json['sender_name'] as String? ?? json['sender'] as String? ?? 'Unknown',
      body: json['body'] as String? ?? json['message'] as String? ?? '',
      createdAt: json['created_at'] as String?,
      isMe: (json['sender_id']?.toString() ?? json['sender_user_id']?.toString()) == currentUserId,
    );
  }
}

class Enquiry {
  final String id;
  final String athleteName;
  final String? athletePhotoUrl;
  final String? sport;
  final String subject;
  final String message;
  final String status;
  final String? createdAt;
  final List<EnquiryMessage> messages;
  final bool isRead;

  Enquiry({
    required this.id,
    required this.athleteName,
    this.athletePhotoUrl,
    this.sport,
    required this.subject,
    required this.message,
    required this.status,
    this.createdAt,
    this.messages = const [],
    this.isRead = false,
  });

  factory Enquiry.fromJson(Map<String, dynamic> json, {String? currentUserId}) {
    final sportRaw = json['sport'];
    final sport = sportRaw is String
        ? sportRaw
        : sportRaw is Map
            ? sportRaw['name'] as String?
            : null;

    final athleteData = json['athlete'] as Map<String, dynamic>?;
    final athleteName = athleteData != null
        ? athleteData['full_name'] as String? ?? 'Unknown'
        : json['athlete_name'] as String? ?? json['sender_name'] as String? ?? 'Unknown';
    String? athletePhotoUrl = json['athlete_photo_url'] as String? ??
        (athleteData != null ? athleteData['photo_media_id'] as String? : null) ??
        json['sender_photo_url'] as String?;
    
    if (athletePhotoUrl != null && athletePhotoUrl.startsWith('/')) {
      athletePhotoUrl = '${ApiConfig.baseUrl}$athletePhotoUrl';
    }

    return Enquiry(
      id: json['id']?.toString() ?? '',
      athleteName: athleteName,
      athletePhotoUrl: athletePhotoUrl,
      sport: sport,
      subject: json['subject_type'] as String? ?? json['subject'] as String? ?? '',
      message: json['message'] as String? ?? json['body'] as String? ?? '',
      status: json['status'] as String? ?? 'new',
      createdAt: json['created_at'] as String?,
      isRead: json['is_read'] == true || json['read_at'] != null,
      messages: (json['messages'] as List? ?? [])
          .map((m) => EnquiryMessage.fromJson(m as Map<String, dynamic>, currentUserId: currentUserId))
          .toList(),
    );
  }

  bool get hasReplied => messages.any((m) => m.isMe);
}

class EnquiryState {
  final List<Enquiry> items;
  final bool isLoading;
  final String? error;

  EnquiryState({this.items = const [], this.isLoading = false, this.error});

  EnquiryState copyWith({List<Enquiry>? items, bool? isLoading, String? error}) {
    return EnquiryState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class EnquiryNotifier extends StateNotifier<EnquiryState> {
  final Dio _dio;
  final Ref _ref;

  EnquiryNotifier(this._dio, this._ref) : super(EnquiryState());

  Future<void> load({String? filter}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, dynamic>{};
      if (filter != null && filter != 'all') {
        params['filter'] = filter;
      }
      final resp = await _dio.get('/me/enquiries', queryParameters: params);
      final user = _ref.read(authProvider).user;
      final currentUserId = user?.id.toString();
      final list = (resp.data['data'] as List? ?? [])
          .map((e) => Enquiry.fromJson(e as Map<String, dynamic>, currentUserId: currentUserId))
          .toList();
      state = EnquiryState(items: list);
    } on DioException catch (e) {
      state = state.copyWith(isLoading: false, error: ApiException.fromDio(e).message);
    }
  }

  Future<void> loadAll() => load(filter: 'all');
}

final enquiryInboxProvider =
    StateNotifierProvider<EnquiryNotifier, EnquiryState>((ref) {
  final n = EnquiryNotifier(ref.watch(dioProvider), ref);
  return n;
});

final enquiryDetailProvider =
    FutureProvider.family<Enquiry, String>((ref, id) async {
  final dio = ref.watch(dioProvider);
  final user = ref.read(authProvider).user;
  final currentUserId = user?.id.toString();

  final resp = await dio.get('/enquiries/$id');
  final body = resp.data;
  final data = body is Map && body['data'] is Map
      ? body['data'] as Map<String, dynamic>
      : body as Map<String, dynamic>;
  final enquiry = Enquiry.fromJson(data, currentUserId: currentUserId);
  final msgs = (data['messages'] as List? ?? [])
      .map((m) => EnquiryMessage.fromJson(m as Map<String, dynamic>, currentUserId: currentUserId))
      .toList();
  return Enquiry(
    id: enquiry.id,
    athleteName: enquiry.athleteName,
    athletePhotoUrl: enquiry.athletePhotoUrl,
    sport: enquiry.sport,
    subject: enquiry.subject,
    message: enquiry.message,
    status: enquiry.status,
    createdAt: enquiry.createdAt,
    messages: msgs,
    isRead: enquiry.isRead,
  );
});

Future<bool> replyEnquiry(WidgetRef ref, String id, String message) async {
  try {
    await ref.read(dioProvider).post('/enquiries/$id/messages', data: {'body': message});
    ref.invalidate(enquiryDetailProvider(id));
    return true;
  } on DioException {
    return false;
  }
}

Future<void> markEnquiryRead(Ref ref, String id) async {
  try {
    await ref.read(dioProvider).put('/enquiries/$id/read');
  } catch (_) {}
}
