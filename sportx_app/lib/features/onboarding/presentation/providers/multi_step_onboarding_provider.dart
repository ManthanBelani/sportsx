import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/role_config.dart';
import 'package:sportx_app/core/utils/api_client.dart';

/// Progressive onboarding state for all roles
/// Steps: Core Identity → Role Profile → Media → Verification → Preferences

enum OnboardingStep {
  coreIdentity,      // Name, DOB, gender, phone
  roleProfile,       // Role-specific fields (sports, license, org name, etc.)
  media,             // Profile photo, cover photo
  verification,      // Govt ID for verified badge
  preferences,       // Notifications, privacy, interests
  complete,
}

/// Tracks which step user is on
class OnboardingProgress {
  final OnboardingStep currentStep;
  final Set<OnboardingStep> completedSteps;
  final Map<String, dynamic> formData;

  OnboardingProgress({
    this.currentStep = OnboardingStep.coreIdentity,
    this.completedSteps = const {},
    this.formData = const {},
  });

  OnboardingProgress copyWith({
    OnboardingStep? currentStep,
    Set<OnboardingStep>? completedSteps,
    Map<String, dynamic>? formData,
  }) {
    return OnboardingProgress(
      currentStep: currentStep ?? this.currentStep,
      completedSteps: completedSteps ?? this.completedSteps,
      formData: formData ?? this.formData,
    );
  }

  bool isStepComplete(OnboardingStep step) => completedSteps.contains(step);
  double get progress => completedSteps.length / OnboardingStep.values.length;
}

class MultiStepOnboardingNotifier extends StateNotifier<OnboardingProgress> {
  final Dio _dio;
  final SportXRole _role;

  MultiStepOnboardingNotifier(this._dio, this._role) : super(OnboardingProgress());

  /// Returns the list of steps for this role (some roles skip certain steps)
  List<OnboardingStep> get stepsForRole => onboardingStepsForRole(_role);

  /// Read-only view of progress, for use outside the notifier (e.g. by widgets
  /// that seed their initial state from previously entered data).
  OnboardingProgress get progress => state;

  /// Value stored for [key], or null if the user has not entered it.
  Object? fieldValue(String key) => state.formData[key];

  /// Form-data keys that must be filled before leaving [step].
  /// Empty means the step has no required input.
  static const Map<OnboardingStep, List<String>> _requiredKeys = {
    OnboardingStep.coreIdentity: ['full_name', 'date_of_birth', 'gender'],
    OnboardingStep.roleProfile: [],
    OnboardingStep.media: [],
    OnboardingStep.verification: [],
    OnboardingStep.preferences: [],
  };

  /// Labels for messages shown when validation fails.
  static const Map<String, String> _keyLabels = {
    'full_name': 'Full Name',
    'date_of_birth': 'Date of Birth',
    'gender': 'Gender',
    'sport_id': 'Primary Sport',
    'skill_level': 'Skill Level',
    'city_id': 'City',
    'organization_name': 'Organization Name',
    'academy_license': 'Academy License',
    'coaching_license': 'Coaching License',
    'scouting_license': 'Scouting License',
    'company_name': 'Company Name',
    'tax_id': 'Tax ID / GST',
    'website': 'Website',
    'bio': 'Bio',
  };

  /// Role-specific keys required on the role profile step.
  List<String> _requiredKeysForRoleProfile() {
    switch (_role) {
      case SportXRole.athlete:
        return ['sport_id', 'skill_level', 'city_id'];
      case SportXRole.coach:
        return ['sport_id', 'skill_level', 'city_id', 'coaching_license'];
      case SportXRole.academy:
        return ['organization_name', 'academy_license', 'city_id'];
      case SportXRole.organizer:
        return ['organization_name', 'tax_id', 'website', 'city_id'];
      case SportXRole.scout:
        return ['scouting_license', 'city_id'];
      case SportXRole.sponsor:
        return ['company_name', 'tax_id', 'website', 'city_id'];
      case SportXRole.admin:
        return [];
    }
  }

  /// Mandatory fields still missing for the current step.
  /// Returns an empty list when the step may be completed.
  List<String> validateCurrentStep() {
    final step = state.currentStep;
    if (step == OnboardingStep.complete) return const [];

    final keys = <String>[
      ...?_requiredKeys[step],
      if (step == OnboardingStep.roleProfile) ..._requiredKeysForRoleProfile(),
    ];

    final missing = <String>[];
    for (final key in keys) {
      final value = state.formData[key];
      if (value == null || value.toString().trim().isEmpty) {
        missing.add(_keyLabels[key] ?? key);
      }
    }
    return missing;
  }


  /// Updates form data for current step
  void updateFormData(Map<String, dynamic> data) {
    state = state.copyWith(formData: {...state.formData, ...data});
  }

