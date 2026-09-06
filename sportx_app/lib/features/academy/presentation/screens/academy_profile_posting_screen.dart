import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/media_picker.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class AcademyProfilePostingScreen extends ConsumerStatefulWidget {
  const AcademyProfilePostingScreen({super.key});

  @override
  ConsumerState<AcademyProfilePostingScreen> createState() => _AcademyProfilePostingScreenState();
}

class _AcademyProfilePostingScreenState extends ConsumerState<AcademyProfilePostingScreen> {
  final _name = TextEditingController();
  final _sport = TextEditingController();
  final _facilities = TextEditingController();
  final _fee = TextEditingController();
  final _ageGroups = TextEditingController();
  final _timings = TextEditingController();
  bool _saving = false;
  int? _logoMediaId;
  String? _logoUrl;
  int? _coverMediaId;
  String? _coverUrl;
  int? _cityId;

  @override
  void initState() {
    super.initState();
    final academy = ref.read(myAcademyProvider).valueOrNull;
    if (academy != null) {
      _name.text = academy.name;
      _sport.text = academy.sport?.name ?? '';
      _fee.text = academy.monthlyRate?.toString() ?? '';
      _logoUrl = academy.logoUrl;
      _coverUrl = academy.coverImageUrl;
      _cityId = academy.cityId;
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _sport.dispose();
    _facilities.dispose();
    _fee.dispose();
    _ageGroups.dispose();
    _timings.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).put('/me/academy', data: {
        'name': _name.text.trim(),
        'sport': _sport.text.trim(),
        'facilities': _facilities.text.trim(),
        'monthly_rate': num.tryParse(_fee.text.trim()) ?? 0,
        'age_groups': _ageGroups.text.trim(),
        'timings': _timings.text.trim(),
        if (_logoMediaId != null) 'logo_media_id': _logoMediaId,
        if (_coverMediaId != null) 'cover_image_media_id': _coverMediaId,
        if (_cityId != null) 'city_id': _cityId,
      });
      ref.invalidate(myAcademyProvider);
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Academy Updated!');
        context.pop();
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Edit Academy Listing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _label('Academy Logo'),
            _buildMediaPicker(
              url: _logoUrl,
              icon: LucideIcons.building2,
              label: 'Upload Logo',
              onTap: () async {
                final media = await pickAndUploadMedia(context, ref);
                if (media != null) setState(() { _logoMediaId = media.mediaId; _logoUrl = media.url; });
              },
            ),
            const SizedBox(height: 16),
            _label('Cover Image'),
            _buildMediaPicker(
              url: _coverUrl,
              icon: LucideIcons.image,
              label: 'Upload Cover',
              onTap: () async {
                final media = await pickAndUploadMedia(context, ref);
                if (media != null) setState(() { _coverMediaId = media.mediaId; _coverUrl = media.url; });
              },
            ),
            const SizedBox(height: 16),
            TextField(controller: _name, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 16),
            TextField(controller: _sport, decoration: const InputDecoration(labelText: 'Sport(s)')),
            const SizedBox(height: 16),
            _label('City'),
            _buildCityDropdown(),
            const SizedBox(height: 16),
            TextField(controller: _facilities, decoration: const InputDecoration(labelText: 'Facilities')),
            const SizedBox(height: 16),
            TextField(controller: _fee, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Monthly Fee')),
            const SizedBox(height: 16),
            TextField(controller: _ageGroups, decoration: const InputDecoration(labelText: 'Age Groups')),
            const SizedBox(height: 16),
            TextField(controller: _timings, decoration: const InputDecoration(labelText: 'Timings')),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      );

  Widget _buildMediaPicker({required String? url, required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          image: url != null ? DecorationImage(image: NetworkImage(url), fit: BoxFit.cover) : null,
        ),
        alignment: Alignment.center,
        child: url == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: AppColors.textSecondary),
                  const SizedBox(height: 8),
                  Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              )
            : Container(
                alignment: Alignment.topRight,
                padding: const EdgeInsets.all(8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.5), shape: BoxShape.circle),
                  child: const Icon(LucideIcons.pencil, size: 14, color: Colors.white),
                ),
              ),
      ),
    );
  }

  Widget _buildCityDropdown() {
    final meta = ref.watch(metaProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonFormField<int>(
        value: _cityId,
        decoration: const InputDecoration(border: InputBorder.none),
        hint: const Text('Select city', style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
        isExpanded: true,
        items: meta.cities.map((c) => DropdownMenuItem<int>(value: c.id, child: Text('${c.name}, ${c.state}'))).toList(),
        onChanged: (v) => setState(() => _cityId = v),
      ),
    );
  }
}
