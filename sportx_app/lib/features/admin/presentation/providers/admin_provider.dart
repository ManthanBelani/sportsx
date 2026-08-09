import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sportx_app/core/utils/api_client.dart';

class PlatformStats {
  final int activeListings;
  final int flaggedItems;
  final int pendingExpirations;
  final int newSignups30d;

  PlatformStats({
    this.activeListings = 0,
    this.flaggedItems = 0,
    this.pendingExpirations = 0,
    this.newSignups30d = 0,
  });

  factory PlatformStats.fromJson(Map<String, dynamic> json) {
    return PlatformStats(
      activeListings: json['active_listings'] ?? 0,
      flaggedItems: json['flagged_items'] ?? 0,
      pendingExpirations: json['pending_expirations'] ?? 0,
      newSignups30d: json['new_signups_30d'] ?? 0,
    );
  }
}

class AdminUser {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String role;
  final String? city;
  final String? profilePhotoUrl;
  final bool isVerified;
  final bool isActive;
  final String? status;
  final String? joinedDate;
  final String? lastActive;
  final List<String>? documents;

  AdminUser({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.role,
    this.city,
    this.profilePhotoUrl,
    this.isVerified = false,
    this.isActive = true,
    this.status,
    this.joinedDate,
    this.lastActive,
    this.documents,
  });

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? json['full_name'] ?? 'Unknown',
      email: json['email'] ?? '',
      phone: json['phone'],
      role: json['role'] ?? 'athlete',
      city: json['city']?['name'] ?? json['city'],
      profilePhotoUrl: json['profile_photo_url'],
      isVerified: json['is_verified'] == true || json['is_verified'] == 1,
      isActive: json['is_active'] != false,
      status: json['status'],
      joinedDate: json['created_at'],
      lastActive: json['last_active'],
      documents: json['documents'] != null
          ? List<String>.from(json['documents'])
          : null,
    );
  }
}

class Report {
  final String id;
  final String reportedBy;
  final String reportedByName;
  final String reason;
  final String? description;
  final String contentType;
  final String contentId;
  final String? contentPreview;
  final String status;
  final String createdAt;

