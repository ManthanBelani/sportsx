import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/media_picker.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class AcademyOnboardingScreen extends ConsumerStatefulWidget {
  const AcademyOnboardingScreen({super.key});

  @override
  ConsumerState<AcademyOnboardingScreen> createState() => _AcademyOnboardingScreenState();
}

class _AcademyOnboardingScreenState extends ConsumerState<AcademyOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _fee = TextEditingController();
  int? _cityId;
  final Set<int> _sportIds = {};
  bool _saving = false;
  int? _logoMediaId;
  String? _logoUrl;
  int? _coverMediaId;
  String? _coverUrl;

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _contact.dispose();
    _fee.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_cityId == null || _sportIds.isEmpty) {
      SnackBarUtils.showError(context, 'Please select city and at least one sport');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).post('/onboarding/academy', data: {
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'address': _address.text.trim(),
        'city_id': _cityId,
        'contact_number': _contact.text.trim(),
        'sports': _sportIds.toList(),
        if (_fee.text.trim().isNotEmpty) 'fee_range': _fee.text.trim(),
        if (_logoMediaId != null) 'logo_media_id': _logoMediaId,
        if (_coverMediaId != null) 'cover_image_media_id': _coverMediaId,
      });
      ref.read(authProvider.notifier).markOnboardingComplete();
      await ref.read(authProvider.notifier).refreshUser();
      if (mounted) context.go('/academy-dashboard');
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e is DioException ? ApiException.fromDio(e as DioException) : e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 24),
          onPressed: () => context.pop(),
        ),
        title: Text('Academy Setup',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border)),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _label('Academy Name'),
                TextFormField(controller: _name, decoration: _dec('e.g. Elite Cricket Academy'), validator: _req),
                const SizedBox(height: 16),
                _label('Description'),
                TextFormField(controller: _description, maxLines: 3, decoration: _dec('Short description of your academy'), validator: _req),
                const SizedBox(height: 16),
                _label('Academy Logo'),
                _buildMediaPicker(
                  url: _logoUrl,
                  icon: LucideIcons.building2,
                  label: 'Upload Logo',
                  onTap: () async {
                    final media = await pickAndUploadMedia(context, ref);
                    if (media != null) setState(() { _logoMediaId = media.mediaId; _logoUrl = MediaUtils.resolveUrl(media.url); });
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
                    if (media != null) setState(() { _coverMediaId = media.mediaId; _coverUrl = MediaUtils.resolveUrl(media.url); });
                  },
                ),
                const SizedBox(height: 16),
                _label('Address'),
                TextFormField(controller: _address, decoration: _dec('Full address'), validator: _req),
                const SizedBox(height: 16),
                _label('City'),
                _dropdown(
                  value: _cityId,
                  hint: 'Select city',
                  items: meta.cities.map((c) => _Item(c.id, '${c.name}, ${c.state}')).toList(),
                  onChanged: (v) => setState(() => _cityId = v),
                ),
                const SizedBox(height: 16),
                _label('Contact Number'),
                TextFormField(controller: _contact, keyboardType: TextInputType.phone, decoration: _dec('e.g. +91 98765 43210'), validator: _req),
                const SizedBox(height: 16),
                _label('Sports Offered'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: meta.sports.map((s) {
                    final selected = _sportIds.contains(s.id);
                    return SportXChip(
                      label: s.name,
                      selected: selected,
                      onTap: () => setState(() =>
                          selected ? _sportIds.remove(s.id) : _sportIds.add(s.id)),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _label('Fee Range (optional)'),
                TextFormField(controller: _fee, decoration: _dec('e.g. ₹2,000 – ₹5,000/mo')),
                const SizedBox(height: 28),
                if (_saving)
                  Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFFFD54A), Color(0xFFFFC107), Color(0xFFF5B400)],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x2E785000)),
                      boxShadow: SportXShadows.btnShadow,
                    ),
                    alignment: Alignment.center,
                    child: const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(color: AppColors.ink, strokeWidth: 2)),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: PrimaryButton(label: 'Save & Continue', onPressed: _submit),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text,
            style: GoogleFonts.inter(
                fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      );

  // v2 inputs — default InputDecoration from app_theme.dart
  // (h50 white, 1.5px border, radius 13, yellow focus ring).
  InputDecoration _dec(String hint) => InputDecoration(hintText: hint);

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _buildMediaPicker({required String? url, required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
          boxShadow: SportXShadows.e1,
          image: url != null ? DecorationImage(image: NetworkImage(MediaUtils.resolveUrl(url)), fit: BoxFit.cover) : null,
        ),
        alignment: Alignment.center,
        child: url == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 32, color: AppColors.textSecondary),
                  const SizedBox(height: 8),
                  Text(label, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary)),
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

  Widget _dropdown({
    required int? value,
    required String hint,
    required List<_Item> items,
    required ValueChanged<int?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: SportXShadows.e1),
      child: DropdownButtonFormField<int>(
        initialValue: value,
        decoration: const InputDecoration(border: InputBorder.none),
        hint: Text(hint, style: GoogleFonts.inter(color: AppColors.textTertiary, fontSize: 14)),
        isExpanded: true,
        items: items
            .map((i) => DropdownMenuItem<int>(
                value: i.value,
                child: Text(i.label,
                    style: GoogleFonts.inter(fontSize: 14, color: AppColors.textPrimary))))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _Item {
  final int value;
  final String label;
  const _Item(this.value, this.label);
}
