import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sportx_app/features/admin/presentation/providers/admin_provider.dart';
import 'package:sportx_app/features/admin/presentation/screens/admin_web_layout.dart';
import 'package:sportx_app/theme/colors.dart';

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
          icon: const Icon(Icons.person_add_outlined),
          onPressed: () => _showAddUserDialog(context),
        ),
      ],
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border(
                bottom: BorderSide(color: AppColors.border),
              ),
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by name, email, or phone...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (value) {
                ref.read(adminProvider.notifier).loadUsers(search: value);
              },
            ),
          ),
          Expanded(
            child: adminState.isLoading
                ? const Center(child: CircularProgressIndicator())
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
                                    style: TextStyle(
                                      color: user.isActive ? AppColors.error : AppColors.success,
                                    ),
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'delete',
                                  child: Text(
                                    'Delete',
                                    style: TextStyle(color: AppColors.error),
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
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User verified')),
          );
        }
        break;
      case 'suspend':
        await notifier.suspendUser(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User suspended')),
          );
        }
        break;
      case 'activate':
        await notifier.approveUser(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User activated')),
          );
        }
        break;
      case 'delete':
        await notifier.deleteUser(userId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User deleted')),
          );
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
