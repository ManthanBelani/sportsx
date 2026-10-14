import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/theme/colors.dart';

/// Provider applications inbox (Phase 4 SP7/SP8/SP9): review applicants,
/// shortlist or decline with an optional note. Athlete gets notified.
class OpportunityApplicationsScreen extends ConsumerStatefulWidget {
  final String opportunityId;
  const OpportunityApplicationsScreen({super.key, required this.opportunityId});

  @override
  ConsumerState<OpportunityApplicationsScreen> createState() => _OpportunityApplicationsScreenState();
}

class _OpportunityApplicationsScreenState extends ConsumerState<OpportunityApplicationsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  final Set<String> _busy = {};

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resp = await ref.read(dioProvider).get('/opportunities/${widget.opportunityId}/applications');
      final body = resp.data;
      final list = body is Map && body['data'] is List ? body['data'] as List : (body is List ? body : []);
      setState(() {
        _items = list.cast<Map<String, dynamic>>();
        _loading = false;
      });
    } on DioException catch (e) {
      setState(() {
        _loading = false;
        _error = ApiException.fromDio(e).message;
      });
    }
  }

  Future<void> _decide(Map<String, dynamic> app, String status) async {
    final note = TextEditingController();
    final confirm = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'shortlisted' ? 'Shortlist applicant' : 'Decline applicant'),
        content: TextField(controller: note, maxLines: 3, decoration: const InputDecoration(hintText: 'Optional note to athlete', border: OutlineInputBorder())),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, note.text.trim()), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirm == null) return;
    final id = (app['id'] ?? '').toString();
    setState(() => _busy.add(id));
    try {
      await ref.read(dioProvider).patch(
        '/opportunities/${widget.opportunityId}/applications/$id',
        data: {'status': status, if (confirm.isNotEmpty) 'decision_note': confirm},
      );
      if (mounted) SnackBarUtils.showSuccess(context, status == 'shortlisted' ? 'Shortlisted' : 'Declined');
      await _load();
    } on DioException catch (e) {
      if (mounted) SnackBarUtils.showError(context, ApiException.fromDio(e).message);
    } finally {
      if (mounted) setState(() => _busy.remove(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        elevation: 0,
        title: Text('Applications',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _items.isEmpty
                    ? const Center(child: Text('No applications yet'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _items.length,
                        itemBuilder: (_, i) {
                          final app = _items[i];
                          final athlete = (app['athlete'] as Map?) ?? {};
                          final user = (athlete['user'] as Map?) ?? {};
                          final status = (app['status'] ?? 'pending').toString();
                          final id = (app['id'] ?? '').toString();
                          final busy = _busy.contains(id);
                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text((user['name'] ?? 'Athlete').toString(),
                                    style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                                if ((app['pitch'] ?? '').toString().isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4),
                                    child: Text(app['pitch'].toString(),
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                                  ),
                                const SizedBox(height: 4),
                                Text('Status: $status',
                                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
                                const SizedBox(height: 8),
                                Row(children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: busy || status == 'shortlisted'
                                          ? null
                                          : () => _decide(app, 'shortlisted'),
                                      icon: const Icon(LucideIcons.star, size: 16),
                                      label: const Text('Shortlist'),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: busy || status == 'declined'
                                          ? null
                                          : () => _decide(app, 'declined'),
                                      icon: const Icon(LucideIcons.x, size: 16),
                                      label: const Text('Decline'),
                                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                                    ),
                                  ),
                                ]),
                              ]),
                            ),
                          );
                        },
                      ),
      ),
    );
  }
}
