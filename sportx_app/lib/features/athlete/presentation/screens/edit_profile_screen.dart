import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/shared/presentation/widgets/media_picker.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _locationController = TextEditingController();

  // Physical attributes
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  
  int? _selectedSportId;
  String? _selectedSportName;
  String _dominantSide = 'Right';
  int? _selectedAgeGroupId;
  String? _selectedGender;
  final List<String> _genders = ['male', 'female', 'other', 'prefer_not_to_say'];
  final List<String> _skillLevels = ['beginner', 'intermediate', 'advanced', 'competitive'];
  
  File? _avatarFile;
  String? _existingAvatarUrl;
  bool _isSaving = false;

  // Required-by-backend fields. These are loaded from the current profile and
  // re-sent on save (PUT /me/profile validates them as required every time).
  String _dob = '';
  String _gender = '';
  String _skillLevel = '';
  int? _cityId;
  int? _photoMediaId;

  final List<String> _dominantSides = ['Right', 'Left', 'Both'];

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final resp = await ref.read(dioProvider).get('/me/profile');
      final d = resp.data['data'] as Map<String, dynamic>?;
      if (d != null && mounted) {
        setState(() {
          _nameController.text = (d['full_name'] ?? d['name'] ?? '') as String;
          _dob = (d['date_of_birth'] ?? '') as String;
          _gender = (d['gender'] ?? '') as String;
          _selectedGender = _genders.contains(_gender) ? _gender : null;
          _skillLevel = (d['skill_level'] ?? '') as String;
          _cityId = d['city_id'] as int?;
          _selectedAgeGroupId = d['age_group_id'] as int?;
          _bioController.text = (d['experience'] ?? d['bio'] ?? _bioController.text) as String;
          final photo = d['photo'] as Map<String, dynamic>?;
          _existingAvatarUrl = photo?['url'] as String?;
          _photoMediaId = photo?['id'] as int?;
          final city = d['city'] as Map<String, dynamic>?;
          if (city?['name'] != null) {
            _locationController.text = (city?['name'] as String?)!;
          }
          // Load sport
          final sport = d['sport'] as Map<String, dynamic>?;
          if (sport != null) {
            _selectedSportId = sport['id'] as int?;
            _selectedSportName = sport['name'] as String?;
          } else {
            _selectedSportId = d['sport_id'] as int?;
          }
          // Load physical attributes
          _heightController.text = (d['height'] ?? '').toString();
          _weightController.text = (d['weight'] ?? '').toString();
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  bool _pickingAvatar = false;
  Future<void> _pickAvatar() async {
    if (_pickingAvatar) return;
    setState(() => _pickingAvatar = true);
    try {
      final media = await pickAndUploadMedia(context, ref, mediaType: 'photo');
      if (media == null) return;
      setState(() {
        _avatarFile = media.file;
        _photoMediaId = media.mediaId;
      });
    } finally {
      if (mounted) setState(() => _pickingAvatar = false);
    }
  }

  Future<void> _pickDob() async {
    final initial = DateTime.tryParse(_dob) ?? DateTime(2010);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dob = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dio = ref.read(dioProvider);

      // Avatar (if newly picked) was already uploaded in _pickAvatar; just
      // attach the resulting media id to the profile.
      await dio.put('/me/profile', data: {
        'full_name': _nameController.text.trim(),
        'date_of_birth': _dob,
        'gender': _selectedGender ?? _gender,
        'skill_level': _skillLevel,
        'city_id': _cityId,
        'age_group_id': _selectedAgeGroupId,
        'experience': _bioController.text.trim(),
        'position': _dominantSide == 'Left' ? 'Left-hand' : 'Right-hand',
        'height': _heightController.text.trim().isNotEmpty ? double.tryParse(_heightController.text.trim()) : null,
        'weight': _weightController.text.trim().isNotEmpty ? double.tryParse(_weightController.text.trim()) : null,
        if (_photoMediaId != null) 'photo_media_id': _photoMediaId,
      });

      // Wire PUT /me/profile/sports (many-to-many) — backend expects {sports:[id]} separately
      if (_selectedSportId != null) {
        try {
          await dio.put('/me/profile/sports', data: {'sports': [_selectedSportId]});
        } catch (_) {
          // Non-fatal: main profile already saved
        }
      }

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Profile updated');
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, ApiException.fromDio(e));
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e, 'Failed to save profile. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        leadingWidth: 80,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Center(
            child: Text('Cancel', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ),
        ),
        title: Text('Edit Profile',
            style: GoogleFonts.sora(
                fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        centerTitle: true,
        actions: [
          GestureDetector(
            onTap: _isSaving ? null : _saveProfile,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 20),
                child: _isSaving
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Save', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildAvatarSection(),
              const SizedBox(height: 24),
              _buildSectionTitle('Basic Information'),
              _buildTextField('Full Name', _nameController),
              _buildDobField(),
              _buildDropdown('Gender', _selectedGender ?? '', [..._genders], (val) => setState(() { _selectedGender = val; _gender = val ?? ''; })),
              _buildBioField(),
              _buildSportDropdown(meta),
              _buildCityDropdown(meta),
              _buildAgeGroupDropdown(meta),
              _buildSkillLevelDropdown(),
              const SizedBox(height: 24),
              _buildSectionTitle('Physical Attributes'),
              Row(
                children: [
                  Expanded(child: _buildTextField('Height (cm)', _heightController, isNumber: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildTextField('Weight (kg)', _weightController, isNumber: true)),
                ],
              ),
              _buildDropdown('Dominant Hand/Foot', _dominantSide, _dominantSides, (val) => setState(() => _dominantSide = val!)),
              const SizedBox(height: 24),
              _buildSectionTitle('Social Links'),
              SizedBox(
                width: double.infinity,
                child: SecondaryButton(
                  label: 'Manage Social Links',
                  icon: LucideIcons.share2,
                  onPressed: () => context.push('/social-links'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Center(
      child: Column(
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.yellow, AppColors.ctaDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: _avatarFile != null
                ? ClipOval(child: Image.file(_avatarFile!, width: 96, height: 96, fit: BoxFit.cover))
                : (_existingAvatarUrl != null && _existingAvatarUrl!.isNotEmpty
                    ? ClipOval(
                        child: Image.network(
                          _absoluteUrl(_existingAvatarUrl!),
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(LucideIcons.user, size: 40, color: AppColors.ink),
                        ),
                      )
                    : const Icon(LucideIcons.user, size: 40, color: AppColors.ink)),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickAvatar,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.camera, size: 16, color: AppColors.primary),
                SizedBox(width: 6),
                Text('Change Photo', style: TextStyle(fontSize: 14, color: AppColors.primary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5),
      ),
    );
  }

  String _absoluteUrl(String url) => MediaUtils.resolveUrl(url);

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBioField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Bio', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          TextFormField(
            controller: _bioController,
            maxLines: 4,
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: value,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
            icon: const Icon(LucideIcons.chevronDown, size: 20),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDobField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Date of Birth', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: _pickDob,
            child: AbsorbPointer(
              child: TextFormField(
                controller: TextEditingController(text: _dob.isEmpty ? '' : _dob),
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'YYYY-MM-DD',
                  filled: true,
                  fillColor: Colors.white,
                  suffixIcon: const Icon(LucideIcons.calendar, size: 18, color: AppColors.textSecondary),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.border)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.primary)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => _dob.isEmpty ? 'Required' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityDropdown(MetaState meta) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('City', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _cityId,
            items: meta.cities.map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name}, ${c.state}'))).toList(),
            onChanged: (v) => setState(() => _cityId = v),
            hint: const Text('Select City'),
            icon: const Icon(LucideIcons.chevronDown, size: 20),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.primary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            validator: (v) => v == null ? 'Required' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildAgeGroupDropdown(MetaState meta) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Age Group', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _selectedAgeGroupId,
            items: meta.ageGroups.map((a) => DropdownMenuItem(value: a.id, child: Text(a.label))).toList(),
            onChanged: (v) => setState(() => _selectedAgeGroupId = v),
            hint: const Text('Select Age Group'),
            icon: const Icon(LucideIcons.chevronDown, size: 20),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.primary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkillLevelDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Skill Level', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: _skillLevels.contains(_skillLevel) ? _skillLevel : null,
            items: _skillLevels.map((s) => DropdownMenuItem(value: s, child: Text(s[0].toUpperCase() + s.substring(1)))).toList(),
            onChanged: (v) => setState(() => _skillLevel = v ?? ''),
            hint: const Text('Select Skill Level'),
            icon: const Icon(LucideIcons.chevronDown, size: 20),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.border)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(13), borderSide: const BorderSide(color: AppColors.primary)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSportDropdown(MetaState meta) {
    final sportList = meta.sports;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Primary Sport', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          DropdownButtonFormField<int>(
            initialValue: _selectedSportId,
            items: sportList.map((sport) {
              return DropdownMenuItem(
                value: sport.id,
                child: Text(sport.name),
              );
            }).toList(),
            onChanged: (val) => setState(() {
              _selectedSportId = val;
              _selectedSportName = sportList.where((s) => s.id == val).firstOrNull?.name;
            }),
            hint: Text(_selectedSportName ?? 'Select Sport'),
            icon: const Icon(LucideIcons.chevronDown, size: 20),
            decoration: InputDecoration(
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(13),
                borderSide: const BorderSide(color: AppColors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
