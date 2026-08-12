import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/theme/colors.dart';

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

  Future<void> _loadCurrentProfile() async {
    try {
      final resp = await ref.read(dioProvider).get('/me/profile');
      final d = resp.data['data'] as Map<String, dynamic>?;
      if (d != null) {
        _profile = d;
        _existing = (d['achievements'] as List? ?? const [])
            .map((e) => <String, dynamic>{'text': (e as Map)['text'] ?? ''})
            .toList();
      }
    } catch (_) {}
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  Future<void> _saveAchievement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final dio = ref.read(dioProvider);
      final allAchievements = <Map<String, dynamic>>[
        ..._existing,
        {
          'text': _titleController.text.trim() +
              (_descriptionController.text.trim().isNotEmpty
                  ? ' — ${_descriptionController.text.trim()} (${_selectedYear})'
                  : ' ($_selectedYear)'),
        },
      ];

      final formData = FormData.fromMap({
        'full_name': _profile['full_name'] ?? _profile['name'] ?? '',
        'date_of_birth': _profile['date_of_birth'] ?? '',
        'gender': _profile['gender'] ?? '',
        'skill_level': _profile['skill_level'] ?? '',
        'city_id': _profile['city_id'],
        'achievements': allAchievements,
      });

      await dio.put('/me/profile', data: formData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Achievement added successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add achievement: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                value: _selectedYear,
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
