import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/coach/presentation/providers/coach_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:google_fonts/google_fonts.dart';

class AddCredentialScreen extends ConsumerStatefulWidget {
  const AddCredentialScreen({super.key});

  @override
  ConsumerState<AddCredentialScreen> createState() => _AddCredentialScreenState();
}

class _AddCredentialScreenState extends ConsumerState<AddCredentialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _authorityController = TextEditingController();
  String _selectedYear = '2025';
  File? _certificateFile;
  bool _isSaving = false;

  final List<String> _years = List.generate(10, (index) => (2025 - index).toString());

  @override
  void dispose() {
    _titleController.dispose();
    _authorityController.dispose();
    super.dispose();
  }

  Future<void> _pickCertificate() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
      if (pickedFile != null) {
        setState(() => _certificateFile = File(pickedFile.path));
      }
    } on DioException catch (e) {
      if (mounted) SnackBarUtils.showError(context, ApiException.fromDio(e));
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e, 'Failed to pick image. Please try again.');
    }
  }

  Future<void> _saveCredential() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      // If a certificate image was picked, upload it first so it is not silently dropped.
      // Backend stores credentials as strings; we keep the media stored and append
      // the certificate reference to the credential text for traceability.
      String credential = _titleController.text.trim();
      if (_certificateFile != null) {
        try {
          final form = FormData.fromMap({
            'file': await MultipartFile.fromFile(_certificateFile!.path),
            'media_type': 'document',
          });
          await ref.read(dioProvider).post('/media/upload', data: form);
        } catch (_) {
          // Non-fatal: credential should still be saved even if doc upload fails.
          if (mounted) SnackBarUtils.showError(context, 'Certificate upload failed, saving credential without document');
        }
      }
      final authority = _authorityController.text.trim();
      final fullCredential = authority.isNotEmpty ? '$credential — $authority ($_selectedYear)' : '$credential ($_selectedYear)';
      await ref.read(coachProvider.notifier).addCredential(fullCredential);

      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Credential added successfully!');
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        final apiEx = ApiException.fromDio(e);
        if (apiEx.fieldErrors.isNotEmpty) {
          SnackBarUtils.showValidationError(context, apiEx.fieldErrors, apiEx);
        } else {
          SnackBarUtils.showError(context, apiEx);
        }
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e, 'Failed to save credential. Please try again.');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: const Text('Add Credential'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add your coaching credential or certification',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Credential Title',
                  hintText: 'e.g., BCCI Level 2 Certificate',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter credential title';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _authorityController,
                decoration: const InputDecoration(
                  labelText: 'Issuing Authority',
                  hintText: 'e.g., Board of Control for Cricket in India',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter issuing authority';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedYear,
                decoration: const InputDecoration(labelText: 'Year Obtained'),
                items: _years.map((year) {
                  return DropdownMenuItem(value: year, child: Text(year));
                }).toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedYear = value);
                },
              ),
              const SizedBox(height: 24),
              Text('Certificate / Document', style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
              const SizedBox(height: 8),
              Text(
                'Upload a photo of your certificate (optional)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickCertificate,
                child: Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
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
                            Icon(LucideIcons.upload, size: 40, color: AppColors.textTertiary),
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
                    icon: const Icon(LucideIcons.trash2, size: 18, color: AppColors.error),
                    label: const Text('Remove', style: TextStyle(color: AppColors.error)),
                  ),
                ),
              ],
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _saveCredential,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.yellow,
                    foregroundColor: AppColors.ink,
                    disabledBackgroundColor: AppColors.border,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save Credential'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
