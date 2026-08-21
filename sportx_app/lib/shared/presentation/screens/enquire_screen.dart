import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/core/utils/api_client.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/shared/providers/activity_provider.dart';
import 'package:sportx_app/theme/colors.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a message')),
      );
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

    try {
      await ref.read(dioProvider).post('/enquiries', data: {
        'subject_type': widget.subjectType,
        'subject_id': widget.subjectId,
        'message': _messageController.text.trim(),
        'preferred_slots': preferredSlots,
        'age': _ageController.text.replaceAll(' years', ''),
        'contact_number': _phoneController.text.trim(),
      });
      ref.invalidate(activityProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enquiry Sent Successfully!')),
        );
        context.pop();
      }
    } on DioException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiException.fromDio(e).message)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send enquiry. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Enquire with ${widget.title}',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
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
                        color: AppColors.primary.withOpacity(0.1),
                      ),
                      child: widget.coachAvatarUrl != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(28),
                              child: Image.network(widget.coachAvatarUrl!, fit: BoxFit.cover),
                            )
                          : const Icon(Icons.person, color: AppColors.primary),
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
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
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
                        value: _ageController.text.isEmpty ? null : _ageController.text,
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
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : const Text('Send Enquiry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