  Report({
    required this.id,
    required this.reportedBy,
    required this.reportedByName,
    required this.reason,
    this.description,
    required this.contentType,
    required this.contentId,
    this.contentPreview,
    this.status = 'pending',
    required this.createdAt,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id']?.toString() ?? '',
      reportedBy: json['reported_by']?.toString() ?? '',
      reportedByName: json['reported_by_name'] ?? 'Anonymous',
      reason: json['reason'] ?? 'Other',
      description: json['description'],
      contentType: json['content_type'] ?? 'post',
      contentId: json['content_id']?.toString() ?? '',
      contentPreview: json['content_preview'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Opportunity {
  final String id;
  final String title;
  final String sponsorName;
  final String? sponsorLogo;
  final String? description;
  final String? budget;
  final String status;
  final String createdAt;

  Opportunity({
    required this.id,
    required this.title,
    required this.sponsorName,
    this.sponsorLogo,
    this.description,
    this.budget,
    this.status = 'pending',
    required this.createdAt,
  });

  factory Opportunity.fromJson(Map<String, dynamic> json) {
    return Opportunity(
      id: json['id']?.toString() ?? '',
      title: json['title'] ?? 'Untitled',
      sponsorName: json['sponsor_name'] ?? json['name'] ?? 'Unknown',
      sponsorLogo: json['sponsor_logo'] ?? json['logo_url'],
      description: json['description'],
      budget: json['budget'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class ContentPicker {
  final String type;
  final int total;
  final int published;
  final int draft;

  ContentPicker({
    required this.type,
    this.total = 0,
    this.published = 0,
    this.draft = 0,
  });

  factory ContentPicker.fromJson(String type, Map<String, dynamic> json) {
    return ContentPicker(
      type: type,
      total: json['total'] ?? 0,
      published: json['published'] ?? 0,
      draft: json['draft'] ?? 0,
    );
  }
}

class AdminState {
  final PlatformStats? stats;
  final List<ContentPicker> contentPicker;
  final List<dynamic> contentList;
  final List<AdminUser> users;
  final List<Report> reports;
  final List<Opportunity> opportunities;
  final List<AdminUser> pendingApprovals;
  final bool isLoading;
  final String? error;
  final bool isLoggedIn;
  final AdminUser? currentAdmin;

  AdminState({
    this.stats,
    this.contentPicker = const [],
    this.contentList = const [],
    this.users = const [],
    this.reports = const [],
    this.opportunities = const [],
    this.pendingApprovals = const [],
    this.isLoading = false,
    this.error,
    this.isLoggedIn = false,
    this.currentAdmin,
  });

  AdminState copyWith({
    PlatformStats? stats,
    List<ContentPicker>? contentPicker,
    List<dynamic>? contentList,
    List<AdminUser>? users,
    List<Report>? reports,
    List<Opportunity>? opportunities,
    List<AdminUser>? pendingApprovals,
    bool? isLoading,
    String? error,
    bool? isLoggedIn,
    AdminUser? currentAdmin,
  }) {
    return AdminState(
      stats: stats ?? this.stats,
      contentPicker: contentPicker ?? this.contentPicker,
      contentList: contentList ?? this.contentList,
      users: users ?? this.users,
      reports: reports ?? this.reports,
      opportunities: opportunities ?? this.opportunities,
      pendingApprovals: pendingApprovals ?? this.pendingApprovals,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      currentAdmin: currentAdmin ?? this.currentAdmin,
    );
  }
}

class AdminNotifier extends StateNotifier<AdminState> {
  final Dio _dio;

  AdminNotifier(this._dio) : super(AdminState());

  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post('/api/v1/admin/login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        state = state.copyWith(
          isLoading: false,
          isLoggedIn: true,
          currentAdmin: AdminUser(
            id: data['user']['id'].toString(),
            name: data['user']['name'] ?? '',
            email: data['user']['email'] ?? '',
            role: data['user']['role'] ?? 'admin',
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      return false;
    }
  }

  Future<bool> verify2fa(String code) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.post('/api/v1/admin/verify-2fa', data: {
        'code': code,
      });

      if (response.statusCode == 200) {
        final data = response.data['data'];
        state = state.copyWith(
          isLoading: false,
          currentAdmin: AdminUser(
            id: data['user']['id'].toString(),
            name: data['user']['name'] ?? '',
            email: data['user']['email'] ?? '',
            role: data['user']['role'] ?? 'admin',
          ),
        );
        return true;
      }
      return false;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/api/v1/admin/logout');
    } catch (_) {}
    state = AdminState();
  }

  Future<void> loadDashboard() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/api/v1/admin/dashboard');
      if (response.statusCode == 200) {
        state = state.copyWith(
          stats: PlatformStats.fromJson(response.data['data']),
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  Future<void> loadContentPicker() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/api/v1/admin/content');
      if (response.statusCode == 200) {
        final data = response.data['data'] as Map<String, dynamic>;
        final pickers = data.entries.map((e) =>
          ContentPicker.fromJson(e.key, e.value as Map<String, dynamic>)
        ).toList();
        state = state.copyWith(
          contentPicker: pickers,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  Future<void> loadContentList(String type, {String? status, String? q}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final params = <String, dynamic>{};
      if (status != null) params['status'] = status;
      if (q != null) params['q'] = q;

      final response = await _dio.get('/api/v1/admin/content/$type', queryParameters: params);
      if (response.statusCode == 200) {
        state = state.copyWith(
          contentList: List<dynamic>.from(response.data['data'] ?? []),
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  Future<void> loadModerationQueue() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/api/v1/admin/moderation/queue');
      if (response.statusCode == 200) {
        final reports = (response.data['data'] as List)
            .map((r) => Report.fromJson(r))
            .toList();
        state = state.copyWith(
          reports: reports,
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  Future<void> approveReport(String reportId) async {
    try {
      await _dio.post('/api/v1/admin/moderation/reports/$reportId/approve');
      state = state.copyWith(
        reports: state.reports.where((r) => r.id != reportId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
    }
  }

  Future<void> removeListing(String reportId) async {
    try {
      await _dio.post('/api/v1/admin/moderation/reports/$reportId/remove');
      state = state.copyWith(
        reports: state.reports.where((r) => r.id != reportId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
    }
  }

  Future<void> warnOwner(String reportId, {String? message}) async {
    try {
      await _dio.post('/api/v1/admin/moderation/reports/$reportId/warn', data: {
        if (message != null) 'message': message,
      });
      state = state.copyWith(
        reports: state.reports.where((r) => r.id != reportId).toList(),
      );
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
    }
  }

  Future<void> loadExpiryMonitor({String tab = 'pending'}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/api/v1/admin/expiry/monitor', queryParameters: {
        'tab': tab,
      });
      if (response.statusCode == 200) {
        state = state.copyWith(
          contentList: List<dynamic>.from(response.data['data'] ?? []),
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  Future<void> overrideExpiry(int eventId) async {
    try {
      await _dio.post('/api/v1/admin/expiry/events/$eventId/override');
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
    }
  }

  Future<void> restoreListing(int eventId) async {
    try {
      await _dio.post('/api/v1/admin/expiry/events/$eventId/restore');
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
    }
  }

  Future<void> loadCategories(String type) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _dio.get('/api/v1/admin/categories/$type');
      if (response.statusCode == 200) {
        state = state.copyWith(
          contentList: List<dynamic>.from(response.data['data'] ?? []),
          isLoading: false,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _getErrorMessage(e));
    }
  }

  Future<bool> createCategory(String type, Map<String, dynamic> data) async {
    try {
      await _dio.post('/api/v1/admin/categories/$type', data: data);
      return true;
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
      return false;
    }
  }

  Future<bool> updateCategory(String type, int id, Map<String, dynamic> data) async {
    try {
      await _dio.put('/api/v1/admin/categories/$type/$id', data: data);
      return true;
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
      return false;
    }
  }

  Future<bool> deleteCategory(String type, int id) async {
    try {
      await _dio.delete('/api/v1/admin/categories/$type/$id');
      return true;
    } catch (e) {
      state = state.copyWith(error: _getErrorMessage(e));
      return false;
    }
  }

  String _getErrorMessage(dynamic e) {
    if (e is DioException && e.response?.data != null) {
      return e.response?.data['error']['message'] ?? 'An error occurred';
    }
    return e.toString();
  }
}

final adminProvider = StateNotifierProvider<AdminNotifier, AdminState>((ref) {
  final dio = ref.watch(dioProvider);
  return AdminNotifier(dio);
});
