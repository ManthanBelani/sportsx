import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/features/opportunity/presentation/providers/opportunity_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';

/// Provider posting form (Phase 4): type, title, deadline, details.
class PostOpportunityScreen extends ConsumerStatefulWidget {
  const PostOpportunityScreen({super.key});

  @override
  ConsumerState<PostOpportunityScreen> createState() => _PostOpportunityScreenState();
}

class _PostOpportunityScreenState extends ConsumerState<PostOpportunityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _eligibility = TextEditingController();
  final _benefits = TextEditingController();
  final _amount = TextEditingController();
  final _deadline = TextEditingController();
  String _type = 'scholarship';
  bool _publishNow = true;
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _eligibility.dispose();
    _benefits.dispose();
    _amount.dispose();
    _deadline.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final payload = <String, dynamic>{
        'type': _type,
        'title': _title.text.trim(),
        'description': _description.text.trim(),
        'eligibility': _eligibility.text.trim(),
        'benefits': _benefits.text.trim(),
        'status': _publishNow ? 'published' : 'draft',
      };
      if (_amount.text.trim().isNotEmpty) payload['amount'] = double.tryParse(_amount.text.trim());
      if (_deadline.text.trim().isNotEmpty) payload['deadline'] = _deadline.text.trim();
      final ok = await ref.read(myOpportunitiesProvider.notifier).post(payload);
      if (!mounted) return;
      if (ok) {
        SnackBarUtils.showSuccess(context, 'Opportunity ${_publishNow ? 'published' : 'saved as draft'}!');
        ref.invalidate(opportunitiesProvider);
        context.pop();
      } else {
        SnackBarUtils.showError(
          context,
          ref.read(myOpportunitiesProvider).error ?? 'Failed to post',
        );
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
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text('Post Opportunity',
            style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: const ['scholarship', 'sponsorship', 'tryout', 'camp']
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) => setState(() => _type = v ?? 'scholarship'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _title,
                decoration: const InputDecoration(labelText: 'Title', hintText: 'e.g. U-16 Cricket Scholarship'),
                validator: (v) => v == null || v.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _description,
                maxLines: 4,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _eligibility,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Eligibility'),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _benefits,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Benefits / Amount details'),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _amount,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Amount (₹, optional)'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _deadline,
                      decoration: const InputDecoration(labelText: 'Deadline (YYYY-MM-DD)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Publish immediately'),
                value: _publishNow,
                onChanged: (v) => setState(() => _publishNow = v),
              ),
              const SizedBox(height: 16),
              _saving
                  ? const Center(child: CircularProgressIndicator())
                  : PrimaryButton(
                      label: _publishNow ? 'Publish' : 'Save Draft',
                      icon: LucideIcons.send,
                      onPressed: _save,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