  /// Marks current step complete and advances to next
  void completeStep() {
    final steps = stepsForRole;
    final currentIndex = steps.indexOf(state.currentStep);
    final newCompleted = {...state.completedSteps, state.currentStep};
    
    if (currentIndex + 1 < steps.length) {
      state = state.copyWith(
        currentStep: steps[currentIndex + 1],
        completedSteps: newCompleted,
      );
    } else {
      state = state.copyWith(
        currentStep: OnboardingStep.complete,
        completedSteps: newCompleted,
      );
    }
  }

  /// Goes back to previous step
  void previousStep() {
    final steps = stepsForRole;
    final currentIndex = steps.indexOf(state.currentStep);
    if (currentIndex > 0) {
      state = state.copyWith(currentStep: steps[currentIndex - 1]);
    }
  }

  /// Jumps to a specific step
  void goToStep(OnboardingStep step) {
    if (stepsForRole.contains(step)) {
      state = state.copyWith(currentStep: step);
    }
  }

  /// Submits all onboarding data to backend
  Future<bool> submit() async {
    try {
      final endpoint = _onboardingEndpointForRole(_role);
      await _dio.post(endpoint, data: state.formData);
      state = state.copyWith(currentStep: OnboardingStep.complete);
      return true;
    } on DioException {
      // Error handling is done by the UI layer.
      rethrow;
    }
  }

  String _onboardingEndpointForRole(SportXRole role) {
    switch (role) {
      case SportXRole.athlete:
        return '/onboarding/athlete';
      case SportXRole.coach:
        return '/onboarding/coach';
      case SportXRole.academy:
        return '/onboarding/academy';
      case SportXRole.organizer:
        return '/onboarding/organizer';
      case SportXRole.scout:
        return '/onboarding/scout';
      case SportXRole.sponsor:
        return '/onboarding/sponsor';
      case SportXRole.admin:
        return '/onboarding/admin';
    }
  }

  void reset() {
    state = OnboardingProgress();
  }
}

/// Provider factory for role-specific onboarding
final multiStepOnboardingProvider = StateNotifierProvider.family<MultiStepOnboardingNotifier, OnboardingProgress, SportXRole>((ref, role) {
  return MultiStepOnboardingNotifier(ref.watch(dioProvider), role);
});

/// Provider to get current role's onboarding steps
final onboardingStepsProvider = Provider.family<List<OnboardingStep>, SportXRole>((ref, role) {
  return onboardingStepsForRole(role);
});

/// Returns the onboarding step list for a role. Admin has no onboarding flow.
List<OnboardingStep> onboardingStepsForRole(SportXRole role) {
  switch (role) {
    case SportXRole.athlete:
      return [
        OnboardingStep.coreIdentity,
        OnboardingStep.roleProfile,
        OnboardingStep.media,
        OnboardingStep.verification,
        OnboardingStep.preferences,
      ];
    case SportXRole.coach:
      return [
        OnboardingStep.coreIdentity,
        OnboardingStep.roleProfile,
        OnboardingStep.media,
        OnboardingStep.verification,
        OnboardingStep.preferences,
      ];
    case SportXRole.academy:
      return [
        OnboardingStep.coreIdentity,
        OnboardingStep.roleProfile,
        OnboardingStep.media,
        OnboardingStep.preferences,
      ];
    case SportXRole.organizer:
      return [
        OnboardingStep.coreIdentity,
        OnboardingStep.roleProfile,
        OnboardingStep.media,
        OnboardingStep.preferences,
      ];
    case SportXRole.scout:
      return [
        OnboardingStep.coreIdentity,
        OnboardingStep.roleProfile,
        OnboardingStep.media,
        OnboardingStep.verification,
        OnboardingStep.preferences,
      ];
    case SportXRole.sponsor:
      return [
        OnboardingStep.coreIdentity,
        OnboardingStep.roleProfile,
        OnboardingStep.media,
        OnboardingStep.preferences,
      ];
    case SportXRole.admin:
      return [];
  }
}

/// Labels for each step
final Map<OnboardingStep, ({String title, String subtitle, IconData icon})> onboardingStepInfo = {
  OnboardingStep.coreIdentity: (
    title: 'Core Identity',
    subtitle: 'Name, date of birth, gender, phone',
    icon: LucideIcons.user,
  ),
  OnboardingStep.roleProfile: (
    title: 'Your Profile',
    subtitle: 'Role-specific details',
    icon: LucideIcons.idCard,
  ),
  OnboardingStep.media: (
    title: 'Photos & Media',
    subtitle: 'Profile photo, cover photo, highlights',
    icon: LucideIcons.camera,
  ),
  OnboardingStep.verification: (
    title: 'Verification',
    subtitle: 'Submit ID for verified badge',
    icon: LucideIcons.badgeCheck,
  ),
  OnboardingStep.preferences: (
    title: 'Preferences',
    subtitle: 'Notifications, privacy, interests',
    icon: LucideIcons.settings,
  ),
  OnboardingStep.complete: (
    title: 'All Done!',
    subtitle: 'Welcome to SportX',
    icon: LucideIcons.checkCircle,
  ),
};