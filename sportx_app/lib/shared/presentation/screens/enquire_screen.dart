import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/providers/activity_provider.dart';
import 'package:sportx_app/shared/presentation/widgets/sportx_ui.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';

class EnquireScreen extends ConsumerStatefulWidget {
  final String subjectType;
  final int subjectId;
  final String title;
  final String? coachName;
  final String? coachDetails;
  final String? coachAvatarUrl;

  const EnquireScreen({
    super.key,
    required this.subjectType,
    required this.subjectId,
    required this.title,
    this.coachName,
    this.coachDetails,
    this.coachAvatarUrl,
  });

  @override
  ConsumerState<EnquireScreen> createState() => _EnquireScreenState();
}

class _EnquireScreenState extends ConsumerState<EnquireScreen> {
  final _messageController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _submitting = false;

  final List<Map<String, TextEditingController>> _trainingSlots = [
    {'day': TextEditingController(), 'time': TextEditingController()},
    {'day': TextEditingController(), 'time': TextEditingController()},
    {'day': TextEditingController(), 'time': TextEditingController()},
  ];

  final List<String> _ageOptions = List.generate(30, (i) => '${i + 5} years');

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).user;
    _phoneController.text = user?.phone ?? '';
    _ageController.text = '14 years';
  }

  @override
  void dispose() {
    _messageController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    for (final slot in _trainingSlots) {
      slot['day']?.dispose();
      slot['time']?.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (_messageController.text.trim().isEmpty) {
      SnackBarUtils.showError(context, 'Please enter a message');
      return;
    }

    setState(() => _submitting = true);

    final preferredSlots = _trainingSlots
        .where((slot) => (slot['day']?.text.trim().isNotEmpty ?? false))
        .map((slot) => {
              'day': slot['day']?.text.trim() ?? '',
              'time': slot['time']?.text.trim() ?? '',
            })
        .toList();

    // Build a single preferred_datetime from first filled slot if parseable, otherwise omit (backend expects nullable date)
    String? preferredDatetime;
    if (preferredSlots.isNotEmpty) {
      // Try to interpret as ISO-like date; UI collects free-form day/time so we store null and include message detail instead
      preferredDatetime = null;
    }
    try {
      final payload = {
        'subject_type': widget.subjectType,
        'subject_id': widget.subjectId,
        'message': _messageController.text.trim() + (preferredSlots.isNotEmpty ? '\nPreferred: ${preferredSlots.map((s) => "${s['day']} ${s['time']}").join(', ')}' : ''),
        if (preferredDatetime != null) 'preferred_datetime': preferredDatetime,
      };
      await ref.read(dioProvider).post('/enquiries', data: payload);
      ref.invalidate(activityProvider);
      if (mounted) {
        SnackBarUtils.showSuccess(context, 'Enquiry sent successfully!');
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
      if (mounted) {
        SnackBarUtils.showError(context, e, 'Failed to send enquiry. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

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
        title: Text(
          'Enquire with ${widget.title}',
          style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.coachName != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(28),
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      child: widget.coachAvatarUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.network(widget.coachAvatarUrl!, fit: BoxFit.cover),
                            )
                          : const Icon(LucideIcons.user, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.coachName ?? '',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                          ),
                          if (widget.coachDetails != null)
                            Text(
                              widget.coachDetails ?? '',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
            Text(
              'Your Profile (auto-filled)',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border), boxShadow: SportXShadows.e1,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Name: ${user?.name ?? 'Loading...'}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('Phone: ${user?.phone ?? 'N/A'}'),
                  Text('Role: ${user?.role ?? 'Athlete'}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Message',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 5,
              enabled: !_submitting,
              decoration: InputDecoration(
                hintText: 'Hi ${widget.coachName ?? 'Coach'}, I\'m interested in training sessions...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Preferred Training Days',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ...List.generate(_trainingSlots.length, (index) {
              final slot = _trainingSlots[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: slot['day'],
                        enabled: !_submitting,
                        decoration: InputDecoration(
                          hintText: 'Day ${index + 1} (e.g., Saturday)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: slot['time'],
                        enabled: !_submitting,
                        decoration: InputDecoration(
                          hintText: 'Time (e.g., 4-6 PM)',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your Age',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: _ageController.text.isEmpty ? null : _ageController.text,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _ageOptions.map((age) {
                          return DropdownMenuItem(value: age, child: Text(age));
                        }).toList(),
                        onChanged: _submitting ? null : (value) {
                          if (value != null) _ageController.text = value;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contact Number',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _phoneController,
                        enabled: !_submitting,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: '+91 98765 43210',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: SizedBox(
                  width: double.infinity,
                  child: PrimaryButton(
                    label: _submitting ? 'Sending…' : 'Send Enquiry',
                    icon: LucideIcons.send,
                    onPressed: _submitting ? null : _submit,
                  ),
                ),
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }
}
