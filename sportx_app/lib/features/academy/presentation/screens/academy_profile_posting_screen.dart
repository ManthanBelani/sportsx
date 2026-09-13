import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/media_utils.dart';
import 'package:sportx_app/features/academy/presentation/providers/academy_provider.dart';
import 'package:sportx_app/shared/models/models.dart';
import 'package:sportx_app/shared/presentation/widgets/media_picker.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

const _facilityOptions = [
  'Turf Ground',
  'AC Classroom',
  'Video Analysis',
  'Gym',
  'Swimming Pool',
  'Changing Rooms',
  'Parking',
];

const _ageGroupOptions = ['5-8', '8-12', '12-16', '16-20', '20+'];

class AcademyProfilePostingScreen extends ConsumerStatefulWidget {
  const AcademyProfilePostingScreen({super.key});

  @override
  ConsumerState<AcademyProfilePostingScreen> createState() => _AcademyProfilePostingScreenState();
}

class _AcademyProfilePostingScreenState extends ConsumerState<AcademyProfilePostingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _contact = TextEditingController();
  final _fee = TextEditingController();
  final _timings = TextEditingController();
  int? _cityId;
  final Set<int> _sportIds = {};
  final Set<String> _facilities = {};
  final Set<String> _ageGroups = {};
  bool _saving = false;
  bool _prefilled = false;
  int? _logoMediaId;
  String? _logoUrl;
  int? _coverMediaId;
  String? _coverUrl;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.invalidate(myAcademyProvider);
      ref.read(myAcademyProvider);
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _address.dispose();
    _contact.dispose();
    _fee.dispose();
    _timings.dispose();
    super.dispose();
  }

  void _prefill(Academy a) {
    _prefilled = true;
    _name.text = a.name;
    _description.text = a.description ?? '';
    _address.text = a.address ?? '';
    _contact.text = a.contactNumber ?? '';
    _fee.text = a.feeRange ?? '';
    _timings.text = a.timings ?? '';
    _cityId = a.cityId;
    _sportIds.addAll(a.sports.map((s) => s.id));
    if (_sportIds.isEmpty && a.sportId != null) _sportIds.add(a.sportId!);
    _facilities.addAll(a.facilities);
    _ageGroups.addAll(a.ageGroups);
    _logoUrl = a.logoUrl;
    _coverUrl = a.coverImageUrl;
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_cityId == null) {
      SnackBarUtils.showError(context, 'Please select a city');
      return;
    }
    if (_sportIds.isEmpty) {
      SnackBarUtils.showError(context, 'Please select at least one sport');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).put('/me/academy', data: {
        'name': _name.text.trim(),
        'description': _description.text.trim(),
        'address': _address.text.trim(),
        'city_id': _cityId,
        'contact_number': _contact.text.trim(),
        'facilities': _facilities.toList(),
        'age_groups': _ageGroups.toList(),
        'sports': _sportIds.toList(),
        if (_fee.text.trim().isNotEmpty) 'fee_range': _fee.text.trim(),
        if (_timings.text.trim().isNotEmpty) 'timings': _timings.text.trim(),
        if (_logoMediaId != null) 'logo_media_id': _logoMediaId,
        if (_coverMediaId != null) 'cover_media_id': _coverMediaId,
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
    final meta = ref.watch(metaProvider);
    final academyAsync = ref.watch(myAcademyProvider);
    if (!_prefilled && academyAsync.hasValue) {
      final academy = academyAsync.value!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_prefilled) setState(() => _prefill(academy));
      });
    }
    // Render the form only after prefill (or when there is no academy data at
    // all) so dropdown initialValue reflects the loaded academy.
    final showForm = _prefilled ||
        (!academyAsync.isLoading && !academyAsync.hasValue);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text('Edit Academy Listing',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
      ),
      body: !showForm
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _sectionTitle('Basic Info'),
                    _label('Academy Name'),
                    TextFormField(
                      controller: _name,
                      decoration: _dec('Academy name'),
                      validator: _req,
                    ),
                    const SizedBox(height: 16),
                    _label('City'),
                    _dropdown(
                      value: _cityId,
                      hint: 'Select city',
                      items: meta.cities
                          .map((c) => DropdownMenuItem(value: c.id, child: Text('${c.name}, ${c.state}')))
                          .toList(),
                      onChanged: (v) => setState(() => _cityId = v),
                    ),
                    const SizedBox(height: 16),
                    _label('Full Address'),
                    TextFormField(
                      controller: _address,
                      maxLines: 2,
                      decoration: _dec('e.g. No. 42, 3rd Cross, Indiranagar, Bangalore'),
                      validator: _req,
                    ),
                    const SizedBox(height: 16),
                    _label('Contact Number'),
                    TextFormField(
                      controller: _contact,
                      keyboardType: TextInputType.phone,
                      decoration: _dec('e.g. +91 98765 43210'),
                      validator: _req,
                    ),
                    const SizedBox(height: 16),
                    _label('Description'),
                    TextFormField(
                      controller: _description,
                      maxLines: 3,
                      decoration: _dec('About your academy, coaching approach, results...'),
                      validator: _req,
                    ),

                    _sectionTitle('Sports Offered'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: meta.sports.map((s) {
                        final selected = _sportIds.contains(s.id);
                        return _chip(
                          label: s.name,
                          selected: selected,
                          onSelected: (sel) => setState(
                              () => sel ? _sportIds.add(s.id) : _sportIds.remove(s.id)),
                        );
                      }).toList(),
                    ),

                    _sectionTitle('Facilities'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _facilityOptions.map((f) {
                        final selected = _facilities.contains(f);
                        return _chip(
                          label: f,
                          selected: selected,
                          onSelected: (sel) =>
                              setState(() => sel ? _facilities.add(f) : _facilities.remove(f)),
                        );
                      }).toList(),
                    ),

                    _sectionTitle('Fee Range (per month)'),
                    TextFormField(
                      controller: _fee,
                      decoration: _dec('e.g. ₹3,000 – ₹8,000'),
                    ),

                    _sectionTitle('Age Groups'),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _ageGroupOptions.map((g) {
                        final selected = _ageGroups.contains(g);
                        return _chip(
                          label: g,
                          selected: selected,
                          onSelected: (sel) =>
                              setState(() => sel ? _ageGroups.add(g) : _ageGroups.remove(g)),
                        );
                      }).toList(),
                    ),

                    _sectionTitle('Training Timings'),
                    TextFormField(
                      controller: _timings,
                      decoration: _dec('e.g. Mon-Fri 4:00 PM - 7:00 PM, Sat 9:00 AM - 1:00 PM'),
                    ),

                    _sectionTitle('Photos'),
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
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary, minimumSize: const Size.fromHeight(52)),
                        child: _saving
                            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Save Changes',
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 24, bottom: 12),
        child: Text(text,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
      );

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
      );

  Widget _chip({required String label, required bool selected, required ValueChanged<bool> onSelected}) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: selected ? Colors.white : AppColors.textPrimary,
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    );
  }

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.background,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
      );

  String? _req(String? v) => (v == null || v.trim().isEmpty) ? 'Required' : null;

  Widget _dropdown({
    required int? value,
    required String hint,
    required List<DropdownMenuItem<int>> items,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: _dec(hint),
      isExpanded: true,
      icon: const Icon(LucideIcons.chevronDown, size: 18, color: AppColors.textSecondary),
      items: items,
      onChanged: onChanged,
    );
  }

  Widget _buildMediaPicker({required String? url, required IconData icon, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
          image: url != null ? DecorationImage(image: NetworkImage(MediaUtils.resolveUrl(url)), fit: BoxFit.cover) : null,
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
}
