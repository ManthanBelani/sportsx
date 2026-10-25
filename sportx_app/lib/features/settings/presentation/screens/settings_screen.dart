import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:sportx_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:sportx_app/features/settings/presentation/providers/settings_provider.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

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
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: Colors.white.withValues(alpha: 0.88),
        surfaceTintColor: Colors.white,
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
        title: Text('Settings',
            style: GoogleFonts.sora(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.ink)),
        centerTitle: false,
      ),
      body: state.isLoading && state.notificationPrefs.isEmpty
          ? const GenericListSkeleton()
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Account'),
                  _buildSettingsGroup(children: [
                    _buildSettingsItem(
                      icon: LucideIcons.user,
                      title: 'Edit Profile',
                      subtitle: 'Name, sport, achievements',
                      onTap: () {
                        final role = ref.read(authProvider).user?.role ?? 'athlete';
                        if (role == 'coach') {
                          context.push('/coach-profile-edit');
                        } else if (role == 'academy') {
                          context.push('/edit-academy-profile');
                        } else if (role == 'talent_scout') {
                          context.push('/scout-profile');
                        } else {
                          context.push('/edit-profile');
                        }
                      },
                    ),
                    // Media gallery hidden for organizers — photo/video
                    // uploads are no longer part of the organizer flows.
                    if ((ref.watch(authProvider).user?.role ?? '') != 'organizer')
                      _buildSettingsItem(
                        icon: LucideIcons.camera,
                        title: 'Media Gallery',
                        subtitle: 'Photos, videos, certificates',
                        onTap: () => context.push('/media-gallery'),
                      ),
                      _buildSettingsItem(
                        icon: LucideIcons.share2,
                        title: 'Social Links',
                        subtitle: 'Instagram, YouTube, website…',
                        onTap: () => context.push('/social-links'),
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
                      _buildSettingsToggleItem(
                        icon: LucideIcons.calendarClock,
                        title: 'Deadline Reminders',
                        subtitle: 'Get reminded 2 days and 1 day before deadlines',
                        value: state.notificationPrefs['deadline_reminders'] ?? true,
                        onChanged: (v) => ref.read(settingsProvider.notifier).updatePrefs(
                          {...state.notificationPrefs, 'deadline_reminders': v},
                        ),
                      ),
                    ],
                  ),

                  _buildSectionTitle('Privacy'),
                  _buildSettingsGroup(
                    children: [
                      _buildSettingsItem(
                        icon: LucideIcons.eye,
                        title: 'Profile Visibility',
                        subtitle: _privacyLabel(state.privacySettings['profile_visibility'] ?? 'public'),
                        onTap: () => _showPrivacyOptions(
                          context,
                          key: 'profile_visibility',
                          title: 'Profile Visibility',
                          options: const {
                            'public': 'Public — anyone can view',
                            'followers': 'Followers — connections only',
                            'private': 'Private — hidden from discovery',
                          },
                        ),
                      ),
                      _buildSettingsItem(
                        icon: LucideIcons.messageCircle,
                        title: 'Who Can Message Me',
                        subtitle: _privacyLabel(state.privacySettings['who_can_message'] ?? 'everyone'),
                        onTap: () => _showPrivacyOptions(
                          context,
                          key: 'who_can_message',
                          title: 'Who Can Message Me',
                          options: const {
                            'everyone': 'Everyone',
                            'connections': 'Connections only',
                            'nobody': 'Nobody',
                          },
                        ),
                      ),
                      _buildSettingsItem(
                        icon: LucideIcons.userPlus,
                        title: 'Who Can Connect',
                        subtitle: _privacyLabel(state.privacySettings['who_can_connect'] ?? 'everyone'),
                        onTap: () => _showPrivacyOptions(
                          context,
                          key: 'who_can_connect',
                          title: 'Who Can Connect',
                          options: const {
                            'everyone': 'Everyone',
                            'nobody': 'Nobody',
                          },
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
                        value: state.notificationPrefs['location'] ?? false,
                        onChanged: (v) => ref.read(settingsProvider.notifier).updatePrefs(
                          {...state.notificationPrefs, 'location': v},
                        ),
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
                        onTap: () => context.push('/legal?tab=terms'),
                      ),
                      _buildSettingsItem(
                        icon: LucideIcons.shield,
                        title: 'Privacy Policy',
                        onTap: () => context.push('/legal?tab=privacy'),
                      ),
                    ],
                  ),

                  _buildSettingsGroup(
                    children: [
                      _buildSettingsItem(
                        icon: LucideIcons.logOut,
                        title: 'Log Out',
                        isDanger: true,
                        onTap: () async {
                          await ref.read(authProvider.notifier).logout();
                        },
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
                color: AppColors.surface,
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
              color: AppColors.surface,
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

  String _privacyLabel(String value) {
    return value
        .split('_')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  void _showPrivacyOptions(
    BuildContext context, {
    required String key,
    required String title,
    required Map<String, String> options,
  }) {
    final current = ref.read(settingsProvider).privacySettings[key];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.entries.map((entry) {
            return ListTile(
              title: Text(entry.value),
              trailing: entry.key == current
                  ? const Icon(LucideIcons.check, color: AppColors.primary)
                  : null,
              onTap: () async {
                Navigator.pop(ctx);
                final ok = await ref
                    .read(settingsProvider.notifier)
                    .updatePrivacy({key: entry.key});
                if (context.mounted) {
                  if (ok) {
                    SnackBarUtils.showSuccess(context, 'Privacy updated');
                  } else {
                    SnackBarUtils.showError(
                      context,
                      ref.read(settingsProvider).error ?? 'Update failed',
                    );
                  }
                }
              },
            );
          }).toList(),
        ),
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
                SnackBarUtils.showSuccess(context, 'Account deleted');
              }
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }
}