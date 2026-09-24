import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/social_links.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Universal Social Links editor — available to every role
/// (athlete, coach, academy, organizer, sponsor, talent_scout, admin).
/// Reads/writes PUT /me/social-links (stored on users.social_links) and
/// refreshes the auth user so profile screens show the new icons.
class SocialLinksScreen extends ConsumerStatefulWidget {
  const SocialLinksScreen({super.key});

  @override
  ConsumerState<SocialLinksScreen> createState() => _SocialLinksScreenState();
}

class _SocialLinksScreenState extends ConsumerState<SocialLinksScreen> {
  Map<String, String>? _links;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    // Prefill instantly from the auth user, then confirm with the server.
    final cached = ref.read(authProvider).user?.socialLinks ?? {};
    if (cached.isNotEmpty) {
      setState(() {
        _links = Map.of(cached);
        _loading = false;
      });
    }
    try {
      final resp = await ref.read(dioProvider).get('/me/social-links');
      final data = (resp.data['data'] as Map?) ?? {};
      if (!mounted) return;
      final links = <String, String>{};
      data.forEach((k, v) {
        final s = v?.toString().trim() ?? '';
        if (s.isNotEmpty) links[k.toString()] = s;
      });
      setState(() {
        _links = links;
        _loading = false;
      });
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() {
        // Fall back to cached links so the form still works offline-ish.
        _links ??= Map.of(cached);
        _loading = false;
        if ((_links ?? {}).isEmpty) _error = ApiException.fromDio(e).message;
      });
    }
  }

  Future<void> _save(Map<String, String> links) async {
    setState(() => _saving = true);
    try {
      await ref.read(dioProvider).put('/me/social-links', data: {'social_links': links});
      await ref.read(authProvider.notifier).refreshUser();
      if (!mounted) return;
      setState(() => _links = Map.of(links));
      SnackBarUtils.showSuccess(context, 'Social links saved');
      context.pop();
    } on DioException catch (e) {
      if (!mounted) return;
      final msg = e.response?.data?['message']?.toString();
      final fieldErrs = e.response?.data?['errors'];
      if (fieldErrs is Map && fieldErrs.isNotEmpty) {
        SnackBarUtils.showError(context, fieldErrs.values.first.toString());
      } else {
        SnackBarUtils.showError(context, msg ?? ApiException.fromDio(e).message);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        surfaceTintColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Social Links',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.border)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(LucideIcons.alertCircle, size: 48, color: AppColors.border),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary), textAlign: TextAlign.center),
                      const SizedBox(height: 12),
                      PrimaryButton(label: 'Retry', onPressed: _load),
                    ]),
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Add your social profiles. They appear as tappable icons on your profile for everyone to see.',
                        style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 16),
                      SocialLinksEditor(initial: _links ?? {}, saving: _saving, onSave: _save),
                    ],
                  ),
                ),
    );
  }
}
