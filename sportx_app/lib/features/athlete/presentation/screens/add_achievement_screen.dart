import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class AddAchievementScreen extends ConsumerStatefulWidget {
  const AddAchievementScreen({super.key});

  @override
  ConsumerState<AddAchievementScreen> createState() => _AddAchievementScreenState();
}

class _AddAchievementScreenState extends ConsumerState<AddAchievementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedYear = '2025';
  File? _certificateFile;
  bool _isSaving = false;

  // Required-by-backend profile fields (loaded + re-sent on save).
  Map<String, dynamic> _profile = {};
  List<Map<String, dynamic>> _existing = [];
  bool _isLoadingProfile = true;

  final List<String> _years = List.generate(10, (index) => (2025 - index).toString());

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCurrentProfile();
  }

  String get _role => ref.read(authProvider).user?.role ?? 'athlete';
  bool get _isCoach => _role == 'coach';

  Future<void> _loadCurrentProfile() async {
    setState(() => _isLoadingProfile = true);
    try {
      try {
        final resp = await ref.read(dioProvider).get('/me/profile');
        final d = resp.data['data'] as Map<String, dynamic>?;
        if (d != null && d.isNotEmpty) {
          _profile = d;
          _existing = (d['achievements'] as List? ?? const [])
              .map((e) {
                if (e is Map) return <String, dynamic>{'text': (e['text'] ?? e['title'] ?? '').toString()};
                return <String, dynamic>{'text': e.toString()};
              })
              .toList();
          return;
        }
      } catch (_) {}
      // Fallback for coach if /me/profile returns null
      if (_isCoach) {
        try {
          final resp = await ref.read(dioProvider).get('/me/coach-profile');
          final d = resp.data['data'] as Map<String, dynamic>?;
          if (d != null) {
            _profile = d;
            _existing = (d['achievements'] as List? ?? const [])
                .map((e) {
                  if (e is Map) return <String, dynamic>{'text': (e['text'] ?? e['title'] ?? '').toString()};
                  return <String, dynamic>{'text': e.toString()};
                })
                .toList();
          }
        } catch (_) {}
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _pickCertificate() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() => _certificateFile = File(pickedFile.path));
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e);
      }
    }
  }

  Future<void> _saveAchievement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dio = ref.read(dioProvider);
      // Upload certificate first if present so it is not silently dropped
      if (_certificateFile != null) {
        try {
          final certForm = FormData.fromMap({
            'file': await MultipartFile.fromFile(_certificateFile!.path),
            'media_type': 'document',
          });
          await dio.post('/media/upload', data: certForm);
        } catch (_) {
          if (mounted) SnackBarUtils.showError(context, 'Certificate upload failed, saving achievement without document');
        }
      }
      final allAchievements = <Map<String, dynamic>>[
        ..._existing,
        {
          'text': _titleController.text.trim() +
              (_descriptionController.text.trim().isNotEmpty
                  ? ' — ${_descriptionController.text.trim()} ($_selectedYear)'
                  : ' ($_selectedYear)'),
          'title': _titleController.text.trim(),
          'description': _descriptionController.text.trim(),
          'year': _selectedYear,
        },
      ];

      // PUT /me/profile now handles both athlete and coach achievements.
      // For athlete, required fields must be re-sent; for coach, achievements-only is sufficient.
      if (_isCoach) {
        await dio.put('/me/profile', data: {
          'achievements': allAchievements,
        });
      } else {
        await dio.put('/me/profile', data: {
          'full_name': _profile['full_name'] ?? _profile['name'] ?? '',
          'date_of_birth': _profile['date_of_birth'] ?? '',
          'gender': _profile['gender'] ?? '',
          'skill_level': _profile['skill_level'] ?? '',
          'city_id': _profile['city_id'],
          'achievements': allAchievements,
        });
      }

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Achievement added successfully!');
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackBarUtils.showError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingProfile) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Achievement')),
        body: const AddAchievementSkeleton(),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Achievement'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add your sports achievement',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Achievement Title',
                  hintText: 'e.g., State-level U-14 selection',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter achievement title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Describe your achievement...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedYear,
                decoration: const InputDecoration(labelText: 'Year'),
                items: _years.map((year) {
                  return DropdownMenuItem(value: year, child: Text(year));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedYear = value);
                },
              ),
              const SizedBox(height: 24),
              Text('Certificate / Photo', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Upload a certificate or photo as proof (optional)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickCertificate,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _certificateFile != null ? AppColors.primary : AppColors.border,
                      width: _certificateFile != null ? 2 : 1,
                    ),
                  ),
                  child: _certificateFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(11),
                          child: Image.file(_certificateFile!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined, size: 40, color: AppColors.textTertiary),
                            const SizedBox(height: 8),
                            Text(
                              'Tap to upload',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'JPG, PNG up to 5MB',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                ),
              ),
              if (_certificateFile != null) ...[
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () => setState(() => _certificateFile = null),
                    icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                    label: const Text('Remove', style: TextStyle(color: AppColors.error)),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveAchievement,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Add Achievement'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
