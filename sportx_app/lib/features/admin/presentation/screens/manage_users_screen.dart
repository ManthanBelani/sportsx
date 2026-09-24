import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_flutter/lucide_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';
import 'package:sportx_app/core/utils/snackbar_utils.dart';
import 'package:sportx_app/shared/presentation/widgets/skeleton.dart';

class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(adminProvider.notifier).loadUsers();
  }

  @override
  Widget build(BuildContext context) {
    final adminState = ref.watch(adminProvider);

    return AdminWebLayout(
      title: 'Manage Users',
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.userPlus),
          onPressed: () => _showAddUserDialog(context),
        ),
      ],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone...',
                prefixIcon: const Icon(LucideIcons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border),
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                ref.read(adminProvider.notifier).loadUsers(search: value);
              },
            ),
          ),
          Expanded(
            child: adminState.isLoading
                ? const GenericListSkeleton()
                : adminState.users.isEmpty
                    ? const Center(child: Text('No users found'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: adminState.users.length,
                        itemBuilder: (context, index) {
                          final user = adminState.users[index];
                          return AdminUserCard(
                            name: user.name,
                            role: user.role.toUpperCase(),
                            city: user.city,
                            avatarUrl: user.profilePhotoUrl,
                            isVerified: user.isVerified,
                            isActive: user.isActive,
                            onTap: () => context.push(
                              '/admin/users/${user.id}/verify',
                              extra: user,
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) => _handleUserAction(value, user.id),
                              itemBuilder: (context) => [
                                if (!user.isVerified)
                                  const PopupMenuItem(
                                    value: 'verify',
                                    child: Text('Verify'),
                                  ),
                                PopupMenuItem(
                                  value: user.isActive ? 'suspend' : 'activate',
                                  child: Text(
                                    user.isActive ? 'Suspend' : 'Activate',
                                    style: GoogleFonts.inter(
                                      color: user.isActive ? AppColors.error : AppColors.success,
                                    ),
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete',
                                    style: GoogleFonts.inter(color: AppColors.error),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  void _handleUserAction(String action, String userId) async {
    final notifier = ref.read(adminProvider.notifier);
    switch (action) {
      case 'verify':
        await notifier.approveUser(userId);
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'User verified');
        }
        break;
      case 'suspend':
        await notifier.suspendUser(userId);
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'User suspended');
        }
        break;
      case 'activate':
        await notifier.approveUser(userId);
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'User activated');
        }
        break;
      case 'delete':
        await notifier.deleteUser(userId);
        if (mounted) {
          SnackBarUtils.showSuccess(context, 'User deleted');
        }
        break;
    }
  }

  void _showAddUserDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add User'),
        content: const Text('This feature allows admins to create new user accounts manually.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}