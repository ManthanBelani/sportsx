import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:sportx_app/theme/colors.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: GestureDetector(
              onTap: () => context.pop(),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(LucideIcons.arrowLeft, color: AppColors.textPrimary, size: 20),
              ),
            ),
          ),
        ),
        title: const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
        centerTitle: false,
      ),
      body: state.isLoading && state.notificationPrefs.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Account'),
                  _buildSettingsGroup(
                    children: [
                      _buildSettingsItem(
                        icon: LucideIcons.user,
                        title: 'Edit Profile',
                        subtitle: 'Name, sport, achievements',
                        onTap: () => context.push('/edit-profile'),
                      ),
                      _buildSettingsItem(
                        icon: LucideIcons.camera,
                        title: 'Media Gallery',
                        subtitle: 'Photos, videos, certificates',
                        onTap: () => context.push('/media-gallery'),
                      ),
                      _buildSettingsItem(
                        icon: LucideIcons.lock,
                        title: 'Change Password',
                        subtitle: 'Update your password',
                        onTap: () => _showChangePasswordDialog(context),
                      ),
                    ],
                  ),

                  _buildSectionTitle('Notifications'),
                  _buildSettingsGroup(
                    children: [
                      _buildSettingsToggleItem(
                        icon: LucideIcons.bell,
                        title: 'Push Notifications',
                        subtitle: 'Trial deadlines, replies, updates',
                        value: state.notificationPrefs['push'] ?? true,
                        onChanged: (v) => ref.read(settingsProvider.notifier).updatePrefs(
                          {...state.notificationPrefs, 'push': v},
                        ),
                      ),
                      _buildSettingsToggleItem(
                        icon: LucideIcons.mail,
                        title: 'Email Alerts',
                        subtitle: 'Weekly digest, important updates',
                        value: state.notificationPrefs['email'] ?? false,
                        onChanged: (v) => ref.read(settingsProvider.notifier).updatePrefs(
                          {...state.notificationPrefs, 'email': v},
                        ),
                      ),
                      _buildSettingsToggleItem(
                        icon: LucideIcons.messageSquare,
                        title: 'SMS Notifications',
                        subtitle: 'Registration confirmations',
                        value: state.notificationPrefs['sms'] ?? true,
                        onChanged: (v) => ref.read(settingsProvider.notifier).updatePrefs(
                          {...state.notificationPrefs, 'sms': v},
                        ),
                      ),
                    ],
                  ),

                  _buildSectionTitle('Preferences'),
                  _buildSettingsGroup(
                    children: [
                      _buildSettingsItem(
                        icon: LucideIcons.globe,
                        title: 'Language',
                        subtitle: state.language == 'hi' ? 'हिंदी (Hindi)' : 'English',
                        onTap: () => _showLanguageDialog(context),
                      ),
                      _buildSettingsToggleItem(
                        icon: LucideIcons.mapPin,
                        title: 'Location Services',
                        subtitle: 'Enable location for nearby results',
                        value: true, // Mock value for UI
                        onChanged: (v) {},
                      ),
                    ],
                  ),

                  _buildSectionTitle('Support'),
                  _buildSettingsGroup(
                    children: [
                      _buildSettingsItem(
                        icon: LucideIcons.helpCircle,
                        title: 'Help & Support',
                        subtitle: 'FAQ, contact us',
                        onTap: () => context.push('/help-support'),
                      ),
                      _buildSettingsItem(
                        icon: LucideIcons.fileText,
                        title: 'Terms of Service',
                        onTap: () {},
                      ),
                      _buildSettingsItem(
                        icon: LucideIcons.shield,
                        title: 'Privacy Policy',
                        onTap: () {},
                      ),
                    ],
                  ),

                  _buildSettingsGroup(
                    children: [
                      _buildSettingsItem(
                        icon: LucideIcons.logOut,
                        title: 'Log Out',
                        isDanger: true,
                        onTap: () {},
                        showArrow: false,
                      ),
                      _buildSettingsItem(
                        icon: LucideIcons.trash2,
                        title: 'Delete Account',
                        isDanger: true,
                        onTap: () => _confirmDelete(context),
                        showArrow: false,
                      ),
                    ],
                  ),

                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text(
                        'SportX India v1.0.0',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildSettingsGroup({required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: children.asMap().entries.map((entry) {
          final isLast = entry.key == children.length - 1;
          return Column(
            children: [
              entry.value,
              if (!isLast) const Divider(height: 1, thickness: 1, color: AppColors.border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    bool isDanger = false,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 18, color: isDanger ? AppColors.error : AppColors.textPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDanger ? AppColors.error : AppColors.textPrimary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
            if (showArrow)
              const Icon(LucideIcons.chevronRight, size: 20, color: AppColors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsToggleItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 18, color: AppColors.textPrimary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          // Custom toggle
          GestureDetector(
            onTap: () => onChanged(!value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: value ? AppColors.primary : AppColors.border,
              ),
              child: Stack(
                children: [
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeIn,
                    top: 3,
                    left: value ? 23 : 3,
                    right: value ? 3 : 23,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final passwordController = TextEditingController();
    final newPasswordController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Current Password', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New Password', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              ref.read(settingsProvider.notifier).updatePassword(
                passwordController.text,
                newPasswordController.text,
              );
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                ref.read(settingsProvider.notifier).updateLanguage('en');
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              title: const Text('हिंदी (Hindi)'),
              onTap: () {
                ref.read(settingsProvider.notifier).updateLanguage('hi');
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final passwordController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Account?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('This action is permanent and cannot be undone. Enter your password to confirm.'),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(settingsProvider.notifier).deleteAccount(passwordController.text);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Account deleted')));
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}
