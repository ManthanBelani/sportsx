import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/media_picker.dart';
import 'package:sportx_app/features/coach/presentation/providers/coach_provider.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/models/coach.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
class CoachProfileEditScreen extends ConsumerStatefulWidget {
  final bool isTabContent;

  const CoachProfileEditScreen({super.key, this.isTabContent = false});

  @override
  ConsumerState<CoachProfileEditScreen> createState() => _CoachProfileEditScreenState();
}

class _CoachProfileEditScreenState extends ConsumerState<CoachProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _initialized = false;
  bool _saving = false;
  bool _uploadingPhoto = false;
  int? _uploadedPhotoMediaId;
  String? _uploadedPhotoUrl;

  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _headlineController = TextEditingController();
  final _locationController = TextEditingController();
  final _bioController = TextEditingController();
  final _feePerSessionController = TextEditingController();
  final _feeMonthlyController = TextEditingController();
  final _feeQuarterlyController = TextEditingController();
  final _contactController = TextEditingController();
  final _qualificationController = TextEditingController();
  final _certificationController = TextEditingController();
  final _languageController = TextEditingController();

  int? _sportId;
  int? _cityId;
  String? _experience;
  bool _personalCoaching = false;
  List<String> _certifications = [];
  List<String> _languages = [];
  Map<String, List<String>> _availability = {};

  final List<String> _experienceOptions = [
    '1-3 years',
    '3-5 years',
    '5-10 years',
    '10+ years',
  ];

  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> _timeSlots = ['6AM', '8AM', '10AM', '12PM', '2PM', '4PM', '6PM', '8PM'];

  @override
  void initState() {
    super.initState();
    for (var day in _days) {
      _availability[day] = [];
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _headlineController.dispose();
    _locationController.dispose();
    _bioController.dispose();
    _feePerSessionController.dispose();
    _feeMonthlyController.dispose();
    _feeQuarterlyController.dispose();
    _contactController.dispose();
    _qualificationController.dispose();
    _certificationController.dispose();
    _languageController.dispose();
    super.dispose();
  }

  void _initializeFromProfile(Coach profile) {
    if (_initialized) return;
    _initialized = true;

    final parts = profile.fullName.split(' ');
    _firstNameController.text = parts.isNotEmpty ? parts.first : '';
    _lastNameController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    _headlineController.text = profile.headline ?? '';
    _locationController.text = profile.location ?? '';
    _bioController.text = profile.bio ?? '';
    _contactController.text = profile.contactNumber ?? '';
    _qualificationController.text = profile.specialization ?? '';

    _experience = profile.experience;
    _personalCoaching = profile.personalCoaching;
    _certifications = profile.certifications ?? [];
    _languages = profile.languages ?? [];

    if (profile.feePerSession != null) {
      _feePerSessionController.text = profile.feePerSession!.toStringAsFixed(0);
    } else if (profile.feeStructure != null) {
      _feePerSessionController.text = profile.feeStructure!;
    }
    if (profile.feeMonthly != null) {
      _feeMonthlyController.text = profile.feeMonthly!.toStringAsFixed(0);
    }
    if (profile.feeQuarterly != null) {
      _feeQuarterlyController.text = profile.feeQuarterly!.toStringAsFixed(0);
    }

    _sportId = profile.sportId;
    _cityId = profile.cityId;

    if (profile.availability != null) {
      _availability = Map<String, List<String>>.from(profile.availability!);
    }
  }



  void _addCertification() {
    final text = _certificationController.text.trim();
    if (text.isNotEmpty && !_certifications.contains(text)) {
      setState(() {
        _certifications.add(text);
        _certificationController.clear();
      });
    }
  }

  void _removeCertification(String cert) {
    setState(() => _certifications.remove(cert));
  }

  void _addLanguage() {
    final text = _languageController.text.trim();
    if (text.isNotEmpty && !_languages.contains(text)) {
      setState(() {
        _languages.add(text);
        _languageController.clear();
      });
    }
  }

  void _removeLanguage(String lang) {
    setState(() => _languages.remove(lang));
  }

  void _toggleTimeSlot(String day, String slot) {
    setState(() {
      _availability[day] ??= [];
      if (_availability[day]!.contains(slot)) {
        _availability[day]!.remove(slot);
      } else {
        _availability[day]!.add(slot);
      }
    });
  }

  Future<void> _pickAndUploadPhoto() async {
    if (_uploadingPhoto) return;
    setState(() => _uploadingPhoto = true);
    try {
      final media = await pickAndUploadMedia(context, ref, mediaType: 'photo');
      if (media == null) return;
      // Optimistic local preview
      setState(() {
        _uploadedPhotoMediaId = media.mediaId;
        _uploadedPhotoUrl = MediaUtils.resolveUrl(media.url);
      });
      // Immediately persist so photo syncs across dashboard/home without requiring Save
      try {
        await ref.read(dioProvider).put('/me/coach-profile', data: {'photo_media_id': media.mediaId});
        await ref.read(coachProvider.notifier).loadCoachProfile();
        // Clear local override to rely on authoritative provider value (prevents stale cache)
        if (mounted) {
          setState(() {
            _uploadedPhotoMediaId = null;
            _uploadedPhotoUrl = null;
          });
          SnackBarUtils.showSuccess(context, 'Profile photo updated');
        }
      } catch (_) {
        // Keep local override so Save Changes can still persist it
        if (mounted) SnackBarUtils.showSuccess(context, 'Photo selected — tap Save to persist');
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, 'Failed to upload photo');
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);
    try {
      final feePerSession = double.tryParse(_feePerSessionController.text.trim());
      final feeMonthly = double.tryParse(_feeMonthlyController.text.trim());
      final feeQuarterly = double.tryParse(_feeQuarterlyController.text.trim());

      final data = <String, dynamic>{
        'full_name': '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}',
        'headline': _headlineController.text.trim(),
        'location': _locationController.text.trim(),
        'bio': _bioController.text.trim(),
        'contact_number': _contactController.text.trim(),
        'qualification': _qualificationController.text.trim(),
        'experience': _experience ?? '',
        'personal_coaching': _personalCoaching,
        if (_sportId != null) 'sport_id': _sportId,
        if (_cityId != null) 'city_id': _cityId,
        'fee_per_session': ?feePerSession,
        'fee_monthly': ?feeMonthly,
        'fee_quarterly': ?feeQuarterly,
        'availability': _availability,
        if (_certifications.isNotEmpty) 'certifications': _certifications,
        if (_languages.isNotEmpty) 'languages': _languages,
        if (_uploadedPhotoMediaId != null) 'photo_media_id': _uploadedPhotoMediaId,
      };

      await ref.read(dioProvider).put('/me/coach-profile', data: data);
      await ref.read(coachProvider.notifier).loadCoachProfile();
      // Clear optimistic photo override after successful save
      _uploadedPhotoMediaId = null;
      _uploadedPhotoUrl = null;

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Profile updated successfully');
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final coachState = ref.watch(coachProvider);
    if (!_initialized) {
      final profile = coachState.coachProfile;
      if (profile != null) {
        _initializeFromProfile(profile);
      }
    }

    // Show skeleton while initial load is in progress and form not yet initialized
    if (!_initialized && coachState.isLoading) {
      final skeleton = const CoachEditFormSkeleton();
      if (widget.isTabContent) return skeleton;
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
            onPressed: () => context.pop(),
          ),
          title: const Text('Edit Coach Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        ),
        body: skeleton,
      );
    }

    if (widget.isTabContent) {
      return _buildFormContent();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Edit Coach Profile',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
      ),
      body: _buildFormContent(),
    );
  }

  Widget _buildFormContent() {
    final meta = ref.watch(metaProvider);
    final profile = ref.watch(coachProvider).coachProfile;

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
            _buildProfilePhoto(profile),
            const SizedBox(height: 24),
            const Text(
              'Personal Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _buildTextField('First Name', _firstNameController, validator: _required)),
                const SizedBox(width: 12),
                Expanded(child: _buildTextField('Last Name', _lastNameController, validator: _required)),
              ],
            ),
            const SizedBox(height: 16),
            _buildTextField('Headline', _headlineController, hint: 'e.g. Professional Football Coach | AIFF C License'),
            const SizedBox(height: 16),
            _buildTextField('Location/Area', _locationController, hint: 'e.g. Indiranagar, Bangalore'),
            const SizedBox(height: 16),
            _buildTextField('Contact Number', _contactController, keyboardType: TextInputType.phone, validator: _required),
            const SizedBox(height: 16),

            const Text(
              'Professional Details',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            _buildDropdownFieldInt('Primary Sport', _sportId, meta.sports.map((s) => _SelectItem(s.id, s.name)).toList(), (v) => setState(() => _sportId = v)),
            const SizedBox(height: 16),
            _buildDropdownFieldInt('City', _cityId, meta.cities.map((c) => _SelectItem(c.id, '${c.name}, ${c.state}')).toList(), (v) => setState(() => _cityId = v)),
            const SizedBox(height: 16),
            _buildDropdownField('Experience', _experience, _experienceOptions, (v) => setState(() => _experience = v)),
            const SizedBox(height: 16),
            _buildTextField('Qualification/Specialization', _qualificationController, hint: 'e.g. BCCI Level-A certified'),

            const SizedBox(height: 16),
            const Text('Certifications', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _certificationController, decoration: _inputDecoration('Add certification'))),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addCertification,
                  icon: const Icon(LucideIcons.plus, color: AppColors.primary),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary.withValues(alpha: 0.1)),
                ),
              ],
            ),
            if (_certifications.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _certifications.map((cert) {
                  return Chip(
                    label: Text(cert, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    deleteIcon: const Icon(LucideIcons.x, size: 14),
                    onDeleted: () => _removeCertification(cert),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 16),
            const Text('Languages Spoken', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: TextField(controller: _languageController, decoration: _inputDecoration('Add language'))),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _addLanguage,
                  icon: const Icon(LucideIcons.plus, color: AppColors.primary),
                  style: IconButton.styleFrom(backgroundColor: AppColors.primary.withValues(alpha: 0.1)),
                ),
              ],
            ),
            if (_languages.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _languages.map((lang) {
                  return Chip(
                    label: Text(lang, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
                    deleteIcon: const Icon(LucideIcons.x, size: 14),
                    onDeleted: () => _removeLanguage(lang),
                    backgroundColor: AppColors.surface,
                    side: const BorderSide(color: AppColors.border),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Personal Coaching', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text('I offer one-on-one coaching', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _personalCoaching,
                    onChanged: (v) => setState(() => _personalCoaching = v),
                    activeThumbColor: AppColors.primary,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text(
              'Fee Structure',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildFeeRow('Per Session (90 min)', _feePerSessionController),
                  const Divider(color: AppColors.border),
                  _buildFeeRow('Monthly (8 sessions)', _feeMonthlyController),
                  const Divider(color: AppColors.border),
                  _buildFeeRow('Quarterly (24 sessions)', _feeQuarterlyController),
                ],
              ),
            ),

            const SizedBox(height: 20),
            _buildTextField('Bio', _bioController, maxLines: 3, hint: 'Describe your coaching approach...'),

            const SizedBox(height: 20),
            const Text(
              'Weekly Availability',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            _buildAvailabilityGrid(),

            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Changes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(LucideIcons.logOut, size: 18),
                label: const Text('Log out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  },
);
  }

  Widget _buildProfilePhoto(Coach? profile) {
    String? photoUrl = _uploadedPhotoUrl ?? profile?.profilePhotoUrl;
    if (photoUrl != null) photoUrl = MediaUtils.resolveUrl(photoUrl);

    return Row(
      children: [
        CircleAvatar(
          key: ValueKey(photoUrl ?? 'no-photo'),
          radius: 40,
          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
          backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
          onBackgroundImageError: (_, _) {},
          child: photoUrl == null ? const Icon(LucideIcons.user, color: AppColors.primary, size: 32) : null,
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: _uploadingPhoto ? null : _pickAndUploadPhoto,
          icon: _uploadingPhoto 
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) 
              : const Icon(LucideIcons.image, size: 16),
          label: Text(_uploadingPhoto ? 'Uploading...' : 'Change Photo'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textPrimary,
            side: const BorderSide(color: AppColors.border),
            minimumSize: Size.zero,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField(String label, dynamic value, List<String> options, ValueChanged<String?> onChanged) {
    final hasValue = options.contains(value);
    final safeValue = hasValue ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: safeValue as String?,
          decoration: InputDecoration(
            hintText: 'Select $label',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
          ),
          isExpanded: true,
          items: options.map((o) => DropdownMenuItem<String>(value: o, child: Text(o, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDropdownFieldInt(String label, int? value, List<_SelectItem> items, ValueChanged<int?> onChanged) {
    final hasValue = items.any((i) => i.value == value);
    final safeValue = hasValue ? value : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          initialValue: safeValue,
          decoration: InputDecoration(
            hintText: 'Select $label',
            hintStyle: const TextStyle(color: AppColors.textSecondary),
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
          ),
          isExpanded: true,
          items: items.map((i) => DropdownMenuItem<int>(value: i.value, child: Text(i.label, style: const TextStyle(fontSize: 14)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildFeeRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Row(
            children: [
              Icon(LucideIcons.circleDot, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
          const Spacer(),
          SizedBox(
            width: 100,
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
              decoration: const InputDecoration(
                hintText: '₹0',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityGrid() {
    return Column(
      children: [
        Row(
          children: _days.map((day) {
            return Expanded(
              child: Center(
                child: Text(day, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        ..._timeSlots.map((slot) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              children: _days.map((day) {
                final isSelected = _availability[day]?.contains(slot) == true;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _toggleTimeSlot(day, slot),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.surface,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: isSelected ? AppColors.primary : AppColors.border),
                      ),
                      child: Center(
                        child: Text(
                          slot,
                          style: TextStyle(
                            fontSize: 9,
                            color: isSelected ? Colors.white : AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }),
      ],
    );
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
      );

  String? _required(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;
}

class _SelectItem {
  final int value;
  final String label;
  const _SelectItem(this.value, this.label);
}
