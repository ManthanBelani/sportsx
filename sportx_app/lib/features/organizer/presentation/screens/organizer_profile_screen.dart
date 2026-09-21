import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/organizer/presentation/providers/organizer_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';
import 'package:sportx_app/theme/colors.dart';

class OrganizerProfileScreen extends ConsumerStatefulWidget {
  const OrganizerProfileScreen({super.key});
  @override
  ConsumerState<OrganizerProfileScreen> createState() => _OrganizerProfileScreenState();
}

class _OrganizerProfileScreenState extends ConsumerState<OrganizerProfileScreen> {
  final _name = TextEditingController();
  final _regNo = TextEditingController();
  final _website = TextEditingController();
  String _type = 'federation';
  bool _saving = false;
  bool _loaded = false;

  final _typeOptions = const [
    {'value': 'federation', 'label': 'Federation / State Association'},
    {'value': 'club', 'label': 'Private Club'},
    {'value': 'other', 'label': 'Other'},
  ];

  @override
  void dispose() {
    _name.dispose();
    _regNo.dispose();
    _website.dispose();
    super.dispose();
  }

  void _fillFromProfile(Map<String, dynamic> p) {
    if (_loaded) return;
    _name.text = (p['organization_name'] ?? '').toString();
    _regNo.text = (p['registration_number'] ?? '').toString();
    _website.text = (p['website'] ?? '').toString();
    final t = (p['org_type'] ?? 'federation').toString();
    if (_typeOptions.any((e) => e['value'] == t)) _type = t;
    _loaded = true;
  }

  Future<void> _save() async {
    if (_name.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Organization name required');
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).put('/me/organizer', data: {
        'organization_name': _name.text.trim(),
        'org_type': _type,
        if (_regNo.text.trim().isNotEmpty) 'registration_number': _regNo.text.trim(),
        if (_website.text.trim().isNotEmpty) 'website': _website.text.trim(),
      });
      ref.invalidate(myOrganizerProvider);
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Organization updated');
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
    final async = ref.watch(myOrganizerProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary), onPressed: () => context.pop()),
        title: const Text('Organization Profile', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        bottom: const PreferredSize(preferredSize: Size.fromHeight(1), child: Divider(height: 1, color: AppColors.border)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8)),
              child: _saving ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
            ),
          ),
        ],
      ),
      body: async.when(
        loading: () => const GenericListSkeleton(),
        error: (e, _) => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Text(ApiException.messageFor(e)), const SizedBox(height: 12), ElevatedButton(onPressed: () => ref.invalidate(myOrganizerProvider), child: const Text('Retry'))])),
        data: (profile) {
          _fillFromProfile(profile);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _label('Organization Name *'),
              TextField(controller: _name, decoration: const InputDecoration(hintText: 'Karnataka State Football Association')),
              const SizedBox(height: 16),
              _label('Organization Type'),
              DropdownButtonFormField<String>(
                initialValue: _type,
                items: _typeOptions.map((o) => DropdownMenuItem(value: o['value']!, child: Text(o['label']!, style: const TextStyle(fontSize: 14)))).toList(),
                onChanged: (v) => setState(() => _type = v ?? _type),
                decoration: const InputDecoration(),
              ),
              const SizedBox(height: 16),
              _label('Registration Number'),
              TextField(controller: _regNo, decoration: const InputDecoration(hintText: 'REG/2020/0456')),
              const SizedBox(height: 16),
              _label('Website'),
              TextField(controller: _website, decoration: const InputDecoration(hintText: 'https://')),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: const Color(0xFFdbeafe), borderRadius: BorderRadius.circular(8)),
                child: const Row(children: [Icon(LucideIcons.info, size: 14, color: AppColors.primary), SizedBox(width: 8), Expanded(child: Text('Verification documents are managed via onboarding. Contact support to update them.', style: TextStyle(fontSize: 12, color: AppColors.primary)))]),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => context.push('/social-links'),
                icon: const Icon(LucideIcons.share2, size: 16),
                label: const Text('Manage Social Links'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary)));
}
