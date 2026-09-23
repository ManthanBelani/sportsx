import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/media_picker.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class SponsorOnboardingScreen extends ConsumerStatefulWidget {
  const SponsorOnboardingScreen({super.key});

  @override
  ConsumerState<SponsorOnboardingScreen> createState() => _SponsorOnboardingScreenState();
}

class _SponsorOnboardingScreenState extends ConsumerState<SponsorOnboardingScreen> {
  final _brand = TextEditingController();
  final _website = TextEditingController();
  String _category = 'Sports Apparel';
  final Set<int> _supportedSports = {};
  bool _saving = false;
  int? _logoMediaId;
  String? _logoName;
  int? _docMediaId;
  String? _docName;

  final Map<String, String> _categoryMap = {
    'Sports Apparel': 'sportswear',
    'Sports Equipment': 'equipment',
    'Beverages': 'energy_drink',
    'Financial Services': 'financial',
    'Healthcare': 'healthcare',
    'Other': 'other',
  };

  @override
  void dispose() {
    _brand.dispose();
    _website.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final media = await pickAndUploadMedia(context, ref, mediaType: 'photo');
    if (media != null && mounted) {
      setState(() {
        _logoMediaId = media.mediaId;
        _logoName = media.file.path.split('/').last;
      });
      SnackBarUtils.showSuccess(context, 'Logo uploaded');
    }
  }

  Future<void> _pickDoc() async {
    final media = await pickAndUploadMedia(context, ref, mediaType: 'document');
    if (media != null && mounted) {
      setState(() {
        _docMediaId = media.mediaId;
        _docName = media.file.path.split('/').last;
      });
      SnackBarUtils.showSuccess(context, 'Document uploaded');
    }
  }

  Future<void> _submit() async {
    if (_brand.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Brand name is required');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).post('/onboarding/sponsor', data: {
        'brand_name': _brand.text.trim(),
        'category': _categoryMap[_category] ?? _category.toLowerCase(),
        'website': _website.text.trim().isEmpty ? null : _website.text.trim(),
        if (_logoMediaId != null) 'logo_media_id': _logoMediaId,
        if (_docMediaId != null) 'verification_doc_media_id': _docMediaId,
        // sports specialization for scout-like handling; backend can ignore if not supported
        'sports': _supportedSports.toList(),
        'sports_specialization': _supportedSports.toList(),
      });
      if (mounted) {
        ref.read(authProvider.notifier).markOnboardingComplete();
        await ref.read(authProvider.notifier).refreshUser();
        if (!mounted) return;
        SnackBarUtils.showSuccess(context, 'Profile Submitted for Review');
        context.go('/sponsor-dashboard');
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e, 'Failed to save profile. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)))),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Row(children: [
              InkWell(
                onTap: () => context.pop(),
                borderRadius: BorderRadius.circular(8),
                child: Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)), alignment: Alignment.center, child: const Icon(LucideIcons.arrowLeft, size: 18, color: AppColors.textPrimary)),
              ),
              const SizedBox(width: 12),
              Text('Sponsor Setup',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ]),
          ),
          Container(margin: const EdgeInsets.only(top: 12), height: 1, color: AppColors.border),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Brand Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                const Text('Tell us about your brand', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                const SizedBox(height: 20),
                const Text('Brand Name', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextField(controller: _brand, decoration: const InputDecoration(hintText: 'e.g. Your Brand Name')),
                const SizedBox(height: 16),
                const Text('Brand Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(),
                  items: _categoryMap.keys.map((label) => DropdownMenuItem(value: label, child: Text(label, style: const TextStyle(fontSize: 14)))).toList(),
                  onChanged: (v) => setState(() => _category = v ?? _category),
                ),
                const SizedBox(height: 16),
                const Text('Sports You Support', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 8),
                if (meta.sports.isEmpty)
                  const Text('Loading sports...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: meta.sports.map((s) {
                      final selected = _supportedSports.contains(s.id);
                      return FilterChip(
                        label: Text(s.name),
                        selected: selected,
                        onSelected: (v) => setState(() {
                          if (v) {
                            _supportedSports.add(s.id);
                          } else {
                            _supportedSports.remove(s.id);
                          }
                        }),
                        selectedColor: AppColors.primary.withValues(alpha: 0.15),
                        checkmarkColor: AppColors.primary,
                        labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.textSecondary, fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                const Text('Brand Website', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                TextField(controller: _website, decoration: const InputDecoration(hintText: 'https://nike.com/india'), keyboardType: TextInputType.url),
                const SizedBox(height: 16),
                const Text('Brand Logo', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickLogo,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(border: Border.all(color: _logoMediaId != null ? AppColors.primary : AppColors.border, style: BorderStyle.solid), borderRadius: BorderRadius.circular(8), color: AppColors.surface),
                    child: Column(children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)), child: Icon(_logoMediaId != null ? LucideIcons.check : LucideIcons.image, color: AppColors.primary, size: 32)),
                      const SizedBox(height: 12),
                      const Text('Upload brand logo', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      const Text('PNG, JPG up to 5MB, 400x400 recommended', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                      if (_logoMediaId != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text('✓ ${_logoName ?? 'logo.png'} uploaded', style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600))),
                      if (_logoMediaId == null) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Click to upload or drag and drop', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500))),
                    ]),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Verification Documents', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
                const SizedBox(height: 6),
                InkWell(
                  onTap: _pickDoc,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(border: Border.all(color: _docMediaId != null ? AppColors.primary : AppColors.border, style: BorderStyle.solid), borderRadius: BorderRadius.circular(8), color: AppColors.surface),
                    child: Column(children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)), child: Icon(_docMediaId != null ? LucideIcons.check : LucideIcons.fileText, color: AppColors.primary, size: 32)),
                      const SizedBox(height: 12),
                      const Text('Upload business registration certificate', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      if (_docMediaId != null) Text('✓ ${_docName ?? 'business_cert.pdf'} uploaded', style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)) else const Text('Click to upload or drag and drop', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      const Text('PDF, JPG up to 10MB', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ]),
                  ),
                ),
                const SizedBox(height: 32),
              ]),
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(context).padding.bottom),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
            child: Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => context.pop(), style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(14), side: const BorderSide(color: AppColors.border)), child: const Text('Back', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(child: FilledButton(onPressed: _saving ? null : _submit, style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.all(14)), child: _saving ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Continue', style: TextStyle(fontWeight: FontWeight.w600)))),
            ]),
          ),
        ]),
      ),
    );
  }
}
