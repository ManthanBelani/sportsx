import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/theme/colors.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Aryan Patel');
  final _bioController = TextEditingController(text: 'Passionate cricketer from Ahmedabad. Looking for opportunities to grow and learn from the best in the game. Dedicated to improving my skills every day.');
  final _locationController = TextEditingController(text: 'Ahmedabad, Gujarat');
  
  // Physical attributes
  final _heightController = TextEditingController(text: '165');
  final _weightController = TextEditingController(text: '58');
  
  String _selectedSport = 'Cricket';
  String _dominantSide = 'Right';
  
  File? _avatarFile;
  bool _isSaving = false;

  // Required-by-backend fields. These are loaded from the current profile and
  // re-sent on save (PUT /me/profile validates them as required every time).
  String _dob = '';
  String _gender = '';
  String _skillLevel = '';
  int? _cityId;

  final List<String> _sports = [
    'Cricket',
    'Football',
    'Badminton',
    'Tennis',
    'Hockey',
    'Kabaddi',
    'Athletics',
    'Swimming',
    'Boxing',
    'Wrestling',
  ];
  
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
          _skillLevel = (d['skill_level'] ?? '') as String;
          _cityId = d['city_id'] as int?;
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

  Future<void> _pickAvatar() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() => _avatarFile = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dio = ref.read(dioProvider);
      final formData = FormData.fromMap({
        'full_name': _nameController.text.trim(),
        'date_of_birth': _dob,
        'gender': _gender,
        'skill_level': _skillLevel,
        'city_id': _cityId,
        'experience': _bioController.text.trim(),
        if (_avatarFile != null) 'profile_photo': await MultipartFile.fromFile(
          _avatarFile!.path,
          filename: 'avatar.jpg',
        ),
      });

      await dio.put('/me/profile', data: formData);

      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 80,
        leading: GestureDetector(
          onTap: () => context.pop(),
          child: const Center(
            child: Text('Cancel', style: TextStyle(fontSize: 15, color: AppColors.textSecondary)),
          ),
        ),
        title: const Text('Edit Profile', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
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
              _buildBioField(),
              _buildDropdown('Primary Sport', _selectedSport, _sports, (val) => setState(() => _selectedSport = val!)),
              _buildTextField('Location', _locationController),
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
                colors: [AppColors.primary, Color(0xFF0d47a1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            alignment: Alignment.center,
            child: _avatarFile != null
                ? ClipOval(child: Image.file(_avatarFile!, width: 96, height: 96, fit: BoxFit.cover))
                : const Icon(LucideIcons.user, size: 40, color: Colors.white),
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
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
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
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
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
            value: value,
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
            onChanged: onChanged,
            icon: const Icon(LucideIcons.chevronDown, size: 20),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
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
