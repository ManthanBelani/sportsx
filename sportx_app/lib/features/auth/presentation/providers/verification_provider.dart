import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';

/// A.10 Verification badge — request the blue check and track its status.
enum VerifyBadgeStatus { none, pending, verified, rejected }

class VerificationState {
  final VerifyBadgeStatus status;

  /// Profile the request targets (verifiable type/id resolved from /me/profile).
  final String? verifiableType;
  final int? verifiableId;

  /// Proof documents (media_items ids) staged for submission.
  final List<int> proofIds;

  final String? decisionReason;
  final String? submittedAt;

  final bool isLoading;
  final bool submitting;
  final String? error;

  const VerificationState({
    this.status = VerifyBadgeStatus.none,
    this.verifiableType,
    this.verifiableId,
    this.proofIds = const [],
    this.decisionReason,
    this.submittedAt,
    this.isLoading = false,
    this.submitting = false,
    this.error,
  });

  VerificationState copyWith({
    VerifyBadgeStatus? status,
    String? verifiableType,
    Object? verifiableId = _sentinel,
    List<int>? proofIds,
    Object? decisionReason = _sentinel,
    Object? submittedAt = _sentinel,
    bool? isLoading,
    bool? submitting,
    Object? error = _sentinel,
  }) {
    return VerificationState(
      status: status ?? this.status,
      verifiableType: verifiableType ?? this.verifiableType,
      verifiableId:
          verifiableId == _sentinel ? this.verifiableId : verifiableId as int?,
      proofIds: proofIds ?? this.proofIds,
      decisionReason: decisionReason == _sentinel
          ? this.decisionReason
          : decisionReason as String?,
      submittedAt:
          submittedAt == _sentinel ? this.submittedAt : submittedAt as String?,
      isLoading: isLoading ?? this.isLoading,
      submitting: submitting ?? this.submitting,
      error: error == _sentinel ? this.error : error as String?,
    );
  }

  static const _sentinel = Object();
}

class VerificationNotifier extends StateNotifier<VerificationState> {
  final Dio _dio;
  final Ref _ref;

  VerificationNotifier(this._dio, this._ref) : super(const VerificationState());

  /// morph-map alias per app role (docs §3.1 table).
  static String? verifiableTypeForRole(String? role) {
    switch (role) {
      case 'athlete':
        return 'athlete_profile';
      case 'coach':
        return 'coach_profile';
      case 'academy':
        return 'academy';
      case 'organizer':
        return 'organizer_profile';
      case 'scout':
      case 'talent_scout':
        return 'talent_scout_profile';
      case 'sponsor':
        return 'sponsor_profile';
      default:
        return null;
    }
  }

  /// Load the profile id + the latest verification request.
  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final role = _ref.read(authProvider).user?.role;
      final verifiableType = verifiableTypeForRole(role);

      // Resolve the profile pk (verifiable_id) and the badge flag.
      int? profileId;
      bool verified = false;
      final profileResp = await _dio.get('/me/profile');
      final profile = profileResp.data['data'] as Map<String, dynamic>?;
      if (profile != null) {
        profileId = profile['id'] is int
            ? profile['id'] as int
            : int.tryParse('${profile['id']}');
        verified = profile['is_verified'] == true ||
            profile['is_verified'] == 1;
      }

      // Latest request for this profile (server reuses pending rows).
      String? decisionReason;
      String? submittedAt;
      var status = verified
          ? VerifyBadgeStatus.verified
          : VerifyBadgeStatus.none;

      final resp = await _dio.get('/me/verification');
      final items = resp.data['data'] as List? ?? [];
      if (items.isNotEmpty) {
        final latest = items.first as Map<String, dynamic>;
        final apiStatus = '${latest['status']}';
        // Only trust the request row for THIS profile.
        final sameTarget =
            verifiableType == null ||
            latest['verifiable_type'] == verifiableType;
        if (sameTarget) {
          switch (apiStatus) {
            case 'pending':
              status = VerifyBadgeStatus.pending;
            case 'approved':
              status = VerifyBadgeStatus.verified;
            case 'rejected':
              // A rejected request only matters if no newer/liv(er) state.
              if (!verified) {
                status = VerifyBadgeStatus.rejected;
              }
          }
          decisionReason = latest['decision_reason'] as String?;
          submittedAt = latest['created_at'] as String?;
          final reqVerifiableId = latest['verifiable_id'] is int
              ? latest['verifiable_id'] as int
              : int.tryParse('${latest['verifiable_id']}');
          profileId = reqVerifiableId;

        }
      }

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        status: status,
        verifiableType: verifiableType,
        verifiableId: profileId,
        proofIds: [],
        decisionReason: decisionReason,
        submittedAt: submittedAt,
        error: null,
      );
    } on DioException catch (e) {
      if (mounted) {
        state = state.copyWith(
            isLoading: false, error: ApiException.fromDio(e).message);
      }
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
            isLoading: false,
            error: 'Something went wrong. Please try again.');
      }
    }
  }

  /// Stage a proof document (media_item id) for submission.
  void addProof(int mediaId) {
    if (state.proofIds.contains(mediaId)) return;
    state = state.copyWith(proofIds: [...state.proofIds, mediaId], error: null);
  }

  void removeProof(int mediaId) {
    state = state.copyWith(
      proofIds: state.proofIds.where((id) => id != mediaId).toList(),
    );
  }

  /// POST /me/verification. Returns true when the request is pending.
  Future<bool> submit(String? notes) async {
    final verifiableType = state.verifiableType;
    final verifiableId = state.verifiableId;
    if (verifiableType == null || verifiableId == null) {
      state = state.copyWith(
          error: 'Complete your profile before requesting verification.');
      return false;
    }

    state = state.copyWith(submitting: true, error: null);
    try {
      await _dio.post('/me/verification', data: {
        'verifiable_type': verifiableType,
        'verifiable_id': verifiableId,
        if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        'proof_media_ids': state.proofIds,
      });
      if (!mounted) return false;
      await load();
      return true;
    } on DioException catch (e) {
      final message = ApiException.fromDio(e).message;
      if (mounted) {
        state = state.copyWith(submitting: false, error: message);
      }
      return false;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(
            submitting: false,
            error: 'Submission failed. Please check your connection and try again.');
      }
      return false;
    }
  }
}

final verificationProvider =
    StateNotifierProvider<VerificationNotifier, VerificationState>((ref) {
  return VerificationNotifier(ref.watch(dioProvider), ref);
});
