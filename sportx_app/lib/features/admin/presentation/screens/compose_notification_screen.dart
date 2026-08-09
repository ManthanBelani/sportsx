import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';

class ComposeNotificationScreen extends ConsumerStatefulWidget {
  const ComposeNotificationScreen({super.key});

  @override
  ConsumerState<ComposeNotificationScreen> createState() =>
      _ComposeNotificationScreenState();
}

class _ComposeNotificationScreenState
    extends ConsumerState<ComposeNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  String _selectedTarget = 'all';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminWebLayout(
      title: 'Compose Notification',
      actions: [
        TextButton(
          onPressed: _isLoading ? null : _sendNotification,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Send'),
        ),
      ],
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildNotificationForm(),
            const SizedBox(height: 24),
            _buildTargetingSection(),
            const SizedBox(height: 24),
            _buildPreviewSection(),
            const SizedBox(height: 24),
            _buildSendButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Notification Content'),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter notification title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Title is required';
                }
                if (value.length > 100) {
                  return 'Title must be less than 100 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _bodyController,
              decoration: const InputDecoration(
                labelText: 'Body',
                hintText: 'Enter notification message',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Body is required';
                }
                if (value.length > 500) {
                  return 'Body must be less than 500 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Text(
              '${_titleController.text.length}/100 characters',
              style: TextStyle(
                color: _titleController.text.length > 100
                    ? AppColors.error
                    : AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Target Audience'),
            const SizedBox(height: 16),
            _buildTargetOption(
              value: 'all',
              title: 'All Users',
              description: 'Send to all registered users',
              icon: Icons.people_outline,
            ),
            _buildTargetOption(
              value: 'athletes',
              title: 'Athletes Only',
              description: 'Send to athlete accounts',
              icon: Icons.sports,
            ),
            _buildTargetOption(
              value: 'coaches',
              title: 'Coaches Only',
              description: 'Send to coach accounts',
              icon: Icons.fitness_center,
            ),
            _buildTargetOption(
              value: 'sponsors',
              title: 'Sponsors Only',
              description: 'Send to sponsor accounts',
              icon: Icons.business,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push('/admin/notifications/targeting'),
                icon: const Icon(Icons.tune),
                label: const Text('Advanced Targeting'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTargetOption({
    required String value,
    required String title,
    required String description,
    required IconData icon,
  }) {
    final isSelected = _selectedTarget == value;

    return RadioListTile<String>(
      value: value,
      groupValue: _selectedTarget,
      onChanged: (val) {
        setState(() {
          _selectedTarget = val!;
        });
      },
      title: Row(
        children: [
          Icon(icon, color: isSelected ? AppColors.primary : AppColors.textSecondary),
          const SizedBox(width: 12),
          Text(title),
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(left: 44),
        child: Text(description),
      ),
      activeColor: AppColors.primary,
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionLabel(label: 'Notification Preview'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.sports,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _titleController.text.isEmpty
                                  ? 'Notification Title'
                                  : _titleController.text,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'SportX India',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'now',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _bodyController.text.isEmpty
                        ? 'Notification body text will appear here...'
                        : _bodyController.text,
                    style: TextStyle(
                      color: _bodyController.text.isEmpty
                          ? AppColors.textTertiary
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSendButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _sendNotification,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.cta,
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
      child: _isLoading
          ? const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text(
              'Send Notification',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      List<String>? roles;
      if (_selectedTarget == 'athletes') roles = ['athlete'];
      if (_selectedTarget == 'coaches') roles = ['coach'];
      if (_selectedTarget == 'sponsors') roles = ['sponsor'];

      await ref.read(adminProvider.notifier).sendNotification(
        title: _titleController.text,
        body: _bodyController.text,
        roles: roles,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Notification sent successfully')),
        );
        context.pop();
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
