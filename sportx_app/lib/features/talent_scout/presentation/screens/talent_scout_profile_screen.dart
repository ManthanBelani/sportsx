import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/shared/presentation/widgets/media_picker.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:sportx_app/features/talent_scout/presentation/providers/talent_scout_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/shared/presentation/widgets/social_links.dart';
import 'package:sportx_app/shared/providers/meta_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class TalentScoutProfileScreen extends ConsumerStatefulWidget {
  const TalentScoutProfileScreen({super.key});

  @override
  ConsumerState<TalentScoutProfileScreen> createState() => _TalentScoutProfileScreenState();
}

class _TalentScoutProfileScreenState extends ConsumerState<TalentScoutProfileScreen> {
  final _org = TextEditingController();
  final _affiliation = TextEditingController();
  final _bio = TextEditingController();
  int? _exp;
  int? _cityId;
  Set<int> _sports = {};
  int? _photoMediaId;
  String? _photoUrl;
  bool _listingStatus = true;
  bool _saving = false;
  bool _loading = true;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => _load());
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _loadError = null;
      });
    }
    await ref.read(talentScoutProvider.notifier).loadProfile();
    if (!mounted) return;
    final state = ref.read(talentScoutProvider);
    if (state.error != null && state.profile == null) {
      setState(() {
        _loadError = state.error;
        _loading = false;
      });
      return;
    }
    final p = state.profile;
    if (p != null) {
      setState(() {
        _org.text = p.organization ?? '';
        _affiliation.text = p.affiliation ?? '';
        _bio.text = p.bio ?? '';
        _exp = p.experienceYears;
        _cityId = p.cityId;
        _sports = p.sportsSpecialization.toSet();
        _photoMediaId = p.photoMediaId;
        _photoUrl = p.photoUrl;
        _listingStatus = p.listingStatus;
        _loading = false;
      });
    } else {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _org.dispose();
    _affiliation.dispose();
    _bio.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final media = await pickAndUploadMedia(context, ref, mediaType: 'photo');
    if (media != null && mounted) {
      setState(() {
        _photoMediaId = media.mediaId;
        _photoUrl = media.url;
      });
      SnackBarUtils.showSuccess(context, 'Photo uploaded — tap Save to apply');
    }
  }

  void _removePhoto() {
    setState(() {
      _photoMediaId = null;
      _photoUrl = null;
    });
    SnackBarUtils.showSuccess(context, 'Photo removed — tap Save to apply');
  }

  double _completeness() {
    int filled = 0;
    const total = 6;
    if (_sports.isNotEmpty) filled++;
    if (_org.text.trim().isNotEmpty) filled++;
    if (_affiliation.text.trim().isNotEmpty) filled++;
    if (_exp != null) filled++;
    if (_cityId != null) filled++;
    if (_bio.text.trim().isNotEmpty) filled++;
    return filled / total;
  }

  Future<void> _save() async {
    if (_sports.isEmpty) {
      SnackBarUtils.showError(context, 'Select at least one sport');
      return;
    }
    setState(() => _saving = true);
    try {
      final ok = await ref.read(talentScoutProvider.notifier).updateProfile({
        'organization': _org.text.trim().isEmpty ? null : _org.text.trim(),
        'affiliation': _affiliation.text.trim().isEmpty ? null : _affiliation.text.trim(),
        'sports_specialization': _sports.toList(),
        'experience_years': _exp,
        'city_id': _cityId,
        'bio': _bio.text.trim().isEmpty ? null : _bio.text.trim(),
        'photo_media_id': _photoMediaId,
        'listing_status': _listingStatus,
      });
      if (mounted) {
        if (ok) {
          SnackBarUtils.showSuccess(context, 'Profile updated');
          setState(() {});
        } else {
          SnackBarUtils.showError(context, ref.read(talentScoutProvider).error ?? 'Failed to update');
        }
      }
    } catch (e) {
      if (mounted) SnackBarUtils.showError(context, e, 'Failed to update profile. Please try again.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final meta = ref.watch(metaProvider);
    final user = ref.watch(authProvider).user;
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: const SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: CoachProfileViewSkeleton(),
        ),
      );
    }
    if (_loadError != null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text('Scout Profile',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.border)),
        ),
        body: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.border),
            const SizedBox(height: 16),
            Text(_loadError!, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _load,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
          ]),
        ),
      );
    }

    String? cityName;
    for (final c in meta.cities) {
      if (c.id == _cityId) {
        cityName = c.name;
        break;
      }
    }
    final sportNames = meta.sports.where((s) => _sports.contains(s.id)).map((s) => s.name).toList();
    final completeness = _completeness();
    final hasAtAGlance = _org.text.trim().isNotEmpty ||
        _affiliation.text.trim().isNotEmpty ||
        sportNames.isNotEmpty ||
        _bio.text.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Scout Profile',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: false,
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildProfileHeader(user, cityName),
              _buildSectionDivider(),
              _buildCompletenessSection(completeness),
              _buildSectionDivider(),
              _buildAtAGlanceSection(sportNames, hasAtAGlance),
              _buildSectionDivider(),
              _buildListingStatusSection(),
              _buildSectionDivider(),
              _buildSocialLinksSection(),
              _buildSectionDivider(),
              _buildEditFormSection(meta),
              _buildSectionDivider(),
              _buildAccountActions(),
            ],
          ),
        ),
      ),
    );
  }

  // ── sections ──

  Widget _buildSectionDivider() => Container(height: 8, color: AppColors.surface);

  Widget _buildProfileHeader(dynamic user, String? cityName) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
      child: Column(
        children: [
          GestureDetector(
            onTap: _pickPhoto,
            child: Stack(alignment: Alignment.bottomRight, children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(colors: [AppColors.primary, Color(0xFF0d47a1)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                ),
                child: ClipOval(
                    child: _photoUrl != null
                      ? Image.network(
                          _photoUrl!,
                          width: 96,
                          height: 96,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(LucideIcons.user, size: 48, color: Colors.white),
                        )
                      : const Icon(LucideIcons.user, size: 48, color: Colors.white),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(LucideIcons.camera, size: 14, color: Colors.white),
              ),
            ]),
          ),
          if (_photoUrl != null) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _removePhoto,
              child: const Text('Remove photo', style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500)),
            ),
          ] else ...[
            const SizedBox(height: 8),
            const Text('Tap to add profile photo', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 16),
          Text(user?.name ?? 'Talent Scout',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (user?.email != null) ...[
            const SizedBox(height: 4),
            Text(user!.email, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, alignment: WrapAlignment.center, children: [
            _chip(LucideIcons.userSearch, 'Talent Scout'),
            if (cityName != null) _chip(LucideIcons.mapPin, cityName),
            if (_exp != null) _chip(LucideIcons.briefcase, '$_exp yrs exp'),
            _chip(_listingStatus ? LucideIcons.eye : LucideIcons.eyeOff, _listingStatus ? 'Visible' : 'Hidden'),
          ]),
        ],
      ),
    );
  }

  Widget _buildCompletenessSection(double completeness) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Profile completeness',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          Text('${(completeness * 100).toInt()}%',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
        ]),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
              value: completeness,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary)),
        ),
        if (completeness < 1) ...[
          const SizedBox(height: 10),
          InkWell(
            onTap: () {},
            child: const Text('Complete all 6 fields to reach 100%', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ),
        ],
      ]),
    );
  }

  Widget _buildAtAGlanceSection(List<String> sportNames, bool hasAtAGlance) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('At a glance',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        if (!hasAtAGlance)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
            child: const Row(children: [
              Icon(LucideIcons.info, size: 18, color: AppColors.textSecondary),
              SizedBox(width: 10),
              Expanded(child: Text('Add organization, sports or bio to preview your public scout card', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))),
            ]),
          )
        else ...[
          if (_org.text.trim().isNotEmpty) _infoRow(LucideIcons.building2, 'Organization', _org.text.trim()),
          if (_affiliation.text.trim().isNotEmpty) _infoRow(LucideIcons.shieldCheck, 'Affiliation', _affiliation.text.trim()),
          if (sportNames.isNotEmpty) ...[
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sportNames
                  .map((s) => Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.15))),
                        child: Text(s,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ))
                  .toList(),
            ),
          ],
          if (_bio.text.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_bio.text.trim(), style: const TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5)),
          ],
        ],
      ]),
    );
  }

  Widget _buildListingStatusSection() {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
          child: Icon(_listingStatus ? LucideIcons.eye : LucideIcons.eyeOff, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Discoverable by athletes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            SizedBox(height: 2),
            Text('When off, your profile is hidden from search', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ]),
        ),
        Switch(value: _listingStatus,
          activeThumbColor: AppColors.primary,
          onChanged: (v) => setState(() => _listingStatus = v),
        ),
      ]),
    );
  }

  Widget _buildSocialLinksSection() {
    final links = ref.watch(talentScoutProvider).profile?.socialLinks ?? const <String, String>{};
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Social Links',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          GestureDetector(
            onTap: () async {
              await context.push('/social-links');
              _load();
            },
            child: Text(links.isEmpty ? 'Add' : 'Edit',
                style: const TextStyle(fontSize: 13, color: AppColors.primary)),
          ),
        ]),
        const SizedBox(height: 12),
        if (links.isEmpty)
          const Text('No social links yet. Add them so athletes can find you elsewhere.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
        else
          SocialLinksRow(links: links),
      ]),
    );
  }

  Widget _buildEditFormSection(dynamic meta) {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Edit details',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        TextField(
            controller: _org,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Organization', hintText: 'Elite Talent Agency')),
        const SizedBox(height: 16),
        TextField(
            controller: _affiliation,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Affiliation', hintText: 'Gujarat Cricket Association')),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: _exp,
          decoration: const InputDecoration(labelText: 'Years of Experience'),
          items: List.generate(31, (i) => DropdownMenuItem(value: i, child: Text('$i years'))),
          onChanged: (v) => setState(() => _exp = v),
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<int>(
          initialValue: _cityId,
          decoration: const InputDecoration(labelText: 'City'),
          hint: const Text('Select city'),
          items: meta.cities.map<DropdownMenuItem<int>>((c) => DropdownMenuItem(value: c.id as int, child: Text(c.name))).toList(),
          onChanged: (v) => setState(() => _cityId = v),
        ),
        const SizedBox(height: 16),
        const Text('Sports Specialization *',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
        const SizedBox(height: 8),
        if (meta.sports.isEmpty)
          const Text('Loading sports...', style: TextStyle(fontSize: 13, color: AppColors.textSecondary))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: meta.sports.map<Widget>((s) {
              final sel = _sports.contains(s.id);
              return FilterChip(
                label: Text(s.name),
                selected: sel,
                onSelected: (v) => setState(() {
                  if (v) {
                    _sports.add(s.id as int);
                  } else {
                    _sports.remove(s.id);
                  }
                }),
                selectedColor: AppColors.primary.withValues(alpha: 0.15),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                    color: sel ? AppColors.primary : AppColors.textSecondary,
                    fontWeight: sel ? FontWeight.w600 : FontWeight.normal),
              );
            }).toList(),
          ),
        const SizedBox(height: 16),
        TextField(
            controller: _bio,
            onChanged: (_) => setState(() {}),
            maxLines: 4,
            decoration: const InputDecoration(
                labelText: 'Bio',
                hintText: 'Describe your scouting background...',
                alignLabelWithHint: true)),
        const SizedBox(height: 8),
        const Text('Visible on your public scout card', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _saving ? null : _save,
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _saving
                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Text('Save Profile', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }

  Widget _buildAccountActions() {
    return Container(
      width: double.infinity,
      color: AppColors.background,
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Text('Account', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        _accountTile(LucideIcons.settings, 'Settings', 'Notifications, language', () => context.push('/settings')),
        const SizedBox(height: 10),
        _accountTile(LucideIcons.helpCircle, 'Help & Support', 'FAQ, contact us', () => context.push('/help-support')),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () async => await ref.read(authProvider.notifier).logout(),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(LucideIcons.logOut, size: 18),
          label: const Text('Log out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 10),
        OutlinedButton.icon(
          onPressed: () => _confirmDelete(context),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            minimumSize: const Size.fromHeight(48),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          icon: const Icon(LucideIcons.trash2, size: 18),
          label: const Text('Delete Account', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  Widget _accountTile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(8)),
        child: Row(children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ]),
          ),
          const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
        ]),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final pw = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('This action is permanent and cannot be undone. Enter your password to confirm.'),
          const SizedBox(height: 16),
          TextField(controller: pw, obscureText: true, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final ok = await ref.read(settingsProvider.notifier).deleteAccount(pw.text);
              if (ok && context.mounted) SnackBarUtils.showSuccess(context, 'Account deleted');
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
          color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 11, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ]),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, size: 15, color: AppColors.primary),
        const SizedBox(width: 10),
        SizedBox(width: 100, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary))),
        Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
      ]),
    );
  }
}
